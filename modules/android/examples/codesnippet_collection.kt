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

    // ### Database FullSync
    fun DatabaseFullSyncExample() {
        // tag::database-fullsync[]
        val database = Database(
            "my-db",
            DatabaseConfigurationFactory.newConfig(
                fullSync = true
            )
        ) 
        // end::database-fullsync[]
        
        config.setFullSync()
        
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
@file:Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE", "UNUSED_VALUE", "UNUSED_VARIABLE", "unused")

package com.couchbase.codesnippets

import com.couchbase.codesnippets.utils.Logger
import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.ValueIndexConfiguration
import com.couchbase.lite.ValueIndexItem


class CollectionExamples {
    // We need to add a code sample to create a new collection in a scope
    @Throws(CouchbaseLiteException::class)
    fun createCollectionInScope(db: Database) {
        // tag::scopes-manage-create-collection[]
        // create the collection "Verlaine" in the default scope ("_default")
        var collection1: Collection? = db.createCollection("Verlaine")
        // both of these retrieve collection1 created above
        collection1 = db.getCollection("Verlaine")
        collection1 = db.defaultScope.getCollection("Verlaine")

        // create the collection "Verlaine" in the scope "Television"
        var collection2: Collection? = db.createCollection("Television", "Verlaine")
        // both of these retrieve  collection2 created above
        collection2 = db.getCollection("Television", "Verlaine")
        collection2 = db.getScope("Television")!!.getCollection("Verlaine")
        // end::scopes-manage-create-collection[]
    }

    // We need to add a code sample to index a collection
    @Throws(CouchbaseLiteException::class)
    fun createIndexInCollection(collection: Collection) {
        // tag::scopes-manage-index-collection[]
        // Create an index named "nameIndex1" on the property "lastName" in the collection using the IndexBuilder
        collection.createIndex("nameIndex1", IndexBuilder.valueIndex(ValueIndexItem.property("lastName")))

        // Create a similar index named "nameIndex2" using and IndexConfiguration
        collection.createIndex("nameIndex2", ValueIndexConfiguration("lastName"))

        // get the names of all the indices in the collection
        val indices = collection.indexes

        // delete all the collection indices
        indices.forEach { collection.deleteIndex(it) }
        // end::scopes-manage-index-collection[]
    }

    // We need to add a code sample to drop a collection
    @Throws(CouchbaseLiteException::class)
    fun deleteCollection(db: Database, collectionName: String, scopeName: String) {
        // tag::scopes-manage-drop-collection[]
        db.getCollection(collectionName, scopeName)?.let {
            db.deleteCollection(it.name, it.scope.name)
        }
        // end::scopes-manage-drop-collection[]
    }

    // We need to add a code sample to list scopes and collections
    @Throws(CouchbaseLiteException::class)
    fun listScopesAndCollections(db: Database) {
        // tag::scopes-manage-list[]
        // List all of the collections in each of the scopes in the database
        db.scopes.forEach { scope ->
            Logger.log("Scope :: " + scope.name)
            scope.collections.forEach {
                Logger.log("    Collection :: " + it.name)
            }
        }
        // end::scopes-manage-list[]
    }
}
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

import com.couchbase.lite.Database
import com.couchbase.lite.DatabaseEndpoint
import com.couchbase.lite.ListenerToken
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorChangeListener
import com.couchbase.lite.ReplicatorConfiguration
import com.couchbase.lite.ReplicatorType
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.RejectedExecutionHandler
import java.util.concurrent.SynchronousQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference



class InOrderExecutionExample {
    private var thisReplicator: Replicator? = null
    private var thisToken: ListenerToken? = null

    // tag::execution-inorder[]
    companion object {
        private val IN_ORDER_EXEC: ExecutorService = Executors.newSingleThreadExecutor()
    }

    /**
     * This version guarantees in order delivery and is parsimonious with space
     * The listener does not need to be thread safe (at least as far as this code is concerned).
     * It will run on only thread (the Executor's thread) and must return from a given call
     * before the next call commences.  Events may be delivered arbitrarily late, though,
     * depending on how long it takes the listener to run.
     */
    fun runInOrder(collection: Collection<*>?, target: Database?) {
        val repl = Replicator(
            ReplicatorConfiguration(DatabaseEndpoint(target!!))
                .setType(ReplicatorType.PUSH_AND_PULL)
                .setContinuous(false)
        )

        thisToken = repl.addChangeListener(IN_ORDER_EXEC) { TODO() }

        repl.start()
        thisReplicator = repl
    }
    // end::execution-inorder[]
}

class MaxThroughputExecutionExample {
    private var thisReplicator: Replicator? = null
    private var thisToken: ListenerToken? = null

    // tag::execution-maxthroughput[]
    companion object {
        private val MAX_THROUGHPUT_EXEC: ExecutorService = Executors.newCachedThreadPool()
    }

    /**
     * This version maximizes throughput.  It will deliver change notifications as quickly
     * as CPU availability allows. It may deliver change notifications out of order.
     * Listeners must be thread safe because they may be called from multiple threads.
     * In fact, they must be re-entrant because a given listener may be running on mutiple threads
     * simultaneously.  In addition, when notifications swamp the processors, notifications awaiting
     * a processor will be queued as Threads, (instead of as Runnables) with accompanying memory
     * and GC impact.
     */
    fun runMaxThroughput(collection: Collection<*>?, target: Database?) {
        val repl = Replicator(
            ReplicatorConfiguration(DatabaseEndpoint(target!!))
                .setType(ReplicatorType.PUSH_AND_PULL)
                .setContinuous(false)
        )
        thisToken = repl.addChangeListener(MAX_THROUGHPUT_EXEC) { TODO() }

        repl.start()
        thisReplicator = repl
    }
    // end::execution-maxthroughput[]
}

class PoliciedExecutionExample {
    private var thisReplicator: Replicator? = null
    private var thisToken: ListenerToken? = null

    // end::execution-maxthroughput[]
    companion object {
        private val CPUS = Runtime.getRuntime().availableProcessors()
        private val BACKUP_EXEC: AtomicReference<ThreadPoolExecutor> = AtomicReference()
        private val BACKUP_EXECUTION = RejectedExecutionHandler { r, _ ->
            val exec = BACKUP_EXEC.get()
            if (exec != null) {
                exec.execute(r)
            } else {
                BACKUP_EXEC.compareAndSet(null, createBackupExecutor())
                BACKUP_EXEC.get().execute(r)
            }
        }

        private fun createBackupExecutor(): ThreadPoolExecutor {
            val exec = ThreadPoolExecutor(
                CPUS + 1,
                2 * CPUS + 1,
                30, TimeUnit.SECONDS,
                LinkedBlockingQueue()
            )
            exec.allowCoreThreadTimeOut(true)
            return exec
        }

        private val STANDARD_EXEC: ThreadPoolExecutor = ThreadPoolExecutor(
            CPUS + 1,
            2 * CPUS + 1,
            30, TimeUnit.SECONDS,
            SynchronousQueue()
        )

        init {
            STANDARD_EXEC.rejectedExecutionHandler = BACKUP_EXECUTION
        }
    }

    /**
     * This version demonstrates the extreme configurability of the Couchbase Lite replicator callback system.
     * It may deliver updates out of order and does require thread-safe and re-entrant listeners
     * (though it does correctly synchronize tasks passed to it using a SynchronousQueue).
     * The thread pool executor shown here is configured for the sweet spot for number of threads per CPU.
     * In a real system, this single executor might be used by the entire application and be passed to
     * this module, thus establishing a reasonable app-wide threading policy.
     * In an emergency (Rejected Execution) it lazily creates a backup executor with an unbounded queue
     * in front of it.  It, thus, may deliver notifications late, as well as out of order.
     */
    fun runExecutionPolicy(collection: Collection<*>?, target: Database?, listener: ReplicatorChangeListener?) {
        val repl = Replicator(
            ReplicatorConfiguration(DatabaseEndpoint(target!!))
                .setType(ReplicatorType.PUSH_AND_PULL)
                .setContinuous(false)
        )
        thisToken = repl.addChangeListener(STANDARD_EXEC) { TODO() }
        repl.start()
        thisReplicator = repl
    }
}

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

import androidx.lifecycle.LiveData
import androidx.lifecycle.asLiveData
import com.couchbase.lite.Collection
import com.couchbase.lite.DocumentChange
import com.couchbase.lite.Query
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorActivityLevel
import com.couchbase.lite.Result
import com.couchbase.lite.collectionChangeFlow
import com.couchbase.lite.documentChangeFlow
import com.couchbase.lite.queryChangeFlow
import com.couchbase.lite.replicatorChangesFlow
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapNotNull


class FlowExamples {

    fun replChangeFlowExample(repl: Replicator): LiveData<ReplicatorActivityLevel> {
        // tag::flow-as-replicator-change-listener[]
        return repl.replicatorChangesFlow()
            .map { it.status.activityLevel }
            .asLiveData()
        // end::flow-as-replicator-change-listener[]
    }

    fun replChangeFlowExample(collection: Collection): LiveData<MutableList<String>> {
        // tag::flow-as-database-change-listener[]
        return collection.collectionChangeFlow(null)
            .map { it.documentIDs }
            .asLiveData()
        // end::flow-as-database-change-listener[]
    }

    fun docChangeFlowExample(collection: Collection, owner: String): LiveData<DocumentChange?> {
        // tag::flow-as-document-change-listener[]
        return collection.documentChangeFlow("1001")
            .mapNotNull { change ->
                change.takeUnless {
                    collection.getDocument(it.documentID)?.getString("owner").equals(owner)
                }
            }
            .asLiveData()
        // end::flow-as-document-change-listener[]
    }

    // tag::flow-as-query-change-listener[]
    fun watchQuery(query: Query): LiveData<List<Result>> {
        return query.queryChangeFlow()
            .mapNotNull { change ->
                val err = change.error
                if (err != null) {
                    throw err
                }
                change.results?.allResults()
            }
            .asLiveData()
    }
    // end::flow-as-query-change-listener[]
}
package com.couchbase.codesnippets

data class Hotel(
    var description: String? = null,
    var country: String? = null,
    var city: String? = null,
    var name: String? = null,
    var type: String? = null,
    var id: String? = null
)//
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

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.Blob
import com.couchbase.lite.Collection
import com.couchbase.lite.DataSource
import com.couchbase.lite.Meta
import com.couchbase.lite.MutableArray
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Query
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.SelectResult
import org.json.JSONObject


const val JSON = """[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\",
        \"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},
        {\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\",
        \"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},
        {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
        \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\",
        \"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]"""

private const val TAG = "SNIPPETS"

class KtJSONExamples {


    fun jsonArrayExample(collection: Collection) {
        // tag::tojson-array[]
        // github tag=tojson-array
        val mArray = MutableArray(JSON) // <.>
        for (i in 0 until mArray.count()) {
            mArray.getDictionary(i)?.apply {
                log(getString("name") ?: "unknown")
                collection.save(MutableDocument(getString("id"), toMap()))
            } // <.>
        }

        collection.getDocument("1002")?.getArray("features")?.apply {
            for (feature in toList()) {
                log("$feature")
            } // <.>
            log(toJSON())
        } // <.>
        // end::tojson-array[]
    }

    fun jsonBlobExample(collection: Collection) {
        // tag::tojson-blob[]
        // github tag=tojson-blob
        val thisBlob = collection.getDocument("thisdoc-id")!!.toMap()
        if (!Blob.isBlob(thisBlob)) {
            return
        }
        val blobType = thisBlob["content_type"].toString()
        val blobLength = thisBlob["length"] as Number?
        // end::tojson-blob[]
    }

    fun jsonDictionaryExample() {
        // tag::tojson-dictionary[]
        // github tag=tojson-dictionary
        val mDict = MutableDictionary(JSON) // <.>
        log("$mDict")
        log("Details for: ${mDict.getString("name")}")
        mDict.keys.forEach { key ->
            log(key + " => " + mDict.getValue(key))
        }
        // end::tojson-dictionary[]
    }

    fun jsonDocumentExample(srcColl: Collection, dstColl: Collection) {
        // tag::tojson-document[]
        QueryBuilder
            .select(SelectResult.expression(Meta.id).`as`("metaId"))
            .from(DataSource.collection(srcColl))
            .execute()
            .forEach {
                it.getString("metaId")?.let { thisId ->
                    srcColl.getDocument(thisId)?.toJSON()?.let { json -> // <.>
                        log("JSON String = $json")
                        val hotelFromJSON = MutableDocument(thisId, json) // <.>
                        dstColl.save(hotelFromJSON)
                        dstColl.getDocument(thisId)?.toMap()?.forEach { e ->
                            log("$e.key => $e.value")
                        } // <.>
                    }
                }
            }
        // end::tojson-document[]
    }

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
}//
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

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.KeyStoreUtils
import com.couchbase.lite.ListenerCertificateAuthenticator
import com.couchbase.lite.ListenerPasswordAuthenticator
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpointListener
import com.couchbase.lite.URLEndpointListenerConfiguration
import com.couchbase.lite.URLEndpointListenerConfigurationFactory
import com.couchbase.lite.newConfig
import java.io.File
import java.io.IOException
import java.net.URI
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.NoSuchAlgorithmException
import java.security.cert.Certificate
import java.security.cert.CertificateException

private const val TAG = "LISTEN"

@Suppress("unused")
class ListenerExamples {
    private var thisListener: URLEndpointListener? = null

    // tag::listener-config-auth-cert-full[]
    /**
     * Snippet 2: create a ListenerCertificateAuthenticator and configure the listener with it
     *
     *
     * Start a listener for db that accepts connections from a client identified by any of the passed certs
     *
     * @param collections the collections to which the listener is attached
     * @param certs the name of the single valid user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Throws(CouchbaseLiteException::class)
    fun startServer(collections: Set<Collection>, serverId: TLSIdentity, certs: List<Certificate?>): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                collections = collections,
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


    fun listenerConfigClientAuthLambdaExample(thisConfig: URLEndpointListenerConfiguration) {
        // tag::listener-config-client-auth-lambda[]
        // Configure authentication using application logic
        val thisCorpId = TLSIdentity.getIdentity("OurCorp") // <.>
            ?: throw IllegalStateException("Cannot find corporate id")

        thisConfig.tlsIdentity = thisCorpId

        thisConfig.authenticator = ListenerCertificateAuthenticator { certs ->
            // supply logic that returns boolean
            // true for authenticate, false if not
            // For instance:
            certs[0] == thisCorpId.certs[0]
        } // <.> <.>


        val thisListener = URLEndpointListener(thisConfig)

        // end::listener-config-client-auth-lambda[]
    }

    fun listenerConfigClientAuthRootExample(collections: Set<Collection>) {
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
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                // get the identity <.>
                collections = collections,
                identity = validId,
                authenticator = ListenerCertificateAuthenticator(validId.certs)
            )
        ) // <.>

        // end::listener-config-client-auth-root[]
        // end::listener-config-client-root-ca[]
    }

    fun listenerConfigTlsIdFullExample(keyFile: File, collections: Set<Collection>) {
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]

        // Import a key pair into secure storage
        // Create a TLSIdentity from the imported key-pair
        // This only needs to happen once.  Once the key is in the internal store
        // it can be referenced using its alias
        // This method of importing a key is insecure
        // Android has better ways of importing keys
        keyFile.inputStream().use { // <.>
            KeyStoreUtils.importEntry(
                "PKCS12",  // KeyStore type, eg: "PKCS12"
                it,  // An InputStream from the keystore
                "let me in".toCharArray(),  // The keystore password
                "topSekritKey",  // The alias to be used (in external keystore)
                null,  // The key password or null if the key has none
                "test-alias" // The alias for the imported key
            )
        }

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        URLEndpointListenerConfigurationFactory.newConfig(
            collections,
            identity = TLSIdentity.getIdentity("test-alias")
        ) // <.>
        // end::listener-config-tls-id-caCert[]

        // end::listener-config-tls-id-set[]
        // end::listener-config-tls-id-full[]
    }

    fun deleteIdentityExample(alias: String) {
        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        val thisKeyStore = KeyStore.getInstance("AndroidKeyStore")
        thisKeyStore.load(null)
        thisKeyStore.deleteEntry(alias)

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]
    }

    fun listenerGetNetworkInterfacesExample(collections: Set<Collection>) {
        // tag::listener-get-network-interfaces[]
        val listener = URLEndpointListener(URLEndpointListenerConfigurationFactory.newConfig(collections))
        listener.start()
        thisListener = listener
        log("URLS are ${listener.urls}")
        // end::listener-get-network-interfaces[]
    }


    // tag::listener-config-client-auth-pwd-full[]
    /**
     *
     * Start a listener for db that accepts connections using exactly the passed username and password
     *
     *
     * @param collections       the set of collections to which the listener is attached
     * @param username the name of the single valid user
     * @param password the password for the user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    fun startServer(collections: Set<Collection>, username: String, password: CharArray): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                collections = collections,
                port = 0,// this is the default
                disableTls = true,
                authenticator = ListenerPasswordAuthenticator { usr, pwd ->
                    (usr == username) && (pwd.contentEquals(password))
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
    // notend::listener-config-client-auth-pwd-full[]


    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    // Create a TLSIdentity for the server using convenience API.
    // System generates self-signed cert
    companion object {
        val CERT_ATTRIBUTES = mapOf( //<.>
            TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
            TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
        )
    }

    // Store the TLS identity in secure storage
    // under the label 'couchbase-docs-cert'
    fun listenerWithSelfSignedCert(thisConfig: URLEndpointListenerConfiguration) {
        val thisIdentity = TLSIdentity.createIdentity(
            true,
            CERT_ATTRIBUTES,
            null,
            "couchbase-docs-cert"
        ) // <.>

        // end::listener-config-tls-id-SelfSigned[]

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        thisConfig.tlsIdentity = thisIdentity // <.>

        // end::listener-config-tls-id-set[]
    }

    fun passiveListenerExample(collections: Set<Collection>, validUser: String, validPass: CharArray) {
        // EXAMPLE 1
        // tag::listener-start[]
        // Initialize the listener
        // tag::listener-initialize[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                // tag::listener-config-db[]
                collections = collections, // <.>
                // end::listener-config-db[]
                // tag::listener-config-port[]
                port = 55990, // <.>
                // end::listener-config-port[]
                // tag::listener-config-netw-iface[]
                networkInterface = "wlan0", // <.>

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
                authenticator = ListenerPasswordAuthenticator { usr, pwd ->
                    (usr === validUser) && (validPass.contentEquals(pwd))
                }
            ))

        // Start the listener
        listener.start() // <.>
        // end::listener-initialize[]
        // end::listener-start[]
    }

    fun simpleListenerExample(db: Database) {
        // tag::listener-simple[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                collections = db.collections,
                authenticator = ListenerPasswordAuthenticator { user, pwd ->
                    (user == "daniel") && (String(pwd) == "123")  // <.>
                })
        )
        listener.start() // <.>
        thisListener = listener

        // end::listener-simple[]
    }

    fun overrideConfigExample(db: Database) {
        // tag::override-config[]
        val listener8080 = URLEndpointListenerConfigurationFactory.newConfig(
            networkInterface = "en0",
            port = 8080
        )
        val listener8081 = listener8080.newConfig(port = 8081)
        // end::override-config[]
    }

    fun listenerStatusCheckExample(db: Database) {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory
                .newConfig(collections = db.collections)
        )
        listener.start()
        thisListener = listener
        // tag::listener-status-check[]
        val connectionCount = listener.status?.connectionCount // <.>
        val activeConnectionCount = listener.status?.activeConnectionCount // <.>
        // end::listener-status-check[]
    }

    fun listenerStopExample() {
        // tag::listener-stop[]
        val listener = thisListener
        thisListener = null
        listener?.stop()

        // end::listener-stop[]
    }

}


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

import com.couchbase.lite.Collection
import com.couchbase.lite.Conflict
import com.couchbase.lite.ConflictResolver
import com.couchbase.lite.Document
import com.couchbase.lite.MutableDocument
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream


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

    fun testSaveWithCustomConflictResolver(collection: Collection) {
        // tag::update-document-with-conflict-handler[]
        val mutableDocument = collection.getDocument("xyz")?.toMutable() ?: return
        mutableDocument.setString("name", "apples")
        collection.save(mutableDocument) { newDoc, curDoc ->  // <.>
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

import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLiteException
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
import com.couchbase.lite.newConfig


@Suppress("unused")
class BrowserSessionManager : MessageEndpointDelegate {
    private var replicator: Replicator? = null

    fun initCouchbase(collections: Set<Collection>) {
        // tag::message-endpoint[]

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        val messageEndpoint = MessageEndpoint("UID:123", "active", ProtocolType.MESSAGE_STREAM, this)
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        // Create the replicator object.
        val repl = Replicator(
            ReplicatorConfigurationFactory.newConfig(
                collections = mapOf(collections to null),
                target = messageEndpoint
            )
        )

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
class PassivePeerConnection : MessageEndpointConnection {
    private var listener: MessageEndpointListener? = null
    private var replicatorConnection: ReplicatorConnection? = null

    @Throws(CouchbaseLiteException::class)
    fun startListener(collections: Set<Collection>) {
        // tag::listener[]
        listener = MessageEndpointListener(
            MessageEndpointListenerConfigurationFactory.newConfig(collections, ProtocolType.MESSAGE_STREAM)
        )
        // end::listener[]
    }

    fun stopListener() {
        // tag::passive-stop-listener[]
        listener?.closeAll()
        // end::passive-stop-listener[]
    }

    fun accept() {
        // tag::advertizer-accept[]
        val connection = PassivePeerConnection() /* implements MessageEndpointConnection */
        listener?.accept(connection)
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

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.Collection
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.Dictionary
import com.couchbase.lite.Expression
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.PredictionFunction
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndexItem


private const val TAG = "PREDICT"

// tag::predictive-model[]
// tensorFlowModel is a fake implementation
object TensorFlowModel {
    fun predictImage(data: ByteArray?): Map<String, Any?> = TODO()
}

object ImageClassifierModel : PredictiveModel {
    const val name = "ImageClassifier"

    // this would be the implementation of the ml model you have chosen
    override fun predict(input: Dictionary) = input.getBlob("photo")?.let {
        MutableDictionary(TensorFlowModel.predictImage(it.content)) // <1>
    }
}
// end::predictive-model[]


fun predictiveModelExamples(collection: Collection) {

    // tag::register-model[]
    Database.prediction.registerModel("ImageClassifier", ImageClassifierModel)
    // end::register-model[]

    // tag::predictive-query-value-index[]
    collection.createIndex(
        "value-index-image-classifier",
        IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")))
    )
    // end::predictive-query-value-index[]

    // tag::unregister-model[]
    Database.prediction.unregisterModel("ImageClassifier")
    // end::unregister-model[]
}


fun predictiveIndexExamples(collection: Collection) {

    // tag::predictive-query-predictive-index[]
    val inputMap: Map<String, Any?> = mutableMapOf("numbers" to Expression.property("photo"))
    collection.createIndex(
        "predictive-index-image-classifier",
        IndexBuilder.predictiveIndex("ImageClassifier", Expression.map(inputMap), null)
    )
    // end::predictive-query-predictive-index[]
}


fun predictiveQueryExamples(collection: Collection) {

    // tag::predictive-query[]
    val inputMap: Map<String, Any?> = mutableMapOf("photo" to Expression.property("photo"))
    val prediction: PredictionFunction = Function.prediction(
        ImageClassifierModel.name,
        Expression.map(inputMap) // <1>
    )

    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            prediction.propertyPath("label").equalTo(Expression.string("car"))
                .and(
                    prediction.propertyPath("probability")
                        .greaterThanOrEqualTo(Expression.doubleValue(0.8))
                )
        )

    query.execute().use {
        log("Number of rows: ${it.allResults().size}")
    }
    // end::predictive-query[]
}
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
@file:Suppress("UNUSED_VARIABLE", "unused", "UNUSED_PARAMETER")

package com.couchbase.codesnippets

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.ArrayFunction
import com.couchbase.lite.Collection
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.Expression
import com.couchbase.lite.FullTextFunction
import com.couchbase.lite.FullTextIndexConfigurationFactory
import com.couchbase.lite.FullTextIndexItem
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.Join
import com.couchbase.lite.Meta
import com.couchbase.lite.Ordering
import com.couchbase.lite.Parameters
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.Result
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndexConfigurationFactory
import com.couchbase.lite.ValueIndexItem
import com.couchbase.lite.newConfig
import com.fasterxml.jackson.databind.ObjectMapper


private const val TAG = "QUERY"

// ### Indexing
fun indexingExample(collection: Collection) {

    // tag::query-index[]
    collection.createIndex(
        "TypeNameIndex",
        ValueIndexConfigurationFactory.newConfig("type", "name")
    )
    // end::query-index[]
}

// ### SELECT statement
fun selectStatementExample(collection: Collection) {

    // tag::query-select-props[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("name"),
            SelectResult.property("type")
        )
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
        .orderBy(Ordering.expression(Meta.id))

    query.execute().use { rs ->
        rs.forEach {
            log("hotel id ->${it.getString("id")}")
            log("hotel name -> ${it.getString("name")}")
        }
    }
    // end::query-select-props[]
}

fun whereStatementExample(collection: Collection) {

    // tag::query-where[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
        .limit(Expression.intValue(10))

    query.execute().use { rs ->
        rs.forEach { result ->
            result.getDictionary("myDatabase")?.let {
                log("name -> ${it.getString("name")}")
                log("type -> ${it.getString("type")}")
            }
        }
    }
    // end::query-where[]
}

// ####　Collection Operators
fun collectionStatementExample(collection: Collection) {
    // tag::query-collection-operator-contains[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("name"),
            SelectResult.property("public_likes")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("hotel"))
                .and(
                    ArrayFunction.contains(
                        Expression.property("public_likes"),
                        Expression.string("Armani Langworth")
                    )
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("public_likes -> ${it.getArray("public_likes")?.toList()}")
        }
    }
    // end::query-collection-operator-contains[]
}

// Pattern Matching
fun patternMatchingExample(collection: Collection) {
    // tag::query-like-operator[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .like(Expression.string("royal engineers museum"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-like-operator[]
}

// ### Wildcard Match
fun wildcardMatchExample(collection: Collection) {
    // tag::query-like-operator-wildcard-match[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .like(Expression.string("eng%e%"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-like-operator-wildcard-match[]
}

// Wildcard Character Match
fun wildCharacterMatchExample(collection: Collection) {
    // tag::query-like-operator-wildcard-character-match[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .like(Expression.string("eng____r"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-like-operator-wildcard-character-match[]
}

// ### Regex Match
fun regexMatchExample(collection: Collection) {
    // tag::query-regex-operator[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .regex(Expression.string("\\beng.*r\\b"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-regex-operator[]
}

// ###　WHERE statement
fun queryDeletedDocumentsExample(collection: Collection) {
    // tag::query-deleted-documents[]
    // Query documents that have been deleted
    val query = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.collection(collection))
        .where(Meta.deleted)
    // end::query-deleted-documents[]
}

// JOIN statement
fun joinStatementExample(collection: Collection) {
    // tag::query-join[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Expression.property("name").from("airline")),
            SelectResult.expression(Expression.property("callsign").from("airline")),
            SelectResult.expression(Expression.property("destinationairport").from("route")),
            SelectResult.expression(Expression.property("stops").from("route")),
            SelectResult.expression(Expression.property("airline").from("route"))
        )
        .from(DataSource.collection(collection).`as`("airline"))
        .join(
            Join.join(DataSource.collection(collection).`as`("route"))
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
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.toMap()}")
        }
    }
    // end::query-join[]
}

// ### GROUPBY statement
fun groupByStatementExample(collection: Collection) {
    // tag::query-groupby[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Function.count(Expression.string("*"))),
            SelectResult.property("country"),
            SelectResult.property("tz")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("airport"))
                .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300)))
        )
        .groupBy(
            Expression.property("country"), Expression.property("tz")
        )
        .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending())
    query.execute().use { rs ->
        rs.forEach {
            log(
                "There are ${it.getInt("$1")} airports on the ${
                    it.getString("tz")
                } timezone located in ${
                    it.getString("country")
                } and above 300ft"
            )
        }
    }
    // end::query-groupby[]
}

// ### ORDER BY statement
fun orderByStatementExample(collection: Collection) {
    // tag::query-orderby[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
        .orderBy(Ordering.property("name").ascending())
        .limit(Expression.intValue(10))

    query.execute().use { rs ->
        rs.forEach {
            log("${it.toMap()}")
        }
    }
    // end::query-orderby[]
}

fun querySyntaxAllExample(collection: Collection) {
    // tag::query-syntax-all[]
    val listQuery = QueryBuilder.select(SelectResult.all())
        .from(DataSource.collection(collection))
    // end::query-syntax-all[]

    // tag::query-access-all[]
    val hotels = mutableMapOf<String, Hotel>()
    listQuery.execute().use { rs ->
        rs.allResults().forEach {
            // get the k-v pairs from the 'hotel' key's value into a dictionary
            val thisDocsProps = it.getDictionary(0) // <.>
            val thisDocsId = thisDocsProps!!.getString("id")
            val thisDocsName = thisDocsProps.getString("name")
            val thisDocsType = thisDocsProps.getString("type")
            val thisDocsCity = thisDocsProps.getString("city")

            // Alternatively, access results value dictionary directly
            val id = it.getDictionary(0)?.getString("id").toString() // <.>
            hotels[id] = Hotel(
                id,
                it.getDictionary(0)?.getString("type"),
                it.getDictionary(0)?.getString("name"),
                it.getDictionary(0)?.getString("city"),
                it.getDictionary(0)?.getString("country"),
                it.getDictionary(0)?.getString("description")
            )
        }
    }
    // end::query-access-all[]
}

fun querySyntaxIdExample(collection: Collection) {
    // tag::query-select-meta
    // tag::query-syntax-id[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id).`as`("hotelId")
        )
        .from(DataSource.collection(collection))

    // end::query-syntax-id[]

    // tag::query-access-id[]
    query.execute().use { rs ->
        rs.allResults().forEach {
            log("hotel id ->${it.getString("hotelId")}")
        }
    }
    // end::query-access-id[]
    // end::query-select-meta
}

fun querySyntaxCountExample(collection: Collection) {
    // tag::query-syntax-count-only[]

    val query = QueryBuilder
        .select(
            SelectResult.expression(Function.count(Expression.string("*"))).`as`("mycount")
        ) // <.>
        .from(DataSource.collection(collection))

    // end::query-syntax-count-only[]

    // tag::query-access-count-only[]
    query.execute().use { rs ->
        rs.allResults().forEach {
            log("name -> ${it.getInt("mycount")}")
        }
    }
    // end::query-access-count-only[]
}

fun querySyntaxPropsExample(collection: Collection) {
    // tag::query-syntax-props[]

    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))

    // end::query-syntax-props[]

    // tag::query-access-props[]
    query.execute().use { rs ->
        rs.allResults().forEach {
            log("Hotel name -> ${it.getString("name")}, in ${it.getString("country")}")
        }
    }
    // end::query-access-props[]
}

// IN operator
fun inOperatorExample(collection: Collection) {
    // tag::query-collection-operator-in[]
    val query = QueryBuilder.select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            Expression.string("Armani").`in`(
                Expression.property("first"),
                Expression.property("last"),
                Expression.property("username")
            )
        )

    query.execute().use { rs ->
        rs.forEach {
            log("public_likes -> ${it.toMap()}")
        }
    }
    // end::query-collection-operator-in[]
}


// tag::query-syntax-pagination-all[]
fun queryPaginationExample(collection: Collection) {
    // tag::query-syntax-pagination[]
    val thisOffset = 0
    val thisLimit = 20
    val listQuery = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .limit(
            Expression.intValue(thisLimit),
            Expression.intValue(thisOffset)
        ) // <.>

    // end::query-syntax-pagination[]
}
// end::query-syntax-pagination-all[]

// ### all(*)
fun selectAllExample(collection: Collection) {
    // tag::query-select-all[]
    val queryAll = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
    // end::query-select-all[]

}

fun liveQueryExample(collection: Collection) {
    // tag::live-query[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection)) // <.>

    // Adds a query change listener.
    // Changes will be posted on the main queue.
    val token = query.addChangeListener { change ->
        change.results?.let { rs ->
            rs.forEach {
                log("results: ${it.keys}")
                /* Update UI */
            }
        } // <.>
    }

    // end::live-query[]

    // tag::stop-live-query[]
    token.remove()
    // end::stop-live-query[]
}

// META function
fun metaFunctionExample(collection: Collection) {
    // tag::query-select-meta[]
    val query = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("airport")))
        .orderBy(Ordering.expression(Meta.id))

    query.execute().use { rs ->
        rs.forEach {
            log("airport id ->${it.getString("id")}")
            log("airport id -> ${it.getString(0)}")
        }
    }
    // end::query-select-meta[]
}

// ### EXPLAIN statement
// tag::query-explain[]
fun explainAllExample(collection: Collection) {
    // tag::query-explain-all[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("university")))
        .groupBy(Expression.property("country"))
        .orderBy(Ordering.property("name").descending()) // <.>

    log(query.explain()) // <.>
    // end::query-explain-all[]
}

fun explainLikeExample(collection: Collection) {
    // tag::query-explain-like[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").like(Expression.string("%hotel%"))) // <.>
        .groupBy(Expression.property("country"))
        .orderBy(Ordering.property("name").descending()) // <.>
    log(query.explain())
    // end::query-explain-like[]
}

fun explainNoPFXExample(collection: Collection) {
    // tag::query-explain-nopfx[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").like(Expression.string("hotel%")) // <.>
                .and(Expression.property("name").like(Expression.string("%royal%")))
        )
    log(query.explain())
    // end::query-explain-nopfx[]
}

fun explainFnExample(collection: Collection) {
    // tag::query-explain-function[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))) // <.>
    log(query.explain())
    // end::query-explain-function[]

}

fun explainNoFnExample(collection: Collection) {
    // tag::query-explain-nofunction[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel"))) // <.>
    log(query.explain())
    // end::query-explain-nofunction[]
}
// end::query-explain[]

fun prepareIndex(collection: Collection) {
    // tag::fts-index[]
    collection.createIndex(
        "overviewFTSIndex",
        FullTextIndexConfigurationFactory.newConfig("overview"))
    // end::fts-index[]
}

fun prepareIndexBuilderExample(collection: Collection) {
    // tag::fts-index_Querybuilder[]
    collection.createIndex(
        "overviewFTSIndex",
        IndexBuilder.fullTextIndex(FullTextIndexItem.property("overview")).ignoreAccents(false)
    )
    // end::fts-index_Querybuilder[]
}

fun indexingQueryBuilderExample(collection: Collection) {
    // tag::query-index_Querybuilder[]
    collection.createIndex(
        "TypeNameIndex",
        IndexBuilder.valueIndex(
            ValueIndexItem.property("type"),
            ValueIndexItem.property("name")
        )
    )
    // end::query-index_Querybuilder[]
}

fun ftsExample(database: Database) {
    // tag::fts-query[]
    val ftsQuery = database.createQuery(
        "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK(overviewFTSIndex)"
    )
    ftsQuery.execute().use { rs ->
        rs.allResults().forEach {
            log("${it.getString("id")}: ${it.getString("overview")}")
        }
    }
    // end::fts-query[]
}

fun ftsQueryBuilderExample(collection: Collection) {
    // tag::fts-query_Querybuilder[]
    val ftsQuery =
        QueryBuilder.select(
            SelectResult.expression(Meta.id),
            SelectResult.property("overview")
        )
            .from(DataSource.collection(collection))
            .where(FullTextFunction.match(Expression.fullTextIndex("overviewFTSIndex"), "michigan"))

    ftsQuery.execute().use { rs ->
        rs.allResults().forEach {
            log("${it.getString("Meta.id")}: ${it.getString("overview")}")
        }
    }
    // end::fts-query_Querybuilder[]
}

fun querySyntaxJsonExample(collection: Collection) {
    // tag::query-syntax-json[]
    // Example assumes Hotel class object defined elsewhere
    // Build the query
    val listQuery = QueryBuilder.select(SelectResult.all())
        .from(DataSource.collection(collection))
    // end::query-syntax-json[]
    // tag::query-access-json[]
    // Uses Jackson JSON processor
    val mapper = ObjectMapper()
    val hotels = mutableListOf<Hotel>()

    listQuery.execute().use { rs ->
        rs.forEach {

            // Get result as JSON string
            val json = it.toJSON() // <.>

            // Get Hashmap from JSON string
            val dictFromJSONstring = mapper.readValue(json, HashMap::class.java) // <.>

            // Use created hashmap
            val hotelId = dictFromJSONstring["id"].toString() //
            val hotelType = dictFromJSONstring["type"].toString()
            val hotelname = dictFromJSONstring["name"].toString()

            // Get custom object from JSON string
            val thisHotel = mapper.readValue(json, Hotel::class.java) // <.>
            hotels.add(thisHotel)
        }
    }
    // end::query-access-json[]
}

fun docsOnlyQuerySyntaxN1QL(thisDb: Database): List<Result> {
    // For Documentation -- N1QL Query using parameters
    // tag::query-syntax-n1ql[]
    val thisQuery = thisDb.createQuery(
        "SELECT META().id AS id FROM _ WHERE type = \"hotel\""
    ) // <.>

    return thisQuery.execute().use { rs -> rs.allResults() }
    // end::query-syntax-n1ql[]
}

fun docsOnlyQuerySyntaxN1QLParams(database: Database): List<Result> {
    // For Documentation -- N1QL Query using parameters
    // tag::query-syntax-n1ql-params[]
    val thisQuery = database.createQuery(
        "SELECT META().id AS id FROM _ WHERE type = \$type"
    ) // <.>

    thisQuery.parameters = Parameters().setString("type", "hotel") // <.>

    return thisQuery.execute().allResults()

    // end::query-syntax-n1ql-params[]
}

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
package com.couchbase.codesnippets

import android.app.Application
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.Database
import com.couchbase.lite.LogDomain
import com.couchbase.lite.LogLevel


class SnippetApplication : Application() {
    // tag::sdk-initializer[]
    override fun onCreate() {
        super.onCreate()
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(this)
    }

    // end::sdk-initializer[]
    fun troubleshootingExample() {
        // tag::replication-logging[]
        CouchbaseLite.init(this, true)

        Database.log.console.setDomains(LogDomain.REPLICATOR)
        Database.log.console.level = LogLevel.DEBUG
        // end::replication-logging[]
    }
}
