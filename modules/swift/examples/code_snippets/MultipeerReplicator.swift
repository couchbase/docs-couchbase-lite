//
//  MultipeerReplicator.swift
//  code-snippets
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
        // tag::multipeer-collection-simple[]
        let collections = [collection1, collection2, collection3].map {
            MultipeerCollectionConfiguration(collection: $0)
        }
        // end::multipeer-collection-simple[]
        return collections
    }

    func collectionConfig() throws -> [MultipeerCollectionConfiguration] {
        // tag::multipeer-collection-config[]
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
        // end::multipeer-collection-config[]
        return collections
    }

    func createselfSignedIdentity() throws -> TLSIdentity {
        // tag::multipeer-selfsigned-tlsidentity[]
        let persistentLabel = "com.myapp.identity"

        // Retrieve the TLS identity from the keychain using the persistent label.
        var identity = try TLSIdentity.identity(withLabel: persistentLabel)

        // If the identity exists but is expired, delete it.
        if let existing = identity, existing.expiration < Date() {
            try TLSIdentity.deleteIdentity(withLabel: persistentLabel)
            identity = nil
        }

        // If the identity doesn't exist or expired, create a new one.
        if identity == nil {
            // Define certificate attributes and expiration date.
            let attrs: [String: String] = [certAttrCommonName: "MyApp"]
            let expiration = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

            // Create and store a new self-signed identity in the keychain with a persistent label.
            identity = try TLSIdentity.createIdentity(
                for: [.clientAuth, .serverAuth],
                attributes: attrs,
                expiration: expiration,
                label: persistentLabel)
        }
        // end::multipeer-selfsigned-tlsidentity[]
        return identity!
    }

    func createCASignedIdentity() throws -> TLSIdentity {
        // tag::multipeer-tlsidentity[]
        let persistentLabel = "com.myapp.identity"

        // Retrieve the TLS identity from the keychain using the persistent label.
        var identity = try TLSIdentity.identity(withLabel: persistentLabel)

        // If the identity exists but is expired, delete it.
        if let existing = identity, existing.expiration < Date() {
            try TLSIdentity.deleteIdentity(withLabel: persistentLabel)
            identity = nil
        }

        // If the identity doesn't exist or expired, create a new one.
        if identity == nil {
            // Define certificate attributes and expiration date.
            let attrs: [String: String] = [certAttrCommonName: "MyApp"]
            let expiration = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

            // Get issuer's private key and certificate data (DER format) for signing the identity's certificate.
            let caKey = try getIssuerPrivateKeyData()
            let caCert = try getIssuerCertificateData()

            // Create and store a new identity signed with the issuer in the keychain with a persistent label.
            identity = try TLSIdentity.createSignedIdentityInsecure(
                for: [.clientAuth, .serverAuth],
                attributes: attrs,
                expiration: expiration,
                caKey: caKey,
                caCertificate: caCert,
                label: persistentLabel)
        }
        // end::multipeer-tlsidentity[]
        return identity!
    }

    func getIssuerPrivateKeyData() throws -> Data {
        return Data(base64Encoded: "your_base64_encoded_private_key")!
    }

    func getIssuerCertificateData() throws -> Data {
        return Data(base64Encoded: "your_base64_encoded_certicate")!
    }

    func authenticatorWithCallback() throws -> MultipeerAuthenticator{
        // tag::multipeer-authenticator-callback[]
        let authenticator = MultipeerCertificateAuthenticator { peerID, certs in
            return true
        }
        // end::multipeer-authenticator-callback[]
        return authenticator
    }

    func authenticatorWithRootCerts() throws -> MultipeerAuthenticator {
        // tag::multipeer-authenticator-rootcerts[]
        // Get issuer's certificate data (DER format), which was used to sign the peer's certificate.
        let caCert = try getIssuerCertificateData()
        let caCertRef = SecCertificateCreateWithData(nil, caCert as CFData)!
        let authenticator = MultipeerCertificateAuthenticator(rootCerts: [caCertRef])
        // end::multipeer-authenticator-rootcerts[]
        return authenticator
    }

    func createConfig() throws -> MultipeerReplicatorConfiguration {
        let identity = try createCASignedIdentity()
        let authenticator = try authenticatorWithRootCerts()
        let collections = try collectionConfig()

        // tag::multipeer-config[]
        let config = MultipeerReplicatorConfiguration(
            peerGroupID: "com.myapp",
            identity: identity,
            authenticator: authenticator,
            collections: collections)
        // end::multipeer-config[]
        return config
    }

    func createConfigTransportsDefault() throws -> MultipeerReplicatorConfiguration {
        let identity = try createCASignedIdentity()
        let authenticator = try authenticatorWithRootCerts()
        let collections = try collectionConfig()

        // tag::multipeer-config-transports-default[]
        // Wi-Fi is the default transport. No additional configuration is required.
        let config = MultipeerReplicatorConfiguration(
            peerGroupID: "com.myapp",
            identity: identity,
            authenticator: authenticator,
            collections: collections)
        // config.transports defaults to [.wifi]
        // end::multipeer-config-transports-default[]
        return config
    }

    func createConfigTransportsBoth() throws -> MultipeerReplicatorConfiguration {
        let identity = try createCASignedIdentity()
        let authenticator = try authenticatorWithRootCerts()
        let collections = try collectionConfig()

        // tag::multipeer-config-transports-both[]
        var config = MultipeerReplicatorConfiguration(
            peerGroupID: "com.myapp",
            identity: identity,
            authenticator: authenticator,
            collections: collections)
        config.transports = [.wifi, .bluetooth]
        // end::multipeer-config-transports-both[]
        return config
    }

    func createConfigTransportsBluetoothOnly() throws -> MultipeerReplicatorConfiguration {
        let identity = try createCASignedIdentity()
        let authenticator = try authenticatorWithRootCerts()
        let collections = try collectionConfig()

        // tag::multipeer-config-transports-bluetooth-only[]
        var config = MultipeerReplicatorConfiguration(
            peerGroupID: "com.myapp",
            identity: identity,
            authenticator: authenticator,
            collections: collections)
        config.transports = [.bluetooth]
        // end::multipeer-config-transports-bluetooth-only[]
        return config
    }

    func statusListener() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-status-listener[]
        let token = replicator.addStatusListener { status in
            // transport is nil for the aggregated overall status;
            // non-nil for a per-transport status update.
            let transport = status.transport.map { $0 == .wifi ? "wifi" : "bluetooth" } ?? "all"
            let state = status.active ? "active" : "inactive"
            let error = status.error?.localizedDescription ?? "none"
            print("Multipeer Replicator [\(transport)]: \(state), Error: \(error)")
        }
        // end::multipeer-status-listener[]
        print(token)
    }


    func peerDiscoveryListener() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-peer-discovery-listener[]
        let token = replicator.addPeerDiscoveryStatusListener { status in
            let online = status.online ? "online" : "offline"
            let transport = status.transport == .wifi ? "wifi" : "bluetooth"
            print("Peer Discovery Status - Peer ID: \(status.peerID), " +
                  "Transport: \(transport), Status: \(online)")
        }
        // end::multipeer-peer-discovery-listener[]
        print(token)
    }

    func peerReplicatorStatus() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-replicator-status-listener[]
        let activities = ["stopped", "offline", "connecting", "idle", "busy"]
        let token = replicator.addPeerReplicatorStatusListener { replStatus in
            let direction = replStatus.outgoing ? "outgoing" : "incoming"
            let activity = activities[Int(replStatus.status.activity.rawValue)]
            let transport = replStatus.transport == .wifi ? "wifi" : "bluetooth"
            let error = replStatus.status.error?.localizedDescription ?? "none"
            print("Peer Replicator Status - Peer ID: \(replStatus.peerID), " +
                  "Transport: \(transport), " +
                  "Direction: \(direction), " +
                  "Activity: \(activity), " +
                  "Error: \(error)")
        }
        // end::multipeer-replicator-status-listener[]
        print(token)
    }

    func peerDocumentReplication() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-document-replication-listener[]
        let token = replicator.addPeerDocumentReplicationListener { docRepl in
            let direction = docRepl.isPush ? "Push" : "Pull"
            let transport = docRepl.transport == .wifi ? "wifi" : "bluetooth"
            print("Peer Document Replication - Peer ID: \(docRepl.peerID), " +
                  "Transport: \(transport), Direction: \(direction)")
            docRepl.documents.forEach { doc in
                let error = doc.error?.localizedDescription ?? "none"
                let collection = "\(doc.scope).\(doc.collection)"
                print(" Collection: \(collection)" +
                      " Document ID: \(doc.id)," +
                      " Flags: \(doc.flags)," +
                      " Error: \(error)")
            }
        }
        // end::multipeer-document-replication-listener[]
        print(token)
    }

    func peerInfo() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-peer-info[]
        let activities = ["stopped", "offline", "connecting", "idle", "busy"]

        let printPeerInfo: (PeerInfo) -> Void = { info in
            print("Peer ID: \(info.peerID)")
            print(" Status: \(info.online ? "online" : "offline")")

            // transports: the set of transports on which this peer was discovered.
            let transports = info.transports.map { $0 == .wifi ? "wifi" : "bluetooth" }.joined(separator: ", ")
            print(" Discovered on: \(transports)")

            // replicatorTransport: the transport currently used for replication,
            // or nil if replication is not active.
            let replicatorTransport = info.replicatorTransport.map { $0 == .wifi ? "wifi" : "bluetooth" } ?? "none"
            print(" Replicating on: \(replicatorTransport)")

            print(" Neighbor Peers:")
            info.neighborPeers.forEach { peerID in
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

    }
        // end::multipeer-peer-info[]

    func createMultipeerReplicator() throws -> MultipeerReplicator {
        let config = try createConfig()
        // tag::multipeer-replicator[]
        let replicator = try MultipeerReplicator(config: config)
        // end::multipeer-replicator[]
        return replicator
    }

    func startReplicator() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-replicator-start[]
        replicator.start()
        // end::multipeer-replicator-start[]
    }

    func stopReplicator() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-replicator-stop[]
        replicator.stop()
        // end::multipeer-replicator-stop[]
    }

    func peerID() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-peer-id[]
        let peerID = replicator.peerID
        print("Peer ID: \(peerID)")
        // end::multipeer-peer-id[]
    }

    func neighborPeers() throws {
        let replicator = try createMultipeerReplicator()
        // tag::multipeer-neighbor-peers[]
        print("Neighbor Peers:")
        replicator.neighborPeers.forEach { peerID in
            print(" \(peerID)")
        }
        // end::multipeer-neighbor-peers[]
    }


    func logging() throws {
        // tag::multipeer-logdomain[]
        // Enable verbose console logging for multipeer replicator-related domains only.
        LogSinks.console = ConsoleLogSink(level: .verbose, domains: [.peerDiscovery, .multipeer])
        // end::multipeer-logdomain[]
    }
}
