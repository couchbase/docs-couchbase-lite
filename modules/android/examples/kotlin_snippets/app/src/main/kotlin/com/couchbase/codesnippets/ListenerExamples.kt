//
// Copyright (c) 2021 Couchbase, Inc All rights reserved.
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
@file:Suppress("UNUSED_VARIABLE", "unused")

package com.couchbase.codesnippets

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.KeyStoreUtils
import com.couchbase.lite.ListenerCertificateAuthenticator
import com.couchbase.lite.ListenerPasswordAuthenticator
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpointListener
import com.couchbase.lite.URLEndpointListenerConfiguration
import com.couchbase.lite.URLEndpointListenerConfigurationFactory
import com.couchbase.lite.newConfig
import java.io.File
import java.io.IOException
import java.net.URI
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.NoSuchAlgorithmException
import java.security.cert.Certificate
import java.security.cert.CertificateException

private const val TAG = "LISTEN"

@Suppress("unused")
class ListenerExamples {
    private var thisListener: URLEndpointListener? = null

    // tag::listener-config-auth-cert-full[]
    /**
     * Snippet 2: create a ListenerCertificateAuthenticator and configure the listener with it
     *
     *
     * Start a listener for db that accepts connections from a client identified by any of the passed certs
     *
     * @param collections the collections to which the listener is attached
     * @param certs the name of the single valid user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Throws(CouchbaseLiteException::class)
    fun startServer(collections: Set<Collection>, serverId: TLSIdentity, certs: List<Certificate?>): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                collections = collections,
                port = 0, // this is the default
                disableTls = false,
                identity = serverId,
                authenticator = ListenerCertificateAuthenticator(certs)
            )
        )
        listener.start()
        val urls: List<URI> = listener.urls
        return if (urls.isEmpty()) {
            null
        } else {
            urls[0]
        }
    }
    // end::listener-config-auth-cert-full[]

    // tag::listener-config-delete-cert-full[]
    /**
     * Delete an identity from the keystore
     *
     * @param alias the alias for the identity to be deleted
     */
    @Throws(
        KeyStoreException::class,
        CertificateException::class,
        NoSuchAlgorithmException::class,
        IOException::class
    )
    fun deleteIdentity(alias: String?) {
        val keyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        keyStore.deleteEntry(alias) // <.>
    }
    // end::listener-config-delete-cert-full[]


    fun listenerConfigClientAuthLambdaExample(thisConfig: URLEndpointListenerConfiguration) {
        // tag::listener-config-client-auth-lambda[]
        // Configure authentication using application logic
        val thisCorpId = TLSIdentity.getIdentity("OurCorp") // <.>
            ?: throw IllegalStateException("Cannot find corporate id")

        thisConfig.tlsIdentity = thisCorpId

        thisConfig.authenticator = ListenerCertificateAuthenticator { certs ->
            // supply logic that returns boolean
            // true for authenticate, false if not
            // For instance:
            certs[0] == thisCorpId.certs[0]
        } // <.> <.>


        val thisListener = URLEndpointListener(thisConfig)

        // end::listener-config-client-auth-lambda[]
    }

    fun listenerConfigClientAuthRootExample(collections: Set<Collection>) {
        // tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Configure the client authenticator
        // to validate using ROOT CA
        // thisClientID.certs is a list containing a client cert to accept
        // and any other certs needed to complete a chain between the client cert
        // and a CA
        val validId = TLSIdentity.getIdentity("Our Corporate Id")
            ?: throw IllegalStateException("Cannot find corporate id")

        // accept only clients signed by the corp cert
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                // get the identity <.>
                collections = collections,
                identity = validId,
                authenticator = ListenerCertificateAuthenticator(validId.certs)
            )
        ) // <.>

        // end::listener-config-client-auth-root[]
        // end::listener-config-client-root-ca[]
    }

    fun listenerConfigTlsIdFullExample(keyFile: File, collections: Set<Collection>) {
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]

        // Import a key pair into secure storage
        // Create a TLSIdentity from the imported key-pair
        // This only needs to happen once.  Once the key is in the internal store
        // it can be referenced using its alias
        // This method of importing a key is insecure
        // Android has better ways of importing keys
        keyFile.inputStream().use { // <.>
            KeyStoreUtils.importEntry(
                "PKCS12",  // KeyStore type, eg: "PKCS12"
                it,  // An InputStream from the keystore
                "let me in".toCharArray(),  // The keystore password
                "topSekritKey",  // The alias to be used (in external keystore)
                null,  // The key password or null if the key has none
                "test-alias" // The alias for the imported key
            )
        }

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        URLEndpointListenerConfigurationFactory.newConfig(
            collections,
            identity = TLSIdentity.getIdentity("test-alias")
        ) // <.>
        // end::listener-config-tls-id-caCert[]

        // end::listener-config-tls-id-set[]
        // end::listener-config-tls-id-full[]
    }

    fun deleteIdentityExample(alias: String) {
        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        val thisKeyStore = KeyStore.getInstance("AndroidKeyStore")
        thisKeyStore.load(null)
        thisKeyStore.deleteEntry(alias)

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]
    }

    fun listenerGetNetworkInterfacesExample(collections: Set<Collection>) {
        // tag::listener-get-network-interfaces[]
        val listener = URLEndpointListener(URLEndpointListenerConfigurationFactory.newConfig(collections))
        listener.start()
        thisListener = listener
        log("URLS are ${listener.urls}")
        // end::listener-get-network-interfaces[]
    }


    // tag::listener-config-client-auth-pwd-full[]
    /**
     *
     * Start a listener for db that accepts connections using exactly the passed username and password
     *
     *
     * @param collections       the set of collections to which the listener is attached
     * @param username the name of the single valid user
     * @param password the password for the user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    fun startServer(collections: Set<Collection>, username: String, password: CharArray): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                collections = collections,
                port = 0,// this is the default
                disableTls = true,
                authenticator = ListenerPasswordAuthenticator { usr, pwd ->
                    (usr == username) && (pwd.contentEquals(password))
                })
        )

        listener.start()
        val urls: List<URI> = listener.urls
        return if (urls.isEmpty()) {
            null
        } else {
            urls[0]
        }
    }
    // notend::listener-config-client-auth-pwd-full[]


    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    // Create a TLSIdentity for the server using convenience API.
    // System generates self-signed cert
    companion object {
        val CERT_ATTRIBUTES = mapOf( //<.>
            TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
            TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
        )
    }

    // Store the TLS identity in secure storage
    // under the label 'couchbase-docs-cert'
    fun listenerWithSelfSignedCert(thisConfig: URLEndpointListenerConfiguration) {
        val thisIdentity = TLSIdentity.createIdentity(
            true,
            CERT_ATTRIBUTES,
            null,
            "couchbase-docs-cert"
        ) // <.>

        // end::listener-config-tls-id-SelfSigned[]

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        thisConfig.tlsIdentity = thisIdentity // <.>

        // end::listener-config-tls-id-set[]
    }

    fun passiveListenerExample(collections: Set<Collection>, validUser: String, validPass: CharArray) {
        // EXAMPLE 1
        // tag::listener-start[]
        // Initialize the listener
        // tag::listener-initialize[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                // tag::listener-config-db[]
                collections = collections, // <.>
                // end::listener-config-db[]
                // tag::listener-config-port[]
                port = 55990, // <.>
                // end::listener-config-port[]
                // tag::listener-config-netw-iface[]
                networkInterface = "wlan0", // <.>

                // end::listener-config-netw-iface[]
                // tag::listener-config-delta-sync[]
                enableDeltaSync = false, // <.>

                // end::listener-config-delta-sync[]
                // tag::listener-config-tls-full[]
                // Configure server security
                // tag::listener-config-tls-enable[]
                disableTls = false, // <.>

                // end::listener-config-tls-enable[]
                // tag::listener-config-tls-id-anon[]
                // Use an Anonymous Self-Signed Cert
                identity = null, // <.>
                // end::listener-config-tls-id-anon[]

                // tag::listener-config-client-auth-pwd[]
                // Configure Client Security using an Authenticator
                // For example, Basic Authentication <.>
                authenticator = ListenerPasswordAuthenticator { usr, pwd ->
                    (usr === validUser) && (validPass.contentEquals(pwd))
                }
            ))

        // Start the listener
        listener.start() // <.>
        // end::listener-initialize[]
        // end::listener-start[]
    }

    fun simpleListenerExample(db: Database) {
        // tag::listener-simple[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.newConfig(
                collections = db.collections,
                authenticator = ListenerPasswordAuthenticator { user, pwd ->
                    (user == "daniel") && (String(pwd) == "123")  // <.>
                })
        )
        listener.start() // <.>
        thisListener = listener

        // end::listener-simple[]
    }

    fun overrideConfigExample(db: Database) {
        // tag::override-config[]
        val listener8080 = URLEndpointListenerConfigurationFactory.newConfig(
            networkInterface = "en0",
            port = 8080
        )
        val listener8081 = listener8080.newConfig(port = 8081)
        // end::override-config[]
    }

    fun listenerStatusCheckExample(db: Database) {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory
                .newConfig(collections = db.collections)
        )
        listener.start()
        thisListener = listener
        // tag::listener-status-check[]
        val connectionCount = listener.status?.connectionCount // <.>
        val activeConnectionCount = listener.status?.activeConnectionCount // <.>
        // end::listener-status-check[]
    }

    fun listenerStopExample() {
        // tag::listener-stop[]
        val listener = thisListener
        thisListener = null
        listener?.stop()

        // end::listener-stop[]
    }

}


