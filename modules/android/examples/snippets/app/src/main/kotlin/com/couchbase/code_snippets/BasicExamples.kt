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
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.Blob
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.DatabaseConfiguration
import com.couchbase.lite.DatabaseConfigurationFactory
import com.couchbase.lite.Document
import com.couchbase.lite.EncryptionKey
import com.couchbase.lite.Expression
import com.couchbase.lite.LogDomain
import com.couchbase.lite.LogFileConfigurationFactory
import com.couchbase.lite.LogLevel
import com.couchbase.lite.Meta
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Query
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.ResultSet
import com.couchbase.lite.SelectResult
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.UnitOfWork
import com.couchbase.lite.create
import com.couchbase.lite.internal.utils.PlatformUtils
import org.junit.Test
import java.io.File
import java.io.IOException
import java.net.URI
import java.net.URISyntaxException
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.Arrays
import java.util.Date


private const val TAG = "BASIC"

// tag::example-app[]
@Suppress("unused")
class BasicExamples(private val context: Context) {
    private val database: Database

    init {
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        // Get the database (and create it if it doesn’t exist).
        val config = DatabaseConfiguration()
        config.directory = context.filesDir.absolutePath
        database = Database("getting-started", config)
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
        val replicator = Replicator(
            ReplicatorConfigurationFactory.create(
                database = database,
                target = URLEndpoint(URI("ws://localhost:4984/getting-started-db")),
                type = ReplicatorType.PUSH_AND_PULL,
                authenticator = BasicAuthenticator("sync-gateway", "password".toCharArray())
            )
        )

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
        ZipUtils.unzip(PlatformUtils.getAsset("replacedb/android140-sqlite.cblite2.zip"), context.filesDir)

        val db = Database("android-sqlite", DatabaseConfiguration())
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
        val db = Database("my-db", DatabaseConfigurationFactory.create(context.filesDir.absolutePath)) // <.>
        // end::new-database[]
        db.delete()
    }

    // ### Database Encryption
    @Throws(CouchbaseLiteException::class)
    fun testDatabaseEncryption() {
        // tag::database-encryption[]
        val db = Database("my-db", DatabaseConfigurationFactory.create(encryptionKey = EncryptionKey("PASSWORD")))
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
        Database.log.custom = Examples.LogTestLogger(LogLevel.WARNING) // <.>
        // end::set-custom-logging[]
    }

    // ### Console logging
    @Throws(CouchbaseLiteException::class)
    fun testConsoleLogging() {
        // tag::console-logging[]
        Database.log.console.domains = LogDomain.ALL_DOMAINS // <.>
        Database.log.console.level = LogLevel.VERBOSE // <.>
        // end::console-logging[]
    }

    // ### File logging
    @Throws(CouchbaseLiteException::class)
    fun testFileLogging() {
        // tag::file-logging[]
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
    }

    fun writeConsoleLog() {
        // tag::write-console-logmsg[]
        Database.log.console.log(LogLevel.WARNING, LogDomain.REPLICATOR, "Any old log message")
        // end::write-console-logmsg[]
    }

    fun writeCustomLog() {
        // tag::write-custom-logmsg[]
        Database.log.custom?.log(LogLevel.WARNING, LogDomain.REPLICATOR, "Any old log message")
        // end::write-custom-logmsg[]
    }

    fun writeFileLog() {
        // tag::write-file-logmsg[]
        Database.log.file.log(LogLevel.WARNING, LogDomain.REPLICATOR, "Any old log message")
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
        Database.copy(File(context.filesDir, "travel-sample"), "travel-sample", DatabaseConfiguration())
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
                Log.i(TAG, "saved user document: ${doc.getString("name")}")
            }
        })
        // end::batch[]
    }

    // ### Document Expiration
    @Throws(CouchbaseLiteException::class)
    fun documentExpiration() {
        // tag::document-expiration[]
        // Purge the document one day from now
        database.setDocumentExpiration("doc123", Date(Instant.now().plus(1, ChronoUnit.DAYS).toEpochMilli()))

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
                Toast.makeText(context, "Status: ${it.getString("verified_account")}", Toast.LENGTH_SHORT).show()
            }
        }
        // end::document-listener[]
    }

    // ### Blobs
    fun testBlobs() {
        val mDoc = MutableDocument()

        // tag::blob[]
        PlatformUtils.getAsset("avatar.jpg")?.use {
            mDoc.setBlob("avatar", Blob("image/jpeg", it))
            database.save(mDoc)
        }

        val doc = database.getDocument(mDoc.id)
        val bytes = doc?.getBlob("avatar")?.content
        // end::blob[]
    }
}
