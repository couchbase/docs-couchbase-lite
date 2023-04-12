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
package com.couchbase.codesnippets;

import androidx.annotation.NonNull;

import java.net.URI;
import java.net.URISyntaxException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.cert.X509Certificate;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CollectionConfiguration;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseEndpoint;
import com.couchbase.lite.DocumentFlag;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.ReplicatedDocument;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorProgress;
import com.couchbase.lite.ReplicatorStatus;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.SessionAuthenticator;
import com.couchbase.lite.URLEndpoint;


@SuppressWarnings({"unused"})
public class ReplicationExamples {
    private Replicator thisReplicator;
    private ListenerToken thisToken;

    public void activeReplicatorExample(Set<Collection> collections)
        throws URISyntaxException {
        // tag::p2p-act-rep-start-full[]
        // Create replicator
        // Consider holding a reference somewhere
        // to prevent the Replicator from being GCed
        Replicator repl = new Replicator( // <.>

            // tag::p2p-act-rep-func[]
            // tag::p2p-act-rep-initialize[]
            // initialize the replicator configuration
            new ReplicatorConfiguration(new URLEndpoint(new URI("wss://listener.com:8954"))) // <.>
                .addCollections(collections, null)

                // end::p2p-act-rep-initialize[]
                // tag::p2p-act-rep-config-type[]
                // Set replicator type
                .setType(ReplicatorType.PUSH_AND_PULL)

                // end::p2p-act-rep-config-type[]
                // tag::p2p-act-rep-config-cont[]
                // Configure Sync Mode
                .setContinuous(false) // default value

                // end::p2p-act-rep-config-cont[]

                // tag::autopurge-override[]
                // set auto-purge behavior
                // (here we override default)
                .setAutoPurgeEnabled(false) // <.>

                // end::autopurge-override[]

                // tag::p2p-act-rep-config-self-cert[]
                // Configure Server Authentication --
                // only accept self-signed certs
                .setAcceptOnlySelfSignedServerCertificate(true) // <.>

                // end::p2p-act-rep-config-self-cert[]
                // tag::p2p-act-rep-auth[]
                // Configure the credentials the
                // client will provide if prompted
                .setAuthenticator(new BasicAuthenticator("Our Username", "Our Password".toCharArray())) // <.>

            // end::p2p-act-rep-auth[]
        );

        // tag::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-add-change-listener-label[]
        // Optionally add a change listener <.>
        // end::p2p-act-rep-add-change-listener-label[]
        ListenerToken token = repl.addChangeListener(change -> {
            CouchbaseLiteException err = change.getStatus().getError();
            if (err != null) { Logger.log("Error code :: " + err.getCode(), err); }
        });

        // end::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-start[]
        // Start replicator
        repl.start(false); // <.>

        // end::p2p-act-rep-start[]

        thisReplicator = repl;
        thisToken = token;

        // end::p2p-act-rep-start-full[]
        // end::p2p-act-rep-func[]
    }

    public void replicatorSimpleExample(Set<Collection> collections) throws URISyntaxException {
        // tag::replicator-simple[]
        Endpoint theListenerEndpoint
            = new URLEndpoint(new URI("wss://10.0.2.2:4984/db")); // <.>

        ReplicatorConfiguration thisConfig =
            new ReplicatorConfiguration(theListenerEndpoint) // <.>
                .addCollections(collections, null) // default configuration

                .setAcceptOnlySelfSignedServerCertificate(true) // <.>
                .setAuthenticator(new BasicAuthenticator(
                    "valid.user",
                    "valid.password".toCharArray())); // <.>

        Replicator repl = new Replicator(thisConfig); // <.>
        // Start the replicator
        repl.start(); // <.>
        // (be sure to hold a reference somewhere that will prevent it from being GCed)
        thisReplicator = repl;

        // end::replicator-simple[]
    }

    public void replicationBasicAuthenticationExample(
        Set<Collection> collections,
        CollectionConfiguration collectionConfig)
        throws URISyntaxException {
        // tag::basic-authentication[]

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, collectionConfig)
                .setAuthenticator(new BasicAuthenticator("username", "password".toCharArray())));

        repl.start();
        thisReplicator = repl;
        // end::basic-authentication[]
    }


    public void replicationSessionAuthenticationExample(
        Set<Collection> collections,
        CollectionConfiguration collectionConfig)
        throws URISyntaxException {
        // tag::session-authentication[]

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, collectionConfig)
                .setAuthenticator(new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447")));

        repl.start();
        thisReplicator = repl;
        // end::session-authentication[]
    }

    public void replicationCustomHeaderExample(
        Set<Collection> collections,
        CollectionConfiguration collectionConfig)
        throws URISyntaxException {
        // tag::replication-custom-header[]
        Map<String, String> headers = new HashMap<>();
        headers.put("CustomHeaderName", "Value");

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, collectionConfig)
                .setHeaders(headers));

        repl.start();
        thisReplicator = repl;
        // end::replication-custom-header[]
    }

    public void replicationPushFilterExample(Set<Collection> collections) throws URISyntaxException {
        // tag::replication-push-filter[]
        CollectionConfiguration collectionConfig = new CollectionConfiguration()
            .setPushFilter((document, flags) -> flags.contains(DocumentFlag.DELETED)); // <1>

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, collectionConfig));

        repl.start();
        thisReplicator = repl;
        // end::replication-push-filter[]
    }


    public void replicationPullFilterExample(Set<Collection> collections) throws URISyntaxException {
        // tag::replication-pull-filter[]
        CollectionConfiguration collectionConfig = new CollectionConfiguration()
            .setPullFilter((document, flags) -> "draft".equals(document.getString("type"))); // <1>

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, collectionConfig));

        repl.start();
        thisReplicator = repl;
        // end::replication-pull-filter[]
    }

    public void replicationResetCheckpointExample(Set<Collection> collections) throws URISyntaxException {
        // tag::replication-startup[]
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, null));

        // tag::replication-reset-checkpoint[]
        repl.start(true);
        // end::replication-reset-checkpoint[]

        // ... at some later time

        repl.stop();
        // end::replication-startup[]
    }

    public void handlingNetworkErrorsExample(Set<Collection> collections) throws URISyntaxException {
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, null));

        // tag::replication-error-handling[]
        repl.addChangeListener(change -> {
            CouchbaseLiteException error = change.getStatus().getError();
            if (error != null) { Logger.log("Error code:: " + error); }
        });
        repl.start();
        thisReplicator = repl;
        // end::replication-error-handling[]
    }

    public void certificatePinningExample(Set<Collection> collections, String keyStoreName, String certAlias)
        throws URISyntaxException, KeyStoreException {
        // tag::certificate-pinning[]
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, null)
                .setPinnedServerX509Certificate(
                    (X509Certificate) KeyStore.getInstance(keyStoreName).getCertificate(certAlias)));

        repl.start();
        thisReplicator = repl;
        // end::certificate-pinning[]
    }

    public void replicatorConfigExample(Set<Collection> collections) throws URISyntaxException {
        // tag::sgw-act-rep-initialize[]
        // initialize the replicator configuration
        ReplicatorConfiguration thisConfig = new ReplicatorConfiguration(
            new URLEndpoint(new URI("wss://10.0.2.2:8954/travel-sample"))) // <.>
            .addCollections(collections, null);
        // end::sgw-act-rep-initialize[]
    }


    public void p2pReplicatorStatusExample(Replicator repl) {
        // tag::p2p-act-rep-status[]
        ReplicatorStatus status = repl.getStatus();
        ReplicatorProgress progress = status.getProgress();
        Logger.log(
            "The Replicator is " + status.getActivityLevel()
                + "and has processed " + progress.getCompleted()
                + " of " + progress.getTotal() + " changes");
    }
    // end::p2p-act-rep-status[]


    public void p2pReplicatorStopExample(Replicator repl) {
        // tag::p2p-act-rep-stop[]
        // Stop replication.
        repl.stop(); // <.>
        // end::p2p-act-rep-stop[]
    }


    public void customRetryConfigExample(Set<Collection> collections) throws URISyntaxException {
        // tag::replication-retry-config[]
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, null)
                //  other config as required . . .
                // tag::replication-heartbeat-config[]
                .setHeartbeat(150) // <.>
                // end::replication-heartbeat-config[]
                // tag::replication-maxattempts-config[]
                .setMaxAttempts(20) // <.>
                // end::replication-maxattempts-config[]
                // tag::replication-maxattemptwaittime-config[]
                .setMaxAttemptWaitTime(600)); // <.>
        // end::replication-maxattemptwaittime-config[]

        repl.start();
        thisReplicator = repl;
        // end::replication-retry-config[]
    }

    public void replicatorDocumentEventExample(Set<Collection> collections) throws URISyntaxException {
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollections(collections, null));


        // tag::add-document-replication-listener[]
        ListenerToken token = repl.addDocumentReplicationListener(replication -> {
            Logger.log("Replication type: " + ((replication.isPush()) ? "push" : "pull"));
            for (ReplicatedDocument document: replication.getDocuments()) {
                Logger.log("Doc ID: " + document.getID());

                CouchbaseLiteException err = document.getError();
                if (err != null) {
                    // There was an error
                    Logger.log("Error replicating document: ", err);
                    return;
                }

                if (document.getFlags().contains(DocumentFlag.DELETED)) {
                    Logger.log("Successfully replicated a deleted document");
                }
            }
        });


        repl.start();
        thisReplicator = repl;
        // end::add-document-replication-listener[]

        // tag::remove-document-replication-listener[]
        token.remove();
        // end::remove-document-replication-listener[]
    }

    public void replicationPendingDocumentsExample(Collection collection)
        throws CouchbaseLiteException, URISyntaxException {
        // tag::replication-pendingdocuments[]
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(new URI("ws://localhost:4984/mydatabase")))
                .addCollection(collection, null)
                .setType(ReplicatorType.PUSH));

        // tag::replication-push-pendingdocumentids[]
        Set<String> pendingDocs = repl.getPendingDocumentIds(collection);
        // end::replication-push-pendingdocumentids[]

        if (!pendingDocs.isEmpty()) {
            Logger.log("There are " + pendingDocs.size() + " documents pending");

            final String firstDoc = pendingDocs.iterator().next();

            repl.addChangeListener(change -> {
                Logger.log("Replicator activity level is " + change.getStatus().getActivityLevel());
                // tag::replication-push-isdocumentpending[]
                try {
                    if (!repl.isDocumentPending(firstDoc, collection)) {
                        Logger.log("Doc ID " + firstDoc + " has been pushed");
                    }
                }
                catch (CouchbaseLiteException err) {
                    Logger.log("Failed getting pending docs", err);
                }
                // end::replication-push-isdocumentpending[]
            });

            repl.start();
            this.thisReplicator = repl;
        }
        // end::replication-pendingdocuments[]
    }

    public void databaseReplicatorExample(@NonNull Set<Collection> srcCollections, @NonNull Database targetDb) {
        // tag::database-replica[]
        // This is an Enterprise feature:
        // the code below will generate a compilation error
        // if it's compiled against CBL Android Community Edition.
        // Note: the target database must already contain the
        //       source collections or the replication will fail.
        final Replicator repl = new Replicator(
            new ReplicatorConfiguration(new DatabaseEndpoint(targetDb))
                .addCollections(srcCollections, null)
                .setType(ReplicatorType.PUSH));

        // Start the replicator
        // (be sure to hold a reference somewhere that will prevent it from being GCed)
        repl.start();
        thisReplicator = repl;
        // end::database-replica[]
    }

    public void replicationWithCustomConflictResolverExample(Set<Collection> srcCollections, URI targetUri) {
        // tag::replication-conflict-resolver[]
        Replicator repl = new Replicator(
            new ReplicatorConfiguration(new URLEndpoint(targetUri))
                .addCollections(
                    srcCollections,
                    new CollectionConfiguration()
                        .setConflictResolver(new LocalWinConflictResolver())));

        // Start the replicator
        // (be sure to hold a reference somewhere that will prevent it from being GCed)
        repl.start();
        thisReplicator = repl;
        // end::replication-conflict-resolver[]
    }
}


