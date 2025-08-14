package com.couchbase.codesnippets;

import android.util.Log;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.KeyUsage;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.lite.MultipeerCertificateAuthenticator;
import com.couchbase.lite.MultipeerCollectionConfiguration;
import com.couchbase.lite.MultipeerReplicator;
import com.couchbase.lite.MultipeerReplicatorConfiguration;
import com.couchbase.lite.PeerInfo;
import com.couchbase.lite.ReplicatedDocument;
import com.couchbase.lite.ReplicatorStatus;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.logging.ConsoleLogSink;
import com.couchbase.lite.logging.LogSinks;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

@SuppressWarnings("unused")
public class MultipeerExamples {
    private final String TAG = "MultipeerExamples";

    private Collection collection1;
    private Collection collection2;
    private Collection collection3;

    private byte[] getCAPrivateKeyData() {
        return "your_base64_encoded_private_key".getBytes(StandardCharsets.UTF_8);
    }

    private byte[] getCACertificateData() {
        return "your_base64_encoded_certificate".getBytes(StandardCharsets.UTF_8);
    }

    public Set<MultipeerCollectionConfiguration> collectionSimple() {
        // tag::multipeer-collection-simple
        final Set<MultipeerCollectionConfiguration> collections = new HashSet<>();
        for(Collection col : Arrays.asList(collection1, collection2, collection3)) {
            MultipeerCollectionConfiguration.Builder builder =
                    new MultipeerCollectionConfiguration.Builder(col);
            collections.add(builder.build());
        }
        // end::multipeer-collection-
        return collections;
    }

    @SuppressWarnings("UnnecessaryLocalVariable")
    public Set<MultipeerCollectionConfiguration> collectionConfig() {
        // tag::multipeer-collection-config
        final MultipeerCollectionConfiguration config1 =
                new MultipeerCollectionConfiguration.Builder(collection1)
                        .setConflictResolver((peerId, conflict) -> conflict.getRemoteDocument())
                        .build();

        final MultipeerCollectionConfiguration config2 =
                new MultipeerCollectionConfiguration.Builder(collection1)
                        .setDocumentIDs(Arrays.asList("doc1", "doc2"))
                        .build();

        final MultipeerCollectionConfiguration config3 =
                new MultipeerCollectionConfiguration.Builder(collection1)
                        .setPushFilter((peerId, doc, flags) -> doc.getInt("access-level") == 2)
                        .build();

        final Set<MultipeerCollectionConfiguration> collections = Set.of(config1, config2, config3);
        // end::multipeer-collection-config

        return collections;
    }

    public TLSIdentity createSelfSignedIdentity() throws CouchbaseLiteException {
        // tag::multipeer-selfsigned-tlsidentity[]
        // NOTE: Error handling omitted

        final String persistentLabel = "com.myapp.identity";

        // Retrieve the TLS identity from the key store using the persistent label.
        TLSIdentity identity = TLSIdentity.getIdentity(persistentLabel);

        // If the identity exists but is expired, delete it.
        if(identity != null && identity.getExpiration().before(new Date())) {
            TLSIdentity.deleteIdentity(persistentLabel);
        }

        if(identity == null) {
            // Define certificate attributes and expiration date.
            final Map<String, String> certAttributes = Map.of(
                    TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "Couchbase Demo",
                    TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase",
                    TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile",
                    TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "noreply@couchbase.com"
            );

            final Calendar calendar = Calendar.getInstance();
            calendar.add(Calendar.YEAR, 2);
            Date expiration = calendar.getTime();

            identity = TLSIdentity.createIdentity(
                    Set.of(KeyUsage.CLIENT_AUTH, KeyUsage.SERVER_AUTH),
                    certAttributes,
                    expiration,
                    persistentLabel
            );
        }
        // end::multipeer-selfsigned-tlsidentity[]

        return identity;
    }

    public TLSIdentity createCASignedIdentity() throws CouchbaseLiteException {
        // tag::multipeer-tlsidentity[]
        // NOTE: Error handling omitted

        final String persistentLabel = "com.myapp.identity";

        // Retrieve the TLS identity from the key store using the persistent label.
        TLSIdentity identity = TLSIdentity.getIdentity(persistentLabel);

        // If the identity exists but is expired, delete it.
        if(identity != null && identity.getExpiration().before(new Date())) {
            // NOTE: Important to delete identity this way for CA signed identities
            // since they extend beyond the Android key store
            TLSIdentity.deleteIdentity(persistentLabel);
        }

        if(identity == null) {
            // Define certificate attributes and expiration date.
            final Map<String, String> certAttributes = Map.of(
                    TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "Couchbase Demo",
                    TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase",
                    TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile",
                    TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "noreply@couchbase.com"
            );

            final Calendar calendar = Calendar.getInstance();
            calendar.add(Calendar.YEAR, 2);
            final Date expiration = calendar.getTime();

            final byte[] caKey = getCAPrivateKeyData();
            final byte[] caCert = getCACertificateData();

            // As the function name indicates, this is not a secure way of doing things
            // and should either be done for testing only, or in an environment that you
            // assure to be secure against unknown actors, because otherwise anyone who
            // can install the app can probably easily extract the CA key.
            identity = TLSIdentity.createdSignedIdentityInsecure(
                    Set.of(KeyUsage.SERVER_AUTH, KeyUsage.CLIENT_AUTH),
                    certAttributes,
                    caKey,
                    caCert,
                    expiration,
                    persistentLabel
            );
        }
        // end::multipeer-tlsidentity[]

        return identity;
    }

    @SuppressWarnings("UnnecessaryLocalVariable")
    public MultipeerCertificateAuthenticator authenticatorWithCallback()  {
        // tag::multipeer-authenticator-callback[]
        // Use peer and certs to decide whether or not to allow (true) this peer
        // or reject (false)
        final MultipeerCertificateAuthenticator authenticator =
                new MultipeerCertificateAuthenticator((peer, certs) -> true);
        // end::multipeer-authenticator-callback[]

        return authenticator;
    }

    @SuppressWarnings("UnnecessaryLocalVariable")
    public MultipeerCertificateAuthenticator authenticatorWithRootCerts() throws CertificateException {
        // tag::multipeer-authenticator-rootcerts[]
        final byte[] caCert = getCACertificateData();
        final CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509");
        final ByteArrayInputStream inputStream = new ByteArrayInputStream(caCert);
        final X509Certificate certObject = (X509Certificate) certificateFactory.generateCertificate(inputStream);
        final MultipeerCertificateAuthenticator authenticator =
                new MultipeerCertificateAuthenticator(Collections.singletonList(certObject));
        // end::multipeer-authenticator-rootcerts[]

        return authenticator;
    }

    @SuppressWarnings("UnnecessaryLocalVariable")
    public MultipeerReplicatorConfiguration createConfig() throws CouchbaseLiteException, CertificateException {
        final TLSIdentity identity = createCASignedIdentity();
        final MultipeerCertificateAuthenticator authenticator = authenticatorWithRootCerts();
        final Set<MultipeerCollectionConfiguration> collections = collectionConfig();

        // tag::multipeer-config[]
        MultipeerReplicatorConfiguration config = new MultipeerReplicatorConfiguration.Builder()
                .setPeerGroupID("com.myapp")
                .setIdentity(identity)
                .setAuthenticator(authenticator)
                .setCollections(collections)
                .build();
        // end::multipeer-config[]

        return config;
    }

    @SuppressWarnings("UnnecessaryLocalVariable")
    public MultipeerReplicator createMultipeerReplicator() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicatorConfiguration config = createConfig();

        // tag::multipeer-replicator
        final MultipeerReplicator replicator = new MultipeerReplicator(config);
        // end::multipeer-replicator[]

        return replicator;
    }

    public void startReplicator() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();
        // tag::multipeer-replicator-start[]
        replicator.start();
        // end::multipeer-replicator-start[]
    }

    public void stopReplicator() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();
        // tag::multipeer-replicator-stop[]
        replicator.stop();
        // end::multipeer-replicator-stop[]
    }

    public void statusListener() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();

        // tag::multipeer-status-listener[]
        final ListenerToken token = replicator.addStatusListener(status -> {
            final String state = status.isActive() ? "active" : "inactive";
            final String error = status.getError() != null ? status.getError().getMessage() : "none";

            Log.i(TAG, String.format("Multipeer replicator: %s, Error: %s", state, error));
        });
        // end::multipeer-status-listener[]
    }

    public void peerDiscoveryListener() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();

        // tag::multipeer-peer-discovery-listener[]
        final ListenerToken token = replicator.addPeerDiscoveryStatusListener(status -> {
            final String online = status.isOnline() ? "online" : "offline";
            Log.i(TAG, String.format("Peer Discovery Status - Peer ID: %s Status: %s",
                    status.getPeer(), online));
        });
        // end::multipeer-peer-discovery-listener[]
    }

    public void peerDocumentReplication() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();

        // tag::multipeer-document-replication-listener[]
        final ListenerToken token = replicator.addPeerDocumentReplicationListener(status -> {
            final String direction = status.isPush() ? "push" : "pull";
            Log.i(TAG, String.format("Peer Document Replication - Peer ID: %s Direction: %s", status.getPeer(), direction));
            for(ReplicatedDocument doc : status.getDocuments()) {
                final Exception docError = doc.getError();
                final String error = docError != null ? docError.getMessage() : "none";
                final String collection = String.format("%s.%s", doc.getScope(), doc.getCollection());
                Log.i(TAG, String.format(" Collection: %s, Document ID: %s, " +
                        "Flags: %s, Error: %s", collection, doc.getID(), doc.getFlags(), error));
            }
        });
        // end::multipeer-document-replication-listener[]
    }

    public void peerID() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();

        // tag::multipeer-peer-id[]
        final PeerInfo.PeerId peerID = replicator.getPeerId();
        Log.i(TAG, String.format("Peer ID: %s", peerID));
        // end::multipeer-peer-id[]
    }

    public void neighborPeers() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();

        // tag::multipeer-neighbor-peers[]
        Log.i(TAG, "Neighbor Peers:");
        for(PeerInfo.PeerId peer : replicator.getNeighborPeers()) {
            Log.i(TAG, String.format(" %s", peer));
        }
        // end::multipeer-neighbor-peers[]
    }

    public void peerInfo() throws CouchbaseLiteException, CertificateException {
        final MultipeerReplicator replicator = createMultipeerReplicator();

        // tag::multipeer-peer-info[]
        for(PeerInfo.PeerId peer : replicator.getNeighborPeers()) {
            final PeerInfo info = replicator.getPeerInfo(peer);
            Log.i(TAG, String.format("Peer ID: %s", peer));
            final String online = info.isOnline() ? "online" : "offline";
            Log.i(TAG, String.format(" Status: %s", online));
            Log.i(TAG, " Neighbor Peers:");
            for(PeerInfo.PeerId neighbor : info.getNeighbors()) {
                Log.i(TAG, String.format(" %s", neighbor));
            }

            final ReplicatorStatus replStatus = info.getReplicatorStatus();
            final String activity = replStatus.getActivityLevel().name().toLowerCase();
            final String error = replStatus.getError() != null ? replStatus.getError().getMessage() : "none";
            Log.i(TAG, String.format(" Replicator Status: %s, Error: %s", activity, error));
        }
        // end::multipeer-peer-info[]
    }

    public void logging() {
        // tag::multipeer-logdomain[]
        // Enable verbose console logging for multipeer replicator-related domains only.
        LogSinks.get().setConsole(new ConsoleLogSink(LogLevel.VERBOSE, LogDomain.PEER_DISCOVERY,
                LogDomain.MULTIPEER));
        // end::multipeer-logdomain[]
    }
}
