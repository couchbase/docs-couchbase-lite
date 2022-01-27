

// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/BlobExamples.java 
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
package com.couchbase.code_snippets;

import java.util.Map;

import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;


public class BlobExamples {

    // Example 2: Using Blobs
    public void example2(final Database db) throws CouchbaseLiteException {
        final Document doc = db.getDocument("1000");
        if (doc == null) { return; }

        // Create a blob from an asset
        final Blob blob = new Blob(
            "image/png",
            Thread.currentThread().getContextClassLoader().getResourceAsStream("couchbaseimage.png"));

        // This will fail:
        // IllegalStateException("A Blob may be encoded as JSON only after it has been saved in a database")
        blob.toJSON();

        // Save the blob as part of a document
        final MutableDocument mDoc = doc.toMutable();
        mDoc.setBlob("avatar", blob);
        db.save(mDoc);

        // Experts only!!!
        db.saveBlob(blob);

        // Retrieve saved blob
        final Document sameDoc = db.getDocument("1000");
        if (sameDoc == null) { return; }

        final Blob sameBlob = sameDoc.getBlob("avatar");
        if (sameBlob == null) { return; }

        // Get as JSON again
        final String blobAsJSONString = sameBlob.toJSON();

        // reconstitute
        final Map<String, Object> blobAsMap = new MutableDictionary().setJSON(blobAsJSONString).toMap();

        // show the contents of the reconstituted blob
        for (Map.Entry<String, Object> entry: blobAsMap.entrySet()) {
            System.out.println("Data: " + entry.getKey() + " -> " + entry.getValue());
        }

        // verify that the reconstituted thing is still blob
        if (Blob.isBlob(blobAsMap)) { System.out.println(blobAsJSONString); }
    }
}



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/BlobExamples.java 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/p2psync-websocket.java 
// subsumed-p2p
// PASSIVE PEER STUFF
// Stuff I adapted
//



// tag::listener-simple[]
final URLEndpointListenerConfiguration thisConfig =
  new URLEndpointListenerConfiguration(thisDB); // <.>

thisConfig.setAuthenticator(
  new ListenerPasswordAuthenticator(
    (username, password) ->
      username.equals("valid.User") &&
      Arrays.equals(password, valid.password.string)
    )
  ); // <.>

final URLEndpointListener thisListener =
  new URLEndpointListener(thisConfig); // <.>

thisListener.start(); // <.>

// end::listener-simple[]



// tag::replicator-simple[]
final ReplicatorConfiguration thisConfig =
  new ReplicatorConfiguration(
    thisDB,
    URLEndpoint(URI("wss://listener.com:8954"))); // <.> <.>

thisConfig.setAcceptOnlySelfSignedServerCertificate(true); // <.>

final BasicAuthenticator thisAuth
= new BasicAuthenticator(
    "valid.user",
    "valid.password.string"));
thisConfig.setAuthenticator(thisAuth) // <.>

this.replicator = new Replicator(config); // <.>
this.replicator.start(); // <.>

// end::replicator-simple[]




import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class cMyPassListener {
    // tag::listener-initialize[]
    // tag::listener-config-db[]
    // Initialize the listener config
    final URLEndpointListenerConfiguration thisConfig
       = new URLEndpointListenerConfiguration(thisDB); // <.>

    // end::listener-config-db[]
    // tag::listener-config-port[]
    thisConfig.setPort(55990); //<.>

    // end::listener-config-port[]
    // tag::listener-config-netw-iface[]
    thisConfig.setNetworkInterface("10.1.1.10"); // <.>

    // end::listener-config-netw-iface[]
    // tag::listener-config-delta-sync[]
    thisConfig.setEnableDeltaSync(false); // <.>

    // end::listener-config-delta-sync[]
    // Configure server security
    // tag::listener-config-tls-enable[]
    thisConfig.setDisableTLS(false); // <.>

    // end::listener-config-tls-enable[]
    // tag::listener-config-tls-id-anon[]
    // Use an Anonymous Self-Signed Cert
    thisConfig.setTlsIdentity(null); // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-client-auth-pwd[]
    // Configure Client Security using an Authenticator
    // For example, Basic Authentication <.>
    thisConfig.setAuthenticator(new ListenerPasswordAuthenticator(
      (validUser, validPassword) ->
        username.equals(validUser) &&
        Arrays.equals(password, validPassword)));

    // end::listener-config-client-auth-pwd[]

    // tag::listener-start[]
    // Initialize the listener
    final URLEndpointListener thisListener
      = new URLEndpointListener(thisConfig); // <.>

    // Start the listener
    thisListener.start(); // <.>

    // end::listener-start[]
    // end::listener-initialize[]
  }

// ADDITIONAL SNIPPETS

// tag::listener-get-network-interfaces[]
// . . . code snippet to be provided

// end::listener-get-network-interfaces[]

// tag::listener-get-url-list[]
final URLEndpointListenerConfigurationthisConfig =
  URLEndpointListenerConfiguration(database: self.oDB)
final URLEndpointListener thisListener
  = new URLEndpointListener(thisConfig);
thisListener.start()
Log.i(TAG, "URLS are " + thisListener.getUrls();

// end::listener-get-url-list[]


    // tag::listener-local-db[]
    // . . . preceding application logic . . .
    CouchbaseLite.init(context); <.>
    Database thisDB = new Database("passivepeerdb");

    // end::listener-local-db[]

    // tag::listener-config-tls-full[]
    // tag::listener-config-tls-disable[]
    thisConfig.setDisableTLS(true); // <.>

    // end::listener-config-tls-disable[]
    // tag::listener-config-tls-id-full[]
    // tag::listener-config-tls-id-caCert[]
    // Use CA Cert
    // Import a key pair into secure storage
    // Create a TLSIdentity from the imported key-pair
    InputStream thisKeyPair = new FileInputStream();
    thisKeyPair.getClass().getResourceAsStream("serverkeypair.p12"); // <.>

    TLSIdentity thisIdentity = new TLSIdentity.importIdentity(
      EXTERNAL_KEY_STORE_TYPE,  // KeyStore type, eg: "PKCS12"
      thisKeyPair,              // An InputStream from the keystore
      password,                 // The keystore password
      EXTERNAL_KEY_ALIAS,       // The alias to be used (in external keystore)
      null,                     // The key password
      "test-alias"              // The alias for the imported key
    ); // <.>

    // end::listener-config-tls-id-caCert[]
    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    // Create a TLSIdentity for the server using convenience API.
    // System generates self-signed cert
    private static final Map<String, String> CERT_ATTRIBUTES; //<.>
    static {
      final Map<String, String> thisMap = new HashMap<>();
      m.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "Couchbase Demo");
      m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
      m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
      m.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "noreply@couchbase.com");
      CERT_ATTRIBUTES = Collections.unmodifiableMap(thisMap);
    }

    // Store the TLS identity in secure storage
    // under the label 'couchbase-docs-cert'
    TLSIdentity thisIdentity =
      new TLSIdentity.createIdentity(
        true,
        CERT_ATTRIBUTES,
        null,
        "couchbase-docs-cert"); <.>

    // end::listener-config-tls-id-SelfSigned[]

    // tag::listener-config-tls-id-set[]
    // Set the TLS Identity
    thisConfig.setTlsIdentity(thisIdentity); // <.>

    // end::listener-config-tls-id-set[]
    // end::listener-config-tls-id-full[]
    // tag::listener-config-client-auth-root[]
    // Configure the client authenticator
    // to validate using ROOT CA
    TLSIdentity thisServerID = getIdentity(“server”) // <.>
    TLSIdentity thisClientID = getIdentity(“authorizedClient”)

    thisConfig.setTlsIdentity = thisServerID;

    thisConfig.setAuthenticator(
      new ListenerCertificateAuthenticator(thisClientID.getCerts())); // <.> <.>

    URLEndpointListener thisListener = new URLEndpointListener(thisConfig) //

    // end::listener-config-client-auth-root[]
    // tag::listener-config-client-auth-lambda[]
    // Configure authentication using application logic
    final TLSIdentity thisCorpId = TLSIdentity.getIdentity("OurCorp"); // <.>
    if (thisCorpId == null) {
      throw new IllegalStateException("Cannot find corporate id"); }
    thisConfig.setTlsIdentity(thisCorpId);
    thisConfig.setAuthenticator(
      new ListenerCertificateAuthenticator(
        (thisCorpId.getCerts()) -> {
        // use supplied logic that resolves to boolean
        // true=valid, false=invalid
        }
      ); // <.> <.>
    final ULEndpointListener thisListener =
      new URLEndpointListener(thisConfig);

    // end::listener-config-client-auth-lambda[]






  // Quick sync

  // tag::quick-sync[]
    final URLEndpointListenerConfiguration thisConfig
       = new URLEndpointListenerConfiguration(thisDB); // <.>

    thisConfig.setAuthenticator(new ListenerPasswordAuthenticator(
      (validUser, validPassword) ->
        username.equals(validUser) &&
        Arrays.equals(password, validPassword)));

    final URLEndpointListener thisListener
      = new URLEndpointListener(thisConfig); // <.>
    thisListener.start();
    // end::quick-sync[]
  }


  // tag::listener-config-tls-disable[]
  thisConfig.disableTLS(true);

  // end::listener-config-tls-disable[]

  // tag::listener-config-tls-id-nil-2[]

  // Use “anonymous” cert. These are self signed certs created by the system
  thisConfig.setTlsIdentity(nil);

  // end::listener-config-tls-id-nil-2[]

  // tag::old-listener-config-tls-id-caCert[]
  // Use CA Cert
  // Import a key pair into secure storage
  // Create a TLSIdentity from the imported key-pair
  InputStream thisKeyPair = new FileInputStream();

  thisKeyPair.getClass().getResourceAsStream("serverkeypair.p12");

  TLSIdentity thisIdentity = new TLSIdentity.importIdentity(
    EXTERNAL_KEY_STORE_TYPE,  // KeyStore type, eg: "PKCS12"
    thisKeyPair,              // An InputStream from the keystore
    password,                 // The keystore password
    EXTERNAL_KEY_ALIAS,       // The alias to be used (in external keystore)
    null,                     // The key password
    "test-alias"              // The alias for the imported key
  );

  // end::old-listener-config-tls-id-caCert[]




  // tag::old-listener-config-delta-sync[]
  thisConfig.enableDeltaSync(true;)

  // end::old-listener-config-delta-sync[]


  // tag::listener-status-check[]
  int connectionCount =
    thisListener.getStatus().getConnectionCount(); // <.>

  int activeConnectionCount =
    thisListener.getStatus().getActiveConnectionCount();  // <.>

    // end::listener-status-check[]


  // tag::listener-stop[]
  thisListener.stop();

  // end::listener-stop[]


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


  // tag::old-listener-config-client-root-ca[]
  // thisClientID.certs is a list containing a client cert to accept
  // and any other certs needed to complete a chain between the client cert
  // and a CA
  TlsIdentity thisServerID = getIdentity(“server”)
  TlsIdentity thisClientID = getIdentity(“authorizedClient”)

  thisConfig.setTlsIdentity = thisServerID;
  thisConfig.setAuthenticator(
    new ListenerCertificateAuthenticator(thisClientID.getCerts()));

  URLEndpointListener thisListener = new URLEndpointListener(thisConfig)

  // end::old-listener-config-client-root-ca[]


  // prev content of listener-config-client-auth-self-signed (for ios)
  thisConfig.authenticator =
    ListenerCertificateAuthenticator.init {
      (cert) -> Bool in
      var cert:SecCertificate
      var certCommonName:CFString?
      let status
        = SecCertificateCopyCommonName(cert, &certCommonName)
      if (self._allowlistedUsers.contains(
        ["name": certCommonName! as String]))
        {
          return true
        }
      return false
    }
  // tag::old-listener-config-client-auth-self-signed[]
  // Work in progress. Code snippet to be provided.

  // end::old-listener-config-client-auth-self-signed[]

// tag::p2p-ws-api-urlendpointlistener[]
public class URLEndpointListener {
    // Properties // <1>
    public let config: URLEndpointListenerConfiguration
    public let port UInt16?
    public let tlsIdentity: TLSIdentity?
    public let urls: Array<URL>?
    public let status: ConnectionStatus?
    // Constructors <2>
    public init(config: URLEndpointListenerConfiguration)
    // Methods <3>
    public func start() throws
    public func stop()
}
// end::p2p-ws-api-urlendpointlistener[]


// tag::p2p-ws-api-urlendpointlistener-constructor[]
let config = URLEndpointListenerConfiguration.init(database: self.oDB)
thisConfig.port = tls ? wssPort : wsPort
thisConfig.disableTLS = !tls
thisConfig.authenticator = auth
self.listener = URLEndpointListener.init(config: config) // <1>
// end::p2p-ws-api-urlendpointlistener-constructor[]


// ACTIVE PEER STUFF
// Replication code
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
package com.couchbase.code_snippets;

import android.content.Context;
import android.support.annotation.NonNull;
import android.util.Log;
import android.widget.Toast;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import com.couchbase.lite.ArrayFunction;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Conflict;
import com.couchbase.lite.ConflictResolver;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.DatabaseEndpoint;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.DocumentFlag;
import com.couchbase.lite.EncryptionKey;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.Expression;
import com.couchbase.lite.FullTextExpression;
import com.couchbase.lite.FullTextIndexItem;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Join;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogFileConfiguration;
import com.couchbase.lite.LogLevel;
import com.couchbase.lite.Logger;
import com.couchbase.lite.Message;
import com.couchbase.lite.MessageEndpoint;
import com.couchbase.lite.MessageEndpointConnection;
import com.couchbase.lite.MessageEndpointDelegate;
import com.couchbase.lite.MessageEndpointListener;
import com.couchbase.lite.MessageEndpointListenerConfiguration;
import com.couchbase.lite.MessagingCloseCompletion;
import com.couchbase.lite.MessagingCompletion;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.PredictionFunction;
import com.couchbase.lite.PredictiveIndex;
import com.couchbase.lite.PredictiveModel;
import com.couchbase.lite.ProtocolType;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.ReplicatedDocument;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorConnection;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.SessionAuthenticator;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.ValueIndex;
import com.couchbase.lite.ValueIndexItem;
import com.couchbase.lite.Where;

public class Examples {
  private static final String TAG = "EXAMPLE ACTIVE PEER";
  private static final String thisDBNAME = "local-database";
  private final Context context;
  // private Database database;
  // private Replicator replicator;

  public Examples(Context context) { this.context = context; }

  String user = "syncuser";
  String password = "sync9455";
  SecCertificate cert=null;
  String passivePeerEndpoint = "10.1.1.12:8920";
  String passivePeerPort = "8920";
  String passiveDbName = "userdb";
  Database thisDB;
  Replicator thisReplicator;
  ListenerToken replicatorListener;

  //@Test
  public void testActPeerSync() throws CouchbaseLiteException, URISyntaxException {
    // tag::p2p-act-rep-func[]
        // tag::p2p-act-rep-initialize[]
        // initialize the replicator configuration
        final ReplicatorConfiguration thisConfig
           = new ReplicatorConfiguration(
              thisDB,
              URLEndpoint(URI("wss://listener.com:8954"))); // <.> <.>

        // end::p2p-act-rep-initialize[]
        // tag::p2p-act-rep-config-type[]
        // Set replicator type
        thisConfig.setReplicatorType(
          ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);

        // end::p2p-act-rep-config-type[]
        // tag::autopurge-override[]
        // set auto-purge behavior (here we override default)
        thisConfig.setAutoPurgeEnabled(false); // <.>

        // end::autopurge-override[]
        // tag::p2p-act-rep-config-cont[]
        // Configure Sync Mode
        thisConfig.setContinuous(false); // default value

        // end::p2p-act-rep-config-cont[]
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Security --
        // only accept self-signed certs
        thisConfig.setAcceptOnlySelfSignedServerCertificate(true); // <.>

        // end::p2p-act-rep-config-self-cert[]
        // Configure Client Security //
        // tag::p2p-act-rep-auth[]
        // Configure basic auth using user credentials
        final BasicAuthenticator thisAuth
          = new BasicAuthenticator(
              "Our Username",
              "Our PasswordValue")); // <.>

        thisConfig.setAuthenticator(thisAuth)

        // end::p2p-act-rep-auth[]
        // tag::p2p-act-rep-config-conflict[]
        /* Optionally set custom conflict resolver call back */
        thisConfig.setConflictResolver( /* user supplied code */ ); // <.>

        // end::p2p-act-rep-config-conflict[]
        // tag::p2p-act-rep-start-full[]
        // Create replicator
        final Replicator thisReplicator = new Replicator(thisConfig); // <.>

        // tag::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-add-change-listener-label[]
        // Optionally add a change listener
        // end::p2p-act-rep-add-change-listener-label[]
        ListenerToken thisListener
          = new thisReplicator.addChangeListener(change -> {
            if (change.getStatus().getError() != null) {
              Log.i(TAG, "Error code ::  " +
                change.getStatus().getError().getCode());
            }
          }); // <.>
        // end::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-start[]
        // Start replicator
        thisReplicator.start(false); // <.>

        // end::p2p-act-rep-start[]
        // end::p2p-act-rep-start-full[]
        // end::p2p-act-rep-func[]         ***** End p2p-act-rep-func
      }
    }



// BEGIN additoinal active snippet
    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security
    // -- only accept CA Certs
    thisConfig.setAcceptOnlySelfSignedServerCertificate(false); // <.>

    // end::p2p-act-rep-config-cacert[]    // tag::p2p-act-rep-config-pinnedcert[]
    // Return the remote pinned cert (the listener's cert)
    byte returnedCert
    = new byte(thisConfig.getPinnedCertificate()); // Get listener cert if pinned

    // end::p2p-act-rep-config-pinnedcert[]
    // end::p2p-act-rep-config-tls-full[]
    // tag::p2p-tlsid-tlsidentity-with-label[]
    // ... other replicator configuration
    // Provide a client certificate to the server for authentication
    final TLSIdentity thisClientId =
      TLSIdentity.getIdentity(
        store,     // keystore holding private key and cert chain
        "clientId", // key label/alias
        null        // key password as required
      ); // <.>
    if (thisClientId == null) { throw new IllegalStateException("Client id not found"); } // Error path

    thisConfig.setAuthenticator(
      new ClientCertificateAuthenticator(thisClientId)); // <.>

    // ... other replicator configuration
    // final thisReplicator(thisConfig);

    // end::p2p-tlsid-tlsidentity-with-label[]
    // tag::p2p-act-rep-config-cacert-pinned[]
    // Use the pinned certificate from the byte array (cert)
    thisConfig.setPinnedServerCertificate(cert.getEncoded()); // <.>

    // end::p2p-act-rep-config-cacert-pinned[]






// tag::p2p-act-rep-status[]

    Log.i(TAG, "The Replicator is currently " +
      thisReplicator.getStatus().getActivityLevel());

    Log.i(TAG, "The Replicator has processed " + t);

    if (thisReplicator.getStatus().getActivityLevel() ==
      Replicator.ActivityLevel.BUSY) {
        Log.i(TAG, "Replication Processing");
        Log.i(TAG, "It has completed " +
          thisReplicator.getStatus().getProgess().getTotal() +
          " changes");
      }
      // end::p2p-act-rep-status[]

      // tag::p2p-act-rep-stop[]
      // Stop replication.
      thisReplicator.stop(); // <.>
      // end::p2p-act-rep-stop[]


  }

{
  CouchbaseLite.init(context);
  Database thisDB = new Database("passivepeerdb");  // <.>
  // Initialize the listener config
  final URLEndpointListenerConfiguration thisConfig = new URLEndpointListenerConfiguration(database);
  thisConfig.setPort(55990)           // <.> Optional; defaults to auto
  thisConfig.setDisableTls(false)     // <.> Optional; defaults to false
  thisConfig.setEnableDeltaSync(true) // <.> Optional; Defaults to false

  // Configure the client authenticator (if using basic auth)
  ListenerPasswordAuthenticator auth = new ListenerPasswordAuthenticator { "username", "password"}; // <.>
  thisConfig.setAuthenticator(auth); // <.>

  // Initialize the listener
  final URLEndpointListener listener = new URLEndpointListener( thisConfig ); // <.>

  // Start the listener
  listener.start(); // <.>
    }


// tag::createTlsIdentity[]

Map<String, String> X509_ATTRIBUTES = mapOf(
           TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME to "Couchbase Demo",
           TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION to "Couchbase",
           TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT to "Mobile",
           TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS to "noreply@couchbase.com"
       )

TLSIdentity thisIdentity = new TLSIdentity.createIdentity(true, X509_ATTRIBUTES, null, "test-alias");

// end::createTlsIdentity[]

// tag::p2p-tlsid-store-in-keychain[]
// end::p2p-tlsid-store-in-keychain[]


// tag::deleteTlsIdentity[]
// tag::p2p-tlsid-delete-id-from-keychain[]
String thisAlias = "alias-to-delete";
final KeyStore thisKeyStore
  =  KeyStore.getInstance("AndroidKeyStore");
thisKeyStore.load(null);
thisKeyStore.deleteEntry(thisAlias);

// end::p2p-tlsid-delete-id-from-keychain[]
// end::deleteTlsIdentity[]

// tag::retrieveTlsIdentity[]
// OPTIONALLY:: Retrieve a stored TLS identity using its alias/label

TLSIdentity thisIdentity =
  new TLSIdentity.getIdentity("couchbase-docs-cert")
// end::retrieveTlsIdentity[]


    // Configure the client authenticator (if using Basic Authentication)
    // String validUser = new String("validUsername"); // an example username
    // String validPassword = new String("validPasswordValue"); // an example password

    // ListenerPasswordAuthenticator thisAuth = new ListenerPasswordAuthenticator( // <.>
    //   validUser, validPassword -> validUser == "validUsername" && validPassword == "validPasswordValue" );

    // if (thisAuth) {
    //   thisConfig.setAuthenticator(auth);
    // }
    // else {
    //   // . . . authentication failed take appropriate exception action
    //   return
    // };




    // tag::old-p2p-act-rep-add-change-listener[]
    ListenerToken thisListener
      = new thisReplicator.addChangeListener(change -> { // <.>
      if (change.getStatus().getError() != null) {
        Log.i(TAG, "Error code ::  " +
          change.getStatus().getError().getCode());
        }
      });

    // end::old-p2p-act-rep-add-change-listener[]



// g u b b i n s
// tag::duff-p2p-tlsid-tlsidentity-with-label[]


    // Configure TLS Cert CA auth using key-stored cert id alias 'doc-sync-server'

    // TLSIdentity thisIdentity = new TLSIdentity.getIdentity("doc-sync-server"); // Get existing TLS ID from sec storage

    // ClientCertificateAuthenticator thisAuth = new ClientCertificateAuthenticator(thisIdentity);

    // thisConfig.setAuthenticator(thisAuth);



    // USE KEYCHAIN IDENTITY IF EXISTS
    // Check if Id exists in keychain. If so use that Id

    // STILL NEED TO REFACTOR

    do {
      if let thisIdentity = try TLSIdentity.identity(withLabel: "couchbase-docs-cert") {
          print("An identity with label : couchbase-docs-cert already exists in keychain")
          return thisIdentity
          }
    } catch
    {return nil}
    thisAuthenticator.ClientCertificateAuthenticator(identity: thisIdentity )
    thisConfig.thisAuthenticator

    // end::duff-p2p-tlsid-tlsidentity-with-label[]


// tag::old-deleteTlsIdentity[]

String thisAlias = "alias-to-delete";
KeyStore thisKeystore = KeyStore.getInstance("AndroidKeyStore"); // <.>
thisKeyStore.load(null);
if (thisAlias != null) {
   thisKeystore.deleteEntry(thisAlias);  // <.>
}

// end::old-deleteTlsIdentity[]


// cert auth
let thisRootCertData = SecCertificateCopyData(cert) as Data
let thisRootCert = SecCertificateCreateWithData(kCFAllocatorDefault, thisRootCertData as CFData)!
// Listener:
thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [thisRootCert])

SecCertificate thisCert = new SecCertificate(); // populated as nec.

Data thisRootCertData = new Data(SecCertificateCopyData(thisCert));

let thisRootCert = SecCertificateCreateWithData(kCFAllocatorDefault, thisRootCertData as CFData)!
// Listener:
thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [thisRootCert])
// cert auth


// C A L L O U T S

// tag::p2p-act-rep-config-cacert-pinned-callouts[]
<.> Configure to accept only CA certs
<.> Configure the pinned certificate using data from the byte array `cert`
// end::p2p-act-rep-config-cacert-pinned-callouts[]

// tag::p2p-tlsid-tlsidentity-with-label-callouts[]
<.> Attempt to get the identity from secure storage
<.> Set the authenticator to ClientCertificateAuthenticator and  the configure it to use the retrieved identity

// end::p2p-tlsid-tlsidentity-with-label-callouts[]





    // thisConfig.setAuthenticator(
    // new ListenerCertificateAuthenticator(certs));


        // tag::beta-listener-config-tls-id-caCert[]
    // Use CA Cert
    // Create a TLSIdentity from a key-pair and
    // certificate in Android's canonical keystore
    TLSIdentity thisIdentity = new TLSIdentity.getIdentity("server"); // <.>

    // end::beta-listener-config-tls-id-caCert[]



    / For replications

// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
class MyClass {
  Database database;
  Replicator replicator; // <1>

  void startReplication() {
      URI uri = null;
      try {
          uri = new URI("wss://10.0.2.2:4984/db"); // <2>
      } catch (URISyntaxException e) {
          e.printStackTrace();
      }
      Endpoint endpoint = new URLEndpoint(uri);
      ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
      config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
      this.replicator = new Replicator(config);
      this.replicator.start();
  }

}

// end::sgw-repl-pull[]

// tag::sgw-repl-pull-callouts[]
<.> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<.> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
You should now use `ws:`, or `wss:` for SSL/TLS connections.
In this example the hostname is `10.0.2.2`.

// end::sgw-repl-pull-callouts[]

// tag::sgw-act-rep-initialize[]
// initialize the replicator configuration
final ReplicatorConfiguration thisConfig
    = new ReplicatorConfiguration(
      thisDB,
      URLEndpoint(URI("wss://listener.com:8954/travel-sample"))); // <.>

// end::sgw-act-rep-initialize[]

// END=subsumed-p2p


// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/p2psync-websocket.java 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/Examples.java 
package com.couchbase.examples;

import com.couchbase.lite.*;
import com.example.docsnippet.Datastore;
import com.example.docsnippet.Hotel;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.Map;
import com.couchbase.lite.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

import com.couchbase.lite.Array;
import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;

// tag::getting-started[]
import com.couchbase.lite.*;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class Examples {
}

public class GettingStarted {

private static final String DB_NAME = "getting-started";
/*      Credentials declared this way purely for expediency in this demo - use OAUTH in production code */
private static final String DB_USER = "sync_gateway";
private static final String DB_PASS = "password"; // <3>
//    private static final String SYNC_GATEWAY_URL = "ws://127.0.0.1:4984/db" + DB_NAME;
private static final String SYNC_GATEWAY_URL = "ws://127.0.0.1:4984/getting-started"; // <1>
private static final String DB_PATH = new File("").getAbsolutePath()+"/resources";


public static void main (String [] args) throws CouchbaseLiteException, InterruptedException, URISyntaxException {
    Random RANDOM = new Random();
    int randPtrLang = RANDOM.nextInt(5) ;
    int randPtrType = RANDOM.nextInt(5) ;
    int numRows = 0;

    Double randVn = RANDOM.nextDouble() + 1;

    List<String> listLangs = new ArrayList<String> (Arrays.asList("Java","Swift","C#.Net","Objective-C","C++","Cobol"));
//        List<String> listTypes = new ArrayList<String>();
    List<String> listTypes = new ArrayList<String> (Arrays.asList("SDK","API","Framework","Methodology","Language","IDE"));

    String Prop_Id ="id";
    String Prop_Language = "language";
    String Prop_Type = "type";
    String Prop_Version = "version";
    String searchStringType = "SDK";
    String dirPath = new File("").getAbsolutePath()+"/resources";


    // Initialize Couchbase Lite
    CouchbaseLite.init(); // <2>

    // Get the database (and create it if it doesn’t exist).
    DatabaseConfiguration config = new DatabaseConfiguration();

//    config.setDirectory(
//            (context.getFilesDir().getAbsolutePath()); // <5>

    config.setEncryptionKey(new EncryptionKey(DB_PASS)); // <3>
    Database database = new Database(DB_NAME, config);

    // Create a new document (i.e. a record) in the database.
    MutableDocument mutableDoc = new MutableDocument()
            .setDouble(Prop_Version, randVn)
            .setString(Prop_Type,listTypes.get(randPtrType));

    // Save it to the database.
    database.save(mutableDoc);

    // Update a document.
    mutableDoc = database.getDocument(mutableDoc.getId()).toMutable();
    mutableDoc.setString(Prop_Language, listLangs.get(randPtrLang));
    database.save(mutableDoc);

    Document document = database.getDocument(mutableDoc.getId());
    // Log the document ID (generated by the database) and properties
    System.out.println("Document ID is :: " + document.getId());
    System.out.println("Learning " + document.getString(Prop_Language));

    // Create a query to fetch documents of type SDK.
    System.out.println("== Executing Query 1");
    Query query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property(Prop_Type).equalTo(Expression.string(searchStringType)));
    ResultSet result = query.execute();
    System.out.println(String.format("Query returned %d rows of type %s", result.allResults().size(), searchStringType));

    // Create a query to fetch all documents.
    System.out.println("== Executing Query 2");
    Query queryAll = QueryBuilder.select(SelectResult.expression(Meta.id),
            SelectResult.property(Prop_Language),
            SelectResult.property(Prop_Version),
            SelectResult.property(Prop_Type))
        .from(DataSource.database(database));
        try {
            for (Result thisDoc : queryAll.execute()) {
              numRows++;
              System.out.println(String.format("%d ... Id: %s is learning: %s version: %.2f type is %s",
                  numRows,
                  thisDoc.getString(Prop_Id),
                  thisDoc.getString(Prop_Language),
                  thisDoc.getDouble(Prop_Version),
                  thisDoc.getString(Prop_Type)));
              }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    System.out.println(String.format("Total rows returned by query = %d", numRows));

    Endpoint targetEndpoint = new URLEndpoint(new URI(SYNC_GATEWAY_URL));
    ReplicatorConfiguration replConfig = new ReplicatorConfiguration(database, targetEndpoint);
    replConfig.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);

    // Add authentication.
    replConfig.setAuthenticator(new BasicAuthenticator(DB_USER, DB_PASS));

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
    while (replicator.getStatus().getActivityLevel() != Replicator.ActivityLevel.STOPPED) {
        Thread.sleep(1000);
    }

    System.out.println("Finish!");

    System.exit(0); // <4>
}
// end::getting-started[]



// tag::GsWebApp_GettingStarted[]

//@WebServlet( value = "/GettingStarted")
//public class GettingStartedWebApp extends javax.servlet.http.HttpServlet {
public class GettingStartedWebApp {
    private static final String DB_DIR = "/usr/local/var/tomcat/data"; // <1>
    private static final String DB_NAME = "getting-started";
    /*      Credentials declared this way purely for expediency in this demo - use OAUTH in production code */
    private static final String DB_USER = "sync_gateway";
    private static final String DB_PASS = "password";
    //    private static final String SYNC_GATEWAY_URL = "ws://127.0.0.1:4984/db" + DB_NAME;
    private static final String SYNC_GATEWAY_URL = "ws://127.0.0.1:4984/getting-started"; // <2>
    private static final String NEWLINETAG = "<br />";
    private String MYRESULTS;
    private int NUMROWS;
    private Random RANDOM = new Random();

    protected void doGet(javax.servlet.http.HttpServletRequest request, javax.servlet.http.HttpServletResponse
            response) throws javax.servlet.ServletException, IOException {
        outputMessage("Servlet started :: doGet Invoked");
        doPost(request, response);
    }

    protected void doPost(javax.servlet.http.HttpServletRequest request, javax.servlet.http.HttpServletResponse
            response) throws javax.servlet.ServletException, IOException {
        NUMROWS = 0;
        MYRESULTS = "";
        outputMessage("Servlet started :: doPost Invoked");
        String url = "/showDbItems.jsp";
        try {
            MYRESULTS = testCouchbaseLite();
        } catch (CouchbaseLiteException | URISyntaxException | InterruptedException e) {
            e.printStackTrace();
        } finally {
            outputMessage(String.format("CouchbaseLite Test Ended :: There are %d rows in DB", NUMROWS));
        }
        request.setAttribute("myRowCount", NUMROWS);
        request.setAttribute("myResults", MYRESULTS);
        getServletContext()
                .getRequestDispatcher(url)
                .forward(request, response);
        outputMessage("Servlet Ended :: doPost Exits");
    }

    public String testCouchbaseLite() throws CouchbaseLiteException, URISyntaxException, InterruptedException, ServletException {

        int randPtr = RANDOM.nextInt(5) + 1;
        long syncTotal = 0;
        Double randVn = RANDOM.nextDouble() + 1;
        List<String> listLangs = new ArrayList<String>(Arrays.asList("Java", "Swift", "C#.Net", "Objective-C", "C++", "Cobol"));
        List<String> listTypes = new ArrayList<String>(Arrays.asList("SDK", "API", "Framework", "Methodology", "Language", "IDE"));

        String Prop_Id = "id";
        String Prop_Language = "language";
        String Prop_Type = "type";
        String Prop_Version = "version";
        String searchStringType = "SDK";

        // Get and configure database
        // Note initialisation of CouchbaseLite is done in ServletContextListener
        outputMessage("== Opening DB and doing initial sync");
        Database database = DatabaseManager.manager().getDatabase(DB_NAME,DB_DIR,DB_PASS);

        // Initial DB sync prior to local updates
        syncTotal = DatabaseManager.manager().runOneShotReplication(database, SYNC_GATEWAY_URL, DB_USER, DB_PASS);
        outputMessage(String.format("Inital number of rows synchronised = %d", syncTotal));

        // Create a new document (i.e. a record) in the database.
        outputMessage("== Adding a record");
        MutableDocument mutableDoc = new MutableDocument()
                .setDouble(Prop_Version, randVn)
                .setString(Prop_Type, listTypes.get(RANDOM.nextInt(listTypes.size() - 1)));

        // Save it to the database.
        try {
            database.save(mutableDoc);
        } catch (CouchbaseLiteException e) {
            throw new ServletException("Error saving a document", e);
        }

        // Update a document.
        outputMessage("== Updating added record");
        mutableDoc = database.getDocument(mutableDoc.getId()).toMutable();
        mutableDoc.setString(Prop_Language, listLangs.get(RANDOM.nextInt(listLangs.size() - 1)));
        // Save it to the database.
        try {
            database.save(mutableDoc);
        } catch (CouchbaseLiteException e) {
            throw new ServletException("Error saving a document", e);
        }

        outputMessage("== Retrieving record by id");
        Document newDoc = database.getDocument(mutableDoc.getId());
        // Show the document ID (generated by the database) and properties
        outputMessage("Document ID :: " + newDoc.getId());
        outputMessage("Learning " + newDoc.getString(Prop_Language));

        // Create a query to fetch documents of type SDK.
        outputMessage("== Executing Query 1");
        Query query = QueryBuilder.select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property(Prop_Type).equalTo(Expression.string(searchStringType)));
        try{
            ResultSet result = query.execute();
            outputMessage(String.format("Query returned %d rows of type %s", result.allResults().size(), searchStringType));
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        // Create a query to fetch all documents.
        outputMessage("== Executing Query 2");
        Query queryAll = QueryBuilder.select(SelectResult.expression(Meta.id),
                SelectResult.property(Prop_Language),
                SelectResult.property(Prop_Version),
                SelectResult.property(Prop_Type))
                .from(DataSource.database(database));
        try {
            for (Result thisDoc : queryAll.execute()) {
              NUMROWS++;
                outputMessage(String.format("%d ... Id: %s is learning: %s version: %.2f type is %s",
                  NUMROWS,
                  thisDoc.getString(Prop_Id),
                  thisDoc.getString(Prop_Language),
                  thisDoc.getDouble(Prop_Version),
                  thisDoc.getString(Prop_Type)));
              }
            } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        outputMessage(String.format("Total rows returned by query = %d", NUMROWS));

//      Do final single-shot replication to incorporate changed NumRows
        outputMessage("== Doing final single-shot sync");
        syncTotal = DatabaseManager.manager().runOneShotReplication(database, SYNC_GATEWAY_URL, DB_USER, DB_PASS);
        outputMessage(String.format("Total rows synchronised = %d", syncTotal));
        database.close();
        return MYRESULTS;
    }

    public void outputMessage(String msg) {
        String thisMsg = "Null message";
        if (msg.length() > 0) {
            thisMsg = msg;
        }
        System.out.println(msg);
        MYRESULTS = MYRESULTS + msg + NEWLINETAG;
    }
}
// end::GsWebApp_GettingStarted[]

// tag::GsWebApp_Listener[]
//    import javax.servlet.ServletContextEvent;
//    import javax.servlet.ServletContextListener;
//    import javax.servlet.annotation.WebListener;
//
//    @WebListener
//    public class Application implements ServletContextListener {
public class GsWebApp_Listener {
      @Override
      public void contextInitialized(ServletContextEvent event) {
          DatabaseManager.manager().init();
      }
    }
// end::GsWebApp_Listener[]

// tag::GsWebApp_DbManager[]
//import com.couchbase.lite.*;
//import java.net.URI;
//import java.net.URISyntaxException;

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
    public synchronized Database getDatabase(String parDbname, String parDbDir,  String parDbPass) {
        if (database == null) {
            try {
                DatabaseConfiguration config = new DatabaseConfiguration();
                config.setDirectory(parDbDir); // <2>
                config.setEncryptionKey(new EncryptionKey(parDb_PASS)); // <3>
                database = new Database(parDbname, config);
            }
            catch (CouchbaseLiteException e) {
                throw new IllegalStateException("Cannot create database", e);
            }
        }
        return database;
    }

    public synchronized long runOneShotReplication( Database parDb, String parURL, String parName, String parPassword) throws InterruptedException {
        long syncTotal = 0;
        // Set replicator endpoint
        URI sgURI = null;
        try {
            sgURI = new URI(parURL);
        } catch (URISyntaxException e) {
            e.printStackTrace();
        }
        URLEndpoint targetEndpoint = new URLEndpoint(sgURI);

        // Configure replication
        System.out.println("== Synchronising DB :: Configuring replicator");
        ReplicatorConfiguration replConfig = new ReplicatorConfiguration(parDb, targetEndpoint);

        replConfig.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);
        replConfig.setContinuous(false);    // make this a single-shot replication cf. a continuous replication

        // Add authentication.
//        outputMessage("== Synchronising DB :: Setting authenticator");
        replConfig.setAuthenticator(new BasicAuthenticator(parName, parPassword));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
//        outputMessage("== Synchronising DB :: Creating replicator");
        Replicator replicator = new Replicator(replConfig);

        // Listen to replicator change events.
//        System.out.println("== Synchronising DB :: Adding listener");
        replicator.addChangeListener(change -> {
            if (change.getStatus().getError() != null) {
                System.err.println("Error code ::  " + change.getStatus().getError().getCode());
            }
        });

        // Start replication.
//        outputMessage("== Synchronising DB :: Starting");
        replicator.start();
        // Check status of replication and wait till it is completed
        while ((replicator.getStatus().getActivityLevel() != Replicator.ActivityLevel.STOPPED) && (replicator.getStatus().getActivityLevel() != Replicator.ActivityLevel.IDLE)) {
            Thread.sleep(1000);
        }

        syncTotal = replicator.getStatus().getProgress().getTotal();
        replicator.stop();
//        outputMessage("== Synchronising DB :: Completed ");
        return replicator.getStatus().getProgress().getTotal();

        }
}

// end::GsWebApp_DbManager[]


// Check context validity for JVM cf Android
// Needs JVM alterative to ZipUtils
    public void test1xAttachments() throws CouchbaseLiteException, IOException {
        // if db exist, delete it
        private string final DB_NAME = "cbl-sqlite"
        File dbPath=new File(“.").getAbsolutePath();
        deleteDB(DB_NAME, context.getFilesDir());

        ZipUtils.unzip(getAsset("replacedb/android140-sqlite.cblite2.zip"), context.getFilesDir());

        Database db = new Database(DB_NAME, new DatabaseConfiguration());
        try {

            Document doc = db.getDocument("doc1");

            // For Validation
            Dictionary attachments = doc.getDictionary("_attachments");
            Blob blob = attachments.getBlob("attach1");
            byte[] content = blob.getContent();
            // For Validation

            byte[] attach = String.format(Locale.ENGLISH, "attach1").getBytes();
            Arrays.equals(attach, content);

        } finally {
            // close db
            db.close();
            // if db exist, delete it
            deleteDB(DB_NAME, context.getFilesDir());
        }

        Document document = new MutableDocument();

        // tag::1x-attachment[]
        Dictionary attachments = document.getDictionary("_attachments");
        Blob blob = attachments != null ? attachments.getBlob("avatar") : null;
        byte[] content = blob != null ? blob.getContent() : null;
        // end::1x-attachment[]
    }

    // ### Initializer
    public void testInitializer() {
        // tag::sdk-initializer[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init();
        // end::sdk-initializer[]
    }

    // ### New Database
    public void testNewDatabase() throws CouchbaseLiteException {
        // tag::new-database[]
        DatabaseConfiguration config = new DatabaseConfiguration();

        config.setDirectory(context.getFilesDir().getAbsolutePath());

        Database database = new Database(DB_NAME, config);
        // end::new-database[]


        database.delete();
      }

      // tag::close-database[]
      database.close()

      // end::close-database[]

    // ### Database Encryption
    public void testDatabaseEncryption() throws CouchbaseLiteException {
        // tag::database-encryption[]
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setEncryptionKey(new EncryptionKey("PASSWORD"));
        Database database = new Database(DB_NAME, config);
        // end::database-encryption[]
    }

    // ### Logging
    public void testLogging() {
        // tag::logging[]
        // deprecated
        Database.setLogLevel(LogDomain.REPLICATOR, LogLevel.VERBOSE);
        Database.setLogLevel(LogDomain.QUERY, LogLevel.VERBOSE);

        // end::logging[]
    }

    public void testEnableCustomLogging() {
        // tag::set-custom-logging[]
        Database.log.setCustom(new LogTestLogger(LogLevel.WARNING)); // <.>
        // end::set-custom-logging[]
    }


    // ### Console logging
    public void testConsoleLogging() throws CouchbaseLiteException {
      // tag::console-logging[]
          Database.log.getConsole().setDomain(LogDomain.ALL_DOMAINS); // <.>
          Database.log.getConsole().setLevel(LogLevel.VERBOSE); // <.>

      // end::console-logging[]

      // tag::console-logging-db[]
      Database.log.getConsole().setDomain(LogDomain.DATABASE);

  // end::console-logging-db[]
    }


    // ### File logging
    public void testFileLogging() throws CouchbaseLiteException {
       // tag::file-logging[]
          LogFileConfiguration LogCfg = new LogFileConfiguration(
              (System.getProperty("user.dir") + "/MyApp/logs")); // <.>
          LogCfg.setMaxSize(10240); // <.>
          LogCfg.setMaxRotateCount(5); // <.>
          LogCfg.setUsePlainText(false); // <.>
          Database.log.getFile().setConfig(LogCfg);
          Database.log.getFile().setLevel(LogLevel.INFO); // <.>

        // end::file-logging[]
    }

    // ### Loading a pre-built database

    public void testPreBuiltDatabase() throws IOException {
        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        DatabaseConfiguration configuration = new DatabaseConfiguration();
        if (!Database.exists("travel-sample", APP_DB_DIR)) {
            File tmpDir = new File(System.getProperty("java.io.tmpdir"));
            ZipUtils.unzip(getAsset("travel-sample.cblite2.zip"), tmpDir);
            File path = new File(tmpDir, "travel-sample");
            try {
                Database.copy(path, "travel-sample", configuration);
            } catch (CouchbaseLiteException e) {
                e.printStackTrace();
            }
        }
        // end::prebuilt-database[]
    }

    // helper methods

    // if db exist, delete it
    private void deleteDB(String name, File dir) {
        // database exist, delete it
        if (Database.exists(name, dir)) {
            // sometimes, db is still in used, wait for a while. Maximum 3 sec
            for (int i = 0; i < 10; i++) {
                try {
                    Database.delete(name, dir);
                    break;
                } catch (CouchbaseLiteException ex) {
                    try { Thread.sleep(300); }
                    catch (InterruptedException ignore) { }
                }
            }
        }
    }

    // ### Initializers
    public void testInitializers() {
        // tag::initializer[]
        MutableDocument newTask = new MutableDocument();
        newTask.setString("type", "task");
        newTask.setString("owner", "todo");
        newTask.setDate("createdAt", new Date());
        try {
            database.save(newTask);
        } catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        // end::initializer[]
    }

    // ### Mutability
    public void testMutability() {
        try { database.save(new MutableDocument("xyz")); }
        catch (CouchbaseLiteException ignore) { }

        // tag::update-document[]
        Document document = database.getDocument("xyz");
        MutableDocument mutableDocument = document.toMutable();
        mutableDocument.setString("name", "apples");
        try {
            database.save(mutableDocument);
        } catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        // end::update-document[]
    }

    // ### Typed Accessors
    public void testTypedAccessors() {
        MutableDocument newTask = new MutableDocument();

        // tag::date-getter[]
        newTask.setValue("createdAt", new Date());
        Date date = newTask.getDate("createdAt");
        // end::date-getter[]
    }

    // ### Batch operations
    public void testBatchOperations() {
        // tag::batch[]
        try {
            database.inBatch(() -> {
                for (int i = 0; i < 10; i++) {
                    MutableDocument doc = new MutableDocument();
                    doc.setValue("type", "user");
                    doc.setValue("name", "user " + i);
                    doc.setBoolean("admin", false);
                    try {
                        database.save(doc);
                    } catch (CouchbaseLiteException e) {
                        Log.e(TAG, e.toString());
                    }
                    Log.i(TAG, String.format("saved user document %s", doc.getString("name")));
                }
            });
        } catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        // end::batch[]
    }

    // ### Document Expiration
    public void DocumentExpiration() throws CouchbaseLiteException {
        // tag::document-expiration[]
        // Purge the document one day from now
        Instant ttl = Instant.now().plus(1, ChronoUnit.DAYS);
        database.setDocumentExpiration("doc123", new Date(ttl.toEpochMilli()));

        // Reset expiration
        database.setDocumentExpiration("doc1", null);

        // Query documents that will be expired in less than five minutes
        Instant fiveMinutesFromNow = Instant.now().plus(5, ChronoUnit.MINUTES);
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Meta.expiration.lessThan(Expression.doubleValue(fiveMinutesFromNow.toEpochMilli())));
        // end::document-expiration[]
    }

    public void testDocumentChangeListener() throws CouchbaseLiteException {
        // tag::document-listener[]
        database.addDocumentChangeListener(
            "user.john",
            change -> {
                Document doc = database.getDocument(change.getDocumentID());
                if (doc != null) {
                    Toast.makeText(context, "Status: " + doc.getString("verified_account"), Toast.LENGTH_SHORT).show();
                }
            });
        // end::document-listener[]
    }

    // ### Blobs
    public void testBlobs() {
        MutableDocument newTask = new MutableDocument();

        // tag::blob[]
        InputStream is = getAsset("avatar.jpg"); // <.>
        if (is == null) { return; }
        try {
            Blob blob = new Blob("image/jpeg", is);  // <.>
            newTask.setBlob("avatar", blob); // <.>
            database.save(newTask);

            Blob taskBlob = newTask.getBlob("avatar");
            byte[] bytes = taskBlob.getContent();
        } catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        } finally {
            try { is.close(); }
            catch (IOException ignore) { }
        }
        // end::blob[]
    }

    // ### Indexing
    public void testIndexing() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-index[]
            database.createIndex(
                "TypeNameIndex",
                IndexBuilder.valueIndex(
                    ValueIndexItem.property("type"),
                    ValueIndexItem.property("name")));
            // end::query-index[]
        }
    }

    // ### SELECT statement
    public void testSelectStatement() {
        {
            // tag::query-select-meta[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("type"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")))
                .orderBy(Ordering.expression(Meta.id));

            try {
                for (Result result : query.execute()) {
                    Log.i("Sample", String.format("hotel id -> %s", result.getString("id")));
                    Log.i("Sample", String.format("hotel name -> %s", result.getString("name")));
                }
            } catch (CouchbaseLiteException e) {
                Log.e("Sample", e.getLocalizedMessage());
            }
            // end::query-select-meta[]
        }
    }

    // META function
    public void testMetaFunction() throws CouchbaseLiteException {
        // For Documentation
        {
            Query query = QueryBuilder
                .select(SelectResult.expression(Meta.id))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("airport")))
                .orderBy(Ordering.expression(Meta.id));
            for (Result result : query.execute()) {
                Log.w("Sample", String.format("airport id -> %s", result.getString("id")));
                Log.w("Sample", String.format("airport id -> %s", result.getString(0)));
            }
        }
    }

    // ### all(*)
    public void testSelectAll() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-select-all[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")));
            // end::query-select-all[]

            // tag::live-query[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database)); // <.>

            // Adds a query change listener.
            // Changes will be posted on the main queue.
            ListenerToken token = query.addChangeListener(change -> { // <.>
                for (Result result : change.getResults()) {
                    Log.d(TAG, "results: " + result.getKeys());
                    /* Update UI */
                }
            });

            // end::live-query[]

            // tag::stop-live-query[]
            query.removeChangeListener(token); // <.>
            // end::stop-live-query[]

            for (Result result : query.execute()) {
                Log.i(
                    "Sample",
                    String.format("hotel -> %s", result.getDictionary(DATABASE_NAME).toMap()));
            }
        }
    }

    // ###　WHERE statement
    public void testWhereStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-where[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")))
                .limit(Expression.intValue(10));
            for (Result result : query.execute()) {
                Dictionary all = result.getDictionary(DATABASE_NAME);
                Log.i("Sample", String.format("name -> %s", all.getString("name")));
                Log.i("Sample", String.format("type -> %s", all.getString("type")));
            }
            // end::query-where[]
        }
    }

    public void testQueryDeletedDocuments() {
        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        Where query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Meta.deleted);
        // end::query-deleted-documents[]
    }


    // ####　Collection Operators
    public void testCollectionStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-collection-operator-contains[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("public_likes"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel"))
                    .and(ArrayFunction
                        .contains(Expression.property("public_likes"), Expression.string("Armani Langworth"))));
            for (Result result : query.execute()) {
                Log.i(
                    "Sample",
                    String.format("public_likes -> %s", result.getArray("public_likes").toList()));
            }
            // end::query-collection-operator-contains[]
        }
    }

    // IN operator
    public void testInOperator() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-collection-operator-in[]
            Expression[] values = new Expression[] {
                Expression.property("first"),
                Expression.property("last"),
                Expression.property("username")
            };

            Query query = QueryBuilder.select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.string("Armani").in(values));
            // end::query-collection-operator-in[]

            for (Result result : query.execute()) {
                { Log.w("Sample", String.format("%s", result.toMap().toString()));
                }
             }
        }

    // Pattern Matching
    public void testPatternMatching() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-like-operator[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name")).like(Function.Expression.string("royal engineers museum")))));
            for (Result result : query.execute()) {
                Log.i("Sample", String.format("name -> %s", result.getString("name")));
            }
            // end::query-like-operator[]
        }
    }

    // ### Wildcard Match
    public void testWildcardMatch() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-like-operator-wildcard-match[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("eng%e%"))));
            for (Result result : query.execute()) {
                Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-like-operator-wildcard-match[]
        }
    }

    // Wildcard Character Match
    public void testWildCharacterMatch() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-like-operator-wildcard-character-match[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("eng____r"))));
            for (Result result : query.execute()) {
                Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-like-operator-wildcard-character-match[]
        }
    }

    // ### Regex Match
    public void testRegexMatch() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-regex-operator[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).regex(Expression.string("\\beng.*r\\b"))));            ResultSet rs = query.execute();
            for (Result result : query.execute()) {
                Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-regex-operator[]
        }
    }

    // JOIN statement
    public void testJoinStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-join[]
            Query query = QueryBuilder.select(
                SelectResult.expression(Expression.property("name").from("airline")),
                SelectResult.expression(Expression.property("callsign").from("airline")),
                SelectResult.expression(Expression.property("destinationairport").from("route")),
                SelectResult.expression(Expression.property("stops").from("route")),
                SelectResult.expression(Expression.property("airline").from("route")))
                .from(DataSource.database(database).as("airline"))
                .join(Join.join(DataSource.database(database).as("route"))
                    .on(Meta.id.from("airline").equalTo(Expression.property("airlineid").from("route"))))
                .where(Expression.property("type").from("route").equalTo(Expression.string("route"))
                    .and(Expression.property("type").from("airline").equalTo(Expression.string("airline")))
                    .and(Expression.property("sourceairport").from("route").equalTo(Expression.string("RIX"))));
            for (Result result : query.execute()) {
                     Log.w("Sample", String.format("%s", result.toMap().toString()));
            }
            // end::query-join[]
        }
    }

    // ### GROUPBY statement
    public void testGroupByStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-groupby[]
            Query query = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))),
                SelectResult.property("country"),
                SelectResult.property("tz"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("airport"))
                    .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300))))
                .groupBy(
                    Expression.property("country"),
                    Expression.property("tz"))
                .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending());
            for (Result result : query.execute()) {
                Log.i(
                    "Sample",
                    String.format(
                        "There are %d airports on the %s timezone located in %s and above 300ft",
                        result.getInt("$1"),
                        result.getString("tz"),
                        result.getString("country")));
            }
            // end::query-groupby[]
        }
    }

    // ### ORDER BY statement
    public void testOrderByStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-orderby[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")))
                .orderBy(Ordering.property("name").ascending())
                .limit(Expression.intValue(10));
            For (Result result : query.execute()) {
                Log.i("Sample", String.format("%s", result.toMap()));
            }
            // end::query-orderby[]
        }
    }

    // EXPLAIN statement
    public void testExplainStatement() throws CouchbaseLiteException {
    // For Documentation
            // tag::query-explain-all[]
            Query query = QueryBuilder
              .select(SelectResult.all())
              .from(DataSource.database(database))
              .where(Expression.property("type").equalTo(Expression.string("university")))
              .groupBy(Expression.property("country"))
              .orderBy(Ordering.property("name").descending()); // <.>
            Log.i(query.explain()); // <.>
            // end::query-explain-all[]
            // tag::query-explain-like[]
            Query query = QueryBuilder
              .select(SelectResult.all())
              .from(DataSource.database(database))
              .where(Expression.property("type").like(Expression.string("%hotel%"))); // <.>
            Log.i(query.explain());
            // end::query-explain-like[]
            // tag::query-explain-nopfx[]
            Query query = QueryBuilder
              .select(SelectResult.all())
              .from(DataSource.database(database))
              .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                .and(Expression.property("name").like(Expression.string("%royal%"))));
            Log.i(query.explain());
            // end::query-explain-nopfx[]
            // tag::query-explain-function[]
            Query query = QueryBuilder
              .select(SelectResult.all())
              .from(DataSource.database(database))
              .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))); // <.>
            Log.i(query.explain());
            // end::query-explain-function[]
            // tag::query-explain-nofunction[]
            Query query = QueryBuilder
              .select(SelectResult.all())
              .from(DataSource.database(database))
              .where(Expression.property("type").equalTo(Expression.string("hotel"))); // <.>
            Log.i(query.explain());
            // end::query-explain-nofunction[]

    }
    // end query-explain



    void prepareIndex() throws CouchbaseLiteException {
        // tag::fts-index[]
        database.createIndex(
            "nameFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("name")).ignoreAccents(false));
        // end::fts-index[]
    }

    public void testFTS() throws CouchbaseLiteException {
        // tag::fts-query[]
        Expression whereClause = FullTextExpression.index("nameFTSIndex").match("buy");
        Query ftsQuery = QueryBuilder.select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(whereClause);
        ResultSet ftsQueryResult = ftsQuery.execute();
        for (Result result : ftsQueryResult) {
            Log.i(
                TAG,
                String.format("document properties %s", result.getString(0)));
        }
        // end::fts-query[]
    }

    /* The `tag::replication[]` example is inlined in java.adoc */

    public void testTroubleshooting() {
        // tag::replication-logging[]
        Database.setLogLevel(LogDomain.REPLICATOR, LogLevel.VERBOSE);
        // end::replication-logging[]
    }

    public void testReplicationBasicAuthentication() throws URISyntaxException {
        // tag::basic-authentication[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setAuthenticator(new BasicAuthenticator("username", "password"));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::basic-authentication[]
    }

    public void testReplicationSessionAuthentication() throws URISyntaxException {
        // tag::session-authentication[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setAuthenticator(new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447"));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::session-authentication[]
    }

    public void testReplicationStatus() throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::replication-status[]
        replicator.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == Replicator.ActivityLevel.STOPPED) {
                Log.i(TAG, "Replication stopped");
            }
        });
        // end::replication-status[]
    }

    //  BEGIN PendingDocuments BM -- 19/Feb/21 --
    import android.support.annotation.NonNull;
    import android.util.Log;

    import java.net.URI;
    import java.net.URISyntaxException;
    import java.util.Iterator;
    import java.util.Set;

    import com.couchbase.lite.CouchbaseLiteException;
    import com.couchbase.lite.Database;
    import com.couchbase.lite.Endpoint;
    import com.couchbase.lite.Replicator;
    import com.couchbase.lite.ReplicatorConfiguration;
    import com.couchbase.lite.URLEndpoint;

    class PendingDocsExample {
        private static final String TAG = "SCRATCH";

        private Database database;
        private Replicator replicator;

        //  BEGIN PendingDocuments IB -- 11/Feb/21 --
        public void testReplicationPendingDocs() throws URISyntaxException, CouchbaseLiteException {
            // nottag::replication-pendingdocuments[]
            // ... include other code as required
            //
            final Endpoint endpoint =
              new URLEndpoint(new URI("ws://localhost:4984/db"));

            final ReplicatorConfiguration config =
              new ReplicatorConfiguration(database, endpoint)
            .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH);
            // tag::replication-push-pendingdocumentids[]

            replicator = new Replicator(config);
            final Set<String> pendingDocs =
              replicator.getPendingDocumentIds(); // <.>

            // end::replication-push-pendingdocumentids[]

            replicator.addChangeListener(change -> {
              onStatusChanged(pendingDocs, change.getStatus()); });

            replicator.start();

            // ... include other code as required
            // notend::replication-pendingdocuments[]
          }
        //
        // tag::replication-pendingdocuments[]
        //
        private void onStatusChanged(
          @NonNull final Set<String> pendingDocs,
          @NonNull final Replicator.Status status) {
          // ... sample onStatusChanged function
          //
          Log.i(TAG,
            "Replicator activity level is " + status.getActivityLevel().toString());

          // iterate and report-on previously
          // retrieved pending docids 'list'
          for (Iterator<String> itr = pendingDocs.iterator(); itr.hasNext(); ) {
            final String docId = itr.next();
            try {
              // tag::replication-push-isdocumentpending[]
              if (!replicator.isDocumentPending(docId)) { continue; } // <.>
              // end::replication-push-isdocumentpending[]

              itr.remove();
              Log.i(TAG, "Doc ID " + docId + " has been pushed");
            }
            catch (CouchbaseLiteException e) {
              Log.w(TAG, "isDocumentPending failed", e); }
          }
        }
        // end::replication-pendingdocuments[]
        //  END PendingDocuments BM -- 19/Feb/21 --
    }




    public void testHandlingNetworkErrors() throws URISyntaxException {
        Endpoint endpoint = new URLEndpoint(new URI("ws://localhost:4984/db"));
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::replication-error-handling[]
        replicator.addChangeListener(change -> {
            CouchbaseLiteException error = change.getStatus().getError();
            if (error != null) { Log.w(TAG, "Error code:: %d", error); }
        });
        replicator.start();
        // end::replication-error-handling[]

        replicator.stop();
    }

    public void testReplicatorDocumentEvent() throws URISyntaxException {
        Endpoint endpoint = new URLEndpoint(new URI("ws://localhost:4984/db"));
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::add-document-replication-listener[]
        ListenerToken token = replicator.addDocumentReplicationListener(replication -> {

            Log.i(TAG, "Replication type: " + ((replication.isPush()) ? "Push" : "Pull"));
            for (ReplicatedDocument document : replication.getDocuments()) {
                Log.i(TAG, "Doc ID: " + document.getID());

                CouchbaseLiteException err = document.getError();
                if (err != null) {
                    // There was an error
                    Log.e(TAG, "Error replicating document: ", err);
                    return;
                }

                if (document.flags().contains(DocumentFlag.DocumentFlagsDeleted)) {
                    Log.i(TAG, "Successfully replicated a deleted document");
                }
            }
        });

        replicator.start();
        // end::add-document-replication-listener[]

        // tag::remove-document-replication-listener[]
        replicator.removeChangeListener(token);
        // end::remove-document-replication-listener[]
    }

    public void testReplicationCustomHeader() throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);

        // tag::replication-custom-header[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        Map<String, String> headers = new HashMap<>();
        headers.put("CustomHeaderName", "Value");
        config.setHeaders(headers);
        // end::replication-custom-header[]
    }

    // ### Certificate Pinning

    public void testCertificatePinning() throws URISyntaxException, IOException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);

        // tag::certificate-pinning[]
        InputStream is = getAsset("cert.cer");
        byte[] cert = IOUtils.toByteArray(is);
        if (is != null) {
            try { is.close(); }
            catch (IOException ignore) {}
        }

        config.setPinnedServerCertificate(cert);
        // end::certificate-pinning[]
    }

    // ### Reset replicator checkpoint
    public void testReplicationResetCheckpoint() throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();

        // tag::replication-reset-checkpoint[]
        if(resetCheckpointExample) {
          replicator.start(true);
        else
          replicator.start(false);
        }
        // end::replication-reset-checkpoint[]

        replicator.stop();
    }

    public void testReplicationPushFilter() throws URISyntaxException {
        // tag::replication-push-filter[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setPushFilter((document, flags) -> flags.contains(DocumentFlag.DocumentFlagsDeleted)); // <1>

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::replication-push-filter[]
    }

    public void testReplicationPullFilter() throws URISyntaxException {
        // tag::replication-pull-filter[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setPullFilter((document, flags) -> "draft".equals(document.getString("type"))); // <1>

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::replication-pull-filter[]
    }

    //
    public void testCustomRetryConfig() throws URISyntaxException {
    // tag::replication-retry-config[]
        URLEndpoint target =
            new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config =
            new ReplicatorConfiguration(database, target);

        //  other config as required . . .
        // tag::replication-heartbeat-config[]
        config.setHeartbeat(150L); // <.>
        // end::replication-heartbeat-config[]
        // tag::replication-maxattempts-config[]
        config.setMaxattempts(20L); // <.>
        // end::replication-maxattempts-config[]
        // tag::replication-maxattemptwaittime-config[]
        config.setMaxAttemptWaitTime(600L); // <.>
        // end::replication-maxattemptwaittime-config[]

        //  other config as required . . .

        Replicator repl = new Replicator(config);

    // end::replication-retry-config[]
    }




    public void testDatabaseReplica() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database1 = new Database(DB_NAME, config);

        config = new DatabaseConfiguration();
        Database database2 = new Database(DB_NAME2, config);

        /* EE feature: code below might throw a compilation error
           if it's compiled against CBL Android Community. */
        // tag::database-replica[]
        DatabaseEndpoint targetDatabase = new DatabaseEndpoint(database2);
        ReplicatorConfiguration replicatorConfig = new ReplicatorConfiguration(database1, targetDatabase);
        replicatorConfig.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH);

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(replicatorConfig);
        replicator.start();
        // end::database-replica[]
    }

    public void testPredictiveModel() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database = new Database(DB_NAME, config);

        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", new ImageClassifierModel());
        // end::register-model[]

        // tag::predictive-query-value-index[]
        ValueIndex index = IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")));
        database.createIndex("value-index-image-classifier", index);
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier");
        // end::unregister-model[]
    }

    public void testPredictiveIndex() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database = new Database(DB_NAME, config);

        // tag::predictive-query-predictive-index[]
        Map<String, Object> inputMap = new HashMap<>();
        inputMap.put("numbers", Expression.property("photo"));
        Expression input = Expression.map(inputMap);

        PredictiveIndex index = IndexBuilder.predictiveIndex("ImageClassifier", input, null);
        database.createIndex("predictive-index-image-classifier", index);
        // end::predictive-query-predictive-index[]
    }

    public void testPredictiveQuery() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database = new Database(DB_NAME, config);

        // tag::predictive-query[]
        Map<String, Object> inputProperties = new HashMap<>();
        inputProperties.put("photo", Expression.property("photo"));
        Expression input = Expression.map(inputProperties);
        PredictionFunction prediction = PredictiveModel.predict("ImageClassifier", input); // <1>

        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("label").equalTo(Expression.string("car"))
                .and(Expression.property("probability").greaterThanOrEqualTo(Expression.doubleValue(0.8))));

        // Run the query.
        ResultSet result = query.execute();
        Log.d(TAG, "Number of rows: " + result.allResults().size());
        // end::predictive-query[]
    }

    public void testReplicationWithCustomConflictResolver() throws URISyntaxException {
        // tag::replication-conflict-resolver[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setConflictResolver(new LocalWinConflictResolver());

        Replicator replication = new Replicator(config);
        replication.start();
        // end::replication-conflict-resolver[]
    }

    public void testSaveWithCustomConflictResolver() throws CouchbaseLiteException {
        // tag::update-document-with-conflict-handler[]
        Document doc = database.getDocument("xyz");
        if (doc == null) { return; }
        MutableDocument mutableDocument = doc.toMutable();
        mutableDocument.setString("name", "apples");

        database.save(
            mutableDocument,
            (newDoc, curDoc) -> {
                if (curDoc == null) { return false; }
                Map<String, Object> dataMap = curDoc.toMap();
                dataMap.putAll(newDoc.toMap());
                newDoc.setData(dataMap);
                return true;
            });
        // end::update-document-with-conflict-handler[]
    }
}

// tag::local-win-conflict-resolver[]
class LocalWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getLocalDocument();
    }
}
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
class RemoteWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getRemoteDocument();
    }
}
// end::remote-win-conflict-resolver[]

// tag::merge-conflict-resolver[]
class MergeConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        Map<String, Object> merge = conflict.getLocalDocument().toMap();
        merge.putAll(conflict.getRemoteDocument().toMap());
        return new MutableDocument(conflict.getDocumentId(), merge);
    }
}
// end::merge-conflict-resolver[]


/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ----------------------------------------------------------- */

class BrowserSessionManager implements MessageEndpointDelegate {
    private final Context context;
    private Replicator replicator;

// Check context validity for JVM cf Android
private BrowserSessionManager(Context context) { this.context = context; }

    public void initCouchbase() throws CouchbaseLiteException {
        // tag::message-endpoint[]
        DatabaseConfiguration databaseConfiguration = new DatabaseConfiguration(context);
        Database database = new Database(DB_NAME, databaseConfiguration);

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        MessageEndpoint messageEndpointTarget = new MessageEndpoint(
            "UID:123",
            "active",
            ProtocolType.MESSAGE_STREAM,
            this);
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, messageEndpointTarget);

        // Create the replicator object.
        replicator = new Replicator(config);
        // Start the replication.
        replicator.start();
        // end::message-endpoint-replicator[]
    }

    // tag::create-connection[]
    /* implementation of MessageEndpointDelegate */
    @NonNull
    @Override
    public MessageEndpointConnection createConnection(@NonNull MessageEndpoint endpoint) {
        return new ActivePeerConnection(); /* implements MessageEndpointConnection */
    }
    // end::create-connection[]
}

class ActivePeerConnection implements MessageEndpointConnection {

    private ReplicatorConnection replicatorConnection;

    public void disconnect() {
        // tag::active-replicator-close[]
        replicatorConnection.close(null);
        // end::active-replicator-close[]
    }

    // tag::active-peer-open[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void open(@NonNull ReplicatorConnection connection, @NonNull MessagingCompletion completion) {
        replicatorConnection = connection;
        completion.complete(true, null);
    }
    // end::active-peer-open[]

    // tag::active-peer-close[]
    @Override
    public void close(Exception error, @NonNull MessagingCloseCompletion completion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete();
    }
    // end::active-peer-close[]

    // tag::active-peer-send[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void send(@NonNull Message message, @NonNull MessagingCompletion completion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null);
    }
    // end::active-peer-send[]

    public void receive(Message message) {
        // tag::active-peer-receive[]
        replicatorConnection.receive(message);
        // end::active-peer-receive[]
    }

}

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ----------------------------------------------------------- */

// Check context validity for JVM cf Android
class PassivePeerConnection implements MessageEndpointConnection {
    private final Context context;

    private MessageEndpointListener messageEndpointListener;
    private ReplicatorConnection replicatorConnection;

    private PassivePeerConnection(Context context) { this.context = context; }

    public void startListener() throws CouchbaseLiteException {
        // tag::listener[]
        DatabaseConfiguration databaseConfiguration = new DatabaseConfiguration();
        Database database = new Database(DB_NAME, databaseConfiguration);
        MessageEndpointListenerConfiguration listenerConfiguration = new MessageEndpointListenerConfiguration(
            database,
            ProtocolType.MESSAGE_STREAM);
        this.messageEndpointListener = new MessageEndpointListener(listenerConfiguration);
        // end::listener[]
    }

    public void stopListener() {
        // tag::passive-stop-listener[]
        messageEndpointListener.closeAll();
        // end::passive-stop-listener[]
    }

    public void accept() {
        // tag::advertizer-accept[]
        PassivePeerConnection connection = new PassivePeerConnection(context); /* implements
        MessageEndpointConnection */
        messageEndpointListener.accept(connection);
        // end::advertizer-accept[]
    }

    public void disconnect() {
        // tag::passive-replicator-close[]
        replicatorConnection.close(null);
        // end::passive-replicator-close[]
    }

    // tag::passive-peer-open[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void open(@NonNull ReplicatorConnection connection, @NonNull MessagingCompletion completion) {
        replicatorConnection = connection;
        completion.complete(true, null);
    }
    // end::passive-peer-open[]

    // tag::passive-peer-close[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void close(Exception error, @NonNull MessagingCloseCompletion completion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete();
    }
    // end::passive-peer-close[]

    // tag::passive-peer-send[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void send(@NonNull Message message, @NonNull MessagingCompletion completion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null);
    }
    // end::passive-peer-send[]

    public void receive(Message message) {
        // tag::passive-peer-receive[]
        replicatorConnection.receive(message);
        // end::passive-peer-receive[]
    }
}

// tag::predictive-model[]
// tensorFlowModel is a fake implementation
// this would be the implementation of the ml model you have chosen
class ImageClassifierModel implements PredictiveModel {
    @Override
    public Dictionary predict(@NonNull Dictionary input) {
        Blob blob = input.getBlob("photo");
        if (blob == null) { return null; }

        // tensorFlowModel is a fake implementation
        // this would be the implementation of the ml model you have chosen
        return new MutableDictionary(TensorFlowModel.predictImage(blob.getContent())); // <1>
    }
}

class TensorFlowModel {
    public static Map<String, Object> predictImage(byte[] data) {
        return null;
    }
}
// end::predictive-model[]

// tag::custom-logging[]
class LogTestLogger implements Logger {
    @NonNull
    private final LogLevel level;

    public LogTestLogger(@NonNull LogLevel level) { this.level = level; }

    @NonNull
    @Override
    public LogLevel getLevel() { return level; }

    @Override
    public void log(@NonNull LogLevel level, @NonNull LogDomain domain, @NonNull String message) {

    }
}
// end::custom-logging[]




// tag::ziputils-unzip[]
public class ZipUtils {
    public static void unzip(InputStream in, File destination) throws IOException {
        byte[] buffer = new byte[1024];
        ZipInputStream zis = new ZipInputStream(in);
        ZipEntry ze = zis.getNextEntry();
        while (ze != null) {
            String fileName = ze.getName();
            File newFile = new File(destination, fileName);
            if (ze.isDirectory()) {
                newFile.mkdirs();
            } else {
                new File(newFile.getParent()).mkdirs();
                FileOutputStream fos = new FileOutputStream(newFile);
                int len;
                while ((len = zis.read(buffer)) > 0) {
                    fos.write(buffer, 0, len);
                }
                fos.close();
            }
            ze = zis.getNextEntry();
        }
        zis.closeEntry();
        zis.close();
        in.close();
    }
}
// end::ziputils-unzip[]






/*
 QUERY RESULT SET HANDLING EXAMPLES
*/
package com.example.docsnippet;
        import android.app.Application.*;
        import android.content.Context;
        import android.content.Context.*;
        import java.lang.Object;
        import java.security.Key;
        import java.util.*;
        import com.couchbase.lite.*;
        import com.couchbase.lite.Dictionary;

public class TestQueries {

    // For Documentation

    Datastore ds = new Datastore();

    Database this_Db = ds.getDB();

    String dbName = this_Db.getName();

    HashMap<String, Object> hotels = new HashMap<>();

    Dictionary thisDocsProps;
    String thisDocsId;
    String thisDocsName;
    String thisDocsType;
    String thisDocsCity;



    static {
        init();
    }

    private static void init() {
    }



    public void testQuerySyntaxAll() throws CouchbaseLiteException {

        // tag::query-syntax-all[]
        try {
          this_Db = new Database("hotels");
        } catch (CouchbaseLiteException e) {
          e.printStackTrace();
        }

      Query listQuery = QueryBuilder.select(SelectResult.all())
              .from(DataSource.database(this_Db));

        // end::query-syntax-all[]

        // tag::query-access-all[]
        try {
            for (Result result : listQuery.execute().allResults()) {
                             // get the k-v pairs from the 'hotel' key's value into a dictionary
                thisDocsProps = result.getDictionary(0)); // <.>
                thisDocsId = thisDocsProps.getString("id");
                thisDocsName = thisDocsProps.getString("Name");
                thisDocsType = thisDocsProps.getString("Type");
                thisDocsCity = thisDocsProps.getString("City");

                // Alternatively, access results value dictionary directly
                final Hotel hotel = new Hotel();
                hotel.Id = result.getDictionary(0).getString("id"); // <.>
                hotel.Type = result.getDictionary(0).getString("Type");
                hotel.Name = result.getDictionary(0).getString("Name");
                hotel.City = result.getDictionary(0).getString("City");
                hotel.Country= result.getDictionary(0).getString("Country");
                hotel.Description = result.getDictionary(0).getString("Description");
                hotels.put(hotel.Id, hotel);

            }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        // end::query-access-all[]
    }


  // tag::query-access-json[]
    // Uses Jackson JSON processor

    ArrayList<Hotel> hotels = new ArrayList<Hotel>();
    HashMap<String, Object> dictFromJSONstring;
    for (Result result : listQuery.execute()) {

      // Get result as JSON string
      String thisJsonString = result.toJSON(); // <.>

            // Get Java  Hashmap from JSON string
      HashMap<String, Object> dictFromJSONstring =
              mapper.readValue(thisJsonString, HashMap.class); // <.>


      // Use created hashmap
      String hotelId = dictFromJSONstring.get("id").toString();
      String hotelType = dictFromJSONstring.get("type").toString();
      String hotelname = dictFromJSONstring.get("name").toString();


      // Get custom object from Native 'dictionary' object
      Hotel thisHotel =
              mapper.readValue(thisJsonString, Hotel.class); // <.>
      hotels.add(thisHotel);

    }

  // end::query-access-json[]
            }

    public void testQuerySyntaxProps() throws CouchbaseLiteException {

        // tag::query-syntax-props[]
        try {
          this_Db = new Database("hotels");
        } catch (CouchbaseLiteException e) {
          e.printStackTrace();
        }

        Query listQuery =
                QueryBuilder.select(SelectResult.expression(Meta.id),
                        SelectResult.property("name"),
                        SelectResult.property("Name"),
                        SelectResult.property("Type"),
                        SelectResult.property("City"))
                        .from(DataSource.database(this_Db));

        // end::query-syntax-props[]

        // tag::query-access-props[]

        try {
            for (Result result : listQuery.execute().allResults()) {

                // get data direct from result k-v pairs
                final Hotel hotel = new Hotel();
                hotel.Id = result.getString("id");
                hotel.Type = result.getString("Type");
                hotel.Name = result.getString("Name");
                hotel.City = result.getString("City");

                // Store created hotel object in a hashmap of hotels
                hotels.put(hotel.Id, hotel);

                // Get result k-v pairs into a 'dictionary' object
                Map <String, Object> thisDocsProps = result.toMap();
                thisDocsId =
                        thisDocsProps.getOrDefault("id",null).toString();
                thisDocsName =
                        thisDocsProps.getOrDefault("Name",null).toString();
                thisDocsType =
                        thisDocsProps.getOrDefault("Type",null).toString();
                thisDocsCity =
                        thisDocsProps.getOrDefault("City",null).toString();

            }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        // end::query-access-props[]
    }


    public void testQuerySyntaxCount() throws CouchbaseLiteException {
      try {
        this_Db = new Database("hotels");
      } catch (CouchbaseLiteException e) {
        e.printStackTrace();
      }

      // tag::query-syntax-count-only[]
      Query listQuery = QueryBuilder.select(
              SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
              .from(DataSource.database(this_Db));

      // end::query-syntax-count-only[]


        // tag::query-access-count-only[]
        try {
            for (Result result : listQuery.execute()) {

                // Retrieve count using key 'mycount'
                Integer altDocId = result.getInt("mycount");

                // Alternatively, use the index
                Integer orDocId = result.getInt(0);
            }
            // Or even miss out the for-loop altogether
            Integer resultCount = listQuery.execute().next().getInt("mycount");

        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::query-access-count-only[]
    }


    public void testQuerySyntaxId() throws CouchbaseLiteException {
      // tag::query-syntax-id[]
      try {
        this_Db = new Database("hotels");
      } catch (CouchbaseLiteException e) {
        e.printStackTrace();
      }

      Query listQuery =
              QueryBuilder.select(SelectResult.expression(Meta.id).as("metaID"))
                      .from(DataSource.database(this_Db));

      // end::query-syntax-id[]


        // tag::query-access-id[]

        try {
            for (Result result : listQuery.execute().allResults()) {

                // get the ID form the result's k-v pair array
                thisDocsId = result.getString("metaID"); // <.>

                // Get document from DB using retrieved ID
                Document thisDoc = this_Db.getDocument(thisDocsId);

                // Process document as required
                thisDocsName = thisDoc.getString("Name");

            }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        // end::query-access-id[]

    }


    // tag::query-syntax-pagination-all[]
    public void testQueryPagination() throws CouchbaseLiteException {


      // tag::query-syntax-pagination[]
      try {
        this_Db = new Database("hotels");
      } catch (CouchbaseLiteException e) {
        e.printStackTrace();
      }

      int thisOffset = 0;
      int thisLimit = 20;

      Query listQuery =
      QueryBuilder
      .select(SelectResult.all())
      .from(DataSource.database(this_Db))
      .limit(Expression.intValue(thisLimit),
      Expression.intValue(thisOffset)); // <.>

      // end::query-syntax-pagination[]

    }

    // end::query-syntax-pagination-all[]



    public List<Result> docsonly_QuerySyntaxN1QL (Database argDB)
    {
      // For Documentation -- N1QL Query using parameters
      // tag::query-syntax-n1ql[]
      //  Declared elsewhere: Database argDB

      Database thisDb = argDB;

      Query thisQuery =
      thisDb.createQuery(
        "SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.

        return thisQuery.execute().allResults();

        // end::query-syntax-n1ql[]
      }


    public List<Result> docsonly_QuerySyntaxN1QLParams (Database argDB)
    {
      // For Documentation -- N1QL Query using parameters
      // tag::query-syntax-n1ql-params[]
      //  Declared elsewhere: Database argDB

      Database thisDb = argDB;

      Query thisQuery =
          thisDb.createQuery(
              "SELECT META().id AS thisId FROM _ WHERE type = $type"); // <.

      thisQuery.parameters =
          Parameters.setString("type", "hotel"); // <.>

      return thisQuery.execute().allResults();

      // end::query-syntax-n1ql-params[]
  }


} // class

public class Supporting_Datatypes {
    private static final String TAG = "info";

    public void datatype_dictionary() throws CouchbaseLiteException {
        Database database = new Database("mydb");

        // tag::datatype_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)
        Document document = database.getDocument("doc1");

        // Getting a dictionary from the document's properties
        Dictionary dict = document.getDictionary("address");

        // Access a value with a key from the dictionary
        String street = dict.getString("street");

        // Iterate dictionary
        for (String key : dict) {
            dict.getValue(key);
            Log.i("x", "Key %s, = %s", key, dict.getValue(key));
        }

        // Create a mutable copy
        MutableDictionary mutable_Dict = dict.toMutable();
        // end::datatype_dictionary[]
    }

    public void datatype_mutable_dictionary() throws CouchbaseLiteException {

        Database database = new Database("mydb");

        // tag::datatype_mutable_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)

        // Create a new mutable dictionary and populate some keys/values
        MutableDictionary mutable_dict = new MutableDictionary();
        mutable_dict.setString("street", "1 Main st.");
        mutable_dict.setString("city", "San Francisco");

        // Add the dictionary to a document's properties and save the document
        MutableDocument mutable_doc = new MutableDocument("doc1");
        mutable_doc.setDictionary("address", mutable_dict);
        database.save(mutable_doc);

        // end::datatype_mutable_dictionary[]
    }


    public void datatype_array() throws CouchbaseLiteException {
        Database database = new Database("mydb");

        // tag::datatype_array[]
        // NOTE: No error handling, for brevity (see getting started)

        Document document = database.getDocument("doc1");

        // Getting a phones array from the document's properties
        Array array = document.getArray("phones");

        // Get element count
        int count = array.count();

        // Access an array element by index
        if (count >= 0) { String phone = array.getString(1); }

        // Iterate dictionary
        for (int i = 0; i < count; i++)
        {
            Log.i("tag", "Item %d = %s", i, array.getString(i));
        }

        // Create a mutable copy
        MutableArray mutable_array = array.toMutable();
        // end::datatype_array[]


    }

    public void datatype_mutable_array() throws CouchbaseLiteException {
        Database database = new Database("mydb");

        // tag::datatype_mutable_array[]
        // NOTE: No error handling, for brevity (see getting started)

        // Create a new mutable array and populate data into the array
        MutableArray mutable_array = new MutableArray();
        mutable_array.addString("650-000-0000");
        mutable_array.addString("650-000-0001");

        // Set the array to document's properties and save the document
        MutableDocument mutable_doc = new MutableDocument("doc1");
        mutable_doc.setArray("phones", mutable_array);
        database.save(mutable_doc);
        // end::datatype_mutable_array[]
    }

} // end  class supporting_datatypes




// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/Examples.java 



// MODULE_BEGIN --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/JSONExamples.java 
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
package com.couchbase.code_snippets;

import java.util.Map;
import java.util.Objects;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.json.JSONException;
import org.json.JSONObject;

import com.couchbase.lite.Array;
import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;


public class JSONExamples {
    public static final String JSON
        = "[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\","
        + "\"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},"
        + "{\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\","
        + "\"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},"
        + "{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\","
        + "\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\","
        + "\"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]";

    public void jsonArrayExample(Database db) throws CouchbaseLiteException {
        // tag::tojson-array[]
        // github tag=tojson-array
        final MutableArray mArray = new MutableArray(JSON); // <.>

        for (int i = 0; i < mArray.count(); i++) { // <.>
            final Dictionary dict = mArray.getDictionary(i);
            System.out.println(dict.getString("name"));
            db.save(new MutableDocument(dict.getString("id"), dict.toMap()));
        }

        final Array features = db.getDocument("1002").getArray("features");
        for (Object feature: features.toList()) { System.out.println(feature.toString()); }
        System.out.println(features.toJSON()); // <.>
        // end::tojson-array[]
    }

    public void jsonBlobExample(Database db) {
      // tag::tojson-blob[]
      // github tag=tojson-blob
      final Map<String, ?> thisBlob = db.getDocument("thisdoc-id").toMap();
        if (!Blob.isBlob(thisBlob)) { return; }

        final String blobType = thisBlob.get("content_type").toString();
        final Number blobLength = (Number) thisBlob.get("length");
      // end::tojson-blob[]
    }

    public void jsonDictionaryExample(Database db) {
        // tag::tojson-dictionary[]
        // github tag=tojson-dictionary
        final MutableDictionary mDict = new MutableDictionary(JSON); // <.>
        System.out.println(mDict.toString());

        System.out.println("Details for: " + mDict.getString("name"));
        for (String key: mDict.getKeys()) {
            System.out.println(key + " => " + mDict.getValue(key));
        }
        // end::tojson-dictionary[]
      }

    public void jsonDocumentExample(Database srcDb, Database dstDb) throws CouchbaseLiteException {
        // tag::tojson-document[]
        // github tag=tojson-document
        final Query listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(srcDb));

        for (Result row: listQuery.execute()) {
            final String thisId = row.getString("metaId");

            final String json = srcDb.getDocument(thisId).toJSON(); // <.>
            System.out.println("JSON String = " + json);

            final MutableDocument hotelFromJSON = new MutableDocument(thisId, json); // <.>

            dstDb.save(hotelFromJSON);

            for (Map.Entry entry: dstDb.getDocument(thisId).toMap().entrySet()) {
                System.out.println(entry.getKey() + " => " + entry.getValue()); // <.>
            }
        }
        // end::tojson-document[]
    }

    public void jsonQueryExample(Query query) throws CouchbaseLiteException, JSONException {
        for (Result row: query.execute()) {

            // get the result into a JSON String
            final String jsonString = row.toJSON();

            final JSONObject thisJsonObj = new JSONObject(jsonString);

            // Use Json Object to populate Native object
            // Use Codable class to unpack JSON data to native object
            final Hotel thisHotel = new Hotel(
                "this hotel",
                "Ghana, West Africa",
                thisJsonObj.getString("city"),
                thisJsonObj.getString("name"),
                thisJsonObj.getString("type"),
                thisJsonObj.getString("id"));
        }
    }
}

class Hotel {
    @Nullable
    private String description;
    @Nullable
    private String country;
    @Nullable
    private String city;
    @Nullable
    private String name;
    @Nullable
    private String type;
    @Nullable
    private String id;

    public Hotel(
        @Nullable String description,
        @Nullable String country,
        @Nullable String city,
        @Nullable String name,
        @Nullable String type,
        @Nullable String id) {
        this.description = description;
        this.country = country;
        this.city = city;
        this.name = name;
        this.type = type;
        this.id = id;
    }

    @Nullable
    public final String getDescription() { return this.description; }

    public final void setDescription(@Nullable String var1) { this.description = var1; }

    @Nullable
    public final String getCountry() { return this.country; }

    public final void setCountry(@Nullable String var1) { this.country = var1; }

    @Nullable
    public final String getCity() { return this.city; }

    public final void setCity(@Nullable String var1) { this.city = var1; }

    @Nullable
    public final String getName() { return this.name; }

    public final void setName(@Nullable String var1) { this.name = var1; }

    @Nullable
    public final String getType() { return this.type; }

    public final void setType(@Nullable String var1) { this.type = var1; }

    @Nullable
    public final String getId() { return this.id; }

    public final void setId(@Nullable String var1) { this.id = var1; }

    @NotNull
    @Override
    public String toString() {
        return "Hotel(description=" + this.description + ", country=" + this.country
            + ", city=" + this.city + ", " + "name=" + this.name + ", type=" + this.type + ", id=" + this.id + ")";
    }

    @Override
    public int hashCode() { return Objects.hash(description, country, city, name, type, id); }

    @Override
    public boolean equals(Object o) {
        if (this == o) { return true; }
        if (!(o instanceof Hotel)) { return false; }
        Hotel hotel = (Hotel) o;
        return Objects.equals(description, hotel.description)
            && Objects.equals(country, hotel.country)
            && Objects.equals(city, hotel.city)
            && Objects.equals(name, hotel.name)
            && Objects.equals(type, hotel.type)
            && Objects.equals(id, hotel.id);
    }
}



// MODULE_END --/Users/ianbridge/CouchbaseDocs/bau/cbl/modules/java/examples/snippets/src/main/java/com/couchbase/code_snippets/JSONExamples.java 

