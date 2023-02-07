package com.couchbase.gettingstarted;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
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
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.URLEndpoint;


public class DBManager {
    public static final class Replication {
        public final Replicator replicator;
        public final ListenerToken token;

        Replication(Replicator replicator, ListenerToken token) {
            this.replicator = replicator;
            this.token = token;
        }
    }

    private static final AtomicReference<DBManager> INSTANCE = new AtomicReference<>();

    public static DBManager getInstance() {
        DBManager mgr = INSTANCE.get();
        if (mgr == null) {
            mgr = new DBManager();
            if (INSTANCE.compareAndSet(null, mgr)) { mgr.init(); }
        }
        return INSTANCE.get();
    }

    // tag::getting-started[]

    // <.>
    // One-off initialization
    private void init() {
        CouchbaseLite.init();
    }

    // <.>
    // Create a database
    public Database createDb(String dbName) throws CouchbaseLiteException {
        return new Database(dbName);
    }

    // <.>
    // Create a new named collection (like a SQL table)
    // in the database's default scope.
    public Collection createCollection(Database database, String collName) throws CouchbaseLiteException {
        return database.createCollection(collName);
    }

    // <.>
    // Create a new document (i.e. a record)
    // and save it in a collection in the database.
    public String createDoc(Collection collection) throws CouchbaseLiteException {
        MutableDocument mutableDocument = new MutableDocument()
            .setFloat("version", 2.0f)
            .setString("language", "Java");
        collection.save(mutableDocument);
        return mutableDocument.getId();
    }

    // <.>
    // Retrieve immutable document and log the database generated
    // document ID and some document properties
    public Document retrieveDoc(Collection collection, String docId) throws CouchbaseLiteException {
        return collection.getDocument(docId);
    }

    // <.>
    // Retrieve and update a document.
    public void updateDoc(Collection collection, String docId) throws CouchbaseLiteException {
        Document document = collection.getDocument(docId);
        if (document != null) {
            collection.save(
                document.toMutable().setString("language", "Kotlin"));
        }
    }

    // <.>
    // Create a query to fetch documents with language == Kotlin.
    public List<Result> queryDocs(Collection collection) throws CouchbaseLiteException {
        Query query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("language").equalTo(Expression.string("Kotlin")));
        try (ResultSet rs = query.execute()) { return rs.allResults(); }
    }

    // <.>
    // OPTIONAL -- if you have Sync Gateway Installed you can try replication too.
    // Create a replicator to push and pull changes to and from the cloud.
    // Be sure to hold a reference somewhere to prevent the Replicator from being GCed
    public Replication startReplicator(Collection collection, ReplicatorChangeListener listener)
        throws URISyntaxException {
        CollectionConfiguration collConfig = new CollectionConfiguration()
            .setPullFilter((doc, flags) -> "Java".equals(doc.getString("language")));

        ReplicatorConfiguration replConfig =
            new ReplicatorConfiguration(
                new URLEndpoint(new URI("ws://localhost:4984/getting-started-db")))
                .addCollection(collection, collConfig)
                .setType(ReplicatorType.PUSH_AND_PULL)
                .setAuthenticator(new BasicAuthenticator("sync-gateway", "password".toCharArray()));

        Replicator replicator = new Replicator(replConfig);

        // Listen to replicator change events.
        // Use `token.remove()` to stop the listener
        ListenerToken token = replicator.addChangeListener(listener);

        // Start replication.
        replicator.start();

        return new Replication(replicator, token);
    }

    // tag::getting-started[]

    public void stopReplicator(Replication replication) {
        if (replication == null) { return; }
        replication.token.remove();
        replication.replicator.stop();
    }
}
