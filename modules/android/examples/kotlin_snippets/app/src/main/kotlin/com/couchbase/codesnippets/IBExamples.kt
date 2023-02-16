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

import android.content.Context
import com.couchbase.codesnippets.util.log
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.ClientCertificateAuthenticator
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.Database
import com.couchbase.lite.Endpoint
import com.couchbase.lite.KeyStoreUtils
import com.couchbase.lite.ListenerCertificateAuthenticator
import com.couchbase.lite.ListenerPasswordAuthenticator
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorActivityLevel
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.URLEndpointListener
import com.couchbase.lite.URLEndpointListenerConfigurationFactory
import com.couchbase.lite.create
import java.net.URI
import java.security.KeyStore
import java.security.cert.Certificate

private const val TAG = "P2P"


@Suppress("unused")
class IBExamples(private val context: Context, private val caCert: Certificate) {
    private val database: Database
    private var thisReplicator: Replicator? = null
    private var thisListener: URLEndpointListener? = null

    init {
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context)

        database = Database("p2p_demo")

        /* do some stuff here */
    }

    // PASSIVE PEER STUFF
    fun ibListenerSimple() {
        // tag::listener-simple[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                database = database,
                authenticator
                = ListenerPasswordAuthenticator { user, pwd -> (user == "daniel") && (String(pwd) == "123") })
        ) // <.>
        listener.start() // <.>
        thisListener = listener

        // end::listener-simple[]
    }

    fun ibReplicatorSimple() {
        // tag::replicator-simple[]
        val theListenerEndpoint: Endpoint = URLEndpoint(URI("wss://10.0.2.2:4984/db")) // <.>
        val repl = Replicator(
            ReplicatorConfigurationFactory.create(
                database = database,
                target = theListenerEndpoint,
                authenticator = BasicAuthenticator("valid.user", "valid.password.string".toCharArray()), // <.>
                acceptOnlySelfSignedServerCertificate = true
            )
        )
        repl.start() // <.>
        thisReplicator = repl
        // end::replicator-simple[]
    }

    fun ibPassListener(validUser: String, validPassword: CharArray) {
        // EXAMPLE 1
        // tag::listener-start[]
        // Initialize the listener
        // tag::listener-initialize[]
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                // tag::listener-config-db[]
                database = database, // <.>
                // end::listener-config-db[]
                // tag::listener-config-port[]
                port = 55990, // <.>
                // end::listener-config-port[]
                // tag::listener-config-netw-iface[]
                networkInterface = "10.1.1.10", // <.>

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
                authenticator = ListenerPasswordAuthenticator { username, paassword ->
                    (username === validUser) && (paassword === validPassword)
                }
            ))

        // Start the listener
        listener.start() // <.>
        thisListener = listener

        // end::listener-initialize[]
        // end::listener-start[]
    }

    fun ibListenerGetNetworkInterfaces() {
        // tag::listener-get-network-interfaces[]
        val listener = URLEndpointListener(URLEndpointListenerConfigurationFactory.create(database = database))
        listener.start()
        log("URLS are ${listener.urls}")
        thisListener = listener
        // end::listener-get-network-interfaces[]
    }

    fun ibListenerLocalDb() {
        // tag::listener-local-db[]
        // . . . preceding application logic . . .
        CouchbaseLite.init(context) // <.>
        val thisDB = Database("passivepeerdb")
        // end::listener-local-db[]
    }

    fun ibListenerConfigTlsDisable() {
        // tag::listener-config-tls-disable[]
        URLEndpointListenerConfigurationFactory.create(database, disableTls = false) // <.>
        // end::listener-config-tls-disable[]
    }


    // !!!GBM: USERS SHOULD BE CAUTIONED THAT THIS IS INSECURE
    // Android has much better ways of importing keys
    fun ibListenerConfigTlsIdFull() {
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]
        // Use CA Cert
        // Import a key pair into secure storage
        // Create a TLSIdentity from the imported key-pair

        this.javaClass.getResourceAsStream("serverkeypair.p12")?.use { // <.>
            KeyStoreUtils.importEntry(
                "teststore.p12",  // KeyStore type, eg: "PKCS12"
                it,  // An InputStream from the keystore
                "let me in".toCharArray(),  // The keystore password
                "topSekritKey",  // The alias to be used (in external keystore)
                null,  // The key password or null if the key has none
                "test-alias" // The alias for the imported key
            )
        }

        // end::listener-config-tls-id-caCert[]

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        URLEndpointListenerConfigurationFactory.create(
            database,
            identity = TLSIdentity.getIdentity("test-alias")
        ) // <.>

        // end::listener-config-tls-id-set[]
// end::listener-config-tls-id-full[]
    }

    fun ibListenerConfigClientAuthRoot() {
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
        thisListener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                // get the identity <.>
                database = database,
                identity = validId,
                authenticator = ListenerCertificateAuthenticator(validId.certs)
            )
        ) // <.>

        // end::listener-config-client-auth-root[]
// end::listener-config-client-root-ca[]
    }

    fun ibListenerConfigTlsDisable2() {

        // tag::listener-config-tls-disable[]
        URLEndpointListenerConfigurationFactory.create(database = database, disableTls = true)
        // end::listener-config-tls-disable[]
    }

    fun ibListenerStatusCheck() {
        val listener = URLEndpointListener(URLEndpointListenerConfigurationFactory.create(database = database))
        // tag::listener-status-check[]
        val connectionCount = listener.status?.connectionCount // <.>
        val activeConnectionCount = listener.status?.activeConnectionCount // <.>
        // end::listener-status-check[]
    }

    fun ibListenerStop() {

        // tag::listener-stop[]
        thisListener?.stop()

        // end::listener-stop[]
    }

    fun ibReplicatorConfig() {
        // BEGIN additional snippets
        // tag::p2p-act-rep-config-tls-full[]

        val repl = Replicator(
            ReplicatorConfigurationFactory.create(
                database = database,

                // tag::p2p-act-rep-config-cacert[]
                // Configure Server Security
                // -- only accept CA attested certs
                acceptOnlySelfSignedServerCertificate = false, // <.>

                // end::p2p-act-rep-config-cacert[]


                // tag::p2p-act-rep-config-cacert-pinned[]

                // Use the pinned certificate from the byte array (cert)
                pinnedServerCertificate = caCert.encoded, // <.>
                // end::p2p-act-rep-config-cacert-pinned[]


                // end::p2p-act-rep-config-tls-full[]
                // tag::p2p-tlsid-tlsidentity-with-label[]
                // ... other replicator configuration
                // Provide a client certificate to the server for authentication
                authenticator = ClientCertificateAuthenticator(
                    TLSIdentity.getIdentity("clientId")
                        ?: throw IllegalStateException("Cannot find client id")
                ) // <.>

                // ... other replicator configuration

            )
        )

        thisReplicator = repl
        // end::p2p-tlsid-tlsidentity-with-label[]
    }

    fun ibP2pListener() {
        CouchbaseLite.init(context)
        val thisDB = Database("passivepeerdb") // <.>


        // Initialize the listener
        val listener = URLEndpointListener( // <.>

            // Initialize the listener config
            URLEndpointListenerConfigurationFactory.create(
                database = thisDB,
                port = 55990, /* <.>  Optional; defaults to auto */
                disableTls = false, /* <.>  Optional; defaults to false */
                enableDeltaSync = true,  /* <.> Optional; defaults to false */

                // Configure the client authenticator (if using basic auth)
                authenticator = ListenerPasswordAuthenticator { username, password ->
                    ("username" === username) && (password === "password".toCharArray())  // <.>
                }
            )
        )

        // Start the listener
        listener.start() // <.>


        // tag::createTlsIdentity[]

//        Map<String, String> X509_ATTRIBUTES = mapOf(
//                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
//                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
//                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
//                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
//        );
        val thisIdentity = TLSIdentity.createIdentity(
            true,
            mapOf(
                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
            ),
            null,
            "test-alias"
        )

        // end::createTlsIdentity[]

        // tag::p2p-tlsid-store-in-keychain[]
        // end::p2p-tlsid-store-in-keychain[]


        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        val thisAlias = "alias-to-delete"
        val thisKeyStore = KeyStore.getInstance("AndroidKeyStore")
        thisKeyStore.load(null)
        thisKeyStore.deleteEntry(thisAlias)

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]

        // tag::retrieveTlsIdentity[]
        // OPTIONALLY:: Retrieve a stored TLS identity using its alias/label
        val thatIdentity = TLSIdentity.getIdentity("couchbase-docs-cert")
        // end::retrieveTlsIdentity[]
    }

    // tag::sgw-repl-pull[]
    fun ibRplicatorPull() {
        val database = Database("ian")

        val uri = URI("wss://10.0.2.2:4984/db") // <.>

        val repl = Replicator( // <.>
            ReplicatorConfigurationFactory.create(
                database = database,
                target = URLEndpoint(uri),
                type = ReplicatorType.PULL
            )
        )

        repl.start()
        thisReplicator = repl
    }

/* C A L L O U T S

// Listener Callouts

// tag::listener-callouts-full[]

// tag::listener-start-callouts[]
<.> Initialize the listener instance using the configuration settings.
<.> Start the listener, ready to accept connections and incoming data from active peers.

// end::listener-start-callouts[]

// tag::listener-status-check-callouts[]

<.> `connectionCount` -- the total number of connections served by the listener
<.> `activeConnectionCount` -- the number of active (BUSY) connections currently being served by the listener
//
// end::listener-status-check-callouts[]

// end::listener-callouts-full[]


// tag::p2p-act-rep-config-cacert-pinned-callouts[]
<.> Configure the pinned certificate using data from the byte array `cert`
// end::p2p-act-rep-config-cacert-pinned-callouts[]

// tag::p2p-tlsid-tlsidentity-with-label-callouts[]
<.> Attempt to get the identity from secure storage
<.> Set the authenticator to ClientCertificateAuthenticator and configure it to use the retrieved identity

// end::p2p-tlsid-tlsidentity-with-label-callouts[]

// tag::sgw-repl-pull-callouts[]
<.> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<.> The URL scheme for remote database URLs uses `ws:`, or `wss:` for SSL/TLS connections over wb sockets.
In this example the hostname is `10.0.2.2` because the Android emulator runs in a VM that is generally accessible on `10.0.2.2` from the host machine (see https://developer.android.com/studio/run/emulator-networking[Android Emulator networking] documentation).
+
NOTE: As of Android Pie, version 9, API 28, cleartext support is disabled, by default.
Although `wss:` protocol URLs are not affected, in order to use the `ws:` protocol, applications must target API 27 or lower, or must configure application network security as described https://developer.android.com/training/articles/security-config#CleartextTrafficPermitted[here].

// end::sgw-repl-pull-callouts[]
*/
}
