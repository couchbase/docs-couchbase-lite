//
// Program.cs
//
// Copyright (c) 2017 Couchbase, Inc All rights reserved.
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
using Couchbase.Lite;
using Couchbase.Lite.DI;
using Couchbase.Lite.Enterprise.Query;
using Couchbase.Lite.Logging;
using Couchbase.Lite.P2P;
using Couchbase.Lite.Query;
using Couchbase.Lite.Sync;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net.NetworkInformation;
using System.Security;
using System.Security.Cryptography.X509Certificates;

namespace api_walkthrough
{
    class Hotel
    {
        public string Id { get; set; }

        public string Name { get; set; }
    }

    class Program
    {
        private static readonly Database _Database = null;
        private static readonly Replicator _Replicator = null;
        private static readonly URLEndpointListener _listener = null;

        public void GettingStarted()
        {
            // tag::getting-started[]

            // using System;
            // using Couchbase.Lite;
            // using Couchbase.Lite.Query;
            // using Couchbase.Lite.Sync;

            // Get the database (and create it if it doesn't exist)
            var database = new Database("mydb");
            var collection = database.GetDefaultCollection();

            // Create a new document (i.e. a record) in the database
            var id = default(string);
            using var createdDoc = new MutableDocument();
            createdDoc.SetFloat("version", 2.0f)
                .SetString("type", "SDK");

            // Save it to the database
            collection.Save(createdDoc);
            id = createdDoc.Id;

            // Update a document
            using var doc = collection.GetDocument(id);
            using var mutableDoc = doc.ToMutable();
            createdDoc.SetString("language", "C#");
            collection.Save(createdDoc);

            using var docAgain = collection.GetDocument(id);
            Console.WriteLine($"Document ID :: {docAgain.Id}");
            Console.WriteLine($"Learning {docAgain.GetString("language")}");


            // Create a query to fetch documents of type SDK
            // i.e. SELECT * FROM database WHERE type = "SDK"
            using var query = QueryBuilder.Select(SelectResult.All())
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("SDK")));

            // Run the query
            var result = query.Execute();
            Console.WriteLine($"Number of rows :: {result.AllResults().Count}");

            // Create replicator to push and pull changes to and from the cloud
            var targetEndpoint = new URLEndpoint(new Uri("ws://localhost:4984/getting-started-db"));
            var replConfig = new ReplicatorConfiguration(targetEndpoint);
            replConfig.AddCollection(database.GetDefaultCollection());

            // Add authentication
            replConfig.Authenticator = new BasicAuthenticator("john", "pass");

            // Create replicator (make sure to add an instance or static variable
            // named _Replicator)
            var replicator = new Replicator(replConfig);
            replicator.AddChangeListener((sender, args) =>
            {
                if (args.Status.Error != null) {
                    Console.WriteLine($"Error :: {args.Status.Error}");
                }
            });

            replicator.Start();

            // Later, stop and dispose the replicator *before* closing/disposing the database

            // end::getting-started[]
        }

        private static void TestReplicatorConflictResolver()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::replication-conflict-resolver[]
            var target = new URLEndpoint(new Uri("ws://localhost:4984/mydatabase"));
            var replConfig = new ReplicatorConfiguration(target);
            replConfig.AddCollection(collection, new CollectionConfiguration()
            {
                ConflictResolver = new LocalWinConflictResolver()
            });

            var replicator = new Replicator(replConfig);
            replicator.Start();
            // end::replication-conflict-resolver[]
        }

        private static void TestSaveWithConflictHandler()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::update-document-with-conflict-handler[]
            using var doc = collection.GetDocument("xyz");
            using var mutableDoc = doc.ToMutable();
            mutableDoc.SetString("name", "apples");
            collection.Save(mutableDoc, (updated, current) =>
            {
                var currentDict = current.ToDictionary();
                var newDict = updated.ToDictionary();
                var result = newDict.Concat(currentDict)
                    .GroupBy(kv => kv.Key)
                    .ToDictionary(g => g.Key, g => g.First().Value);
                updated.SetData(result);
                return true;
            });
            // end::update-document-with-conflict-handler[]
        }

        private static bool IsValidCredential(string name, SecureString password) { return true; } // helper
        private static void TestInitListener()
        {
            var database = new Database("other-database");
            var collection = database.GetDefaultCollection();

#warning init-urllistener Unused?
            // tag::init-urllistener[]
            var endpointConfig = new URLEndpointListenerConfiguration(new[] { collection });
            endpointConfig.TlsIdentity = null; // Use with anonymous self-signed cert
            endpointConfig.Authenticator = new ListenerPasswordAuthenticator((sender, username, password) =>
            {
                if (IsValidCredential(username, password)) {
                    return true;
                }

                return false;
            });

            var listener = new URLEndpointListener(endpointConfig);
            // end::init-urllistener[]
        }

        private static void TestListenerStart()
        {
            var listener = _listener;
#warning start-urllistener Unused?
            // tag::start-urllistener[]
            // CouchbaseLiteException will be thrown when the listener cannot be started. The most common error
            // would be that the configured port has already been used.
            listener.Start();
            // end::start-urllistener[]
        }

        private static void TestListenerStop()
        {
            var listener = _listener;
#warning stop-urllistener Unused?
            // tag::stop-urllistener[]
            listener.Stop();
            // end::stop-urllistener[]
        }

        private static void TestCreateSelfSignedCert()
        {
            X509Store store =
             new X509Store(StoreName.My);
            // The identity will be stored in the secure
            // storage using the given label.
            DateTimeOffset fiveMinToExpireCert = DateTimeOffset.UtcNow.AddMinutes(5);

            // tag::create-self-signed-cert[]
            // tag::listener-config-tls-id-SelfSigned[]
            var identity = TLSIdentity.CreateIdentity(true, /* isServer */
                new Dictionary<string, string>() { { Certificate.CommonNameAttribute, "Couchbase Inc" } },
                // The common name attribute is required
                // when creating a CSR. If it is not presented
                // in the cert, an exception is thrown.
                fiveMinToExpireCert,
                // If the expiration date is not specified,
                // the certs expiration will be 365 days
                store,
                "CBL-Server-Cert",
                null);  // The key label to get cert in certificate map.
                        // If null, the same default directory
                        // for a Couchbase Lite db is used for map.

            // end::listener-config-tls-id-SelfSigned[]
            // end::create-self-signed-cert[]
        }

        private static void TestImportTLSIdentity()
        {
            X509Store store = new X509Store(StoreName.My); // The identity will be stored in the secure storage using the given label
            byte[] data = File.ReadAllBytes("C:\\client.p12"); // PKCS12 data containing private key, public key, and certificates

            // tag::import-tls-identity[]
            // tag::listener-config-tls-id-caCert[]
            var identity = TLSIdentity.ImportIdentity(store,
                data,
                "123", // The password that is needed to access the certificate data
                "CBL-Client-Cert",
                null);  // The key label to get cert in certificate map.
                        // If null, the same default directory
                        // for a Couchbase Lite db is used for map.
            // end::listener-config-tls-id-caCert[]
            // end::import-tls-identity[]
        }

        private static void TestClientCertAuthenticatorRootCerts()
        {
            var otherDatabase = new Database("other-database");
            var collection = otherDatabase.GetDefaultCollection();

            X509Store store = new X509Store(StoreName.My);

#warning client-cert-authenticator-root-certs unused?
            // tag::client-cert-authenticator-root-certs[]
            byte[] caData, clientData;
            clientData = File.ReadAllBytes("C:\\client.p12"); // PKCS12 data containing private key, public key, and certificates
            caData = File.ReadAllBytes("C:\\client-ca.der");

            // Root certs
            var rootCert = new X509Certificate2(caData);
            var auth = new ListenerCertificateAuthenticator(new X509Certificate2Collection(rootCert));

            // Create URL Endpoint Listener
            var listenerConfig = new URLEndpointListenerConfiguration(new[] { collection });
            listenerConfig.DisableTLS = false; //The default value is false which means that the TLS will be enabled by default.
            listenerConfig.Authenticator = auth;
            var listener = new URLEndpointListener(listenerConfig);
            listener.Start();

            // Client identity
            var identity = TLSIdentity.ImportIdentity(store,
                clientData,
                "123",
                "CBL-Client-Cert",
                null);

            // Replicator -- Client
            var database = new Database("client-database");
            var builder = new UriBuilder(
                "wss",
                "localhost",
                listener.Port,
                $"/{listener.Config.Collections.First().Name}"
            );

            var url = builder.Uri;
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(target);
            config.AddCollection(database.GetDefaultCollection());
            config.ReplicatorType = ReplicatorType.PushAndPull;
            config.Continuous = false;
            config.Authenticator = new ClientCertificateAuthenticator(identity);
            config.AcceptOnlySelfSignedServerCertificate = true;
            config.PinnedServerCertificate = _listener.TlsIdentity.Certs[0];
            var replicator = new Replicator(config);
            replicator.Start(); // Dispose after stop
            

            // Stop listener after replicator is stopped
            listener.Stop();
            // end::client-cert-authenticator-root-certs[]
        }

        private static void TestClientCertAuthenticator()
        {
            var otherDatabase = new Database("other-database");
            var collection = otherDatabase.GetDefaultCollection();

            X509Store store = new X509Store(StoreName.My);

#warning client-cert-authenticator unused?
            // tag::client-cert-authenticator[]

            // Create Listener Certificate Authenticator
            var auth = new ListenerCertificateAuthenticator((sender, cert) =>
            {
                if (cert.Count != 1) {
                    return false;
                }

                return cert[0].SubjectName.Name?.Replace("CN=", "") == "couchbase";
            });

            // Create URL Endpoint Listener
            var listenerConfig = new URLEndpointListenerConfiguration(new[] { collection  });
            listenerConfig.DisableTLS = false; //The default value is false which means that the TLS will be enabled by default.
            listenerConfig.Authenticator = auth;
            var listener = new URLEndpointListener(listenerConfig);
            listener.Start();

            // User Identity
            var identity = TLSIdentity.CreateIdentity(false,
                new Dictionary<string, string>() { { Certificate.CommonNameAttribute, "couchbase" } },
                null,
                store,
                "ClientCertLabel",
                null);

            // Replicator -- Client
            var database = new Database("client-database");
            var builder = new UriBuilder(
                "wss",
                "localhost",
                listener.Port,
                $"/{listener.Config.Collections.First().Name}"
            );

            var url = builder.Uri;
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(target);
            config.AddCollection(database.GetDefaultCollection());
            config.ReplicatorType = ReplicatorType.PushAndPull;
            config.Continuous = false;
            config.Authenticator = new ClientCertificateAuthenticator(identity);
            config.AcceptOnlySelfSignedServerCertificate = false;
            config.PinnedServerCertificate = _listener.TlsIdentity.Certs[0];
            var replicator = new Replicator(config);
            replicator.Start(); // Dispose after stopped

            // Stop listener after replicator is stopped
            listener.Stop();
            // end::client-cert-authenticator[]
        }

        public void IdentityWithLabel()
        {
            X509Store store = null;
            byte[] clientData = null;
            var replConfig = new ReplicatorConfiguration(null);

            // tag::p2p-tlsid-tlsidentity-with-label[]
            // Client identity
            var identity =
              TLSIdentity.ImportIdentity(store,
                clientData,
                "123",
                "CBL-Client-Cert",
                null); // <.>

            replConfig.Authenticator =
              new ClientCertificateAuthenticator(identity); // <.>

            // end::p2p-tlsid-tlsidentity-with-label[]
        }

        public void UseEncryption()
        {
            // Enterprise edition only

            // tag::database-encryption[]
            // Create a new, or open an existing database with encryption enabled
            var config = new DatabaseConfiguration
            {
                // Or, derive a key yourself and pass a byte array of the proper size
                EncryptionKey = new EncryptionKey("password")
            };

            using var database = new Database("seekrit", config);

            // Change the encryption key (or add encryption if the DB is unencrypted)
            database.ChangeEncryptionKey(new EncryptionKey("betterpassw0rd"));

            // Remove encryption
            database.ChangeEncryptionKey(null);
            // end::database-encryption[]
        }

        private static void ResetReplicatorCheckpoint()
        {
            var url = new Uri("ws://localhost:4984/db");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(target);
            bool resetCheckpointRequired_Example = true;
            config.AddCollection(_Database.GetDefaultCollection());
            var replicator = new Replicator(config);
            // tag::replication-reset-checkpoint[]
            // replicator is a Replicator instance
            if (resetCheckpointRequired_Example) {
                replicator.Start(true); // <.>
            } else { 
                replicator.Start(false);
            }

            // Stop and dispose replicator later
            // end::replication-reset-checkpoint[]
            
        }

        private static void Read1xAttachment()
        {
            using var doc = new MutableDocument();
            // tag::1x-attachment[]
            var attachments = doc.GetDictionary("_attachments");
            var avatar = attachments.GetBlob("avatar");
            var content = avatar?.Content;
            // end::1x-attachment[]
            
        }

        private static void CreateNewDatabase()
        {
            // tag::new-database[]
            var database = new Database("my-database");
            // end::new-database[]
        }

        private static void CloseDatabase()
        {
            var database = _Database;

            // tag::close-database[]
            database.Close();
            // end::close-database[]
        }

        private static void DatabaseFullsync()
        {
           var config = new DatabaseConfiguration(); 
           // tag::database-fullsync[] 
           // this enables fullsync
           config.FullSync = true;
           // end::database-fullsync[]
        }

        private static void CreateCollection() 
        {
            // tag::scopes-manage-create-collection[]
            var collectionWithDefaultScope = _Database.CreateCollection("colA");
            var collection = _Database.CreateCollection("colA", "scopeA"); // Scope with named scopeA will be created if it's not existed. There is no public API to create a Scope. 
            // end::scopes-manage-create-collection[]
        }

        private static void DeleteCollection()
        {
            // tag::scopes-manage-drop-collection[]
            _Database.DeleteCollection("colA", "scopeA"); // Scope with named scopeA will be deleted if there is no collections in the scope after the last collection is deleted via this API. There is no public API to remove a Scope.
            // end::scopes-manage-drop-collection[]
        }

        private static void ListCollectionsAndScopes()
        {
            // tag::scopes-manage-list[]
            // Get Scopes
            var scopes = _Database.GetScopes();
            // Get Collections of a Scope named scopeA
            var scopeA = _Database.GetScope("scopeA");
            var collectionsInScopeA = scopeA.GetCollections();
            // end::scopes-manage-list[]
        }

        private static void ChangeLogging()
        {
            // tag::logging[]
            // This sets the overall level of console logging
            Database.Log.Console.Level = LogLevel.Verbose;

            // This flag can enable and disable specific domains
            Database.Log.Console.Domains = LogDomain.Couchbase | LogDomain.Database;
            // end::logging[]
        }

        private static void LoadPrebuilt()
        {
            // tag::prebuilt-database[]
            // Note: Getting the path to a database is platform-specific.  For .NET Core / .NET Framework this
            // can be a simple filesystem path.  For UWP, you will need to get the path from your assets.  For
            // iOS you need to get the path from the main bundle.  For Android you need to extract it from your
            // assets to a temporary directory and then pass that path.
            var path = Path.Combine(Environment.CurrentDirectory, "travel-sample.cblite2" + Path.DirectorySeparatorChar);
            if (!Database.Exists("travel-sample", null)) {
                Database.Copy(path, "travel-sample", null);
            }
            // end::prebuilt-database[]
        }

        private static void QueryDeletedDocuments()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-deleted-documents[]
            // Query documents that have been deleted
            var query = QueryBuilder
                .Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Collection(collection))
                .Where(Meta.IsDeleted);
            // end::query-deleted-documents[]
        }

        private static void CreateDocument()
        {
            var collection = _Database.GetDefaultCollection();
            // tag::initializer[]
            using var mutableDoc = new MutableDocument("xyz");
            mutableDoc.SetString("type", "task")
                .SetString("owner", "todo")
                .SetDate("createdAt", DateTimeOffset.UtcNow);

            collection.Save(mutableDoc);
            // end::initializer[]
        }

        private static void UpdateDocument()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::update-document[]
            using var doc = collection.GetDocument("xyz");
            using var mutableDoc = doc.ToMutable();
            mutableDoc.SetString("name", "apples");
            collection.Save(mutableDoc);
            // end::update-document[]
        }

        private static void UseTypedAccessors()
        {
            using var mutableDoc = new MutableDocument();
            // tag::date-getter[]
            mutableDoc.SetValue("createdAt", DateTimeOffset.UtcNow);
            var date = mutableDoc.GetDate("createdAt");
            // end::date-getter[]

            Console.WriteLine(date);
        }

        private static void DoBatchOperation()
        {
            var database = _Database;
            var collection = database.GetDefaultCollection();
            // tag::batch[]
            database.InBatch(() =>
            {
                for (var i = 0; i < 10; i++) {
                    using var mutableDoc = new MutableDocument();
                    mutableDoc.SetString("type", "user");
                    mutableDoc.SetString("name", $"user {i}");
                    mutableDoc.SetBoolean("admin", false);
                    collection.Save(mutableDoc);
                    Console.WriteLine($"Saved user document {mutableDoc.GetString("name")}");
                }
            });
            // end::batch[]
        }

        private static void DatabaseChangeListener()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::document-listener[]
            collection.AddDocumentChangeListener("user.john", (sender, args) =>
            {
                using var doc = collection.GetDocument(args.DocumentID);
                Console.WriteLine($"Status :: {doc.GetString("verified_account")}");
            });
            // end::document-listener[]
        }

        private static void DocumentExpiration()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::document-expiration[]
            // Purge the document one day from now
            var ttl = DateTimeOffset.UtcNow.AddDays(1);
            collection.SetDocumentExpiration("doc123", ttl);

            // Reset expiration
            collection.SetDocumentExpiration("doc1", null);

            // Query documents that will be expired in less than five minutes
            var fiveMinutesFromNow = DateTimeOffset.UtcNow.AddMinutes(5).ToUnixTimeMilliseconds();
            using var query = QueryBuilder
                .Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Collection(collection))
                .Where(Meta.Expiration.LessThan(Expression.Double(fiveMinutesFromNow)));

            // end::document-expiration[]
        }

        private static void UseBlob()
        {
            var collection = _Database.GetDefaultCollection();
            using var newTask = new MutableDocument();
            // tag::blob[]
            // Note: Reading the data is implementation dependent, as with prebuilt databases
            var image = File.ReadAllBytes("avatar.jpg"); // <.>
            var blob = new Blob("image/jpeg", image); // <.>
            newTask.SetBlob("avatar", blob); // <.>
            collection.Save(newTask);
            // end::blob[]
        }

        public void CreateIndex()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-index[]
            // tag::scopes-manage-index-collection[]
            string[] indexProperties = new string[] { "type", "name" };
            var config = new ValueIndexConfiguration(indexProperties);
            collection.CreateIndex("TypeNameIndex", config);
            // end::scopes-manage-index-collection[]
            // end::query-index[]
        }

        public void CreateIndex_Querybuilder()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-index_Querybuilder[]
            // For value types, this is optional but provides performance enhancements
            var index = IndexBuilder.ValueIndex(
                ValueIndexItem.Expression(Expression.Property("type")),
                ValueIndexItem.Expression(Expression.Property("name"))); // <.>
            collection.CreateIndex("TypeNameIndex", index);
            // end::query-index_Querybuilder[]
        }
        private static void SelectMeta()
        {
            var collection = _Database.GetDefaultCollection();

#warning query-select-meta unused?
            // tag::query-select-meta[]
            // tag::query-select-props[]
            using var query = QueryBuilder.Select(
                SelectResult.Expression(Meta.ID),
                SelectResult.Property("type"),
                SelectResult.Property("name"))
            .From(DataSource.Collection(collection));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Document ID :: {result.GetString("id")}");
                Console.WriteLine($"Document Name :: {result.GetString("name")}");
            }
            // end::query-select-props[]
            // end::query-select-meta[]
        }

        private static void SelectAll()
        {
            var collection = _Database.GetDefaultCollection();

            {
                // tag::query-select-all[]
                using var query = QueryBuilder.Select(SelectResult.All())
                    .From(DataSource.Collection(collection));
                // end::query-select-all[]
            }

            {
                // tag::live-query[]
                var query = QueryBuilder
                    .Select(SelectResult.All())
                    .From(DataSource.Collection(collection)); // <.>


                // Adds a query change listener.
                // Changes will be posted on the main queue.
                var token = query.AddChangeListener((sender, args) => // <.>
                {
                    var allResult = args.Results.AllResults();
                    foreach (var result in allResult) {
                        Console.WriteLine(result.Keys);
                        /* Update UI */
                    }
                });
                // end::live-query[]

                // tag::stop-live-query[]
                query.RemoveChangeListener(token);
                query.Dispose();
                // end::stop-live-query[]
            }
        }

        private static void SelectWhere()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-where[]
            using var query = QueryBuilder.Select(SelectResult.All())
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("hotel")))
                .Limit(Expression.Int(10));

            foreach (var result in query.Execute()) {
                var dict = result.GetDictionary(collection.Name);
                Console.WriteLine($"Document Name :: {dict?.GetString("name")}");
            }
            // end::query-where[]
        }

        private static void UseCollectionContains()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-collection-operator-contains[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"),
                    SelectResult.Property("public_likes"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("hotel"))
                    .And(ArrayFunction.Contains(Expression.Property("public_likes"),
                        Expression.String("Armani Langworth"))));

            foreach (var result in query.Execute()) {
                var publicLikes = result.GetArray("public_likes");
                var jsonString = JsonConvert.SerializeObject(publicLikes);
                Console.WriteLine($"Public Likes :: {jsonString}");
            }
            // end::query-collection-operator-contains[]
        }

        private static void UseCollectionIn()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-collection-operator-in[]
            var values = new IExpression[]
                { Expression.Property("first"), Expression.Property("last"), Expression.Property("username") };

            using var query = QueryBuilder.Select(
                    SelectResult.All())
                .From(DataSource.Collection(collection))
                .Where(Expression.String("Armani").In(values));

            foreach (var result in query.Execute()) {
                var body = result.GetDictionary(0);
                var jsonString = JsonConvert.SerializeObject(body);
                Console.WriteLine($"In results :: {jsonString}");
            }
            
            // end::query-collection-operator-in[]
        }

        private static void SelectLike()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-like-operator[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Function.Lower(Expression.Property("name")).Like(Expression.String("Royal Engineers Museum"))))
                .Limit(Expression.Int(10));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Name Property :: {result.GetString("name")}");
            }
            // end::query-like-operator[]
        }

        private static void SelectWildcardLike()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-like-operator-wildcard-match[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Function.Lower(Expression.Property("name")).Like(Expression.String("Eng%e%"))))
                .Limit(Expression.Int(10));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Name Property :: {result.GetString("name")}");
            }
            // end::query-like-operator-wildcard-match[]
        }

        private static void SelectWildcardCharacterLike()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-like-operator-wildcard-character-match[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Expression.Property("name").Like(Expression.String("Royal Eng____rs Museum"))))
                .Limit(Expression.Int(10));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Name Property :: {result.GetString("name")}");
            }
            
            // end::query-like-operator-wildcard-character-match[]
        }

        private static void SelectRegex()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-regex-operator[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Expression.Property("name").Regex(Expression.String("\\bEng.*e\\b"))))
                .Limit(Expression.Int(10));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Name Property :: {result.GetString("name")}");
            }
            // end::query-regex-operator[]
        }

        private static void SelectJoin()
        {
            var collection = _Database.GetDefaultCollection();
            var collection2 = _Database.GetDefaultCollection();

            // tag::query-join[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Expression.Property("name").From("airline")),
                    SelectResult.Expression(Expression.Property("callsign").From("airline")),
                    SelectResult.Expression(Expression.Property("destinationairport").From("route")),
                    SelectResult.Expression(Expression.Property("stops").From("route")),
                    SelectResult.Expression(Expression.Property("airline").From("route")))
                .From(DataSource.Collection(collection).As("airline"))
                .Join(Join.InnerJoin(DataSource.Collection(collection2).As("route"))
                    .On(Meta.ID.From("airline").EqualTo(Expression.Property("airlineid").From("route"))))
                .Where(Expression.Property("type").From("route").EqualTo(Expression.String("route"))
                    .And(Expression.Property("type").From("airline").EqualTo(Expression.String("airline")))
                    .And(Expression.Property("sourceairport").From("route").EqualTo(Expression.String("RIX"))));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Name Property :: {result.GetString("name")}");
            }
            // end::query-join[]
        }

        private static void GroupBy()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-groupby[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Function.Count(Expression.All())),
                    SelectResult.Property("country"),
                    SelectResult.Property("tz"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("airport"))
                    .And(Expression.Property("geo.alt").GreaterThanOrEqualTo(Expression.Int(300))))
                .GroupBy(Expression.Property("country"), Expression.Property("tz"));

            foreach (var result in query.Execute()) {
                Console.WriteLine(
                    $"There are {result.GetInt("$1")} airports in the {result.GetString("tz")} timezone located in {result.GetString("country")} and above 300 ft");
            }
            // end::query-groupby[]
        }

        private static void OrderBy()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::query-orderby[]
            using var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("title"))
                .From(DataSource.Collection(collection))
                .Where(Expression.Property("type").EqualTo(Expression.String("hotel")))
                .OrderBy(Ordering.Property("title").Ascending())
                .Limit(Expression.Int(10));

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Title :: {result.GetString("title")}");
            }
            // end::query-orderby[]
        }

        private static void TestExplainStatement()
        {
            var collection = _Database.GetDefaultCollection();

            {
                // tag::query-explain-all[]
                using var query =
                  QueryBuilder
                    .Select(SelectResult.All())
                    .From(DataSource.Collection(collection))
                    .Where(Expression.Property("type").EqualTo(Expression.String("hotel")))
                    .GroupBy(Expression.Property("country"))
                    .OrderBy(Ordering.Property("title").Ascending()); // <.>

                Console.WriteLine(query.Explain()); // <.>
                // end::query-explain-all[]
            }

            {
                // tag::query-explain-like[]
                using var query =
                  QueryBuilder
                    .Select(SelectResult.All())
                    .From(DataSource.Collection(collection))
                    .Where(Expression.Property("type").Like(Expression.String("%hotel%"))
                      .And(Function.Lower(Expression.Property("name")).Like(Expression.String("%royal%")))); // <.>
                Console.WriteLine(query.Explain());
                // end::query-explain-like[]
            }

            {
                // tag::query-explain-nopfx[]
                using var query =
                  QueryBuilder
                    .Select(SelectResult.All())
                    .From(DataSource.Collection(collection))
                    .Where(Expression.Property("type").Like(Expression.String("hotel%"))
                      .And(Function.Lower(Expression.Property("name")).Like(Expression.String("%royal%")))); // <.>

                Console.WriteLine(query.Explain());
                // end::query-explain-nopfx[]
            }

            {
                // tag::query-explain-function[]
                using var query =
                  QueryBuilder
                    .Select(SelectResult.All())
                    .From(DataSource.Collection(collection))
                    .Where(Function.Lower(Expression.Property("type")).EqualTo(Expression.String("hotel"))); // <.>

                Console.WriteLine(query.Explain());
                // end::query-explain-function[]
            }

            {
                // tag::query-explain-nofunction[]
                using var query =
                  QueryBuilder
                    .Select(SelectResult.All())
                    .From(DataSource.Collection(collection))
                    .Where(Expression.Property("type").EqualTo(Expression.String("hotel"))); // <.>

                Console.WriteLine(query.Explain());
                // end::query-explain-nofunction[]
            }
        }

        public void CreateFullTextIndex()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::fts-index[]
            string[] indexProperties = new string[] { "overview", "name" };
            var config = new FullTextIndexConfiguration(indexProperties);
            collection.CreateIndex("overviewFTSIndex", config);
            // end::fts-index[]
        }

        public void FullTextSearch()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::fts-query[]
            var query = collection.CreateQuery("SELECT * FROM _ WHERE MATCH(overviewFTSIndex, 'Michigan') ORDER BY RANK(overviewFTSIndex)");
            foreach (var result in query.Execute()) {
                Console.WriteLine($"Document id {result.GetString(0)}");
            }
            // end::fts-query[]
        }


        private static void CreateFullTextIndex_Querybuilder()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::fts-index_Querybuilder[]
            var index = IndexBuilder.FullTextIndex(FullTextIndexItem.Property("overview")).IgnoreAccents(false);
            collection.CreateIndex("overviewFTSIndex", index);
            // end::fts-index_Querybuilder[]
        }

        private static void FullTextSearch_Querybuilder()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::fts-query_Querybuilder[]
            var whereClause = FullTextFunction.Match(Expression.FullTextIndex("overviewFTSIndex"), "'michigan'");

            using var query = QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Collection(collection))
                .Where(whereClause);

            foreach (var result in query.Execute()) {
                Console.WriteLine($"Document id {result.GetString(0)}");
            }
            // end::fts-query_Querybuilder[]
        }

        private static void StartReplication()
        {
            var collection = _Database.GetDefaultCollection();

#warning replication unused?
            // tag::replication[]
            // Note: Android emulator needs to use 10.0.2.2 for localhost (10.0.3.2 for GenyMotion)
            var url = new Uri("ws://localhost:4984/db");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(target)
            {
                ReplicatorType = ReplicatorType.Pull
            };
            config.AddCollection(collection);

            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication[]
        }

        private static void ConsoleLogging()
        {
            // tag::console-logging[]
            Database.Log.Console.Domains = LogDomain.All; // <.>
            Database.Log.Console.Level = LogLevel.Verbose; // <.>
            // end::console-logging[]

            // tag::console-logging-db[]
            Database.Log.Console.Domains = LogDomain.Database;
            // end::console-logging-db[]
        }

        private static void FileLogging()
        {
            // tag::file-logging[]
            var tempFolder = Path.Combine(Service.GetInstance<IDefaultDirectoryResolver>().DefaultDirectory(), "cbllog");
            var config = new LogFileConfiguration(tempFolder) // <.>
            {
                MaxRotateCount = 5, // <.>
                MaxSize = 10240, // <.>
                UsePlaintext = false  // <.>
            };
            Database.Log.File.Config = config; // Apply configuration
            Database.Log.File.Level = LogLevel.Info; // <.>
            // end::file-logging[]
        }

        private static void EnableCustomLogging()
        {
            // tag::set-custom-logging[]
            Database.Log.Custom = new LogTestLogger(); // <.>
           
            // You can also specify the level of logging the logger receives
            Database.Log.Custom = new LogTestLogger { Level = LogLevel.Warning };
            // end::set-custom-logging[]
        }

        private static void WriteConsoleLog()
        {
#warning write-console-logmsg unused?
            // tag::write-console-logmsg[]
            Database.Log.Console.Log(LogLevel.Warning, LogDomain.Replicator, "Any old log message");
            // end::write-console-logmsg[]
        }

        private static void WriteCustomLog()
        {
#warning write-custom-logmsg unused?
            // tag::write-custom-logmsg[]
            Database.Log.Custom?.Log(LogLevel.Warning, LogDomain.Replicator, "Any old log message");
            // end::write-custom-logmsg[]
        }

        private static void WriteFileLog()
        {
#warning write-file-logmsg unused?
            // tag::write-file-logmsg[]
            Database.Log.File.Log(LogLevel.Warning, LogDomain.Replicator, "Any old log message");
            // end::write-file-logmsg[]
        }

        private static void EnableBasicAuth()
        {
            var collection = _Database.GetDefaultCollection();

#warning basic-authentication unused?
            // tag::basic-authentication[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(target);
            config.AddCollection(collection);
            config.Authenticator = new BasicAuthenticator("john", "pass");

            var replicator = new Replicator(config);
            replicator.Start();
            // end::basic-authentication[]
        }

        private static void EnableSessionAuth()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::session-authentication[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(target);
            config.AddCollection(collection);
            config.Authenticator = new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447");

            var replicator = new Replicator(config);
            replicator.Start();
            // end::session-authentication[]
        }

        private static void SetupReplicatorListener()
        {
            var replicator = _Replicator;

#warning replication-status unused?
            // tag::replication-status[]
            replicator.AddChangeListener((sender, args) =>
            {
                if (args.Status.Activity == ReplicatorActivityLevel.Stopped) {
                    Console.WriteLine("Replication stopped");
                }
            });
            // end::replication-status[]
        }

        private static void ReplicatorPendingDocuments()
        {
            // tag::replication-pendingdocuments[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var database = new Database("myDB");
            var config = new ReplicatorConfiguration(target);
            config.AddCollection(database.GetDefaultCollection());
            config.ReplicatorType = ReplicatorType.Push;

            // tag::replication-push-pendingdocumentids[]
            var replicator = new Replicator(config);

            var pendingDocIDs =
              new HashSet<string>(replicator.GetPendingDocumentIDs(database.GetDefaultCollection())); // <.>
            // end::replication-push-pendingdocumentids[]

            if (pendingDocIDs.Count > 0) {
                Console.WriteLine($"There are {pendingDocIDs.Count} documents pending");
                replicator.AddChangeListener((sender, change) =>
                {
                    Console.WriteLine($"Replicator activity level is " +
                                      change.Status.Activity.ToString());
                    // iterate and report-on previously
                    // retrieved pending docids 'list'
                    foreach (var docID in pendingDocIDs)
#warning replication-push-isdocumentpending unused?
                        // tag::replication-push-isdocumentpending[]
                        if (!replicator.IsDocumentPending(docID, database.GetDefaultCollection())) // <.>
                        {
                            Console.WriteLine($"Doc ID {docID} now pushed");
                        };
                        // end::replication-push-isdocumentpending[]
                });

                replicator.Start();
            }
            // end::replication-pendingdocuments[]
        }

        private static void ReplicatorDocumentEvent()
        {
            var replicator = _Replicator;

            // tag::add-document-replication-listener[]
            var token = replicator.AddDocumentReplicationListener((sender, args) =>
            {
                var direction = args.IsPush ? "Push" : "Pull";
                Console.WriteLine($"Replication type :: {direction}");
                foreach (var doc in args.Documents) {
                    if (doc.Error == null) {
                        Console.WriteLine($"Doc ID :: {doc.Id}");
                        if (doc.Flags.HasFlag(DocumentFlags.Deleted)) {
                            Console.WriteLine("Successfully replicated a deleted document");
                        }
                    } else {
                        // There was an error
                    }
                }
            });

            replicator.Start();
            // end::add-document-replication-listener[]

            // tag::remove-document-replication-listener[]
            replicator.RemoveChangeListener(token);
            // end::remove-document-replication-listener[]
        }

        private static void SetupReplicatorErrorListener()
        {
            // This can be done in the SetupReplicatorListener method
            // But it is separate so that we can have two documentation entries

            var replicator = _Replicator;

            // tag::replication-error-handling[]
            replicator.AddChangeListener((sender, args) =>
            {
                if (args.Status.Error != null) {
                    Console.WriteLine($"Error :: {args.Status.Error}");
                }
            });
            // end::replication-error-handling[]
        }

        private static void DatabaseReplica()
        {
            var collection = _Database.GetDefaultCollection();
            using (var database2 = new Database("backup")) {
                // EE feature: This code will not compile on the community edition
                // tag::database-replica[]
                var targetDatabase = new DatabaseEndpoint(database2);
                var config = new ReplicatorConfiguration(targetDatabase)
                {
                    ReplicatorType = ReplicatorType.Push
                };
                config.AddCollection(collection);

                var replicator = new Replicator(config);
                replicator.Start();
                // end::database-replica[]
            }
        }

        private X509Certificate2 GetCertificate(string name)
        {
            return null;
        }

        public void PinCertificate()
        {
            var url = new Uri("wss://localhost:4984/db");
            var target = new URLEndpoint(url);

            // tag::certificate-pinning[]
            // Note: `GetCertificate` is a placeholder method. This would be the platform-specific method
            // to find and load the certificate as an instance of `X509Certificate2`.
            // For .NET Core / .NET Framework this can be loaded from the filesystem path.
            // For WinUI, from the assets directory.
            // For iOS, from the main bundle.
            // For Android, from the assets directory.
            var certificate = GetCertificate("cert.cer");
            var config = new ReplicatorConfiguration(target)
            {
                PinnedServerCertificate = certificate
            };
            // end::certificate-pinning[]
        }

        public void ReplicationCustomHeaders()
        {
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            // tag::replication-custom-header[]
            var config = new ReplicatorConfiguration(target)
            {
                Headers = new Dictionary<string, string>
                {
                    ["CustomHeaderName"] = "Value"
                }
            };
            // end::replication-custom-header[]
        }

        private static void PushWithFilter(Database database)
        {
            var collection = _Database.GetDefaultCollection();

            // tag::replication-push-filter[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var config = new ReplicatorConfiguration(target);
            config.AddCollection(collection, new CollectionConfiguration()
            {
                PushFilter = (document, flags) => // <1>
                {
                    if (flags.HasFlag(DocumentFlags.Deleted)) {
                        return false;
                    }

                    return true;
                }
            });

            // Dispose() later
            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication-push-filter[]
        }

        private static void PullWithFilter(Database database)
        {
            var collection = _Database.GetDefaultCollection();

            // tag::replication-pull-filter[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var config = new ReplicatorConfiguration(target);
            config.AddCollection(collection, new CollectionConfiguration()
            {
                PullFilter = (document, flags) => // <1>
                {
                    if (document.GetString("type") == "draft") {
                        return false;
                    }

                    return true;
                }
            });

            // Dispose() later
            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication-pull-filter[]
        }

        public void TestCustomRetryConfig()
        {
            // tag::replication-retry-config[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var config = new ReplicatorConfiguration(target);

            //  other config as required . . .

#warning replication-set-heartbeat unused?
            // tag::replication-set-heartbeat[]
            config.Heartbeat = TimeSpan.FromSeconds(120); //  <.>
                                                          // end::replication-set-heartbeat[]

            // tag::replication-set-maxattempts[]
#warning replication-set-maxattempts unused?
            config.MaxAttempts = 20; //  <.>
                                     // end::replication-set-maxattempts[]

            // tag::replication-set-maxattemptwaittime[]
#warning replication-set-maxattemptwaittime unused?
            config.MaxAttemptsWaitTime = TimeSpan.FromSeconds(600); //  <.>
            // end::replication-set-maxattemptwaittime[]

            //  other config as required . . .

            var replicator = new Replicator(config);

            // end::replication-retry-config[]
        }


        private static void UsePredictiveModel()
        {
            using (var database = new Database("mydb")) {
                var collection = database.GetDefaultCollection();
                // tag::register-model[]
                var model = new ImageClassifierModel();
                Database.Prediction.RegisterModel("ImageClassifier", model);
                // end::register-model[]

                // tag::predictive-query-value-index[]
                var index = IndexBuilder.ValueIndex(ValueIndexItem.Property("label"));
                collection.CreateIndex("value-index-image-classifier", index);
                // end::predictive-query-value-index[]

                // tag::unregister-model[]
                Database.Prediction.UnregisterModel("ImageClassifier");
                // end::unregister-model[]
            }
        }

        private static void UsePredictiveIndex()
        {
            using (var database = new Database("mydb")) {
                var collection = database.GetDefaultCollection();
                // tag::predictive-query-predictive-index[]
                var input = Expression.Dictionary(new Dictionary<string, object>
                {
                    ["photo"] = Expression.Property("photo")
                });

                var index = IndexBuilder.PredictiveIndex("ImageClassifier", input);
                collection.CreateIndex("predictive-index-image-classifier", index);
                // end::predictive-query-predictive-index[]
            }
        }

        private static void DoPredictiveQuery()
        {
            using (var database = new Database("mydb")) {
                var collection = database.GetDefaultCollection();
                // tag::predictive-query[]
                var input = Expression.Dictionary(new Dictionary<string, object>
                {
                    ["photo"] = Expression.Property("photo")
                });
                var prediction = Function.Prediction("ImageClassifier", input); // <1>

                using var query = QueryBuilder.Select(SelectResult.All())
                    .From(DataSource.Collection(collection))
                    .Where(prediction.Property("label").EqualTo(Expression.String("car"))
                        .And(prediction.Property("probability").GreaterThanOrEqualTo(Expression.Double(0.8))));

                var result = query.Execute();
                Console.WriteLine($"Number of rows: {result.Count()}");
                // end::predictive-query[]
            }
        }

        public List<Result> docsonly_N1QLQueryString(Database argDB)
        {
            DatabaseConfiguration config = new DatabaseConfiguration();

            Database database = new Database("dbName", config);

            // tag::query-syntax-n1ql[]
            using var query =
                database.CreateQuery("SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.>

            return query.Execute().AllResults();
            // end::query-syntax-n1ql[]
        }

        public void docsonly_N1QLQueryStringParams(Database argDB)
        {
            var database = _Database;

            // tag::query-syntax-n1ql-params[]
            using var query =
                database.CreateQuery("SELECT META().id AS thisId FROM _ WHERE type = $type"); // <.>

            var n1qlParams = new Parameters();
            n1qlParams.SetString("type", "hotel"); // <.>
            query.Parameters = n1qlParams;

            var results = query.Execute().AllResults();
            // end::query-syntax-n1ql-params[]
        }

        public void testQuerySyntaxAll()
        {
            // tag::query-syntax-all[]
            var database = new Database("hotels");

            var query = QueryBuilder
                  .Select(SelectResult.All())
                  .From(DataSource.Collection(database.GetDefaultCollection()));
            // end::query-syntax-all[]

            // tag::query-access-all[]
            var results = query.Execute().AllResults();
            var hotels = new List<Dictionary<string, object>>();

            if (results?.Count > 0) {
                foreach (var result in results) {
                    // get the result into our dictionary object
                    var thisDocsProps = result.GetDictionary("hotels"); // <.>

                    if (thisDocsProps != null) {
                        var docID = thisDocsProps.GetString("id"); // <.>
                        var docName = thisDocsProps.GetString("name");
                        var docCity = thisDocsProps.GetString("city");
                        var docType = thisDocsProps.GetString("type");
                        var hotel = thisDocsProps.ToDictionary();
                        hotels.Add(hotel);
                    }

                }
            }
            // end::query-access-all[]

            // tag::query-access-json[]
            foreach (var result in query.Execute()) {

                // get the result into a JSON String
                var docJSONString = result.ToJSON();

                // Get a native dictionary object using the JSON string
                var dictFromJSONstring =
                      JsonConvert.
                        DeserializeObject<Dictionary<string, object>>
                          (docJSONString);

                // use the created dictionary
                if (dictFromJSONstring != null) {
                    var docID = dictFromJSONstring["id"].ToString();
                    var docName = dictFromJSONstring["name"].ToString();
                    var docCity = dictFromJSONstring["city"].ToString();
                    var docType = dictFromJSONstring["type"].ToString();
                }

                //Get a custom object using the JSON string
                Hotel hotel =
                    JsonConvert.DeserializeObject<Hotel>(docJSONString);

            } 
            // end::query-access-json[]
        }

        public void testQuerySyntaxProps()
        {
            // tag::query-syntax-props[]
            var database = new Database("hotels");

            List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();

            var query = QueryBuilder.Select(
                    SelectResult.Property("type"),
                    SelectResult.Property("name"),
                    SelectResult.Property("city")).From(DataSource.Collection(database.GetDefaultCollection()));
            // end::query-syntax-props[]

            // tag::query-access-props[]
            var results = query.Execute().AllResults();
            foreach (var result in results) {

                // get the returned array of k-v pairs into a dictionary
                var hotel = result.ToDictionary();

                // add hotel dictionary to list of hotel dictionaries
                hotels.Add(hotel);

                // use the properties of the returned array of k-v pairs directly
                var docType = result.GetString("type");
                var docName = result.GetString("name");
                var docCity = result.GetString("city");

            }
            // end::query-access-props[]
        }

        public void testQuerySyntaxCount()
        {
            // tag::query-syntax-count-only[]
            var database = new Database("hotels");

            var query =
              QueryBuilder
                .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount")) // <.>
                .From(DataSource.Collection(database.GetDefaultCollection()));
            // end::query-syntax-count-only[]


            // tag::query-access-count-only[]
            var results = query.Execute().AllResults();
            foreach (var result in results) {
                var numberOfDocs = result.GetInt("mycount"); // <.>
            }
            // end::query-access-count-only[]
        }

        public void ibQueryForID()
        {
            // tag::query-syntax-id[]
            var database = new Database("hotels");

            var query = QueryBuilder
                    .Select(SelectResult.Expression(Meta.ID).As("this_ID"))
                    .From(DataSource.Collection(database.GetDefaultCollection()));
            // end::query-syntax-id[]

            // tag::query-access-id[]
            var results = query.Execute().AllResults();
            foreach (var result in results) {

                var docID = result.GetString("this_ID"); // <.>
                var doc = database.GetDefaultCollection().GetDocument(docID);
            }
            // end::query-access-id[]
        }

#warning query-syntax-pagination-all unused (and out of place)?
        // tag::query-syntax-pagination-all[]
        public void testQueryPagination()
        {
            // tag::query-syntax-pagination[]
            var database = new Database("hotels");
            var limit = 20;
            var offset = 0;

            // get a count of the number of docs matching the query
            var countQuery =
                QueryBuilder
                    .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount"))
                    .From(DataSource.Collection(database.GetDefaultCollection()));
            var numberOfDocs =
                countQuery.Execute().First().GetInt("mycount");

            if (numberOfDocs < limit) {
                limit = numberOfDocs;
            }

            while (offset < numberOfDocs) {
                var listQuery =
                    QueryBuilder
                        .Select(SelectResult.All())
                        .From(DataSource.Collection(database.GetDefaultCollection()))
                        .Limit(Expression.Int(limit), Expression.Int(offset)); // <.>

                foreach (var result in listQuery.Execute()) {
                    // Display and or process query results batch
                }

                offset = offset + limit;
            }

            // end::query-syntax-pagination[]
            // end::query-syntax-pagination-all[]
        }

        public void JsonApiDocument()
        {
            var collection = _Database.GetDefaultCollection();
            // tag::tojson-document[]
            // Get a document
            var doc = collection.GetDocument("hotel_10025");

            // Get document data as JSON String
            var docJSONString = doc?.ToJSON();

            // Get Json Object from the Json String
            JObject jsonObject = JObject.Parse(docJSONString);

            // Get Native Object (anhotel) from JSON String
            List<Hotel> hotels = new List<Hotel>();

            var hotel = JsonConvert.DeserializeObject<Hotel>(docJSONString);
            hotels.Add(hotel);

            // Update the retrieved native object
            hotel.Name = "A Copy of " + hotel.Name;
            hotel.Id = "2001";

            // Convert the updated object back to a JSON string
            var newJsonString = JsonConvert.SerializeObject(hotel);

            // Update new document with JSOn String
            MutableDocument newhotel = doc.ToMutable();
            newhotel.SetJSON(newJsonString);
            

            foreach (string key in newhotel.ToDictionary().Keys) {
                Console.WriteLine("Data -- {0} = {1}",
                    key, newhotel.GetValue(key));
            }

            collection.Save(newhotel);
            var retrievedDoc = collection.GetDocument("2001").ToJSON();
            Console.Write(retrievedDoc);
            // end::tojson-document[]

        }

        public void JsonApiArray()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::tojson-array[]
            // JSON String -- an Array (3 elements. including embedded arrays)
            var jsonString = "[{'id':'1000','type':'hotel','name':'Hotel Ted','city':'Paris','country':'France','description':'Undefined description for Hotel Ted'},{'id':'1001','type':'hotel','name':'Hotel Fred','city':'London','country':'England','description':'Undefined description for Hotel Fred'},                        {'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}]".Replace("'", "\"");

            // Get JSON Array from JSON String
            var jsonArray = JArray.Parse(jsonString);

            // Create mutable array using JSON String Array
            var mutableArray = new MutableArrayObject();
            mutableArray.SetJSON(jsonString);

            // Create a new document for each array element
            for (int i = 0; i < mutableArray.Count; i++) {
                var dict = mutableArray.GetDictionary(i);
                var docid = mutableArray[i].Dictionary.GetString("id");
                var mutableDoc = new MutableDocument(docid, dict.ToDictionary());
                collection.Save(mutableDoc);
            }

            // Get one of the created docs and iterate through one of the embedded arrays
            var extendedDoc = collection.GetDocument("1002");
            var features = extendedDoc.GetArray("features");

            // Print its elements
            foreach (string feature in features) {
                Console.Write($"{feature} ");

                //process array item as required
            }
            var featuresJSON = extendedDoc.GetArray("features").ToJSON();
            // end::tojson-array[]
        }

        public void JsonApiDictionary()
        {
            var ourdbname = "ournewdb";
            if (Database.Exists(ourdbname, "/")) {
                Database.Delete(ourdbname, "/");
            }

            // tag::tojson-dictionary[]
            // Get dictionary from JSONstring
            var jsonString = "{'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}".Replace("'", "\"");
            var mutableDict = new MutableDictionaryObject(json: jsonString);

            // use dictionary to get name value
            var name = mutableDict.GetString("name");

            // Iterate through keys
            foreach (string key in mutableDict.Keys) {
                Console.WriteLine("Data -- {0} = {1}", key, mutableDict.GetValue(key).ToString());

            }
            // end::tojson-dictionary[]
        }

        public void JsonApiBlob()
        {
            var userName = "ian";
            var collection = _Database.GetDefaultCollection();
            var database = _Database;

            // tag::tojson-blob[]
            // Initialize base document for blob from a JSON string
            var docId = "1002";
            var jsonString = "{'ref':'hotel_1002','type':'hotel','name':'Hotel Ned'," +
                "'city':'Balmain','country':'Australia'," +
                "'description':'Undefined description for Hotel Ned'," +
                "'features':['Cable TV','Toaster','Microwave']}".Replace("'", "\"");
            var mutableDoc = new MutableDocument(docId, jsonString);

            // Get the content (an image), create blob and add to doc)
            var defaultDirectory =
                Path.Combine(Service.GetInstance<IDefaultDirectoryResolver>()
                            .DefaultDirectory(),
                                userName);
            var imagePath = Path.Combine(defaultDirectory, "avatarimage.jpg");
            var imageUri = new Uri(imagePath.ToString());
            var imageBlob = new Blob("image/jpg", imageUri);
            mutableDoc.SetBlob("avatar", imageBlob);

            // This example generates a 'blob not saved' exception
            try { 
                Console.WriteLine("myBlob (unsaved) as JSON = {0}", imageBlob.ToJSON()); 
            } catch (Exception e) { 
                Console.WriteLine("Exception = {0}", e.Message); 
            }

            collection.Save(mutableDoc);

            // Alternatively -- depending on use case
            database.SaveBlob(new Blob("image/jpg", imageUri));

            // Retrieve saved doc, get blob as JSON andheck its still a 'blob'
            var sameDoc = collection.GetDocument(docId);
            var reconstitutedBlob = new MutableDictionaryObject().
                SetDictionary("blobCOPY", new MutableDictionaryObject(sameDoc.GetBlob("avatar").ToJSON()));

            if (Blob.IsBlob(
                    reconstitutedBlob.GetDictionary("blobCOPY").ToDictionary())) {
                //... process accordingly
                Console.WriteLine("Its a Blob!!");
            }
            // end::tojson-blob[]
        }

        private bool ValidatePassword(SecureString password) => true;

        public void P2PListenerSimple()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::listener-simple[]
            var endpointConfig = new URLEndpointListenerConfiguration(new[] { collection }); // <.>

            endpointConfig.Authenticator =
              new ListenerPasswordAuthenticator(
                (sender, username, password) =>
                {
                    // ValidatePassword can make use of the SecureString class
                    // to the desired level of security (or just convert it to string
                    // if no intense security is required)
                    return username == "valid.user" && ValidatePassword(password);
                }
              ); // <.>

            var listener = new URLEndpointListener(endpointConfig); // <.>
            listener.Start(); // <.>
            // end::listener-simple[]
        }

        public void P2PReplicatorSimple()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::replicator-simple[]
            var endpointConfig = new URLEndpoint(new Uri("wss://listener.com:4984/otherDB")); // <.>

            var replConfig = new ReplicatorConfiguration(endpointConfig); // <.>
            replConfig.AddCollection(collection);
            replConfig.AcceptOnlySelfSignedServerCertificate = true; // <.>
            replConfig.Authenticator =
              new BasicAuthenticator("valid.user", "valid.password.string"); // <.>

            var replicator = new Replicator(replConfig); // <.>
            replicator.Start(); // <.>
            // end::replicator-simple[]
        }

        public void GettingStarted1()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::listener-initialize[]
            // tag::listener-config-db[]
            // Initialize the listener config
            var endpointConfig = new URLEndpointListenerConfiguration(new[] { collection }); // <.>
            // end::listener-config-db[]

            // tag::listener-config-port[]
            endpointConfig.Port = 55990; //<.>
            // end::listener-config-port[]

            // tag::listener-config-netw-iface[]
            endpointConfig.NetworkInterface = "10.1.1.10"; // <.>
            // end::listener-config-netw-iface[]

            // tag::listener-config-delta-sync[]
            endpointConfig.EnableDeltaSync = true; // <.>
                                               // end::listener-config-delta-sync[]

#warning listener-config-tls-full unused?
            // tag::listener-config-tls-full[]
            // tag::listener-config-tls-enable[]
            endpointConfig.DisableTLS = false; // <.>
            // end::listener-config-tls-enable[]

            // tag::listener-config-tls-id-anon[]
            // Use an Anonymous Self-Signed Cert
            endpointConfig.TlsIdentity = null; // <.>
            // end::listener-config-tls-id-anon[]

            // tag::listener-config-client-auth-pwd[]
            // Configure the client authenticator
            // Here we are using Basic Authentication) <.>
            SecureString validPassword = new SecureString(); /* example only */
            // Get SecureString input for validPassword
            var validUser = "valid.username";
            endpointConfig.Authenticator = new ListenerPasswordAuthenticator(
            (sender, username, password) =>
            {
                // Implement your own ValidatePassword function
                return username == validUser && ValidatePassword(password);
            }
            );
            // end::listener-config-client-auth-pwd[]

            // tag::listener-start[]
            // Initialize the listener
            var listener = new URLEndpointListener(endpointConfig); // <.>

            // Start the listener
            listener.Start(); // <.>
                              // end::listener-start[]
                              // end::listener-initialize[]

#warning old-listener-config-tls-disable unused?
            // tag::old-listener-config-tls-disable[]
            endpointConfig.DisableTLS = true;
            // end::old-listener-config-tls-disable[]

#warning listener-config-tls-id-nil-2 unused?
            // tag::listener-config-tls-id-nil-2[]
            // Use “anonymous” cert. These are self signed certs created by the system
            endpointConfig.TlsIdentity = null;
            // end::listener-config-tls-id-nil-2[]

#warning old-listener-config-delta-sync unused?
            // tag::old-listener-config-delta-sync[]
            endpointConfig.EnableDeltaSync = true;
            // end::old-listener-config-delta-sync[]

            // tag::listener-status-check[]
            ulong connectionCount = listener.Status.ConnectionCount; // <.>
            ulong activeConnectionCount = listener.Status.ActiveConnectionCount;  // <.>
            // end::listener-status-check[]

            // tag::listener-stop[]
            listener.Stop();
            // end::listener-stop[]

            // tag::listener-get-network-interfaces[]
            foreach (NetworkInterface ni in NetworkInterface.GetAllNetworkInterfaces()) {
                if (ni.NetworkInterfaceType == NetworkInterfaceType.Wireless80211 ||
                    ni.NetworkInterfaceType == NetworkInterfaceType.Ethernet) {
                    // do something with the interface(s)
                }
            }
            // end::listener-get-network-interfaces[]
        }

        public void GettingStarted2()
        {
            var collection = _Database.GetDefaultCollection();

            {
#warning listener-get-url-list unused?
                // tag::listener-get-url-list[]
                var endpointConfig = new URLEndpointListenerConfiguration(new[] { collection });
                var listener = new URLEndpointListener(endpointConfig);

                listener.Start();

                // Note, converting to string omitted.
                Console.WriteLine("URLS are {0} ", listener.Urls);
                // end::listener-get-url-list[]

#warning listener-config-tls-disable unused?
                // tag::listener-config-tls-disable[]
                endpointConfig.DisableTLS = true; // <.>
                                          // end::listener-config-tls-disable[]

#warning listener-local-db unused?
                // tag::listener-local-db[]
                // . . . preceding application logic . . .
                // Get the database (and create it if it doesn't exist)
                var database = new Database("mydb");
                // end::listener-local-db[]

                // tag::listener-config-tls-id-full[]
                // tag::listener-config-tls-id-caCert[]
                // Use CA Cert
                // Create a TLSIdentity from an imported key-pair
                // . . . previously declared variables include ...
                X509Store store =
                  new X509Store(StoreName.My); // create and label x509 store

                // Get keys and certificates from PKCS12 data
                byte[] certData =
                  File.ReadAllBytes("c:client.p12"); // <.>
                                                     // . . . other user code . . .

#warning import-tls-identity unused?
                // tag::import-tls-identity[]
                TLSIdentity identity = TLSIdentity.ImportIdentity(
                  store,
                  certData, // <.>
                  "123", // Password to access certificate data
                  "couchbase-demo-cert",
                  null); // Label to get cert in certificate map
                         // NOTE: If a null label is supplied then the same
                         // default directory for a Couchbase Lite database
                         // is used for map.

                // end::import-tls-identity[]
                // end::listener-config-tls-id-caCert[]

                // tag::listener-config-tls-id-anon[]
                // Use an Anonymous Self-Signed Cert
                endpointConfig.TlsIdentity = null; // <.>
                // end::listener-config-tls-id-anon[]

#warning listener-config-tls-id-set unused?
                // tag::listener-config-tls-id-set[]
                // Set the TLS Identity
                endpointConfig.TlsIdentity = identity; // <.>
                // end::listener-config-tls-id-set[]
                // end::listener-config-tls-id-full[]
            }

            {
                var endpointConfig = new URLEndpointListenerConfiguration(new[] { collection });

                // tag::listener-config-client-auth-root[]
                // Configure the client authenticator
                // to validate using ROOT CA

                // Get the valid cert chain, in this instance from
                // PKCS12 data containing private key, public key
                // and certificates <.>
                var clientData = File.ReadAllBytes("c:client.p12");
                var ourCaData = File.ReadAllBytes("c:client-ca.der");

                // Get the root certs from the data
                var rootCert = new X509Certificate2(ourCaData); // <.>

                // Configure the authenticator to use the root certs
                var certAuth = new ListenerCertificateAuthenticator(new X509Certificate2Collection(rootCert));

                endpointConfig.Authenticator = certAuth; // <.>

                // Initialize the listener using the config
                var listener = new URLEndpointListener(endpointConfig);
                // end::listener-config-client-auth-root[]

                // tag::listener-config-client-auth-lambda[]
                // Configure the client authenticator
                // to validate using application logic

                // Get the valid cert chain, in this instance from
                // PKCS12 data containing private key, public key
                // and certificates <.>
                clientData = File.ReadAllBytes("c:client.p12");
                ourCaData = File.ReadAllBytes("c:client-ca.der");

                // Configure the authenticator to pass the root certs
                // To a user supplied code block for authentication
                var callbackAuth =
                  new ListenerCertificateAuthenticator(
                    (object sender, X509Certificate2Collection chain) =>
                    {
                        // . . . user supplied code block
                        // . . . returns boolean value (true=authenticated)
                        return true;
                    }); // <.>

                endpointConfig.Authenticator = callbackAuth; // <.>
                // end::listener-config-client-auth-lambda[]
            }
        }

        public void datatype_usage()
        {
#warning datatype_usage unused?
            // tag::datatype_usage[]
            // tag::datatype_usage_createdb[]
            // Get the database (and create it if it doesn’t exist).
            using var database = new Database("hoteldb");
            var collection = database.GetDefaultCollection();
            // end::datatype_usage_createdb[]

            // tag::datatype_usage_createdoc[]
            // Create your new document
            using var mutableDoc = new MutableDocument("hoteldoc");
            // end::datatype_usage_createdoc[]

            // tag::datatype_usage_mutdict[]
            // Create and populate mutable dictionary
            var address = new MutableDictionaryObject();
            address.SetString("street", "1 Main st.");
            address.SetString("city", "San Francisco");
            address.SetString("state", "CA");
            address.SetString("country", "USA");
            address.SetString("code", "90210");
            // end::datatype_usage_mutdict[]

            // tag::datatype_usage_mutarray[]
            // Create and populate mutable array
            var phones = new MutableArrayObject();
            phones.AddString("650-000-0000");
            phones.AddString("650-000-0001");
            // end::datatype_usage_mutarray[]

            // tag::datatype_usage_populate[]
            // Initialize and populate the document

            // Add document type and hotel name as string
            mutableDoc.SetString("type", "hotel");
            mutableDoc.SetString("name", "Hotel Java Mo");

            // Add average room rate (float)
            mutableDoc.SetFloat("room_rate", 121.75f);

            // Add address (dictionary)
            mutableDoc.SetDictionary("address", address);

            // Add phone numbers(array)
            mutableDoc.SetArray("phones", phones);
            // end::datatype_usage_populate[]

            // tag::datatype_usage_persist[]
            collection.Save(mutableDoc);
            // end::datatype_usage_persist[]

            // tag::datatype_usage_closedb[]
            database.Close();
            // end::datatype_usage_closedb[]
            // end::datatype_usage[]
        }

        public void datatype_dictionary()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::datatype_dictionary[]
            var doc = collection.GetDocument("doc1");

            // Getting a dictionary from the document's properties
            var dict = doc.GetDictionary("address");

            // Access a value with a key from the dictionary
            var street = dict.GetString("street");

            // Iterate dictionary
            foreach (var key in dict.Keys) {
                Console.WriteLine($"Key {key} = {dict.GetValue(key)}");
            }

            // Create a mutable copy
            var mutableDict = dict.ToMutable();
            // end::datatype_dictionary[]
        }

        public void datatype_mutable_dictionary()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::datatype_mutable_dictionary[]
            // Create a new mutable dictionary and populate some keys/values
            var mutableDict = new MutableDictionaryObject();
            mutableDict.SetString("street", "1 Main st.");
            mutableDict.SetString("city", "San Francisco");

            // Add the dictionary to a document's properties and save the document
            using var mutableDoc = new MutableDocument("doc1");
            mutableDoc.SetDictionary("address", mutableDict);
            collection.Save(mutableDoc);
            // end::datatype_mutable_dictionary[]
        }

        public void datatype_array()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::datatype_array[]
            var document = collection.GetDocument("doc1");

            // Getting a phones array from the document's properties
            var array = document.GetArray("phones");

            // Get element count
            var count = array.Count();

            // Access an array element by index
            if (count >= 0) { var phone = array[1]; }

            // Iterate dictionary
            for (int i = 0; i < count; i++) {
                Console.WriteLine($"Item {i.ToString()} = {array[i]}");
            }

            // Create a mutable copy
            var mutableArray = array.ToMutable();
            // end::datatype_array[]
        }

        public void datatype_mutable_array()
        {
            var collection = _Database.GetDefaultCollection();

            // tag::datatype_mutable_array[]
            // Create a new mutable array and populate data into the array
            var mutableArray = new MutableArrayObject();
            mutableArray.AddString("650-000-0000");
            mutableArray.AddString("650-000-0001");

            // Set the array to document's properties and save the document
            using var mutableDoc = new MutableDocument("doc1");
            mutableDoc.SetArray("phones", mutableArray);
            collection.Save(mutableDoc);
            // end::datatype_mutable_array[]
        }

        static void Main(string[] args)
        {
            // NOTE: PLEASE PLEASE PLEASE do not break the compilation of this file.  It is
            // by far the easiest way to check for its correctness.  If you don't know how to
            // compile a C# program, then find someone who does before you commit your changes!!!
            Console.WriteLine("This program is not meant to be executed, only compiled");
        }
    }

    /* ----------------------------------------------------------- */
    /* ---------------------  ACTIVE SIDE  ----------------------- */
    /* ---------------  stubs for documentation  ----------------- */
    /* ----------------------------------------------------------- */

    class ActivePeer : IMessageEndpointDelegate
    {
        ActivePeer()
        {
            // tag::message-endpoint[]
            var database = new Database("dbname");

            // The delegate must implement the `IMessageEndpointDelegate` protocol.
            var messageEndpointTarget = new MessageEndpoint(uid: "UID:123", target: "",
                protocolType: ProtocolType.MessageStream, delegateObject: this);
            // end::message-endpoint[]

            // tag::message-endpoint-replicator[]
            var replConfig = new ReplicatorConfiguration(messageEndpointTarget);
            replConfig.AddCollection(database.GetDefaultCollection());

            // Create the replicator object
            var replicator = new Replicator(replConfig);
            // Start the replicator
            replicator.Start();
            // end::message-endpoint-replicator[]
        }

        // tag::create-connection[]
        /* implementation of MessageEndpointDelegate */
        public IMessageEndpointConnection CreateConnection(MessageEndpoint endpoint)
        {
            var connection = new ActivePeerConnection(); /* implements MessageEndpointConnection */
            return connection;
        }
        // end::create-connection[]
    }

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously
    class ActivePeerConnection : IMessageEndpointConnection
    {
        private IReplicatorConnection _replicatorConnection;

        public void Disconnect()
        {
            // tag::active-replicator-close[]
            _replicatorConnection?.Close(null);
            // end::active-replicator-close[]
        }

        public void Receive(byte[] data)
        {
            // tag::active-peer-receive[]
            var message = Message.FromBytes(data);
            _replicatorConnection?.Receive(message);
            // end::active-peer-receive[]
        }

        // tag::active-peer-close[]
        /* implementation of MessageEndpointConnection */
        public async Task Close(Exception error)
        {
            // await socket.Close, etc (or do nothing if already closed)
            // throw MessagingException if something goes wrong (though
            // since it is "close" nothing special will happen)
        }
        // end::active-peer-close[]

        // tag::active-peer-open[]
        /* implementation of MessageEndpointConnection */
        public async Task Open(IReplicatorConnection connection)
        {
            _replicatorConnection = connection;
            // await socket.Open(), etc
            // throw MessagingException if something goes wrong
        }
        // end::active-peer-open[]

        // tag::active-peer-send[]
        /* implementation of MessageEndpointConnection */
        public async Task Send(Message message)
        {
            var data = message.ToByteArray();
            // await Socket.Send(), etc
            // throw MessagingException if something goes wrong
        }
        // end::active-peer-send[]
    }


    /* ----------------------------------------------------------- */
    /* ---------------------  PASSIVE SIDE  ---------------------- */
    /* ---------------  stubs for documentation  ----------------- */
    /* ----------------------------------------------------------- */
    class PassivePeerConnection : IMessageEndpointConnection
    {
        private MessageEndpointListener _messageEndpointListener;
        private IReplicatorConnection _replicatorConnection;

        public void StartListener()
        {
            // tag::listener[]
            var database = new Database("mydb");
            var endpointConfig = new MessageEndpointListenerConfiguration(new[] { database.GetDefaultCollection() }, ProtocolType.MessageStream);
            _messageEndpointListener = new MessageEndpointListener(endpointConfig);
            // end::listener[]
        }

        public void StopListener()
        {
            // tag::passive-stop-listener[]
            _messageEndpointListener?.CloseAll();
            // end::passive-stop-listener[]
        }

        public void AcceptConnection()
        {
            // tag::advertizer-accept[]
            var connection = new PassivePeerConnection(); /* implements MessageEndpointConnection */
            _messageEndpointListener?.Accept(connection);
            // end::advertizer-accept[]
        }

        public void Disconnect()
        {
            // tag::passive-replicator-close[]
            _replicatorConnection?.Close(null);
            // end::passive-replicator-close[]
        }

        public void Receive(byte[] data)
        {
            // tag::passive-peer-receive[]
            var message = Message.FromBytes(data);
            _replicatorConnection?.Receive(message);
            // end::passive-peer-receive[]
        }

        // tag::passive-peer-close[]
        /* implementation of MessageEndpointConnection */
        public async Task Close(Exception error)
        {
            // await socket.Close, etc (or do nothing if already closed)
            // throw MessagingException if something goes wrong (though
            // since it is "close" nothing special will happen)
        }
        // end::passive-peer-close[]

        // tag::passive-peer-open[]
        /* implementation of MessageEndpointConnection */
        public Task Open(IReplicatorConnection connection)
        {
            _replicatorConnection = connection;
            // socket should already be open on the passive side
            return Task.FromResult(true);
        }
        // end::passive-peer-open[]

        // tag::passive-peer-send[]
        /* implementation of MessageEndpointConnection */
        public async Task Send(Message message)
        {
            var data = message.ToByteArray();
            // await Socket.Send(), etc
            // throw MessagingException if something goes wrong
        }
        // end::passive-peer-send[]
    }

#pragma warning restore CS1998 // Async method lacks 'await' operators and will run synchronously

    // tag::predictive-model[]
    // tensorFlowModel is a fake implementation
    // this would be the implementation of the ml model you have chosen
    class TensorFlowModel
    {
        public static IDictionary<string, object> PredictImage(byte[] data)
        {
            // Do calculations, etc
            return null;
        }
    }

    class ImageClassifierModel : IPredictiveModel
    {
        public DictionaryObject Predict(DictionaryObject input)
        {
            var blob = input.GetBlob("photo");
            if (blob == null) {
                return null;
            }

            var imageData = blob.Content;
            // tensorFlowModel is a fake implementation
            // this would be the implementation of the ml model you have chosen
            var modelOutput = TensorFlowModel.PredictImage(imageData);
            return new MutableDictionaryObject(modelOutput); // <1>
        }
    }
    // end::predictive-model[]

    // tag::custom-logging[]
    class LogTestLogger : ILogger
    {
        public LogLevel Level { get; set; }

        public void Reset()
        {
        }

        public void Log(LogLevel level, LogDomain domain, string message)
        {
            // handle the message, for example piping it to
            // a third party framework
        }
    }
    // end::custom-logging[]

    // tag::local-win-conflict-resolver[]
    class LocalWinConflictResolver : IConflictResolver
    {
        public Document Resolve(Conflict conflict)
        {
            return conflict.LocalDocument;
        }
    }
    // end::local-win-conflict-resolver[]

    // tag::remote-win-conflict-resolver[]
    class RemoteWinConflictResolver : IConflictResolver
    {
        public Document Resolve(Conflict conflict)
        {
            return conflict.RemoteDocument;
        }
    }
    // end::remote-win-conflict-resolver[]

    // tag::merge-conflict-resolver[]
    class MergeConflictResolver : IConflictResolver
    {
        public Document Resolve(Conflict conflict)
        {
            var localDict = conflict.LocalDocument.ToDictionary();
            var remoteDict = conflict.RemoteDocument.ToDictionary();
            var result = localDict.Concat(remoteDict)
               .GroupBy(kv => kv.Key)
               .ToDictionary(g => g.Key, g => g.First().Value);
            return new MutableDocument(conflict.DocumentID, result);
        }
    }
    // end::merge-conflict-resolver[]
 }

#warning p2p-act-rep-func used, but contains nothing
// tag::p2p-act-rep-func[]

#warning p2p-act-rep-config-type used, but contains nothing
// tag::p2p-act-rep-config-type[]

// end::p2p-act-rep-config-type[]

#warning autopurge-override used, but contains nothing
// tag::autopurge-override[]
// Set autopurge option
// here we override its default

// end::autopurge-override[]

#warning p2p-act-rep-config-cont used, but contains nothing
// tag::p2p-act-rep-config-cont[]
// Configure Sync Mode

// end::p2p-act-rep-config-cont[]

#warning p2p-act-rep-config-self-cert used, but contains nothing
// tag::p2p-act-rep-config-self-cert[]
// Configure Server Security -- only accept self-signed certs

// end::p2p-act-rep-config-self-cert[]

// Configure Client Security // <.>

#warning p2p-act-rep-auth used, but contains nothing
// tag::p2p-act-rep-auth[]
// Configure basic auth using user credentials

// end::p2p-act-rep-auth[]

#warning p2p-act-rep-start-full used, but contains nothing
// tag::p2p-act-rep-start-full[]
// Initialize and start a replicator
// Initialize replicator with configuration data

#warning p2p-act-rep-add-change-listener used, but contains nothing
// tag::p2p-act-rep-add-change-listener[]
#warning p2p-act-rep-add-change-listener-label used, but contains nothing
// tag::p2p-act-rep-add-change-listener-label[]
//Optionally add a change listener // <.>
// end::p2p-act-rep-add-change-listener-label[]

// end::p2p-act-rep-add-change-listener[]

#warning p2p-act-rep-start used, but contains nothing
// tag::p2p-act-rep-start[]
// Start replicator

// end::p2p-act-rep-start[]
// end::p2p-act-rep-start-full[]
// end::p2p-act-rep-func[] 

#warning p2p-act-rep-config-cacert used, but contains nothing
// tag::p2p-act-rep-config-cacert[]
// Configure Server Security -- only accept CA certs
// end::p2p-act-rep-config-cacert[]

#warning p2p-act-rep-config-cacert-pinned used, but contains nothing
// tag::p2p-act-rep-config-cacert-pinned[]
// Only CA Certs accepted
// end::p2p-act-rep-config-cacert-pinned[]

#warning p2p-act-rep-status used, but contains nothing
// tag::p2p-act-rep-status[]
// end::p2p-act-rep-status[]

#warning p2p-act-rep-stop used, but contains nothing
// tag::p2p-act-rep-stop[]
// Stop replication.
// end::p2p-act-rep-stop[]

#warning p2p-tlsid-store-in-keychain used, but contains nothing
// tag::p2p-tlsid-store-in-keychain[]
// end::p2p-tlsid-store-in-keychain[]

#warning p2p-tlsid-delete-id-from-keychain used, but contains nothing
// tag::p2p-tlsid-delete-id-from-keychain[]
// end::p2p-tlsid-delete-id-from-keychain[]

public class MyClass
{
    public Database Database { get; set; }
    public Replicator Replicator { get; set; } // <.>

    public void StartReplication()
    {
        // tag::sgw-repl-pull[]
        var url = new Uri("wss://localhost:4984/db"); // <.>
        var target = new URLEndpoint(url);
        var config = new ReplicatorConfiguration(target)
        {
            ReplicatorType = ReplicatorType.Pull
        };
        config.AddCollection(Database.GetDefaultCollection());

        Replicator = new Replicator(config);
        Replicator.Start();
        // end::sgw-repl-pull[]
    }

    public void InitReplication()
    {
        // tag::sgw-act-rep-initialize[]
        // initialize the replicator configuration

        var url = new URLEndpoint(new Uri("wss://10.0.2.2:4984/anotherDB")); // <.>
        var replConfig = new ReplicatorConfiguration(url);
        // Add collections to the config now

        // end::sgw-act-rep-initialize[]
    }
}
