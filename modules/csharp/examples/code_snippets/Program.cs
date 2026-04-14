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

using System.Collections.Immutable;
using System.Diagnostics;
using Couchbase.Lite;
using Couchbase.Lite.DI;
using Couchbase.Lite.Enterprise.Query;
using Couchbase.Lite.Logging;
using Couchbase.Lite.P2P;
using Couchbase.Lite.Query;
using Couchbase.Lite.Sync;
using System.Net.NetworkInformation;
using System.Security;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;

// ReSharper disable UnusedMember.Global
// ReSharper disable UnusedVariable
// ReSharper disable InconsistentNaming
// ReSharper disable UnusedMember.Local

namespace api_walkthrough
{
    internal class Hotel
    {
        public string? Id { get; set; }

        public string? Name { get; set; }
    }

    internal class Program
    {
        private static readonly Database? Database = null;
        private static readonly Replicator? Replicator = null;

        public static void GettingStarted()
        {
            // tag::getting-started[]

            // using System;
            // using Couchbase.Lite;
            // using Couchbase.Lite.Query;
            // using Couchbase.Lite.Sync;

            // Get the database (and create it if it doesn't exist)
            var database = new Database("mydb");
            var collection = Database!.GetDefaultCollection();

            // Create a new document (i.e. a record) in the database
            using var createdDoc = new MutableDocument();
            createdDoc.SetFloat("version", 2.0f)
                .SetString("type", "SDK");

            // Save it to the database
            collection.Save(createdDoc);
            var id = createdDoc.Id;

            // Update a document
            using var doc = collection.GetDocument(id);
            using var mutableDoc = doc?.ToMutable();
            Debug.Assert(mutableDoc != null);
            mutableDoc.SetString("language", "C#");
            collection.Save(mutableDoc);

            using var docAgain = collection.GetDocument(id);
            Debug.Assert(docAgain != null);
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
            var replCollections = CollectionConfiguration.FromCollections(database.GetDefaultCollection());
            var replConfig = new ReplicatorConfiguration(replCollections, targetEndpoint)
            {
                // Add authentication
                Authenticator = new BasicAuthenticator("john", "pass")
            };

            // Create replicator (make sure to add an instance or static variable
            // named _Replicator)
            var replicator = new Replicator(replConfig);
            replicator.AddChangeListener((_, args) =>
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
            var collection = Database!.GetDefaultCollection();

            // tag::replication-conflict-resolver[]
            var target = new URLEndpoint(new Uri("ws://localhost:4984/mydatabase"));
            var collectionConfig = new CollectionConfiguration(collection)
            {
                ConflictResolver = new LocalWinConflictResolver()
            };

            var replConfig = new ReplicatorConfiguration([collectionConfig], target);

            var replicator = new Replicator(replConfig);
            replicator.Start();
            // end::replication-conflict-resolver[]
        }

        private static void TestSaveWithConflictHandler()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::update-document-with-conflict-handler[]
            using var doc = collection.GetDocument("xyz");
            using var mutableDoc = doc?.ToMutable();
            Debug.Assert(mutableDoc != null);
            mutableDoc.SetString("name", "apples");
            collection.Save(mutableDoc, (updated, current) =>
            {
                var currentDict = current?.ToDictionary() ?? new();
                var newDict = updated.ToDictionary();
                var result = newDict.Concat(currentDict)
                    .GroupBy(kv => kv.Key)
                    .ToDictionary(g => g.Key, g => g.First().Value);
                updated.SetData(result);
                return true;
            });
            // end::update-document-with-conflict-handler[]
        }

        // ReSharper disable UnusedParameter.Local
        private static bool IsValidCredential(string name, SecureString password) { return true; } // helper
        // ReSharper restore UnusedParameter.Local

        private static void TestCreateSelfSignedCert()
        {
            var store = new X509Store(StoreName.My);

            // The identity will be stored in the secure
            // storage using the given label.
            var fiveMinToExpireCert = DateTimeOffset.UtcNow.AddMinutes(5);

            // tag::create-self-signed-cert[]
            // tag::listener-config-tls-id-SelfSigned[]
            var identity = TLSIdentity.CreateIdentity(KeyUsages.ServerAuth, /* isServer */
                new() { { Certificate.CommonNameAttribute, "Couchbase Inc" } },
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
            var store = new X509Store(StoreName.My); // The identity will be stored in the secure storage using the given label
            var data = File.ReadAllBytes("C:\\client.p12"); // PKCS12 data containing private key, public key, and certificates

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

        public static void IdentityWithLabel()
        {
            var store = new X509Store(StoreName.My);
            byte[] clientData = [1, 2, 3, 4, 5];
            var database = Database!;

            // tag::p2p-tlsid-tlsidentity-with-label[]
            // Client identity
            var identity =
              TLSIdentity.ImportIdentity(store,
                clientData,
                "123",
                "CBL-Client-Cert",
                null); // <.>
            Debug.Assert(identity != null);
            var collectionConfig = CollectionConfiguration.FromCollections(Database!.GetDefaultCollection());
            var replConfig = new ReplicatorConfiguration(collectionConfig, new URLEndpoint(new("ws://localhost:4984/db")))
            {
                Authenticator = new ClientCertificateAuthenticator(identity) // <.>
            };

            // end::p2p-tlsid-tlsidentity-with-label[]
        }

        public static void UseEncryption()
        {
            // Enterprise edition only

            // tag::database-encryption[]
            // Create a new, or open an existing database with encryption enabled
            var config = new DatabaseConfiguration
            {
                // Or, derive a key yourself and pass a byte array of the proper size
                EncryptionKey = new("password")
            };

            using var database = new Database("seekrit", config);

            // Change the encryption key (or add encryption if the DB is unencrypted)
            database.ChangeEncryptionKey(new("betterpassw0rd"));

            // Remove encryption
            database.ChangeEncryptionKey(null);
            // end::database-encryption[]
        }

        private static void ResetReplicatorCheckpoint()
        {
            var url = new Uri("ws://localhost:4984/db");
            var target = new URLEndpoint(url);
            var collectionConfig = CollectionConfiguration.FromCollections(Database!.GetDefaultCollection());
            var config = new ReplicatorConfiguration(collectionConfig, target);
            // ReSharper disable once ConvertToConstant.Local
            var resetCheckpointRequired_Example = true;
            var replicator = new Replicator(config);
            // ReSharper disable once ConvertIfStatementToConditionalTernaryExpression
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
            Debug.Assert(attachments != null);
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
            var database = Database!;

            // tag::close-database[]
            Database!.Close();
            // end::close-database[]
        }

        private static void DatabaseFullsync()
        {
           // tag::database-fullsync[]
           // this enables fullsync
           var config = new DatabaseConfiguration
           {
               FullSync = true,
           };
           // end::database-fullsync[]
        }

        private static void CreateCollection()
        {
            var database = Database!;
            // tag::scopes-manage-create-collection[]
            var collectionWithDefaultScope = Database!.CreateCollection("colA");
            var collection = database.CreateCollection("colA", "scopeA"); // Scope with named scopeA will be created if it's not existed. There is no public API to create a Scope.
            // end::scopes-manage-create-collection[]
        }

        private static void DeleteCollection()
        {
            var database = Database!;
            // tag::scopes-manage-drop-collection[]
            database.DeleteCollection("colA", "scopeA"); // Scope with named scopeA will be deleted if there is no collections in the scope after the last collection is deleted via this API. There is no public API to remove a Scope.
            // end::scopes-manage-drop-collection[]
        }

        private static void ListCollectionsAndScopes()
        {
            var database = Database!;
            // tag::scopes-manage-list[]
            // Get Scopes
            var scopes = Database!.GetScopes();
            // Get Collections of a Scope named scopeA
            var scopeA = database.GetScope("scopeA");
            Debug.Assert(scopeA != null);
            var collectionsInScopeA = scopeA.GetCollections();
            // end::scopes-manage-list[]
        }

        private static void ChangeLogging()
        {
            // tag::logging[]
            // This sets the overall level of console logging
            LogSinks.Console = new(LogLevel.Verbose)
            {
                // This flag can enable and disable specific domains
                Domains = LogDomain.Couchbase | LogDomain.Database
            };
            // end::logging[]
        }

        private static void LoadPrebuilt()
        {
            // tag::prebuilt-database[]
            // Note: Getting the path to a database is platform-specific.  For .NET Core / .NET Framework this
            // can be a simple filesystem path.  For UWP, you will need to get the path from your assets.  For
            // iOS, you need to get the path from the main bundle.  For Android, you need to extract it from your
            // assets to a temporary directory and then pass that path.
            var path = Path.Combine(Environment.CurrentDirectory, "travel-sample.cblite2" + Path.DirectorySeparatorChar);
            if (!Database.Exists("travel-sample", null)) {
                Database.Copy(path, "travel-sample", null);
            }
            // end::prebuilt-database[]
        }

        private static void QueryDeletedDocuments()
        {
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();
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
            var collection = Database!.GetDefaultCollection();

            // tag::update-document[]
            using var doc = collection.GetDocument("xyz");
            Debug.Assert(doc != null);
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
            var database = Database!;
            var collection = Database!.GetDefaultCollection();
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
            var collection = Database!.GetDefaultCollection();

            // tag::document-listener[]
            collection.AddDocumentChangeListener("user.john", (_, args) =>
            {
                using var doc = collection.GetDocument(args.DocumentID);
                Console.WriteLine($"Status :: {doc?.GetString("verified_account")}");
            });
            // end::document-listener[]
        }

        private static void DocumentExpiration()
        {
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();
            using var newTask = new MutableDocument();
            // tag::blob[]
            // Note: Reading the data is implementation dependent, as with prebuilt databases
            var image = File.ReadAllBytes("avatar.jpg"); // <.>
            var blob = new Blob("image/jpeg", image); // <.>
            newTask.SetBlob("avatar", blob); // <.>
            collection.Save(newTask);
            // end::blob[]
        }

        public static void CreateIndex()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::query-index[]
            // tag::scopes-manage-index-collection[]
            string[] indexProperties = ["type", "name"];
            var config = new ValueIndexConfiguration(indexProperties);
            collection.CreateIndex("TypeNameIndex", config);
            // end::scopes-manage-index-collection[]
            // end::query-index[]
        }

        public void CreateIndex_Querybuilder()
        {
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();

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
        }

        private static void SelectAll()
        {
            var collection = Database!.GetDefaultCollection();

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
                var token = query.AddChangeListener((_, args) => // <.>
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
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();

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
                var jsonString = JsonSerializer.Serialize(publicLikes);
                Console.WriteLine($"Public Likes :: {jsonString}");
            }
            // end::query-collection-operator-contains[]
        }

        private static void UseCollectionIn()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::query-collection-operator-in[]
            var values = new IExpression[]
                { Expression.Property("first"), Expression.Property("last"), Expression.Property("username") };

            using var query = QueryBuilder.Select(
                SelectResult.All())
                .From(DataSource.Collection(collection))
                .Where(Expression.String("Armani").In(values));

            foreach (var result in query.Execute()) {
                var body = result.GetDictionary(0);
                var jsonString = JsonSerializer.Serialize(body);
                Console.WriteLine($"In results :: {jsonString}");
            }

            // end::query-collection-operator-in[]
        }

        private static void SelectLike()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::query-like-operator[]
            using var query = QueryBuilder.Select(
                SelectResult.Expression(Meta.ID),
                SelectResult.Property("name"),
                SelectResult.Property("country"))
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
            var collection = Database!.GetDefaultCollection();

            // tag::query-like-operator-wildcard-match[]
            using var query = QueryBuilder.Select(
                SelectResult.Expression(Meta.ID),
                SelectResult.Property("name"),
                SelectResult.Property("country"))
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
            var collection = Database!.GetDefaultCollection();

            // tag::query-like-operator-wildcard-character-match[]
            using var query = QueryBuilder.Select(
                SelectResult.Expression(Meta.ID),
                SelectResult.Property("name"),
                SelectResult.Property("country"))
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
            var collection = Database!.GetDefaultCollection();

            // tag::query-regex-operator[]
            using var query = QueryBuilder.Select(
                SelectResult.Expression(Meta.ID),
                SelectResult.Property("name"),
                SelectResult.Property("country"))
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
            var collection = Database!.GetDefaultCollection();
            var collection2 = Database.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();

            // tag::query-orderby[]
            using var query = QueryBuilder.Select(
                SelectResult.Expression(Meta.ID),
                SelectResult.Property("title"),
                SelectResult.Property("country"))
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
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();

            // tag::fts-index[]
            string[] indexProperties = ["overview", "name"];
            var config = new FullTextIndexConfiguration(indexProperties);
            collection.CreateIndex("overviewFTSIndex", config);
            // end::fts-index[]
        }

        public void FullTextSearch()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::fts-query[]
            var query = collection.CreateQuery("SELECT * FROM _ WHERE MATCH(overviewFTSIndex, 'Michigan') ORDER BY RANK(overviewFTSIndex)");
            foreach (var result in query.Execute()) {
                Console.WriteLine($"Document id {result.GetString(0)}");
            }
            // end::fts-query[]
        }


        private static void CreateFullTextIndex_Querybuilder()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::fts-index_Querybuilder[]
            var index = IndexBuilder.FullTextIndex(FullTextIndexItem.Property("overview")).IgnoreAccents(false);
            collection.CreateIndex("overviewFTSIndex", index);
            // end::fts-index_Querybuilder[]
        }

        private static void FullTextSearch_Querybuilder()
        {
            var collection = Database!.GetDefaultCollection();

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

        private static void ConsoleLogging()
        {
            // tag::console-logging[]
            LogSinks.Console = new(LogLevel.Verbose) // <.>
            {
                // This is the default, so explicitly stating it is not needed
                Domains = LogDomain.All // <.>
            };
            // end::console-logging[]

            // tag::console-logging-db[]
            LogSinks.Console = new(LogLevel.Verbose)
            {
                Domains = LogDomain.Database
            };
            // end::console-logging-db[]
        }

        private static void FileLogging()
        {
            // tag::file-logging[]
            var tempFolder = Path.Combine(Service.Provider.GetRequiredService<IDefaultDirectoryResolver>().DefaultDirectory(), "cbllog");
            LogSinks.File = new(LogLevel.Info, tempFolder)
            {
                MaxKeptFiles = 6, // <.>
                MaxSize = 10240, // <.>
                UsePlaintext = false // <.>
            };
            // end::file-logging[]
        }

        private static void EnableCustomLogging()
        {
            // tag::set-custom-logging[]
            LogSinks.Custom = new LogTestSink(); // <.>

            // You can also specify the level of logging the logger receives
            LogSinks.Custom = new LogTestSink(LogLevel.Warning);
            // end::set-custom-logging[]
        }

        private static void EnableBasicAuth()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::basic-authentication[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var collectionConfig = CollectionConfiguration.FromCollections(collection);
            var config = new ReplicatorConfiguration(collectionConfig, target)
            {
                Authenticator = new BasicAuthenticator("john", "pass")
            };

            var replicator = new Replicator(config);
            replicator.Start();
            // end::basic-authentication[]
        }

        private static void EnableSessionAuth()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::session-authentication[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var collectionConfig = CollectionConfiguration.FromCollections(collection);
            var config = new ReplicatorConfiguration(collectionConfig, target)
            {
                Authenticator = new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447")
            };

            var replicator = new Replicator(config);
            replicator.Start();
            // end::session-authentication[]
        }

        private static void ReplicatorPendingDocuments()
        {
            // tag::replication-pendingdocuments[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var database = new Database("myDB");
            var collectionConfig = CollectionConfiguration.FromCollections(Database!.GetDefaultCollection());
            var config = new ReplicatorConfiguration(collectionConfig, target)
            {
                ReplicatorType = ReplicatorType.Push
            };

            var replicator = new Replicator(config);

            var pendingDocIDs =
              new HashSet<string>(replicator.GetPendingDocumentIDs(database.GetDefaultCollection())); // <.>

            if (pendingDocIDs.Count > 0) {
                Console.WriteLine($"There are {pendingDocIDs.Count} documents pending");
                replicator.AddChangeListener((_, change) =>
                {
                    Console.WriteLine($"Replicator activity level is " +
                                      change.Status.Activity.ToString());
                    // iterate and report-on previously
                    // retrieved pending docids 'list'
                    foreach (var docID in pendingDocIDs)
                        if (!replicator.IsDocumentPending(docID, database.GetDefaultCollection())) // <.>
                        {
                            Console.WriteLine($"Doc ID {docID} now pushed");
                        }
                });

                replicator.Start();
            }
            // end::replication-pendingdocuments[]
        }

        private static void ReplicatorDocumentEvent()
        {
            var replicator = Replicator!;

            // ReSharper disable once RedundantIfElseBlock
            // tag::add-document-replication-listener[]
            var token = replicator.AddDocumentReplicationListener((_, args) =>
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

            var replicator = Replicator!;

            // tag::replication-error-handling[]
            replicator.AddChangeListener((_, args) =>
            {
                if (args.Status.Error != null) {
                    Console.WriteLine($"Error :: {args.Status.Error}");
                }
            });
            // end::replication-error-handling[]
        }

        private static void DatabaseReplica()
        {
            var collection = Database!.GetDefaultCollection();
            using var database2 = new Database("backup");

            // EE feature: This code will not compile on the community edition
            // tag::database-replica[]
            var targetDatabase = new DatabaseEndpoint(database2);
            var collectionConfig =  CollectionConfiguration.FromCollections(collection);
            var config = new ReplicatorConfiguration(collectionConfig, targetDatabase)
            {
                ReplicatorType = ReplicatorType.Push
            };

            var replicator = new Replicator(config);
            replicator.Start();
            // end::database-replica[]
        }

        // ReSharper disable once UnusedParameter.Local
        private static X509Certificate2? GetCertificate(string name) => null;

        public static void PinCertificate()
        {
            var url = new Uri("wss://localhost:4984/db");
            var target = new URLEndpoint(url);
            var collection = Database!.GetDefaultCollection();

            // tag::certificate-pinning[]
            // Note: `GetCertificate` is a placeholder method. This would be the platform-specific method
            // to find and load the certificate as an instance of `X509Certificate2`.
            // For .NET / .NET Framework this can be loaded from the filesystem path.
            // For iOS, from the main bundle.
            // For Android, from the assets directory.
            var certificate = GetCertificate("cert.cer");
            var collectionConfig = CollectionConfiguration.FromCollections(collection);
            var config = new ReplicatorConfiguration(collectionConfig, target)
            {
                PinnedServerCertificate = certificate
            };
            // end::certificate-pinning[]
        }

        public static void ReplicationCustomHeaders()
        {
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);
            var collection = Database!.GetDefaultCollection();

            // tag::replication-custom-header[]
            var collectionConfig = CollectionConfiguration.FromCollections(collection);
            var headers = ImmutableDictionary.CreateBuilder<string, string?>();
            headers["CustomerHeaderName"] = "Value";
            var config = new ReplicatorConfiguration(collectionConfig, target)
            {
                Headers = headers.ToImmutable()
            };
            // end::replication-custom-header[]
        }

        private static void PushWithFilter()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::replication-push-filter[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var collectionConfig = new CollectionConfiguration(collection)
            {
                PushFilter = (_, flags) => flags.HasFlag(DocumentFlags.Deleted) // <1>
            };
            var config = new ReplicatorConfiguration([collectionConfig], target);

            // Dispose() later
            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication-push-filter[]
        }

        private static void PullWithFilter()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::replication-pull-filter[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var collectionConfig = new CollectionConfiguration(collection)
            {
                PullFilter = (document, _) => document.GetString("type") == "draft" // <1>
            };
            var config = new ReplicatorConfiguration([collectionConfig], target);

            // Dispose() later
            var replicator = new Replicator(config);
            replicator.Start();
            // end::replication-pull-filter[]
        }

        public void TestCustomRetryConfig()
        {
            var collection = Database!.GetDefaultCollection();
            // tag::replication-retry-config[]
            var url = new Uri("ws://localhost:4984/mydatabase");
            var target = new URLEndpoint(url);

            var collectionConfig = CollectionConfiguration.FromCollections(collection);
            var config = new ReplicatorConfiguration(collectionConfig, target)
            {
                Heartbeat = TimeSpan.FromSeconds(120), // <.>
                MaxAttempts = 20, // <.>
                MaxAttemptsWaitTime = TimeSpan.FromSeconds(600) // <.>
                //  other config as required . . .
            };

            var replicator = new Replicator(config);
            // end::replication-retry-config[]
        }


        private static void UsePredictiveModel()
        {
            using var database = new Database("mydb");
            var collection = Database!.GetDefaultCollection();
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

        private static void UsePredictiveIndex()
        {
            using var database = new Database("mydb");
            var collection = Database!.GetDefaultCollection();
            // tag::predictive-query-predictive-index[]
            var input = Expression.Dictionary(new Dictionary<string, object>
            {
                ["photo"] = Expression.Property("photo")
            });

            var index = IndexBuilder.PredictiveIndex("ImageClassifier", input);
            collection.CreateIndex("predictive-index-image-classifier", index);
            // end::predictive-query-predictive-index[]
        }

        private static void DoPredictiveQuery()
        {
            using var database = new Database("mydb");
            var collection = Database!.GetDefaultCollection();
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

        public List<Result> docsonly_N1QLQueryString(Database argDB)
        {
            DatabaseConfiguration config = new DatabaseConfiguration();

            Database database = new Database("dbName", config);

            // tag::query-syntax-n1ql[]
            using var query =
                Database!.CreateQuery("SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.>

            return query.Execute().AllResults();
            // end::query-syntax-n1ql[]
        }

        public void docsonly_N1QLQueryStringParams(Database argDB)
        {
            var database = Database;

            // tag::query-syntax-n1ql-params[]
            using var query =
                Database!.CreateQuery("SELECT META().id AS thisId FROM _ WHERE type = $type"); // <.>

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
                  .From(DataSource.Collection(Database!.GetDefaultCollection()));
            // end::query-syntax-all[]

            // ReSharper disable CollectionNeverQueried.Local
            // tag::query-access-all[]
            var results = query.Execute().AllResults();
            var hotels = new List<Dictionary<string, object?>>();

            if (results.Count > 0) {
                foreach (var result in results) {
                    // get the result into our dictionary object
                    var thisDocsProps = result.GetDictionary("hotels"); // <.>

                    if (thisDocsProps != null) {
                        var docID = thisDocsProps.GetString("id"); // <.>
                        var docName = thisDocsProps.GetString("name");
                        var docCity = thisDocsProps.GetString("city");
                        var docType = thisDocsProps.GetString("type");
                        var hotel = thisDocsProps.ToDictionary();
                        Debug.Assert(hotel != null);
                        hotels.Add(hotel);
                    }

                }
            }
            // end::query-access-all[]
            // ReSharper restore CollectionNeverQueried.Local

            // tag::query-access-json[]
            foreach (var result in query.Execute()) {

                // get the result into a JSON String
                var docJSONString = result.ToJSON();

                // Get a native dictionary object using the JSON string
                var dictFromJSONString =
                      JsonSerializer.
                        Deserialize<Dictionary<string, object>>
                          (docJSONString);

                // use the created dictionary
                if (dictFromJSONString != null) {
                    var docID = dictFromJSONString["id"].ToString();
                    var docName = dictFromJSONString["name"].ToString();
                    var docCity = dictFromJSONString["city"].ToString();
                    var docType = dictFromJSONString["type"].ToString();
                }

                //Get a custom object using the JSON string
                var hotel = JsonSerializer.Deserialize<Hotel>(docJSONString);

            }
            // end::query-access-json[]
        }

        public static void testQuerySyntaxProps()
        {
            // ReSharper disable CollectionNeverQueried.Local
            // tag::query-syntax-props[]
            var database = new Database("hotels");

            var hotels = new List<Dictionary<string, object?>>();

            var query = QueryBuilder.Select(
                    SelectResult.Property("type"),
                    SelectResult.Property("name"),
                    SelectResult.Property("city")).From(DataSource.Collection(Database!.GetDefaultCollection()));
            // end::query-syntax-props[]
            // ReSharper restore CollectionNeverQueried.Local

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
                .From(DataSource.Collection(Database!.GetDefaultCollection()));
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
                    .From(DataSource.Collection(Database!.GetDefaultCollection()));
            // end::query-syntax-id[]

            // tag::query-access-id[]
            var results = query.Execute().AllResults();
            foreach (var result in results) {

                var docID = result.GetString("this_ID"); // <.>
                Debug.Assert(docID != null);
                var doc = database.GetDefaultCollection().GetDocument(docID);
            }
            // end::query-access-id[]
        }

        public static void testQueryPagination()
        {
            // tag::query-syntax-pagination[]
            var database = new Database("hotels");
            var limit = 20;
            var offset = 0;

            // get a count of the number of docs matching the query
            var countQuery =
                QueryBuilder
                    .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount"))
                    .From(DataSource.Collection(Database!.GetDefaultCollection()));
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

                offset += limit;
            }

            // end::query-syntax-pagination[]
        }

        public void JsonApiDocument()
        {
            var collection = Database!.GetDefaultCollection();
            // ReSharper disable CollectionNeverQueried.Local
            // tag::tojson-document[]
            // Get a document
            var doc = collection.GetDocument("hotel_10025");
            Debug.Assert(doc != null);

            // Get document data as JSON String
            var docJSONString = doc.ToJSON();

            // Get Native Object (hotel) from JSON String
            var hotels = new List<Hotel>();

            var hotel = JsonSerializer.Deserialize<Hotel>(docJSONString);
            Debug.Assert(hotel != null);
            hotels.Add(hotel);

            // Update the retrieved native object
            hotel.Name = "A Copy of " + hotel.Name;
            hotel.Id = "2001";

            // Convert the updated object back to a JSON string
            var newJsonString = JsonSerializer.Serialize(hotel);

            // Update new document with JSOn String
            using var newHotel = doc.ToMutable();
            newHotel.SetJSON(newJsonString);

            foreach (var key in newHotel.ToDictionary().Keys) {
                Console.WriteLine("Data -- {0} = {1}",
                    key, newHotel.GetValue(key));
            }

            collection.Save(newHotel);
            var retrievedDoc = collection.GetDocument("2001")?.ToJSON();
            Console.Write(retrievedDoc);
            // end::tojson-document[]
            // ReSharper restore CollectionNeverQueried.Local

        }

        public static void JsonApiArray()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::tojson-array[]
            // JSON String -- an Array (3 elements. including embedded arrays)
            var jsonString = "[{'id':'1000','type':'hotel','name':'Hotel Ted','city':'Paris','country':'France','description':'Undefined description for Hotel Ted'},{'id':'1001','type':'hotel','name':'Hotel Fred','city':'London','country':'England','description':'Undefined description for Hotel Fred'},                        {'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}]".Replace("'", "\"");

            // Create mutable array using JSON String Array
            var mutableArray = new MutableArrayObject();
            mutableArray.SetJSON(jsonString);

            // Create a new document for each array element
            for (var i = 0; i < mutableArray.Count; i++) {
                var dict = mutableArray.GetDictionary(i);
                Debug.Assert(dict != null);
                var docID = dict.GetString("id");
                var mutableDoc = new MutableDocument(docID, dict.ToDictionary());
                collection.Save(mutableDoc);
            }

            // Get one of the created docs and iterate through one of the embedded arrays
            var extendedDoc = collection.GetDocument("1002");
            Debug.Assert(extendedDoc != null);
            var features = extendedDoc.GetArray("features");
            Debug.Assert(features != null);

            // Print its elements
            foreach (var feature in features) {
                Console.Write($"{feature} ");

                //process array item as required
            }
            var featuresJSON = features.ToJSON();
            // end::tojson-array[]
        }

        public static void DeleteTLSIdentity()
        {

            // tag::p2p-tlsid-delete-id-from-keychain[]
            var store = new X509Store(StoreName.My);
            TLSIdentity.DeleteIdentity(store, "CBL-Server-Cert", null); // <.>
            // end::p2p-tlsid-delete-id-from-keychain[]
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
            foreach (var key in mutableDict.Keys) {
                Console.WriteLine("Data -- {0} = {1}", key, mutableDict.GetValue(key));

            }
            // end::tojson-dictionary[]
        }

        public void JsonApiBlob()
        {
            var userName = "ian";
            var collection = Database!.GetDefaultCollection();
            var database = Database;

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
                Path.Combine(Service.Provider.GetRequiredService<IDefaultDirectoryResolver>()
                            .DefaultDirectory(),
                                userName);
            var imagePath = Path.Combine(defaultDirectory, "avatarimage.jpg");
            var imageUri = new Uri(imagePath);
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
            database.SaveBlob(new("image/jpg", imageUri));

            // Retrieve saved doc, get blob as JSON and check it's still a 'blob'
            var sameDoc = collection.GetDocument(docId);
            Debug.Assert(sameDoc != null);
            var gotBlob = sameDoc.GetBlob("avatar");
            Debug.Assert(gotBlob != null);
            var reconstitutedBlob = new MutableDictionaryObject().
                SetDictionary("blobCOPY", new MutableDictionaryObject(gotBlob.ToJSON()));

            var gotDictionary = reconstitutedBlob.GetDictionary("blobCOPY")?.ToDictionary();
            Debug.Assert(gotDictionary != null);
            if (Blob.IsBlob(gotDictionary)) {
                //... process accordingly
                Console.WriteLine("Its a Blob!!");
            }
            // end::tojson-blob[]
        }

        public void CreateArrayIndex()
        {
            var database = new Database("my-database");
            var collection = Database!.GetDefaultCollection();

            {
                // tag::array-index-single[]
                // tag::array-index-config[]
                var arrayIndexConfiguration = new ArrayIndexConfiguration("likes");
                // end::array-index-config[]
                collection.CreateIndex("myindex", arrayIndexConfiguration);
                // end::array-index-single[]
            }

            {
                // tag::array-index-nested[]
                var arrayIndexConfiguration = new ArrayIndexConfiguration("contacts[].phones", "type");
                collection.CreateIndex("myindex", arrayIndexConfiguration);
                // end::array-index-nested[]
            }
        }

        // ReSharper disable once UnusedParameter.Local
        private static bool ValidatePassword(SecureString password) => true;

        public void P2PListenerSimple()
        {
            var collection = Database!.GetDefaultCollection();

            // ReSharper disable ConvertToLambdaExpression
            // tag::listener-simple[]
            var endpointConfig = new URLEndpointListenerConfiguration([collection]) // <.>
            {
                Authenticator = new ListenerPasswordAuthenticator((_, user, password) =>
                {
                    // ValidatePassword can make use of the SecureString class
                    // to the desired level of security (or just convert it to string
                    // if no intense security is required)
                    return user == "valid.user" && ValidatePassword(password);
                }) // <.>
            };

            var listener = new URLEndpointListener(endpointConfig); // <.>
            listener.Start(); // <.>
            // end::listener-simple[]
            // ReSharper restore ConvertToLambdaExpression
        }

        public void P2PReplicatorSimple()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::replicator-simple[]
            var endpointConfig = new URLEndpoint(new("wss://listener.com:4984/otherDB")); // <.>

            var collectionConfig = CollectionConfiguration.FromCollections(collection);
            var replConfig = new ReplicatorConfiguration(collectionConfig, endpointConfig) // <.>
            {
                AcceptOnlySelfSignedServerCertificate = true, // <.>
                Authenticator = new BasicAuthenticator("valid.user", "valid.password.string") // <.>
            };

            var replicator = new Replicator(replConfig); // <.>
            replicator.Start(); // <.>
            // end::replicator-simple[]
        }

        public void P2PActivePeer()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::p2p-act-rep-func[]
            // tag::p2p-act-rep-config-type[]
            var url = new URLEndpoint(new Uri("wss://listener.com:4984/otherDB"));
            var collectionConfig = new CollectionConfiguration(collection)
            {
                // tag::p2p-act-rep-config-cont[]
                // Configure Sync Mode
                ConflictResolver = new LocalWinConflictResolver() // <.>
                // end::p2p-act-rep-config-cont[]
            };

            var replConfig = new ReplicatorConfiguration([collectionConfig], url)
            {
                // tag::p2p-act-rep-config-self-cert[]
                // Configure Server Security -- only accept self-signed certs
                AcceptOnlySelfSignedServerCertificate = true, // <.>
                // end::p2p-act-rep-config-self-cert[]

                // Configure Client Security
                // tag::p2p-act-rep-auth[]
                // Configure basic auth using user credentials
                Authenticator = new BasicAuthenticator("valid.user", "valid.password.string") // <.>
                // end::p2p-act-rep-auth[]
            };
            // end::p2p-act-rep-config-type[]

            // tag::p2p-act-rep-start-full[]
            // Initialize and start a replicator
            // Initialize replicator with configuration data
            var replicator = new Replicator(replConfig); // <.>

            // tag::p2p-act-rep-add-change-listener[]
            // tag::p2p-act-rep-add-change-listener-label[]
            // Optionally add a change listener // <.>
            var token = replicator.AddChangeListener((_, args) =>
            {
                if (args.Status.Error != null) {
                    Console.WriteLine($"Error :: {args.Status.Error}");
                }
            });
            // end::p2p-act-rep-add-change-listener-label[]
            // end::p2p-act-rep-add-change-listener[]

            // tag::p2p-act-rep-start[]
            // Start replicator
            replicator.Start(); // <.>
            // end::p2p-act-rep-start[]
            // end::p2p-act-rep-start-full[]
            // end::p2p-act-rep-func[]
        }

        private static void ListenerInitialize()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::listener-initialize[]
            var endpointConfig = new URLEndpointListenerConfiguration([collection]) // <.>
            {
                Port = 55900, //<.>
                NetworkInterface = "10.1.1.10", //<.>
                EnableDeltaSync = true, //<.>
                DisableTLS = false, //<.>
                // Use an Anonymous Self-Signed Cert
                TlsIdentity = null, // <.>
                // Implement your own ValidatePassword function
                Authenticator = new ListenerPasswordAuthenticator((_, user, password) => user == "valid.username" && ValidatePassword(password)) // <.>
            };

            // tag::listener-start[]
            // Initialize the listener
            var listener = new URLEndpointListener(endpointConfig); // <.>

            // Start the listener
            listener.Start(); // <.>
            // end::listener-start[]

            // tag::listener-status-check[]
            var connectionCount = listener.Status.ConnectionCount; // <.>
            var activeConnectionCount = listener.Status.ActiveConnectionCount;  // <.>
            // end::listener-status-check[]
            // tag::listener-stop[]
            listener.Stop();
            // end::listener-stop[]
            // tag::listener-get-network-interfaces[]
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces()) {
                if (ni.NetworkInterfaceType is NetworkInterfaceType.Wireless80211 or NetworkInterfaceType.Ethernet) {
                    // do something with the interface(s)
                }
            }
            // end::listener-get-network-interfaces[]
            // end::listener-initialize[]
        }

        public void GettingStarted1()
        {
            var collection = Database!.GetDefaultCollection();
            {
                // tag::listener-config-db[]
                // Initialize the listener config
                var endpointConfig = new URLEndpointListenerConfiguration([collection]); // <.>
                // end::listener-config-db[]
            }
            {
                // tag::listener-config-port[]
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    Port = 55900 // <.>
                };
                // end::listener-config-port[]
            }
            {
                // tag::listener-config-netw-iface[]
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    NetworkInterface = "10.1.1.10" // <.>
                };
                // end::listener-config-netw-iface[]
            }
            {
                // tag::listener-config-delta-sync[]
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    EnableDeltaSync = true // <.>
                };
                // end::listener-config-delta-sync[]
            }
            {
                // tag::listener-config-tls-enable[]
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                   DisableTLS = false // <.>
                };
                // end::listener-config-tls-enable[]
            }
            {
                // tag::listener-config-tls-id-anon[]
                // Use an Anonymous Self-Signed Cert
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    TlsIdentity = null // <.>
                };
                // end::listener-config-tls-id-anon[]
            }
            {
                // tag::listener-config-client-auth-pwd[]
                // Configure the client authenticator
                // (Here we are using Basic Authentication)
                var validUser = "valid.username";
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    // Implement your own ValidatePassword function
                    Authenticator = new ListenerPasswordAuthenticator((_, user, password) =>
                        user == validUser && ValidatePassword(password)) // <.>
                };
                // end::listener-config-client-auth-pwd[]
            }
        }

        public void GettingStarted2()
        {
            var collection = Database!.GetDefaultCollection();

            {
                // tag::listener-config-client-auth-root[]
                // Configure the client authenticator
                // to validate using ROOT CA

                // Get the valid cert chain, in this instance from
                // PKCS12 data containing private key, public key
                // and certificates <.>
                var clientData = File.ReadAllBytes("client.p12");
                var ourCaData = File.ReadAllBytes("client-ca.der");

                // Get the root certs from the data
                var rootCert = new X509Certificate2(ourCaData); // <.>

                // Configure the authenticator to use the root certs
                var certAuth = new ListenerCertificateAuthenticator(new X509Certificate2Collection(rootCert));
                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    Authenticator = certAuth // <.>
                };

                // Initialize the listener using the config
                var listener = new URLEndpointListener(endpointConfig);
                // end::listener-config-client-auth-root[]
            }
            {
                // ReSharper disable ConvertToLambdaExpression
                // tag::listener-config-client-auth-lambda[]
                // Configure the client authenticator
                // to validate using application logic

                // Get the valid cert chain, in this instance from
                // PKCS12 data containing private key, public key
                // and certificates <.>
                var clientData = File.ReadAllBytes("client.p12");
                var ourCaData = File.ReadAllBytes("client-ca.der");

                // Configure the authenticator to pass the root certs
                // To a user supplied code block for authentication
                var callbackAuth =
                  new ListenerCertificateAuthenticator((_, _) =>
                    {
                        // . . . user supplied code block
                        // . . . returns boolean value (true=authenticated)
                        return true;
                    }); // <.>

                var endpointConfig = new URLEndpointListenerConfiguration([collection])
                {
                    Authenticator = callbackAuth // <.>
                };
                // end::listener-config-client-auth-lambda[]
                // ReSharper restore ConvertToLambdaExpression
            }
        }


        public void ConfigureTLSListenerIdentity()
        {
            var collection = Database!.GetDefaultCollection();
            var store = new X509Store(StoreName.My);

            // tag::listener-config-tls-id-full[]
            // tag::listener-config-tls-id-caCert[]
            var serverData = File.ReadAllBytes("server.p12"); // <.>
            var serverIdentity = TLSIdentity.ImportIdentity(store,
                serverData,
                "password", // <.>
                "CBL-Server-Cert",
                null); // <.>
            var endpointConfigCa = new URLEndpointListenerConfiguration([collection])
            {
                TlsIdentity = serverIdentity // <.>
            };
            // end::listener-config-tls-id-caCert[]
            // tag::listener-config-tls-id-SelfSigned[]
            var certAttrs = new Dictionary<string, string>
            {
                { Certificate.CommonNameAttribute, "Couchbase Inc" } // <.>
            };
            var selfSignedIdentity = TLSIdentity.CreateIdentity(
                KeyUsages.ServerAuth,
                certAttrs,
                null,
                store,
                "CBL-Server-Cert", // <.>
                null);
            var endpointConfigSs = new URLEndpointListenerConfiguration([collection])
            {
                TlsIdentity = selfSignedIdentity // <.>
            };
            // end::listener-config-tls-id-SelfSigned[]
            // end::listener-config-tls-id-full[]
        }

        public void datatype_usage()
        {
            // tag::datatype_usage_createdb[]
            // Get the database (and create it if it doesn't exist).
            using var database = new Database("hoteldb");
            var collection = Database!.GetDefaultCollection();
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
        }

        public void datatype_dictionary()
        {
            var collection = Database!.GetDefaultCollection();

            // tag::datatype_dictionary[]
            var doc = collection.GetDocument("doc1");
            Debug.Assert(doc != null);

            // Getting a dictionary from the document's properties
            var dict = doc.GetDictionary("address");
            Debug.Assert(dict != null);

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
            var collection = Database!.GetDefaultCollection();

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
            var collection = Database!.GetDefaultCollection();

            // tag::datatype_array[]
            var document = collection.GetDocument("doc1");
            Debug.Assert(document != null);

            // Getting a phones array from the document's properties
            var array = document.GetArray("phones");
            Debug.Assert(array != null);

            // Get element count
            var count = array.Count;

            // Access an array element by index
            if (count >= 0) { var phone = array[1]; }

            // Iterate dictionary
            for (var i = 0; i < count; i++) {
                Console.WriteLine($"Item {i.ToString()} = {array[i]}");
            }

            // Create a mutable copy
            var mutableArray = array.ToMutable();
            // end::datatype_array[]
        }

        public void datatype_mutable_array()
        {
            var collection = Database!.GetDefaultCollection();

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

        // ReSharper disable once UnusedParameter.Local
        private static void Main(string[] args)
        {
            // NOTE: PLEASE PLEASE PLEASE do not break the compilation of this file.  It is
            // by far the easiest way to check for its correctness.  If you don't know how to
            // compile a C# program, then find someone who does before you commit your changes!!!
            Console.WriteLine("This program is not meant to be executed, only compiled");
        }
    }

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
            var collectionConfig = CollectionConfiguration.FromCollections(database.GetDefaultCollection());
            var replConfig = new ReplicatorConfiguration(collectionConfig, messageEndpointTarget);

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
        private IReplicatorConnection? _replicatorConnection;

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
        public async Task Close(Exception? error)
        {
            // await socket.Close, etc. (or do nothing if already closed)
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
        private MessageEndpointListener? _messageEndpointListener;
        private IReplicatorConnection? _replicatorConnection;

        public void StartListener()
        {
            // tag::listener[]
            var database = new Database("mydb");
            var endpointConfig = new MessageEndpointListenerConfiguration([database.GetDefaultCollection()], ProtocolType.MessageStream);
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
        public async Task Close(Exception? error)
        {
            // await socket.Close, etc. (or do nothing if already closed)
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
    internal class TensorFlowModel
    {
        public static IDictionary<string, object?>? PredictImage(byte[] data)
        {
            // Do calculations, etc
            return null;
        }
    }

    internal class ImageClassifierModel : IPredictiveModel
    {
        public DictionaryObject? Predict(DictionaryObject input)
        {
            var blob = input.GetBlob("photo");
            if (blob == null) {
                return null;
            }

            var imageData = blob.Content;
            Debug.Assert(imageData != null);
            // tensorFlowModel is a fake implementation
            // this would be the implementation of the ml model you have chosen
            var modelOutput = TensorFlowModel.PredictImage(imageData);
            Debug.Assert(modelOutput != null);
            return new MutableDictionaryObject(modelOutput); // <1>
        }
    }
    // end::predictive-model[]

    // tag::custom-logging[]
    internal class LogTestSink(LogLevel level = LogLevel.Info) : BaseLogSink(level)
    {
        protected override void WriteLog(LogLevel level, LogDomain domain, string message)
        {
            // handle the message, for example piping it to
            // a third party framework
        }
    }
    // end::custom-logging[]

    // tag::local-win-conflict-resolver[]
    internal class LocalWinConflictResolver : IConflictResolver
    {
        public Document? Resolve(Conflict conflict)
        {
            return conflict.LocalDocument;
        }
    }
    // end::local-win-conflict-resolver[]

    // tag::remote-win-conflict-resolver[]
    internal class RemoteWinConflictResolver : IConflictResolver
    {
        public Document? Resolve(Conflict conflict)
        {
            return conflict.RemoteDocument;
        }
    }
    // end::remote-win-conflict-resolver[]

    // tag::merge-conflict-resolver[]
    internal class MergeConflictResolver : IConflictResolver
    {
        public Document? Resolve(Conflict conflict)
        {
            var localDict = conflict.LocalDocument?.ToDictionary();
            var remoteDict = conflict.RemoteDocument?.ToDictionary();
            var result = localDict;
            if (localDict == null) {
                result = remoteDict;
            } else if (remoteDict != null) {
                result = localDict.Concat(remoteDict)
                    .GroupBy(kv => kv.Key)
                    .ToDictionary(g => g.Key, g => g.First().Value);
            }

            return result != null ? new MutableDocument(conflict.DocumentID, result) : null;
        }
    }
    // end::merge-conflict-resolver[]
 }

// tag::autopurge-override[]
// Note: EnableAutoPurge is a ReplicatorConfiguration property applicable to
// Sync Gateway replication only. It is not supported for peer-to-peer replication.
// end::autopurge-override[]

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

public class MyClass
{
    public Database? Database { get; set; }

    public void StartReplication()
    {
        var collection = Database!.GetDefaultCollection();
        // tag::sgw-repl-pull[]
        var url = new Uri("wss://localhost:4984/db"); // <.>
        var target = new URLEndpoint(url);
        var collectionConfig = CollectionConfiguration.FromCollections(collection);
        var config = new ReplicatorConfiguration(collectionConfig, target)
        {
            ReplicatorType = ReplicatorType.Pull
        };

        var replicator = new Replicator(config);
        replicator.Start();
        // end::sgw-repl-pull[]
    }

    public void InitReplication()
    {
        var collection = Database!.GetDefaultCollection();
        // tag::sgw-act-rep-initialize[]
        // initialize the replicator configuration

        var url = new URLEndpoint(new("wss://10.0.2.2:4984/anotherDB")); // <.>
        var collectionConfig = CollectionConfiguration.FromCollections(collection);
        var replConfig = new ReplicatorConfiguration(collectionConfig, url);

        // end::sgw-act-rep-initialize[]
    }

    // tag::custom-log-sink
    internal class MyCoolLogSink(LogLevel level) : BaseLogSink(level)
    {
        protected override void WriteLog(LogLevel level, LogDomain domain, string message)
        {
            // Do something cool with this information
        }
    }
    // end::custom-log-sink

    public void OldLoggingApi()
    {
        // tag::console-logging[]
        // Removed in 4.0
        // end::console-logging[]

        // tag::file-logging[]

        // Removed in 4.0
        // end::file-logging[]

        // tag::custom-logging[]
        // Removed in 4.0
        // end::custom-logging[]
    }

    public void NewLoggingApi()
    {
        // tag::new-console-logging[]
        LogSinks.Console = new(LogLevel.Verbose);
        // end::new-console-logging[]

        // tag::new-file-logging[]
        LogSinks.File = new(LogLevel.Verbose, "path/to/log/directory")
        {
            MaxKeptFiles = 3, // Save 3 log files (i.e. 2 rotated and 1 current)
            MaxSize = 1024 * 512, // 512KB per file, then rotated
        };
        // end::new-file-logging[]

        // tag::new-custom-logging[]
        LogSinks.Custom = new MyCoolLogSink(LogLevel.Verbose);
        // end::new-custom-logging[]
    }


    public void PartialValueIndex()
    {
        var collection = Database!.GetDefaultCollection();

        // tag::partial-value-index[]
        var config = new ValueIndexConfiguration("city")
        {
            Where = "type = \"hotel\""
        };

        collection.CreateIndex("HotelCityIndex", config);
        // end::partial-value-index[]
    }

    public void PartialFTSIndex()
    {
        var collection = Database!.GetDefaultCollection();

        // tag::partial-full-text-index[]
        var config = new FullTextIndexConfiguration("description")
        {
            Where = "type = \"hotel\""
        };

        collection.CreateIndex("HotelDescIndex", config);
        // end::partial-full-text-index[]
    }
}