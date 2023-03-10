//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
@file:Suppress("UNUSED_VARIABLE", "unused", "UNUSED_PARAMETER")

package com.couchbase.codesnippets

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.ClientCertificateAuthenticator
import com.couchbase.lite.Collection
import com.couchbase.lite.CollectionConfigurationFactory
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.DatabaseEndpoint
import com.couchbase.lite.DocumentFlag
import com.couchbase.lite.Endpoint
import com.couchbase.lite.ListenerToken
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.SessionAuthenticator
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.newConfig
import java.net.URI
import java.security.KeyStore
import java.security.cert.X509Certificate


class ReplicationExamples {
    private var thisReplicator: Replicator? = null
    private var thisToken: ListenerToken? = null

    fun activeReplicatorExample(collections: Set<Collection>) {
        // tag::p2p-act-rep-start-full[]
        // Create replicator
        // Consider holding a reference somewhere
        // to prevent the Replicator from being GCed
        val repl = Replicator( // <.>

            // tag::p2p-act-rep-func[]
            // tag::p2p-act-rep-initialize[]
            // initialize the replicator configuration
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("wss://listener.com:8954")), // <.>

                collections = mapOf(collections to null),

                // end::p2p-act-rep-initialize[]
                // tag::p2p-act-rep-config-type[]
                // Set replicator type
                type = ReplicatorType.PUSH_AND_PULL,

                // end::p2p-act-rep-config-type[]
                // tag::p2p-act-rep-config-cont[]
                // Configure Sync Mode
                continuous = false, // default value

                // end::p2p-act-rep-config-cont[]

                // tag::autopurge-override[]
                // set auto-purge behavior
                // (here we override default)
                enableAutoPurge = false, // <.>

                // end::autopurge-override[]

                // tag::p2p-act-rep-config-self-cert[]
                // Configure Server Authentication --
                // only accept self-signed certs
                acceptOnlySelfSignedServerCertificate = true, // <.>

                // end::p2p-act-rep-config-self-cert[]

                // tag::p2p-act-rep-auth[]
                // Configure the credentials the
                // client will provide if prompted
                authenticator = BasicAuthenticator("PRIVUSER", "let me in".toCharArray())  // <.>

                // end::p2p-act-rep-auth[]
            )
        )

        // tag::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-add-change-listener-label[]
        // Optionally add a change listener <.>
        // end::p2p-act-rep-add-change-listener-label[]
        val token = repl.addChangeListener { change ->
            val err: CouchbaseLiteException? = change.status.error
            if (err != null) {
                log("Error code ::  ${err.code}", err)
            }
        }

        // end::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-start[]
        // Start replicator
        repl.start(false) // <.>

        // end::p2p-act-rep-start[]

        thisReplicator = repl
        thisToken = token

        // end::p2p-act-rep-start-full[]
        // end::p2p-act-rep-func[]
    }

    fun replicationBasicAuthenticationExample(collections: Set<Collection>) {
        // tag::basic-authentication[]

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null),
                authenticator = BasicAuthenticator("username", "password".toCharArray())
            )
        )
        repl.start()
        thisReplicator = repl
        // end::basic-authentication[]
    }

    fun replicationSessionAuthenticationExample(collections: Set<Collection>) {
        // tag::session-authentication[]
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null),
                authenticator = SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447")
            )
        )
        repl.start()
        thisReplicator = repl
        // end::session-authentication[]
    }

    fun replicationCustomHeaderExample(collections: Set<Collection>) {
        // tag::replication-custom-header[]
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null),
                headers = mapOf("CustomHeaderName" to "Value")
            )
        )
        repl.start()
        thisReplicator = repl
        // end::replication-custom-header[]
    }

    fun testReplicationPushFilter(collections: Set<Collection>) {
        // tag::replication-push-filter[]
        val collectionConfig = CollectionConfigurationFactory.newConfig(
            pushFilter = { _, flags -> flags.contains(DocumentFlag.DELETED) } // <1>
        )

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to collectionConfig)
            )
        )
        repl.start()
        thisReplicator = repl
        // end::replication-push-filter[]
    }

    fun replicationPullFilterExample(collections: Set<Collection>) {
        // tag::replication-pull-filter[]
        val collectionConfig = CollectionConfigurationFactory.newConfig(
            pullFilter = { document, _ -> "draft" == document.getString("type") } // <1>
        )

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to collectionConfig)
            )
        )
        repl.start()
        thisReplicator = repl
        // end::replication-pull-filter[]
    }

    // ### Reset replicator checkpoint
    fun replicationResetCheckpointExample(collections: Set<Collection>) {
        // tag::replication-startup[]
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null)
            )
        )

        // tag::replication-reset-checkpoint[]
        repl.start(true)
        // end::replication-reset-checkpoint[]

        // ... at some later time

        repl.stop()
        // end::replication-startup[]
    }

    fun handlingNetworkErrorExample(collections: Set<Collection>) {
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null)
            )
        )

        // tag::replication-error-handling[]
        repl.addChangeListener { change ->
            change.status.error?.let {
                log("Error code: ${it.code}")
            }
        }
        repl.start()
        thisReplicator = repl
        // end::replication-error-handling[]
    }

    // ### Certificate Pinning
    fun certificatePinningExample(collections: Set<Collection>, keyStoreName: String, certAlias: String) {
        // tag::certificate-pinning[]
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null),
                pinnedServerCertificate = KeyStore.getInstance(keyStoreName)
                    .getCertificate(certAlias) as X509Certificate
            )
        )
        repl.start()
        thisReplicator = repl
        // end::certificate-pinning[]
    }

    fun replicatorConfigExample(collections: Set<Collection>) {
        // tag::sgw-act-rep-initialize[]
        // initialize the replicator configuration
        val thisConfig = ReplicatorConfigurationFactory.newConfig(
            target = URLEndpoint(URI("wss://10.0.2.2:8954/travel-sample")), // <.>
            collections = mapOf(collections to null)
        )
        // end::sgw-act-rep-initialize[]
    }

    fun p2pReplicatorStatusExample(repl: Replicator) {
        // tag::p2p-act-rep-status[]
        repl.status.let {
            val progress = it.progress
            log(
                "The Replicator is ${
                    it.activityLevel
                } and has processed ${
                    progress.completed
                } of ${progress.total} changes"
            )
        }
        // end::p2p-act-rep-status[]
    }

    fun p2pReplicatorStopExample(repl: Replicator) {
        // tag::p2p-act-rep-stop[]
        // Stop replication.
        repl.stop() // <.>
        // end::p2p-act-rep-stop[]
    }

    fun testCustomRetryConfig(collections: Set<Collection>) {
        // tag::replication-retry-config[]
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null),
                //  other config params as required . .
                // tag::replication-heartbeat-config[]
                heartbeat = 150, // <1>
                // end::replication-heartbeat-config[]
                // tag::replication-maxattempts-config[]
                maxAttempts = 20,
                // end::replication-maxattempts-config[]
                // tag::replication-maxattemptwaittime-config[]
                maxAttemptWaitTime = 600
                // end::replication-maxattemptwaittime-config[]
            )
        )
        repl.start()
        thisReplicator = repl
        // end::replication-retry-config[]
    }

    fun replicatorDocumentEventExample(collections: Set<Collection>) {
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(collections to null),
            )
        )

        // tag::add-document-replication-listener[]
        val token = repl.addDocumentReplicationListener { replication ->
            log("Replication type: ${if (replication.isPush) "push" else "pull"}")

            for (document in replication.documents) {
                document.let { doc ->
                    log("Doc ID: ${document.id}")

                    doc.error?.let {
                        // There was an error
                        log("Error replicating document: ", it)
                        return@addDocumentReplicationListener
                    }

                    if (doc.flags.contains(DocumentFlag.DELETED)) {
                        log("Successfully replicated a deleted document")
                    }
                }
            }
        }

        repl.start()
        thisReplicator = repl
        // end::add-document-replication-listener[]

        // tag::remove-document-replication-listener[]
        token.remove()
        // end::remove-document-replication-listener[]
    }

    private fun replicationPendingDocumentsExample(collection: Collection) {
        // tag::replication-pendingdocuments[]
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(setOf(collection) to null),
                type = ReplicatorType.PUSH
            )
        )

        // tag::replication-push-pendingdocumentids[]
        val pendingDocs = repl.getPendingDocumentIds(collection)
        // end::replication-push-pendingdocumentids[]

        // iterate and report on previously
        // retrieved pending docids 'list'
        if (pendingDocs.isNotEmpty()) {
            log("There are ${pendingDocs.size} documents pending")

            val firstDoc = pendingDocs.first()
            repl.addChangeListener { change ->
                log("Replicator activity level is ${change.status.activityLevel}")
                // tag::replication-push-isdocumentpending[]
                try {
                    if (!repl.isDocumentPending(firstDoc, collection)) {
                        log("Doc ID ${firstDoc} has been pushed")
                    }
                } catch (err: CouchbaseLiteException) {
                    log("Failed getting pending docs", err)
                }
                // end::replication-push-isdocumentpending[]
            }

            repl.start()
            thisReplicator = repl
        }
        // end::replication-pendingdocuments[]
    }

    fun collectionReplicationExample(srcCollections: Set<Collection>, targetDb: Database) {
        // tag::database-replica[]
        // This is an Enterprise feature:
        // the code below will generate a compilation error
        // if it's compiled against CBL Android Community Edition.
        // Note: the target database must already contain the
        //       source collections or the replication will fail.
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = DatabaseEndpoint(targetDb),
                collections = mapOf(srcCollections to null),
                type = ReplicatorType.PUSH
            )
        )

        // Start the replicator
        // (be sure to hold a reference somewhere that will prevent it from being GCed)
        repl.start()
        thisReplicator = repl
        // end::database-replica[]
    }

    fun replicatorConfigurationExample(srcCollections: Set<Collection>, targetUrl: URI) {
        // tag::p2p-act-rep-config-tls-full[]
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(targetUrl),

                collections = mapOf(srcCollections to null),

                // tag::p2p-act-rep-config-cacert[]
                // Configure Server Security
                // -- only accept CA attested certs
                acceptOnlySelfSignedServerCertificate = false, // <.>

                // end::p2p-act-rep-config-cacert[]

                // tag::p2p-act-rep-config-cacert-pinned[]
                // Use the pinned certificate from the byte array (cert)
                pinnedServerCertificate =
                TLSIdentity.getIdentity("Our Corporate Id")?.certs?.get(0) as? X509Certificate // <.>
                    ?: throw IllegalStateException("Cannot find corporate id"),
                // end::p2p-act-rep-config-cacert-pinned[]


                // end::p2p-act-rep-config-tls-full[]
                // tag::p2p-tlsid-tlsidentity-with-label[]
                // Provide a client certificate to the server for authentication
                authenticator = ClientCertificateAuthenticator(
                    TLSIdentity.getIdentity("clientId")
                        ?: throw IllegalStateException("Cannot find client id")
                ) // <.>

                // ... other replicator configuration
            )
        )

        thisReplicator = repl
        // end::p2p-tlsid-tlsidentity-with-label[]
    }

    fun ibReplicatorSimple(collections: Set<Collection>) {
        // tag::replicator-simple[]
        val theListenerEndpoint: Endpoint = URLEndpoint(URI("wss://10.0.2.2:4984/db")) // <.>
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                collections = mapOf(collections to null),
                target = theListenerEndpoint,
                authenticator = BasicAuthenticator("valid.user", "valid.password.string".toCharArray()), // <.>
                acceptOnlySelfSignedServerCertificate = true
            )
        )
        repl.start() // <.>
        thisReplicator = repl
        // end::replicator-simple[]
    }

    fun testReplicationWithCustomConflictResolver(srcCollections: Set<Collection>) {
        // tag::replication-conflict-resolver[]

        val collectionConfig = CollectionConfigurationFactory.newConfig(conflictResolver = LocalWinsResolver)
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                collections = mapOf(srcCollections to collectionConfig)
            )
        )

        // Start the replicator
        // (be sure to hold a reference somewhere that will prevent it from being GCed)
        repl.start()
        thisReplicator = repl
        // end::replication-conflict-resolver[]
    }
}

/* C A L L O U T S

// Listener Callouts

// tag::listener-callouts-full[]

// tag::listener-start-callouts[]
<.> Initialize the listener instance using the configuration settings.
<.> Start the listener, ready to accept connections and incoming data from active peers.

// end::listener-start-callouts[]

// tag::listener-status-check-callouts[]

<.> `connectionCount` -- the total number of connections served by the listener
<.> `activeConnectionCount` -- the number of active (BUSY) connections currently being served by the listener
//
// end::listener-status-check-callouts[]

// end::listener-callouts-full[]


// tag::p2p-act-rep-config-cacert-pinned-callouts[]
<.> Configure the pinned certificate using data from the byte array `cert`
// end::p2p-act-rep-config-cacert-pinned-callouts[]

// tag::p2p-tlsid-tlsidentity-with-label-callouts[]
<.> Attempt to get the identity from secure storage
<.> Set the authenticator to ClientCertificateAuthenticator and configure it to use the retrieved identity

// end::p2p-tlsid-tlsidentity-with-label-callouts[]

// tag::sgw-repl-pull-callouts[]
<.> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<.> The URL scheme for remote database URLs uses `ws:`, or `wss:` for SSL/TLS connections over wb sockets.
In this example the hostname is `10.0.2.2` because the Android emulator runs in a VM that is generally accessible on `10.0.2.2` from the host machine (see https://developer.android.com/studio/run/emulator-networking[Android Emulator networking] documentation).
+
NOTE: As of Android Pie, version 9, API 28, cleartext support is disabled, by default.
Although `wss:` protocol URLs are not affected, in order to use the `ws:` protocol, applications must target API 27 or lower, or must configure application network security as described https://developer.android.com/training/articles/security-config#CleartextTrafficPermitted[here].

// end::sgw-repl-pull-callouts[]
*/

