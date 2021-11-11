//
//  SampleCodeTest+2.swift
//  code-snippets
//
//  Created by Jayahari Vavachan on 11/9/21.
//  Copyright © 2021 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

struct Hotel: Codable {
    var id: String
    var type: String?
    var name: String?
    var city: String?
}

extension SampleCodeTest {
    // MARK: -- URLEndpointListener
    func dontTestTLSIdentityCreate() throws {
        // tag::p2psync-act-tlsid-create[]
        try TLSIdentity.deleteIdentity(withLabel: "couchbaselite-server-cert-label");
        let attrs = [certAttrCommonName: "CBL-Server"]
        let identity = try TLSIdentity.createIdentity(forServer: true,
                                                      attributes: attrs,
                                                      expiration: nil,
                                                      label: "couchbaselite-server-cert-label")
        // end::p2psync-act-tlsid-create[]
        print(identity)
    }
    
    func dontTestDeleteIdentity() throws {
        // tag::p2psync-act-tlsid-delete[]
        try TLSIdentity.deleteIdentity(withLabel: "couchbaselite-client-cert-label")
        // end::p2psync-act-tlsid-delete[]
    }
    
    func dontTestImportTLSIdentity() throws {
        // tag::p2psync-act-tlsid-import[]
        
        let path = Bundle.main.path(forResource: "identity/client", ofType: "p12")
        let clientCertData = try NSData(contentsOfFile: path!, options: []) as Data
        let identity = try TLSIdentity.importIdentity(withData: clientCertData,
                                                      password: "123",
                                                      label: "couchbaselite-client-cert-label")
        // end::p2psync-act-tlsid-import[]
        print(identity)
    }
    
    // MARK: -- QUERY RESULT SET HANDLING EXAMPLES
    
    func donTestQuerySyntaxAll() throws {
        // tag::query-syntax-all[]
        let db = try Database(name: "hotel")
        let listQuery = QueryBuilder.select(SelectResult.all()).from(DataSource.database( db))
        
        // end::query-syntax-all[]
        
        print(listQuery)
    }
    
    func dontTestQueryAccessAll() throws {
        let listQuery = QueryBuilder.select(SelectResult.all()).from(DataSource.database( db))
        var hotels = [String: Any]()
        
        // tag::query-access-all[]
        
        for row in try listQuery.execute() {
            let thisDocsProps = row.dictionary(at: 0)?.toDictionary() // <.>
            
            let docid = thisDocsProps!["id"] as! String
            let name = thisDocsProps!["name"] as! String
            let type = thisDocsProps!["type"] as! String
            let city = thisDocsProps!["city"] as! String
            
            print("\(docid): \(name), \(type), \(city)")
            let hotel = row.dictionary(at: 0)?.toDictionary()  //<.>
            let hotelId = hotel!["id"] as! String
            
            hotels[hotelId] = hotel
        }
        
        // end::query-access-all[]
    }
    
    
    
    func dontTestQueryAccessJSON() throws {
        let listQuery = QueryBuilder.select(SelectResult.all()).from(DataSource.database( db))
        var hotels = [String:Hotel]()
        // tag::query-access-json[]
        
        // In this example the Hotel class is defined using Codable
        //
        // class Hotel : Codable {
        //   var id : String = "undefined"
        //   var type : String = "hotel"
        //   var name : String = "undefined"
        //   var city : String = "undefined"
        //   var country : String = "undefined"
        //   var description : String? = ""
        //   var text : String? = ""
        //   ... other class content
        // }
        
        let results = try listQuery.execute()
        for row in  results {
            
            // get the result into a JSON String
            let jsonString = row.toJSON() // <.>
            
            let thisJsonObj:Dictionary =
            try (JSONSerialization.jsonObject(
                with: jsonString.data(using: .utf8)!,
                options: .allowFragments)
                 as? [String: Any])! // <.>
            
            // Use Json Object to populate Native object
            // Use Codable class to unpack JSON data to native object
            var this_hotel: Hotel = try JSONDecoder().decode(Hotel.self, from: jsonString.data(using: .utf8)!) // <.>
            
            // ALTERNATIVELY unpack in steps
            this_hotel.id = thisJsonObj["id"] as! String
            this_hotel.name = thisJsonObj["name"] as! String
            this_hotel.type = thisJsonObj["type"] as! String
            this_hotel.city = thisJsonObj["city"] as! String
            hotels[this_hotel.id] = this_hotel
        
        } // end for
        
        // end::query-access-json[]
    }
    
    func dontTestQuerySyntaxProps() throws {
        // tag::query-syntax-props[]
        let db = try! Database(name: "hotel")
        
        let listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"),
                    SelectResult.expression(Expression.property("id")),
                    SelectResult.expression(Expression.property("name")),
                    SelectResult.expression(Expression.property("city")),
                    SelectResult.expression(Expression.property("type")))
            .from(DataSource.database(db))
        
        // end::query-syntax-props[]
        print(listQuery)
    }
    
    func dontTestQueryAccessProps () throws {
        let listQuery = QueryBuilder.select(SelectResult.all()).from(DataSource.database( db))
        var hotels = [String: Hotel]()
        
        // tag::query-access-props[]
        for result in try! listQuery.execute() {
            
            
            let thisDoc = result.toDictionary()  // <.>
            
            // Store dictionary data in hotel object and save in arry
            guard let id = thisDoc["id"] as? String else {
                continue
            }
            var hotel = Hotel(id: id)
            hotel.name = thisDoc["name"] as? String
            hotel.city = thisDoc["city"] as? String
            hotel.type = thisDoc["type"] as? String
            hotels[id] = hotel
            
            // Use result content directly
            let docid = result.string(forKey: "metaId") // Selected (Meta.id).as("metaId")
            let hotelId = result.string(forKey: "id")
            let name = result.string(forKey: "name")
            let city = result.string(forKey: "city")
            let type = result.string(forKey: "type")
            
            // ... process document properties as required
            print("Result properties are: ", docid, hotelId,name, city, type)
        } // end for
        
        // end::query-access-props[]
    }// end func
    
    func dontTestQueryCount() throws {
        // tag::query-syntax-count-only[]
        let db = try Database(name: "hotel")
        let listQuery = QueryBuilder
            .select(SelectResult.expression(Function.count(Expression.all())).as("mycount"))
            .from (DataSource.database(db)).groupBy(Expression.property("type"))
        
        // end::query-syntax-count-only[]
        
        // tag::query-access-count-only[]
        for result in try listQuery.execute() {
            let dict = result.toDictionary() as? [String: Int]
            let thiscount = dict!["mycount"]! // <.>
            print("There are ", thiscount, " rows")
            
            // Alternatively
            print ( result["mycount"] )
            
        }
        // end::query-access-count-only[]
    }
    
    func dontTestQueryId () throws {
        
        // tag::query-syntax-id[]
        let db = try Database(name: "hotel")
        let listQuery = QueryBuilder.select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(db))
        
        // end::query-syntax-id[]
        
        
        // tag::query-access-id[]
        for result in try listQuery.execute() {
            
            print(result.toDictionary())
            print("Document Id is -- ", result["metaId"].string!)
            
            let thisDocsId = result["metaId"].string! // <.>
            
            // Now you can get the document using the ID
            var thisDoc = db.document(withID: thisDocsId)!.toDictionary()
            
            let hotelId = thisDoc["id"] as! String
            
            let name = thisDoc["name"] as! String
            
            let city = thisDoc["city"] as! String
            
            let type = thisDoc["type"] as! String
            
            // ... process document properties as required
            print("Result properties are: ", hotelId,name, city, type)
            
            
        }
        // end::query-access-id[]
    }
    
    func query_pagination () throws {
        //tag::query-syntax-pagination[]
        let thisOffset = 0;
        let thisLimit = 20;
        //
        let listQuery = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(db))
            .limit(Expression.int(thisLimit),
                   offset: Expression.int(thisOffset))
        
        // end::query-syntax-pagination[]
    }
    
    func dontTestQueryN1QL() throws {
        
        // tag::query-syntax-n1ql[]
        let db = try Database(name: "hotel")
        
        let listQuery =  db.createQuery(query: "SELECT META().id AS thisId FROM _ WHERE type = 'hotel'") // <.>
        
        let results: ResultSet = try listQuery.execute()
        
        // end::query-syntax-n1ql[]
        
        print(results.allResults().count)
    }
    
    func dontTestQueryN1QLparams() throws {
        
        // tag::query-syntax-n1ql-params[]
        let db = try! Database(name: "hotel")
        
        let listQuery =
        db.createQuery(query: "SELECT META().id AS thisId FROM _ WHERE type = $type") // <.>
        
        listQuery.parameters =
        Parameters().setString("hotel", forName: "type") // <.>
        
        let results: ResultSet = try listQuery.execute()
        
        // end::query-syntax-n1ql-params[]
        
        print(results.allResults().count)
    }
    
    func dontTestProcessResults(results: ResultSet) throws {
        // tag::query-access-n1ql[]
        // tag::query-process-results[]
        
        for row in results {
            print(row["thisId"].string!)
            
            let thisDocsId = row["thisId"].string!
            
            // Now you can get the document using the ID
            let thisDoc = db.document(withID: thisDocsId)!.toDictionary()
            
            let hotelId = thisDoc["id"] as! String
            
            let name = thisDoc["name"] as! String
            
            let city = thisDoc["city"] as! String
            
            let type = thisDoc["type"] as! String
            
            // ... process document properties as required
            print("Result properties are: ", hotelId,name, city, type)
            
        }
        // end::query-access-n1ql[]
        // end::query-process-results[]
        
    }
    
    // MARK: -- Listener
    
    func dontTestListenerSimple() throws {
        let database = try Database(name: "database")
        // tag::listener-simple[]
        var config = URLEndpointListenerConfiguration(database: database) // <.>
        config.authenticator = ListenerPasswordAuthenticator { username, password in
            return "valid.user" == username && "valid.password.string" == String(password)
        } // <.>
        
        let listener = URLEndpointListener(config: config) // <.>
        
        try listener.start()  // <.>
        
        // end::listener-simple[]
    }
    
    func dontTestListenerInitialize() throws {
        let otherDB = try Database(name: "otherDB")
        // tag::listener-initialize[]
        
        // tag::listener-config-db[]
        var config = URLEndpointListenerConfiguration(database: otherDB) // <.>

        // end::listener-config-db[]
        // tag::listener-config-port[]
        /* optionally */ let wsPort: UInt16 = 55991
        /* optionally */ let wssPort: UInt16 = 55990
        config.port =  wssPort // <.>

        // end::listener-config-port[]
        // tag::listener-config-netw-iface[]
        config.networkInterface = "10.1.1.10"  // <.>

        // end::listener-config-netw-iface[]
        // tag::listener-config-delta-sync[]
        config.enableDeltaSync = true // <.>

        // end::listener-config-delta-sync[]
        // tag::listener-config-tls-enable[]
        config.disableTLS  = false // <.>

        // end::listener-config-tls-enable[]
        // tag::listener-config-tls-id-anon[]
        // Set the credentials the server presents the client
        // Use an anonymous self-signed cert
        config.tlsIdentity = nil // <.>

        // end::listener-config-tls-id-anon[]
        // tag::listener-config-client-auth-pwd[]
        // Configure how the client is to be authenticated
        // Here, use Basic Authentication
        config.authenticator = ListenerPasswordAuthenticator(authenticator: { uname, pword -> Bool in
            return self.isValidCredentials(uname, password: pword)
        }) // <.>

        // end::listener-config-client-auth-pwd[]

        // tag::listener-start[]
        // Initialize the listener
        self.listener = URLEndpointListener(config: config) // <.>
        if self.listener == nil {
            fatalError("ListenerError Not Initialized")
            // ... take appropriate actions
        }
        
        // Start the listener
        try self.listener.start() // <.>

        // end::listener-start[]
        // end::listener-initialize[]
    }
    
    func dontTestReplicatorSimple() throws {
        let actDb = try Database(name: "actDb")
        // tag::replicator-simple[]

        let tgtUrl = URL(string: "wss://10.1.1.12:8092/actDb")!
        let targetEndpoint = URLEndpoint(url: tgtUrl) //  <.>

        var thisConfig = ReplicatorConfiguration(database: actDb, target: targetEndpoint) // <.>

        thisConfig.acceptOnlySelfSignedServerCertificate = true // <.>

        let thisAuthenticator = BasicAuthenticator(username: "valid.user", password: "valid.password.string")
        thisConfig.authenticator = thisAuthenticator // <.>

        replicator = Replicator(config: thisConfig) // <.>

        replicator.start(); // <.>

        // end::replicator-simple[]
    }

    // FIXME: Could you please check, whether this is necessary? it was a unit test helper function!
    // tag::xctListener-start-func[]
    func listen(tls: Bool, auth: ListenerAuthenticator?) throws -> URLEndpointListener {
        let thisDB = try? Database(name: "thisDB")
        let wssPort: UInt16 = 4985
        let wsPort: UInt16 = 4984
        // Stop if already running :
        if let listener = self.listener {
            listener.stop()
        }

        // Listener:
        // tag::xctListener-start[]
        // tag::xctListener-config[]
        //  ... fragment preceded by other user code, including
        //  ... Couchbase Lite Database initialization that returns `thisDB`

        guard let db = thisDB else {
            fatalError("DatabaseNotInitialized")
            // ... take appropriate actions
        }
        
        var config = URLEndpointListenerConfiguration.init(database: db)
        config.port = tls ? wssPort : wsPort
        config.disableTLS = !tls
        config.authenticator = auth
        listener = URLEndpointListener.init(config: config)
        //  ... fragment followed by other user code
        // end::xctListener-config[]

        // Start:
        try listener.start()
        // end::xctListener-start[]

        return listener
    }
    // end::xctListener-start-func[]

    
    func dontTestStopListener(listener: URLEndpointListener) throws {
        // tag::xctListener-stop-func[]
        listener.stop()
        // end::xctListener-stop-func[]
        
        // FIXME: Removed an internal only function 'deleteFromKeyChain'; Not public API to expose!
    }

    // FIXME: this is only for tests: Internal only: Don't expose this!!
//    func dontTestDeleteAnonymousIds() throws {
        // tag::xctListener-delete-anon-ids[]
//        FIXME: try URLEndpointListener.deleteAnonymousIdentities()
        // end::xctListener-delete-anon-ids[]
//    }
    
    func dontTestTLSIdentityAnonym() throws {
        // tag::xctListener-auth-tls-tlsidentity-anon[]
        // Anonymous Identity:
        let config = URLEndpointListenerConfiguration.init(database: db)
        listener = URLEndpointListener.init(config: config)
        try listener.start()
        
        print(listener.tlsIdentity) // anonymous tls-identity
        // end::xctListener-auth-tls-tlsidentity-anon[]
    }

    func testTLSIdentityCA() throws {
        let otherDB = try Database(name: "otherDB")
        // tag::xctListener-auth-tls-tlsidentity-ca[]
        // User Identity:
        let attrs = [certAttrCommonName: "CBL-Server"]
        let identity = try TLSIdentity.createIdentity(forServer: true,
                                                      attributes: attrs,
                                                      expiration: nil,
                                                      label: "couchbaselite-server-cert-label")
        var config = URLEndpointListenerConfiguration.init(database: otherDB)
        config.tlsIdentity = identity
        listener = URLEndpointListener.init(config: config)

        try listener.start()
        print(listener.tlsIdentity) // tlsIdentity with label 'couchbaselite-server-cert-label'
        // end::xctListener-auth-tls-tlsidentity-ca[]
    }

    func testPasswordAuthenticator() throws {
        let otherDB = try Database(name: "otherDB")
        
        // tag::xctListener-auth-basic-pwd-full[]
        // Listener:
        // tag::xctListener-auth-basic-pwd[]
        var config = URLEndpointListenerConfiguration(database: otherDB)
        config.authenticator = ListenerPasswordAuthenticator.init { username, password -> Bool in
            return username == "daniel" && password == "123"
        }
        
        listener = URLEndpointListener(config: config)
        try listener.start()
        // end::xctListener-auth-basic-pwd[]
    }
    // end::xctListener-auth-basic-pwd-full[]

    func testClientCertAuthenticatorWithRootCerts() throws {
        let otherDB = try Database(name: "otherDB")
        // tag::xctListener-auth-tls-CCA-Root-full[]
        // tag::xctListener-auth-tls-CCA-Root[]
        // Root Cert:
        let path = Bundle.main.path(forResource: "identity/client-ca", ofType: "der")
        let rootCertData = try NSData(contentsOfFile: path!, options: []) as Data
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!

        // Listener:
        var config = URLEndpointListenerConfiguration(database: otherDB)
        config.authenticator = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
        listener = URLEndpointListener(config: config)
        
        try listener.start()
        // end::xctListener-auth-tls-CCA-Root[]

        
        // Create client identity:
        let clientCertPath = Bundle.main.path(forResource: "identity/client", ofType: "p12")
        let clientCertData = try NSData(contentsOfFile: clientCertPath!, options: []) as Data
        let identity = try TLSIdentity.importIdentity(withData: clientCertData,
                                                      password: "123",
                                                      label: "couchbaselite-client-cert-label")

        // Replicator:
        let target = URLEndpoint(url: URL(string: "wss://localhost:4985/otherDB")!)
        var replicatorConfig = ReplicatorConfiguration(database: db, target: target)
        replicatorConfig.replicatorType = .pushAndPull
        replicatorConfig.continuous = false
        replicatorConfig.authenticator = ClientCertificateAuthenticator.init(identity: identity)
        replicatorConfig.pinnedServerCertificate = listener.tlsIdentity!.certs[0]
        replicator = Replicator(config: replicatorConfig)
        
        replicator.start()
        // end::xctListener-auth-tls-CCA-Root-full[]
    }

    func testServerCertVerificationModeSelfSignedCert() throws {
        let otherDB = try Database(name: "otherDB")
        // tag::xctListener-auth-tls-self-signed-full[]
        // tag::xctListener-auth-tls-self-signed[]
        // Listener:
        let config = URLEndpointListenerConfiguration(database: otherDB)
        listener = URLEndpointListener(config: config)
        try listener.start()
        
        print(listener.tlsIdentity) // self signed anonymnous
        print(listener.tlsIdentity!.certs.count)
        // end::xctListener-auth-tls-self-signed[]
        
        // Connect replicator with accept only self signed config
        let target = URLEndpoint(url: URL(string: "wss://localhost:4985/otherDB")!)
        var replicatorConfig = ReplicatorConfiguration(database: db, target: target)
        replicatorConfig.replicatorType = .pushAndPull
        replicatorConfig.continuous = false
        replicatorConfig.acceptOnlySelfSignedServerCertificate = true
        replicator = Replicator(config: replicatorConfig)
        replicator.start()
        
        // end::xctListener-auth-tls-self-signed-full[]
    }

    // tag::xctListener-auth-tls-ca-cert-full[]
    func testServerCertVerificationModeCACert() throws {
        let otherDB = try Database(name: "otherDB")
        // Listener:
        // tag::xctListener-auth-tls-ca-cert[]
        let rootCertPath = Bundle.main.path(forResource: "identity/certs", ofType: "p12")
        let rootCertData = try NSData(contentsOfFile: rootCertPath!, options: []) as Data
        var config = URLEndpointListenerConfiguration(database: otherDB)
        let identity = try TLSIdentity.importIdentity(withData: rootCertData,
                                                      password: "123",
                                                      label: "couchbaselite-server-cert-label")
        config.tlsIdentity = identity
        listener = URLEndpointListener(config: config)
        try listener.start()
        
        print(listener.tlsIdentity) // TLS identity with ca-cert data
        print(listener.tlsIdentity!.certs.count)

        // Replicator
        let target = URLEndpoint(url: URL(string: "wss://localhost:4985/otherDB")!)
        var replicatorConfig = ReplicatorConfiguration(database: db, target: target)
        replicatorConfig.replicatorType = .pushAndPull
        replicatorConfig.continuous = false
        replicatorConfig.pinnedServerCertificate = listener.tlsIdentity!.certs[0]
        replicator = Replicator(config: replicatorConfig)
        replicator.start()
        // end::xctListener-auth-tls-ca-cert[]
    }

    // tag::xctListener-status-check-full[]
    // FIXME: Can we link to the unit test??
    // https://github.com/couchbase/couchbase-lite-ios/blob/release/lithium/Swift/Tests/URLEndpointListenerTest.swift#L626-L676
    // ??
    // end::xctListener-status-check-full[]

    func dontTestListenerBasicAuthPassword() throws {
        let otherDB = try Database(name: "otherDB")
        var listenerConfig = URLEndpointListenerConfiguration(database: otherDB)
        let _allowListedUsers: [String] = []
        // tag::xctListener-auth-password-basic[]
        listenerConfig.authenticator = ListenerPasswordAuthenticator.init { username, _ -> Bool in
            if _allowListedUsers.contains(username) {
                return true
            }
            return false
        }
        // end::xctListener-auth-password-basic[]
    }

    func dontTestListenerAuthCertRoots() throws {
        let otherDB = try Database(name: "otherDB")
        let _whitelistedUsers = [String]()
        // tag::xctListener-auth-cert-roots[]
        let path = Bundle.main.path(forResource: "identity/client-ca", ofType: "der")
        let rootCertData = try NSData(contentsOfFile: path!, options: []) as Data
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
        
        var config = URLEndpointListenerConfiguration(database: otherDB)
        config.authenticator = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
        listener = URLEndpointListener(config: config)
        // end::xctListener-auth-cert-roots[]

        // tag::xctListener-auth-cert-auth[]
        let listenerAuth = ListenerCertificateAuthenticator { certs in
            print(certs.count)
            var commongName: CFString?
            let status = SecCertificateCopyCommonName(certs[0], &commongName)
            guard status == errSecSuccess, let commongName = commongName as String?, commongName == "daniel" else  {
                return false
            }
            return true
        }
        // end::xctListener-auth-cert-auth[]
        print(listenerAuth)

        // tag::xctListener-config-basic-auth[]
        var listenerConfig = URLEndpointListenerConfiguration(database: otherDB)
        
        listenerConfig.authenticator = ListenerPasswordAuthenticator(authenticator: { username, password in
            if _whitelistedUsers.contains(username) {
                return true
            }
            return false
        })
        
        listener = URLEndpointListener(config: listenerConfig)
        // end::xctListener-config-basic-auth[]
    }
    
    // MARK: Append
    
    func dontTestGetURLList() throws {
        // tag::listener-get-url-list[]
        let config = URLEndpointListenerConfiguration(database: otherDB)
        let listener = URLEndpointListener(config: config)
        try listener.start()
        
        if let urls = listener.urls {
            print("URLs are: \(urls)")
        }
        
        // end::listener-get-url-list[]
    }

    
    func dontTestListenerConfigDisableTLSUpdate() throws {
        var config = URLEndpointListenerConfiguration(database: otherDB)
        // tag::listener-config-tls-full-enable[]
        config.disableTLS  = false // <.>
        
        // end::listener-config-tls-full-enable[]
        // tag::listener-config-tls-disable[]
        config.disableTLS  = true // <.>
        
        // end::listener-config-tls-disable[]
    }
    
    func dontTestListenerConfigTLSIdentity() throws {
        var config = URLEndpointListenerConfiguration(database: otherDB)
        
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]
        guard let path = Bundle.main.path(forResource: "cert", ofType: "p12") else {
            /* process error */ return
        }
        
        guard let certData = try? NSData(contentsOfFile: path) as Data else {
            /* process error */ return
        } // <.>
        
        let tlsIdentity = try TLSIdentity.importIdentity(withData: certData,
                                                         password: "123",
                                                         label: "Server-Cert-Label") // <.>
        
        // end::listener-config-tls-id-caCert[]
        // tag::listener-config-tls-id-SelfSigned[]
        let attrs = [certAttrCommonName: "Couchbase Inc"] // <.>
        
        let identity = try TLSIdentity.createIdentity(forServer: true, /* isServer */
                                                      attributes: attrs,
                                                      expiration: Date().addingTimeInterval(86400),
                                                      label: "Server-Cert-Label") // <.>
        
        // end::listener-config-tls-id-SelfSigned[]
        // tag::listener-config-tls-id-full-set[]
        // Set the credentials the server presents the client
        config.tlsIdentity = tlsIdentity    // <.>
        
        // end::listener-config-tls-id-full-set[]
        // end::listener-config-tls-id-full[]
        
        print("To avoid waring: \(identity)")
    }
    
    func dontTestListenerConfigClientRootCA() throws {
        var config = URLEndpointListenerConfiguration(database: otherDB)
        let cert = self.listener.tlsIdentity!.certs[0]
        
        // tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Authenticate using Cert Authority

        // cert is a pre-populated object of type:SecCertificate representing a certificate
        let rootCertData = SecCertificateCopyData(cert) as Data // <.>
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)! //

        config.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert]) // <.> <.>

        // end::listener-config-client-auth-root[]
        // end::listener-config-client-root-ca[]
    }
    
    func isValidCertificates(_ certs: [SecCertificate]) -> Bool { return true }

    func dontTestClientAuthLambda() throws {
        var config = URLEndpointListenerConfiguration(database: otherDB)
        
        // tag::listener-config-client-auth-lambda[]
        // tag::listener-config-client-auth-self-signed[]
        // Authenticate self-signed cert using application logic

        config.authenticator = ListenerCertificateAuthenticator { certs -> Bool in // <.>
            // Validate the cert
            return self.isValidCertificates(certs)
        } // <.>

        // end::listener-config-client-auth-self-signed[]
        // end::listener-config-client-auth-lambda[]
    }

    func dontTestListenerConfigUpdate() throws {
        var config = URLEndpointListenerConfiguration(database: otherDB)
        let cert = self.listener.tlsIdentity!.certs[0]
        
        // tag::old-listener-config-tls-id-nil[]
        config.tlsIdentity = nil

        // end::old-listener-config-tls-id-nil[]
        // tag::old-listener-config-delta-sync[]
        config.enableDeltaSync = true

        // end::old-listener-config-delta-sync[]
        // tag::listener-status-check[]
        let totalConnections = self.listener.status.connectionCount
        let activeConnections = self.listener.status.activeConnectionCount

        // end::listener-status-check[]
        // tag::listener-stop[]
        self.listener.stop()

        // end::listener-stop[]
        // tag::old-listener-config-client-auth-root[]
        // cert is a pre-populated object of type:SecCertificate representing a certificate
        let rootCertData = SecCertificateCopyData(cert) as Data
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
        
        config.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

        // end::old-listener-config-client-auth-root[]
        // tag::old-listener-config-client-auth-self-signed[]
        config.authenticator = ListenerCertificateAuthenticator { self.isValidCertificates($0) }
        // end::old-listener-config-client-auth-self-signed[]
        
        print("to avoid warnings: \(activeConnections)/\(totalConnections) ")
    }

    func dontTestURLEndpointListenerConstructor() throws {
        let enableTLS = Bool.random()
        let wssPort: UInt16 = 4985
        let wsPort: UInt16 = 4984
        let auth = ListenerPasswordAuthenticator { self.isValidCredentials($0, password: $1)}
        
        // tag::p2p-ws-api-urlendpointlistener-constructor[]
        var config = URLEndpointListenerConfiguration.init(database: otherDB)
        config.port = enableTLS ? wssPort : wsPort
        config.disableTLS = !enableTLS
        config.authenticator = auth
        self.listener = URLEndpointListener.init(config: config) // <1>
        // end::p2p-ws-api-urlendpointlistener-constructor[]
    }

    func fMyActPeer() {
        // tag::p2p-act-rep-func[]
        
        // tag::p2p-act-rep-initialize[]
        guard let targetURL = URL(string: "wss://10.1.1.12:8092/actDb") else {
            fatalError("Invalid URL")
        }
        let targetEndpoint = URLEndpoint(url: targetURL)
        var config = ReplicatorConfiguration(database: self.db, target: targetEndpoint) // <.>

        // end::p2p-act-rep-initialize[]
        // tag::p2p-act-rep-config[]
        // tag::p2p-act-rep-config-type[]
        config.replicatorType = .pushAndPull

        // end::p2p-act-rep-config-type[]
        // tag::autopurge-override[]
        // set auto-purge behavior (here we override default)
        config.enableAutoPurge = false // <.>

        // end::autopurge-override[]
        // tag::p2p-act-rep-config-cont[]
        // Configure Sync Mode
        config.continuous = true

        // end::p2p-act-rep-config-cont[]
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Security -- only accept self-signed certs
        config.acceptOnlySelfSignedServerCertificate = true; // <.>

        // end::p2p-act-rep-config-self-cert[]
        // Configure Client Security // <.>
        // tag::p2p-act-rep-auth[]
        //  Set Authentication Mode
        config.authenticator = BasicAuthenticator(username: "cbl-user-01",
                                                  password: "secret")

        // end::p2p-act-rep-auth[]
        // tag::p2p-act-rep-config-conflict[]
        /* Optionally set custom conflict resolver call back
         config.conflictResolver = LocalWinConflictResolver()  // <.>
         */

        // end::p2p-act-rep-config-conflict[]
        // end::p2p-act-rep-config[]
        // tag::p2p-act-rep-start-full[]
        // Apply configuration settings to the replicator
        self.replicator = Replicator.init( config: config) // <.>

        // tag::p2p-act-rep-add-change-listener[]
        // Optionally add a change listener
        // Retain token for use in deletion
        let token = self.replicator.addChangeListener { change in // <.>
            if change.status.activity == .stopped {
                print("Replication stopped")
            } else {
                // tag::p2p-act-rep-status[]
                print("Replicator is currently : \(self.replicator.status.activity)")
            }
        }
        // end::p2p-act-rep-status[]
        // end::p2p-act-rep-add-change-listener[]

        // tag::p2p-act-rep-start[]
        // Run the replicator using the config settings
        self.replicator.start()  // <.>

        // end::p2p-act-rep-start[]
        // end::p2p-act-rep-start-full[]


        // end::p2p-act-rep-func[]
        self.replicator.removeChangeListener(withToken: token)
    }


    func dontTestReplicatorStop() {
        let token = self.replicator.addChangeListener { change in }
        // tag::p2p-act-rep-stop[]
        
        // Remove the change listener
        self.replicator.removeChangeListener(withToken: token)
        
        // Stop the replicator
        self.replicator.stop()

        // end::p2p-act-rep-stop[]
    }
    
    func dontTestAdditionalListenerConfigs() throws {
        let target = DatabaseEndpoint(database: otherDB)
        var config = ReplicatorConfiguration(database: db, target: target)
        let cert = self.listener.tlsIdentity!.certs[0]
        let validUsername = "cbl-user-01"
        let validPassword = "secret"
        // tag::p2p-act-rep-config-tls-full[]
        // tag::p2p-act-rep-config-cacert[]
        // Configure Server Security -- only accept CA Certs
        config.acceptOnlySelfSignedServerCertificate = false // <.>

        // end::p2p-act-rep-config-cacert[]
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Security -- only accept self-signed certs
        config.acceptOnlySelfSignedServerCertificate = true // <.>

        // end::p2p-act-rep-config-self-cert[]
        // tag::p2p-act-rep-config-pinnedcert[]
        // Return the remote pinned cert (the listener's cert)
        config.pinnedServerCertificate = cert // Get listener cert if pinned

        // end::p2p-act-rep-config-pinnedcert[]
        // Configure Client Security // <.>
        // tag::p2p-act-rep-auth[]
        //  Set Authentication Mode
        config.authenticator = BasicAuthenticator(username: validUsername, password: validPassword)

        // end::p2p-act-rep-auth[]
        // end::p2p-act-rep-config-tls-full[]

        // tag::p2p-tlsid-tlsidentity-with-label[]
        // Check if Id exists in keychain and if so, use that Id
        if let tlsIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") { // <.>
            print("An identity with label : doco-sync-server already exists in keychain")
            config.authenticator = ClientCertificateAuthenticator(identity: tlsIdentity) // <.>
        }

        // end::p2p-tlsid-check-keychain[]
        // end::p2p-tlsid-tlsidentity-with-label[]
    }
    
    // tag::p2p-tlsid-manage-func[]
    func myGetCert() throws -> TLSIdentity? {
        var osStatus: OSStatus
        let thisLabel : String? = "doco-sync-server"

        //var thisData : CFData?
        // tag::old-p2p-tlsid-tlsidentity-with-label[]
        // tag::p2p-tlsid-check-keychain[]
        // USE KEYCHAIN IDENTITY IF EXISTS
        // Check if Id exists in keychain. If so use that Id
        if let tlsIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") {
            print("An identity with label : doco-sync-server already exists in keychain")
            return tlsIdentity
        }
        
        // end::p2p-tlsid-check-keychain[]
//        thisAuthenticator.ClientCertificateAuthenticator(identity: thisIdentity )
//        config.thisAuthenticator
//        FIXME: Not sure, whats done here? Is this client side / server side authenticator?
        // end::old-p2p-tlsid-tlsidentity-with-label[]


        // tag::p2p-tlsid-check-bundled[]
        // CREATE IDENTITY FROM BUNDLED RESOURCE IF FOUND

        // Check for a resource bundle with required label to generate identity from
        // return nil identify if not found
        guard let path = Bundle.main.path(forResource: "doco-sync-server", ofType: "p12"),
              let certData = NSData(contentsOfFile: path)
        else {
            return nil
        }
        // end::p2p-tlsid-check-bundled[]

        // tag::p2p-tlsid-import-from-bundled[]
        // Use SecPKCS12Import to import the contents (identities and certificates)
        // of the required resource bundle (PKCS #12 formatted blob).
        //
        // Set passphrase using kSecImportExportPassphrase.
        // This passphrase should correspond to what was specified when .p12 file was created
        var result : CFArray?
        osStatus = SecPKCS12Import(certData as CFData, [String(kSecImportExportPassphrase): "couchbase"] as CFDictionary, &result)
        if osStatus != errSecSuccess {
            print("Failed to import data from provided with error :\(osStatus) ")
            return nil
        }
        let importedItems = result! as NSArray
        let item = importedItems[0] as! [String: Any]

        // Get SecIdentityRef representing the item's id
        let secIdentity = item[String(kSecImportItemIdentity)]  as! SecIdentity

        // Get Id's Private Key, return nil id if fails
        var privateKey : SecKey?
        osStatus = SecIdentityCopyPrivateKey(secIdentity, &privateKey)
        if osStatus != errSecSuccess {
            print("Failed to import private key from provided with error :\(osStatus) ")
            return nil
        }

        // Get all relevant certs [SecCertificate] from the ID's cert chain using kSecImportItemCertChain
        let certChain = item[String(kSecImportItemCertChain)] as? [SecCertificate]
        

        // Return nil, if errors in key, certChain at this stage
        guard let privateKey = privateKey, let certChain = certChain else {
            return nil
        }
        // end::p2p-tlsid-import-from-bundled[]

        // tag::p2p-tlsid-store-in-keychain[]
        // STORE THE IDENTITY AND ITS CERT CHAIN IN THE KEYCHAIN
#if os(iOS)
        // For iOS, need to save the identity into the KeyChain.
        // Save or Update identity with a label so that it could be cleaned up easily
        // Store Private Key in Keychain
        let params: [String : Any] = [
            String(kSecClass):          kSecClassKey,
            String(kSecAttrKeyType):    kSecAttrKeyTypeRSA,
            String(kSecAttrKeyClass):   kSecAttrKeyClassPrivate,
            String(kSecValueRef):       privateKey
        ]
        osStatus = SecItemAdd(params as CFDictionary, nil)
        if osStatus != errSecSuccess {
            print("Unable to store private key")
            return nil
        }
        // Store all Certs for Id in Keychain:
        var i = 0;
        for cert in certChain {
            let params: [String : Any] = [
                String(kSecClass):      kSecClassCertificate,
                String(kSecValueRef):   cert,
                String(kSecAttrLabel):  "doco-sync-server"
            ]
            osStatus = SecItemAdd(params as CFDictionary, nil)
            if osStatus != errSecSuccess {
                print("Unable to store certs")
                return nil
            }
            i=i+1
        }
#else
        let query: [String : Any] = [
            String(kSecClass):          kSecClassCertificate,
            String(kSecValueRef):       certs[0]
        ]
        
        let update: [String: Any] = [
            String(kSecClass):          kSecClassCertificate,
            String(kSecValueRef):       certs[0],
            String(kSecAttrLabel):      label
        ]
        
        osStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if osStatus != errSecSuccess {
            print("Unable to update certs \(osStatus)")
            return nil
        }
#endif
        // end::p2p-tlsid-store-in-keychain[]

        // tag::p2p-tlsid-return-id-from-keychain[]
        
        // RETURN A TLSIDENTITY FROM THE KEYCHAIN FOR USE IN CONFIGURING TLS COMMUNICATION
        return try TLSIdentity.identity(withIdentity: secIdentity, certs: [certChain[1]])
        // end::p2p-tlsid-return-id-from-keychain[]
    }

    func dontTestDeleteIDFromKeychain() throws {
        // tag::p2p-tlsid-delete-id-from-keychain[]

        try TLSIdentity.deleteIdentity(withLabel: "doco-sync-server")

        // end::p2p-tlsid-delete-id-from-keychain[]

    }
    
    func dontTestReplicatorConfigSelfCert() throws {
        let target = DatabaseEndpoint(database: otherDB)
        var config = ReplicatorConfiguration(database: db, target: target)
        // tag::old-p2p-act-rep-config-self-cert[]
        // acceptOnlySelfSignedServerCertificate = true -- accept Slf-Signed Certs
//        FIXME: !!
//          `disableTLS` is for listener and it is 'false' by default.
//          `acceptOnlySelfSignedServerCertificate` is for replicator
//        config.disableTLS = false
        config.acceptOnlySelfSignedServerCertificate = true

        // end::old-p2p-act-rep-config-self-cert[]
    }

    // tag::p2p-act-rep-config-cacert-pinned-func[]
    func myCaCertPinned() {
        let targetURL = URL(string: "wss://10.1.1.12:8092/actDb")!
        let targetEndpoint = URLEndpoint(url: targetURL)
        var config = ReplicatorConfiguration(database: self.db, target: targetEndpoint)
        // tag::p2p-act-rep-config-cacert-pinned[]

        // Get bundled resource and read into localcert
        guard
            let pathToCert = Bundle.main.path(forResource: "listener-pinned-cert", ofType: "cer"),
            let localCertificate:NSData = NSData(contentsOfFile: pathToCert)
        else { /* process error */ return }
        
        // Create certificate
        // using its DER representation as a CFData
        guard
            let pinnedCert = SecCertificateCreateWithData(nil, localCertificate)
        else { /* process error */  return }

        // Add `pinnedCert` and `acceptOnlySelfSignedServerCertificate=false` to `ReplicatorConfiguration`
        config.acceptOnlySelfSignedServerCertificate = false
        config.pinnedServerCertificate = pinnedCert
        // end::p2p-act-rep-config-cacert-pinned[]
        // end::p2p-act-rep-config-cacert-pinned-func[]
        
    }

    func dontTestOldListenerConfigClientRootCA() throws {
        // tag::old-listener-config-client-root-ca[]
        // Configure the client authenticator to validate using ROOT CA <.>
        // end::old-listener-config-client-root-ca[]
    }

    // end::p2p-tlsid-manage-func[]

    
    // MARK: -- JSON API SNIPPETS
    
    func dontTestQueryGetAll() throws {
        // tag::query-get-all[]
        let db = try Database(name: "hotel")
        let listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(db))
        
        // end::query-get-all[]
        print(listQuery)
    }
    
    func dontTestToJSONDocument() throws {
        let listQuery = QueryBuilder.select(SelectResult.all()).from(DataSource.database( db))
        let dbnew = try Database(name: "dbnew")
        
        for row in try listQuery.execute() {
            // tag::tojson-document[]
            let thisId = row.string(forKey: "metaId")! as String
            
            let thisJSONstring = db.document(withID: thisId)!.toJSON() // <.>
            
            print("JSON String = ", thisJSONstring)
            
            let hotelFromJSON:MutableDocument = try MutableDocument(id: thisId, json: thisJSONstring) // <.>
            
            try dbnew.saveDocument(hotelFromJSON)
            
            let newhotel = dbnew.document(withID: thisId)
            
            let keys = newhotel!.keys
            for key in keys { // <.>
                print(key, newhotel!.value(forKey: key) as! String)
            }
            
            // end::tojson-document[]
            
            /*
             // tag::tojson-document-output[]
             JSON String =  {"description":"Very good and central","id":"1000","country":"France","name":"Hotel Ted","type":"hotel","city":"Paris"}
             type hotel
             id 1000
             country France
             city Paris
             description Very good and central
             name Hotel Ted
             // end::tojson-document-output[]
             */
        }
    }
    
    func dontTestToJSONArray() throws {
        let dbnew = try Database(name: "dbnew")
        
        // tag::tojson-array[]
        let thisJSONstring = """
            [{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\",
            \"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},
            {\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\",
            \"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},
            {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
            \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\",
            \"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]
            """
        let myArray:MutableArrayObject =
        try! MutableArrayObject.init(json: thisJSONstring) // <.>
        
        for i in 0...myArray.count-1 {
            
            print(i+1, myArray.dictionary(at: i)!.string(forKey: "name")!)
            
            let docid = myArray.dictionary(at: i)!.string(forKey: "id")
            
            let newdoc:MutableDocument = MutableDocument(id: docid, data: (myArray.dictionary(at: i)?.toDictionary())! ) // <.>
            
            try! dbnew.saveDocument(newdoc)
            
        }
        
        let extendedDoc = dbnew.document(withID: "1002")
        let features = extendedDoc!.array(forKey: "features")?.toArray() // <.>
        for i in 0...features!.count-1 {
            print(features![i])
        }
        
        print(" \(extendedDoc!.array(forKey: "features")?.toJSON() ?? "--") ") // <.>
        
        // end::tojson-array[]
        
        /*
         // tag::tojson-array-output[]
         
         1 Hotel Ted
         2 Hotel Fred
         3 Hotel Ned
         
         Cable TV
         Toaster
         Microwave
         
         ["Cable TV","Toaster","Microwave"]
         // end::tojson-array-output[]
         */
    }
    
    func dontTestJSONdocument() {
        // tag::tojson-dictionary[]
        
        let aJSONstring = """
            {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
            \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\"}
            """
        
        let myDict:MutableDictionaryObject = try! MutableDictionaryObject(json: aJSONstring) // <.>
        print(myDict)
        
        let name = myDict.string(forKey: "name")
        print("Details for: ", name!)
        
        for key in myDict {
            
            print(key, myDict.value(forKey: key) as! String)
            
        }
        // end::tojson-dictionary[]
        
        /*
         // tag::tojson-dictionary-output[]
         
         Details for:  Hotel Ned
         description Undefined description for Hotel Ned
         id 1002
         name Hotel Ned
         country Australia
         type hotel
         city Balmain
         
         // end::tojson-dictionary-output[]
         */
    }
    
    
    func JsonApiBlob() throws {
#if TARGET_OS_IPHONE
        // tag::tojson-blob[]
        // Get a document
        let thisDoc = db.document(withID: "1000")?.toMutable() // <.>
        
        // Get the image and add as a blob to the document
        let contentType = "image/jpg";
        let ourImage = UIImage(named: "couchbaseimage.png")!
        let imageData = ourImage.jpegData(compressionQuality: 1)!
        thisDoc?.setBlob(Blob(contentType: contentType, data: imageData), forKey: "avatar") // <.>
        
        let theBlobAsJSONstringFails =
        thisDoc?.blob(forKey: "avatar")!.toJSON()
        
        // Save blob as part of doc or alternatively as a blob
        
        try! db.saveDocument(thisDoc!);
        try! db.saveBlob(blob: Blob(contentType: contentType, data: imageData)) // <.>
        
        // Retrieve saved blob as a JSON, reconstitue and check still blob
        let sameDoc = db.document(withID: "1000")
        let sameBlob = sameDoc?.blob(forKey: "avatar")
        let theBlobAsJSONstring = sameBlob!.toJSON() // <.>
        
        for (key, value) in sameDoc!.toDictionary() {
            print( "Data -- {0) = {1}", key, value)
        }
        
        if(Blob.isBlob(properties: sameBlob!.properties)) { // <.>
            print(theBlobAsJSONstring);
        }

        // end::tojson-blob[]
#endif
    }
}
