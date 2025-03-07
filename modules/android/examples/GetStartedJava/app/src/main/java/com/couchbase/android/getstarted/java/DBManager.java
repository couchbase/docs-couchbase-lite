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
package com.couchbase.android.getstarted.java;

import android.util.Log;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CollectionConfiguration;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.URLEndpoint;


@SuppressWarnings("unused")
public class DBManager {
    private static final String TAG = "START_JAVA";

    private static final AtomicReference<DBManager> INSTANCE = new AtomicReference<>();

    public static synchronized DBManager getInstance() {
        DBManager mgr = INSTANCE.get();
        if (mgr == null) {
            mgr = new DBManager();
            if (INSTANCE.compareAndSet(null, mgr)) { mgr.init(); }
        }
        return INSTANCE.get();
    }

    private Database database;
    private Collection collection;
    private Replicator replicator;

    private DBManager() { }

    // tag::getting-started[]

    // <.>
    // One-off initialization
    private void init() {
        CouchbaseLite.init(GettingStartedApplication.getAppContext());
        Log.i(TAG, "CBL Initialized");
    }

    // <.>
    // Create a database
    public void createDb(String dbName) throws CouchbaseLiteException {
        database = new Database(dbName);
        Log.i(TAG, "Database created: " + dbName);
    }

    // <.>
    // Create a new named collection (like a SQL table)
    // in the database's default scope.
    public void createCollection(String collName) throws CouchbaseLiteException {
        collection = database.createCollection(collName);
        Log.i(TAG, "Collection created: " + collection);
    }

    // <.>
    // Create a new document (i.e. a record)
    // and save it in a collection in the database.
    public String createDoc() throws CouchbaseLiteException {
        MutableDocument mutableDocument = new MutableDocument()
            .setFloat("version", 2.0f)
            .setString("language", "Java");
        collection.save(mutableDocument);
        return mutableDocument.getId();
    }

    // <.>
    // Retrieve immutable document and log the database generated
    // document ID and some document properties
    public void retrieveDoc(String docId) throws CouchbaseLiteException {
        Document document = collection.getDocument(docId);
        if (document == null) {
            Log.i(TAG, "No such document :: " + docId);
        }
        else {
            Log.i(TAG, "Document ID :: " + document.getId());
            Log.i(TAG, "Learning :: " + document.getString("language"));
        }
    }

    // <.>
    // Retrieve and update a document.
    public void updateDoc(String docId) throws CouchbaseLiteException {
        Document document = collection.getDocument(docId);
        if (document != null) {
            collection.save(
                document.toMutable().setString("language", "Kotlin"));
        }
    }

    // <.>
    // Create a query to fetch documents with language == Kotlin.
    public void queryDocs() throws CouchbaseLiteException {
        Query query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("language").equalTo(Expression.string("Kotlin")));

        try (ResultSet rs = query.execute()) {
            Log.i(TAG, "Number of rows :: " + rs.allResults().size());
        }
    }

    // <.>
    // OPTIONAL -- if you have Sync Gateway Installed you can try replication too.
    // Create a replicator to push and pull changes to and from the cloud.
    // Be sure to hold a reference somewhere to prevent the Replicator from being GCed
    public ListenerToken replicate(String uri, ReplicatorChangeListener listener) throws URISyntaxException {
        CollectionConfiguration collConfig = new CollectionConfiguration()
            .setPullFilter((doc, flags) -> "Java".equals(doc.getString("language")));

        ReplicatorConfiguration replConfig =
            new ReplicatorConfiguration(
                new URLEndpoint(new URI(uri)))
                .addCollection(collection, collConfig)
                .setType(ReplicatorType.PUSH_AND_PULL)
                .setAuthenticator(new BasicAuthenticator("sync-gateway", "password".toCharArray()));

        replicator = new Replicator(replConfig);

        // Listen to replicator change events.
        // Use `token.remove()` to stop the listener

        ListenerToken token = replicator.addChangeListener(listener);

        // Start replication.
        replicator.start();

        return token;
    }
    // end::getting-started[]
}
