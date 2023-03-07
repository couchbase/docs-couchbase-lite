//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http:        //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.codesnippets;

import java.util.Set;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Scope;
import com.couchbase.lite.ValueIndexConfiguration;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "UnusedAssignment"})
public class CollectionExamples {
    // We need to add a code sample to create a new collection in a scope
    public void createCollectionInScope(Database db)
        throws CouchbaseLiteException {
        // tag::scopes-manage-create-collection[]
        // create the collection "Verlaine" in the default scope ("_default")
        Collection collection1 = db.createCollection("Verlaine");
        // both of these retrieve collection1 created above
        collection1 = db.getCollection("Verlaine");
        collection1 = db.getDefaultScope().getCollection("Verlaine");

        // create the collection "Verlaine" in the scope "Television"
        Collection collection2 = db.createCollection("Television", "Verlaine");
        // both of these retrieve  collection2 created above
        collection2 = db.getCollection("Television", "Verlaine");
        collection2 = db.getScope("Television").getCollection("Verlaine");
        // end::scopes-manage-create-collection[]
    }

    // We need to add a code sample to index a collection
    public void createIndexInCollection(Collection collection) throws CouchbaseLiteException {
        // tag::scopes-manage-index-collection[]
        // Create an index named "nameIndex1" on the property "lastName" in the collection using the IndexBuilder
        collection.createIndex("nameIndex1", IndexBuilder.valueIndex(ValueIndexItem.property("lastName")));

        // Create a similar index named "nameIndex2" using and IndexConfiguration
        collection.createIndex("nameIndex2", new ValueIndexConfiguration("lastName"));

        // get the names of all the indices in the collection
        final Set<String> indices = collection.getIndexes();

        // delete all the collection indices
        for (String index: indices) { collection.deleteIndex(index); }
        // end::scopes-manage-index-collection[]
    }

    // We need to add a code sample to drop a collection
    public void deleteCollection(Database db, String collectionName, String scopeName)
        throws CouchbaseLiteException {
        // tag::scopes-manage-drop-collection[]
        Collection collection = db.getCollection(collectionName, scopeName);
        if (collection != null) { db.deleteCollection(collection.getName(), collection.getScope().getName()); }
        // end::scopes-manage-drop-collection[]
    }

    // We need to add a code sample to list scopes and collections
    public void listScopesAndCollections(Database db) throws CouchbaseLiteException {
        // tag::scopes-manage-list[]
        final Set<Scope> scopes = db.getScopes();
        for (Scope scope: scopes) {
            Logger.log("Scope :: " + scope.getName());
            final Set<Collection> collections = scope.getCollections();
            for (Collection collection: collections) {
                Logger.log("    Collection :: " + collection.getName());
            }
        }
        // end::scopes-manage-list[]
    }
}
