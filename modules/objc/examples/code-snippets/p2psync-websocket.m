//
// Stuff I adapted
//


import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class cMyPassListener {
  // tag::listener-initialize[]
  // tag::listener-local-db[]
  // . . . preceding application logic . . .
  fileprivate  var _allowlistedUsers:[[String:String]] = []
  fileprivate var _thisListener:URLEndpointListener?
  fileprivate var thisDB:Database?
  // Include websockets listener initializer code
  // func fMyPassListener() {
  CBLDatabase *thisDB = self.db;
  // end::listener-local-db[]
  // tag::listener-config-db[]
  // Initialize the listener config
  CBLURLEndpointListenerConfiguration* thisConfig; // <.>
  thisConfig = [[CBLURLEndpointListenerConfiguration alloc] initWithDatabase: database];

    // end::listener-config-db[]
    // tag::listener-config-port[]
    thisConfig.port =  55990; // <.>

    // end::listener-config-port[]
    // tag::listener-config-netw-iface[]
    NSURL *thisURL = [NSURL URLWithString:@"10.1.1.10"];
    thisConfig.networkInterface = thisURL; // <.>

    // end::listener-config-netw-iface[]
    // tag::listener-config-delta-sync[]
    thisConfig.enableDeltaSync = true // <.>

    // end::listener-config-delta-sync[]
    // tag::listener-config-tls-full[]
    // Configure server security
    // tag::listener-config-tls-enable[]
    thisConfig.disableTLS  = false; // <.>

    // end::listener-config-tls-enable[]
    // tag::listener-config-tls-disable[]
    thisConfig.disableTLS  = true; // <.>

    // end::listener-config-tls-disable[]
    // tag::listener-config-tls-id-full[]
    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    NSDictionary* attrs =
      @{ kCBLCertAttrCommonName: @"Couchbase Inc" }; // <.>

    thisIdentity =
      [CBLTLSIdentity createIdentityForServer: YES /* isServer */
          attributes: attrs
          expiration: [NSDate dateWithTimeIntervalSinceNow: 86400]
                label: @" couchbase-docs-cert"
                error: &error]; // <.>
    // end::listener-config-tls-id-SelfSigned[]
    // tag::listener-config-tls-id-caCert[]
    // Use CA Cert
    // Create a TLSIdentity from a key-pair and
    // certificate in secure storage

    // end::listener-config-tls-id-caCert[]
    // tag::listener-config-tls-id-anon[]
    // Use an anonymous self-signed cert
    thisConfig.tlsIdentity = nil; // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-tls-id-set[]
    // set the TLS Identity
    thisConfig.tlsIdentity =
      TLSIdentity(withLabel:thisIdentity); // <.>

    // end::listener-config-tls-id-set[]
    // end::listener-config-tls-id-full[]
    // tag::listener-config-client-auth-pwd[]
    // Configure Client Security using an Authenticator
    // For example, Basic Authentication <.>
    - (BOOL) isValidCredentials: (NSString*)u password: (NSString*)p { return YES; } // helper

    thisConfig.authenticator = [[CBLListenerPasswordAuthenticator alloc] initWithBlock: ^BOOL(NSString * thisUser, NSString * thisPassword) {
        if ([self isValidCredentials: thisUser password:thisPassword]) {
            return  YES;
        }
        return NO;
    }];

    // end::listener-config-client-auth-pwd[]
    // tag::listener-config-client-auth-root[]
    // tag::listener-config-client-root-ca[]
    // Configure the client authenticator
    // to validate using ROOT CA <.>
    // cert is a pre-populated object of
    // type:SecCertificate representing a certificate
    NEEDS CODE CONVERSION

    let rootCertData = SecCertificateCopyData(cert) as Data
    let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
    // Listener:
    thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

    // end::listener-config-client-root-ca[]
    // tag::listener-config-client-auth-self-signed[]
    // Authenticate self-signed cert
    // using application logic
    NEEDS CODE CONVERSION
    thisConfig.authenticator = ListenerCertificateAuthenticator.init {
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
    // tag::listener-start[]
    // Initialize the listener
    CBLURLEndpointListener* thisListener = nil;
    thisListener = [[CBLURLEndpointListener alloc] initWithConfig: listenerConfig]; // <.>
    }

    // start the listener
    BOOL success = [thisListener startWithError: &error];
    if (!success) {
        NSLog(@"Cannot start the listener: %@", error);
    } // <.>

    // end::listener-start[]
// end::listener-initialize[]

// tag::listener-stop[]
    [thisListener stop];

// end::listener-stop[]

  }
}

// tag::listener-config-tls-disable[]
thisConfig.disableTLS  = true

// end::listener-config-tls-disable[]

// tag::listener-config-tls-id-nil[]
thisConfig.tlsIdentity = nil

// end::listener-config-tls-id-nil[]


// tag::old-listener-config-delta-sync[]
thisConfig.enableDeltaSync = true

// end::old-listener-config-delta-sync[]


// tag::listener-status-check[]
let totalConnections = thisListener.status.connectionCount
let activeConnections = thisListener.status.activeConnectionCount

// end::listener-status-check[]


// tag::listener-config-client-auth-root[]
  // cert is a pre-populated object of type:SecCertificate representing a certificate
  let rootCertData = SecCertificateCopyData(cert) as Data
  let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
  // Listener:
  thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

// end::listener-config-client-auth-root[]


// tag::listener-config-client-auth-self-signed[]
thisConfig.authenticator = ListenerCertificateAuthenticator.init {
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

// tag::p2p-ws-api-urlendpointlistener[]
public class URLEndpointListener {
    // Properties // <1>
    public let config: URLEndpointListenerConfiguration
    public let port UInt16?
    public let tlsIdentity: TLSIdentity?
    public let urls: Array<URL>?
    public let status: ConnectionStatus?
    // Constructors <2>
    public init(config: URLEndpointListenerConfiguration)
    // Methods <3>
    public func start() throws
    public func stop()
}

// end::p2p-ws-api-urlendpointlistener[]


// tag::p2p-ws-api-urlendpointlistener-constructor[]
let config = URLEndpointListenerConfiguration.init(database: self.oDB)
thisConfig.port = tls ? wssPort : wsPort
thisConfig.disableTLS = !tls
thisConfig.authenticator = auth
self.listener = URLEndpointListener.init(config: config) // <1>

// end::p2p-ws-api-urlendpointlistener-constructor[]


// Active Peer Connection Snippets

//
//  my Other Bits.swift
//  doco-sync
//
//  Created by Ian Bridge on 19/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class myActPeerClass {

  func fMyActPeer() {
    // let thisUser = "syncthisUser"
    // let thisPassword = "sync9455"
    // let cert:SecCertificate?
    // let passivePeerEndpoint = "10.1.1.12:8920"
    // let passivePeerPort = "8920"
    // let passiveDbName = "userdb"
    // var actDb:Database?
    // var thisReplicator:Replicator?
    // var replicatorListener:ListenerToken?

    CBLReplicator *_thisReplicator;
    CBLListenerToken *_thisListenerToken;

    CBLDatabase *database
      = [[CBLDatabase alloc] initWithName:@"thisDB" error:&error];
        if (!database) {
          NSLog(@"Cannot open the database: %@", error);
        };

    // tag::p2p-act-rep-func[]
    // tag::p2p-act-rep-initialize[]
    // Set listener DB endpoint
    NSURL *url = [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
    CBLURLEndpoint *thisListener = [[CBLURLEndpoint alloc] initWithURL:url];

    CBLReplicatorConfiguration *thisConfig
      = [[CBLReplicatorConfiguration alloc]
          initWithDatabase:thisDB target:thisListener]; // <.>

    // end::p2p-act-rep-initialize[]
    // tag::p2p-act-rep-config[]
    // tag::p2p-act-rep-config-type[]
    thisConfig.replicatorType = kCBLReplicatorTypePush;

    // end::p2p-act-rep-config-type[]
    // tag::p2p-act-rep-config-cont[]
    thisConfig.continuous = YES;

    // end::p2p-act-rep-config-cont[]
    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security -- only accept CA Certs
    thisConfig.acceptOnlySelfSignedServerCertificate = NO; // <.>

    // end::p2p-act-rep-config-cacert[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Security -- only accept self-signed certs
    thisConfig.acceptOnlySelfSignedServerCertificate = YES; <.>

    // end::p2p-act-rep-config-self-cert[]
    // tag::p2p-act-rep-config-pinnedcert[]
    // Return the remote pinned cert (the listener's cert)
    thisConfig.pinnedServerCertificate = thisCert; // Get listener cert if pinned

    // end::p2p-act-rep-config-pinnedcert[]
    // Configure Client Security // <.>
    // tag::p2p-act-rep-auth[]
    //  Set Authentication Mode
    thisConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];

    // end::p2p-act-rep-auth[]
    // end::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-conflict[]
    /* Optionally set custom conflict resolver call back */
    thisConfig.conflictResolver = [[LocalWinConflictResolver alloc] // <.>

    // end::p2p-act-rep-config-conflict[]    //
    // end::p2p-act-rep-config[]
    // tag::p2p-act-rep-start-full[]
    // Apply configuration settings to the replicator
    _thisReplicator = [[CBLReplicator alloc] initWithConfig:thisConfig]; // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // Optionally add a change listener
    // retain token for use in deletion
    id<CBLListenerToken> thisListenerToken
      = [thisReplicator addChangeListener:^(CBLReplicatorChange *thisChange) {
    // tag::p2p-act-rep-status[]
          if (thisChange.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
            } else {
            NSLog(@"Status: " + thisChange.status.activity);
            };
    // end::p2p-act-rep-status[]
        }]; // <.>
// end::p2p-act-rep-add-change-listener[]
// tag::p2p-act-rep-start[]
    // Run the replicator using the config settings
    [thisReplicator start]; // <.>

// end::p2p-act-rep-start[]
// end::p2p-act-rep-start-full[]
// end::p2p-act-rep-func[]
    }

    func mystopfunc() {
// tag::p2p-act-rep-stop[]
    // Remove the change listener
    [thisReplicator removeChangeListenerWithToken: thisLstenerToken];

    // Stop the replicator
    [thisReplicator start];
// end::p2p-act-rep-stop[]
}







// tag::p2p-tlsid-manage-func[]
//
//  cMyGetCert.swift
//  doco-sync
//
//  Created by Ian Bridge on 20/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

import Foundation
import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity


class cMyGetCert1{

    let kListenerCertLabel = "doco-sync-server"
    let kListenerCertKeyP12File = "listener-cert-pkey"
    let kListenerPinnedCertFile = "listener-pinned-cert"
    let kListenerCertKeyExportPassword = "couchbase"
    //var importedItems : NSArray
    let thisData : CFData?
    var items : CFArray?

    func fMyGetCert() ->TLSIdentity? {
        var kcStatus = errSecSuccess // Zero
        let thisLabel : String? = "doco-sync-server"

        //var thisData : CFData?
        // tag::p2p-tlsid-check-keychain[]
        // tag::p2p-tlsid-tlsidentity-with-label[]
        // USE KEYCHAIN IDENTITY IF EXISTS
        // Check if Id exists in keychain. If so use that Id
        do {
            if let thisIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") {
                print("An identity with label : doco-sync-server already exists in keychain")
                return thisIdentity
                }
        } catch
          {return nil}
// end::p2p-tlsid-check-keychain[]
        thisAuthenticator.ClientCertificateAuthenticator(identity: thisIdentity )
        thisConfig.thisAuthenticator
// end::p2p-tlsid-tlsidentity-with-label[]


// tag::p2p-tlsid-check-bundled[]
// CREATE IDENTITY FROM BUNDLED RESOURCE IF FOUND

        // Check for a resource bundle with required label to generate identity from
        // return nil identify if not found
        guard let pathToCert = Bundle.main.path(forResource: "doco-sync-server", ofType: "p12"),
                let thisData = NSData(contentsOfFile: pathToCert)
            else
                {return nil}
// end::p2p-tlsid-check-bundled[]

// tag::p2p-tlsid-import-from-bundled[]
        // Use SecPKCS12Import to import the contents (identities and certificates)
        // of the required resource bundle (PKCS #12 formatted blob).
        //
        // Set passphrase using kSecImportExportPassphrase.
        // This passphrase should correspond to what was specified when .p12 file was created
        kcStatus = SecPKCS12Import(thisData as CFData, [String(kSecImportExportPassphrase): "couchbase"] as CFDictionary, &items)
            if kcStatus != errSecSuccess {
             print("failed to import data from provided with error :\(kcStatus) ")
             return nil
            }
        let importedItems = items! as NSArray
        let thisItem = importedItems[0] as! [String: Any]

        // Get SecIdentityRef representing the item's id
        let thisSecId = thisItem[String(kSecImportItemIdentity)]  as! SecIdentity

        // Get Id's Private Key, return nil id if fails
        var thisPrivateKey : SecKey?
        kcStatus = SecIdentityCopyPrivateKey(thisSecId, &thisPrivateKey)
            if kcStatus != errSecSuccess {
                print("failed to import private key from provided with error :\(kcStatus) ")
                return nil
            }

        // Get all relevant certs [SecCertificate] from the ID's cert chain using kSecImportItemCertChain
        let thisCertChain = thisItem[String(kSecImportItemCertChain)] as? [SecCertificate]

        // Return nil Id if errors in key or cert chain at this stage
        guard let pKey = thisPrivateKey, let pubCerts = thisCertChain else {
            return nil
        }
// end::p2p-tlsid-import-from-bundled[]

// tag::p2p-tlsid-store-in-keychain[]
// STORE THE IDENTITY AND ITS CERT CHAIN IN THE KEYCHAIN

        // Store Private Key in Keychain
        let params: [String : Any] = [
            String(kSecClass):          kSecClassKey,
            String(kSecAttrKeyType):    kSecAttrKeyTypeRSA,
            String(kSecAttrKeyClass):   kSecAttrKeyClassPrivate,
            String(kSecValueRef):       pKey
        ]
        kcStatus = SecItemAdd(params as CFDictionary, nil)
            if kcStatus != errSecSuccess {
                print("Unable to store private key")
                return nil
            }
       // Store all Certs for Id in Keychain:
       var i = 0;
       for cert in thisCertChain! {
            let params: [String : Any] = [
                String(kSecClass):      kSecClassCertificate,
                String(kSecValueRef):   cert,
                String(kSecAttrLabel):  "doco-sync-server"
                ]
            kcStatus = SecItemAdd(params as CFDictionary, nil)
                if kcStatus != errSecSuccess {
                    print("Unable to store certs")
                    return nil
                }
            i=i+1
        }
// end::p2p-tlsid-store-in-keychain[]

// tag::p2p-tlsid-return-id-from-keychain[]
// RETURN A TLSIDENTITY FROM THE KEYCHAIN FOR USE IN CONFIGURING TLS COMMUNICATION
do {
    return try TLSIdentity.identity(withIdentity: thisSecId, certs: [pubCerts[0]])
} catch {
    print("Error while loading self signed cert : \(error)")
    return nil
}
// end::p2p-tlsid-return-id-from-keychain[]
    } // fMyGetCert
} // cMyGetCert


// tag::p2p-tlsid-delete-id-from-keychain[]

do {
    try TLSIdentity.identity(withIdentity: thisSecId)
} catch {
    print("Error while deleting cert : \(error)")
    return nil
}

// end::p2p-tlsid-delete-id-from-keychain[]



// end::p2p-tlsid-manage-func[]







// tag::p2p-act-rep-config-self-cert[]
// Use serverCertificateVerificationMode set to `.selfSignedCert` to disable cert validation
thisConfig.disableTLS = false
thisConfig.acceptOnlySelfSignedServerCertificate=true
// end::p2p-act-rep-config-self-cert[]


// tag::p2p-act-rep-config-cacert-pinned-func[]
func fMyCaCertPinned() {
  // do {
  let tgtUrl = URL(string: "wss://10.1.1.12:8092/actDb")!
  let targetEndpoint = URLEndpoint(url: tgtUrl)
  let actDb:Database?
  let config = ReplicatorConfiguration(database: actDb!, target: targetEndpoint)
  // tag::p2p-act-rep-config-cacert-pinned[]
    NSURL *certURL =
      [[NSBundle mainBundle] URLForResource: @"cert" withExtension: @"cer"];
    NSData *data =
      [[NSData alloc] initWithContentsOfURL: certURL];
    SecCertificateRef certificate =
      SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    NSURL *url =
      [NSURL URLWithString:@"ws://localhost:4984/db"];

    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];

    CBLReplicatorConfiguration *thisConfig =
      [[CBLReplicatorConfiguration alloc] initWithDatabase:database
                                          target:target];
    thisConfig.pinnedServerCertificate =
      (SecCertificateRef)CFAutorelease(certificate);

    thisConfig.acceptOnlySelfSignedServerCertificate=false;

  // end::p2p-act-rep-config-cacert-pinned[]
  // end::p2p-act-rep-config-cacert-pinned-func[]
}
