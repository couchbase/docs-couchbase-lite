package com.couchbase.gettingstarted;

import java.net.URI;
import java.net.URISyntaxException;

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
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.URLEndpoint;


public class Main {
    private static final String SG_URI = null; // "ws://localhost:4984/getting-started-db"

    public static void main(String[] args) throws CouchbaseLiteException, URISyntaxException {
        Main main = new Main();
        main.getStarted();
    }


    private Replicator replicator;

    // tag::getting-started[]

    private void getStarted() throws CouchbaseLiteException, URISyntaxException {
        // <.>
        // One-off initialization
        CouchbaseLite.init();
        System.out.println("CBL Initialized");

        // <.>
        // Create a database
        Database database = new Database("mydb");
        System.out.println("Database created: mydb");

        // <.>
        // Create a new collection (like a SQL table) in the database.
        Collection collection = database.createCollection("myCollection", "myScope");
        System.out.println("Collection created: " + collection);

        // <.>
        // Create a new document (i.e. a record)
        // and save it in a collection in the database.
        MutableDocument mutableDoc = new MutableDocument()
            .setString("version", "2.0")
            .setString("language", "Java");
        collection.save(mutableDoc);

        // <.>
        // Retrieve immutable document and log the database generated
        // document ID and some document properties
        Document document = collection.getDocument(mutableDoc.getId());
        if (document == null) {
            System.out.println("No such document :: " + mutableDoc.getId());
        }
        else {
            System.out.println("Document ID :: " + document.getId());
            System.out.println("Learning :: " + document.getString("language"));
        }

        // <.>
        // Retrieve and update a document.
        document = collection.getDocument(mutableDoc.getId());
        if (document != null) {
            collection.save(document.toMutable().setString("language", "Kotlin"));
        }

        // <.>
        // Create a query to fetch documents with language == "Kotlin"
        Query query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("language")
                .equalTo(Expression.string("Kotlin")));

        try (ResultSet rs = query.execute()) {
            System.out.println("Number of rows :: " + rs.allResults().size());
        }

        //  <.>
        // OPTIONAL -- if you have Sync Gateway Installed you can try replication too
        // Create a replicator to push and pull changes to and from the cloud.
        // Be sure to hold a reference somewhere to prevent the Replicator from being GCed
        if (SG_URI != null) { replicator = startRepl(SG_URI, collection); }
    }

    private Replicator startRepl(String uri, Collection collection) throws URISyntaxException {
        CollectionConfiguration collConfig = new CollectionConfiguration()
            .setPullFilter((doc, flags) -> "Java".equals(doc.getString("language")));

        ReplicatorConfiguration replConfig = new ReplicatorConfiguration(
            new URLEndpoint(new URI(uri)))
            .addCollection(collection, collConfig)
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setAuthenticator(new BasicAuthenticator("sync-gateway", "password".toCharArray()));

        Replicator repl = new Replicator(replConfig);

        // Listen to replicator change events.
        // Use `token.remove()` to stop the listener
        ListenerToken token = replicator.addChangeListener(change -> {
            System.out.println("Replicator state :: " + change.getStatus().getActivityLevel());
        });

        // Start replication.
        repl.start();

        return repl;
    }
    // end::getting-started[]
}


