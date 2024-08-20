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
@file:Suppress("UNUSED_VARIABLE", "unused")

package com.couchbase.codesnippets

import android.content.Context
import com.couchbase.codesnippets.util.getAsset
import com.couchbase.codesnippets.util.log
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.Blob
import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLite
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
import com.couchbase.lite.Logger
import com.couchbase.lite.Meta
import com.couchbase.lite.MutableArray
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.SelectResult
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.UnitOfWork
import com.couchbase.lite.newConfig
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.URI
import java.util.*
import java.util.zip.ZipInputStream


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
class BasicExamples(private val context: Context) {
    private var database: Database? = null

    init {
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        // Get the database (and create it if it doesn’t exist).
        // tag::database-config-factory[]
        database = Database(
            "getting-started",
            DatabaseConfigurationFactory.newConfig()
        )
        // end::database-config-factory[]
    }

    fun replicatorConfigFactory(db: Database) {
        //  tag::replicator-config-factory[]
        val replicator =
            Replicator(
                ReplicatorConfigurationFactory.newConfig(
                    collections = mapOf(db.collections to null),
                    target = URLEndpoint(URI("ws://localhost:4984/getting-started-db")),
                    type = ReplicatorType.PUSH_AND_PULL,
                    authenticator = BasicAuthenticator("sync-gateway", "password".toCharArray())
                )
            )
        //  end::replicator-config-factory[]
    }

    fun oneXAttachmentsExample(document: Document) {
        // tag::1x-attachment[]
        val content = document.getDictionary("_attachments")?.getBlob("avatar")?.content
        // end::1x-attachment[]
    }

    // ### New Database
    fun newDatabaseExample() {
        // tag::new-database[]
        val database = Database(
            "my-db",
            DatabaseConfigurationFactory.newConfig()
        ) // <.>
        // end::new-database[]
        // tag::close-database[]
        database.close()

        // end::close-database[]

        database.delete()
    }

    fun databaseFullSyncExample() {
        // tag::database-fullsync[]
        val db = Database(
            "my-db",
            DatabaseConfigurationFactory.newConfig(
                fullSync = true
            )
        )
        // end::database-fullsync[]
    }

    // ### Database Encryption
    fun databaseEncryptionExample() {
        // tag::database-encryption[]
        val db = Database(
            "my-db",
            DatabaseConfigurationFactory.newConfig(
                encryptionKey = EncryptionKey("PASSWORD")
            )
        )

        // end::database-encryption[]
    }

    // ### Logging
    // !!!GBM: OBSOLETE in 3.0
    fun loggingExample() {
        // tag::logging[]
        // end::logging[]
    }

    fun enableCustomLoggingExample() {
        // tag::set-custom-logging[]
        // this custom logger will not log an event with a log level < WARNING
        Database.log.custom = LogTestLogger(LogLevel.WARNING) // <.>
        // end::set-custom-logging[]
    }

    // ### Console logging
    fun consoleLoggingExample() {
        // tag::console-logging[]
        Database.log.console.domains = LogDomain.ALL_DOMAINS // <.>
        Database.log.console.level = LogLevel.VERBOSE // <.>
        // end::console-logging[]

        // tag::console-logging-db[]
        Database.log.console.domains = EnumSet.of(LogDomain.DATABASE) // <.>
        // end::console-logging-db[]
    }

    // ### File logging
    fun fileLoggingExample() {
        // tag::file-logging[]
        // tag::file-logging-config-factory[]
        Database.log.file.let {
            it.config = LogFileConfigurationFactory.newConfig(
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

    // ### Loading a pre-built database
    fun preBuiltDatabaseExample() {
        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        // For Android you need to extract the database from your assets
        // to a temporary directory and then copy it, using Database.copy()
        if (Database.exists("travel-sample", context.filesDir)) {
            return
        }
        ZipUtils.unzip(getAsset("travel-sample.cblite2.zip"), context.filesDir)
        Database.copy(
            File(context.filesDir, "travel-sample"),
            "travel-sample",
            DatabaseConfiguration()
        )
        // end::prebuilt-database[]
    }

    // ### Initializers
    fun initializersExample(collection: Collection) {
        // tag::initializer[]
        val doc = MutableDocument()
        doc.let {
            it.setString("type", "task")
            it.setString("owner", "todo")
            it.setDate("createdAt", Date())
        }
        collection.save(doc)
        // end::initializer[]
    }


    // ### Mutability
    fun mutabilityExample(collection: Collection) {
        collection.save(MutableDocument("xyz"))

        // tag::update-document[]
        collection.getDocument("xyz")?.toMutable()?.let {
            it.setString("name", "apples")
            collection.save(it)
        }
        // end::update-document[]
    }

    // ### Typed Accessors
    fun typedAccessorsExample() {
        val doc = MutableDocument()

        // tag::date-getter[]
        doc.setValue("createdAt", Date())
        val date = doc.getDate("createdAt")
        // end::date-getter[]
    }

    // ### Batch operations
    fun batchOperationsExample(database: Database) {
        // tag::batch[]
        database.inBatch(UnitOfWork {
            for (i in 0..9) {
                val doc = MutableDocument()
                doc.let {
                    it.setValue("type", "user")
                    it.setValue("name", "user $i")
                    it.setBoolean("admin", false)
                }
                log("saved user document: ${doc.getString("name")}")
            }
        })
        // end::batch[]
    }

    fun useExplicitType(collection: Collection, someDoc: Document) {
        // tag::fleece-data-encoding[]
        val doc = collection.getDocument (someDoc.id)
        // force longVal to be type Long, even if it could be represented as an Int.
        val longVal = doc?.getLong(("test"))
        // end::fleece-data-encoding[]
    }

    // toJSON
    fun toJsonOperationsExample(argDb: Database) {
        val db = argDb

    }


    // ### Document Expiration
    fun documentExpiration(collection: Collection) {
        // tag::document-expiration[]
        // Purge the document one day from now
        collection.setDocumentExpiration(
            "doc123",
            Date(System.currentTimeMillis() + (1000 * 60 * 60 * 24))
        )

        // Reset expiration
        collection.setDocumentExpiration("doc1", null)

        // Query documents that will be expired in less than five minutes
        val query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(
                Meta.expiration.lessThan(
                    Expression.longValue(System.currentTimeMillis() + (1000 * 60 * 5))
                )
            )
        // end::document-expiration[]
    }

    fun documentChangeListenerExample(collection: Collection) {
        // tag::document-listener[]
        collection.addDocumentChangeListener("user.john") { change ->
            collection.getDocument(change.documentID)?.let {
                log("Status: ${it.getString("verified_account")}")
            }
        }
        // end::document-listener[]
    }

    // ### Blobs
    fun blobsExample(collection: Collection) {
        val mDoc = MutableDocument()

        // tag::blob[]
        getAsset("avatar.jpg")?.use { // <.>
            mDoc.setBlob("avatar", Blob("image/jpeg", it)) // <.> <.>
            collection.save(mDoc)
        }

        val doc = collection.getDocument(mDoc.id)
        val bytes = doc?.getBlob("avatar")?.content
        // end::blob[]
    }
}

class SupportingDatatypes(private val context: Context) {

    fun datatypeUsage() {
        // tag::datatype_usage[]
        // tag::datatype_usage_createdb[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        // Get the database (and create it if it doesn’t exist).
        val config = DatabaseConfiguration()
        config.directory = context.filesDir.absolutePath
        val database = Database("getting-started", config)
        val collection = database.getCollection("myCollection")
            ?: throw IllegalStateException("collection not found")

        // end::datatype_usage_createdb[]
        // tag::datatype_usage_createdoc[]
        // Create your new document
        val mutableDoc = MutableDocument()

        // end::datatype_usage_createdoc[]
        // tag::datatype_usage_mutdict[]
        // Create and populate mutable dictionary
        // Create a new mutable dictionary and populate some keys/values
        val address = MutableDictionary()
        address.setString("street", "1 Main st.")
        address.setString("city", "San Francisco")
        address.setString("state", "CA")
        address.setString("country", "USA")
        address.setString("code", "90210")

        // end::datatype_usage_mutdict[]
        // tag::datatype_usage_mutarray[]
        // Create and populate mutable array
        val phones = MutableArray()
        phones.addString("650-000-0000")
        phones.addString("650-000-0001")

        // end::datatype_usage_mutarray[]
        // tag::datatype_usage_populate[]
        // Initialize and populate the document

        // Add document type to document properties <.>
        mutableDoc.setString("type", "hotel")

        // Add hotel name string to document properties <.>
        mutableDoc.setString("name", "Hotel Java Mo")

        // Add float to document properties <.>
        mutableDoc.setFloat("room_rate", 121.75f)

        // Add dictionary to document's properties <.>
        mutableDoc.setDictionary("address", address)

        // Add array to document's properties <.>
        mutableDoc.setArray("phones", phones)

        // end::datatype_usage_populate[]
        // tag::datatype_usage_persist[]
        // Save the document changes <.>
        collection.save(mutableDoc)

        // end::datatype_usage_persist[]
        // tag::datatype_usage_closedb[]
        // Close the database <.>
        database.close()

        // end::datatype_usage_closedb[]

        // end::datatype_usage[]
    }


    fun datatypeDictionary(collection: Collection) {

        // tag::datatype_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)
        val document = collection.getDocument("doc1")

        // Getting a dictionary from the document's properties
        val dict = document?.getDictionary("address")

        // Access a value with a key from the dictionary
        val street = dict?.getString("street")

        // Iterate dictionary
        for (key in dict!!.keys) {
            println("Key ${key} = ${dict.getValue(key)}")
        }

        // Create a mutable copy
        val mutableDict = dict.toMutable()

        // end::datatype_dictionary[]
    }

    fun datatypeMutableDictionary(collection: Collection) {

        // tag::datatype_mutable_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)

        // Create a new mutable dictionary and populate some keys/values
        val mutableDict = MutableDictionary()
        mutableDict.setString("street", "1 Main st.")
        mutableDict.setString("city", "San Francisco")

        // Add the dictionary to a document's properties and save the document
        val mutableDoc = MutableDocument("doc1")
        mutableDoc.setDictionary("address", mutableDict)
        collection.save(mutableDoc)

        // end::datatype_mutable_dictionary[]
    }


    fun datatypeArray(collection: Collection) {

        // tag::datatype_array[]
        // NOTE: No error handling, for brevity (see getting started)

        val document = collection.getDocument("doc1")

        // Getting a phones array from the document's properties
        val array = document?.getArray("phones")

        // Get element count
        val count = array?.count()

        // Access an array element by index
        val phone = array?.getString(1)

        // Iterate array
        array?.forEachIndexed { index, item -> println("Row  ${index} = ${item}") }

        // Create a mutable copy
        val mutableArray = array?.toMutable()
        // end::datatype_array[]
    }

    fun datatypeMutableArray(collection: Collection) {

        // tag::datatype_mutable_array[]
        // NOTE: No error handling, for brevity (see getting started)

        // Create a new mutable array and populate data into the array
        val mutableArray = MutableArray()
        mutableArray.addString("650-000-0000")
        mutableArray.addString("650-000-0001")

        // Set the array to document's properties and save the document
        val mutableDoc = MutableDocument("doc1")
        mutableDoc.setArray("phones", mutableArray)
        collection.save(mutableDoc)
        // end::datatype_mutable_array[]
    }

} // end  class supporting_datatypes


// tag::ziputils-unzip[]
object ZipUtils {
    fun unzip(src: InputStream?, dst: File?) {
        val buffer = ByteArray(1024)
        src?.use { sis ->
            ZipInputStream(sis).use { zis ->
                var ze = zis.nextEntry
                while (ze != null) {
                    val newFile = File(dst, ze.name)
                    if (ze.isDirectory) {
                        newFile.mkdirs()
                    } else {
                        File(newFile.parent!!).mkdirs()
                        FileOutputStream(newFile).use { fos ->
                            var len: Int
                            while (zis.read(buffer).also { len = it } > 0) {
                                fos.write(buffer, 0, len)
                            }
                        }
                    }
                    ze = zis.nextEntry
                }
                zis.closeEntry()
            }
        }
    }
}
