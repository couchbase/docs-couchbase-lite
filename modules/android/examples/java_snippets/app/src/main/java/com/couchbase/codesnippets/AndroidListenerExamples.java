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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableEntryException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import com.couchbase.lite.ClientCertificateAuthenticator;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.KeyStoreUtils;
import com.couchbase.lite.ListenerCertificateAuthenticator;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;


@SuppressWarnings("unused")
public class AndroidListenerExamples {
    private URLEndpointListener thisListener;
    private Replicator thisReplicator;

    public void listenerConfigTlsIdFullExample(File keyFile, Set<Collection> collections)
        throws IOException, UnrecoverableEntryException, CertificateException, KeyStoreException,
        NoSuchAlgorithmException, CouchbaseLiteException {
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]


        // Import a key pair into secure storage
        // Create a TLSIdentity from the imported key-pair
        // This only needs to happen once.  Once the key is in the internal store
        // it can be referenced using its alias
        // This method of importing a key is insecure
        // Android has better ways of importing keys
        try (InputStream thisKeyPair = new FileInputStream(keyFile)) { // <.>
            KeyStoreUtils.importEntry(
                "PKCS12",  // KeyStore type, eg: "PKCS12"
                thisKeyPair, // An InputStream from the keystore
                "let me in".toCharArray(), // The keystore password
                "sekrit", // The alias of the key in the external keystore
                null, // The key password
                "test-alias" // The alias for the imported key
            );
        }

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(collections);
        config.setTlsIdentity(TLSIdentity.getIdentity("test-alias")); // <.>
        // end::listener-config-tls-id-caCert[]

        // end::listener-config-tls-id-set[]
        // end::listener-config-tls-id-full[]
    }

    public void listenerConfigClientAuthLambdaExample(URLEndpointListenerConfiguration thisConfig)
        throws CouchbaseLiteException {
        // tag::listener-config-client-auth-lambda[]
        // Configure authentication using application logic
        final TLSIdentity thisCorpId = TLSIdentity.getIdentity("OurCorp"); // <.>
        if (thisCorpId == null) {
            throw new IllegalStateException("Cannot find corporate id");
        }
        thisConfig.setTlsIdentity(thisCorpId);
        thisConfig.setAuthenticator(
            new ListenerCertificateAuthenticator(
                (certs) -> {
                    // supply logic that returs boolean
                    // true for authenticate, false if not
                    // For instance:
                    return certs.get(0).equals(thisCorpId.getCerts().get(0));
                }
            )); // <.> <.>
        URLEndpointListener listener = new URLEndpointListener(thisConfig);
        listener.start();
        thisListener = listener;

        // end::listener-config-client-auth-lambda[]
    }

    public void listenerConfigClientAuthRootExample(URLEndpointListenerConfiguration thisConfig)
        throws CouchbaseLiteException {
        // tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Configure the client authenticator
        // to validate using ROOT CA
        // thisClientID.certs is a list containing a client cert to accept
        // and any other certs needed to complete a chain between the client cert
        // and a CA
        final TLSIdentity validId =
            TLSIdentity.getIdentity("Our Corporate Id");  // get the identity <.>
        if (validId == null) { throw new IllegalStateException("Cannot find corporate id"); }

        thisConfig.setTlsIdentity(validId);

        thisConfig.setAuthenticator(
            new ListenerCertificateAuthenticator(validId.getCerts())); // <.> <.>
        // accept only clients signed by the corp cert

        final URLEndpointListener thisListener =
            new URLEndpointListener(thisConfig);

        // end::listener-config-client-auth-root[]
        // end::listener-config-client-root-ca[]
    }

    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    private static final Map<String, String> CERT_ATTRIBUTES; //<.>
    static {
        final Map<String, String> m = new HashMap<>();
        m.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "Couchbase Demo");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
        m.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "noreply@couchbase.com");
        CERT_ATTRIBUTES = Collections.unmodifiableMap(m);
    }
    // Create the TLS identity in secure storage
    // with the alias 'couchbase-docs-cert'
    public void listenerWithSelfSignedCert(KeyStore keyStore, URLEndpointListenerConfiguration thisConfig)
        throws CouchbaseLiteException {
        TLSIdentity thisIdentity = TLSIdentity.createIdentity(
            true,
            CERT_ATTRIBUTES,
            null,
            "couchbase-docs-cert"
        ); // <.>

        // end::listener-config-tls-id-SelfSigned[]

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        thisConfig.setTlsIdentity(thisIdentity); // <.>

        // end::listener-config-tls-id-set[]
    }


    public void replicatorConfigurationExample(Set<Collection> srcCollections, URI targetUrl, KeyStore keyStore)
        throws CouchbaseLiteException {
        // tag::p2p-act-rep-config-tls-full[]

        ReplicatorConfiguration config =
            new ReplicatorConfiguration(new URLEndpoint(targetUrl))
                .addCollections(srcCollections, null)

                // tag::p2p-act-rep-config-cacert[]
                // Configure Server Security
                // -- only accept CA attested certs
                .setAcceptOnlySelfSignedServerCertificate(false); // <.>

        // end::p2p-act-rep-config-cacert[]

        // tag::p2p-act-rep-config-cacert-pinned[]
        // Use the pinned certificate from the byte array (cert)

        TLSIdentity identity = TLSIdentity.getIdentity("OurCorp");
        if (identity == null) { throw new IllegalStateException("Cannot find corporate id"); }
        config.setPinnedServerX509Certificate((X509Certificate) identity.getCerts().get(0)); // <.>

        // end::p2p-act-rep-config-cacert-pinned[]


        // end::p2p-act-rep-config-tls-full[]
        // tag::p2p-tlsid-tlsidentity-with-label[]
        // Provide a client certificate to the server for authentication
        TLSIdentity clientId = TLSIdentity.getIdentity("client");
        if (clientId == null) { throw new IllegalStateException("Cannot find client id"); }
        config.setAuthenticator(new ClientCertificateAuthenticator(clientId)); // <.>

        // ... other replicator configuration

        Replicator repl = new Replicator(config);
        repl.start();
        thisReplicator = repl;
        // end::p2p-tlsid-tlsidentity-with-label[]
    }
}
