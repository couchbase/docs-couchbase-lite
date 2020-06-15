//
//  URLEndpontListenerTest.swift
//  CouchbaseLite
//
//  Copyright (c) 2020 Couchbase, Inc. All rights reserved.
//
//  Licensed under the Couchbase License Agreement (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  https://info.couchbase.com/rs/302-GJY-034/images/2017-10-30_License_Agreement.pdf
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// tag::listener[]

import XCTest
@testable import CouchbaseLiteSwift

@available(macOS 10.12, iOS 10.0, *)
class URLEndpontListenerTest: ReplicatorTest {
    let wsPort: UInt16 = 4984
    let wssPort: UInt16 = 4985
    let serverCertLabel = "CBL-Server-Cert"
    let clientCertLabel = "CBL-Client-Cert"

    var listener: URLEndpointListener?

    @discardableResult
    func listen() throws -> URLEndpointListener {
        return try listen(tls: true, auth: nil)
    }

    @discardableResult
    func listen(tls: Bool) throws -> URLEndpointListener {
        return try! listen(tls: tls, auth: nil)
    }

    @discardableResult
    // tag::listener-start-func[]
    func listen(tls: Bool, auth: ListenerAuthenticator?) throws -> URLEndpointListener {
        // Stop:
        if let listener = self.listener {
            listener.stop()
        }

        // Listener:
    // tag::listener-start[]
    // tag::listener-config[]
    //  ... fragment preceded by other user code, including
    //  ... Couchbase Lite Database initialization that returns `_userDB`

    guard let db = _userDb else {
        throw ListDocError.DatabaseNotInitialized
    }
    var listener: URLEndpointListener?
    let config = URLEndpointListenerConfiguration.init(database: db)
    config.port = tls ? wssPort : wsPort
    config.disableTLS = !tls
    config.authenticator = auth
    self.listener = URLEndpointListener.init(config: config)
//  ... fragment followed by other user code
    // end::listener-config[]

        // Start:
        try self.listener!.start()
    // end::listener-start[]

        return self.listener!
    }
    // end::listener-start-func[]

    func stopListen() throws {
        if let listener = self.listener {
            try stopListener(listener: listener)
        }
    }

    func stopListener(listener: URLEndpointListener) throws {
    // tag::listener-stop-func[]
    var listener: URLEndpointListener?
        let identity = listener.tlsIdentity
        listener.stop()
        if let id = identity {
            try id.deleteFromKeyChain()
    // end::listener-stop-func[]
        }
    }

    func cleanUpIdentities() throws {
// tag::listener-delete-anon-ids[]
        try URLEndpointListener.deleteAnonymousIdentities()
// end::listener-delete-anon-ids[]
    }

    override func setUp() {
        super.setUp()
        try! cleanUpIdentities()
    }

    override func tearDown() {
        try! stopListen()
        try! cleanUpIdentities()
        super.tearDown()
    }

    func testTLSIdentity() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Disabled TLS:
        var config = URLEndpointListenerConfiguration.init(database: self.oDB)
        config.disableTLS = true
        var listener = URLEndpointListener.init(config: config)
        XCTAssertNil(listener.tlsIdentity)

        try listener.start()
        XCTAssertNil(listener.tlsIdentity)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)

// tag::listener-auth-tls-tlsidentity-anon[]
        // Anonymous Identity:

        config = URLEndpointListenerConfiguration.init(database: self.oDB)
        listener = URLEndpointListener.init(config: config)
        XCTAssertNil(listener.tlsIdentity)

        try listener.start()
        XCTAssertNotNil(listener.tlsIdentity)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)

// end::listener-auth-tls-tlsidentity-anon[]

// tag::listener-auth-tls-tlsidentity-ca[]
        // User Identity:
        try TLSIdentity.deleteIdentity(withLabel: serverCertLabel);
        let attrs = [certAttrCommonName: "CBL-Server"]
        let identity = try TLSIdentity.createIdentity(forServer: true,
                                                      attributes: attrs,
                                                      expiration: nil,
                                                      label: serverCertLabel)
        config = URLEndpointListenerConfiguration.init(database: self.oDB)
        config.tlsIdentity = identity
        listener = URLEndpointListener.init(config: config)
        var(listener.tlsIdentity)

        try listener.start()
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssert(identity === listener.tlsIdentity!)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)
// end::listener-auth-tls-tlsidentity-ca[]
    }

    func testPasswordAuthenticator() throws {
// tag::listener-auth-basic-pwd-full[]
        // Listener:
// tag::listener-auth-basic-pwd[]
        let listenerAuth = ListenerPasswordAuthenticator.init {
            (username, password) -> Bool in
            return (username as NSString).isEqual(to: "daniel") &&
                   (password as NSString).isEqual(to: "123")
        }
        let listener = try listen(tls: false, auth: listenerAuth)

        auth = BasicAuthenticator.init(username: "daniel", password: "123")
        self.run(target: listener.localURLEndpoint, type: .pushAndPull,    continuous: false,
                 auth: auth)
// end::listener-auth-basic-pwd[]

        // Replicator - No Authenticator:
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: nil, expectedError: CBLErrorHTTPAuthRequired)

        // Replicator - Wrong Credentials:
        var auth = BasicAuthenticator.init(username: "daniel", password: "456")
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: auth, expectedError: CBLErrorHTTPAuthRequired)


        // Cleanup:
        try stopListen()
    }
// end::listener-auth-basic-pwd-full[]

    func testClientCertAuthenticatorWithClosure() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Listener:
        let listenerAuth = ListenerCertificateAuthenticator.init { (certs) -> Bool in
            XCTAssertEqual(certs.count, 1)
            var commongName: CFString?
            let status = SecCertificateCopyCommonName(certs[0], &commongName)
            XCTAssertEqual(status, errSecSuccess)
            XCTAssertNotNil(commongName)
            XCTAssertEqual((commongName! as String), "daniel")
            return true
        }
        let listener = try listen(tls: true, auth: listenerAuth)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)

        // Create client identity:
        let attrs = [certAttrCommonName: "daniel"]
        let identity = try TLSIdentity.createIdentity(forServer: false, attributes: attrs, expiration: nil, label: clientCertLabel)

        // Replicator:
        let auth = ClientCertificateAuthenticator.init(identity: identity)
        let serverCert = listener.tlsIdentity!.certs[0]
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false, auth: auth, serverCert: serverCert)

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)
        try stopListen()
    }

    func testClientCertAuthenticatorWithRootCerts() throws {
        if !self.keyChainAccessAllowed {
            return
        }

// tag::listener-auth-tls-CCA-Root-full[]
// tag::listener-auth-tls-CCA-Root[]
        // Root Cert:
        let rootCertData = try dataFromResource(name: "identity/client-ca", ofType: "der")
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!

        // Listener:
        let listenerAuth = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
        let listener = try listen(tls: true, auth: listenerAuth)
// end::listener-auth-tls-CCA-Root[]

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)

        // Create client identity:
        let clientCertData = try dataFromResource(name: "identity/client", ofType: "p12")
        let identity = try TLSIdentity.importIdentity(withData: clientCertData, password: "123", label: clientCertLabel)

        // Replicator:
        let auth = ClientCertificateAuthenticator.init(identity: identity)
        let serverCert = listener.tlsIdentity!.certs[0]

        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false, auth: auth, serverCert: serverCert)
// end::listener-auth-tls-CCA-Root-full[]
        }

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)
        try stopListen()
    }

    func testServerCertVerificationModeSelfSignedCert() throws {
        if !self.keyChainAccessAllowed {
            return
        }
// tag::listener-auth-tls-self-signed-full[]
// tag::listener-auth-tls-self-signed[]
        // Listener:
        let listener = try listen(tls: true)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)


        // Replicator - Success:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .selfSignedCert, serverCert: nil)
        }
// end::listener-auth-tls-self-signed[]
        // Replicator - TLS Error:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .caCert, serverCert: nil, expectedError: CBLErrorTLSCertUnknownRoot)
        }

        // Cleanup
        try stopListen()
// end::listener-auth-tls-self-signed-full[]
    }

// tag::listener-auth-tls-ca-cert-full[]
    func testServerCertVerificationModeCACert() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Listener:
// tag::listener-auth-tls-ca-cert[]
        let listener = try listen(tls: true)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)

        // Replicator - Success:
        self.ignoreException {
            let serverCert = listener.tlsIdentity!.certs[0]
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .caCert, serverCert: serverCert)
        }
// end::listener-auth-tls-ca-cert[]

        // Replicator - TLS Error:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .caCert, serverCert: nil, expectedError: CBLErrorTLSCertUnknownRoot)
        }

        // Cleanup
        try stopListen()
    }

    func testPort() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = wsPort
        self.listener = URLEndpointListener(config: config)
        XCTAssertNil(self.listener!.port)

        // Start:
        try self.listener!.start()
        XCTAssertEqual(self.listener!.port, wsPort)

        try stopListen()
        XCTAssertNil(self.listener!.port)
    }

    func testEmptyPort() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        self.listener = URLEndpointListener(config: config)
        XCTAssertNil(self.listener!.port)

        // Start:
        try self.listener!.start()
        XCTAssertNotEqual(self.listener!.port, 0)

        try stopListen()
        XCTAssertNil(self.listener!.port)
    }

    func testBusyPort() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        try listen()

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = self.listener!.port
        let listener2 = URLEndpointListener(config: config)

        expectError(domain: NSPOSIXErrorDomain, code: Int(EADDRINUSE)) {
            try listener2.start()
        }
    }

    func testURLs() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = wsPort
        self.listener = URLEndpointListener(config: config)
        XCTAssertNil(self.listener!.urls)

        // Start:
        try self.listener!.start()
        XCTAssert(self.listener!.urls?.count != 0)

        try stopListen()
        XCTAssertNil(self.listener!.urls)
    }

    func testConnectionStatus() throws {
// tag::listener-status-check-full[]
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = wsPort
        config.disableTLS = true
        self.listener = URLEndpointListener(config: config)
        XCTAssertEqual(self.listener!.status.connectionCount, 0)
        XCTAssertEqual(self.listener!.status.activeConnectionCount, 0)

        // Start:
        try self.listener!.start()
        XCTAssertEqual(self.listener!.status.connectionCount, 0)
        XCTAssertEqual(self.listener!.status.activeConnectionCount, 0)

        try generateDocument(withID: "doc-1")
        let rConfig = self.config(target: self.listener!.localURLEndpoint,
                                 type: .pushAndPull, continuous: false, auth: nil,
                                 serverCertVerifyMode: .caCert, serverCert: nil)
        var maxConnectionCount: UInt64 = 0, maxActiveCount:UInt64 = 0
        run(config: rConfig, reset: false, expectedError: nil) { (replicator) in
            replicator.addChangeListener { (change) in
                maxConnectionCount = max(self.listener!.status.connectionCount, maxConnectionCount)
                maxActiveCount = max(self.listener!.status.activeConnectionCount, maxActiveCount)
            }
        }
        XCTAssertEqual(maxConnectionCount, 1)
        XCTAssertEqual(maxActiveCount, 1)
        XCTAssertEqual(self.oDB.count, 1)

        try stopListen()
        XCTAssertEqual(self.listener!.status.connectionCount, 0)
        XCTAssertEqual(self.listener!.status.activeConnectionCount, 0)
    }
// end::listener-status-check-full[]

}

@available(macOS 10.12, iOS 10.0, *)
extension URLEndpointListener {
    var localURL: URL {
        assert(self.port != nil && self.port! > UInt16(0))
        var comps = URLComponents()
        comps.scheme = self.config.disableTLS ? "ws" : "wss"
        comps.host = "localhost"
        comps.port = Int(self.port!)
        comps.path = "/\(self.config.database.name)"
        return comps.url!
    }

    var localURLEndpoint: URLEndpoint {
        return URLEndpoint.init(url: self.localURL)
    }
}
// end::start-replication[]

// tag::listener-auth-password-basic[]
listenerConfig.authenticator = ListenerPasswordAuthenticator.init {
            (username, password) -> Bool in
    if (self._allowListedUsers.contains(["password" : password, "name":username])) {
        return true
    }
    return false
// end::listener-auth-password-basic[]

// tag::listener-auth-cert-roots[]
let rootCertData = try dataFromResource(name: "identity/client-ca", ofType: "der")
let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
let listenerAuth = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
let listener = try listen(tls: true, auth: listenerAuth)// end::listener-auth-cert-roots[]

// tag::listener-auth-cert-auth[]
let listenerAuth = ListenerCertificateAuthenticator.init { (certs) -> Bool in
    XCTAssertEqual(certs.count, 1)
    var commongName: CFString?
    let status = SecCertificateCopyCommonName(certs[0], &commongName)
    XCTAssertEqual(status, errSecSuccess)
    XCTAssertNotNil(commongName)
    XCTAssertEqual((commongName! as String), "daniel")
    return true
}
// end::listener-auth-cert-auth[]

// tag::listener-config-basic-auth[]
let listenerConfig = URLEndpointListenerConfiguration(database: db)
listenerConfig.disableTLS  = true // Use with anonymous self signed cert
listenerConfig.enableDeltaSync = true
listenerConfig.tlsIdentity = nil

listenerConfig.authenticator = ListenerPasswordAuthenticator.init {
            (username, password) -> Bool in
    if (self._whitelistedUsers.contains(["password" : password, "name":username])) {
        return true
    }
    return false
        }

_websocketListener = URLEndpointListener(config: listenerConfig)
// end::listener-config-basic-auth[]





// tag::replication-start-func[]
    func startP2PReplicationWithUserDatabaseToRemotePeer(_ peer:PeerHost, handler:@escaping(_ status:PeerConnectionStatus)->Void) throws{
        print("\(#function) with ws://\(peer)/\(kUserDBName)")
        guard let userDb = _userDb else {
             throw ListDocError.DatabaseNotInitialized

        }
        guard let user = self.currentUserCredentials?.user, let password = self.currentUserCredentials?.password else {
                    throw ListDocError.UserCredentialsNotProvided

        }

// tag::replicator-start-func-config-init[]
        var replicatorForUserDb = _replicatorsToPeers[peer]

        if replicatorForUserDb == nil {
            // Start replicator to connect to the URLListenerEndpoint
            guard let targetUrl = URL(string: "ws://\(peer)/\(kUserDBName)") else {
                throw ListDocError.URLInvalid
            }


            let config = ReplicatorConfiguration.init(database: userDb, target: URLEndpoint.init(url:targetUrl)) //<1>
// end::replicator-start-func-config-init[]

// tag::replicator-start-func-config-more[]

            config.replicatorType = .pushAndPull // <2>
            config.continuous =  true // <3>

// end::replicator-start-func-config-more[]

// tag::replicator-start-func-config-auth[]

            config.serverCertificateVerificationMode = .selfSignedCert
            let authenticator = BasicAuthenticator(username: user, password: password)
            config.authenticator = authenticator
// end::replicator-start-func-config-auth[]

// tag::replicator-start-func-repl-init[]
replicatorForUserDb = Replicator.init(config: config)
_replicatorsToPeers[peer] = replicatorForUserDb
// end::replicator-start-func-repl-init[]
          }


// tag::replicator-start-func-repl-start[]
if let pushPullReplListenerForUserDb = registerForEventsForReplicator(replicatorForUserDb,handler:handler) {
    _replicatorListenersToPeers[peer] = pushPullReplListenerForUserDb

}
replicatorForUserDb?.start()
handler(PeerConnectionStatus.Connecting)
// end::replicator-start-func-repl-start[]

      }
// end::replication-start-func[]


// tag::replicator-register-for-events[]
fileprivate func registerForEventsForReplicator(_ replicator:Replicator?,
  handler:@escaping(_ status:PeerConnectionStatus)->Void )->ListenerToken? {
    let pushPullReplListenerForUserDb = replicator?.addChangeListener({ (change) in

      let s = change.status
      if s.error != nil {
          handler(PeerConnectionStatus.Error)
          return
      }

      switch s.activity {
      case .connecting:
          print("Replicator Connecting to Peer")
          handler(PeerConnectionStatus.Connecting)
      case .idle:
          print("Replicator in Idle state")
          handler(PeerConnectionStatus.Connected)
      case .busy:
          print("Replicator in busy state")
          handler(PeerConnectionStatus.Busy)
      case .offline:
          print("Replicator in offline state")
      case .stopped:
          print("Completed syncing documents")
          handler(PeerConnectionStatus.Error)

      }

      if s.progress.completed == s.progress.total {
          print("All documents synced")
      }
      else {
          print("Documents \(s.progress.total - s.progress.completed) still pending sync")
      }
  })
  return pushPullReplListenerForUserDb
// end::replicator-register-for-events[]




//
// Stuff I adapted
//


import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class myclass {
// tag::listener-initialize[]
    fileprivate  var _allowlistedUsers:[[String:String]] = []
    fileprivate var _websocketListener:URLEndpointListener?
    fileprivate var _userDb:Database?
        // Include websockets listener initializer code
        let db=_userDb!

        let listenerConfig = URLEndpointListenerConfiguration(database: db) // <1>

        listenerConfig.disableTLS  = false // <2>
        listenerConfig.tlsIdentity = nil //
// tag::listener-config-auth[]
        listenerConfig.authenticator = ListenerPasswordAuthenticator.init { // <3>
            (username, password) -> Bool in
                if (self._allowlistedUsers.contains(
                  ["password" : password, "name":username])) {
                    return true
                }
            return false
        }
// end::listener-config-auth[]

        listenerConfig.enableDeltaSync = true // <4>

        _websocketListener = URLEndpointListener(config: listenerConfig) // <5>

        guard let websocketListener = _websocketListener else {
            throw ListDocError.WebsocketsListenerNotInitialized
            }
        try websocketListener.start() // <6> <7>

// end::listener-initialize[]
    }
}

// tag::listener-config-port[]
let wsPort: UInt16 = 4984
let wssPort: UInt16 = 4985
    listenerConfig.port = listener.config.disableTLS ? wsPort, wssPort
// end::listener-config-port[]

// tag::listener-config-netw-iface[]
listenerConfig.networkInterface = "10.1.1.10"
// end::listener-config-netw-iface[]

// tag::listener-config-disable-tls[]
// This combination will force non-TLS communication
listenerConfig.disableTLS  = true
// end::listener-config-disable-tls[]

// tag::listener-config-tls-id[]
listenerConfig.tlsIdentity = nil
// end::listener-config-tls-id[]

// tag::listener-config-delta-sync[]
listenerConfig.enableDeltaSync = true
// end::listener-config-delta-sync[]


// tag::listener-start[]
_websocketListener = URLEndpointListener(config: listenerConfig)
guard let websocketListener = _websocketListener else {
    throw ListDocError.WebsocketsListenerNotInitialized
    }
try websocketListener.start()
// end::listener-start[]

// tag::listener-status-check[]
let totalConnections = websocketListener.status.connectionCount
let activeConnections = websocketListener.status.activeConnectionCount
// end::listener-status-check[]


// tag::listener-stop[]
        listener.stop()
// end::listener-stop[]

// tag::listener-config-client-auth-root[]
  // cert is a pre-populated object of type:SecCertificate representing a certificate
  let rootCertData = SecCertificateCopyData(cert) as Data
  let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
  // Listener:
  listenerConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])
// end::listener-config-client-auth-root[]


// tag::listener-config-client-auth-self-signed[]
listenerConfig.authenticator = ListenerCertificateAuthenticator.init {
  (cert) -> Bool in
    var cert:SecCertificate
    var certCommonName:CFString?
    let status=SecCertificateCopyCommonName(cert, &certCommonName)
    if (self._allowlistedUsers.contains(["name": certCommonName! as String])) {
        return true
    }
    return false
}
// end::listener-config-client-auth-self-signed[]

