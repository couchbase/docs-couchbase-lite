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
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Threading;
using System.Threading.Tasks;

using Couchbase.Lite;
using Couchbase.Lite.Enterprise.Query;
using Couchbase.Lite.Logging;
using Couchbase.Lite.P2P;
using Couchbase.Lite.Query;
using Couchbase.Lite.Sync;
using Newtonsoft.Json;

using SkiaSharp;

namespace api_walkthrough
{
    class Program
    {
        private static Database _Database;
        private static Replicator _Replicator;
        private static URLEndpointListener _listener;
        private static ListenerToken _ListenerToken;
        private static bool _NeedsExtraDocs;

        #region Private Methods

        private static void GettingStarted()
        {
            // tag::getting-started[]

            // using System;
            // using Couchbase.Lite;
            // using Couchbase.Lite.Query;
            // using Couchbase.Lite.Sync;

            // Get the database (and create it if it doesn't exist)
            var database = new Database("mydb");
            // Create a new document (i.e. a record) in the database
            string id = null;
            using (var mutableDoc = new MutableDocument())
            {
                mutableDoc.SetFloat("version", 2.0f)
                    .SetString("type", "SDK");

                // Save it to the database
                database.Save(mutableDoc);
                id = mutableDoc.Id;
            }

            // Update a document
            using (var doc = database.GetDocument(id))
            using (var mutableDoc = doc.ToMutable())
            {
                mutableDoc.SetString("language", "C#");
                database.Save(mutableDoc);

                using (var docAgain = database.GetDocument(id))
                {
                    Console.WriteLine($"Document ID :: {docAgain.Id}");
                    Console.WriteLine($"Learning {docAgain.GetString("language")}");
                }
            }

            // Create a query to fetch documents of type SDK
            // i.e. SELECT * FROM database WHERE type = "SDK"
            using (var query = QueryBuilder.Select(SelectResult.All())
                .From(DataSource.Database(database))
                .Where(Expression.Property("type").EqualTo(Expression.String("SDK"))))
            {
                // Run the query
                var result = query.Execute();
                Console.WriteLine($"Number of rows :: {result.AllResults().Count}");
            }

            // Create replicator to push and pull changes to and from the cloud
            var targetEndpoint = new URLEndpoint(new Uri("ws://localhost:4984/getting-started-db"));
            var replConfig = new ReplicatorConfiguration(database, targetEndpoint);

            // Add authentication
            replConfig.Authenticator = new BasicAuthenticator("john", "pass");

            // Create replicator (make sure to add an instance or static variable
            // named _Replicator)
            var _Replicator = new Replicator(replConfig);
            _Replicator.AddChangeListener((sender, args) =>
            {
                if (args.Status.Error != null)
                {
                    Console.WriteLine($"Error :: {args.Status.Error}");
                }
            });

            _Replicator.Start();

            // Later, stop and dispose the replicator *before* closing/disposing the
        }
    }
}
// end::getting-started[]

        private static void TestReplicatorConflictResolver()
        {
            // tag::replication-conflict-resolver[]
            var target = new URLEndpoint(new Uri("ws://localhost:4984/mydatabase"));
            var replConfig = new ReplicatorConfiguration(database, target);
            replConfig.ConflictResolver = new LocalWinConflictResolver();

            var replicator = new Replicator(replConfig);
            replicator.Start();
            // end::replication-conflict-resolver[]
        }

        private static void TestSaveWithConflictHandler()
        {
            // tag::update-document-with-conflict-handler[]
            using (var document = database.GetDocument("xyz"))
            using (var mutableDocument = document.ToMutable()) {
                mutableDocument.SetString("name", "apples");
                database.Save(mutableDocument, (updated, current) =>
                {
                    var currentDict = current.ToDictionary();
                    var newDict = updated.ToDictionary();
                    var result = newDict.Concat(currentDict)
                        .GroupBy(kv => kv.Key)
                        .ToDictionary(g => g.Key, g => g.First().Value);
                    updated.SetData(result);
                    return true;
                });
            }
            // end::update-document-with-conflict-handler[]
        }

        private static bool IsValidCredential(string name, SecureString password) { return true;  } // helper
        private static void TestInitListener()
        {
            var db = new Database("other-database");
            _Database = db;

            // tag::init-urllistener[]
            var config = new URLEndpointListenerConfiguration(_Database);
            config.TlsIdentity = null; // Use with anonymous self-signed cert
            config.Authenticator = new ListenerPasswordAuthenticator((sender, username, password) =>
            {
                if(IsValidCredential(username, password)) {
                    return true;
                }

                return false;
            });

            _listener = new URLEndpointListener(config);
            // end::init-urllistener[]
        }

        private static void TestListenerStart()
        {
            // tag::start-urllistener[]
            // CouchbaseLiteException will be thrown when the listener cannot be started. The most common error
            // would be that the configured port has already been used.
            _listener.Start();
            // end::start-urllistener[]
        }

        private static void TestListenerStop()
        {
            // tag::stop-urllistener[]
            _listener.Stop();
            // end::stop-urllistener[]
        }

        private static void TestCreateSelfSignedCert()
        {
            TLSIdentity identity;
            X509Store _store =
             new X509Store(StoreName.My);
              // The identity will be stored in the secure
              // storage using the given label.
            DateTimeOffset fiveMinToExpireCert = DateTimeOffset.UtcNow.AddMinutes(5);

            // tag::create-self-signed-cert[]
            // tag::listener-config-tls-id-SelfSigned[]
            identity = TLSIdentity.CreateIdentity(true, /* isServer */
                new Dictionary<string, string>() { { Certificate.CommonNameAttribute, "Couchbase Inc" } },
                    // The common name attribute is required
                    // when creating a CSR. If it is not presented
                    // in the cert, an exception is thrown.
                fiveMinToExpireCert,
                    // If the expiration date is not specified,
                    // the certs expiration will be 365 days
                _store,
                "CBL-Server-Cert",
                null);  // The key label to get cert in certificate map.
                        // If null, the same default directory
                        // for a Couchbase Lite db is used for map.

            // end::listener-config-tls-id-SelfSigned[]
            // end::create-self-signed-cert[]
        }

        private static void TestImportTLSIdentity()
        {
            TLSIdentity identity;
            X509Store _store = new X509Store(StoreName.My); // The identity will be stored in the secure storage using the given label
            byte[] data = File.ReadAllBytes("C:\\client.p12"); // PKCS12 data containing private key, public key, and certificates

            // tag::import-tls-identity[]
            // tag::listener-config-tls-id-caCert[]
            identity = TLSIdentity.ImportIdentity(_store,
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
            var db = new Database("other-database");
            _Database = db;

            X509Store _store = new X509Store(StoreName.My);
            TLSIdentity identity;

            // tag::client-cert-authenticator-root-certs[]
            byte[] caData, clientData;
            clientData = File.ReadAllBytes("C:\\client.p12"); // PKCS12 data containing private key, public key, and certificates
            caData = File.ReadAllBytes("C:\\client-ca.der");

            // Root certs
            var rootCert = new X509Certificate2(caData);
            var auth = new ListenerCertificateAuthenticator(new X509Certificate2Collection(rootCert));

            // Create URL Endpoint Listener
            var listenerConfig = new URLEndpointListenerConfiguration(_Database);
            listenerConfig.DisableTLS = false; //The default value is false which means that the TLS will be enabled by default.
            listenerConfig.Authenticator = auth;
            _listener = new URLEndpointListener(listenerConfig);
            _listener.Start();

            // Client identity
            identity = TLSIdentity.ImportIdentity(_store,
                clientData,
                "123",
                "CBL-Client-Cert",
                null);

            // Replicator -- Client
            var database = new Database("client-database");
            var builder = new UriBuilder(
                "wss",
                "localhost",
                _listener.Port,
                $"/{_listener.Config.Database.Name}"
            );

            var url = builder.Uri;
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(database, target);
            config.ReplicatorType = ReplicatorType.PushAndPull;
            config.Continuous = false;
            config.Authenticator = new ClientCertificateAuthenticator(identity);
            config.AcceptOnlySelfSignedServerCertificate = true;
            config.PinnedServerCertificate = _listener.TlsIdentity.Certs[0];
            using (var replicator = new Replicator(config)) {
                replicator.Start();
            }

            // Stop listener after replicator is stopped
            _listener.Stop();
            // end::client-cert-authenticator-root-cert
        }

        private static void TestClientCertAuthenticator()
        {
            var db = new Database("other-database");
            _Database = db;

            X509Store _store = new X509Store(StoreName.My);
            TLSIdentity identity;

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
            var listenerConfig = new URLEndpointListenerConfiguration(_Database);
            listenerConfig.DisableTLS = false; //The default value is false which means that the TLS will be enabled by default.
            listenerConfig.Authenticator = auth;
            _listener = new URLEndpointListener(listenerConfig);
            _listener.Start();

            // User Identity
            identity = TLSIdentity.CreateIdentity(false,
                new Dictionary<string, string>() { { Certificate.CommonNameAttribute, "couchbase" } },
                null,
                _store,
                ClientCertLabel,
                null);

            // Replicator -- Client
            var database = new Database("client-database");
            var builder = new UriBuilder(
                "wss",
                "localhost",
                _listener.Port,
                $"/{_listener.Config.Database.Name}"
            );

            var url = builder.Uri;
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(database, target);
            config.ReplicatorType = ReplicatorType.PushAndPull;
            config.Continuous = false;
            config.Authenticator = new ClientCertificateAuthenticator(identity);
            config.AcceptOnlySelfSignedServerCertificate = false;
            config.PinnedServerCertificate = _listener.TlsIdentity.Certs[0];
            using (var replicator = new Replicator(config)) {
                replicator.Start();
            }

            // Stop listener after replicator is stopped
            _listener.Stop();
            // end::client-cert-authenticator[]
        }

        private static void UseEncryption()
        {
            // Enterprise edition only

            // tag::database-encryption[]
            // Create a new, or open an existing database with encryption enabled
            var config = new DatabaseConfiguration
            {
                // Or, derive a key yourself and pass a byte array of the proper size
                EncryptionKey = new EncryptionKey("password")
            };

            using (var db = new Database("seekrit", config)) {
                // Change the encryption key (or add encryption if the DB is unencrypted)
                db.ChangeEncryptionKey(new EncryptionKey("betterpassw0rd"));

                // Remove encryption
                db.ChangeEncryptionKey(null);
            }
            // end::database-encryption[]
        }

        private static void ResetReplicatorCheckpoint()
        {
            var database = _Database;
            var url = new Uri("ws://localhost:4984/db");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(database, target);
            using (var replicator = new Replicator(config)) {
              // tag::replication-reset-checkpoint[]
              // replicator is a Replicator instance
              if (resetCheckpointRequired_Example) {
                  replicator.Start(true); // <.>
              else
                replicator.Start(false);
              }
              // end::replication-reset-checkpoint[]




                // end::replication-reset-checkpoint[]
            }
        }

        private static void Read1xAttachment()
        {
            var db = _Database;
            using (var document = new MutableDocument()) {
                // tag::1x-attachment[]
                var attachments = document.GetDictionary("_attachments");
                var avatar = attachments.GetBlob("avatar");
                var content = avatar?.Content;
                // end::1x-attachment[]
            }
        }

        private static void CreateNewDatabase()
        {
            // tag::new-database[]
            var db = new Database("my-database");
            // end::new-database[]

            _Database = db;
        }

        private static void CloseDatabase()
        {
          // tag::close-database[]
          database.close()

          // end::close-database[]
        }

        private static void ChangeLogging()
        {
            // tag::logging[]
            Database.SetLogLevel(LogDomain.Replicator, LogLevel.Verbose);
            Database.SetLogLevel(LogDomain.Query, LogLevel.Verbose);
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
                _NeedsExtraDocs = true;
                Database.Copy(path, "travel-sample", null);
            }
            // end::prebuilt-database[]

            _Database.Close();
            _Database = new Database("travel-sample");
        }

        private static void QueryDeletedDocuments()
        {
            // tag::query-deleted-documents[]
            // Query documents that have been deleted
            var query = QueryBuilder
                .Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(db))
                .Where(Meta.IsDeleted);
            // end::query-deleted-documents[]
        }

        private static void CreateDocument()
        {
            var db = _Database;
            // tag::initializer[]
            using (var newTask = new MutableDocument("xyz")) {
                newTask.SetString("type", "task")
                    .SetString("owner", "todo")
                    .SetDate("createdAt", DateTimeOffset.UtcNow);

                db.Save(newTask);
            }
            // end::initializer[]
        }

        private static void UpdateDocument()
        {
            var db = _Database;
            // tag::update-document[]
            using(var document = db.GetDocument("xyz"))
            using (var mutableDocument = document.ToMutable()) {
                mutableDocument.SetString("name", "apples");
                db.Save(mutableDocument);
            }
            // end::update-document[]
        }

        private static void UseTypedAccessors()
        {
            using (var newTask = new MutableDocument()) {
                // tag::date-getter[]
                newTask.SetValue("createdAt", DateTimeOffset.UtcNow);
                var date = newTask.GetDate("createdAt");
                // end::date-getter[]

                Console.WriteLine(date);
            }
        }

        private static void DoBatchOperation()
        {
            var db = _Database;
            // tag::batch[]
            db.InBatch(() =>
            {
                for (var i = 0; i < 10; i++) {
                    using (var doc = new MutableDocument()) {
                        doc.SetString("type", "user");
                        doc.SetString("name", $"user {i}");
                        doc.SetBoolean("admin", false);
                        db.Save(doc);
                        Console.WriteLine($"Saved user document {doc.GetString("name")}");
                    }
                }
            });
            // end::batch[]
        }

        private static void DatabaseChangeListener()
        {
            var db = _Database;

            // tag::document-listener[]
            db.AddDocumentChangeListener("user.john", (sender, args) =>
            {
                using (var doc = Db.GetDocument(args.DocumentID)) {
                    Console.WriteLine($"Status :: {doc.GetString("verified_account")}");
                }
            });
            // end::document-listener[]
        }

        private static void DocumentExpiration()
        {
            var db = _Database;

            // tag::document-expiration[]
            // Purge the document one day from now
            var ttl = DateTimeOffset.UtcNow.AddDays(1);
            db.SetDocumentExpiration("doc123", ttl);

            // Reset expiration
            db.SetDocumentExpiration("doc1", null);

            // Query documents that will be expired in less than five minutes
            var fiveMinutesFromNow = DateTimeOffset.UtcNow.AddMinutes(5).ToUnixTimeMilliseconds();
            var query = QueryBuilder
                .Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(db))
                .Where(Meta.Expiration.LessThan(Expression.Double(fiveMinutesFromNow)));
            // end::document-expiration[]
        }

        private static void UseBlob()
        {
            var db = _Database;
            using (var newTask = new MutableDocument()) {
                // tag::blob[]
                // Note: Reading the data is implementation dependent, as with prebuilt databases
                var image = File.ReadAllBytes("avatar.jpg"); // <.>
                var blob = new Blob("image/jpeg", image); // <.>
                 newTask.SetBlob("avatar", blob); // <.>
                db.Save(newTask);
                // end::blob[]

                var taskBlob = newTask.GetBlob("avatar");
                using (var bitmap = SKBitmap.Decode(taskBlob.ContentStream)) {
                    Console.WriteLine($"Bitmap dimensions: {bitmap.Width} x {bitmap.Height} ({bitmap.BytesPerPixel} bytes per pixel)");
                }
            }
        }

        private static void CreateIndex()
        {
            var db = _Database;

            // tag::query-index[]
            // For value types, this is optional but provides performance enhancements
            var index = IndexBuilder.ValueIndex(
                ValueIndexItem.Expression(Expression.Property("type")),
                ValueIndexItem.Expression(Expression.Property("name"))); // <.>
            db.CreateIndex("TypeNameIndex", index);
            // end::query-index[]
        }

        private static void SelectMeta()
        {
            Console.WriteLine("Select Meta");
            var db = _Database;

            // tag::query-select-meta[]
            // tag::query-select-props[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("type"),
                    SelectResult.Property("name"))
                .From(DataSource.Database(db))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Document ID :: {result.GetString("id")}");
                    Console.WriteLine($"Document Name :: {result.GetString("name")}");
                }
            }
            // end::query-select-props[]
            // end::query-select-meta[]
        }

        private static void SelectAll()
        {
            var db = _Database;

            // tag::query-select-all[]
            using (var query = QueryBuilder.Select(SelectResult.All())
                .From(DataSource.Database(db))) {
                // All user properties will be available here
            }
            // end::query-select-all[]

            // tag::live-query[]
            var query = QueryBuilder
                .Select(SelectResult.All())
                .From(DataSource.Database(db)); // <.>

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

        private static void SelectWhere()
        {
            Console.WriteLine("Where");
            var db = _Database;

            // tag::query-where[]
            using (var query = QueryBuilder.Select(SelectResult.All())
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("hotel")))
                .Limit(Expression.Int(10))) {
                foreach (var result in query.Execute()) {
                    var dict = result.GetDictionary(db.Name);
                    Console.WriteLine($"Document Name :: {dict?.GetString("name")}");
                }
            }
            // end::query-where[]
        }

        private static void UseCollectionContains()
        {
            Console.WriteLine("Collection Operator CONTAINS");
            var db = _Database;

            // tag::query-collection-operator-contains[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"),
                    SelectResult.Property("public_likes"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("hotel"))
                    .And(ArrayFunction.Contains(Expression.Property("public_likes"),
                        Expression.String("Armani Langworth"))))) {
                foreach (var result in query.Execute()) {
                    var publicLikes = result.GetArray("public_likes");
                    var jsonString = JsonConvert.SerializeObject(publicLikes);
                    Console.WriteLine($"Public Likes :: {jsonString}");
                }
            }
            // end::query-collection-operator-contains[]
        }

        private static void UseCollectionIn()
        {
            Console.WriteLine("Collection Operator IN");
            var db = _Database;

            // tag::query-collection-operator-in[]
            var values = new IExpression[]
                { Expression.Property("first"), Expression.Property("last"), Expression.Property("username") };

            using (var query = QueryBuilder.Select(
                    SelectResult.All())
                .From(DataSource.Database(db))
                .Where(Expression.String("Armani").In(values))) {
                foreach (var result in query.Execute()) {
                    var body = result.GetDictionary(0);
                    var jsonString = JsonConvert.SerializeObject(body);
                    Console.WriteLine($"In results :: {jsonString}");
                }
            }
            // end::query-collection-operator-in[]
        }

        private static void SelectLike()
        {
            Console.WriteLine("Like");
            var db = _Database;

            // tag::query-like-operator[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Function.Lower(Expression.Property("name")).Like(Expression.String("Royal Engineers Museum"))))
                .Limit(Expression.Int(10))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Name Property :: {result.GetString("name")}");
                }
            }
            // end::query-like-operator[]
        }

        private static void SelectWildcardLike()
        {
            Console.WriteLine("Wildcard Like");
            var db = _Database;

            // tag::query-like-operator-wildcard-match[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Function.Lower(Expression.Property("name")).Like(Expression.String("Eng%e%"))))
                .Limit(Expression.Int(10))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Name Property :: {result.GetString("name")}");
                }
            }
            // end::query-like-operator-wildcard-match[]
        }

        private static void SelectWildcardCharacterLike()
        {
            Console.WriteLine("Wildchard Characters");
            var db = _Database;

            // tag::query-like-operator-wildcard-character-match[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Expression.Property("name").Like(Expression.String("Royal Eng____rs Museum"))))
                .Limit(Expression.Int(10))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Name Property :: {result.GetString("name")}");
                }
            }
            // end::query-like-operator-wildcard-character-match[]
        }

        private static void SelectRegex()
        {
            Console.WriteLine("Regex");
            var db = _Database;

            // tag::query-regex-operator[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("name"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("landmark"))
                    .And(Expression.Property("name").Regex(Expression.String("\\bEng.*e\\b"))))
                .Limit(Expression.Int(10))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Name Property :: {result.GetString("name")}");
                }
            }
            // end::query-regex-operator[]
        }

        private static void SelectJoin()
        {
            Console.WriteLine("Join");
            var db = _Database;

            // tag::query-join[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Expression.Property("name").From("airline")),
                    SelectResult.Expression(Expression.Property("callsign").From("airline")),
                    SelectResult.Expression(Expression.Property("destinationairport").From("route")),
                    SelectResult.Expression(Expression.Property("stops").From("route")),
                    SelectResult.Expression(Expression.Property("airline").From("route")))
                .From(DataSource.Database(db).As("airline"))
                .Join(Join.InnerJoin(DataSource.Database(db).As("route"))
                    .On(Meta.ID.From("airline").EqualTo(Expression.Property("airlineid").From("route"))))
                .Where(Expression.Property("type").From("route").EqualTo(Expression.String("route"))
                    .And(Expression.Property("type").From("airline").EqualTo(Expression.String("airline")))
                    .And(Expression.Property("sourceairport").From("route").EqualTo(Expression.String("RIX"))))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Name Property :: {result.GetString("name")}");
                }
            }
            // end::query-join[]
        }

        private static void GroupBy()
        {
            Console.WriteLine("GroupBy");
            var db = _Database;

            // tag::query-groupby[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Function.Count(Expression.All())),
                    SelectResult.Property("country"),
                    SelectResult.Property("tz"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("airport"))
                    .And(Expression.Property("geo.alt").GreaterThanOrEqualTo(Expression.Int(300))))
                .GroupBy(Expression.Property("country"), Expression.Property("tz"))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine(
                        $"There are {result.GetInt("$1")} airports in the {result.GetString("tz")} timezone located in {result.GetString("country")} and above 300 ft");
                }
            }
            // end::query-groupby[]
        }

        private static void OrderBy()
        {
            Console.WriteLine("OrderBy");
            var db = _Database;

            // tag::query-orderby[]
            using (var query = QueryBuilder.Select(
                    SelectResult.Expression(Meta.ID),
                    SelectResult.Property("title"))
                .From(DataSource.Database(db))
                .Where(Expression.Property("type").EqualTo(Expression.String("hotel")))
                .OrderBy(Ordering.Property("title").Ascending())
                .Limit(Expression.Int(10))) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Title :: {result.GetString("title")}");
                }
            }
            // end::query-orderby[]
        }

      // ### EXPLAIN statement
      private static void TestExplainStatement()
      // For Documentation
      {
        var db = _Database;
          // tag::query-explain-all[]
        var query =
          QueryBuilder
            .Select(SelectResult.All())
            .From(DataSource.Database(db))
            .Where(Expression.Property("type").EqualTo(Expression.String("hotel")))
            .GroupBy(Expression.Property("country"))
            .OrderBy(Ordering.Property("title").Ascending()) // <.>

          Console.WriteLine(query.Explain()); // <.>

          // end::query-explain-all[]
          // tag::query-explain-like[]
var query =
  QueryBuilder
    .Select(SelectResult.All())
    .From(DataSource.Database(db))
    .Where(Expression.Property("type").Like(Expression.String("%hotel%"))
      .And(Function.Lower(Expression.Property("name")).Like(Expression.String("%royal%")))); // <.>
  Console.WriteLine(query.Explain());

          // end::query-explain-like[]
          // tag::query-explain-nopfx[]
var query =
  QueryBuilder
    .Select(SelectResult.All())
    .From(DataSource.Database(db))
    .Where(Expression.Property("type").Like(Expression.String("hotel%"))
      .And(Function.Lower(Expression.Property("name")).Like(Expression.String("%royal%")))); // <.>

  Console.WriteLine(query.Explain());

          // end::query-explain-nopfx[]
          // tag::query-explain-function[]
var query =
  QueryBuilder
    .Select(SelectResult.All())
    .From(DataSource.Database(db))
    .Where(Function.Lower(Expression.Property("type")).EqualTo(Expression.String("hotel"))); // <.>

  Console.WriteLine(query.Explain());

          // end::query-explain-function[]
          // tag::query-explain-nofunction[]
        var query =
          QueryBuilder
            .Select(SelectResult.All())
            .From(DataSource.Database(db))
            .Where(Expression.Property("type")).EqualTo(Expression.String("hotel")); // <.>

          Console.WriteLine(query.Explain());

          // end::query-explain-nofunction[]
      }

      // end query-explain





        private static void CreateFullTextIndex()
        {
            var db = _Database;
            if (_NeedsExtraDocs) {
                var tasks = new[] { "buy groceries", "play chess", "book travels", "buy museum tickets" };
                foreach (var task in tasks) {
                    using (var doc = new MutableDocument()) {
                        doc.SetString("type", "task");
                        doc.SetString("name", task);
                        db.Save(doc);
                    }
                }
            }

            // tag::fts-index[]
            var index = IndexBuilder.FullTextIndex(FullTextIndexItem.Property("name")).IgnoreAccents(false);
            db.CreateIndex("nameFTSIndex", index);
            // end::fts-index[]
        }

        private static void FullTextSearch()
        {
            Console.WriteLine("Full text search");
            var db = _Database;

            // tag::fts-query[]
            var whereClause = FullTextExpression.Index("nameFTSIndex").Match("'buy'");
            using (var query = QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(db))
                .Where(whereClause)) {
                foreach (var result in query.Execute()) {
                    Console.WriteLine($"Document id {result.GetString(0)}");
                }
            }
            // end::fts-query[]
        }
        private static void StartReplication()
        {
            var db = _Database;

            /*
             * This requires Sync Gateway running with the following config, or equivalent:
             *
             * {
             *     "log":["*"],
             *     "databases": {
             *         "db": {
             *             "server":"walrus:",
             *             "users": {
             *                 "GUEST": {"disabled": false, "admin_channels": ["*"] }
             *             }
             *         }
             *     }
             * }
             */

            // tag::replication[]
            // Note: Android emulator needs to use 10.0.2.2 for localhost (10.0.3.2 for GenyMotion)
            var url = new Uri("ws://localhost:4984/db");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(db, target)
            {
                ReplicatorType = ReplicatorType.Pull
            };

            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication[]

            _Replicator = replicator;
        }

        private static void VerboseReplicatorLogging()
        {
            // tag::replication-logging[]
            // deprecated
            Database.SetLogLevel(LogDomain.Replicator, LogLevel.Verbose);
            Database.SetLogLevel(LogDomain.Network, LogLevel.Verbose);
            // end::replication-logging[]
        }

        private static void ConsoleLogging()
        {
            // tag::console-logging[]
            Database.Log.Console.Domains = LogDomain.All; // <.>
            Database.Log.Console.LogLevel = LogLevel.Verbose; // <.>

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
                UsePlainText = false  // <.>
            };
            Database.Log.File.Config = config; // Apply configuration
            Database.Log.File.Level = LogLevel.Info; // <.>

            // end::file-logging[]
        }

        private static void EnableCustomLogging()
        {
            // tag::set-custom-logging[]
            Database.Log.Custom = new LogTestLogger(); // <.>
            or
            Database.Log.Custom = new LogTestLogger { Level = LogLevel.Warning };

            // end::set-custom-logging[]
        }

        private static void WriteConsoleLog()
        {
            // tag::write-console-logmsg[]
            Database.Log.Console.Log(LogLevel.Warning, LogDomain.Replicator, "Any old log message");
            // end::write-console-logmsg[]
        }
        private static void WriteCustomLog()
        {
            // tag::write-custom-logmsg[]
            Database.Log.Custom?.Log(LogLevel.Warning, LogDomain.Replicator, "Any old log message");
            // end::write-custom-logmsg[]
        }


        private static void WriteFileLog()
        {
            // tag::write-file-logmsg[]
            Database.Log.File.Log(LogLevel.Warning, LogDomain.Replicator, "Any old log message");
            // end::write-file-logmsg[]
        }

        private static void EnableBasicAuth()
        {
            var database = _Database;

            // tag::basic-authentication[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(database, target);
            config.Authenticator = new BasicAuthenticator("john", "pass");

            var replicator = new Replicator(config);
            replicator.Start();
            // end::basic-authentication[]
        }

        private static void EnableSessionAuth()
        {
            var database = _Database;

            // tag::session-authentication[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var config = new ReplicatorConfiguration(database, target);
            config.Authenticator = new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447");

            var replicator = new Replicator(config);
            replicator.Start();
            // end::session-authentication[]
        }

        private static void SetupReplicatorListener()
        {
            var replicator = _Replicator;

            // tag::replication-status[]
            replicator.AddChangeListener((sender, args) =>
            {
                if (args.Status.Activity == ReplicatorActivityLevel.Stopped) {
                    Console.WriteLine("Replication stopped");
                }
            });
            // end::replication-status[]
        }




    //  BEGIN PendingDocuments IB -- 11/Feb/21 --
    private static void ReplicatorPendingDocuments()
    {
        // tag::replication-pendingdocuments[]
        var url = new Uri("ws://localhost:4984/mydatabase");
        var target = new URLEndpoint(url);
        var database = new Database("myDB");
        var config = new ReplicatorConfiguration(database, target);
        config.ReplicatorType  = ReplicatorType.Push;

        // tag::replication-push-pendingdocumentids[]
        var replicator = new Replicator(config);

        var mydocids =
          new HashSet <string> (replicator.GetPendingDocumentIDs()); // <.>

        // end::replication-push-pendingdocumentids[]

        if (mydocids.Count > 0)
        {
            Console.WriteLine($"There are {mydocids.Count} documents pending");
            replicator.AddChangeListener((sender, change) =>
            {
                Console.WriteLine($"Replicator activity level is " +
                                  change.Status.Activity.ToString());
                // iterate and report-on previously
                // retrieved pending docids 'list'
                foreach (var thisId in mydocids)
                    // tag::replication-push-isdocumentpending[]
                    if (!replicator.IsDocumentPending(thisId)) // <.>
                    {
                        Console.WriteLine($"Doc ID {thisId} now pushed");
                    };
                // end::replication-push-isdocumentpending[]
            });

            replicator.Start();
        }
    // end::replication-pendingdocuments[]
    }


//  END PendingDocuments IB -- 11/Feb/21 --



		private static void ReplicatorDocumentEvent()
        {
            var replicator = _Replicator;

            // tag::add-document-replication-listener[]
            var token = replicator.AddDocumentReplicationListener((sender, args) =>
            {
                var direction = args.IsPush ? "Push" : "Pull";
                Console.WriteLine($"Replication type :: {direction}");
                foreach (var document in args.Documents) {
                    if (document.Error == null) {
                        Console.WriteLine($"Doc ID :: {document.Id}");
                        if (document.Flags.HasFlag(DocumentFlags.Deleted)) {
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
            var db = _Database;
            using (var database2 = new Database("backup")) {
                // EE feature: This code will not compile on the community edition
                // tag::database-replica[]
                var targetDatabase = new DatabaseEndpoint(database2);
                var config = new ReplicatorConfiguration(db, targetDatabase)
                {
                    ReplicatorType = ReplicatorType.Push
                };

                var replicator = new Replicator(config);
                replicator.Start();
                // end::database-replica[]

                _Replicator?.Stop();
                _Replicator = replicator;
            }
        }

        private static void PinCertificate()
        {
            // Note: No certificate is included here, so this code is for show only
            var url = new Uri("wss://localhost:4984/db");
            var target = new URLEndpoint(url);
            var db = _Database;

            // tag::certificate-pinning[]
            // Note: `GetCertificate` is a fake method. This would be the platform-specific method
            // to find and load the certificate as an instance of `X509Certificate2`.
            // For .NET Core / .NET Framework this can be loaded from the filesystem path.
            // For UWP, from the assets directory.
            // For iOS, from the main bundle.
            // For Android, from the assets directory.
            var certificate = GetCertificate("cert.cer");
            var config = new ReplicatorConfiguration(db, target)
            {
                PinnedServerCertificate = certificate
            };
            // end::certificate-pinning[]
        }

        private static void ReplicationCustomHeaders()
        {
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            // tag::replication-custom-header[]
            var config = new ReplicatorConfiguration(database, target)
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
            // tag::replication-push-filter[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var config = new ReplicatorConfiguration(database, target);
            config.PushFilter = (document, flags) => // <1>
            {
                if (flags.HasFlag(DocumentFlags.Deleted)) {
                    return false;
                }

                return true;
            };

            // Dispose() later
            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication-push-filter[]
        }

        private static void PullWithFilter(Database database)
        {
            // tag::replication-pull-filter[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var config = new ReplicatorConfiguration(database, target);
            config.PullFilter = (document, flags) => // <1>
            {
                if (document.GetString("type") == "draft") {
                    return false;
                }

                return true;
            };

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

            var config = new ReplicatorConfiguration(database, target);

        //  other config as required . . .

        // tag::replication-set-heartbeat[]
            config.Heartbeat = TimeSpan.FromSeconds(120); //  <.>
        // end::replication-set-heartbeat[]
        // tag::replication-set-maxattempts[]
            config.Maxattempts = 20; //  <.>
        // end::replication-set-maxattempts[]
        // tag::replication-set-maxattemptwaittime[]
            config.MaxAttemptWaitTime = TimeSpan.FromSeconds(600); //  <.>
        // end::replication-set-maxattemptwaittime[]

        //  other config as required . . .

            var repl = new Replicator(config);

        // end::replication-retry-config[]
        }


        private static void UsePredictiveModel()
        {
            using (var db = new Database("mydb")) {
                // tag::register-model[]
                var model = new ImageClassifierModel();
                Database.Prediction.RegisterModel("ImageClassifier", model);
                // end::register-model[]

                // tag::predictive-query-value-index[]
                var index = IndexBuilder.ValueIndex(ValueIndexItem.Property("label"));
                db.CreateIndex("value-index-image-classifier", index);
                // end::predictive-query-value-index[]

                // tag::unregister-model[]
                Database.Prediction.UnregisterModel("ImageClassifier");
                // end::unregister-model[]
            }
        }

        private static void UsePredictiveIndex()
        {
            using (var db = new Database("mydb")) {
                // tag::predictive-query-predictive-index[]
                var input = Expression.Dictionary(new Dictionary<string, object>
                {
                    ["photo"] = Expression.Property("photo")
                });

                var index = IndexBuilder.PredictiveIndex("ImageClassifier", input);
                db.CreateIndex("predictive-index-image-classifier", index);
                // end::predictive-query-predictive-index[]
            }
        }

        private static void DoPredictiveQuery()
        {
            using (var db = new Database("mydb")) {
                // tag::predictive-query[]
                var input = Expression.Dictionary(new Dictionary<string, object>
                {
                    ["photo"] = Expression.Property("photo")
                });
                var prediction = PredictiveModel.predict("ImageClassifier", input); // <1>

                using (var q = QueryBuilder.Select(SelectResult.All())
                    .From(DataSource.Database(db))
                    .Where(prediction.Property("label").EqualTo(Expression.String("car"))
                        .And(prediction.Property("probability").GreaterThanOrEqualTo(Expression.Double(0.8))))) {
                    var result = q.Execute();
                    Console.WriteLine($"Number of rows: {result.Count()}");
                }
                // end::predictive-query[]
            }
        }

        static void Main(string[] args)
        {
            // This only needs to be done once for whatever platform the executable is running
            // (UWP, iOS, Android, or desktop)
            Couchbase.Lite.Support.NetDesktop.Activate();

            CreateNewDatabase();
            CreateDocument();
            UpdateDocument();
            UseTypedAccessors();
            DoBatchOperation();
            UseBlob();
            SelectMeta();

            LoadPrebuilt();
            CreateIndex();
            SelectWhere();
            UseCollectionContains();
            SelectLike();
            SelectWildcardLike();
            SelectWildcardCharacterLike();
            SelectRegex();
            SelectJoin();
            GroupBy();
            OrderBy();

            CreateFullTextIndex();
            FullTextSearch();
            StartReplication();
            SetupReplicatorListener();

            _Replicator.Stop();
            while (_Replicator.Status.Activity != ReplicatorActivityLevel.Stopped) {
                // Database cannot close until replicators are stopped
                Console.WriteLine($"Waiting for replicator to stop (currently {_Replicator.Status.Activity})...");
                Thread.Sleep(200);
            }

            _Database.Close();
        }

        #endregion
    }

    /* ----------------------------------------------------------- */
    /* ---------------------  ACTIVE SIDE  ----------------------- */
    /* ---------------  stubs for documentation  ----------------- */
    /* ----------------------------------------------------------- */

    class ActivePeer : IMessageEndpointDelegate
    {
        ActivePeer()
        {
            var id = "";

            // tag::message-endpoint[]
            var database = new Database("dbname");

            // The delegate must implement the `IMessageEndpointDelegate` protocol.
            var messageEndpointTarget = new MessageEndpoint(uid: "UID:123", target: "",
                protocolType: ProtocolType.MessageStream, delegateObject: this);
            // end::message-endpoint[]

            // tag::message-endpoint-replicator[]
            var config = new ReplicatorConfiguration(database, messageEndpointTarget);

            // Create the replicator object
            var replicator = new Replicator(config);
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
            var config = new MessageEndpointListenerConfiguration(database, ProtocolType.MessageStream);
            _messageEndpointListener = new MessageEndpointListener(config);
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

    // tag::predictive-model[]
    // `TensorFlowModel` is a fake implementation
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
            // `TensorFlowModel` is a fake implementation
            // this would be the implementation of the ml model you have chosen
            var modelOutput = TensorFlowModel.PredictImage(imageData);
            return new MutableDictionaryObject(modelOutput); // <1>
        }
    }
    // end::predictive-model[]

    // tag::custom-logging[]
    private class LogTestLogger : ILogger
    {
        public LogLevel Level { get; set; }

        public void Reset()
        {
            _lines.Clear();
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
        Document Resolve(Conflict conflict)
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

// N1QL QUERY

  public List<Result> docsonly_N1QLQueryString(Database argDB)
  {
      DatabaseConfiguration dbCfg = new DatabaseConfiguration();

      Database thisDb = new Database(dbName, dbCfg);

      // For Documentation -- N1QL Query
      // tag::query-syntax-n1ql[]
      var thisQuery =
          thisDb.CreateQuery("SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.>

      return thisQuery.Execute().AllResults();

      // end::query-syntax-n1ql[]
  }


  public  List<Result> docsonly_N1QLQueryStringParams(Database argDB)
  {
      DatabaseConfiguration dbCfg = new DatabaseConfiguration();

      Database thisDb = new Database(dbName, dbCfg);

      // For Documentation -- N1QL Query
      // tag::query-syntax-n1ql-params[]
      // Declared elsewhere: Database argDB

      var thisQuery =
          thisDb.CreateQuery("SELECT META().id AS thisId FROM _ WHERE type = $type"); // <.>

      var n1qlParams = new Parameters();
      n1qlParams.SetString("type", "hotel"); // <.>
      thisQuery.Parameters = n1qlParams;

      return thisQuery.Execute().AllResults();

      // end::query-syntax-n1ql-params[]
  }


// QUERY RESULT SET HANDLING EXAMPLES

    public static void testQuerySyntaxAll()
    {
        // For Documentation
        var dbName = "travel-sample";

        string thisDocsId;
        string thisDocsName;
        string thisDocsType;
        string thisDocsCity;
        Dictionary<string,object> hotel = new Dictionary<string,object>();

        // tag::query-syntax-all[]
        var this_Db = new Database("hotels") ;

        var query = QueryBuilder
              .Select(SelectResult.All())
              .From(DataSource.Database(this_Db));

        // end::query-syntax-all[]

        // tag::query-access-all[]
        var results = query.Execute().AllResults();

        if (results?.Count > 0)
        {
            List<Dictionary<string,object>> hotels = new List<Dictionary<string,object>>();
            foreach (var result in results)
            {
                // get the result into our dictionary object
                var thisDocsProps = result.GetDictionary(dbName); // <.>

                if (thisDocsProps != null)
                {
                    thisDocsId = thisDocsProps.GetString("id"); // <.>
                    thisDocsName = thisDocsProps.GetString("name");
                    thisDocsCity = thisDocsProps.GetString("city");
                    thisDocsType = thisDocsProps.GetString("type");
                    hotel = thisDocsProps.ToDictionary();
                    hotels.Add(hotel);
                }

            }
        }
        // end::query-access-all[]

    // tag::query-access-json[]

    foreach (var result in query.Execute().AsEnumerable()) {

        // get the result into a JSON String
                var thisDocsJSONString = result.ToJSON();// <.>

        // Get a native dictionary object using the JSON string
        var dictFromJSONstring =
              JsonConvert.
                DeserializeObject<Dictionary<string, object>>
                  (thisDocsJSONString); // <.>

        // use the created dictionary
        if (dictFromJSONstring != null)
        {
            thisDocsId = dictFromJSONstring["id"].ToString();
            thisDocsName = dictFromJSONstring["name"].ToString();
            thisDocsCity = dictFromJSONstring["city"].ToString();
            thisDocsType = dictFromJSONstring["type"].ToString();
        }

        //Get a custom object using the JSON string
        Hotel this_hotel =
            JsonConvert.DeserializeObject<Hotel>(thisDocsJSONString); // <.>

        // Store this hotel object in a list of hotels
        hotels.Add(
            this_hotel.Id.ToString(),
                this_hotel);

    } // end foreach result
    // end::query-access-json[]
  }


    private static void testQuerySyntaxProps()
    {
        // For Documentation
        var dbName = "travel-sample";
        // var this_Db = new Database(dbName);

        string thisDocsName;
        string thisDocsType;
        string thisDocsCity;
        // tag::query-syntax-props[]
        var this_Db = new Database("hotels") ;

        Dictionary<string, object> hotel = new Dictionary<string, object>();

        List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();

        var query = QueryBuilder.Select(
                SelectResult.Property("type"),
                SelectResult.Property("name"),
                SelectResult.Property("city")).From(DataSource.Database(this_Db));
        // end::query-syntax-props[]

        // tag::query-access-props[]
        var results = query.Execute().AllResults();
        foreach (var result in results)
        {

            // get the returned array of k-v pairs into a dictionary
            hotel = result.ToDictionary();

            // add hotel dictionary to list of hotel dictionaries
            hotels.Add(hotel);

            // use the properties of the returned array of k-v pairs directly
            thisDocsType = result.GetString("type");
            thisDocsName = result.GetString("name");
            thisDocsCity = result.GetString("city");

        }

    // end::query-access-props[]
    } // test-query-access-props



    private static void testQuerySyntaxCount()
    {
        // For Documentation
        var dbName = "travel-sample";
        // var this_Db = new Database(dbName);

        Dictionary<string, object> hotel = new Dictionary<string, object>();
        List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();

        // tag::query-syntax-count-only[]
        var this_Db = new Database("hotels") ;

        var query =
          QueryBuilder
            .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount")) // <.>
            .From(DataSource.Database(this_Db));

        // end::query-syntax-count-only[]


        // tag::query-access-count-only[]

        var results = query.Execute().AllResults();

        foreach (var result in results)
        {

            var numberOfDocs = result.GetInt("mycount"); // <.>

        }

        // end::query-access-count-only[]
    }




    private static void ibQueryForID()
    {

        // For Documentation
        var dbName = "travel-sample";
        // var this_Db = new Database(dbName);

        Dictionary<string, object> hotel = new Dictionary<string, object>();
        List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();


        // tag::query-syntax-id[]
        var this_Db = new Database("hotels") ;

        var query = QueryBuilder
                .Select(SelectResult.Expression(Meta.ID).As("this_ID"))
                .From(DataSource.Database(this_Db));

        // end::query-syntax-id[]


        // tag::query-access-id[]
        var results = query.Execute().AllResults();
        foreach (var result in results)
        {

            var thisDocsID = result.GetString("this_ID"); // <.>
            var doc = this_Db.GetDocument(thisDocsID);
        }

        // end::query-access-id[]
    }


// tag::query-syntax-pagination-all[]
    private static void testQueryPagination()
    {
      // For Documentation
      var dbName = "travel-sample";
      // var this_Db = new Database(dbName);

    // tag::query-syntax-pagination[]
      var this_Db = new Database("hotels") ;

      var thisLimit = 20;
      var thisOffset = 0;

      // get a count of the number of docs matching the query
      var countQuery =
          QueryBuilder
              .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount"))
              .From(DataSource.Database(this_Db));
      var numberOfDocs =
          countQuery.Execute().AllResults().ElementAt(0).GetInt("mycount");

      if (numberOfDocs < thisLimit) {
          thisLimit = numberOfDocs;
      }

      while (thisOffset < numberOfDocs)
      {
          var listQuery =
              QueryBuilder
                  .Select(SelectResult.All())
                  .From(DataSource.Database(this_Db))
                  .Limit(Expression.Int(thisLimit), Expression.Int(thisOffset)); // <.>

          foreach (var result in listQuery.Execute().AllResults())
          {
              // Display and or process query results batch

          }

          thisOffset = thisOffset + thisLimit;

      } // end while

// end::query-syntax-pagination[]
// end::query-syntax-pagination-all[]
    }

    // JSONAPIMETHODS



        public void JsonApiDocument()
        {

            // tag::tojson-document[]
            Database this_DB = new Database("travel-sample");
            Database newDb = new Database("ournewdb");

            // Get a document
            var thisDoc = this_Db.GetDocument("hotel_10025");

            // Get document data as JSON String
            var thisDocAsJsonString = thisDoc?.ToJSON(); // <.>

            // Get Json Object from the Json String
            JObject myJsonObj = JObject.Parse(thisDocAsJsonString);

            // Get Native Object (anhotel) from JSON String
            List<Hotel> thehotels = new List<Hotel>();

            Hotel anhotel = new Hotel();
            anhotel = JsonConvert.DeserializeObject<Hotel>(thisDocAsJsonString);
            thehotels.Add(anhotel);

            // Update the retrieved native object
            anhotel.Name = "A Copy of " + anhotel.Name;
            anhotel.Id = "2001";

            // Convert the updated object back to a JSON string
            var newJsonString = JsonConvert.SerializeObject(anhotel);

            // Update new document with JSOn String
            MutableDocument newhotel =
                new MutableDocument(anhotel.Id, newJsonString); // <.>

            foreach (string key in newhotel.ToDictionary().Keys)
            {
                System.Console.WriteLine("Data -- {0} = {1}",
                    key, newhotel.GetValue(key));
            }

            newDb.Save(newhotel);

            var thatDoc = newDb.GetDocument("2001").ToJSON(); // <.>
            System.Console.Write(thatDoc);

            // end::tojson-document[]


        //    // tag::tojson-document-output[]
        //    JSON String = { "description":"Very good and central","id":"1000","country":"France","name":"Hotel Ted","type":"hotel","city":"Paris"}
        //             type = hotel
        //             id = 1000
        //             country = France
        //             city = Paris
        //             description = Very good and central
        //             name = Hotel Ted
        //        // end::tojson-document-output[]
        //         */

        } // End JSONAPIDocument


    public void JsonApiArray()
        {
            // Init for docs
            //var this_Db = DataStore.getDbHandle();
            var ourdbname = "ournewdb";

            if (Database.Exists(ourdbname, "/"))
            {
                Database.Delete(ourdbname, "/");
            }

        // tag::tojson-array[]

            Database dbNew = new Database(ourdbname);

            // JSON String -- an Array (3 elements. including embedded arrays)
            var thisJSONstring = "[{'id':'1000','type':'hotel','name':'Hotel Ted','city':'Paris','country':'France','description':'Undefined description for Hotel Ted'},{'id':'1001','type':'hotel','name':'Hotel Fred','city':'London','country':'England','description':'Undefined description for Hotel Fred'},                        {'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}]".Replace("'", "\"");

            // Get JSON Array from JSON String
            JArray myJsonObj = JArray.Parse(thisJSONstring);

            // Create mutable array using JSON String Array
            var myArray = new MutableArrayObject();
            myArray.SetJSON(thisJSONstring);  // <.>


            // Create a new documenty for each array element
            for (int i = 0; i < myArray.Count; i++)
            {
                var dict = myArray.GetDictionary(i);
                var docid = myArray[i].Dictionary.GetString("id");
                var newdoc = new MutableDocument(docid, dict.ToDictionary()); // <.>
                dbNew.Save(newdoc);
            }

            // Get one of the created docs and iterate through one of the embedded arrays
            var extendedDoc = dbNew.GetDocument("1002");
            var features = extendedDoc.GetArray("features");
            // <.>
            foreach (string feature in features) {
                System.Console.Write(feature);
                //process array item as required
            }
            var featuresJSON = extendedDoc.GetArray("features").ToJSON(); // <.>

            // end::tojson-array[]
        }


        public void JsonApiDictionary()
        {

            var ourdbname = "ournewdb";

            if (Database.Exists(ourdbname, "/"))
            {
                Database.Delete(ourdbname, "/");
            }
            Database dbNew = new Database(ourdbname);

            // tag::tojson-dictionary[]

            // Get dictionary from JSONstring
            var aJSONstring = "{'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}".Replace("'", "\"");
            var myDict = new MutableDictionaryObject(json: aJSONstring); // <.>

            // use dictionary to get name value
            var name = myDict.GetString("name");


            // Iterate through keys
            foreach (string key in myDict.Keys)
            {
                System.Console.WriteLine("Data -- {0} = {1}", key, myDict.GetValue(key).ToString());

            }
            // end::tojson-dictionary[]

            /*
            // tag::tojson-dictionary-output[]

                mono-stdout: Data -- id = 1002
                mono-stdout: Data -- type = hotel
                mono-stdout: Data -- name = Hotel Ned
                mono-stdout: Data -- city = Balmain
                mono-stdout: Data -- country = Australia
                mono-stdout: Data -- description = Undefined description for Hotel Ned
                mono-stdout: Data -- features = Couchbase.Lite.MutableArrayObject

            // end::tojson-dictionary-output[]
            */
        } /* end of func */


         public void JsonApiBlob()
        {
            // Init
            var ourpath = DataStore.getUserFolder();
            var ourdbname = "ournewdb";
            var userName = "ian";
            //ourpath = Path.Combine(ourpath,userName);

            if (Database.Exists(ourdbname, ourpath))
            {
                Database.Delete(ourdbname, ourpath);
            }
            var dbCfg = new DatabaseConfiguration();
            dbCfg.Directory=ourpath;
            Database dbNew = new Database(ourdbname,dbCfg);

            // tag::tojson-blob[]

            // Initialize base document for blob from a JSON string
            var docId = "1002";
            var aJSONstring = "{'ref':'hotel_1002','type':'hotel','name':'Hotel Ned'," +
                "'city':'Balmain','country':'Australia'," +
                "'description':'Undefined description for Hotel Ned'," +
                "'features':['Cable TV','Toaster','Microwave']}".Replace("'", "\"");
            var myDoc = new MutableDocument(docId, aJSONstring); // <.>


            // Get the content (an image), create blob and add to doc)
            var defaultDirectory =
                Path.Combine(Service.GetInstance<IDefaultDirectoryResolver>()
                            .DefaultDirectory(),
                                userName);
            var myImagePath = Path.Combine(defaultDirectory, "avatarimage.jpg");
            var myImageUri = new Uri(myImagePath.ToString());
            var myBlob = new Blob("image/jpg", myImageUri); // <.>
            myDoc.SetBlob("avatar", myBlob); // <.>


            // This example generates a 'blob not saved' exception
            try { Console.WriteLine("myBlob (unsaved) as JSON = {0}", myBlob.ToJSON());}
                catch (Exception e)
                    {Console.WriteLine("Exception = {0}", e.Message);}

            dbNew.Save(myDoc);

            // Alternatively -- depending on use case
            dbNew.SaveBlob(new Blob("image/jpg", myImageUri)); // <.>


            // Retrieve saved doc, get blob as JSON andheck its still a 'blob'
            var sameDoc = dbNew.GetDocument(docId);
            var reconstitutedBlob = new MutableDictionaryObject().
                SetDictionary("blobCOPY", new MutableDictionaryObject(sameDoc.GetBlob("avatar").ToJSON())); // <.>

            if (Blob.IsBlob(
                    reconstitutedBlob.GetDictionary("blobCOPY").ToDictionary()))  //<.>
            {
               //... process accordingly
               Console.WriteLine("Its a Blob!!");
            }

            // end::tojson-blob[]
            var datavalue = "";
            foreach (string key in myDoc.Keys)
            {
                if (key == "features")
                {
                    datavalue = "features are: ";
                    foreach (string item in myDoc.GetArray(key))
                    {
                        datavalue = datavalue + ", " + item;
                    }
                }
                else if (key == "avatar")
                {
                    datavalue = sameDoc.GetBlob(key).ToJSON();
                }
                else
                {
                    datavalue = sameDoc.GetValue(key).ToString();
                }

                System.Console.WriteLine(" Data -- {0} = {1}", key, datavalue);
            }

            // System.Console.WriteLine(" reconstitutedBlob = {0}", reconstitutedBlob.GetDictionary("blobCOPY").ToJSON());



            //}

            /*
            // tag::tojson-blob-output[]


                Exception = Missing Digest Due To Blob Is Not Saved To Database yet.

                Data -- id = 1002
                Data -- type = hotel
                Data -- name = Hotel Ned
                Data -- city = Balmain
                Data -- country = Australia
                Data -- description = Undefined description for Hotel Ned
                Data -- features = features are: , Cable TV, Toaster, Microwave
                Data -- avatar = {"digest":"sha1-sdCxeOeP3IZV4FEvVVlvtulpWA8=","length":2975,"content_type":"image/jpg","@type":"blob"}

                blobAsJSONstring = {"digest":"sha1-sdCxeOeP3IZV4FEvVVlvtulpWA8=","length":2975,"content_type":"image/jpg","@type":"blob"}

            // end::tojson-blob-output[]
            */
        } /* end of func */




  } // end of class



// p2p sync items


// tag::listener-simple[]
var thisConfig = new URLEndpointListenerConfiguration(thisDB); // <.>

thisConfig.Authenticator =
  new ListenerPasswordAuthenticator(
    (sender, username, password) =>
      {
      return username.equals("valid.user")  && (password == validPassword);
      }
  ); // <.>

_thisListener = new URLEndpointListener(thisConfig); // <.>

_thisListener.Start(); // <.>

// end::listener-simple[]



// tag::replicator-simple[]
var theListenerEndpoint = new URLEndpoint("wss://listener.com:4984/otherDB"); // <.>

var thisConfig = new ReplicatorConfiguration(thisDB, theListenerEndpoint); // <.>

thisConfig.AcceptOnlySelfSignedServerCertificate = true; // <.>

thisConfig.Authenticator =
  new BasicAuthenticator("valid.user", "valid.password.string"); // <.>

var thisReplicator = new Replicator(thisConfig); // <.>

thisReplicator.Start(); // <.>

// end::replicator-simple[]







// PASSIVE PEER STUFF
// Stuff I adapted
//
//
// p2pSync-websockets.cs
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
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Threading;
using System.Threading.Tasks;

using Couchbase.Lite;
using Couchbase.Lite.Enterprise.Query;
using Couchbase.Lite.Logging;
using Couchbase.Lite.P2P;
using Couchbase.Lite.Query;
using Couchbase.Lite.Sync;
using Newtonsoft.Json;

using SkiaSharp;
namespace api_walkthrough
{
  class Program
  {
  private static Database _Database;
  private static Replicator _Replicator;
  private static ListenerToken _thisListenerToken;
  private static bool _NeedsExtraDocs;

  #region Private Methods
  private static void GettingStarted()
  {
    // tag::listener-initialize[]

    // tag::listener-config-db[]
    // Initialize the listener config
    var thisConfig = new URLEndpointListenerConfiguration(thisDB); // <.>

    // end::listener-config-db[]
    // tag::listener-config-port[]
    thisConfig.Port = 55990; //<.>

    // end::listener-config-port[]
    // tag::listener-config-netw-iface[]
    thisConfig.NetworkInterface = "10.1.1.10"; // <.>

    // end::listener-config-netw-iface[]
    // tag::listener-config-delta-sync[]
    thisConfig.EnableDeltaSync = true; // <.>

    // end::listener-config-delta-sync[]
    // tag::listener-config-tls-full[]
    // tag::listener-config-tls-enable[]
    thisConfig.DisableTLS = false; // <.>

    // end::listener-config-tls-enable[]
    // tag::listener-config-tls-id-anon[]
    // Use an Anonymous Self-Signed Cert
    thisConfig.TlsIdentity = null; // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-client-auth-pwd[]
    // Configure the client authenticator
    // Here we are using Basic Authentication) <.>
    SecureString validPassword =  new SecureString(); /* example only */
    // Get SecureString input for validPassword
    var validUser = "valid.username";
    thisConfig.Authenticator = new ListenerPasswordAuthenticator(
      (sender, validUser, validPassword) =>
        {
          return username.equals(validUser)  && password == validPassword);
        }
      );

    // end::listener-config-client-auth-pwd[]
    // tag::listener-start[]
    // Initialize the listener
    _thisListener = new URLEndpointListener(thisConfig); // <.>

    // Start the listener
    thisListener.Start(); // <.>

    // end::listener-start[]
    // end::listener-initialize[]
  }

  // tag::old-listener-config-tls-disable[]
  thisConfig.disableTLS = true;
  // end::old-listener-config-tls-disable[]

  // tag::listener-config-tls-id-nil-2[]

  // Use “anonymous” cert. These are self signed certs created by the system
  thisConfig.TlsIdentity = null;
  // end::listener-config-tls-id-nil-2[]


  // tag::old-listener-config-delta-sync[]
  thisConfig.EnableDeltaSync = true;
  // end::old-listener-config-delta-sync[]


  // tag::listener-status-check[]
  int connectionCount = thisListener.Status.ConnectionCount; // <.>
  int activeConnectionCount = thisListener.Status.ActiveConnectionCount;  // <.>

  // end::listener-status-check[]


  // tag::listener-stop[]
  thisListener.Stop();

  // end::listener-stop[]

// Additional snippets


// tag::listener-get-network-interfaces[]
foreach(NetworkInterface ni in NetworkInterface.GetAllNetworkInterfaces())
{
  if(ni.NetworkInterfaceType == NetworkInterfaceType.Wireless80211 ||
      ni.NetworkInterfaceType == NetworkInterfaceType.Ethernet)
  {
    // do something with the interface(s)
  }
}

// end::listener-get-network-interfaces[]


// tag::listener-get-url-list[]
var thisConfig = new URLEndpointListenerConfiguration(thisDB);
_thisListener = new URLEndpointListener(thisConfig);

_thisListener.Start();

 Console.WriteLine("URLS are {0} ", thisListener.Urls;

// end::listener-get-url-list[]

    // tag::listener-config-tls-disable[]
    thisConfig.DisableTLS = true; // <.>

    // end::listener-config-tls-disable[]

    // tag::listener-local-db[]
    // . . . preceding application logic . . .
    // Get the database (and create it if it doesn't exist)
    var thisDB = new Database("mydb");

    // end::listener-local-db[]

    // tag::listener-config-tls-id-full[]
    // tag::listener-config-tls-id-caCert[]
    // Use CA Cert
    // Create a TLSIdentity from an imported key-pair
    // . . . previously declared variables include ...
    TLSIdentity thisIdentity;
    X509Store _store =
      new X509Store(StoreName.My); // create and label x509 store

    // Get keys and certificates from PKCS12 data
    byte[] thisIdData =
      File.ReadAllBytes("c:client.p12"); // <.>
    // . . . other user code . . .

    // tag::import-tls-identity[]
    thisIdentity = TLSIdentity.ImportIdentity(
      _store,
      thisIdData, // <.>
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
    thisConfig.TlsIdentity = null; // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-tls-id-set[]
    // Set the TLS Identity
    thisConfig.TlsIdentity = thisIdentity; // <.>

    // end::listener-config-tls-id-set[]
    // end::listener-config-tls-id-full[]

    // tag::listener-config-client-auth-root[]
    // Configure the client authenticator
    // to validate using ROOT CA

    // Get the valid cert chain, in this instance from
    // PKCS12 data containing private key, public key
    // and certificates <.>
    var clientData = File.ReadAllBytes("c:client.p12");
    var ourCaData = File.ReadAllBytes("c:client-ca.der");

    // Get the root certs from the data
    var thisRootCert = new X509Certificate2(ourCaData); // <.>

    // Configure the authenticator to use the root certs
    var thisAuth = new ListenerCertificateAuthenticator(new X509Certificate2Collection(thisRootCert));

    thisConfig.Authenticator = thisAuth; // <.>

    // Initialize the listener using the config
    _listener = new URLEndpointListener(thisConfig);

    // end::listener-config-client-auth-root[]
    // tag::listener-config-client-auth-lambda[]
    // Configure the client authenticator
    // to validate using application logic

    // Get the valid cert chain, in this instance from
    // PKCS12 data containing private key, public key
    // and certificates <.>
    clientData = File.ReadAllBytes("c:client.p12");
    ourCaData = File.ReadAllBytes("c:client-ca.der");

    // Get the root certs from the data
    var thisRootCert = new X509Certificate2(ourCaData);

    // Configure the authenticator to pass the root certs
    // To a user supplied code block for authentication
    var thisAuth =
      new ListenerCertificateAuthenticator(
        new X509Certificate2Collection(thisRootCert) => {
          // . . . user supplied code block
          // . . . returns boolean value (true=authenticated)
        }); // <.>

    thisConfig.Authenticator = thisAuth; // <.>

    // end::listener-config-client-auth-lambda[]



// END Additional






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

// tag::listener-config-tls-id-caCert-callouts[]
  <.> Ensure TLS is enabled.
  <.> The identity will be stored in the secure storage using the given label
  <.> PKCS12 data containing private key, public key, and certificates
  <.> The key pair as stored in the byte array
  <.> The password required to access the certificate data
  <.> The key label assigned to the cert in certificate map and used for retrieval
  <.> If null, the same default directory for a Couchbase Lite database is used for map
  <.> Use the TLSIdentity `thisIdentity.`

// end::listener-config-tls-id-caCert-callouts[]

  // tag::listener-config-tls-id-SelfSigned-callouts[]
  <.> Ensure TLS is enabled.
  <.> The identity will be stored in the secure storage using the given label
  <.> When creating a certificate, the common name attribute is required to create a CSR. If the common name is not present in the certificate an exception is thrown.
  <.> If the expiration date is not specified, the expiration date of the certificate is 365 days after creation
  <.> The key label to get cert in certificate map
  <.> If null, the same default directory for a Couchbase Lite database is used for map
  <.> Use the TLSIdentity `thisIdentity.`

  // end::listener-config-tls-id-SelfSigned-callouts[]

// end::listener-callouts-full[]








// tag::old-listener-config-client-auth-root[]
  // cert is a pre-populated object of type:SecCertificate representing a certificate
  // Work in progress. Code snippet to be provided.

  // end::old-listener-config-client-auth-root[]


  // prev content of listener-config-client-auth-self-signed (for ios)
  thisConfig.authenticator = ListenerCertificateAuthenticator.init {
    (cert) -> Bool in
    var cert:SecCertificate
    var certCommonName:CFString?
    let status=SecCertificateCopyCommonName(cert, &certCommonName)
    if (self._allowlistedUsers.contains(["name": certCommonName! as String])) {
      return true
    }
    return false
  }
  // tag::spare-listener-config-client-auth-self-signed[]
  // Work in progress. Code snippet to be provided.

  // end::spare-listener-config-client-auth-self-signed[]

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
    // . . . preceding code. for example . . .
    private static ListenerToken _thisListenerToken;
    var Database thisDB;
    // . . . other code . . .
    // tag::p2p-act-rep-initialize[]
    // initialize the replicator configuration

    var thisUrl = new URLEndpoint("wss://listener.com:4984/otherDB"); // <.>
    var config = new ReplicatorConfiguration(thisDB, thisUrl);

    // end::p2p-act-rep-initialize[]
    // tag::p2p-act-rep-config-type[]

    // Set replicator type
    thisConfig.ReplicatorType = ReplicatorType.PushAndPull;

    // end::p2p-act-rep-config-type[]
    // tag::autopurge-override[]
    // Set autopurge option
    // here we override its default
    thisConfig.EnableAutoPurge = false; // <.>

    // end::autopurge-override[]
    // tag::p2p-act-rep-config-cont[]
    // Configure Sync Mode
    thisConfig.Continuous = true; // default value

    // end::p2p-act-rep-config-cont[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Security -- only accept self-signed certs
    thisConfig.AcceptOnlySelfSignedServerCertificate = true; // <.>

    // end::p2p-act-rep-config-self-cert[]
    // Configure Client Security // <.>
    // tag::p2p-act-rep-auth[]
    // Configure basic auth using user credentials
    thisConfig.Authenticator = new BasicAuthenticator("Our Username", "Our Password");

    // end::p2p-act-rep-auth[]
    // tag::p2p-act-rep-config-conflict-full[]
    // tag::p2p-act-rep-config-conflict-builtin[]
    /* Optionally set a conflict resolver call back */ // <.>
    // Use built-in resolver
    thisConfig.ConflictResolver = new LocalWinConflictResolver();  //

    // end::p2p-act-rep-config-conflict-builtin[]
    // tag::p2p-act-rep-config-conflict-custom[]
    // optionally use custom resolver
    thisConfig.ConflictResolver = new ConflictResolver(
      (conflict) => {
        /* define resolver function */
      }
    ); //

    // end::p2p-act-rep-config-conflict-custom[]
    // end::p2p-act-rep-config-conflict-full[]
    // tag::p2p-act-rep-start-full[]
    // Initialize and start a replicator
    // Initialize replicator with configuration data
    var thisReplicator = new Replicator(thisConfig); // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-add-change-listener-label[]
    //Optionally add a change listener // <.>
    // end::p2p-act-rep-add-change-listener-label[]
    _thisListenerToken =
      thisReplicator.AddChangeListener((sender, args) =>
        {
          if (args.Status.Activity == ReplicatorActivityLevel.Stopped) {
              Console.WriteLine("Replication stopped");
          }
        });

    // end::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-start[]
    // Start replicator
    thisReplicator.Start(); // <.>

    // end::p2p-act-rep-start[]
// end::p2p-act-rep-start-full[]
// end::p2p-act-rep-func[]         ***** End p2p-act-rep-func
}

// Additional snippets

    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security -- only accept CA certs
    thisConfig.AcceptOnlySelfSignedServerCertificate = false; // <.>

    // end::p2p-act-rep-config-cacert[]
    // tag::p2p-act-rep-config-pinnedcert[]

    // Return the remote pinned cert (the listener's cert)
    byte returnedCert = new byte(thisConfig.getPinnedCertificate()); // Get listener cert if pinned
    // end::p2p-act-rep-config-pinnedcert[]
    // Configure Client Security // <.>
    // tag::p2p-act-rep-auth[]
    // Configure basic auth using user credentials
    thisConfig.Authenticator = new BasicAuthenticator("Our Username", "Our Password");

    // end::p2p-act-rep-auth[]
    // end::p2p-act-rep-config-tls-full[]

    // tag::p2p-act-rep-config-cacert-pinned[]
    // Only CA Certs accepted
    thisConfig.AcceptOnlySelfSignedServerCertificate =
      false; // <.>

    var thisCert =
      new X509Certificate2(caData); // <.>

    thisConfig.PinnedServerCertificate =
      thisCert; // <.>

    // end::p2p-act-rep-config-cacert-pinned[]












    // Code to refactor
    Log.i(TAG, "The Replicator is currently " + thisReplicator.Status().getActivityLevel());

    Log.i(TAG, "The Replicator has processed " + t);

    if (thisReplicator.Status().getActivityLevel() == Replicator.ActivityLevel.BUSY) {
          Log.i(TAG, "Replication Processing");
          Log.i(TAG, "It has completed " + thisReplicator.Status().getProgess().getTotal() + " changes");
      }
    // tag::p2p-act-rep-status[]
    _thisReplicator.Stop();
    while (_thisReplicator.Status.Activity != ReplicatorActivityLevel.Stopped) {
        // Database cannot close until replicators are stopped
        Console.WriteLine($"Waiting for replicator to stop (currently {_thisReplicator.Status.Activity})...");
        Thread.Sleep(200);
    }
    _thisDatabase.Close();
    // end::p2p-act-rep-status[]

      // tag::p2p-act-rep-stop[]
      // Stop replication.
      thisReplicator.Stop(); // <.>
      // end::p2p-act-rep-stop[]


  }

{
  CouchbaseLite.init(context);
  Database thisDB = new Database("passivepeerdb");  // <.>
  // Initialize the listener config
  final URLEndpointListenerConfiguration thisConfig = new URLEndpointListenerConfiguration(database);
  thisConfig.Port(55990)             // <.> Default- port is selected
  thisConfig.DisableTls(false)       // <.> Optional. Defaults to false. You get TLS encryption out-of-box
  thisConfig.EnableDeltaSync(true)   // <.> Optional. Defaults to false.

  // Configure the client authenticator (if using basic auth)
  ListenerPasswordAuthenticator auth = new ListenerPasswordAuthenticator { "Our Username", "Our Password"}; // <.>
  thisConfig.Authenticator(auth); // <.>

  // Initialize the listener
  final URLEndpointListener listener = new URLEndpointListener( thisConfig ); // <.>

  // Start the listener
  listener.Start(); // <.>
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
. . . work in progress - GetHashCode snippet to be provided
// end::p2p-tlsid-store-in-keychain[]

// tag::deleteTlsIdentity[]
// tag::p2p-tlsid-delete-id-from-keychain[]
TLSIdentity.DeleteIdentity(_store, "alias-to-delete", null);

// end::p2p-tlsid-delete-id-from-keychain[]
// end::deleteTlsIdentity[]

// tag::retrieveTlsIdentity[]
// OPTIONALLY:: Retrieve a stored TLS identity using its alias/label

TLSIdentity thisIdentity = new TLSIdentity.getIdentity("CBL-Demo-Server-Cert")
// end::retrieveTlsIdentity[]


    // Configure the client authenticator (if using Basic Authentication)
    // String validUser = new String("validUsername"); // an example username
    // String validPassword = new String("validPasswordValue"); // an example password

    // ListenerPasswordAuthenticator thisAuth = new ListenerPasswordAuthenticator( // <.>
    //   validUser, validPassword -> validUser == "validUsername" && validPassword == "validPasswordValue" );

    // if (thisAuth) {
    //   thisConfig.Authenticator(auth);
    // }
    // else {
    //   // . . . authentication failed take appropriate exception action
    //   return
    // };




    // tag::old-p2p-act-rep-add-change-listener[]
    ListenerToken thisListener = new thisReplicator.addChangeListener(change -> { // <.>
      if (change.Status().getError() != null) {
        Log.i(TAG, "Error code ::  " + change.Status().getError().getCode());
      }
    });

    // end::old-p2p-act-rep-add-change-listener[]



// g u b b i n s
// tag::duff-p2p-tlsid-tlsidentity-with-label[]


    // Configure TLS Cert CA auth using key-stored cert id alias 'doc-sync-server'

    // TLSIdentity thisIdentity = new TLSIdentity.getIdentity("doc-sync-server"); // Get existing TLS ID from sec storage

    // ClientCertificateAuthenticator thisAuth = new ClientCertificateAuthenticator(thisIdentity);

    // thisConfig.Authenticator(thisAuth);



    // USE KEYCHAIN IDENTITY IF EXISTS
    // Check if Id exists in keychain. If so use that Id

    // STILL NEED TO REFACTOR

    do {
      if let thisIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") {
          print("An identity with label : doco-sync-server already exists in keychain")
          return thisIdentity
          }
    } catch
    {return nil}
    thisAuthenticator.ClientCertificateAuthenticator(identity: thisIdentity )
    thisConfig.thisAuthenticator

    // end::duff-p2p-tlsid-tlsidentity-with-label[]


// tag::old-deleteTlsIdentity[]

String thisAlias = "alias-to-delete";
KeyStore thisKeystore = KeyStore.getInstance("PKCS12"); // <.>
thisKeyStore.load= null;
if (thisAlias != null) {
   thisKeystore.deleteEntry(thisAlias);  // <.>
}

// end::old-deleteTlsIdentity[]


// cert auth
let rootCertData = SecCertificateCopyData(cert) as Data
let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
// Listener:
thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

SecCertificate thisCert = new SecCertificate(); // populated as nec.

Data rootCertData = new Data(SecCertificateCopyData(thisCert));

let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
// Listener:
thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])
// cert auth


// C A L L O U T S

// tag::p2p-act-rep-config-cacert-pinned-callouts[]
<.> Configure to accept only CA certs
<.> Configure the pinned certificate using data from the byte array `cert`
<.> Set the certificate to be compared with that provided by the server
// end::p2p-act-rep-config-cacert-pinned-callouts[]

// tag::??p2p-tlsid-tlsidentity-with-label-callouts[]
<.> PKCS12 data containing private key, public key, and certificates
<.> This is the default value and means that TLS is enabled
// end::??p2p-tlsid-tlsidentity-with-label-callouts[]

// tag::p2p-tlsid-tlsidentity-with-label-callouts[]
<.> Refuse self-signed certificates
<.> Get the identity
<.> Set the Client Certificate Authenticator to require signed certificates with this identity

// end::p2p-tlsid-tlsidentity-with-label-callouts[]


    // tag::old-listener-config-client-root-ca[]
    // Configure the client authenticator
    // to validate using ROOT CA <.>
    byte[] thisCaData; // byte array for CA data
    using (var thisReader = new BinaryReader(stream)) {
      thisCaData = thisReader.ReadBytes(int stream.Length);
    }; // Get cert data

    var thisRootCert = new X509Certificate(thisCaData); //

    thisConfig.Authenticator = new  ListenerCertificateAuthenticator(
      new X509Certificate2Collection(thisRootCert)
    );

    // end::old-listener-config-client-root-ca[]



        // tag::p2p-tlsid-tlsidentity-with-label-per-sam[]
    var db = new Database("other-database");
    _Database = db;
    X509Store _store = new X509Store(StoreName.My);
    TLSIdentity thisIdentity;

    // tag::client-cert-authenticator-root-certs[]

    // Configure the expected server-supplied
    // credentials -- only accept CA Certs
    thisConfig.AcceptOnlySelfSignedServerCertificate = false; // <.>

    // Client identity
    thisIdentity =
      TLSIdentity.ImportIdentity(_store,
        clientData,
        "123",
        "CBL-Client-Cert",
        null); // <.>

    thisConfig.Authenticator =
      new ClientCertificateAuthenticator(thisIdentity); // <.>

    // end::client-cert-authenticator-root-certs[]





    byte[] thisCaData, thisClientData;
    thisClientData = File.ReadAllBytes("C:\\client.p12"); // <.>
    thisCaData = File.ReadAllBytes("C:\\client-ca.der");

    // Root certs
    var thisRootCert = new X509Certificate2(thisCaData);
    var thisAuth =
      new ListenerCertificateAuthenticator(
        new X509Certificate2Collection(thisRootCert));

    // Create URL Endpoint Listener
    var thisConfig = new URLEndpointListenerConfiguration(_Database);
    thisConfig.DisableTLS = false; // <.>
    thisConfig.Authenticator = thisAuth;
    _listener = new URLEndpointListener(thisConfig);
    _listener.Start();

    // Client identity
    thisIdentity = TLSIdentity.ImportIdentity(_store,
        thisClientData,
        "123",
        "CBL-Client-Cert",
        null);

    // Replicator -- Client
    var database = new Database("client-database");
    var builder = new UriBuilder(
        "wss",
        "localhost",
        _listener.Port,
        $"/{_listener.thisConfig.Database.Name}"
    );

    var url = builder.Uri;
    var target = new URLEndpoint(url);
    var thisConfig = new ReplicatorConfiguration(database, target);
    thisConfig.ReplicatorType = ReplicatorType.PushAndPull;
    thisConfig.Continuous = false;
    thisConfig.Authenticator = new ClientCertificateAuthenticator(thisIdentity);
    thisConfig.AcceptOnlySelfSignedServerCertificate = true;
    thisConfig.PinnedServerCertificate = _listener.TlsIdentity.Certs[0];
    using (var replicator = new Replicator(thisConfig)) {
        replicator.Start();
    }





    // Stop listener after replicator is stopped
    _listener.Stop();

    // end::p2p-tlsid-tlsidentity-with-label-per-sam[]


        // tag::p2p-tlsid-tlsidentity-with-label[]
    // Client identity
    thisIdentity =
      TLSIdentity.ImportIdentity(_store,
        clientData,
        "123",
        "CBL-Client-Cert",
        null); // <.>

    thisConfig.Authenticator =
      new ClientCertificateAuthenticator(thisIdentity); // <.>

    // end::p2p-tlsid-tlsidentity-with-label[]


// For replications

// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
public class MyClass
{
    public Database Database { get; set; }
    public Replicator Replicator { get; set; } // <.>

    public void StartReplication()
    {
        var url = new Uri("wss://localhost:4984/db"); // <.>
        var target = new URLEndpoint(url);
        var config = new ReplicatorConfiguration(Database, target)
        {
            ReplicatorType = ReplicatorType.Pull
        };

        Replicator = new Replicator(config);
        Replicator.Start();
    }
}


    public class supporting_datatypes
    {
        public void datatype_dictionary()
        {
            var database = new Database(name: "mydb");

            // tag::datatype_dictionary[]
            // NOTE: No error handling, for brevity (see getting started)
            var document = database.GetDocument("doc1");

            // Getting a dictionary from the document's properties
            var dict = document.GetDictionary("address");

            // Access a value with a key from the dictionary
            var street = dict.GetString("street");

            // Iterate dictionary
            foreach (var key in dict.Keys)
            {
                Console.WriteLine($"Key {key} = {dict.GetValue(key)}");
            }

            // Create a mutable copy
            var mutDict = dict.ToMutable();
            // end::datatype_dictionary[]
        }

        public void datatype_mutable_dictionary()
        {

            var database = new Database("mydb");

            // tag::datatype_mutable_dictionary[]
            // NOTE: No error handling, for brevity (see getting started)

            // Create a new mutable dictionary and populate some keys/values
            var mutable_dict = new MutableDictionaryObject();
            mutable_dict.SetString("street", "1 Main st.");
            mutable_dict.SetString("city", "San Francisco");

            // Add the dictionary to a document's properties and save the document
            var doc = new MutableDocument("doc1");
            doc.SetDictionary("address", mutable_dict);
            database.Save(doc);

            // end::datatype_mutable_dictionary[]
        }


        public void datatype_array()
        {
            var database = new Database("mydb");

            // tag::datatype_array[]
            // NOTE: No error handling, for brevity (see getting started)

            var document = database.GetDocument("doc1");

            // Getting a phones array from the document's properties
            var array = document.GetArray("phones");

            // Get element count
            var count = array.Count();

            // Access an array element by index
            if (count >= 0) { var phone = array[1]; }

            // Iterate dictionary
            for (int i = 0; i < count; i++)
            {
                Console.WriteLine($"Item {i.ToString()} = {array[i]}");
            }

            // Create a mutable copy
            var mutable_array = array.ToMutable();
            // end::datatype_array[]


        }

         public void datatype_mutable_array()
        {
            var database = new Database("mydb");

            // tag::datatype_mutable_array[]
            // NOTE: No error handling, for brevity (see getting started)

            // Create a new mutable array and populate data into the array
            var mutable_array = new MutableArrayObject();
            mutable_array.AddString("650-000-0000");
            mutable_array.AddString("650-000-0001");

            // Set the array to document's properties and save the document
            var doc = new MutableDocument("doc1");
            doc.SetArray("phones", mutable_array);
            database.Save(doc);
            // end::datatype_mutable_array[]
        }

    } // end  class supporting_datatypes

  }



// end::sgw-repl-pull[]

// tag::sgw-repl-pull-callouts[]
<.> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<.> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
You should now use `ws:`, or `wss:` for SSL/TLS connections.
// end::sgw-repl-pull-callouts[]


    // tag::sgw-act-rep-initialize[]
    // initialize the replicator configuration

    var thisUrl = new URLEndpoint("wss://l10.0.2.2:4984/anotherDB"); // <.>
    var config = new ReplicatorConfiguration(thisDB, thisUrl);

    // end::sgw-act-rep-initialize[]
