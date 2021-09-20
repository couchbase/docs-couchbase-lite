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
package com.couchbase.code_snippets

import android.content.Context
import android.util.Log
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.ClientCertificateAuthenticator
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.ListenerCertificateAuthenticator
import com.couchbase.lite.ListenerPasswordAuthenticator
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorActivityLevel
import com.couchbase.lite.ReplicatorConfiguration
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.TLSIdentity
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.URLEndpointListener
import com.couchbase.lite.URLEndpointListenerConfigurationFactory
import com.couchbase.lite.create
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.URI
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.NoSuchAlgorithmException
import java.security.cert.Certificate
import java.security.cert.CertificateEncodingException
import java.security.cert.CertificateException
import java.util.concurrent.CountDownLatch

private const val TAG = "LISTEN"

@Suppress("unused")
class CertAuthListener {
    companion object {
        private val CERT_ATTRIBUTES = mapOf(
            TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "CBL Test",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
            TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
            TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "lite@couchbase.com",
        )
    }

    // start a server and connect to it with a replicator
    @Throws(CouchbaseLiteException::class, IOException::class)
    fun run() {
        val localDb = Database("localDb")
        var doc = MutableDocument()
        doc.setString("dog", "woof")
        localDb.save(doc)

        val remoteDb = Database("remoteDb")
        doc = MutableDocument()
        doc.setString("cat", "meow")
        remoteDb.save(doc)

        val serverIdentity = TLSIdentity.createIdentity(true, CERT_ATTRIBUTES, null, "server")

        val clientIdentity = TLSIdentity.createIdentity(false, CERT_ATTRIBUTES, null, "client")
        val uri = startServer(remoteDb, serverIdentity, clientIdentity.certs)
            ?: throw IOException("Failed to start the server")

        Thread {
            startClient(localDb, uri, clientIdentity, serverIdentity.certs[0])
            Log.e(TAG, "Success!!")
            deleteIdentity("server")
            Log.e(TAG, "Alias deleted: server")
            deleteIdentity("client")
            Log.e(TAG, "Alias deleted: client")
        }.start()
    }

    // start a client replicator
    @Throws(CertificateEncodingException::class, InterruptedException::class)
    fun startClient(db: Database, uri: URI, clientIdentity: TLSIdentity, cert: Certificate) {
        val repl = Replicator(
            ReplicatorConfigurationFactory.create(
                database = db,
                target = URLEndpoint(uri),
                type = ReplicatorType.PUSH_AND_PULL,
                continuous = false,
                authenticator = ClientCertificateAuthenticator(clientIdentity),
                pinnedServerCertificate = cert.encoded
            )
        )

        val completionLatch = CountDownLatch(1)

        repl.addChangeListener { change ->
            if (change.status.activityLevel == ReplicatorActivityLevel.STOPPED) {
                completionLatch.countDown()
            }
        }
        repl.start(false)
        completionLatch.await()
    }
    // tag::listener-config-auth-cert-full[]
    /**
     * Snippet 2: create a ListenerCertificateAuthenticator and configure the listener with it
     *
     *
     * Start a listener for db that accepts connections from a client identified by any of the passed certs
     *
     * @param db    the database to which the listener is attached
     * @param certs the name of the single valid user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Throws(CouchbaseLiteException::class)
    fun startServer(db: Database, serverId: TLSIdentity, certs: List<Certificate?>): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                database = db,
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
    // nottag::p2p-tlsid-tlsidentity-with-label[]
    /**
     * Snippet 4: Create a ClientCertificateAuthenticator and use it in a replicator
     * Snippet 5: Specify a pinned certificate as a byte array
     *
     *
     * Configure Client (active) side certificates
     *
     * @param config         The replicator configuration
     * @param cert           The expected server side certificate
     * @param clientIdentity the identity offered to the server as authentication
     * @throws CertificateEncodingException on certifcate encoding error
     */
    @Throws(CertificateEncodingException::class)
    private fun configureClientCerts(
        config: ReplicatorConfiguration,
        cert: Certificate,
        clientIdentity: TLSIdentity
    ) {

        // Snippet 4: create an authenticator that provides the client identity
        config.setAuthenticator(ClientCertificateAuthenticator(clientIdentity))

        // Configure the pinned certificate passing a byte array.
        config.pinnedServerCertificate = cert.encoded
    }
    // notend::p2p-tlsid-tlsidentity-with-label[]
    /**
     * Snippet 5 (supplement): Copy a cert from a resource bundle
     *
     *
     * Configure Client (active) side certificates
     *
     * @param context Android context
     * @param resId   resource id for resource: R.id.foo
     * @throws IOException on copy error
     */
    @Throws(IOException::class)
    private fun readCertMaterialFromBundle(
        context: Context,
        resId: Int
    ): ByteArray {
        val out = ByteArrayOutputStream()
        val `in` = context.resources.openRawResource(resId)
        val buf = ByteArray(1024)
        var n: Int
        while (`in`.read(buf).also { n = it } >= 0) {
            out.write(buf, 0, n)
        }
        return out.toByteArray()
    }
}

@Suppress("unused")
class PasswordAuthListener {
    companion object {
        private const val VALID_USER = "Minnie"
        private val VALID_PASSWORD = "let me in!".toCharArray()
    }

    // start a server and connect to it with a replicator
    @Throws(CouchbaseLiteException::class, IOException::class)
    fun run() {
        val localDb = Database("localDb")
        var doc = MutableDocument()
        doc.setString("dog", "woof")
        localDb.save(doc)
        val remoteDb = Database("remoteDb")
        doc = MutableDocument()
        doc.setString("cat", "meow")
        localDb.save(doc)
        val uri = startServer(remoteDb, "fox", "wa-pa-pa-pa-pa-pow".toCharArray())
            ?: throw IOException("Failed to start the server")
        Thread {
            try {
                runClient(uri, "fox", "wa-pa-pa-pa-pa-pow".toCharArray(), localDb)
                Log.e(TAG, "Success!!")
            } catch (e: Exception) {
                Log.e(TAG, "Failed!!", e)
            }
        }.start()
    }

    // start a client replicator
    @Throws(InterruptedException::class)
    fun runClient(
        uri: URI,
        username: String,
        password: CharArray,
        db: Database
    ) {
        val config = ReplicatorConfiguration(db, URLEndpoint(uri))
        config.type = ReplicatorType.PUSH_AND_PULL
        config.isContinuous = false
        config.setAuthenticator(BasicAuthenticator(username, password))
        val completionLatch = CountDownLatch(1)
        val repl = Replicator(config)

        // Version using Kotlin Flows to follow shortly ...
        repl.addChangeListener { change ->
            if (change.status
                    .activityLevel == ReplicatorActivityLevel.STOPPED
            ) {
                completionLatch.countDown()
            }
        }
        repl.start(false)
        completionLatch.await()
    }
    // tag::listener-config-client-auth-pwd-full[]
    /**
     *
     * Start a listener for db that accepts connections using exactly the passed username and password
     *
     *
     * @param db       the database to which the listener is attached
     * @param username the name of the single valid user
     * @param password the password for the user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    fun startServer(db: Database, username: String, password: CharArray): URI? {
        val listener = URLEndpointListener(
            URLEndpointListenerConfigurationFactory.create(
                database = db,
                port = 0,// this is the default
                disableTls = true,
                authenticator = ListenerPasswordAuthenticator { usr, pwd ->
                    (usr == username) && pwd.contentEquals(password)
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
// end::listener-config-client-auth-pwd-full[]
}


