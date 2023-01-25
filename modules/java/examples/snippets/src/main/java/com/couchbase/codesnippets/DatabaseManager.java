package com.couchbase.codesnippets;

import java.net.URI;
import java.net.URISyntaxException;

import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.EncryptionKey;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.URLEndpoint;


// tag::GsWebApp_DbManager[]
public class DatabaseManager {

    private static DatabaseManager instance;
    private Database database;

    public static synchronized DatabaseManager manager() {
        if (instance == null) {
            instance = new DatabaseManager();
        }
        return instance;
    }

    public synchronized void init() {
        CouchbaseLite.init(); // <1>
    }

    public synchronized Database getDatabase(String parDbname, String parDbDir, String parDbPass) {
        if (database == null) {
            try {
                DatabaseConfiguration config = new DatabaseConfiguration();
                config.setDirectory(parDbDir); // <2>
                config.setEncryptionKey(new EncryptionKey(parDbPass)); // <3>
                database = new Database(parDbname, config);
            }
            catch (CouchbaseLiteException e) {
                throw new IllegalStateException("Cannot create database", e);
            }
        }
        return database;
    }

    public synchronized long runOneShotReplication(
        Database parDb,
        String parURL,
        String parName,
        String parPassword)
        throws InterruptedException {
        // Set replicator endpoint
        URI sgURI = null;
        try {
            sgURI = new URI(parURL);
        }
        catch (URISyntaxException e) {
            e.printStackTrace();
        }
        URLEndpoint targetEndpoint = new URLEndpoint(sgURI);

        // Configure replication
        System.out.println("== Synchronising DB :: Configuring replicator");
        ReplicatorConfiguration replConfig = new ReplicatorConfiguration(targetEndpoint);
        try {
            replConfig.addCollection(parDb.getDefaultCollection(), null);
        }
        catch (CouchbaseLiteException ex) {
            ex.printStackTrace();
            return -1;
        }

        replConfig.setType(ReplicatorType.PUSH_AND_PULL);
        replConfig.setContinuous(false);    // make this a single-shot replication cf. a continuous replication

        // Add authentication.
        replConfig.setAuthenticator(new BasicAuthenticator(parName, parPassword.toCharArray()));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(replConfig);

        // Listen to replicator change events.
        replicator.addChangeListener(change -> {
            if (change.getStatus().getError() != null) {
                System.err.println("Error code ::  " + change.getStatus().getError().getCode());
            }
        });

        // Start replication.
        replicator.start();
        // Check status of replication and wait till it is completed
        while (
            (replicator.getStatus().getActivityLevel() != ReplicatorActivityLevel.STOPPED)
                && (replicator.getStatus().getActivityLevel() != ReplicatorActivityLevel.IDLE)) {
            // do something useful...
            Thread.sleep(1000);
        }

        replicator.stop();
        replicator.close();
        return replicator.getStatus().getProgress().getTotal();
    }
}

// end::GsWebApp_DbManager[]