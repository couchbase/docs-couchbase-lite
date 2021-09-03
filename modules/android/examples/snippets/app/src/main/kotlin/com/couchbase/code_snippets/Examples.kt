//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
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
import android.widget.Toast
import com.couchbase.lite.ArrayFunction
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.Blob
import com.couchbase.lite.Conflict
import com.couchbase.lite.ConflictResolver
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.DatabaseConfiguration
import com.couchbase.lite.DatabaseEndpoint
import com.couchbase.lite.Dictionary
import com.couchbase.lite.Document
import com.couchbase.lite.DocumentFlag
import com.couchbase.lite.EncryptionKey
import com.couchbase.lite.Endpoint
import com.couchbase.lite.Expression
import com.couchbase.lite.FullTextExpression
import com.couchbase.lite.FullTextIndexItem
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.Join
import com.couchbase.lite.ListenerToken
import com.couchbase.lite.LogDomain
import com.couchbase.lite.LogFileConfiguration
import com.couchbase.lite.LogLevel
import com.couchbase.lite.Logger
import com.couchbase.lite.Message
import com.couchbase.lite.MessageEndpoint
import com.couchbase.lite.MessageEndpointConnection
import com.couchbase.lite.MessageEndpointDelegate
import com.couchbase.lite.MessageEndpointListener
import com.couchbase.lite.MessageEndpointListenerConfiguration
import com.couchbase.lite.MessagingCloseCompletion
import com.couchbase.lite.MessagingCompletion
import com.couchbase.lite.Meta
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Ordering
import com.couchbase.lite.PredictionFunction
import com.couchbase.lite.PredictiveIndex
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.ProtocolType
import com.couchbase.lite.Query
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfiguration
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorConnection
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.ResultSet
import com.couchbase.lite.SelectResult
import com.couchbase.lite.SessionAuthenticator
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.ValueIndex
import com.couchbase.lite.ValueIndexItem
import com.couchbase.lite.Where
import com.couchbase.lite.create
import com.couchbase.lite.internal.utils.PlatformUtils.getAsset
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.net.URI
import java.net.URISyntaxException
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.Arrays
import java.util.Date

private const val DATABASE_NAME = "database"

class PendingDocsExample {
    private val database: Database? = null
    private var replicator: Replicator? = null

    //  BEGIN PendingDocuments IB -- 11/Feb/21 --
    @Throws(URISyntaxException::class, CouchbaseLiteException::class)
    fun testReplicationPendingDocs() {
        // nottag::replication-pendingdocuments[]
        // ... include other code as required
        //
        val endpoint: Endpoint = URLEndpoint(URI("ws://localhost:4984/db"))
        val config: ReplicatorConfiguration = ReplicatorConfiguration(database, endpoint)
            .setType(ReplicatorType.PUSH)
        // tag::replication-push-pendingdocumentids[]
        replicator = Replicator(config)
        val pendingDocs: Set<String> = replicator.getPendingDocumentIds() // <.>

        // end::replication-push-pendingdocumentids[]
        replicator.addChangeListener({ change ->
            onStatusChanged(
                pendingDocs,
                change.status
            )
        })
        replicator.start()

        // ... include other code as required
        // notend::replication-pendingdocuments[]
    }

    //
    // tag::replication-pendingdocuments[]
    //
    private fun onStatusChanged(
        pendingDocs: Set<String>,
        status: Replicator.Status
    ) {
        // ... sample onStatusChanged function
        //
        Log.i(
            Companion.TAG,
            "Replicator activity level is " + status.getActivityLevel().toString()
        )

        // iterate and report-on previously
        // retrieved pending docids 'list'
        val itr = pendingDocs.iterator()
        while (itr.hasNext()) {
            val docId = itr.next()
            try {
                // tag::replication-push-isdocumentpending[]
                if (!replicator.isDocumentPending(docId)) {
                    continue
                } // <.>
                // end::replication-push-isdocumentpending[]
                itr.remove()
                Log.i(
                    Companion.TAG,
                    "Doc ID $docId has been pushed"
                )
            } catch (e: CouchbaseLiteException) {
                Log.w(
                    Companion.TAG,
                    "isDocumentPending failed",
                    e
                )
            }
        }
    } // end::replication-pendingdocuments[]

    //  END PendingDocuments BM -- 19/Feb/21 --
    companion object {
        private const val TAG = "SCRATCH"
    }
}

class Examples(private val context: Context) {

    /* ----------------------------------------------------------- */ /* ---------------------  ACTIVE SIDE  ----------------------- */ /* ----------------------------------------------------------- */
    internal class BrowserSessionManager private constructor(private val context: Context) :
        MessageEndpointDelegate {
        private var replicator: Replicator? = null

        @Throws(CouchbaseLiteException::class)
        fun initCouchbase() {
            // tag::message-endpoint[]
            val databaseConfiguration = DatabaseConfiguration(context)
            val database = Database("mydb", databaseConfiguration)

            // The delegate must implement the `MessageEndpointDelegate` protocol.
            val messageEndpointTarget = MessageEndpoint(
                "UID:123",
                "active",
                ProtocolType.MESSAGE_STREAM,
                this
            )
            // end::message-endpoint[]

            // tag::message-endpoint-replicator[]
            val config =
                ReplicatorConfiguration(database, messageEndpointTarget)

            // Create the replicator object.
            replicator = Replicator(config)
            // Start the replication.
            replicator.start()
            // end::message-endpoint-replicator[]
        }

        // tag::create-connection[]
        /* implementation of MessageEndpointDelegate */
        fun createConnection(endpoint: MessageEndpoint?): MessageEndpointConnection {
            return ActivePeerConnection() /* implements MessageEndpointConnection */
        } // end::create-connection[]

    }

    internal class ActivePeerConnection : MessageEndpointConnection {
        private var replicatorConnection: ReplicatorConnection? = null
        fun disconnect() {
            // tag::active-replicator-close[]
            replicatorConnection.close(null)
            // end::active-replicator-close[]
        }

        // tag::active-peer-open[]
        /* implementation of MessageEndpointConnection */
        fun open(
            connection: ReplicatorConnection?,
            completion: MessagingCompletion
        ) {
            replicatorConnection = connection
            completion.complete(true, null)
        }

        // end::active-peer-open[]
        // tag::active-peer-close[]
        override fun close(
            error: Exception?,
            completion: MessagingCloseCompletion
        ) {
            /* disconnect with communications framework */
            /* ... */
            /* call completion handler */
            completion.complete()
        }

        // end::active-peer-close[]
        // tag::active-peer-send[]
        /* implementation of MessageEndpointConnection */
        fun send(message: Message?, completion: MessagingCompletion) {
            /* send the data to the other peer */
            /* ... */
            /* call the completion handler once the message is sent */
            completion.complete(true, null)
        }

        // end::active-peer-send[]
        fun receive(message: Message?) {
            // tag::active-peer-receive[]
            replicatorConnection.receive(message)
            // end::active-peer-receive[]
        }
    } /* ----------------------------------------------------------- */ /* ---------------------  PASSIVE SIDE  ---------------------- */ /* ----------------------------------------------------------- */

    internal class PassivePeerConnection private constructor(private val context: Context) :
        MessageEndpointConnection {
        private var messageEndpointListener: MessageEndpointListener? = null
        private var replicatorConnection: ReplicatorConnection? = null

        @Throws(CouchbaseLiteException::class)
        fun startListener() {
            // tag::listener[]
            val databaseConfiguration = DatabaseConfiguration()
            val database = Database("mydb", databaseConfiguration)
            val listenerConfiguration =
                MessageEndpointListenerConfiguration(
                    database,
                    ProtocolType.MESSAGE_STREAM
                )
            messageEndpointListener = MessageEndpointListener(listenerConfiguration)
            // end::listener[]
        }

        fun stopListener() {
            // tag::passive-stop-listener[]
            messageEndpointListener.closeAll()
            // end::passive-stop-listener[]
        }

        fun accept() {
            // tag::advertizer-accept[]
            val connection = PassivePeerConnection(context) /* implements
        MessageEndpointConnection */
            messageEndpointListener.accept(connection)
            // end::advertizer-accept[]
        }

        fun disconnect() {
            // tag::passive-replicator-close[]
            replicatorConnection.close(null)
            // end::passive-replicator-close[]
        }

        // tag::passive-peer-open[]
        /* implementation of MessageEndpointConnection */
        fun open(
            connection: ReplicatorConnection?,
            completion: MessagingCompletion
        ) {
            replicatorConnection = connection
            completion.complete(true, null)
        }

        // end::passive-peer-open[]
        // tag::passive-peer-close[]
        /* implementation of MessageEndpointConnection */
        fun close(
            error: Exception?,
            completion: MessagingCloseCompletion
        ) {
            /* disconnect with communications framework */
            /* ... */
            /* call completion handler */
            completion.complete()
        }

        // end::passive-peer-close[]
        // tag::passive-peer-send[]
        /* implementation of MessageEndpointConnection */
        fun send(message: Message?, completion: MessagingCompletion) {
            /* send the data to the other peer */
            /* ... */
            /* call the completion handler once the message is sent */
            completion.complete(true, null)
        }

        // end::passive-peer-send[]
        fun receive(message: Message?) {
            // tag::passive-peer-receive[]
            replicatorConnection.receive(message)
            // end::passive-peer-receive[]
        }

    } // tag::predictive-model[]

    // `tensorFlowModel` is a fake implementation
// this would be the implementation of the ml model you have chosen
    internal class ImageClassifierModel : PredictiveModel {
        fun predict(input: Dictionary): Dictionary? {
            val blob: Blob = input.getBlob("photo") ?: return null

            // `tensorFlowModel` is a fake implementation
            // this would be the implementation of the ml model you have chosen
            return MutableDictionary(TensorFlowModel.predictImage(blob.content)) // <1>
        }
    }

    internal object TensorFlowModel {
        fun predictImage(data: ByteArray?): Map<String, Any>? {
            return null
        }
    } // end::predictive-model[]

    // tag::custom-logging[]
    internal class LogTestLogger(level: LogLevel) : Logger {

        private val level: LogLevel


        fun getLevel(): LogLevel {
            return level
        }

        fun log(
            level: LogLevel?,
            domain: LogDomain?,
            message: String?
        ) {
            // this method will never be called if param level < this.level
            // handle the message, for example piping it to a third party framework
        }

        init {
            this.level = level
        }
    }

    class CertAuthListener {
        companion object {
            private const val TAG = "PWD"
            private var CERT_ATTRIBUTES: Map<String, String>? = null

            init {
                val m: Map<String, String> =
                    HashMap()
                com.couchbase.code_snippets.m.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "CBL Test")
                com.couchbase.code_snippets.m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase")
                com.couchbase.code_snippets.m.put(
                    TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT,
                    "Mobile"
                )
                com.couchbase.code_snippets.m.put(
                    TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS,
                    "lite@couchbase.com"
                )
                CERT_ATTRIBUTES =
                    Collections.unmodifiableMap(com.couchbase.code_snippets.m)
            }
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
            val serverIdentity: TLSIdentity = TLSIdentity.createIdentity(
                true,
                CERT_ATTRIBUTES,
                null,
                "server"
            )
            val clientIdentity: TLSIdentity = TLSIdentity.createIdentity(
                false,
                CERT_ATTRIBUTES,
                null,
                "client"
            )
            val uri = startServer(remoteDb, serverIdentity, clientIdentity.getCerts())
                ?: throw IOException("Failed to start the server")
            Thread(Runnable {
                try {
                    startClient(uri, serverIdentity.getCerts().get(0), clientIdentity, localDb)
                    Log.e(TAG, "Success!!")
                    deleteIdentity("server")
                    Log.e(TAG, "Alias deleted: server")
                    deleteIdentity("client")
                    Log.e(TAG, "Alias deleted: client")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed!!", e)
                }
            }).start()
        }

        // start a client replicator
        @Throws(CertificateEncodingException::class, InterruptedException::class)
        fun startClient(
            uri: URI?,
            cert: Certificate,
            clientIdentity: TLSIdentity,
            db: Database?
        ) {
            val config = ReplicatorConfiguration(db, URLEndpoint(uri))
            config.replicatorType = ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL
            config.isContinuous = false
            configureClientCerts(config, cert, clientIdentity)
            val completionLatch = CountDownLatch(1)
            val repl = Replicator(config)
            repl.addChangeListener({ change ->
                if (change.status
                        .activityLevel === AbstractReplicator.ActivityLevel.STOPPED
                ) {
                    completionLatch.countDown()
                }
            })
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
        @Nullable
        @Throws(CouchbaseLiteException::class)
        fun startServer(
            db: Database?,
            serverId: TLSIdentity?,
            certs: List<Certificate?>?
        ): URI? {
            val config = URLEndpointListenerConfiguration(db)
            config.setPort(0) // this is the default
            config.setDisableTls(false)
            config.setTlsIdentity(serverId)
            config.setAuthenticator(ListenerCertificateAuthenticator(certs))
            val listener = URLEndpointListener(config)
            listener.start()
            val urls: List<URI> = listener.getUrls()
            return if (urls.isEmpty()) {
                null
            } else urls[0]
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
            config.pinnedServerCertificate = cert.getEncoded()
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

    class PasswordAuthListener {
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
            Thread(Runnable {
                try {
                    runClient(uri, "fox", "wa-pa-pa-pa-pa-pow".toCharArray(), localDb)
                    Log.e(TAG, "Success!!")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed!!", e)
                }
            }).start()
        }

        // start a client replicator
        @Throws(InterruptedException::class)
        fun runClient(
            uri: URI?,
            username: String?,
            password: CharArray?,
            db: Database?
        ) {
            val config = ReplicatorConfiguration(db, URLEndpoint(uri))
            config.replicatorType = ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL
            config.isContinuous = false
            config.setAuthenticator(BasicAuthenticator(username, password))
            val completionLatch = CountDownLatch(1)
            val repl = Replicator(config)
            repl.addChangeListener({ change ->
                if (change.status
                        .activityLevel === AbstractReplicator.ActivityLevel.STOPPED
                ) {
                    completionLatch.countDown()
                }
            })
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
        @Nullable
        fun startServer(
            db: Database?,
            username: String?,
            password: CharArray?
        ): URI?

        companion object {
            private const val TAG = "PWD"
        }

        init {
            val config = URLEndpointListenerConfiguration(db)
            config.setPort(0) // this is the default
            config.setDisableTls(true)
            config.setAuthenticator(
                ListenerPasswordAuthenticator { validUser, pwd ->
                    username.equals(validUser) && Arrays.equals(
                        validPassword,
                        pwd
                    )
                }
            )
            val listener = URLEndpointListener(config)
            listener.start()
            val urls: List<URI> = listener.getUrls()
            return if (urls.isEmpty()) {
                null
            } else urls[0]
        }
        // end::listener-config-client-auth-pwd-full[]
    }


    class ExamplesP2p(private val context: Context) {
        private val database: Database? = null
        private var replicator: Replicator? = null

        //@Test
        @Throws(CouchbaseLiteException::class, URISyntaxException::class)
        fun testGettingStarted() {

            // Initialize the Couchbase Lite system
            CouchbaseLite.init(context)

            /* do some stuff here */
        }

        // PASSIVE PEER STUFF
        fun ibListenerSimple() {
            // tag::listener-simple[]
            val thisConfig =
                URLEndpointListenerConfiguration(thisDB) // <.>
            thisConfig.setAuthenticator(
                ListenerPasswordAuthenticator { username, password ->
                    username.equals("valid.User") &&
                            Arrays.equals(password, valid.password.string)
                }
            ) // <.>
            val thisListener = URLEndpointListener(thisConfig) // <.>
            thisListener.start() // <.>

            // end::listener-simple[]
        }

        fun ibReplicatorSimple() {
            // tag::replicator-simple[]
            var uri: URI? = null
            try {
                uri = URI("wss://10.0.2.2:4984/db")
            } catch (e: URISyntaxException) {
                e.printStackTrace()
            }
            val theListenerEndpoint: Endpoint = URLEndpoint(uri) // <.>
            val thisConfig =
                ReplicatorConfiguration(database, theListenerEndpoint) // <.>
            thisConfig.isAcceptOnlySelfSignedServerCertificate = true // <.>
            val thisAuth = BasicAuthenticator(
                "valid.user",
                "valid.password.string"
            )
            thisConfig.setAuthenticator(thisAuth) // <.>
            replicator = Replicator(config) // <.>
            replicator.start() // <.>

            // end::replicator-simple[]
        }

        fun ibPassListener() {
// EXAMPLE 1
            // tag::listener-initialize[]
            // tag::listener-config-db[]
            // Initialize the listener config
            val thisConfig =
                URLEndpointListenerConfiguration(thisDB) // <.>

            // end::listener-config-db[]
            // tag::listener-config-port[]
            thisConfig.setPort(55990) // <.>

            // end::listener-config-port[]
            // tag::listener-config-netw-iface[]
            thisConfig.setNetworkInterface("10.1.1.10") // <.>

            // end::listener-config-netw-iface[]
            // tag::listener-config-delta-sync[]
            thisConfig.setEnableDeltaSync(false) // <.>

            // end::listener-config-delta-sync[]
            // tag::listener-config-tls-full[]
            // Configure server security
            // tag::listener-config-tls-enable[]
            thisConfig.setDisableTls(false) // <.>

            // end::listener-config-tls-enable[]
            // tag::listener-config-tls-id-anon[]
            // Use an Anonymous Self-Signed Cert
            thisConfig.setTlsIdentity(null) // <.>

            // end::listener-config-tls-id-anon[]

            // tag::listener-config-client-auth-pwd[]
            // Configure Client Security using an Authenticator
            // For example, Basic Authentication <.>
            thisConfig.setAuthenticator(
                ListenerPasswordAuthenticator { validUser, validPassword ->
                    username.equals(validUser) &&
                            Arrays.equals(password, validPassword)
                }
            )

            // end::listener-config-client-auth-pwd[]
            // tag::listener-start[]
            // Initialize the listener
            val thisListener = URLEndpointListener(thisConfig) // <.>

            // Start the listener
            thisListener.start() // <.>

            // end::listener-start[]
            // end::listener-initialize[]
        }

        fun ibListenerGetNetworkInterfaces() {
            // tag::listener-get-network-interfaces[]
            val thisConfig =
                URLEndpointListenerConfiguration(database)
            val thisListener = URLEndpointListener(thisConfig)
            thisListener.start()
            Log.i(
                TAG,
                "URLS are " + thisListener.getUrls()
            )

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
            thisConfig.setDisableTls(true) // <.>

            // end::listener-config-tls-disable[]
        }

        fun ibListenerConfigTlsIdFull() {
            // tag::listener-config-tls-id-full[]
            // tag::listener-config-tls-id-caCert[]
            // Use CA Cert
            // Import a key pair into secure storage
            // Create a TLSIdentity from the imported key-pair
            val thisKeyPair: InputStream = FileInputStream()
            thisKeyPair.javaClass.getResourceAsStream("serverkeypair.p12") // <.>
            val thisIdentity: TLSIdentity = importIdentity(
                EXTERNAL_KEY_STORE_TYPE,  // KeyStore type, eg: "PKCS12"
                thisKeyPair,  // An InputStream from the keystore
                password,  // The keystore password
                EXTERNAL_KEY_ALIAS,  // The alias to be used (in external keystore)
                null,  // The key password
                "test-alias" // The alias for the imported key
            )

            // end::listener-config-tls-id-caCert[]

            // tag::listener-config-tls-id-set[]
            // Set the TLS Identity
            thisConfig.setTlsIdentity(thisIdentity) // <.>

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
            val validId: TLSIdentity =
                TLSIdentity.getIdentity("Our Corporate Id")
                    ?: throw IllegalStateException("Cannot find corporate id") // get the identity <.>
            thisConfig.setTlsIdentity(validId)
            thisConfig.setAuthenticator(
                ListenerCertificateAuthenticator(validId.getCerts())
            ) // <.>
            // accept only clients signed by the corp cert
            val thisListener = URLEndpointListener(thisConfig)

            // end::listener-config-client-auth-root[]
// end::listener-config-client-root-ca[]
        }

        fun ibListenerConfigTlsDisable() {

            // tag::listener-config-tls-disable[]
            thisConfig.disableTLS(true)

            // end::listener-config-tls-disable[]
        }

        fun ibListenerStatusCheck() {
            // tag::listener-status-check[]
            val connectionCount: Int = thisListener.getStatus().getConnectionCount() // <.>
            val activeConnectionCount: Int =
                thisListener.getStatus().getActiveConnectionCount() // <.>

            // end::listener-status-check[]
        }

        fun ibListenerStop() {

            // tag::listener-stop[]
            thisListener.stop()

            // end::listener-stop[]
        }

        // ACTIVE PEER STUFF
        // Replication code
        @Throws(CouchbaseLiteException::class, URISyntaxException::class)
        fun testActPeerSync() {
            // tag::p2p-act-rep-func[]
            // tag::p2p-act-rep-initialize[]
            // initialize the replicator configuration
            val thisConfig = ReplicatorConfiguration(
                thisDB,
                URLEndpoint(URI("wss://listener.com:8954"))
            ) // <.>

            // end::p2p-act-rep-initialize[]
            // tag::p2p-act-rep-config-type[]
            // Set replicator type
            thisConfig.replicatorType = ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL

            // end::p2p-act-rep-config-type[]
            // tag::p2p-act-rep-config-cont[]
            // Configure Sync Mode
            thisConfig.isContinuous = false // default value

            // end::p2p-act-rep-config-cont[]

            // tag::autopurge-override[]
            // set auto-purge behavior
            // (here we override default)
            thisConfig.isAutoPurgeEnabled = false // <.>

            // end::autopurge-override[]


            // tag::p2p-act-rep-config-self-cert[]
            // Configure Server Authentication --
            // only accept self-signed certs
            thisConfig.isAcceptOnlySelfSignedServerCertificate = true // <.>

            // end::p2p-act-rep-config-self-cert[]
            // tag::p2p-act-rep-auth[]
            // Configure the credentials the
            // client will provide if prompted
            val thisAuth: BasicAuthenticator // <.>
            thisAuth = BasicAuthenticator("Our Username", "Our PasswordValue")
            thisConfig.setAuthenticator(thisAuth)

            // end::p2p-act-rep-auth[]
            // tag::p2p-act-rep-config-conflict[]
            /* Optionally set custom conflict resolver call back */thisConfig.setConflictResolver() // <.>

            // end::p2p-act-rep-config-conflict[]
            // tag::p2p-act-rep-start-full[]
            // Create replicator
            // Consider holding a reference somewhere
            // to prevent the Replicator from being GCed
            val thisReplicator = Replicator(thisConfig) // <.>

            // tag::p2p-act-rep-add-change-listener[]
            // tag::p2p-act-rep-add-change-listener-label[]
            // Optionally add a change listener <.>
            // end::p2p-act-rep-add-change-listener-label[]
            val thisListener: ListenerToken = addChangeListener { change ->
                val err: CouchbaseLiteException = change.getStatus().getError()
                if (err != null) {
                    Log.i(
                        TAG,
                        "Error code ::  " + err.code,
                        e
                    )
                }
            }

            // end::p2p-act-rep-add-change-listener[]
            // tag::p2p-act-rep-start[]
            // Start replicator
            thisReplicator.start(false) // <.>

            // end::p2p-act-rep-start[]
            // end::p2p-act-rep-start-full[]
            // end::p2p-act-rep-func[]         ***** End p2p-act-rep-func
        }

        fun ibReplicatorConfig() {
            // BEGIN additional snippets
            // tag::p2p-act-rep-config-tls-full[]
            // tag::p2p-act-rep-config-cacert[]
            // Configure Server Security
            // -- only accept CA attested certs
            thisConfig.isAcceptOnlySelfSignedServerCertificate = false // <.>

            // end::p2p-act-rep-config-cacert[]
            // tag::p2p-act-rep-config-pinnedcert[]

            // Return the remote pinned cert (the listener's cert)
            val returnedCert: Byte =
                ByteArray(thisConfig.getPinnedCertificate()) // Get listener cert if pinned
            // end::p2p-act-rep-config-pinnedcert[]

            // end::p2p-act-rep-config-tls-full[]
            // tag::p2p-tlsid-tlsidentity-with-label[]
            // ... other replicator configuration
            // Provide a client certificate to the server for authentication
            val thisClientId: TLSIdentity = TLSIdentity.getIdentity("clientId")
                ?: throw IllegalStateException("Cannot find client id") // <.>
            thisConfig.setAuthenticator(ClientCertificateAuthenticator(thisClientId)) // <.>
            // ... other replicator configuration
            val thisReplicator = Replicator(thisConfig)

            // end::p2p-tlsid-tlsidentity-with-label[]
            // tag::p2p-act-rep-config-cacert-pinned[]

            // Use the pinned certificate from the byte array (cert)
            thisConfig.pinnedServerCertificate = cert.getEncoded() // <.>
            // end::p2p-act-rep-config-cacert-pinned[]
        }

        fun ibP2pReplicatorStatus() {
            // tag::p2p-act-rep-status[]
            Log.i(
                TAG, "The Replicator is currently " +
                        thisReplicator.getStatus().getActivityLevel()
            )
            Log.i(
                TAG,
                "The Replicator has processed $t"
            )
            if (thisReplicator.getStatus().getActivityLevel() ===
                Replicator.ActivityLevel.BUSY
            ) {
                Log.i(
                    TAG,
                    "Replication Processing"
                )
                Log.i(
                    TAG, "It has completed " +
                            thisReplicator.getStatus().getProgess().getTotal().toString() +
                            " changes"
                )
            }
            // end::p2p-act-rep-status[]
        }

        fun ibP2pReplicatorStop() {
            // tag::p2p-act-rep-stop[]
            // Stop replication.
            thisReplicator.stop() // <.>
            // end::p2p-act-rep-stop[]
        }

        fun ibP2pListener() {
            CouchbaseLite.init(context)
            val thisDB = Database("passivepeerdb") // <.>
            // Initialize the listener config
            val thisConfig =
                URLEndpointListenerConfiguration(database)
            thisConfig.setPort(55990) /* <.>  Optional; defaults to auto */
            thisConfig.setDisableTls(false) /* <.>  Optional; defaults to false */
            thisConfig.setEnableDeltaSync(true) /* <.> Optional; defaults to false */

            // Configure the client authenticator (if using basic auth)
            val auth = ListenerPasswordAuthenticator(
                "username", "password"
            ) // <.>
            thisConfig.setAuthenticator(auth) // <.>

            // Initialize the listener
            val listener = URLEndpointListener(thisConfig) // <.>

            // Start the listener
            listener.start() // <.>


            // tag::createTlsIdentity[]

//        Map<String, String> X509_ATTRIBUTES = mapOf(
//                TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
//                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
//                TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
//                TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
//        );
            val thisIdentity: TLSIdentity = createIdentity(true, X509_ATTRIBUTES, null, "test-alias")

            // end::createTlsIdentity[]

            // tag::p2p-tlsid-store-in-keychain[]
            // end::p2p-tlsid-store-in-keychain[]


            // tag::deleteTlsIdentity[]
            // tag::p2p-tlsid-delete-id-from-keychain[]
            val thisAlias = "alias-to-delete"
            val thisKeyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore")
            thisKeyStore.load(null)
            thisKeyStore.deleteEntry(thisAlias)

            // end::p2p-tlsid-delete-id-from-keychain[]
            // end::deleteTlsIdentity[]

            // tag::retrieveTlsIdentity[]
            // OPTIONALLY:: Retrieve a stored TLS identity using its alias/label
            val thisIdentity: TLSIdentity = getIdentity("couchbase-docs-cert")
            // end::retrieveTlsIdentity[]
        }

        // tag::sgw-repl-pull[]
        fun ibRplicatorPull() {
            var database: Database
            var replicator: Replicator // <.>
            var uri: URI? = null
            try {
                uri = URI("wss://10.0.2.2:4984/db") // <.>
            } catch (e: URISyntaxException) {
                e.printStackTrace()
            }
            val endpoint: Endpoint = URLEndpoint(uri)
            val config = ReplicatorConfiguration(database, endpoint)
            config.replicatorType = ReplicatorConfiguration.ReplicatorType.PULL
            this.replicator = Replicator(config)
            this.replicator.start()
        }

        // end::sgw-repl-pull[]
        // tag::sgw-act-rep-initialize[]
        // initialize the replicator configuration
        val thisConfig: ReplicatorConfiguration = ReplicatorConfiguration(
            thisDB,
            URLEndpoint(URI("wss://10.0.2.2:8954/travel-sample"))
        ) // <.> // end::sgw-act-rep-initialize[]

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

        fun testQuerySyntaxAll() {

            // tag::query-syntax-all[]
//        try {
//            this_Db = new Database("hotels");
//        } catch (CouchbaseLiteException e) {
//            e.printStackTrace();
//        }
            val db = openOrCreateDatabaseForUser(currentUser)
            val listQuery: Query = QueryBuilder.select(SelectResult.all())
                .from(DataSource.database(db!!))
            // end::query-syntax-all[]

            // tag::query-access-all[]
            val hotels: HashMap<String, Hotel> = HashMap<String, Hotel>()
            try {
                for (result in listQuery.execute().allResults()) {
                    // get the k-v pairs from the 'hotel' key's value into a dictionary
                    val thisDocsProps = result.getDictionary(0) // <.>
                    val thisDocsId = thisDocsProps!!.getString("id")
                    val thisDocsName = thisDocsProps.getString("name")
                    val thisDocsType = thisDocsProps.getString("type")
                    val thisDocsCity = thisDocsProps.getString("city")

                    // Alternatively, access results value dictionary directly
                    val hotel = Hotel()
                    hotel.id = result.getDictionary(0)!!.getString("id").toString() // <.>
                    hotel.type = result.getDictionary(0)!!.getString("type").toString()
                    hotel.name = result.getDictionary(0)!!.getString("name").toString()
                    hotel.city = result.getDictionary(0)!!.getString("city").toString()
                    hotel.country = result.getDictionary(0)!!.getString("country").toString()
                    hotel.description = result.getDictionary(0)!!.getString("description").toString()
                    hotels[hotel.id] = hotel
                }
            } catch (e: CouchbaseLiteException) {
                e.printStackTrace()
            }

            // end::query-access-all[]
        }

        @Throws(CouchbaseLiteException::class, JSONException::class)
        fun testQuerySyntaxJson() {
            val db = openOrCreateDatabaseForUser(currentUser)
            // tag::query-syntax-json[]
            // Example assumes Hotel class object defined elsewhere
//        Database db = null;
//        try {
//                db = new Database(dbName);
//        } catch (CouchbaseLiteException e) {
//            e.printStackTrace();
//        }

            // Build the query
            val listQuery: Query = QueryBuilder.select(SelectResult.all())
                .from(DataSource.database(db!!))

            // end::query-syntax-json[]

            // tag::query-access-json[]
            // Uses Jackson JSON processor
            val mapper = ObjectMapper()
            val hotels: ArrayList<Hotel> = ArrayList<Hotel>()

            for (result in listQuery.execute()) {

                // Get result as JSON string
                val thisJsonString1: String = result.toJSON() // <.>

                // Get Hashmap from JSON string
                val dictFromJSONstring =
                    mapper.readValue(thisJsonString, HashMap::class.java) // <.>

                // Use created hashmap
                val hotelId = dictFromJSONstring["id"].toString() //
                val hotelType = dictFromJSONstring["type"].toString()
                val hotelname = dictFromJSONstring["name"].toString()


                // Get custom object from JSON strin
                val thisHotel =
                    mapper.readValue(thisJsonString, Hotel::class.java) // <.>
                hotels.add(thisHotel)

            }
            // end::query-access-json[]
        }
/* end func testQuerySyntaxJson */
