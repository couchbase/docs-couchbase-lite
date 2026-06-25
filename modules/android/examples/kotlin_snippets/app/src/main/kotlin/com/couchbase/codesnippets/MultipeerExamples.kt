package com.couchbase.codesnippets

import android.util.Log
import com.couchbase.lite.Database
import com.couchbase.lite.KeyUsage
import com.couchbase.lite.LogDomain
import com.couchbase.lite.LogLevel
import com.couchbase.lite.MultipeerCertificateAuthenticator
import com.couchbase.lite.MultipeerCollectionConfiguration
import com.couchbase.lite.MultipeerReplicator
import com.couchbase.lite.MultipeerReplicatorConfiguration
import com.couchbase.lite.PeerInfo
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.logging.ConsoleLogSink
import com.couchbase.lite.logging.LogSinks
import java.io.ByteArrayInputStream
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.Calendar
import java.util.Date

@Suppress("PropertyName")
class MultipeerExamples {
    companion object {
        private const val TAG = "MultipeerExamples"
    }

    val _database: Database? = null
    val _collection1: com.couchbase.lite.Collection? = null
    val _collection2: com.couchbase.lite.Collection? = null
    val _collection3: com.couchbase.lite.Collection? = null

    private fun getCAPrivateKeyData() : ByteArray {
        return "your_base64_encoded_private_key".toByteArray(Charsets.US_ASCII)
    }

    private fun getCACertificateData() : ByteArray {
        return "your_base64_encoded_certificate".toByteArray(Charsets.US_ASCII)
    }

    fun collectionSimple() : Set<MultipeerCollectionConfiguration> {
        val collection1 = _collection1!!
        val collection2 = _collection2!!
        val collection3 = _collection3!!

        // tag::multipeer-collection-simple[]
        val collections = mutableSetOf<MultipeerCollectionConfiguration>()
        for(col in listOf(collection1, collection2, collection3)) {
            val builder = MultipeerCollectionConfiguration.Builder(col)
            collections.add(builder.build())
        }
        // end::multipeer-collection-simple[]

        return collections
    }

    fun collectionConfig() : Set<MultipeerCollectionConfiguration> {
        val collection1 = _collection1!!
        val collection2 = _collection2!!
        val collection3 = _collection3!!

        // tag::multipeer-collection-config[]

        // Config with custom conflict resolver
        val config1 = MultipeerCollectionConfiguration.Builder(collection1)
            .setConflictResolver { peerId, conflict -> conflict.remoteDocument }
            .build()

        // Config with document IDs filter
        val config2 = MultipeerCollectionConfiguration.Builder(collection2)
            .setDocumentIDs(setOf("doc1", "doc2"))
            .build()

        // Config with push replication filter
        val config3 = MultipeerCollectionConfiguration.Builder(collection3)
            .setPushFilter { peerId, document, flags -> document.getInt("access-level") == 2 }
            .build()

        val collections = setOf(config1, config2, config3)
        // end::multipeer-collection-config[]

        return collections
    }

    fun createSelfSignedIdentity() : TLSIdentity {
        // tag::multipeer-selfsigned-tlsidentity[]
        // NOTE: Error handling omitted

        val persistentLabel = "com.myapp.identity"

        // Retrieve the TLS identity from the key store using the persistent label.
        var identity = TLSIdentity.getIdentity(persistentLabel)

        // If the identity exists but is expired, delete it.
        if(identity != null && identity.expiration.before(Date())) {
            TLSIdentity.deleteIdentity(persistentLabel)
        }

        if(identity == null) {
            // Define certificate attributes and expiration date.
            val certAttributes = mapOf(
                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
            )

            val calendar = Calendar.getInstance()
            calendar.add(Calendar.YEAR, 2)
            val expiration = calendar.time

            identity = TLSIdentity.createIdentity(
                setOf(KeyUsage.CLIENT_AUTH, KeyUsage.SERVER_AUTH),
                certAttributes,
                expiration,
                persistentLabel
            )
        }
        // end::multipeer-selfsigned-tlsidentity[]

        return identity
    }

    fun createCASignedIdentity() : TLSIdentity {
        // tag::multipeer-tlsidentity[]
        // NOTE: Error handling omitted

        val persistentLabel = "com.myapp.identity"

        // Retrieve the TLS identity from the key store using the persistent label.
        var identity = TLSIdentity.getIdentity(persistentLabel)

        // If the identity exists but is expired, delete it.
        if(identity != null && identity.expiration.before(Date())) {
            // NOTE: Important to delete identity this way for CA signed identities
            // since they extend beyond the Android key store
            TLSIdentity.deleteIdentity(persistentLabel)
        }

        if(identity == null) {
            // Define certificate attributes and expiration date.
            val certAttributes = mapOf(
                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
            )

            val calendar = Calendar.getInstance()
            calendar.add(Calendar.YEAR, 2)
            val expiration = calendar.time

            val caKey = getCAPrivateKeyData()
            val caCert = getCACertificateData()

            // As the function name indicates, this is not a secure way of doing things
            // and should either be done for testing only, or in an environment that you
            // assure to be secure against unknown actors, because otherwise anyone who
            // can install the app can probably easily extract the CA key.
            identity = TLSIdentity.createdSignedIdentityInsecure(
                setOf(KeyUsage.SERVER_AUTH, KeyUsage.CLIENT_AUTH),
                certAttributes,
                caKey,
                caCert,
                expiration,
                persistentLabel
            )
        }
        // end::multipeer-tlsidentity[]

        return identity
    }

    fun authenticatorWithCallback() : MultipeerCertificateAuthenticator {
        // tag::multipeer-authenticator-callback[]
        // Use peer and certs to decide whether or not to allow (true) this peer
        // or reject (false)
        val authenticator = MultipeerCertificateAuthenticator { peer, certs -> true }
        // end::multipeer-authenticator-callback[]

        return authenticator
    }

    fun authenticatorWithRootCerts() : MultipeerCertificateAuthenticator {
        // tag::multipeer-authenticator-rootcerts[]
        val caCert = getCACertificateData()
        val certificateFactory = CertificateFactory.getInstance("X.509")
        val inputStream = ByteArrayInputStream(caCert)
        val certObject = certificateFactory.generateCertificate(inputStream) as X509Certificate
        val authenticator = MultipeerCertificateAuthenticator(listOf(certObject))
        // end::multipeer-authenticator-rootcerts[]

        return authenticator
    }

    fun createConfig() : MultipeerReplicatorConfiguration {
        val identity = createCASignedIdentity()
        val authenticator = authenticatorWithRootCerts()
        val collections = collectionConfig()

        // tag::multipeer-config[]
        val config = MultipeerReplicatorConfiguration.Builder()
            .setPeerGroupID("com.myapp")
            .setIdentity(identity)
            .setAuthenticator(authenticator)
            .setCollections(collections)
            .build()
        // end::multipeer-config[]

        return config
    }


    fun createMultipeerReplicator() : MultipeerReplicator {
        val config = createConfig()

        // tag::multipeer-replicator[]
        val replicator = MultipeerReplicator(config)
        // end::multipeer-replicator[]

        return replicator
    }

    fun startReplicator() {
        val replicator = createMultipeerReplicator()
        // tag::multipeer-replicator-start[]
        replicator.start()
        // end::multipeer-replicator-start[]
    }

    fun stopReplicator() {
        val replicator = createMultipeerReplicator()
        // tag::multipeer-replicator-stop[]
        replicator.stop()
        // end::multipeer-replicator-stop[]
    }

    fun statusListener() {
        val replicator = createMultipeerReplicator()

        // tag::multipeer-status-listener[]
        val token = replicator.addStatusListener { status ->
            val state = if(status.isActive) "active" else "inactive"
            val error = status.error?.message ?: "none"
            Log.i(TAG, "Multipeer replicator: $state, Error: $error")
        }
        // end::multipeer-status-listener[]
    }

    fun peerDiscoveryListener() {
        val replicator = createMultipeerReplicator()

        // tag::multipeer-peer-discovery-listener[]
        val token = replicator.addPeerDiscoveryStatusListener { status ->
            val online = if(status.isOnline) "online" else "offline"
            Log.i(TAG, "Peer Discovery Status - Peer ID: ${status.peer}, Status: $online")
        }
        // end::multipeer-peer-discovery-listener[]
    }

    fun peerReplicatorStatus()  {
        val replicator = createMultipeerReplicator()
        // tag::multipeer-replicator-status-listener[]
        //val activities = ["stopped", "offline", "connecting", "idle", "busy"]
        val token = replicator.addPeerReplicatorStatusListener { status ->
            val direction = if(status.isOutgoing) "outgoing" else "incoming"
            val activity = status.status.activityLevel.name.lowercase()
            val error = status.status.error?.message ?: "none"
            Log.i(TAG, "Peer Replicator Status - Peer ID: $status, " +
                    "Direction: $direction, " +
                    "Activity: $activity" +
                    "Error: $error")
        }
        // end::multipeer-replicator-status-listener[]
    }

    fun peerDocumentReplication() {
        val replicator = createMultipeerReplicator()

        // tag::multipeer-document-replication-listener[]
        val token = replicator.addPeerDocumentReplicationListener { status ->
            val direction = if(status.isPush) "push" else "pull"
            Log.i(TAG, "Peer Document Replication - Peer ID: ${status.peer}, Direction: $direction")
            for(doc in status.documents) {
                val error = doc.error?.message ?: "none"
                val collection = "${doc.scope}.${doc.collection}"
                Log.i(TAG, " Collection: $collection, Document ID: ${doc.id}, " +
                        "Flags: ${doc.flags}, Error: $error")
            }
        }
        // end::multipeer-document-replication-listener[]
    }

    fun peerID() {
        val replicator = createMultipeerReplicator()

        // tag::multipeer-peer-id[]
        val peerID = replicator.peerId
        Log.i(TAG, "Peer ID: $peerID")
        // end::multipeer-peer-id[]
    }

    fun neighborPeers() {
        val replicator = createMultipeerReplicator()

        // tag::multipeer-neighbor-peers[]
        Log.i(TAG, "Neighbor Peers:")
        replicator.neighborPeers.forEach { peer -> Log.i(TAG, " $peer") }
        // end::multipeer-neighbor-peers[]
    }

    fun peerInfo() {
        val replicator = createMultipeerReplicator()

        // tag::multipeer-peer-info[]
        fun printPeerInfo(info: PeerInfo) {
            Log.i(TAG, "Peer ID: ${info.peerId}")
            Log.i(TAG, " Status: ${if(info.isOnline) "online" else "offline"}")
            Log.i(TAG, " Neighbor Peers:")
            info.neighbors.forEach { peer -> Log.i(TAG, " $peer") }

            val replStatus = info.replicatorStatus
            val activity = replStatus.activityLevel.name.lowercase()
            val error = replStatus.error?.message ?: "none"
            Log.i(TAG, " Replicator Status: $activity, Error: $error")
        }

        for(peer in replicator.neighborPeers) {
            printPeerInfo(replicator.getPeerInfo(peer))
        }
        // end::multipeer-peer-info[]
    }

    fun logging() {
        // tag::multipeer-logdomain[]
        // Enable verbose console logging for multipeer replicator-related domains only.
        LogSinks.get().console = ConsoleLogSink(LogLevel.VERBOSE, LogDomain.PEER_DISCOVERY,
            LogDomain.MULTIPEER)
        // end::multipeer-logdomain[]
    }
}