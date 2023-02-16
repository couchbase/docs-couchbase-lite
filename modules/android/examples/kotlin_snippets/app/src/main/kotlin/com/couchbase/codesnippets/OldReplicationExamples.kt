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
}

@Suppress("unused")
class OldReplicationExamples(private val database: Database) {
    private var replicator: Replicator? = null

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
                log("Replication stopped")
            }
        }

        repl.start()
        replicator = repl
        // end::replication-status[]
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

