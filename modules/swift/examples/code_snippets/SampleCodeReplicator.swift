//
//  SampleCodeReplicator.swift
//  code-snippets
//
//  Created by Jayahari Vavachan on 11/10/21.
//  Copyright © 2021 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

class SampleCodeReplicator {
    var db: Database?
    var replicatorsToPeers = [String: Replicator]()
    var replicatorListenerTokens = [String: Any]()
    
    // tag::replication-start-func[]
    enum PeerConnectionStatus: UInt8 {
        case stopped = 0;
        case offline
        case connecting
        case idle
        case busy
    }
    
    func dontTestReplicationStart(_ peer: String,
                                  peerDBName: String,
                                  user: String?,
                                  pass: String?,
                                  handler: @escaping (PeerConnectionStatus, Error?) -> Void) throws {
        guard let userDb = self.db else {
            fatalError("DatabaseNotInitialized")
            // ... take appropriate actions
        }
        guard let validUser = user, let validPassword = pass else {
            fatalError("UserCredentialsNotProvided")
            // ... take appropriate actions
        }
        
        // tag::replicator-start-func-config-init[]
        let replicator = self.replicatorsToPeers[peer]
        
        if replicator == nil {
            // Start replicator to connect to the URLListenerEndpoint
            guard let targetUrl = URL(string: "ws://\(peer)/\(peerDBName)") else {
                fatalError("URLInvalid")
                // ... take appropriate actions
            }
            
            var config = ReplicatorConfiguration.init(database: userDb, target: URLEndpoint.init(url:targetUrl)) //<1>
            // end::replicator-start-func-config-init[]
            
            // tag::replicator-start-func-config-more[]
            
            config.replicatorType = .pushAndPull // <2>
            config.continuous =  true // <3>
            
            // end::replicator-start-func-config-more[]
            
            // tag::replicator-start-func-config-auth[]
            config.authenticator = BasicAuthenticator(username: validUser, password: validPassword)
            // end::replicator-start-func-config-auth[]
            
            // tag::replicator-start-func-repl-init[]
            let temp = Replicator.init(config: config)
            self.replicatorsToPeers[peer] = temp
            
            let token = registerForEventsForReplicator(temp, handler: handler)
            self.replicatorListenerTokens[peer] = token
            
            // end::replicator-start-func-repl-init[]
        }
        
        // tag::replicator-start-func-repl-start[]
        replicator?.start()
        // end::replicator-start-func-repl-start[]
    }
    // end::replication-start-func[]
    
    // tag::replicator-register-for-events[]
    func registerForEventsForReplicator(_ replicator: Replicator,
                                        handler: @escaping (PeerConnectionStatus, Error?) -> Void) -> ListenerToken {
        return replicator.addChangeListener { change in
            guard change.status.error == nil else {
                handler(.stopped, change.status.error)
                return
            }
            
            switch change.status.activity {
            case .connecting:
                print("Replicator Connecting to Peer")
            case .idle:
                print("Replicator in Idle state")
            case .busy:
                print("Replicator in busy state")
            case .offline:
                print("Replicator in offline state")
            case .stopped:
                print("Replicator is stopped")
            }
            
            let progress = change.status.progress
            if progress.completed == progress.total {
                print("All documents synced")
            }
            else {
                print("Documents \(progress.total - progress.completed) still pending sync")
            }
            
            if let customStatus = PeerConnectionStatus(rawValue: change.status.activity.rawValue) {
                handler(customStatus, nil)
            }
        }
    }
    // end::replicator-register-for-events[]
}

#if os(macOS)
        // tag::listener-get-network-interfaces[]
        import SystemConfiguration
        // . . .
        
class SomeClass {
    func SomeFunction() {
        for interface in SCNetworkInterfaceCopyAll() as! [SCNetworkInterface] {
            // do something with this `interface`
        }
    }
    
    // . . .
}
        
        // end::listener-get-network-interfaces[]
#endif
