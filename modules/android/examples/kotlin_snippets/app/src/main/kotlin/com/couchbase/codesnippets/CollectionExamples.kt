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
