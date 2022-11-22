

// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/ReplicationExamples.kt 
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

            val resetCheckpointRequired_Example = false
            // tag::replication-reset-checkpoint[]
            repl.start(resetCheckpointRequired_Example) // <.>
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
            config.conflictResolver = LocalWinsResolver
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



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/ReplicationExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/BasicExamples.kt 
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

import android.content.Context
import android.util.Log
import android.widget.Toast
import com.couchbase.lite.*
import com.couchbase.lite.internal.utils.PlatformUtils
import org.junit.Test
import java.io.File
import java.io.IOException
import java.net.URI
import java.net.URISyntaxException
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.*


private const val TAG = "BASIC"

// tag::custom-logging[]
class LogTestLogger(private val level: LogLevel) : Logger {
    override fun getLevel() = level

    override fun log(level: LogLevel, domain: LogDomain, message: String) {
        // this method will never be called if param level < this.level
        // handle the message, for example piping it to a third party framework
    }
}

// end::custom-logging[]
// tag::example-app[]
@Suppress("unused")
class BasicExamples(private val context: Context) {
    private val database: Database

    init {
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        // Get the database (and create it if it doesn’t exist).
        // tag::database-config-factory[]
        database = Database(
          "getting-started",
          DatabaseConfigurationFactory.create(context.filesDir.absolutePath)
          )
        // end::database-config-factory[]
    }

    @Test
    @Throws(CouchbaseLiteException::class, URISyntaxException::class)
    fun testGettingStarted() {

        // !!! Note the code moved from here to the init { } above.
        // tag::getting-started[]
        // Create a new document (i.e. a record) in the database.
        var mutableDoc = MutableDocument().setFloat("version", 2.0f).setString("type", "SDK")

        // Save it to the database.
        database.save(mutableDoc)

        // Update a document.
        mutableDoc = database.getDocument(mutableDoc.id)!!.toMutable().setString("language", "Java")
        database.save(mutableDoc)

        val document = database.getDocument(mutableDoc.id)!!
        // Log the document ID (generated by the database) and properties
        Log.i(TAG, "Document ID :: ${document.id}")
        Log.i(TAG, "Learning ${document.getString("language")}")

        // Create a query to fetch documents of type SDK.
        val rs = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("SDK")))
            .execute()
        Log.i(TAG, "Number of rows :: ${rs.allResults().size}")

        // Create a replicator to push and pull changes to and from the cloud.
        // Be sure to hold a reference somewhere to prevent the Replicator from being GCed
        //  tag::replicator-config-factory[]
        val replicator =
          Replicator(
            ReplicatorConfigurationFactory.create(
              database = database,
              target = URLEndpoint(URI("ws://localhost:4984/getting-started-db")),
              type = ReplicatorType.PUSH_AND_PULL,
              authenticator = BasicAuthenticator("sync-gateway", "password".toCharArray())
              )
          )

        //  end::replicator-config-factory[]

        // Listen to replicator change events.
        replicator.addChangeListener { change ->
            val err = change.status.error
            if (err != null) Log.i(TAG, "Error code ::  ${err.code}")
        }

        // Start replication.
        replicator.start()

        // end::getting-started[]
        database.delete()
    }
    // end::example-app[]

    @Throws(CouchbaseLiteException::class, IOException::class)
    fun test1xAttachments() {
        // if db exist, delete it
        deleteDB("android-sqlite", context.filesDir)
        ZipUtils.unzip(
            PlatformUtils.getAsset("replacedb/android140-sqlite.cblite2.zip"),
            context.filesDir
        )

        val db = Database("android-sqlite")
        try {
            // For Validation
            Arrays.equals(
                "attach1".toByteArray(),
                db.getDocument("doc1")?.getDictionary("_attachments")?.getBlob("attach1")?.content
            )
        } finally {
            // close db
            db.close()
            // if db exist, delete it
            deleteDB("android-sqlite", context.filesDir)
        }
        val document = MutableDocument()

        // tag::1x-attachment[]
        val content = document.getDictionary("_attachments")?.getBlob("avatar")?.content
        // end::1x-attachment[]
    }

    // ### Initializer
    fun testInitializer() {
        // tag::sdk-initializer[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)
        // end::sdk-initializer[]
    }

    // ### New Database
    @Throws(CouchbaseLiteException::class)
    fun testNewDatabase() {
        // tag::new-database[]
        val database = Database(
            "my-db",
            DatabaseConfigurationFactory.create(
                context.filesDir.absolutePath
            )
        ) // <.>
        // end::new-database[]
        // tag::close-database[]
        database.close()

        // end::close-database[]

        database.delete()
    }

    // ### Database Encryption
    @Throws(CouchbaseLiteException::class)
    fun testDatabaseEncryption() {
        // tag::database-encryption[]
        val db = Database(
            "my-db",
            DatabaseConfigurationFactory.create(
                encryptionKey = EncryptionKey("PASSWORD")
            )
        )

        // end::database-encryption[]
    }

    // ### Logging
    // !!! OBSOLETE in 3.0
    fun testLogging() {
        // tag::logging[]
        // end::logging[]
    }

    fun testEnableCustomLogging() {
        // tag::set-custom-logging[]
        // this custom logger will not log an event with a log level < WARNING
        Database.log.custom = LogTestLogger(LogLevel.WARNING) // <.>
        // end::set-custom-logging[]
    }

    // ### Console logging
    @Throws(CouchbaseLiteException::class)
    fun testConsoleLogging() {
        // tag::console-logging[]
        Database.log.console.domains = LogDomain.ALL_DOMAINS // <.>
        Database.log.console.level = LogLevel.VERBOSE // <.>
        // end::console-logging[]

        // tag::console-logging-db[]
        Database.log.console.domains = EnumSet.of(LogDomain.DATABASE) // <.>
        // end::console-logging-db[]
    }

    // ### File logging
    @Throws(CouchbaseLiteException::class)
    fun testFileLogging() {
        // tag::file-logging[]
        // tag::file-logging-config-factory[]
        Database.log.file.let {
          it.config = LogFileConfigurationFactory.create(
            context.cacheDir.absolutePath, // <.>
            maxSize = 10240, // <.>
            maxRotateCount = 5, // <.>
            usePlainText = false
            ) // <.>
            it.level = LogLevel.INFO // <.>

            // end::file-logging[]
          }
        // end::file-logging-config-factory[]
    }

    fun writeConsoleLog() {
        // tag::write-console-logmsg[]
        Database.log.console.log(
            LogLevel.WARNING,
            LogDomain.REPLICATOR, "Any old log message"
        )
        // end::write-console-logmsg[]
    }

    fun writeCustomLog() {
        // tag::write-custom-logmsg[]
        Database.log.custom?.log(
            LogLevel.WARNING,
            LogDomain.REPLICATOR, "Any old log message"
        )
        // end::write-custom-logmsg[]
    }

    fun writeFileLog() {
        // tag::write-file-logmsg[]
        Database.log.file.log(
            LogLevel.WARNING,
            LogDomain.REPLICATOR, "Any old log message"
        )
        // end::write-file-logmsg[]
    }

    /* The `tag::replication[]` example is inlined in java.adoc */
    fun testTroubleshooting() {
        // tag::replication-logging[]
        Database.log.console.let {
            it.level = LogLevel.VERBOSE
            it.domains = LogDomain.ALL_DOMAINS
        }
        // end::replication-logging[]
    }

    // ### Loading a pre-built database
    @Throws(IOException::class)
    fun testPreBuiltDatabase() {
        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        // For Android you need to extract the database from your assets
        // to a temporary directory and then copy it, using Database.copy()
        if (Database.exists("travel-sample", context.filesDir)) {
            return
        }
        ZipUtils.unzip(PlatformUtils.getAsset("travel-sample.cblite2.zip"), context.filesDir)
        Database.copy(
            File(context.filesDir, "travel-sample"),
            "travel-sample",
            DatabaseConfiguration()
        )
        // end::prebuilt-database[]
    }

    // helper methods
    // if db exist, delete it
    fun deleteDB(name: String, dir: File) {
        // database exist, delete it
        if (Database.exists(name, dir)) {
            Database.delete(name, dir)
        }

        // ### Initializers
        fun testInitializers() {
            // tag::initializer[]
            val doc = MutableDocument()
            doc.let {
                it.setString("type", "task")
                it.setString("owner", "todo")
                it.setDate("createdAt", Date())
            }
            database.save(doc)
            // end::initializer[]
        }
    }

    // ### Mutability
    fun testMutability() {
        database.save(MutableDocument("xyz"))

        // tag::update-document[]
        database.getDocument("xyz")?.toMutable()?.let {
            it.setString("name", "apples")
            database.save(it)
        }
        // end::update-document[]
    }

    // ### Typed Accessors
    fun testTypedAccessors() {
        val doc = MutableDocument()

        // tag::date-getter[]
        doc.setValue("createdAt", Date())
        val date = doc.getDate("createdAt")
        // end::date-getter[]
    }

    // ### Batch operations
    fun testBatchOperations() {
        // tag::batch[]
        database.inBatch(UnitOfWork {
            for (i in 0..9) {
                val doc = MutableDocument()
                doc.let {
                    it.setValue("type", "user")
                    it.setValue("name", "user $i")
                    it.setBoolean("admin", false)
                }
                database.save(doc)
                Log.i(TAG, "saved user document: ${doc.getString("name")}")
            }
        })
        // end::batch[]
    }


    // toJSON
    fun testToJsonOperations(argDb: Database) {
        val db = argDb

    }


    // ### Document Expiration
    @Throws(CouchbaseLiteException::class)
    fun documentExpiration() {
        // tag::document-expiration[]
        // Purge the document one day from now
        database.setDocumentExpiration(
            "doc123",
            Date(Instant.now().plus(1, ChronoUnit.DAYS).toEpochMilli())
        )

        // Reset expiration
        database.setDocumentExpiration("doc1", null)

        // Query documents that will be expired in less than five minutes
        val query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(
                Meta.expiration.lessThan(
                    Expression.longValue(Instant.now().plus(5, ChronoUnit.MINUTES).toEpochMilli())
                )
            )
        // end::document-expiration[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testDocumentChangeListener() {
        // tag::document-listener[]
        database.addDocumentChangeListener("user.john") { change ->
            database.getDocument(change.documentID)?.let {
                Toast.makeText(
                    context,
                    "Status: ${it.getString("verified_account")}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
        // end::document-listener[]
    }

    // ### Blobs
    fun testBlobs() {
        val mDoc = MutableDocument()

        // tag::blob[]
        PlatformUtils.getAsset("avatar.jpg")?.use { // <.>
            mDoc.setBlob("avatar", Blob("image/jpeg", it)) // <.> <.>
            database.save(mDoc)
        }

        val doc = database.getDocument(mDoc.id)
        val bytes = doc?.getBlob("avatar")?.content
        // end::blob[]
    }
}


class supportingDatatypes
{

    private val database  = Database("mydb")



    fun datatype_usage() {


        // tag::datatype_usage[]
        // tag::datatype_usage_createdb[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        // Get the database (and create it if it doesn’t exist).
        DatabaseConfiguration config = new DatabaseConfiguration()

        config.setDirectory(context.getFilesDir().getAbsolutePath())

        Database database = new Database("getting-started", config)

        // end::datatype_usage_createdb[]
        // tag::datatype_usage_createdoc[]
        // Create your new document
        // The lack of 'const' indicates this document is mutable
        MutableDocument mutableDoc = new MutableDocument()

        // end::datatype_usage_createdoc[]
        // tag::datatype_usage_mutdict[]
        // Create and populate mutable dictionary
        // Create a new mutable dictionary and populate some keys/values
        MutableDictionary address = new MutableDictionary()
        address.setString("street", "1 Main st.")
        address.setString("city", "San Francisco")
        address.setString("state", "CA")
        address.setString("country", "USA")
        address.setString("code"), "90210")

        // end::datatype_usage_mutdict[]
        // tag::datatype_usage_mutarray[]
        // Create and populate mutable array
        MutableArray phones = new MutableArray()
        phones.addString("650-000-0000")
        phones.addString("650-000-0001")

        // end::datatype_usage_mutarray[]
        
        // tag::datatype_usage_populate[]
        // Initialize and populate the document

        // Add document type and hotel name as string
        mutable_doc.setString("type", "hotel"))
        mutable_doc.setString("name", "Hotel Java Mo"))

        // Add average room rate (float)
        mutable_doc.setFloat("room_rate", 121.75f)

        // Add address (dictionary)
        mutable_doc.setDictionary("address", address)

        // Add phone numbers(array)
        mutable_doc.setArray("phones", phones)

        // end::datatype_usage_populate[]
        // tag::datatype_usage_persist[]
        database.save(mutable_doc)

        // end::datatype_usage_persist[]
        // tag::datatype_usage_closedb[]
        database.close()

        // end::datatype_usage_closedb[]

        // end::datatype_usage[]

    }



    fun datatype_dictionary() {

        // tag::datatype_dictionary[]
        val document = database!!.getDocument("doc1")

        // Getting a dictionary from the document's properties
        val dict = document?.getDictionary("address")

        // Access a value with a key from the dictionary
        val street = dict?.getString("street")

        // Iterate dictionary
        for (key in dict!!.keys) {
            println("Key ${key} = ${dict.getValue(key)}")
        }

      // Create a mutable copy
      val mutable_Dict = dict.toMutable()

      // end::datatype_dictionary[]
    }

    fun datatype_mutable_dictionary() {

        // tag::datatype_mutable_dictionary[]
        // Create a new mutable dictionary and populate some keys/values
        val mutable_dict = MutableDictionary()
        mutable_dict.setString("street", "1 Main st.")
        mutable_dict.setString("city", "San Francisco")

        // Add the dictionary to a document's properties and save the document
        val mutable_doc = MutableDocument("doc1")
        mutable_doc.setDictionary("address", mutable_dict)
        database!!.save(mutable_doc)

    // end::datatype_mutable_dictionary[]
}


    fun datatype_array() {

        // tag::datatype_array[]
        val document = database?.getDocument("doc1")

        // Getting a phones array from the document's properties
        val array = document?.getArray("phones")

        // Get element count
        val count = array?.count()

        // Access an array element by index
        val phone = array?.getString(1)

        // Iterate array
        for ( (index, item) in array!!) {
            println("Row  ${index} = ${item}")
        }

        // Create a mutable copy
        val mutable_array = array.toMutable()
        // end::datatype_array[]
    }

    fun datatype_mutable_array() {

        // tag::datatype_mutable_array[]
        // Create a new mutable array and populate data into the array
        val mutable_array = MutableArray()
        mutable_array.addString("650-000-0000")
        mutable_array.addString("650-000-0001")

        // Set the array to document's properties and save the document
        val mutable_doc = MutableDocument("doc1")
        mutable_doc.setArray("phones", mutable_array)
        database?.save(mutable_doc)
        // end::datatype_mutable_array[]
    }

} // end  class supporting_datatypes



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/BasicExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/PredictiveQueryExamples.kt 
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
import com.couchbase.lite.Blob
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.Dictionary
import com.couchbase.lite.Expression
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.PredictionFunction
import com.couchbase.lite.PredictiveIndex
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndex
import com.couchbase.lite.ValueIndexItem


private const val TAG = "PREDICT"
// tag::predictive-model[]
// tensorFlowModel is a fake implementation

object TensorFlowModel {
    fun predictImage(data: ByteArray?) = mapOf<String, Any?>()
}

object ImageClassifierModel : PredictiveModel {
    const val name = "ImageClassifier"

    override fun predict(input: Dictionary): Dictionary? {
        val blob: Blob = input.getBlob("photo") ?: return null

        // this would be the implementation of the ml model you have chosen
        return MutableDictionary(TensorFlowModel.predictImage(blob.content)) // <1>
    }
}
// end::predictive-model[]


@Suppress("unused")
class PredictiveQueryExamples {
    @Throws(CouchbaseLiteException::class)
    fun testPredictiveModel() {
        val database = Database("mydb")

        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", ImageClassifierModel)
        // end::register-model[]

        // tag::predictive-query-value-index[]
        val index: ValueIndex = IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")))
        database.createIndex("value-index-image-classifier", index)
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier")
        // end::unregister-model[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testPredictiveIndex() {
        val database = Database("mydb")

        // tag::predictive-query-predictive-index[]
        val inputMap: MutableMap<String, Any> = mutableMapOf()
        inputMap["numbers"] = Expression.property("photo")
        val input: Expression = Expression.map(inputMap)
        val index: PredictiveIndex = IndexBuilder.predictiveIndex("ImageClassifier", input, null)
        database.createIndex("predictive-index-image-classifier", index)
        // end::predictive-query-predictive-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testPredictiveQuery() {
        val database = Database("mydb")

        // tag::predictive-query[]
        val prediction: PredictionFunction = Function.prediction(
            ImageClassifierModel.name,
            Expression.map(mutableMapOf("photo" to Expression.property("photo")) as Map<String, Any>?) // <1>
        )

        val rs = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                prediction.property("label").equalTo(Expression.string("car"))
                .and(prediction.property("probability").greaterThanOrEqualTo(Expression.doubleValue(0.8))
                    )
            )
            .execute()

        Log.d(TAG, "Number of rows: ${rs.allResults().size}")
        // end::predictive-query[]
    }
}


// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/PredictiveQueryExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/FlowExamples.kt 
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

import androidx.lifecycle.LiveData
import androidx.lifecycle.asLiveData
import com.couchbase.lite.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.map


class FlowExamples(argDb: Database,
                   argRepl: Replicator,
                   argQuery: Query,
                   argDocOwner: String) {

    // tag::flow-as-replicator-change-listener[]
    val replState: LiveData<ReplicatorActivityLevel> = argRepl.replicatorChangesFlow()
        .map { it.status.activityLevel }
        .asLiveData()

    // end::flow-as-replicator-change-listener[]
    // tag::flow-as-database-change-listener[]
    val dbChanges: LiveData<MutableList<String>> = argDb.databaseChangeFlow()
        .map { it.documentIDs }
        .asLiveData()

    // end::flow-as-database-change-listener[]
    // tag::flow-as-document-change-listener[]
    val docChanges: LiveData<DocumentChange?> = argDb.documentChangeFlow("1001")
        .map {
            it.takeUnless {
                it.database.getDocument(it.documentID)?.getString("owner").equals(argDocOwner)
            }
        }
        .asLiveData()

    // end::flow-as-document-change-listener[]
    // tag::flow-as-query-change-listener[]
    var liveQuery: LiveData<List<Any>?>? = null

    @ExperimentalCoroutinesApi
    fun watchQuery(query: Query): LiveData<List<Any>?> {
        val queryFlow = query.queryChangeFlow()
            .map {
                val err = it.error
                if (err != null) {
                    throw err
                }
                it.results?.allResults()?.flatMap { it.toList() }
            }
            .asLiveData()
        liveQuery = queryFlow
        return queryFlow
    }
    // end::flow-as-query-change-listener[]
}



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/FlowExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/PendingDocsExample.kt 
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
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorStatus


private const val TAG = "PENDING"

@Suppress("unused")
class PendingDocsExample(private var replicator: Replicator) {
    //
    // tag::replication-pendingdocuments[]
    //
    private fun onStatusChanged(pendingDocs: Set<String>, status: ReplicatorStatus) {
        // ... sample onStatusChanged function
        //
        Log.i(TAG, "Replicator activity level is ${status.activityLevel}")

        // iterate and report-on previously
        // retrieved pending docids 'list'
        val itr = pendingDocs.iterator()
        while (itr.hasNext()) {
            val docId = itr.next()

            // tag::replication-push-isdocumentpending[]
            if (!replicator.isDocumentPending(docId)) { // <.>
                continue
            }

            // end::replication-push-isdocumentpending[]
            Log.i(TAG, "Doc ID $docId has been pushed")
        }
    } // end::replication-pendingdocuments[]
}



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/PendingDocsExample.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/IBExamples.kt 
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

import android.content.Context
import android.util.Log
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.ClientCertificateAuthenticator
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.Endpoint
import com.couchbase.lite.KeyStoreUtils
import com.couchbase.lite.ListenerCertificateAuthenticator
import com.couchbase.lite.ListenerPasswordAuthenticator
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorActivityLevel
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.URLEndpointListener
import com.couchbase.lite.URLEndpointListenerConfigurationFactory
import com.couchbase.lite.create
import java.net.URI
import java.net.URISyntaxException
import java.security.KeyStore
import java.security.cert.Certificate

private const val TAG = "P2P"


@Suppress("unused")
class IBExamples(private val context: Context, private val caCert: Certificate) {
    private val database: Database
    private var thisReplicator: Replicator? = null
    private var thisListener: URLEndpointListener? = null

    init {
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        database = Database("p2p_demo")

        /* do some stuff here */
    }

    // PASSIVE PEER STUFF
    fun ibListenerSimple() {
        // tag::listener-simple[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                database = database,
                authenticator
                = ListenerPasswordAuthenticator { user, pwd -> (user == "daniel") && (String(pwd) == "123") })
        ) // <.>
        listener.start() // <.>
        thisListener = listener

        // end::listener-simple[]
    }

    fun ibReplicatorSimple() {
        // tag::replicator-simple[]
        val theListenerEndpoint: Endpoint = URLEndpoint(URI("wss://10.0.2.2:4984/db")) // <.>
        val repl = Replicator(
            ReplicatorConfigurationFactory.create(
                database = database,
                target = theListenerEndpoint,
                authenticator = BasicAuthenticator("valid.user", "valid.password.string".toCharArray()), // <.>
                acceptOnlySelfSignedServerCertificate = true
            )
        )
        repl.start() // <.>
        thisReplicator = repl
        // end::replicator-simple[]
    }

    fun ibPassListener(validUser: String, validPassword: CharArray) {
        // EXAMPLE 1
        // tag::listener-start[]
        // Initialize the listener
        // tag::listener-initialize[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                // tag::listener-config-db[]
                database = database, // <.>
                // end::listener-config-db[]
                // tag::listener-config-port[]
                port = 55990, // <.>
                // end::listener-config-port[]
                // tag::listener-config-netw-iface[]
                networkInterface = "10.1.1.10", // <.>

                // end::listener-config-netw-iface[]
                // tag::listener-config-delta-sync[]
                enableDeltaSync = false, // <.>

                // end::listener-config-delta-sync[]
                // tag::listener-config-tls-full[]
                // Configure server security
                // tag::listener-config-tls-enable[]
                disableTls = false, // <.>

                // end::listener-config-tls-enable[]
                // tag::listener-config-tls-id-anon[]
                // Use an Anonymous Self-Signed Cert
                identity = null, // <.>
                // end::listener-config-tls-id-anon[]

                // tag::listener-config-client-auth-pwd[]
                // Configure Client Security using an Authenticator
                // For example, Basic Authentication <.>
                authenticator = ListenerPasswordAuthenticator { username, paassword ->
                    (username === validUser) && (paassword === validPassword)
                }
                // end::listener-config-client-auth-pwd[]
            ))

        // Start the listener
        listener.start() // <.>
        thisListener = listener

        // end::listener-initialize[]
        // end::listener-start[]
    }

    fun ibListenerGetNetworkInterfaces() {
        // tag::listener-get-network-interfaces[]
        val listener = URLEndpointListener(URLEndpointListenerConfigurationFactory.create(database = database))
        listener.start()
        Log.i(TAG, "URLS are ${listener.urls}")
        thisListener = listener
        // end::listener-get-network-interfaces[]
    }

    fun ibListenerLocalDb() {
        // tag::listener-local-db[]
        // . . . preceding application logic . . .
        CouchbaseLite.init(context) // <.>
        val thisDB = Database("passivepeerdb")
        // end::listener-local-db[]
    }

    fun ibListenerConfigTlsDisable() {
        // tag::listener-config-tls-disable[]
        URLEndpointListenerConfigurationFactory.create(database, disableTls = false) // <.>
        // end::listener-config-tls-disable[]
    }


    // !!! USERS SHOULD BE CAUTIONED THAT THIS IS INSECURE
    // Android has much better ways of importing keys
    fun ibListenerConfigTlsIdFull() {
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]
        // Use CA Cert
        // Import a key pair into secure storage
        // Create a TLSIdentity from the imported key-pair

        this.javaClass.getResourceAsStream("serverkeypair.p12")?.use { // <.>
            KeyStoreUtils.importEntry(
                "teststore.p12",  // KeyStore type, eg: "PKCS12"
                it,  // An InputStream from the keystore
                "let me in".toCharArray(),  // The keystore password
                "topSekritKey",  // The alias to be used (in external keystore)
                null,  // The key password or null if the key has none
                "test-alias" // The alias for the imported key
            )
        }

        // end::listener-config-tls-id-caCert[]

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        URLEndpointListenerConfigurationFactory.create(
            database,
            identity = TLSIdentity.getIdentity("test-alias")
        ) // <.>

        // end::listener-config-tls-id-set[]
// end::listener-config-tls-id-full[]
    }

    fun ibListenerConfigClientAuthRoot() {
// tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Configure the client authenticator
        // to validate using ROOT CA
        // thisClientID.certs is a list containing a client cert to accept
        // and any other certs needed to complete a chain between the client cert
        // and a CA
        val validId = TLSIdentity.getIdentity("Our Corporate Id")
            ?: throw IllegalStateException("Cannot find corporate id")
        // accept only clients signed by the corp cert
        thisListener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                // get the identity <.>
                database = database,
                identity = validId,
                authenticator = ListenerCertificateAuthenticator(validId.certs)
            )
        ) // <.>

        // end::listener-config-client-auth-root[]
// end::listener-config-client-root-ca[]
    }

    fun ibListenerConfigTlsDisable2() {

        // tag::listener-config-tls-disable[]
        URLEndpointListenerConfigurationFactory.create(database = database, disableTls = true)
        // end::listener-config-tls-disable[]
    }

    fun ibListenerStatusCheck() {
        val listener = URLEndpointListener(URLEndpointListenerConfigurationFactory.create(database = database))
        // tag::listener-status-check[]
        val connectionCount = listener.status?.connectionCount // <.>
        val activeConnectionCount = listener.status?.activeConnectionCount // <.>
        // end::listener-status-check[]
    }

    fun ibListenerStop() {

        // tag::listener-stop[]
        thisListener?.stop()

        // end::listener-stop[]
    }

    // ACTIVE PEER STUFF
// Replication code
    @Throws(CouchbaseLiteException::class, URISyntaxException::class)
    fun testActPeerSync() {
        // tag::p2p-act-rep-start-full[]
        // Create replicator
        // Consider holding a reference somewhere
        // to prevent the Replicator from being GCed
        val repl = Replicator( // <.>

            // tag::p2p-act-rep-func[]
            // tag::p2p-act-rep-initialize[]
            // initialize the replicator configuration
            ReplicatorConfigurationFactory.create(
                database = database,
                target = URLEndpoint(URI("wss://listener.com:8954")), // <.>

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
                authenticator = BasicAuthenticator("Our Username", "Our PasswordValue".toCharArray()), // <.>


                // end::p2p-act-rep-auth[]
                // tag::p2p-act-rep-config-conflict[]
                /* Optionally set custom conflict resolver call back */
                conflictResolver = null // <.>
            )
        )

        // end::p2p-act-rep-config-conflict[]

        // tag::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-add-change-listener-label[]
        // Optionally add a change listener <.>
        // end::p2p-act-rep-add-change-listener-label[]
        val thisListener = repl.addChangeListener { change ->
            val err: CouchbaseLiteException? = change.status.error
            if (err != null) {
                Log.i(TAG, "Error code ::  ${err.code}", err)
            }
        }

        // end::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-start[]
        // Start replicator
        repl.start(false) // <.>
        thisReplicator = repl

        // end::p2p-act-rep-start[]
        // end::p2p-act-rep-start-full[]
        // end::p2p-act-rep-func[]         ***** End p2p-act-rep-func
    }

    fun ibReplicatorConfig() {
        // BEGIN additional snippets
        // tag::p2p-act-rep-config-tls-full[]

        val repl = Replicator(
            ReplicatorConfigurationFactory.create(
                database = database,

                // tag::p2p-act-rep-config-cacert[]
                // Configure Server Security
                // -- only accept CA attested certs
                acceptOnlySelfSignedServerCertificate = false, // <.>

                // end::p2p-act-rep-config-cacert[]


                // tag::p2p-act-rep-config-cacert-pinned[]

                // Use the pinned certificate from the byte array (cert)
                pinnedServerCertificate = caCert.encoded, // <.>
                // end::p2p-act-rep-config-cacert-pinned[]


                // end::p2p-act-rep-config-tls-full[]
                // tag::p2p-tlsid-tlsidentity-with-label[]
                // ... other replicator configuration
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

    fun ibP2pReplicatorStatus() {
        // tag::p2p-act-rep-status[]
        thisReplicator?.status?.let {
            Log.i(TAG, "The Replicator is currently ${it.activityLevel}")
            Log.i(TAG, "The Replicator has processed ${it.progress}")
            Log.i(
                TAG,
                if (it.activityLevel === ReplicatorActivityLevel.BUSY) {
                    "Replication Processing"
                } else {
                    "It has completed ${it.progress.total} changes"
                }
            )
        }
        // end::p2p-act-rep-status[]
    }

    fun ibP2pReplicatorStop() {
        // tag::p2p-act-rep-stop[]
        // Stop replication.
        thisReplicator?.stop() // <.>
        // end::p2p-act-rep-stop[]
    }

    fun ibP2pListener() {
        CouchbaseLite.init(context)
        val thisDB = Database("passivepeerdb") // <.>


        // Initialize the listener
        val listener = URLEndpointListener( // <.>

            // Initialize the listener config
            URLEndpointListenerConfigurationFactory.create(
                database = thisDB,
                port = 55990, /* <.>  Optional; defaults to auto */
                disableTls = false, /* <.>  Optional; defaults to false */
                enableDeltaSync = true,  /* <.> Optional; defaults to false */

                // Configure the client authenticator (if using basic auth)
                authenticator = ListenerPasswordAuthenticator { username, password ->
                    ("username" === username) && (password === "password".toCharArray())  // <.>
                }
            )
        )

        // Start the listener
        listener.start() // <.>


        // tag::createTlsIdentity[]

//        Map<String, String> X509_ATTRIBUTES = mapOf(
//                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
//                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
//                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
//                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
//        );
        val thisIdentity = TLSIdentity.createIdentity(
            true,
            mapOf(
                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
            ),
            null,
            "test-alias"
        )

        // end::createTlsIdentity[]

        // tag::p2p-tlsid-store-in-keychain[]
        // end::p2p-tlsid-store-in-keychain[]


        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        val thisAlias = "alias-to-delete"
        val thisKeyStore = KeyStore.getInstance("AndroidKeyStore")
        thisKeyStore.load(null)
        thisKeyStore.deleteEntry(thisAlias)

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]

        // tag::retrieveTlsIdentity[]
        // OPTIONALLY:: Retrieve a stored TLS identity using its alias/label
        val thatIdentity = TLSIdentity.getIdentity("couchbase-docs-cert")
        // end::retrieveTlsIdentity[]
    }

    // tag::sgw-repl-pull[]
    fun ibRplicatorPull() {
        val database = Database("ian")

        val uri = URI("wss://10.0.2.2:4984/db") // <.>

        val repl = Replicator( // <.>
            ReplicatorConfigurationFactory.create(
                database = database,
                target = URLEndpoint(uri),
                type = ReplicatorType.PULL
            )
        )

        repl.start()
        thisReplicator = repl
    }

    // end::sgw-repl-pull[]
// tag::sgw-act-rep-initialize[]
// initialize the replicator configuration
    val thisConfig = ReplicatorConfigurationFactory.create(
        database = database,
        target = URLEndpoint(URI("wss://10.0.2.2:8954/travel-sample"))
    ) // <.> // end::sgw-act-rep-initialize[]

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
}



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/IBExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/ListenerExamples.kt 
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

import android.content.Context
import android.util.Log
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.ClientCertificateAuthenticator
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.ListenerCertificateAuthenticator
import com.couchbase.lite.ListenerPasswordAuthenticator
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorActivityLevel
import com.couchbase.lite.ReplicatorConfiguration
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.URLEndpointListener
import com.couchbase.lite.URLEndpointListenerConfigurationFactory
import com.couchbase.lite.create
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.URI
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.NoSuchAlgorithmException
import java.security.cert.Certificate
import java.security.cert.CertificateEncodingException
import java.security.cert.CertificateException
import java.util.concurrent.CountDownLatch

private const val TAG = "LISTEN"

@Suppress("unused")
class KtCertAuthListener {
    companion object {
        private val CERT_ATTRIBUTES = mapOf(
            TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "CBL Test",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
            TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "lite@couchbase.com",
        )
    }

    // start a server and connect to it with a replicator
    @Throws(CouchbaseLiteException::class, IOException::class)
    fun run() {
        val localDb = Database("localDb")
        var doc = MutableDocument()
        doc.setString("dog", "woof")
        localDb.save(doc)

        val remoteDb = Database("remoteDb")
        doc = MutableDocument()
        doc.setString("cat", "meow")
        remoteDb.save(doc)

        val serverIdentity = TLSIdentity.createIdentity(true, CERT_ATTRIBUTES, null, "server")

        val clientIdentity = TLSIdentity.createIdentity(false, CERT_ATTRIBUTES, null, "client")
        val uri = startServer(remoteDb, serverIdentity, clientIdentity.certs)
            ?: throw IOException("Failed to start the server")

        Thread {
            startClient(localDb, uri, clientIdentity, serverIdentity.certs[0])
            Log.e(TAG, "Success!!")
            deleteIdentity("server")
            Log.e(TAG, "Alias deleted: server")
            deleteIdentity("client")
            Log.e(TAG, "Alias deleted: client")
        }.start()
    }

    // start a client replicator
    @Throws(CertificateEncodingException::class, InterruptedException::class)
    fun startClient(db: Database, uri: URI, clientIdentity: TLSIdentity, cert: Certificate) {
        val repl = Replicator(
            ReplicatorConfigurationFactory.create(
                database = db,
                target = URLEndpoint(uri),
                type = ReplicatorType.PUSH_AND_PULL,
                continuous = false,
                authenticator = ClientCertificateAuthenticator(clientIdentity),
                pinnedServerCertificate = cert.encoded
            )
        )

        val completionLatch = CountDownLatch(1)

        repl.addChangeListener { change ->
            if (change.status.activityLevel == ReplicatorActivityLevel.STOPPED) {
                completionLatch.countDown()
            }
        }
        repl.start(false)
        completionLatch.await()
    }
    // tag::listener-config-auth-cert-full[]
    /**
     * Snippet 2: create a ListenerCertificateAuthenticator and configure the listener with it
     *
     *
     * Start a listener for db that accepts connections from a client identified by any of the passed certs
     *
     * @param db    the database to which the listener is attached
     * @param certs the name of the single valid user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Throws(CouchbaseLiteException::class)
    fun startServer(db: Database, serverId: TLSIdentity, certs: List<Certificate?>): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                database = db,
                port = 0, // this is the default
                disableTls = false,
                identity = serverId,
                authenticator = ListenerCertificateAuthenticator(certs)
            )
        )
        listener.start()
        val urls: List<URI> = listener.urls
        return if (urls.isEmpty()) {
            null
        } else {
            urls[0]
        }
    }
    // end::listener-config-auth-cert-full[]
    // tag::listener-config-delete-cert-full[]
    /**
     * Delete an identity from the keystore
     *
     * @param alias the alias for the identity to be deleted
     */
    @Throws(
        KeyStoreException::class,
        CertificateException::class,
        NoSuchAlgorithmException::class,
        IOException::class
    )
    fun deleteIdentity(alias: String?) {
        val keyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        keyStore.deleteEntry(alias) // <.>
    }
    // end::listener-config-delete-cert-full[]
    // nottag::p2p-tlsid-tlsidentity-with-label[]
    /**
     * Snippet 4: Create a ClientCertificateAuthenticator and use it in a replicator
     * Snippet 5: Specify a pinned certificate as a byte array
     *
     *
     * Configure Client (active) side certificates
     *
     * @param config         The replicator configuration
     * @param cert           The expected server side certificate
     * @param clientIdentity the identity offered to the server as authentication
     * @throws CertificateEncodingException on certifcate encoding error
     */
    @Throws(CertificateEncodingException::class)
    private fun configureClientCerts(
        config: ReplicatorConfiguration,
        cert: Certificate,
        clientIdentity: TLSIdentity
    ) {

        // Snippet 4: create an authenticator that provides the client identity
        config.setAuthenticator(ClientCertificateAuthenticator(clientIdentity))

        // Configure the pinned certificate passing a byte array.
        config.pinnedServerCertificate = cert.encoded
    }
    // notend::p2p-tlsid-tlsidentity-with-label[]
    /**
     * Snippet 5 (supplement): Copy a cert from a resource bundle
     *
     *
     * Configure Client (active) side certificates
     *
     * @param context Android context
     * @param resId   resource id for resource: R.id.foo
     * @throws IOException on copy error
     */
    @Throws(IOException::class)
    private fun readCertMaterialFromBundle(
        context: Context,
        resId: Int
    ): ByteArray {
        val out = ByteArrayOutputStream()
        val `in` = context.resources.openRawResource(resId)
        val buf = ByteArray(1024)
        var n: Int
        while (`in`.read(buf).also { n = it } >= 0) {
            out.write(buf, 0, n)
        }
        return out.toByteArray()
    }
}

@Suppress("unused")
class KtPasswordAuthListener {
    companion object {
        private const val VALID_USER = "Minnie"
        private val VALID_PASSWORD = "let me in!".toCharArray()
    }

    // start a server and connect to it with a replicator
    @Throws(CouchbaseLiteException::class, IOException::class)
    fun run() {
        val localDb = Database("localDb")
        var doc = MutableDocument()
        doc.setString("dog", "woof")
        localDb.save(doc)
        val remoteDb = Database("remoteDb")
        doc = MutableDocument()
        doc.setString("cat", "meow")
        localDb.save(doc)
        val uri = startServer(remoteDb, "fox", "wa-pa-pa-pa-pa-pow".toCharArray())
            ?: throw IOException("Failed to start the server")
        Thread {
            try {
                runClient(uri, "fox", "wa-pa-pa-pa-pa-pow".toCharArray(), localDb)
                Log.e(TAG, "Success!!")
            } catch (e: Exception) {
                Log.e(TAG, "Failed!!", e)
            }
        }.start()
    }

    // start a client replicator
    @Throws(InterruptedException::class)
    fun runClient(
        uri: URI,
        username: String,
        password: CharArray,
        db: Database
    ) {
        val config = ReplicatorConfiguration(db, URLEndpoint(uri))
        config.type = ReplicatorType.PUSH_AND_PULL
        config.isContinuous = false
        config.setAuthenticator(BasicAuthenticator(username, password))
        val completionLatch = CountDownLatch(1)
        val repl = Replicator(config)

        repl.addChangeListener { change ->
            if (change.status
                    .activityLevel == ReplicatorActivityLevel.STOPPED
            ) {
                completionLatch.countDown()
            }
        }
        repl.start(false)
        completionLatch.await()
    }
    // tag::listener-config-client-auth-pwd-full[]
    /**
     *
     * Start a listener for db that accepts connections using exactly the passed username and password
     *
     *
     * @param db       the database to which the listener is attached
     * @param username the name of the single valid user
     * @param password the password for the user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    fun startServer(db: Database, username: String, password: CharArray): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                database = db,
                port = 0,// this is the default
                disableTls = true,
                authenticator = ListenerPasswordAuthenticator { usr, pwd ->
                    (usr == username) && pwd.contentEquals(password)
                })
        )

        listener.start()
        val urls: List<URI> = listener.urls
        return if (urls.isEmpty()) {
            null
        } else {
            urls[0]
        }
    }
// end::listener-config-client-auth-pwd-full[]
}





// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/ListenerExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/Peer2PeerExamples.kt 
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

import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.Message
import com.couchbase.lite.MessageEndpoint
import com.couchbase.lite.MessageEndpointConnection
import com.couchbase.lite.MessageEndpointDelegate
import com.couchbase.lite.MessageEndpointListener
import com.couchbase.lite.MessageEndpointListenerConfigurationFactory
import com.couchbase.lite.MessagingCloseCompletion
import com.couchbase.lite.MessagingCompletion
import com.couchbase.lite.ProtocolType
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorConnection
import com.couchbase.lite.create


@Suppress("unused")
class BrowserSessionManager : MessageEndpointDelegate {
    private var replicator: Replicator? = null

    @Throws(CouchbaseLiteException::class)
    fun initCouchbase() {
        // tag::message-endpoint[]
        val database = Database("mydb")

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        val messageEndpoint = MessageEndpoint("UID:123", "active", ProtocolType.MESSAGE_STREAM, this)
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        // Create the replicator object.
        val repl = Replicator(ReplicatorConfigurationFactory.create(database = database, target = messageEndpoint))
        // Start the replication.
        repl.start()
        replicator = repl
        // end::message-endpoint-replicator[]
    }

    // tag::create-connection[]
    /* implementation of MessageEndpointDelegate */
    override fun createConnection(endpoint: MessageEndpoint) = ActivePeerConnection()
    // end::create-connection[]
}

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ----------------------------------------------------------- */

@Suppress("unused")
class ActivePeerConnection : MessageEndpointConnection {
    private var replicatorConnection: ReplicatorConnection? = null

    // tag::active-replicator-close[]
    fun disconnect() {
        replicatorConnection?.close(null)
        replicatorConnection = null
    }
    // end::active-replicator-close[]

    // tag::active-peer-open[]
    /* implementation of MessageEndpointConnection */
    override fun open(connection: ReplicatorConnection, completion: MessagingCompletion) {
        replicatorConnection = connection
        completion.complete(true, null)
    }

    // end::active-peer-open[]
    // tag::active-peer-close[]
    override fun close(error: Exception?, completion: MessagingCloseCompletion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete()
    }

    // end::active-peer-close[]
    // tag::active-peer-send[]
    /* implementation of MessageEndpointConnection */
    override fun send(message: Message, completion: MessagingCompletion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null)
    }

    // end::active-peer-send[]
    fun receive(message: Message) {
        // tag::active-peer-receive[]
        replicatorConnection?.receive(message)
        // end::active-peer-receive[]
    }
}

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ----------------------------------------------------------- */

@Suppress("unused")
class PassivePeerConnection private constructor() : MessageEndpointConnection {
    private var messageEndpointListener: MessageEndpointListener? = null
    private var replicatorConnection: ReplicatorConnection? = null

    @Throws(CouchbaseLiteException::class)
    fun startListener() {
        // tag::listener[]
        val database = Database("mydb")
        messageEndpointListener = MessageEndpointListener(
            MessageEndpointListenerConfigurationFactory.create(database, ProtocolType.MESSAGE_STREAM)
        )
        // end::listener[]
    }

    fun stopListener() {
        // tag::passive-stop-listener[]
        messageEndpointListener?.closeAll()
        // end::passive-stop-listener[]
    }

    fun accept() {
        // tag::advertizer-accept[]
        val connection = PassivePeerConnection() /* implements MessageEndpointConnection */
        messageEndpointListener?.accept(connection)
        // end::advertizer-accept[]
    }

    fun disconnect() {
        // tag::passive-replicator-close[]
        replicatorConnection?.close(null)
        // end::passive-replicator-close[]
    }

    // tag::passive-peer-open[]
    /* implementation of MessageEndpointConnection */
    override fun open(connection: ReplicatorConnection, completion: MessagingCompletion) {
        replicatorConnection = connection
        completion.complete(true, null)
    }
    // end::passive-peer-open[]

    // tag::passive-peer-close[]
    /* implementation of MessageEndpointConnection */
    override fun close(error: Exception?, completion: MessagingCloseCompletion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete()
    }

    // end::passive-peer-close[]
    // tag::passive-peer-send[]
    /* implementation of MessageEndpointConnection */
    override fun send(message: Message, completion: MessagingCompletion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null)
    }

    // end::passive-peer-send[]
    fun receive(message: Message) {
        // tag::passive-peer-receive[]
        replicatorConnection?.receive(message)
        // end::passive-peer-receive[]
    }

}



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/Peer2PeerExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/QueryExamples.kt 
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
import com.couchbase.lite.Function
import com.fasterxml.jackson.databind.ObjectMapper
import org.json.JSONException


private const val TAG = "QUERY"
private const val DATABASE_NAME = "database"

data class Hotel(
    var description: String? = null,
    var country: String? = null,
    var city: String? = null,
    var name: String? = null,
    var type: String? = null,
    var id: String? = null
)

@Suppress("unused")
class QueryExamples(private val database: Database) {

    // ### Indexing
    @Throws(CouchbaseLiteException::class)
    fun testIndexing() {
        // tag::query-index[]
        database.createIndex(
          "TypeNameIndex",
          ValueIndexConfigurationFactory.create("type","name")
        )

        // end::query-index[]
    }

    fun testIndexing_Querybuilder() {
        // tag::query-index_Querybuilder[]
        database.createIndex(
            "TypeNameIndex",
            IndexBuilder.valueIndex(
                ValueIndexItem.property("type"),
                ValueIndexItem.property("name")
            )
        )
        // end::query-index_Querybuilder[]
    }

    // ### SELECT statement
    fun testSelectStatement() {
        // tag::query-select-props[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("type")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.expression(Meta.id))
            .execute()

        for (result in rs) {
            Log.i(TAG, "hotel id ->${result.getString("id")}")
            Log.i(TAG, "hotel name -> ${result.getString("name")}")
        }
        // end::query-select-props[]
      }

      // META function
      @Throws(CouchbaseLiteException::class)
      fun testMetaFunction() {
        // tag::query-select-meta[]
        val rs = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.database(database))
        .where(Expression.property("type").equalTo(Expression.string("airport")))
        .orderBy(Ordering.expression(Meta.id))
        .execute()

        for (result in rs) {
          Log.w(TAG, "airport id ->${result.getString("id")}")
          Log.w(TAG, "airport id -> ${result.getString(0)}")
        }
        // end::query-select-meta[]
      }

      // ### all(*)
    @Throws(CouchbaseLiteException::class)
    fun testSelectAll() {
        // tag::query-select-all[]
        val queryAll = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
        // end::query-select-all[]

        // tag::live-query[]
        val query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database)) // <.>

        // Adds a query change listener.
        // Changes will be posted on the main queue.
        val token = query.addChangeListener { change ->
            change.results?.let {
                for (result in it) {
                    Log.d(TAG, "results: ${result.keys}")
                    /* Update UI */
                }
            } // <.>
        }

        // end::live-query[]

        // tag::stop-live-query[]
        query.removeChangeListener(token)
        // end::stop-live-query[]

        for (result in query.execute()) {
            Log.i(TAG, "hotel -> ${result.getDictionary(DATABASE_NAME)?.toMap()}")
        }
    }


    // ###　WHERE statement
    @Throws(CouchbaseLiteException::class)
    fun testWhereStatement() {
        // tag::query-where[]
        val rs = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .limit(Expression.intValue(10))
            .execute()
        for (result in rs) {
            result.getDictionary(DATABASE_NAME)?.let {
                Log.i(TAG, "name -> ${it.getString("name")}")
                Log.i(TAG, "type -> ${it.getString("type")}")
            }
        }
        // end::query-where[]
    }

    fun testQueryDeletedDocuments() {
        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        val query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Meta.deleted)
        // end::query-deleted-documents[]
    }

    // ####　Collection Operators
    @Throws(CouchbaseLiteException::class)
    fun testCollectionStatement() {
        // tag::query-collection-operator-contains[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("public_likes")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("hotel"))
                    .and(
                        ArrayFunction.contains(
                            Expression.property("public_likes"),
                            Expression.string("Armani Langworth")
                        )
                    )
            )
            .execute()
        for (result in rs) {
            Log.i(TAG, "public_likes -> ${result.getArray("public_likes")?.toList()}")
        }
        // end::query-collection-operator-contains[]
    }

    // IN operator
    @Throws(CouchbaseLiteException::class)
    fun testInOperator() {
        // tag::query-collection-operator-in[]
        val rs = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.string("Armani").`in`(
                    Expression.property("first"),
                    Expression.property("last"),
                    Expression.property("username")
                )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "public_likes -> ${result.toMap()}")
        }
        // end::query-collection-operator-in[]
    }

    // Pattern Matching
    @Throws(CouchbaseLiteException::class)
    fun testPatternMatching() {
        // tag::query-like-operator[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .like(Expression.string("royal engineers museum"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-like-operator[]
    }

    // ### Wildcard Match
    @Throws(CouchbaseLiteException::class)
    fun testWildcardMatch() {
        // tag::query-like-operator-wildcard-match[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .like(Expression.string("eng%e%"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-like-operator-wildcard-match[]
    }

    // Wildcard Character Match
    @Throws(CouchbaseLiteException::class)
    fun testWildCharacterMatch() {
        // tag::query-like-operator-wildcard-character-match[]

        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .like(Expression.string("eng____r"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-like-operator-wildcard-character-match[]
    }

    // ### Regex Match
    @Throws(CouchbaseLiteException::class)
    fun testRegexMatch() {
        // tag::query-regex-operator[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .regex(Expression.string("\\beng.*r\\b"))
                    )
            )
            .execute()
        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-regex-operator[]
    }

    // JOIN statement
    @Throws(CouchbaseLiteException::class)
    fun testJoinStatement() {
        // tag::query-join[]
        val rs = QueryBuilder.select(
            SelectResult.expression(Expression.property("name").from("airline")),
            SelectResult.expression(Expression.property("callsign").from("airline")),
            SelectResult.expression(Expression.property("destinationairport").from("route")),
            SelectResult.expression(Expression.property("stops").from("route")),
            SelectResult.expression(Expression.property("airline").from("route"))
        )
            .from(DataSource.database(database).as("airline"))
            .join(
                Join.join(DataSource.database(database).as("route"))
                    .on(
                        Meta.id.from("airline")
                            .equalTo(Expression.property("airlineid").from("route"))
                    )
            )
            .where(
                Expression.property("type").from("route").equalTo(Expression.string("route"))
                    .and(
                        Expression.property("type").from("airline")
                            .equalTo(Expression.string("airline"))
                    )
                    .and(
                        Expression.property("sourceairport").from("route")
                            .equalTo(Expression.string("RIX"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.toMap()}")
        }
        // end::query-join[]
    }


    // ### GROUPBY statement
    @Throws(CouchbaseLiteException::class)
    fun testGroupByStatement() {
        // tag::query-groupby[]
        val rs = QueryBuilder.select(
            SelectResult.expression(Function.count(Expression.string("*"))),
            SelectResult.property("country"),
            SelectResult.property("tz")
        )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("airport"))
                    .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300)))
            )
            .groupBy(
                Expression.property("country"), Expression.property("tz")
            )
            .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending())
            .execute()

        for (result in rs) {
            result.let {
                Log.i(
                    TAG,
                    "There are ${it.getInt("$1")} airports on the ${
                        it.getString("tz")
                    } timezone located in ${
                        it.getString("country")
                    } and above 300ft"
                )
            }
            // end::query-groupby[]
        }
    }

    // ### ORDER BY statement
    @Throws(CouchbaseLiteException::class)
    fun testOrderByStatement() {
        // tag::query-orderby[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.property("name").ascending())
            .limit(Expression.intValue(10))
            .execute()

        for (result in rs) {
            Log.i(TAG, "${result.toMap()}")
        }
        // end::query-orderby[]
    }


    // ### EXPLAIN statement
    // tag::query-explain[]
    @Throws(CouchbaseLiteException::class)
    fun testExplainStatement() {
        // tag::query-explain-all[]
        var query: Query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("university")))
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").descending()) // <.>
        Log.i(TAG, query.explain()) // <.>
        // end::query-explain-all[]

        // tag::query-explain-like[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").like(Expression.string("%hotel%"))) // <.>
        Log.i(TAG, query.explain())
        // end::query-explain-like[]

        // tag::query-explain-nopfx[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%")))
            )
        Log.i(TAG, query.explain())
        // end::query-explain-nopfx[]

        // tag::query-explain-function[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Function.lower(
                    Expression.property("type").equalTo(Expression.string("hotel"))
                )
            ) // <.>
        Log.i(TAG, query.explain())
        // end::query-explain-function[]

        // tag::query-explain-nofunction[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))) // <.>
        Log.i(TAG, query.explain())
        // end::query-explain-nofunction[]
    }
// end::query-explain[]

    @Throws(CouchbaseLiteException::class)
    fun prepareIndex() {
        // tag::fts-index[]

      database.createIndex("overviewFTSIndex",
                      FullTextIndexConfigurationFactory.create(
                        expressions = ["overview"]
                      )
                    )

        // end::fts-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testFTS() {
        // tag::fts-query[]

        val ftsQuery =
              database.createQuery(
                "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK(overviewFTSIndex)")

        ftsQuery.execute().allResults().forEach {
          Log.i(TAG, "${result.getString("id")}: ${result.getString("overview")}")
        }

        // end::fts-query[]
    }

    @Throws(CouchbaseLiteException::class)
    fun prepareIndex_Querybuilder() {
        // tag::fts-index_Querybuilder[]
        database.createIndex(
            "overviewFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("overview")).ignoreAccents(false)
        )
        // end::fts-index_Querybuilder[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testFTS_Querybuilder() {
        // tag::fts-query_Querybuilder[]

        val ftsQuery =
              QueryBuilder.select(SelectResult.expression(Meta.id),
                                  SelectResult.expression(overview))
                          .from(DataSource.database(database))
                          .where(FullTextFunction.match("overviewFTSIndex", "michigan"))
                          .execute()

        ftsQuery.execute().allResults().forEach {
          Log.i(TAG, "${result.getString("Meta.id")}: ${result.getString("overview")}")
          }



        // end::fts-query_Querybuilder[]
    }


    fun testQuerySyntaxAll(currentUser: String) {
        // tag::query-syntax-all[]
        val listQuery: Query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(openOrCreateDatabaseForUser(currentUser)))

            // end::query-syntax-all[]
        // tag::query-access-all[]
        val hotels: HashMap<String, Hotel> = HashMap()

        for (result in listQuery.execute().allResults()) {
            // get the k-v pairs from the 'hotel' key's value into a dictionary
            val thisDocsProps = result.getDictionary(0) // <.>
            val thisDocsId = thisDocsProps!!.getString("id")
            val thisDocsName = thisDocsProps.getString("name")
            val thisDocsType = thisDocsProps.getString("type")
            val thisDocsCity = thisDocsProps.getString("city")

            // Alternatively, access results value dictionary directly
            val id = result.getDictionary(0)?.getString("id").toString() // <.>
            hotels[id] = Hotel(
                id,
                result.getDictionary(0)?.getString("type"),
                result.getDictionary(0)?.getString("name"),
                result.getDictionary(0)?.getString("city"),
                result.getDictionary(0)?.getString("country"),
                result.getDictionary(0)?.getString("description")
            )
        }

        // end::query-access-all[]
    }

    @Throws(CouchbaseLiteException::class, JSONException::class)
    fun testQuerySyntaxJson(currentUser: String, argDb: Database) {
        val db = argDb
        // tag::query-syntax-json[]
        // Example assumes Hotel class object defined elsewhere

        // Build the query
        val listQuery: Query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(db))

        // end::query-syntax-json[]
        // tag::query-access-json[]
        // Uses Jackson JSON processor
        val mapper = ObjectMapper()
        val hotels: ArrayList<Hotel> = ArrayList()

        for (result in listQuery.execute()) {

            // Get result as JSON string
            val json = result.toJSON()

            // Get Hashmap from JSON string
            val dictFromJSONstring = mapper.readValue(json, HashMap::class.java)

            // Use created hashmap
            val hotelId = dictFromJSONstring["id"].toString() //
            val hotelType = dictFromJSONstring["type"].toString()
            val hotelname = dictFromJSONstring["name"].toString()


            // Get custom object from JSON string
            val thisHotel = mapper.readValue(json, Hotel::class.java)
            hotels.add(thisHotel)
        }
        // end::query-access-json[]
    }
/* end func testQuerySyntaxJson */



    fun testQuerySyntaxProps(currentUser: String) {
        // tag::query-select-props[]
        // tag::query-syntax-props[]

        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))

        // end::query-syntax-props[]

        // tag::query-access-props[]
        for (result in rs.execute().allResults()) {
            Log.i(TAG, "Hotel name -> ${result.getString("name")}, in ${result.getString("country")}" )
        }
        // end::query-access-props[]
        // end::query-select-props[]
    }

    fun testQuerySyntaxCount(currentUser: String) {
        // tag::query-syntax-count-only[]

        val rs = QueryBuilder
            .select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
            .from(DataSource.database(database))

        // end::query-syntax-count-only[]

        // tag::query-access-count-only[]
        for (result in rs.execute().allResults()) {
            Log.i(TAG, "name -> ${result.getInt("mycount").toString()}")
        }
        // end::query-access-count-only[]
    }


    fun testQuerySyntaxId(currentUser: String) {
        // tag::query-select-meta
        // tag::query-syntax-id[]

        val rs = QueryBuilder
        .select(
          SelectResult.expression(Meta.id).as("hotelId"))
          .from(DataSource.database(database))

          // end::query-syntax-id[]

        // tag::query-access-id[]
        for (result in rs.execute().allResults()) {
          Log.i(TAG, "hotel id ->${result.getString("hotelId")}")
        }
        // end::query-access-id[]
        // end::query-select-meta
    }


    fun docsOnlyQuerySyntaxN1QL(argDb: Database): List<Result> {
      // For Documentation -- N1QL Query using parameters
      val db = argDb
      // tag::query-syntax-n1ql[]
      val thisQuery = db.createQuery(
            "SELECT META().id AS id FROM _ WHERE type = \"hotel\"") // <.>

      return thisQuery.execute().allResults()

      // end::query-syntax-n1ql[]
  }

  fun docsOnlyQuerySyntaxN1QLParams(argDb: Database): List<Result> {
      // For Documentation -- N1QL Query using parameters
      val db = argDb
      // tag::query-syntax-n1ql-params[]
      val thisQuery = db.createQuery(
            "SELECT META().id AS id FROM _ WHERE type = \$type") // <.>

      thisQuery.parameters = Parameters().setString("type", "hotel") // <.>

      return thisQuery.execute().allResults()

      // end::query-syntax-n1ql-params[]
  }

  fun testQuerySyntaxPagination(currentUser: String) {
    // tag::query-syntax-pagination[]
    val limit = 20
    val offset = 0

    val rs = QueryBuilder
      .select(SelectResult.all())
      .from(DataSource.database(database))
      .where(Expression.property("type").equalTo(Expression.string("hotel")))
      .limit(Expression.intValue(limit), Expression.intValue(offset))

    // end::query-syntax-pagination[]
  }

    fun openOrCreateDatabaseForUser(argUser: String): Database = Database(argUser) {

    }



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/QueryExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/JSONExamples.kt 
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
import org.json.JSONException
import org.json.JSONObject


const val JSON = """[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\",
        \"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},
        {\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\",
        \"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},
        {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
        \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\",
        \"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]"""


class KtJSONExamples {
    private val TAG = "SNIPPETS"

    fun jsonArrayExample(db: Database) {
        // tag::tojson-array[]
        // initialize array from JSON string
        val mArray = MutableArray(JSON)
        
        // Create and save new document using the array
        for (i in 0 until mArray.count()) {
            mArray.getDictionary(i)?.apply {
                Log.i(TAG, getString("name") ?: "unknown")
                db.save(MutableDocument(getString("id"), toMap()))
            }
        }
        
        // Get an array from the document as a JSON string
        db.getDocument("1002")?.getArray("features")?.apply {
            // Print its elements
            for (feature in toList()) {
                Log.i(TAG, "$feature")
            }
            Log.i(TAG, toJSON())
        }
        // end::tojson-array[]
    }

    fun jsonBlobExample(db: Database) {
        // tag::tojson-blob[]
        val thisBlob = db.getDocument("thisdoc-id")!!.toMap()
        if (!Blob.isBlob(thisBlob)) {
          return
        }
        val blobType = thisBlob["content_type"].toString()
        val blobLength = thisBlob["length"] as Number?
        // end::tojson-blob[]
    }

    fun jsonDictionaryExample() {
        // tag::tojson-dictionary[]
        val mDict = MutableDictionary(JSON)
        Log.i(TAG, "$mDict")
        Log.i(TAG, "Details for: ${mDict.getString("name")}")
        for (key in mDict.keys) {
          Log.i(TAG, key + " => " + mDict.getValue(key))
        }
        // end::tojson-dictionary[]
      }

      @Throws(CouchbaseLiteException::class)
      fun jsonDocumentExample(srcDb: Database, dstDb: Database) {
        // tag::tojson-document[]
        QueryBuilder
        .select(SelectResult.expression(Meta.id).as("metaId"))
        .from(DataSource.database(srcDb))
        .execute()
        .forEach {
          it.getString("metaId")?.let { thisId ->
            // Get a document as a JSON string
            srcDb.getDocument(thisId)?.toJSON()?.let { json ->
              Log.i(TAG, "JSON String = $json")
              
              // Initialize a MutableDocument using the JSON string and save to a separate database
              val hotelFromJSON = MutableDocument(thisId, json)
              dstDb.save(hotelFromJSON)
              
              // Retrieve the document created from JSON and print values
              dstDb.getDocument(thisId)?.toMap()?.forEach { e ->
                Log.i(TAG, "$e.key => $e.value")
              }
            }
          }
        }
        // end::tojson-document[]
    }

    @Throws(CouchbaseLiteException::class, JSONException::class)
    fun jsonQueryExample(query: Query) {
        query.execute().forEach {

            // Use a Json Object to populate Native object
            JSONObject(it.toJSON()).apply {
                val (description, country, city, name, type, id) = Hotel(
                    id = getString("id"),
                    type = getString("type"),
                    name = getString("name"),
                    city = getString("city"),
                    country = "Ghana, West Africa",
                    description = "this hotel"
                )
            }
        }
    }
}


// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/JSONExamples.kt 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/BlobExamples.kt 
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

import android.content.Context
import android.util.Log
import com.couchbase.lite.Blob
import com.couchbase.lite.Database
import com.couchbase.lite.MutableDictionary

class KtBlobExamples {

    // Example 2: Using Blobs
    fun example2(context: Context, db: Database) {
        val doc = db.getDocument("1000") ?: return

        // Create a blob from an asset
        val blob = Blob("image/png", context.assets.open("couchbaseimage.png"))

        // This will fail:
        // IllegalStateException("A Blob may be encoded as JSON only after it has been saved in a database")
        blob.toJSON()

        // Save the blob as part of a document
        db.save(doc.toMutable().setBlob("avatar", blob))

        // Experts only!!!
        db.saveBlob(blob)

        // Retrieve saved blob and get as JSON again
        val blobAsJSONString = db.getDocument("1000")?.getBlob("avatar")?.toJSON() ?: return

        // reconstitute
        val blobAsMap = MutableDictionary().setJSON(blobAsJSONString).toMap()

        // show the contents of the reconstituted blob
        for ((key, value) in blobAsMap) {
            Log.d("BLOB", "Data: $key -> $value")
        }

        // verify that the reconstitued thing is still blob
        if (Blob.isBlob(blobAsMap)) {
            Log.d("BLOB", blobAsJSONString)
        }
    }
}


// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/android/examples/snippets/app/src/main/kotlin/com/couchbase/code_snippets/BlobExamples.kt 

