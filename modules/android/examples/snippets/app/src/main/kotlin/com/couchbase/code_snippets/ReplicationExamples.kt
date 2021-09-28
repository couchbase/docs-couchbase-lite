//
// Copyright (c) 2021 Couchbase, Inc All rights reserved.
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
package com.couchbase.code_snippets

import android.util.Log
import com.couchbase.lite.*
import com.couchbase.lite.internal.utils.PlatformUtils
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.URI
import java.net.URISyntaxException


private const val TAG = "REPLICATION"

@Throws(IOException::class)
fun InputStream.toByteArray(): ByteArray {
    val buffer = ByteArray(1024)
    val output = ByteArrayOutputStream()

    var n: Int
    while (-1 < this.read(buffer).also { n = it }) {
        output.write(buffer, 0, n)
    }

    return output.toByteArray()
}

// tag::update-document-with-conflict-handler-callouts[]
//
//        <.> The conflict handler code is provided as a lambda.
//
//        <.> If the handler cannot resolve a conflict, it can return false.
//        In this case, the save method will cancel the save operation and return false the same way as using the save() method with the failOnConflict concurrency control.
//
//        <.> Within the conflict handler, you can modify the document parameter which is the same instance of Document that is passed to the save() method. So in effect, you will be directly modifying the document that is being saved.
//
//        <.> When handling is done, the method must return true (for  successful resolution) or false (if it was unable to resolve the conflict).
//
//        <.> If there is an exception thrown in the handle() method, the exception will be caught and re-thrown in the save() method
// end::update-document-with-conflict-handler-callouts[]


// tag::local-win-conflict-resolver[]
// Using replConfig.setConflictResolver(new LocalWinConflictResolver());
@Suppress("unused")
object LocalWinsResolver : ConflictResolver {
    override fun resolve(conflict: Conflict) = conflict.localDocument
}
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
// Using replConfig.setConflictResolver(new RemoteWinConflictResolver());
@Suppress("unused")
object RemoteWinsResolver : ConflictResolver {
    override fun resolve(conflict: Conflict) = conflict.remoteDocument
}
// end::remote-win-conflict-resolver[]

// tag::merge-conflict-resolver[]
// Using replConfig.setConflictResolver(new MergeConflictResolver());
@Suppress("unused")
object MergeConflictResolver : ConflictResolver {
    override fun resolve(conflict: Conflict): Document {
        val localDoc = conflict.localDocument?.toMap()
        val remoteDoc = conflict.remoteDocument?.toMap()

        val merge: MutableMap<String, Any>?
        if (localDoc == null) {
            merge = remoteDoc
        } else {
            merge = localDoc
            if (remoteDoc != null) {
                merge.putAll(remoteDoc)
            }
        }

        return if (merge == null) {
            MutableDocument(conflict.documentId)
        } else {
            MutableDocument(conflict.documentId, merge)
        }
    }
// end::merge-conflict-resolver[]

    @Suppress("unused")
    class ReplicationExamples(private val database: Database) {
        private var replicator: Replicator? = null

        @Throws(URISyntaxException::class)
        fun testReplicationBasicAuthentication() {
            // tag::basic-authentication[]

            // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                    authenticator = BasicAuthenticator("username", "password".toCharArray())
                )
            )
            repl.start()
            replicator = repl
            // end::basic-authentication[]
        }

        @Throws(URISyntaxException::class)
        fun testReplicationSessionAuthentication() {
            // tag::session-authentication[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                    authenticator = SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447")
                )
            )
            repl.start()
            replicator = repl
            // end::session-authentication[]
        }

        @Throws(URISyntaxException::class)
        fun testReplicationStatus() {
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/db")),
                    type = ReplicatorType.PULL
                )
            )

            repl.addChangeListener { change ->
                if (change.status.activityLevel == ReplicatorActivityLevel.STOPPED) {
                    Log.i(TAG, "Replication stopped")
                }
            }

            repl.start()
            replicator = repl
            // end::replication-status[]
        }

        @Throws(URISyntaxException::class)
        fun testHandlingNetworkErrors() {
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/db"))
                )
            )

            // tag::replication-error-handling[]
            repl.addChangeListener { change ->
                change.status.error?.let {
                    Log.w(TAG, "Error code: ${it.code}")
                }
            }
            repl.start()
            replicator = repl
            // end::replication-error-handling[]

            repl.stop()
        }

        @Throws(URISyntaxException::class)
        fun testReplicatorDocumentEvent() {
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/db"))
                )
            )

            // tag::add-document-replication-listener[]
            val token = repl.addDocumentReplicationListener { replication ->
                Log.i(TAG, "Replication type: ${if (replication.isPush) "push" else "pull"}")

                for (document in replication.documents) {
                    document.let { doc ->
                        Log.i(TAG, "Doc ID: ${document.id}")
                        doc.error?.let {
                            // There was an error
                            Log.e(TAG, "Error replicating document: ", it)
                            return@addDocumentReplicationListener
                        }
                        if (doc.flags.contains(DocumentFlag.DELETED)) {
                            Log.i(TAG, "Successfully replicated a deleted document")
                        }
                    }
                }
            }

            repl.start()
            replicator = repl
            // end::add-document-replication-listener[]

            // tag::remove-document-replication-listener[]
            repl.removeChangeListener(token)
            // end::remove-document-replication-listener[]
        }

        @Throws(URISyntaxException::class)
        fun testReplicationCustomHeader() {
            // tag::replication-custom-header[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/db")),
                    headers = mapOf("CustomHeaderName" to "Value")
                )
            )
            replicator = repl
            // end::replication-custom-header[]
        }

        // ### Certificate Pinning
        @Throws(URISyntaxException::class, IOException::class)
        fun testCertificatePinning() {
            // tag::certificate-pinning[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/db")),
                    headers = mapOf("CustomHeaderName" to "Value"),
                    pinnedServerCertificate = PlatformUtils.getAsset("cert.cer")?.toByteArray()
                )
            )
            replicator = repl
            // end::certificate-pinning[]
        }

        // ### Reset replicator checkpoint
        @Throws(URISyntaxException::class)
        // tag::replication-startup[]
        fun testReplicationResetCheckpoint() {
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/db")),
                    type = ReplicatorType.PULL
                )
            )

            // tag::replication-reset-checkpoint[]
            repl.start(resetCheckpoint = resetCheckpointRequired_Example) // <.>
            // end::replication-reset-checkpoint[]

            // ... at some later time

            repl.stop()
            // end::replication-startup[]

        }

        @Throws(URISyntaxException::class)
        fun testReplicationPushFilter() {
            // tag::replication-push-filter[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                    pushFilter = { _, flags -> flags.contains(DocumentFlag.DELETED) } // <1>
                )
            )

            // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
            repl.start()
            replicator = repl
            // end::replication-push-filter[]
        }

        @Throws(URISyntaxException::class)
        fun testReplicationPullFilter() {
            // tag::replication-pull-filter[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                    pushFilter = { document, _ -> "draft" == document.getString("type") } // <1>
                )
            )

            // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
            repl.start()
            replicator = repl
            // end::replication-pull-filter[]
        }

        @Throws(URISyntaxException::class)
        fun testCustomRetryConfig() {
            // tag::replication-retry-config[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database,
                    target = URLEndpoint(URI("ws://localhost:4984/mydatabase")),
                    //  other config params as required . .
                    // tag::replication-heartbeat-config[]
                    heartbeat = 150, // <1>
                    // end::replication-heartbeat-config[]
                    // tag::replication-maxattempts-config[]
                    maxAttempts = 20,
                    // end::replication-maxattempts-config[]
                    maxAttemptWaitTime = 600
                    // end::replication-maxattemptwaittime-config[]
                )
            )

            repl.start()
            replicator = repl
            // end::replication-retry-config[]
        }

        @Throws(CouchbaseLiteException::class)
        fun testDatabaseReplica() {
            val config = DatabaseConfiguration()
            val database1 = Database("mydb", config)
            val database2 = Database("db2", config)

            /* EE feature: code below might throw a compilation error
               if it's compiled against CBL Android Community. */
            // tag::database-replica[]
            val repl = Replicator(
                ReplicatorConfigurationFactory.create(
                    database = database1,
                    target = DatabaseEndpoint(database2),
                    type = ReplicatorType.PULL
                )
            )

            // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
            repl.start()
            replicator = repl
            // end::database-replica[]
        }

        @Throws(URISyntaxException::class)
        fun testReplicationWithCustomConflictResolver() {
            // tag::replication-conflict-resolver[]
            val target = URLEndpoint(URI("ws://localhost:4984/mydatabase"))
            val config = ReplicatorConfiguration(database, target)
            config.conflictResolver = LocalWinConflictResolver()
            val replication = Replicator(config)
            replication.start()
            // end::replication-conflict-resolver[]
        }

        @Throws(CouchbaseLiteException::class)
        fun testSaveWithCustomConflictResolver() {
            // tag::update-document-with-conflict-handler[]
            val mutableDocument = database.getDocument("xyz")?.toMutable() ?: return
            mutableDocument.setString("name", "apples")
            database.save(mutableDocument) { newDoc, curDoc ->  // <.>
                if (curDoc == null) {
                    return@save false
                } // <.>
                val dataMap: MutableMap<String, Any> = curDoc.toMap()
                dataMap.putAll(newDoc.toMap()) // <.>
                newDoc.setData(dataMap)
                true // <.>
            } // <.>
            // end::update-document-with-conflict-handler[]
        }
    }
}
