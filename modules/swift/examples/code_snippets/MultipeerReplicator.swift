//
//  MultipeerReplicator.swift
//  CouchbaseLite
//
//  Copyright © 2025 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

class MultipeerReplicatorSnippets {
    var database: Database!
    var collection1: Collection!
    var collection2: Collection!
    var collection3: Collection!
    
    func collectionSimple() throws -> [MultipeerCollectionConfiguration] {
        // tag::multipeer-collection-simple
        let collections = [collection1, collection2, collection3].map {
            MultipeerCollectionConfiguration(collection: $0)
        }
        // end::multipeer-collection-simple
        return collections
    }
    
    func collectionConfig() throws -> [MultipeerCollectionConfiguration] {
        // tag::multipeer-collection-config
        class CustomConflictResolver: MultipeerConflictResolver {
            func resolve(peerID: PeerID, conflict: Conflict) -> Document? {
                return conflict.remoteDocument
            }
        }
            
        // Create a collection config with a conflict resolver
        var config1 = MultipeerCollectionConfiguration(collection: collection1)
        config1.conflictResolver = CustomConflictResolver()
        
        // Create a collection config with a document ID filter
        var config2 = MultipeerCollectionConfiguration(collection: collection2)
        config2.documentIDs = ["doc1", "doc2"]
        
        // Create a collection config with a push replication filter
        var config3 = MultipeerCollectionConfiguration(collection: collection3)
        config3.pushFilter = { peerID, document, flags in
            return document.int(forKey: "access-level") == 2
        }
        
        let collections = [config1, config2, config3]
        // end::multipeer-collection-config
        return collections
    }
    
    func peerIdentity() throws -> TLSIdentity {
        // tag::multipeer-tlsidentity
        let persistentLabel = "com.myapp.identity"
    
        // Retrieve the TLS identity from the keychain using the persistent label.
        var identity =  try TLSIdentity.identity(withLabel: persistentLabel)
        
        // If the identity doesn't exist or expired, create a new one.
        if (identity == nil || identity!.expiration < Date()) {
            // Create an issuer identity from the private key and certificate data in DER format.
            let privateKey = try getIssuerPrivateKeyData()
            let cert = try getIssuerCertificateData()
            let issuer = try TLSIdentity.createIdentity(
                withPrivateKey: privateKey,
                certificate: cert)
            
            // Create a new identity signed with the issuer.
            let attrs: [String: String] = [certAttrCommonName: "MyApp"]
            let expiration = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
            identity = try TLSIdentity.createIdentity(
                for: [.clientAuth, .serverAuth],
                attributes: attrs,
                expiration: expiration,
                issuer: issuer,
                label: persistentLabel)
        }
        // end::multipeer-tlsidentity
        return identity!
    }
    
    func getIssuerPrivateKeyData() throws -> Data {
        return Data(base64Encoded: "your_base64_encoded_private_key")!
    }
    
    func getIssuerCertificateData() throws -> Data {
        return Data(base64Encoded: "your_base64_encoded_certicate")!
    }
    
    func authenticatorWithCallback() throws -> MultipeerAuthenticator{
        // tag::multipeer-authenticator-callback
        let authenticator = MultipeerCertificateAuthenticator { peerID, certs in
            return true
        }
        // end::multipeer-authenticator-callback
        return authenticator
    }
    
    func authenticatorWithRootCerts() throws -> MultipeerAuthenticator {
        let privateKey = try getIssuerPrivateKeyData()
        let cert = try getIssuerCertificateData()
        let issuer = try TLSIdentity.createIdentity(withPrivateKey: privateKey, certificate: cert)
        
        // tag::multipeer-authenticator-rootcerts
        let authenticator = MultipeerCertificateAuthenticator(rootCerts: issuer.certs)
        // end::multipeer-authenticator-rootcerts
        return authenticator
    }
    
    func createConfig() throws -> MultipeerReplicatorConfiguration {
        let identity = try peerIdentity()
        let authenticator = try authenticatorWithRootCerts()
        let collections = try collectionConfig()
        
        // tag::multipeer-config
        let config = MultipeerReplicatorConfiguration(
            peerGroupID: "com.myapp",
            identity: identity,
            authenticator: authenticator,
            collections: collections)
        // end::multipeer-config
        return config
    }
    
    func createMultipeerReplicator() throws -> MultipeerReplicator {
        let config = try createConfig()
        // tag::multipeer-replicator
        let replicator = try MultipeerReplicator(config: config)
        // end::multipeer-replicator
        return replicator
    }
    
    func startReplicator() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-replicator-start
        replicator.start()
        // end::multipeer-replicator-start
    }
    
    func stopReplicator() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-replicator-stop
        replicator.stop()
        // end::multipeer-replicator-stop
    }
    
    func statusListener() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-status-listener
        let token = replicator.addStatusListener { status in
            let state = status.active ? "active" : "inactive"
            let error = status.error?.localizedDescription ?? "none"
            print("Multipeer Replicator: \(state), Error: \(error)")
        }
        // end::multipeer-status-listener
    }
    
    func peerDiscoveryListener() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-peer-discovery-listener
        let token = replicator.addPeerDiscoveryStatusListener { status in
            let online = status.online ? "online" : "offline"
            print("Peer Discovery Status - Peer ID: \(status.peerID), Status: \(online)")
        }
        // end::multipeer-peer-discovery-listener
    }
    
    func peerReplicatorStatus() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-replicator-status-listener
        let activities = ["stopped", "offline", "connecting", "idle", "busy"]
        let token = replicator.addPeerReplicatorStatusListener { replStatus in
            let direction = replStatus.outgoing ? "outgoing" : "incoming"
            let activity = activities[Int(replStatus.status.activity.rawValue)]
            let error = replStatus.status.error?.localizedDescription ?? "none"
            print("Peer Replicator Status - Peer ID: \(replStatus.peerID), " +
                  "Direction: \(direction), " +
                  "Activity: \(activity), " +
                  "Error: \(error)")
        }
        // end::multipeer-replicator-status-listener
    }
    
    func peerDocumentReplication() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-document-replication-listener
        let token = replicator.addPeerDocumentReplicationListener { docRepl in
            let direction = docRepl.isPush ? "Push" : "Pull"
            print("Peer Document Replication - Peer ID: \(docRepl.peerID), Direction: \(direction)")
            docRepl.documents.forEach { doc in
                let error = doc.error?.localizedDescription ?? "none"
                let collection = "\(doc.scope).\(doc.collection)"
                print(" Collection: \(collection)" +
                      " Document ID: \(doc.id)," +
                      " Flags: \(doc.flags)," +
                      " Error: \(error)")
            }
        }
        // end::multipeer-document-replication-listener
    }
    
    func peerID() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-peer-id
        let peerID = replicator.peerID
        print("Peer ID: \(peerID)")
        // end::multipeer-peer-id
    }
    
    func neighborPeers() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-neighbor-peers
        let neighborPeers = replicator.neighborPeers
        print("Neighbor Peers:")
        neighborPeers.forEach { peerID in
            print(" \(peerID)")
        }
        // end::multipeer-neighbor-peers
    }
    
    func peerInfo() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-peer-info
        let activities = ["stopped", "offline", "connecting", "idle", "busy"]
        
        let printPeerInfo: (PeerInfo) -> Void = { info in
            print("Peer ID: \(info.peerID)")
            print(" Status: \(info.online ? "online" : "offline")")
            let neighborPeers = replicator.neighborPeers
            print(" Neighbor Peers:")
            neighborPeers.forEach { peerID in
                print("  \(peerID)")
            }
            
            let replStatus = info.replicatorStatus
            let activity = activities[Int(replStatus.activity.rawValue)]
            let error = replStatus.error?.localizedDescription ?? "none"
            print(" Replicator Status: \(activity), Error: \(error)")
        }
        
        replicator.neighborPeers.forEach { peerID in
            if let peerInfo = replicator.peerInfo(for: peerID) {
                printPeerInfo(peerInfo)
            }
        }
        // end::multipeer-peer-info
    }
}
