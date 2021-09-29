
//
// Copyright (c) 2020 Couchbase, Inc All rights reserved.
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
package com.couchbase.code_snippets;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;

import com.couchbase.lite.ClientCertificateAuthenticator;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.ListenerCertificateAuthenticator;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;


class CertAuthListener {
    private static final String TAG = "PWD";

    private static final Map<String, String> CERT_ATTRIBUTES;
    static {
        final Map<String, String> m = new HashMap<>();
        m.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "CBL Test");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
        m.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "lite@couchbase.com");
        CERT_ATTRIBUTES = Collections.unmodifiableMap(m);
    }
    // start a server and connect to it with a replicator
    public void run() throws CouchbaseLiteException, IOException {
        final Database localDb = new Database("localDb");
        MutableDocument doc = new MutableDocument();
        doc.setString("dog", "woof");
        localDb.save(doc);

        Database remoteDb = new Database("remoteDb");
        doc = new MutableDocument();
        doc.setString("cat", "meow");
        localDb.save(doc);

        TLSIdentity serverIdentity = TLSIdentity.createIdentity(true, CERT_ATTRIBUTES, null, "server");
        TLSIdentity clientIdentity = TLSIdentity.createIdentity(false, CERT_ATTRIBUTES, null, "client");

        final URI uri = startServer(remoteDb, serverIdentity, clientIdentity.getCerts());
        if (uri == null) { throw new IOException("Failed to start the server"); }

        new Thread(() -> {
            try {
                startClient(uri, serverIdentity.getCerts().get(0), clientIdentity, localDb);
                Log.e(TAG, "Success!!");
                deleteIdentity("server");
                Log.e(TAG, "Alias deleted: server");
                deleteIdentity("client");
                Log.e(TAG, "Alias deleted: client");
            }
            catch (Exception e) { Log.e(TAG, "Failed!!", e); }
        }).start();
    }

    // start a client replicator
    public void startClient(
        @NonNull URI uri,
        @NonNull Certificate cert,
        @NonNull TLSIdentity clientIdentity,
        @NonNull Database db) throws CertificateEncodingException, InterruptedException {
        final ReplicatorConfiguration config = new ReplicatorConfiguration(db, new URLEndpoint(uri));
        config.setType(ReplicatorType.PUSH_AND_PULL);
        config.setContinuous(false);

        configureClientCerts(config, cert, clientIdentity);

        final CountDownLatch completionLatch = new CountDownLatch(1);
        final Replicator repl = new Replicator(config);
        repl.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == ReplicatorActivityLevel.STOPPED) {
                completionLatch.countDown();
            }
        });

        repl.start(false);
        completionLatch.await();
    }

    /**
     * Snippet 2: create a ListenerCertificateAuthenticator and configure the listener with it
     * <p>
     * Start a listener for db that accepts connections from a client identified by any of the passed certs
     *
     * @param db    the database to which the listener is attached
     * @param certs the name of the single valid user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Nullable
    public URI startServer(@NonNull Database db, @NonNull TLSIdentity serverId, @NonNull List<Certificate> certs)
        throws CouchbaseLiteException {
        final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(db);

        config.setPort(0); // this is the default
        config.setDisableTls(false);
        config.setTlsIdentity(serverId);
        config.setAuthenticator(new ListenerCertificateAuthenticator(certs));

        final URLEndpointListener listener = new URLEndpointListener(config);
        listener.start();

        final List<URI> urls = listener.getUrls();
        if (urls.isEmpty()) { return null; }
        return urls.get(0);
    }

    /**
     * Snippet 3: delete an identity from the keystore
     * (NOTE: a keystore doesn't contain TLSIdentities: I'm guessing that this is what you intend)
     * <p>
     * Delete an identity from the key store.
     *
     * @param alias the alias for the identity to be deleted
     */
    public void deleteIdentity(String alias)
        throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException {

        final KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);

        keyStore.deleteEntry(alias);
    }

    /**
     * Snippet 4: Create a ClientCertificateAuthenticator and use it in a replicator
     * Snippet 5: Specify a pinned certificate as a byte array
     * <p>
     * Configure Client (active) side certificates
     *
     * @param config         The replicator configuration
     * @param cert           The expected server side certificate
     * @param clientIdentity the identity offered to the server as authentication
     * @throws CertificateEncodingException on certifcate encoding error
     */
    private void configureClientCerts(
        ReplicatorConfiguration config,
        @NonNull Certificate cert,
        @NonNull TLSIdentity clientIdentity)
        throws CertificateEncodingException {

        // Snippet 4: create an authenticator that provides the client identity
        config.setAuthenticator(new ClientCertificateAuthenticator(clientIdentity));

        // Configure the pinned certificate passing a byte array.
        config.setPinnedServerCertificate(cert.getEncoded());
    }

    /**
     * Snippet 5 (supplement): Copy a cert from a resource bundle
     * <p>
     * Configure Client (active) side certificates
     *
     * @param context Android context
     * @param resId   resource id for resource: R.id.foo
     * @throws IOException on copy error
     */
    private byte[] readCertMaterialFromBundle(@NonNull Context context, int resId) throws IOException {
        final ByteArrayOutputStream out = new ByteArrayOutputStream();
        final InputStream in = context.getResources().openRawResource(resId);
        final byte[] buf = new byte[1024];
        int n;
        while ((n = in.read(buf)) >= 0) { out.write(buf, 0, n); }
        return out.toByteArray();
    }
}
