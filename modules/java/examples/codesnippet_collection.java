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

import com.couchbase.lite.CouchbaseLite;


public class Application {
    public static void main(String... args) {}

    public void testInitializer() {
        // tag::sdk-initializer[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init();
        // end::sdk-initializer[]
    }
}
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
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import com.couchbase.lite.ClientCertificateAuthenticator;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.ListenerCertificateAuthenticator;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;


@SuppressWarnings("unused")
public class JavaListenerExamples {
    private Replicator thisReplicator;
    private URLEndpointListener thisListener;

    public void listenerConfigTlsIdFullExample(File keyFile, Set<Collection> collections)
        throws CouchbaseLiteException, IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException {
        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]

        // Import a key pair from a file into a keystore
        // Create a TLSIdentity from the imported key-pair
        // This only needs to happen once.  Once the key is in the internal store
        // it can be referenced using its alias
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        try (InputStream keyStream = Files.newInputStream(keyFile.toPath())) { // <.>
            keyStore.load(keyStream, "skerit".toCharArray());
        }

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(collections);
        config.setTlsIdentity(TLSIdentity.getIdentity(keyStore, "test-alias", "keyPass".toCharArray())); // <.>
        // end::listener-config-tls-id-caCert[]

        // end::listener-config-tls-id-set[]
        // end::listener-config-tls-id-full[]
    }

    public void listenerConfigClientAuthLambdaExample(KeyStore keyStore, URLEndpointListenerConfiguration thisConfig)
        throws CouchbaseLiteException {
        // tag::listener-config-client-auth-lambda[]
        // Configure authentication using application logic
        final TLSIdentity thisCorpId = TLSIdentity.getIdentity(keyStore, "OurCorp", "sekrit".toCharArray()); // <.>
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

        thisListener = new URLEndpointListener(thisConfig);

        // end::listener-config-client-auth-lambda[]
    }

    public void listenerConfigClientAuthRootExample(KeyStore keyStore, URLEndpointListenerConfiguration thisConfig)
        throws CouchbaseLiteException {
        // tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Configure the client authenticator
        // to validate using ROOT CA
        // thisClientID.certs is a list containing a client cert to accept
        // and any other certs needed to complete a chain between the client cert
        // and a CA
        final TLSIdentity validId =
            TLSIdentity.getIdentity(keyStore, "OurCorp", "sekrit".toCharArray());  // get the identity <.>
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
            keyStore,
            "couchbase-docs-cert",
            "sekrit".toCharArray()
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

        TLSIdentity identity = TLSIdentity.getIdentity(keyStore, "OurCorp", "sekrit".toCharArray());
        if (identity == null) { throw new IllegalStateException("Cannot find corporate id"); }
        config.setPinnedServerX509Certificate((X509Certificate) identity.getCerts().get(0)); // <.>

        // end::p2p-act-rep-config-cacert-pinned[]


        // end::p2p-act-rep-config-tls-full[]
        // tag::p2p-tlsid-tlsidentity-with-label[]
        // Provide a client certificate to the server for authentication
        TLSIdentity clientId = TLSIdentity.getIdentity(keyStore, "client", "squirrel".toCharArray());
        if (clientId == null) { throw new IllegalStateException("Cannot find client id"); }
        config.setAuthenticator(new ClientCertificateAuthenticator(clientId)); // <.>

        // ... other replicator configuration

        Replicator repl = new Replicator(config);
        repl.start();
        thisReplicator = repl;
        // end::p2p-tlsid-tlsidentity-with-label[]
    }
}
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

import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.Array;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;


@SuppressWarnings("unused")
public class BasicExamples {
    public class SupportingDatatypes {
        private final File rootDir;

        public SupportingDatatypes(@NotNull File rootDir) { this.rootDir = rootDir; }

        public void datatypeUsage() throws CouchbaseLiteException {
            // tag::datatype_usage[]
            // tag::datatype_usage_createdb[]
            // Get the database (and create it if it doesn’t exist).
            Database database = new Database("getting-started");
            try (Collection collection = database.getCollection("myCollection")) {
                if (collection == null) { throw new IllegalStateException("collection not found"); }

                // end::datatype_usage_createdb[]
                // tag::datatype_usage_createdoc[]
                // Create your new document
                MutableDocument mutableDoc = new MutableDocument();

                // end::datatype_usage_createdoc[]
                // tag::datatype_usage_mutdict[]
                // Create a new mutable dictionary and populate some keys/values
                MutableDictionary address = new MutableDictionary();
                address.setString("street", "1 Main st.");
                address.setString("city", "San Francisco");
                address.setString("state", "CA");
                address.setString("country", "USA");
                address.setString("code", "90210");

                // end::datatype_usage_mutdict[]
                // tag::datatype_usage_mutarray[]
                // Create and populate mutable array
                MutableArray phones = new MutableArray();
                phones.addString("650-000-0000");
                phones.addString("650-000-0001");

                // end::datatype_usage_mutarray[]
                // tag::datatype_usage_populate[]
                // Initialize and populate the document

                // Add document type to document properties <.>
                mutableDoc.setString("type", "hotel");

                // Add hotel name string to document properties <.>
                mutableDoc.setString("name", "Hotel Java Mo");

                // Add float to document properties <.>
                mutableDoc.setFloat("room_rate", 121.75F);

                // Add dictionary to document's properties <.>
                mutableDoc.setDictionary("address", address);

                // Add array to document's properties <.>
                mutableDoc.setArray("phones", phones);

                // end::datatype_usage_populate[]
                // tag::datatype_usage_persist[]
                // Save the document changes <.>
                collection.save(mutableDoc);
                // end::datatype_usage_persist[]
            }

            // tag::datatype_usage_closedb[]
            // Close the database <.>
            database.close();

            // end::datatype_usage_closedb[]

            // end::datatype_usage[]
        }

        public void useExplicitType(Collection collection, Document someDoc) throws CouchbaseLiteException {
            // tag::fleece-data-encoding[]
            Document doc = collection.getDocument(someDoc.getId());
            // force longVal to be type Long, even if it could be represented as an int.
            long longVal = doc.getLong("test");
            // end::fleece-data-encoding[]
        }

        public void datatypeDictionary(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_dictionary[]
            // NOTE: No error handling, for brevity (see getting started)
            Document document = collection.getDocument("doc1");
            if (document == null) { return; }

            // Getting a dictionary from the document's properties
            Dictionary dict = document.getDictionary("address");
            if (dict == null) { return; }

            // Access a value with a key from the dictionary
            String street = dict.getString("street");

            // Iterate dictionary
            for (String key: dict.getKeys()) {
                System.out.println("Key " + key + " = " + dict.getValue(key));
            }

            // Create a mutable copy
            MutableDictionary mutableDict = dict.toMutable();

            // end::datatype_dictionary[]
        }

        public void datatypeMutableDictionary(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_mutable_dictionary[]
            // NOTE: No error handling, for brevity (see getting started)

            // Create a new mutable dictionary and populate some keys/values
            MutableDictionary mutableDict = new MutableDictionary();
            mutableDict.setString("street", "1 Main st.");
            mutableDict.setString("city", "San Francisco");

            // Add the dictionary to a document's properties and save the document
            MutableDocument mutableDoc = new MutableDocument("doc1");
            mutableDoc.setDictionary("address", mutableDict);
            collection.save(mutableDoc);

            // end::datatype_mutable_dictionary[]
        }

        public void datatypeArray(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_array[]
            // NOTE: No error handling, for brevity (see getting started)

            Document document = collection.getDocument("doc1");
            if (document == null) { return; }

            // Getting a phones array from the document's properties
            Array array = document.getArray("phones");
            if (array == null) { return; }

            // Get element count
            int count = array.count();

            // Access an array element by index
            String phone = array.getString(1);

            // Iterate array
            for (int i = 0; i < count; i++) {
                System.out.println("Row  " + i + " = " + array.getString(i));
            }

            // Create a mutable copy
            MutableArray mutableArray = array.toMutable();
            // end::datatype_array[]
        }

        public void datatypeMutableArray(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_mutable_array[]
            // NOTE: No error handling, for brevity (see getting started)

            // Create a new mutable array and populate data into the array
            MutableArray mutableArray = new MutableArray();
            mutableArray.addString("650-000-0000");
            mutableArray.addString("650-000-0001");

            // Set the array to document's properties and save the document
            MutableDocument mutableDoc = new MutableDocument("doc1");
            mutableDoc.setArray("phones", mutableArray);
            collection.save(mutableDoc);
            // end::datatype_mutable_array[]
        }
    }
}

//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http:        //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.codesnippets;

import java.util.Set;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Scope;
import com.couchbase.lite.ValueIndexConfiguration;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "UnusedAssignment"})
public class CollectionExamples {
    // We need to add a code sample to create a new collection in a scope
    public void createCollectionInScope(Database db)
        throws CouchbaseLiteException {
        // tag::scopes-manage-create-collection[]
        // create the collection "Verlaine" in the default scope ("_default")
        Collection collection1 = db.createCollection("Verlaine");
        // both of these retrieve collection1 created above
        collection1 = db.getCollection("Verlaine");
        collection1 = db.getDefaultScope().getCollection("Verlaine");

        // create the collection "Verlaine" in the scope "Television"
        Collection collection2 = db.createCollection("Television", "Verlaine");
        // both of these retrieve  collection2 created above
        collection2 = db.getCollection("Television", "Verlaine");
        collection2 = db.getScope("Television").getCollection("Verlaine");
        // end::scopes-manage-create-collection[]
    }

    // We need to add a code sample to index a collection
    public void createIndexInCollection(Collection collection) throws CouchbaseLiteException {
        // tag::scopes-manage-index-collection[]
        // Create an index named "nameIndex1" on the property "lastName" in the collection using the IndexBuilder
        collection.createIndex("nameIndex1", IndexBuilder.valueIndex(ValueIndexItem.property("lastName")));

        // Create a similar index named "nameIndex2" using and IndexConfiguration
        collection.createIndex("nameIndex2", new ValueIndexConfiguration("lastName"));

        // get the names of all the indices in the collection
        final Set<String> indices = collection.getIndexes();

        // delete all the collection indices
        for (String index: indices) { collection.deleteIndex(index); }
        // end::scopes-manage-index-collection[]
    }

    // We need to add a code sample to drop a collection
    public void deleteCollection(Database db, String collectionName, String scopeName)
        throws CouchbaseLiteException {
        // tag::scopes-manage-drop-collection[]
        Collection collection = db.getCollection(collectionName, scopeName);
        if (collection != null) { db.deleteCollection(collection.getName(), collection.getScope().getName()); }
        // end::scopes-manage-drop-collection[]
    }

    // We need to add a code sample to list scopes and collections
    public void listScopesAndCollections(Database db) throws CouchbaseLiteException {
        // tag::scopes-manage-list[]
        final Set<Scope> scopes = db.getScopes();
        for (Scope scope: scopes) {
            Logger.log("Scope :: " + scope.getName());
            final Set<Collection> collections = scope.getCollections();
            for (Collection collection: collections) {
                Logger.log("    Collection :: " + collection.getName());
            }
        }
        // end::scopes-manage-list[]
    }
}
package com.couchbase.codesnippets;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.codesnippets.utils.Utils;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
import com.couchbase.lite.Conflict;
import com.couchbase.lite.ConflictResolver;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.EncryptionKey;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.Expression;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogFileConfiguration;
import com.couchbase.lite.LogLevel;
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
import com.couchbase.lite.PredictiveModel;
import com.couchbase.lite.ProtocolType;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorConnection;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.URLEndpoint;


@SuppressWarnings({"unused", "ConstantConditions"})
public class Examples {
    private static final String DB_NAME = "getting-started";
    private static final String DB_NAME2 = "other";

    public void oneXAttachmentsExample(Database database) {
        Document document = new MutableDocument();
        // tag::1x-attachment[]
        Dictionary attachments = document.getDictionary("_attachments");
        Blob blob = attachments != null ? attachments.getBlob("avatar") : null;
        byte[] content = blob != null ? blob.getContent() : null;
        // end::1x-attachment[]
    }

    public void newDatabaseExample() throws CouchbaseLiteException {
        final String customDir = "/foo/bar";
        // tag::new-database[]
        Database database = new Database(DB_NAME);
        // end::new-database[]

        // tag::close-database[]
        database.close();
        // end::close-database[]

        database.delete();
    }

    public void databaseFullSyncExample() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        // tag::database-fullsync[]
        config.setFullSync(true);
        // end::database-fullsync[]
    }

    public void databaseEncryptionExample() throws CouchbaseLiteException {
        // tag::database-encryption[]
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setEncryptionKey(new EncryptionKey("PASSWORD"));
        Database database = new Database(DB_NAME, config);
        // end::database-encryption[]
    }

    public void loggingExample() {
        // tag::logging[]

        // Set the overall logging level
        Database.log.getConsole().setLevel(LogLevel.DEBUG);

        // Enable or disable specific domains
        Database.log.getConsole().setDomains(LogDomain.REPLICATOR, LogDomain.QUERY);
        // end::logging[]
    }

    public void enableCustomLoggingExample() {
        // tag::set-custom-logging[]
        Database.log.setCustom(new LogTestLogger(LogLevel.WARNING)); // <.>
        // end::set-custom-logging[]
    }

    public void consoleLoggingExample() {
        // tag::console-logging[]
        Database.log.getConsole().setLevel(LogLevel.DEBUG); // <.>
        // end::console-logging[]

        // tag::console-logging-db[]
        Database.log.getConsole().setLevel(LogLevel.DEBUG); // <.>
        // end::console-logging-db[]
    }

    public void fileLoggingExample() {
        // tag::file-logging[]
        LogFileConfiguration LogCfg = new LogFileConfiguration(
            (System.getProperty("user.dir") + "/MyApp/logs")); // <.>
        LogCfg.setMaxSize(10240); // <.>
        LogCfg.setMaxRotateCount(5); // <.>
        LogCfg.setUsePlaintext(false); // <.>
        Database.log.getFile().setConfig(LogCfg);
        Database.log.getFile().setLevel(LogLevel.INFO); // <.>
        // end::file-logging[]
    }

    public void preBuiltDatabaseExample(Database database) throws IOException, CouchbaseLiteException {
        final File appDbDir = new File(database.getPath());

        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        if (!Database.exists("travel-sample", appDbDir)) {
            File tmpDir = new File(System.getProperty("java.io.tmpdir"));
            ZipUtils.unzip(Utils.getAsset("travel-sample.cblite2.zip"), tmpDir);
            File path = new File(tmpDir, "travel-sample");
            Database.copy(path, "travel-sample", new DatabaseConfiguration());
        }
        // end::prebuilt-database[]
    }

    public void initializersExample(Collection collection) throws CouchbaseLiteException {
        // tag::initializer[]
        MutableDocument newTask = new MutableDocument();
        newTask.setString("type", "task");
        newTask.setString("owner", "todo");
        newTask.setDate("createdAt", new Date());
        collection.save(newTask);
        // end::initializer[]
    }

    public void mutabilityExample(Collection collection) throws CouchbaseLiteException {
        // tag::update-document[]
        MutableDocument mutableDocument = collection.getDocument("xyz").toMutable();
        mutableDocument.setString("name", "apples");
        collection.save(mutableDocument);
        // end::update-document[]
    }

    public void typedAccessorsExample() {
        MutableDocument newTask = new MutableDocument();

        // tag::date-getter[]
        newTask.setValue("createdAt", new Date());
        Date date = newTask.getDate("createdAt");
        // end::date-getter[]
    }

    public void batchOperationsExample(Database database, Collection collection) throws CouchbaseLiteException {
        // tag::batch[]
        database.inBatch(() -> {
            for (int i = 0; i < 10; i++) {
                MutableDocument doc = new MutableDocument();
                doc.setValue("type", "user");
                doc.setValue("name", "user " + i);
                doc.setBoolean("admin", false);
                collection.save(doc);
            }
        });
        // end::batch[]
    }

    public void DocumentExpiration(Collection collection) throws CouchbaseLiteException {
        // tag::document-expiration[]
        // Purge the document one day from now
        Instant ttl = Instant.now().plus(1, ChronoUnit.DAYS);
        collection.setDocumentExpiration("doc123", new Date(ttl.toEpochMilli()));

        // Reset expiration
        collection.setDocumentExpiration("doc1", null);

        // Query documents that will be expired in less than five minutes
        Instant fiveMinutesFromNow = Instant.now().plus(5, ChronoUnit.MINUTES);
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Meta.expiration.lessThan(Expression.doubleValue(fiveMinutesFromNow.toEpochMilli())));
        // end::document-expiration[]
    }

    public void documentChangeListenerExample(Collection collection) {
        // tag::document-listener[]
        collection.addDocumentChangeListener(
            "user.john",
            change -> {
                String docId = change.getDocumentID();
                try {
                    Document doc = collection.getDocument(docId);
                    if (doc != null) {
                        Logger.log("Status: " + doc.getString("verified_account"));
                    }
                }
                catch (CouchbaseLiteException e) {
                    Logger.log("Failed getting doc : " + docId);
                }
            });
        // end::document-listener[]
    }

    public void blobsExample(Collection collection) throws IOException, CouchbaseLiteException {
        MutableDocument newTask = new MutableDocument();

        // tag::blob[]
        try (InputStream is = Utils.getAsset("avatar.jpg")) { // <.>
            Blob blob = new Blob("image/jpeg", is);  // <.>
            newTask.setBlob("avatar", blob); // <.>
            collection.save(newTask);

            Blob taskBlob = newTask.getBlob("avatar");
            byte[] bytes = taskBlob.getContent();
        }
        // end::blob[]
    }

    public void replicationStatusExample(Collection collection) throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);
        config.setType(ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);

        // tag::replication-status[]
        replicator.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == ReplicatorActivityLevel.STOPPED) {
                Logger.log("Replication stopped");
            }
        });
        // end::replication-status[]

        replicator.close();
    }

    public void replicationPendingDocsExample(Collection collection) throws URISyntaxException, CouchbaseLiteException {
        final Endpoint endpoint =
            new URLEndpoint(new URI("ws://localhost:4984/db"));

        final ReplicatorConfiguration config =
            new ReplicatorConfiguration(endpoint)
                .setType(ReplicatorType.PUSH);
        config.addCollection(collection, null);

        // tag::replication-push-pendingdocumentids[]
        Replicator replicator = new Replicator(config);
        final Set<String> pendingDocs =
            replicator.getPendingDocumentIds(collection); // <.>
        // end::replication-push-pendingdocumentids[]

        replicator.close();
    }

    public void saveWithCustomConflictResolverExample(Collection collection) throws CouchbaseLiteException {
        // tag::update-document-with-conflict-handler[]
        Document doc = collection.getDocument("xyz");
        if (doc == null) { return; }
        MutableDocument mutableDocument = doc.toMutable();
        mutableDocument.setString("name", "apples");

        collection.save(
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

    public void queryAccessJsonExample() throws CouchbaseLiteException, JsonProcessingException {
        Database database = new Database("hotels");

        Collection collection = database.getDefaultCollection();
        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection));

        // tag::query-access-json[]
        ObjectMapper mapper = new ObjectMapper();
        ArrayList<Hotel> hotels = new ArrayList<>();
        HashMap<String, Object> dictFromJSONstring;

        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {

                // Get result as JSON string
                String thisJsonString = result.toJSON(); // <.>

                // Get Java  Hashmap from JSON string
                dictFromJSONstring =
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
        }
        // end::query-access-json[]

        database.close();
    }
}


@SuppressWarnings({"unused", "ConstantConditions"})
// tag::predictive-model[]
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

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::ziputils-unzip[]
class ZipUtils {
    public static void unzip(InputStream src, File dst) throws IOException {
        byte[] buffer = new byte[1024];
        try (InputStream in = src; ZipInputStream zis = new ZipInputStream(in)) {
            ZipEntry ze = zis.getNextEntry();
            while (ze != null) {
                File newFile = new File(dst, ze.getName());
                if (ze.isDirectory()) { newFile.mkdirs(); }
                else {
                    new File(newFile.getParent()).mkdirs();
                    try (FileOutputStream fos = new FileOutputStream(newFile)) {
                        int len;
                        while ((len = zis.read(buffer)) > 0) { fos.write(buffer, 0, len); }
                    }
                }
                ze = zis.getNextEntry();
            }
            zis.closeEntry();
        }
    }
}
// end::ziputils-unzip[]

@SuppressWarnings("unused")

// tag::custom-logging[]
class LogTestLogger implements com.couchbase.lite.Logger {
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


@SuppressWarnings("unused")
class TensorFlowModel {
    public static Map<String, Object> predictImage(byte[] data) {
        return null;
    }
}
// end::predictive-model[]

@SuppressWarnings("unused")
// tag::local-win-conflict-resolver[]
class LocalWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getLocalDocument();
    }
}
// end::local-win-conflict-resolver[]

@SuppressWarnings("unused")
// tag::remote-win-conflict-resolver[]
class RemoteWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getRemoteDocument();
    }
}
// end::remote-win-conflict-resolver[]

@SuppressWarnings({"unused", "ConstantConditions"})
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

@SuppressWarnings({"unused", "ConstantConditions"})
class BrowserSessionManager implements MessageEndpointDelegate {
    private Replicator replicator;

    public void initCouchbase() throws CouchbaseLiteException {
        // tag::message-endpoint[]
        Database database = new Database("dbName");

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        MessageEndpoint messageEndpointTarget = new MessageEndpoint(
            "UID:123",
            "active",
            ProtocolType.MESSAGE_STREAM,
            this);
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(messageEndpointTarget);
        config.addCollection(database.getDefaultCollection(), null);

        // Create the replicator object.
        replicator = new Replicator(config);
        // Start the replication.
        replicator.start();
        // end::message-endpoint-replicator[]

        database.close();
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

@SuppressWarnings("unused")
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

@SuppressWarnings("unused")
// Check context validity for JVM cf Android
class PassivePeerConnection implements MessageEndpointConnection {
    private MessageEndpointListener messageEndpointListener;
    private ReplicatorConnection replicatorConnection;

    public void startListener() throws CouchbaseLiteException {
        // tag::listener[]
        Database database = new Database("dbName");
        MessageEndpointListenerConfiguration listenerConfiguration = new MessageEndpointListenerConfiguration(
            new HashSet<>(Arrays.asList(database.getDefaultCollection())),
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
        PassivePeerConnection connection = new PassivePeerConnection(); /* implements
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

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.RejectedExecutionHandler;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.Collection;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseEndpoint;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;


@SuppressWarnings("unused")
public class ExecutionPolicyExamples {
    private Replicator thisReplicator;
    private ListenerToken thisToken;

    // tag::execution-inorder[]
    private static final ExecutorService IN_ORDER_EXEC = Executors.newSingleThreadExecutor();

    /**
     * This version guarantees in order delivery and is parsimonious with space
     * The listener does not need to be thread safe (at least as far as this code is concerned).
     * It will run on only thread (the Executor's thread) and must return from a given call
     * before the next call commences.  Events may be delivered arbitrarily late, though,
     * depending on how long it takes the listener to run.
     */
    public void runInOrder(Collection collection, Database target) {
        Replicator repl = new Replicator(new ReplicatorConfiguration(new DatabaseEndpoint(target))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false));

        thisToken = repl.addChangeListener(IN_ORDER_EXEC, this::onChange);

        repl.start();
        thisReplicator = repl;
    }
    // end::execution-inorder[]


    // tag::execution-maxthroughput[]
    private static final ExecutorService MAX_THROUGHPUT_EXEC = Executors.newCachedThreadPool();

    /**
     * This version maximizes throughput.  It will deliver change notifications as quickly
     * as CPU availability allows. It may deliver change notifications out of order.
     * Listeners must be thread safe because they may be called from multiple threads.
     * In fact, they must be re-entrant because a given listener may be running on mutiple threads
     * simultaneously.  In addition, when notifications swamp the processors, notifications awaiting
     * a processor will be queued as Threads, (instead of as Runnables) with accompanying memory
     * and GC impact.
     */
    public void runMaxThroughput(Collection collection, Database target) {
        Replicator repl = new Replicator(new ReplicatorConfiguration(new DatabaseEndpoint(target))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false));

        thisToken = repl.addChangeListener(MAX_THROUGHPUT_EXEC, this::onChange);

        repl.start();
        thisReplicator = repl;
    }
    // end::execution-maxthroughput[]


    // tag::execution-policied[]
    private static final int CPUS = Runtime.getRuntime().availableProcessors();

    private static final AtomicReference<ThreadPoolExecutor> BACKUP_EXEC = new AtomicReference<>();

    private static final RejectedExecutionHandler BACKUP_EXECUTION = (r, e) -> {
        ExecutorService exec = BACKUP_EXEC.get();
        if (exec != null) {
            exec.execute(r);
            return;
        }

        BACKUP_EXEC.compareAndSet(null, createBackupExecutor());
        BACKUP_EXEC.get().execute(r);
    };

    private static ThreadPoolExecutor createBackupExecutor() {
        ThreadPoolExecutor exec = new ThreadPoolExecutor(
            CPUS + 1,
            2 * CPUS + 1,
            30, TimeUnit.SECONDS,
            new LinkedBlockingQueue<>());
        exec.allowCoreThreadTimeOut(true);
        return exec;
    }

    private static final ThreadPoolExecutor STANDARD_EXEC = new ThreadPoolExecutor(
        CPUS + 1,
        2 * CPUS + 1,
        30, TimeUnit.SECONDS,
        new SynchronousQueue<>());
    static { STANDARD_EXEC.setRejectedExecutionHandler(BACKUP_EXECUTION); }
    /**
     * This version demonstrates the extreme configurability of the Couchbase Lite replicator callback system.
     * It may deliver updates out of order and does require thread-safe and re-entrant listeners
     * (though it does correctly synchronize tasks passed to it using a SynchronousQueue).
     * The thread pool executor shown here is configured for the sweet spot for number of threads per CPU.
     * In a real system, this single executor might be used by the entire application and be passed to
     * this module, thus establishing a reasonable app-wide threading policy.
     * In an emergency (Rejected Execution) it lazily creates a backup executor with an unbounded queue
     * in front of it.  It, thus, may deliver notifications late, as well as out of order.
     */
    public void runExecutionPolicy(Collection collection, Database target, ReplicatorChangeListener listener) {
        Replicator repl = new Replicator(new ReplicatorConfiguration(new DatabaseEndpoint(target))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false));

        thisToken = repl.addChangeListener(STANDARD_EXEC, this::onChange);

        repl.start();
        thisReplicator = repl;
    }
    // end::execution-policied[]

    private void onChange(ReplicatorChange change) { }
}

package com.couchbase.codesnippets;

import java.util.Objects;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;


public class Hotel {
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

    public Hotel() { }

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
}//
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
package com.couchbase.codesnippets;

import java.util.Map;

import org.json.JSONException;
import org.json.JSONObject;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Array;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
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
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;


@SuppressWarnings({"unused", "ConstantConditions"})
public class JSONExamples {
    public static final String JSON
        = "[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\","
        + "\"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},"
        + "{\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\","
        + "\"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},"
        + "{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\","
        + "\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\","
        + "\"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]";

    public void jsonArrayExample(Collection collection) throws CouchbaseLiteException {
        // tag::tojson-array[]
        // github tag=tojson-array
        final MutableArray mArray = new MutableArray(JSON); // <.>

        for (int i = 0; i < mArray.count(); i++) { // <.>
            final Dictionary dict = mArray.getDictionary(i);
            Logger.log(dict.getString("name"));
            collection.save(new MutableDocument(dict.getString("id"), dict.toMap()));
        }

        final Array features = collection.getDocument("1002").getArray("features");
        for (Object feature: features.toList()) { Logger.log(feature.toString()); }
        Logger.log(features.toJSON()); // <.>
        // end::tojson-array[]
    }

    public void jsonBlobExample(Collection collection) throws CouchbaseLiteException {
        // tag::tojson-blob[]
        // github tag=tojson-blob
        final Map<String, ?> thisBlob = collection.getDocument("thisdoc-id").toMap();
        if (!Blob.isBlob(thisBlob)) { return; }

        final String blobType = thisBlob.get("content_type").toString();
        final Number blobLength = (Number) thisBlob.get("length");
        // end::tojson-blob[]
    }

    public void jsonDictionaryExample(Database db) {
        // tag::tojson-dictionary[]
        // github tag=tojson-dictionary
        final MutableDictionary mDict = new MutableDictionary(JSON); // <.>
        Logger.log(mDict.toString());

        Logger.log("Details for: " + mDict.getString("name"));
        for (String key: mDict.getKeys()) {
            Logger.log(key + " => " + mDict.getValue(key));
        }
        // end::tojson-dictionary[]
    }

    public void jsonDocumentExample(Collection srcColl, Collection dstColl) throws CouchbaseLiteException {
        // tag::tojson-document[]
        // github tag=tojson-document
        final Query listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.collection(srcColl));

        try (ResultSet results = listQuery.execute()) {
            for (Result row: results) {
                final String thisId = row.getString("metaId");

                final String json = srcColl.getDocument(thisId).toJSON(); // <.>
                Logger.log("JSON String = " + json);

                final MutableDocument hotelFromJSON = new MutableDocument(thisId, json); // <.>

                dstColl.save(hotelFromJSON);

                for (Map.Entry<String, Object> entry: dstColl.getDocument(thisId).toMap().entrySet()) {
                    Logger.log(entry.getKey() + " => " + entry.getValue()); // <.>
                }
            }
        }
        // end::tojson-document[]
    }

    public void jsonQueryExample(Query query) throws CouchbaseLiteException, JSONException {
        try (ResultSet results = query.execute()) {
            for (Result row: results) {

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
}

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

import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.util.Arrays;
import java.util.Set;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.ListenerPasswordAuthenticator;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;


@SuppressWarnings("unused")
class ListenerExamples {
    private URLEndpointListener thisListener;

    public void passiveListenerExample(Set<Collection> collections, String validUser, char[] validPass)
        throws CouchbaseLiteException {
        // EXAMPLE 1
        // tag::listener-initialize[]
        // tag::listener-config-db[]
        // Initialize the listener config
        final URLEndpointListenerConfiguration thisConfig
            = new URLEndpointListenerConfiguration(collections); // <.>

        // end::listener-config-db[]
        // tag::listener-config-port[]
        thisConfig.setPort(55990); //<.>

        // end::listener-config-port[]
        // tag::listener-config-netw-iface[]
        thisConfig.setNetworkInterface("wlan0"); // <.>

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
            (username, password) ->
                username.equals(validUser) && Arrays.equals(password, validPass)));

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

    public void listenerStatusCheckExample(URLEndpointListener thisListener) {
        // tag::listener-status-check[]
        int connectionCount =
            thisListener.getStatus().getConnectionCount(); // <.>

        int activeConnectionCount =
            thisListener.getStatus().getActiveConnectionCount();  // <.>

        // end::listener-status-check[]
    }

    public void listenerStopExample() {

        // tag::listener-stop[]
        thisListener.stop();

        // end::listener-stop[]
    }

    public void deleteIdentityExample(String alias)
        throws KeyStoreException, CertificateException, IOException, NoSuchAlgorithmException {
        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        KeyStore thisKeyStore = KeyStore.getInstance("AndroidKeyStore");
        thisKeyStore.load(null);
        thisKeyStore.deleteEntry(alias);

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]
    }

    public void listenerGetNetworkInterfacesExample(Set<Collection> collections) throws CouchbaseLiteException {
        // tag::listener-get-network-interfaces[]
        final URLEndpointListener listener
            = new URLEndpointListener(
            new URLEndpointListenerConfiguration(collections));
        listener.start();
        thisListener = listener;
        Logger.log("URLS are " + thisListener.getUrls());

        // end::listener-get-network-interfaces[]
    }

    public void listenerSimpleExample(Set<Collection> collections, String validUser, char[] validPass)
        throws CouchbaseLiteException {
        // tag::listener-simple[]
        final URLEndpointListenerConfiguration thisConfig =
            new URLEndpointListenerConfiguration(collections); // <.>

        thisConfig.setAuthenticator(
            new ListenerPasswordAuthenticator(
                (username, password) ->
                    validUser.equals(username) && Arrays.equals(validPass, password)
            )
        ); // <.>

        final URLEndpointListener thisListener =
            new URLEndpointListener(thisConfig); // <.>

        thisListener.start(); // <.>

        // end::listener-simple[]
    }
}
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

import java.util.HashMap;
import java.util.Map;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.PredictionFunction;
import com.couchbase.lite.PredictiveIndex;
import com.couchbase.lite.PredictiveModel;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "ConstantConditions"})
public class PredictiveQueryExamples {

    // tag::predictive-model[]
    // tensorFlowModel is a fake implementation
    // this would be the implementation of the ml model you have chosen
    public static class TensorFlowModel {
        public static Map<String, Object> predictImage(byte[] data) {
            return null;
        }
    }

    public static class ImageClassifierModel implements PredictiveModel {
        @Override
        public Dictionary predict(@NonNull Dictionary input) {
            Blob blob = input.getBlob("photo");

            // tensorFlowModel is a fake implementation
            // this would be the implementation of the ml model you have chosen
            return (blob == null)
                ? null
                : new MutableDictionary(TensorFlowModel.predictImage(blob.getContent())); // <1>
        }
    }
    // end::predictive-model[]


    public void predictiveModelExamples(Collection collection) throws CouchbaseLiteException {
        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", new ImageClassifierModel());
        // end::register-model[]

        // tag::predictive-query-value-index[]
        collection.createIndex(
            "value-index-image-classifier",
            IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label"))));
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier");
        // end::unregister-model[]
    }

    public void predictiveIndexExamples(Collection collection) throws CouchbaseLiteException {
        // tag::predictive-query-predictive-index[]
        Map<String, Object> inputMap = new HashMap<>();
        inputMap.put("numbers", Expression.property("photo"));
        Expression input = Expression.map(inputMap);

        PredictiveIndex index = IndexBuilder.predictiveIndex("ImageClassifier", input, null);
        collection.createIndex("predictive-index-image-classifier", index);
        // end::predictive-query-predictive-index[]
    }

    public void predictiveQueryExamples(Collection collection) throws CouchbaseLiteException {
        // tag::predictive-query[]
        Map<String, Object> inputProperties = new HashMap<>();
        inputProperties.put("photo", Expression.property("photo"));
        Expression input = Expression.map(inputProperties);
        PredictionFunction prediction = Function.prediction("ImageClassifier", input); // <1>

        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("label").equalTo(Expression.string("car"))
                .and(prediction.propertyPath("probability").greaterThanOrEqualTo(Expression.doubleValue(0.8))));

        // Run the query.
        try (ResultSet result = query.execute()) {
            Logger.log("Number of rows: " + result.allResults().size());
        }
        // end::predictive-query[]
    }
}
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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jetbrains.annotations.NotNull;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.ArrayFunction;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.FullTextFunction;
import com.couchbase.lite.FullTextIndexConfiguration;
import com.couchbase.lite.FullTextIndexItem;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Join;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Meta;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Parameters;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.ValueIndexConfiguration;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "ConstantConditions", "UnusedAssignment"})
public class QueryExamples {
    public void indexingExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-index[]
        collection.createIndex("TypeNameIndex", new ValueIndexConfiguration("type", "name"));
        // end::query-index[]
    }

    public void selectStatementExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-select-props[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("type"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.expression(Meta.id));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("hotel id -> " + result.getString("id"));
                Logger.log("hotel name -> " + result.getString("name"));
            }
        }
        // end::query-select-props[]
    }

    public void whereStatementExample(Collection collection) throws CouchbaseLiteException {
        final String collectionName = "theStuff";

        // tag::query-where[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .limit(Expression.intValue(10));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Dictionary all = result.getDictionary(collectionName);
                Logger.log("name -> " + all.getString("name"));
                Logger.log("type -> " + all.getString("type"));
            }
        }
        // end::query-where[]
    }

    public void collectionStatementExample(Collection collection) throws CouchbaseLiteException {

        // tag::query-collection-operator-contains[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("public_likes"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))
                .and(ArrayFunction
                    .contains(Expression.property("public_likes"), Expression.string("Armani Langworth"))));
        try (ResultSet results = query.execute()) {
            for (Result result: results) {
                Logger.log("public_likes -> " + result.getArray("public_likes").toList());
            }
        }
        // end::query-collection-operator-contains[]
    }

    public void patternMatchingExample(Collection collection) throws CouchbaseLiteException {

        // tag::query-like-operator[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("royal engineers museum"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("name -> " + result.getString("name"));
            }
        }
        // end::query-like-operator[]
    }

    public void wildcardMatchExample(Collection collection) throws CouchbaseLiteException {

        // tag::query-like-operator-wildcard-match[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("eng%e%"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("name ->  " + result.getString("name"));
            }
        }
        // end::query-like-operator-wildcard-match[]
    }

    public void wildCharacterMatchExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-like-operator-wildcard-character-match[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("eng____r"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("name -> " + result.getString("name"));
            }
        }
        // end::query-like-operator-wildcard-character-match[]
    }

    public void regexMatchExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-regex-operator[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).regex(Expression.string("\\beng.*r\\b"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("name -> " + result.getString("name"));
            }
        }
        // end::query-regex-operator[]
    }

    public void queryDeletedDocumentsExample(Collection collection) {

        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Meta.deleted);
        // end::query-deleted-documents[]
    }

    public void joinStatementExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-join[]
        Query query = QueryBuilder.select(
                SelectResult.expression(Expression.property("name").from("airline")),
                SelectResult.expression(Expression.property("callsign").from("airline")),
                SelectResult.expression(Expression.property("destinationairport").from("route")),
                SelectResult.expression(Expression.property("stops").from("route")),
                SelectResult.expression(Expression.property("airline").from("route")))
            .from(DataSource.collection(collection).as("airline"))
            .join(Join.join(DataSource.collection(collection).as("route"))
                .on(Meta.id.from("airline").equalTo(Expression.property("airlineid").from("route"))))
            .where(Expression.property("type").from("route").equalTo(Expression.string("route"))
                .and(Expression.property("type").from("airline").equalTo(Expression.string("airline")))
                .and(Expression.property("sourceairport").from("route").equalTo(Expression.string("RIX"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log(result.toMap().toString());
            }
        }
        // end::query-join[]
    }

    public void groupByStatementExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-groupby[]
        Query query = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))),
                SelectResult.property("country"),
                SelectResult.property("tz"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("airport"))
                .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300))))
            .groupBy(
                Expression.property("country"),
                Expression.property("tz"))
            .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending());

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log(String.format(
                    "There are %d airports on the %s timezone located in %s and above 300ft",
                    result.getInt("$1"),
                    result.getString("tz"),
                    result.getString("country")));
            }
        }
        // end::query-groupby[]
    }

    public void orderByStatementExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-orderby[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.property("name").ascending())
            .limit(Expression.intValue(10));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log(result.toMap().toString());
            }
        }
        // end::query-orderby[]
    }

    public void querySyntaxAllExample(Collection collection) throws CouchbaseLiteException {

        // tag::query-syntax-all[]
        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection));
        // end::query-syntax-all[]

        // tag::query-access-all[]
        Map<String, Hotel> hotels = new HashMap<>();
        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {
                // get the k-v pairs from the 'hotel' key's value into a dictionary
                Dictionary docsProp = result.getDictionary(0); // <.>
                String docsId = docsProp.getString("id");
                String docsName = docsProp.getString("Name");
                String docsType = docsProp.getString("Type");
                String docsCity = docsProp.getString("City");

                // Alternatively, access results value dictionary directly
                final Hotel hotel = new Hotel();
                hotel.setId(result.getDictionary(0).getString("id")); // <.>
                hotel.setType(result.getDictionary(0).getString("Type"));
                hotel.setName(result.getDictionary(0).getString("Name"));
                hotel.setCity(result.getDictionary(0).getString("City"));
                hotel.setCountry(result.getDictionary(0).getString("Country"));
                hotel.setDescription(result.getDictionary(0).getString("Description"));
                hotels.put(hotel.getId(), hotel);
            }
        }
        // end::query-access-all[]
    }


    public void querySyntaxIdExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-syntax-id[]
        Query listQuery =
            QueryBuilder.select(SelectResult.expression(Meta.id).as("metaID"))
                .from(DataSource.collection(collection));
        // end::query-syntax-id[]

        // tag::query-access-id[]
        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs.allResults()) {

                // get the ID form the result's k-v pair array
                String thisDocsId = result.getString("metaID"); // <.>

                // Get document from DB using retrieved ID
                Document thisDoc = collection.getDocument(thisDocsId);

                // Process document as required
                String thisDocsName = thisDoc.getString("Name");
            }
        }
        // end::query-access-id[]
    }

    public void querySyntaxCountExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-syntax-count-only[]
        Query listQuery = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
            .from(DataSource.collection(collection));
        // end::query-syntax-count-only[]

        // tag::query-access-count-only[]
        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {

                // Retrieve count using key 'mycount'
                Integer altDocId = result.getInt("mycount");

                // Alternatively, use the index
                Integer orDocId = result.getInt(0);
            }
        }

        // Or even leave out the for-loop altogether
        int resultCount;
        try (ResultSet resultSet = listQuery.execute()) {
            resultCount = resultSet.next().getInt("mycount");
        }
        // end::query-access-count-only[]
    }

    public void querySyntaxPropsExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-syntax-props[]

        Query listQuery =
            QueryBuilder.select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("Name"),
                    SelectResult.property("Type"),
                    SelectResult.property("City"))
                .from(DataSource.collection(collection));

        // end::query-syntax-props[]

        // tag::query-access-props[]
        HashMap<String, Hotel> hotels = new HashMap<>();
        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {

                // get data direct from result k-v pairs
                final Hotel hotel = new Hotel();
                hotel.setId(result.getString("id"));
                hotel.setType(result.getString("Type"));
                hotel.setName(result.getString("Name"));
                hotel.setCity(result.getString("City"));

                // Store created hotel object in a hashmap of hotels
                hotels.put(hotel.getId(), hotel);

                // Get result k-v pairs into a 'dictionary' object
                Map<String, Object> thisDocsProps = result.toMap();
                String docId =
                    thisDocsProps.getOrDefault("id", null).toString();
                String docName =
                    thisDocsProps.getOrDefault("Name", null).toString();
                String docType =
                    thisDocsProps.getOrDefault("Type", null).toString();
                String docCity =
                    thisDocsProps.getOrDefault("City", null).toString();
            }
        }
        // end::query-access-props[]
    }

    public void inOperatorExample(Collection collection) throws CouchbaseLiteException {

        // tag::query-collection-operator-in[]
        Expression[] values = new Expression[] {
            Expression.property("first"),
            Expression.property("last"),
            Expression.property("username")
        };

        Query query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.string("Armani").in(values));
        // end::query-collection-operator-in[]

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log(result.toMap().toString());
            }
        }
    }

    // tag::query-syntax-pagination-all[]
    public void queryPaginationExample(Collection collection) {
        // tag::query-syntax-pagination[]

        int thisOffset = 0;
        int thisLimit = 20;

        Query listQuery =
            QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .limit(
                    Expression.intValue(thisLimit),
                    Expression.intValue(thisOffset)); // <.>

        // end::query-syntax-pagination[]

    }
    // end::query-syntax-pagination-all[]


    public void selectAllExample(Collection collection) {
        // tag::query-select-all[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")));
        // end::query-select-all[]

    }

    public void LiveQueryExample(Collection collection) {
        // tag::live-query[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection)); // <.>

        // Adds a query change listener.
        // Changes will be posted on the main queue.
        ListenerToken token = query.addChangeListener(change -> { // <.>
            for (Result result: change.getResults()) {
                Logger.log("results: " + result.getKeys());
                /* Update UI */
            }
        });

        // end::live-query[]

        // tag::stop-live-query[]
        token.remove(); // <.>
        // end::stop-live-query[]
    }

    public void metaFunctionExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-select-meta[]
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("airport")))
            .orderBy(Ordering.expression(Meta.id));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("airport id -> " + result.getString("id"));
                Logger.log("airport id -> " + result.getString(0));
            }
        }
        // end::query-select-meta[]
    }

    // tag::query-explain[]
    public void explainAllExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-all[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("university")))
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").descending()); // <.>
        Logger.log(query.explain()); // <.>
        // end::query-explain-all[]
    }

    public void explainLikeExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-like[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").like(Expression.string("%hotel%"))) // <.>
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").descending()); // <.>
        Logger.log(query.explain());
        // end::query-explain-like[]
    }

    public void explainNoPFXExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-nopfx[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                .and(Expression.property("name").like(Expression.string("%royal%"))));
        Logger.log(query.explain());
        // end::query-explain-nopfx[]
    }

    public void explainFnExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-function[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))); // <.>
        Logger.log(query.explain());
        // end::query-explain-function[]
    }

    public void explainNoFnExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-nofunction[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))); // <.>
        Logger.log(query.explain());
        // end::query-explain-nofunction[]
    }
    // end::query-explain[]

    public void prepareIndexExample(Collection collection) throws CouchbaseLiteException {
        // tag::fts-index[]
        FullTextIndexConfiguration config = new FullTextIndexConfiguration("Overview").ignoreAccents(false);
        collection.createIndex("overviewFTSIndex", config);
        // end::fts-index[]
    }

    public void prepareIndexQueryBuilderExample(Collection collection) throws CouchbaseLiteException {
        // tag::fts-index_Querybuilder[]
        collection.createIndex(
            "overviewFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("overviewFTSIndex")).ignoreAccents(false));
        // end::fts-index_Querybuilder[]
    }

    public void indexingQueryBuilderExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-index_Querybuilder[]
        collection.createIndex(
            "TypeNameIndex",
            IndexBuilder.valueIndex(
                ValueIndexItem.property("type"),
                ValueIndexItem.property("name")));
        // end::query-index_Querybuilder[]
    }

    public void ftsExample(Collection collection) throws CouchbaseLiteException {
        final Database database = null;
        // tag::fts-query[]
        Query ftsQuery =
            database.createQuery(
                "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK"
                    + "(overviewFTSIndex)");


        try (ResultSet resultSet = ftsQuery.execute()) {
            for (Result result: resultSet) {
                Logger.log(result.getString("id") + ": " + result.getString("overview"));
            }
        }
        // end::fts-query[]
    }

    public void ftsQueryBuilderExample(Collection collection) throws CouchbaseLiteException {
        // tag::fts-query_Querybuilder[]
        Expression whereClause = FullTextFunction.match(
            Expression.fullTextIndex("overviewFTSIndex"),
            "'michigan'");
        Query ftsQuery =
            QueryBuilder.select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("overview"))
                .from(DataSource.collection(collection))
                .where(whereClause);


        try (ResultSet resultSet = ftsQuery.execute()) {
            for (Result result: resultSet) {
                Logger.log(result.getString("id") + ": " + result.getString("overview"));
            }
        }
        // end::fts-query_Querybuilder[]
    }

    public void querySyntaxJsonExample(@NotNull Collection collection)
        throws CouchbaseLiteException, JsonProcessingException {
        // tag::query-syntax-json[]
        // Example assumes Hotel class object defined elsewhere
        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection));
        // end::query-syntax-json[]
        // tag::query-access-json[]
        // Uses Jackson JSON processor
        ObjectMapper mapper = new ObjectMapper();
        List<Hotel> hotels = new ArrayList<>();

        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs) {
                String json = result.toJSON();
                Map<String, String> dictFromJSONstring = mapper.readValue(json, HashMap.class);

                String hotelId = dictFromJSONstring.get("id");
                String hotelType = dictFromJSONstring.get("type");
                String hotelname = dictFromJSONstring.get("name");

                // Get custom object from JSON string
                Hotel thisHotel = mapper.readValue(json, Hotel.class);
                hotels.add(thisHotel);
            }
        }
    }

    public List<Map<String, Object>> docsOnlyQuerySyntaxN1QL(Database thisDb) throws CouchbaseLiteException {
        // For Documentation -- N1QL Query using parameters
        // tag::query-syntax-n1ql[]
        //  Declared elsewhere: Database thisDb
        Query thisQuery =
            thisDb.createQuery(
                "SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.>
        List<Map<String, Object>> results = new ArrayList<>();
        try (ResultSet rs = thisQuery.execute()) {
            for (Result result: rs) { results.add(result.toMap()); }
        }
        return results;
        // end::query-syntax-n1ql[]
    }

    public List<Map<String, Object>> docsonlyQuerySyntaxN1QLParams(Database thisDb) throws CouchbaseLiteException {
        // For Documentation -- N1QL Query using parameters
        // tag::query-syntax-n1ql-params[]
        //  Declared elsewhere: Database thisDb

        Query thisQuery =
            thisDb.createQuery(
                "SELECT META().id AS thisId FROM _ WHERE type = $type"); // <.

        thisQuery.setParameters(
            new Parameters().setString("type", "hotel")); // <.>

        List<Map<String, Object>> results = new ArrayList<>();
        try (ResultSet rs = thisQuery.execute()) {
            for (Result result: rs) { results.add(result.toMap()); }
        }
        return results;
        // end::query-syntax-n1ql-params[]
    }
}

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


