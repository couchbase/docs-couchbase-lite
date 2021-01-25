// PASSIVE PEER STUFF
// Stuff I adapted
//
// BEGIN new stuff 90420temp cache
private URLEndpointListener createListener() {
  final URLEndpointListenerConfiguration listenerConfig = new URLEndpointListenerConfiguration(db);

  listenerConfig.setDisableTls(false);

  listenerConfig.setEnableDeltaSync(true);

  listenerConfig.setTlsIdentity(null); // Use with anonymous self signed cert

  listenerConfig.setAuthenticator(new ListenerPasswordAuthenticator(this::isWhitelistedUser));

  return new URLEndpointListener(listenerConfig);
}

private void startListener(@NotNull URLEndpointListener listener) {
  executor.submit(() -> {
      CouchbaseLiteException err = null;
      try { listener.start(); }
      catch (CouchbaseLiteException e) { err = e; }
      onStart(err);
  });
}

private void stopListener(@NotNull URLEndpointListener listener) {
  listener.stop();
}
// END new stuff 90420temp cache



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
URI uri = null;
try {
    uri = new URI("wss://10.0.2.2:4984/db");
} catch (URISyntaxException e) {
    e.printStackTrace();
}
Endpoint theListenerEndpoint = new URLEndpoint(uri); // <.>

ReplicatorConfiguration thisConfig =
  new ReplicatorConfiguration(database, theListenerEndpoint); // <.>

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
// EXAMPLE 1
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
    // tag::listener-config-tls-full[]
    // Configure server security
    // tag::listener-config-tls-enable[]
    thisConfig.setDisableTls(false); // <.>

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
final URLEndpointListenerConfigurationthisConfig =
  URLEndpointListenerConfiguration(database: self.oDB)
final URLEndpointListener thisListener
  = new URLEndpointListener(thisConfig);
thisListener.start()
Log.i(TAG, "URLS are " + thisListener.getUrls();

// end::listener-get-network-interfaces[]



// tag::listener-local-db[]
// . . . preceding application logic . . .
CouchbaseLite.init(context); <.>
Database thisDB = new Database("passivepeerdb");

// end::listener-local-db[]

// tag::listener-config-tls-disable[]
thisConfig.setDisableTls(true); // <.>

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
    );

  // end::listener-config-tls-id-caCert[]

  // tag::listener-config-tls-id-SelfSigned[]
  // Use a self-signed certificate
  // Create a TLSIdentity for the server using convenience API.
  // System generates self-signed cert
  // Work-in-progress. Code snippet coming soon.
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
    // tag::getting-started[]
    // tag::p2p-act-rep-initialize[]
    // initialize the replicator configuration
    final ReplicatorConfiguration thisConfig
       = new ReplicatorConfiguration(
          thisDB,
          URLEndpoint(URI("wss://listener.com:8954"))); // <.>

    // end::p2p-act-rep-initialize[]
    // tag::p2p-act-rep-config-type[]
    // Set replicator type
    thisConfig.setReplicatorType(
      ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);

    // end::p2p-act-rep-config-type[]
    // tag::p2p-act-rep-config-cont[]
    // Configure Sync Mode
    thisConfig.setContinuous(false); // default value

    // end::p2p-act-rep-config-cont[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Authentication --
    // only accept self-signed certs
    thisConfig.setAcceptOnlySelfSignedServerCertificate(true); // <.>

    // end::p2p-act-rep-config-self-cert[]
    // tag::p2p-act-rep-auth[]
    // Configure the credentials the
    // client will provide if prompted
    final BasicAuthenticator thisAuth
      = new BasicAuthenticator(
          "Our Username",
          "Our PasswordValue")); // <.>

    thisConfig.setAuthenticator(thisAuth)

    // end::p2p-act-rep-auth[]
    // tag::p2p-act-rep-config-conflict[]
    /* Optionally set custom conflict resolver call back */
    thisConfig.setConflictResolver( /* define resolver function */); // <.>

    // end::p2p-act-rep-config-conflict[]
    // tag::p2p-act-rep-start-full[]
    // Create replicator
    // Consider holding a reference somewhere
    // to prevent the Replicator from being GCed
    final Replicator thisReplicator = new Replicator(thisConfig); // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-add-change-listener-label[]
    // Optionally add a change listener <.>
    // end::p2p-act-rep-add-change-listener-label[]
    ListenerToken thisListener =
      new thisReplicator.addChangeListener(change -> {
        final CouchbaseLiteException err =
         change.getStatus().getError();
         if (err != null) {
           Log.i(TAG, "Error code ::  " + err.getCode(), e);
         }
      });

    // end::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-start[]
    // Start replicator
    thisReplicator.start(false); // <.>

    // end::p2p-act-rep-start[]
    // end::p2p-act-rep-start-full[]
    // end::p2p-act-rep-func[]         ***** End p2p-act-rep-func
  }
}

// BEGIN additional snippets
    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security
    // -- only accept CA attested certs
    thisConfig.setAcceptOnlySelfSignedServerCertificate(false); // <.>

    // end::p2p-act-rep-config-cacert[]
    // tag::p2p-act-rep-config-pinnedcert[]

    // Return the remote pinned cert (the listener's cert)
    byte returnedCert
     = new byte(thisConfig.getPinnedCertificate()); // Get listener cert if pinned
    // end::p2p-act-rep-config-pinnedcert[]

    // end::p2p-act-rep-config-tls-full[]
    // tag::p2p-tlsid-tlsidentity-with-label[]
    // ... other replicator configuration
    // Provide a client certificate to the server for authentication
    final TLSIdentity thisClientId = TLSIdentity.getIdentity("clientId"); // <.>

    if (thisClientId == null) { throw new IllegalStateException("Cannot find client id"); }

    thisConfig.setAuthenticator(new ClientCertificateAuthenticator(thisClientId)); // <.>
    // ... other replicator configuration
    final thisReplicator= new Replicator(thisConfig);

    // end::p2p-tlsid-tlsidentity-with-label[]
    // tag::p2p-act-rep-config-cacert-pinned[]

    // Use the pinned certificate from the byte array (cert)
    thisConfig.setPinnedServerCertificate(cert.getEncoded()); // <.>

    // end::p2p-act-rep-config-cacert-pinned[]

// END additional snippets







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
    // String validUser = new String("Our Username"); // an example username
    // String validPassword = new String("Our PasswordValue"); // an example password

    // ListenerPasswordAuthenticator thisAuth = new ListenerPasswordAuthenticator( // <.>
    //   validUser, validPassword -> validUser == "validUsername" && validPassword == "Our PasswordValue" );

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
<.> Configure the pinned certificate using data from the byte array `cert`
// end::p2p-act-rep-config-cacert-pinned-callouts[]

// tag::p2p-tlsid-tlsidentity-with-label-callouts[]
<.> Attempt to get the identity from secure storage
<.> Set the authenticator to ClientCertificateAuthenticator and configure it to use the retrieved identity

// end::p2p-tlsid-tlsidentity-with-label-callouts[]




    // thisConfig.setAuthenticator(
    // new ListenerCertificateAuthenticator(certs));


        // tag::beta-listener-config-tls-id-caCert[]
    // Use CA Cert
    // Create a TLSIdentity from a key-pair and
    // certificate in Android's canonical keystore
    TLSIdentity thisIdentity = new TLSIdentity.getIdentity("server"); // <.>

    // end::beta-listener-config-tls-id-caCert[]





Blakes submitted example

public URLEndpointListener getTuesdayListener() throws CouchbaseLiteException {
  final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(new Database("sharedDb"));
  final TLSIdentity thisCorpId = TLSIdentity.getIdentity("OurCorp");
  if (thisCorpId == null) { throw new IllegalStateException("Cannot find corporate id"); }
  thisConfig.setTlsIdentity(thisCorpId);
  thisConfig.setAuthenticator(new ListenerCertificateAuthenticator(
    (thisCorpId.getCerts()) -> {
    // user supplied logic that resolves to boolean
    // true=valid, false=invalid
    });
  final ULEndpointListener thisListener = new URLEndpointListener(thisConfig);
}

private boolean tuesdaysAreGood(List<Certificate> certificates) {
  return Calendar.getInstance().get(Calendar.DAY_OF_WEEK) == Calendar.TUESDAY;
}


/ For replications

// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
class MyClass {
  Database database;
  Replicator replicator; // <.>

  void startReplication() {
      URI uri = null;
      try {
          uri = new URI("wss://10.0.2.2:4984/db"); // <.>
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
<.> The URL scheme for remote database URLs uses `ws:`, or `wss:` for SSL/TLS connections over wb sockets.
In this example the hostname is `10.0.2.2` because the Android emulator runs in a VM that is generally accessible on `10.0.2.2` from the host machine (see https://developer.android.com/studio/run/emulator-networking[Android Emulator networking] documentation).
+
NOTE: As of Android Pie, version 9, API 28, cleartext support is disabled, by default.
Although `wss:` protocol URLs are not affected, in order to use the `ws:` protocol, applications must target API 27 or lower, or must configure application network security as described https://developer.android.com/training/articles/security-config#CleartextTrafficPermitted[here].

// end::sgw-repl-pull-callouts[]


    // tag::sgw-act-rep-initialize[]
    // initialize the replicator configuration
    final ReplicatorConfiguration thisConfig
       = new ReplicatorConfiguration(
          thisDB,
          URLEndpoint(URI("wss://10.0.2.2:8954/travel-sample"))); // <.>

    // end::sgw-act-rep-initialize[]