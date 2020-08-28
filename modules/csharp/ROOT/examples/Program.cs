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
            // Get the database (and create it if it doesn't exist)
            var database = new Database("mydb");
            // Create a new document (i.e. a record) in the database
            string id = null;
            using (var mutableDoc = new MutableDocument()) {
                mutableDoc.SetFloat("version", 2.0f)
                    .SetString("type", "SDK");

                // Save it to the database
                database.Save(mutableDoc);
                id = mutableDoc.Id;
            }

            // Update a document
            using (var doc = database.GetDocument(id))
            using (var mutableDoc = doc.ToMutable()) {
                mutableDoc.SetString("language", "C#");
                database.Save(mutableDoc);

                using (var docAgain = database.GetDocument(id)) {
                    Console.WriteLine($"Document ID :: {docAgain.Id}");
                    Console.WriteLine($"Learning {docAgain.GetString("language")}");
                }
            }

            // Create a query to fetch documents of type SDK
            // i.e. SELECT * FROM database WHERE type = "SDK"
            using (var query = QueryBuilder.Select(SelectResult.All())
                .From(DataSource.Database(database))
                .Where(Expression.Property("type").EqualTo(Expression.String("SDK")))) {
                // Run the query
                var result = query.Execute();
                Console.WriteLine($"Number of rows :: {result.Count()}");
            }

            // Create replicator to push and pull changes to and from the cloud
            var targetEndpoint = new URLEndpoint(new Uri("ws://localhost:4984/getting-started-db"));
            var replConfig = new ReplicatorConfiguration(database, targetEndpoint);

            // Add authentication
            replConfig.Authenticator = new BasicAuthenticator("john", "pass");

            // Create replicator (make sure to add an instance or static variable
            // named _Replicator)
            _Replicator = new Replicator(replConfig);
            _Replicator.AddChangeListener((sender, args) =>
            {
                if (args.Status.Error != null) {
                    Console.WriteLine($"Error :: {args.Status.Error}");
                }
            });

            _Replicator.Start();

            // Later, stop and dispose the replicator *before* closing/disposing the database
            // end::getting-started[]
        }

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
            X509Store _store = new X509Store(StoreName.My); //The identity will be stored in the secure storage using the given label.
            DateTimeOffset fiveMinToExpireCert = DateTimeOffset.UtcNow.AddMinutes(5);

            // tag::create-self-signed-cert[]
            identity = TLSIdentity.CreateIdentity(true, /* isServer */
                new Dictionary<string, string>() { { Certificate.CommonNameAttribute, "Couchbase Inc" } }, // When creating a certificate, the common name attribute is required for creating a CSR. If the common name is not presented in the certificate, an exception will be thrown.
                fiveMinToExpireCert, // If the expiration date is not specified, the expiration date of the certificate will be 365 days
                _store,
                "CBL-Server-Cert",
                null); // The key label to get cert in certificate map. If null, the same default directory for a Couchbase Lite database is used for map.
            // end::create-self-signed-cert[]
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
                replicator.ResetCheckpoint();
                replicator.Start();
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
                var image = File.ReadAllBytes("avatar.jpg");
                var blob = new Blob("image/jpeg", image);
                newTask.SetBlob("avatar", blob);
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
                ValueIndexItem.Expression(Expression.Property("name")));
            db.CreateIndex("TypeNameIndex", index);
            // end::query-index[]
        }

        private static void SelectMeta()
        {
            Console.WriteLine("Select Meta");
            var db = _Database;

            // tag::query-select-meta[]
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
                .From(DataSource.Database(db));

            // Adds a query change listener.
            // Changes will be posted on the main queue.
            var token = query.AddChangeListener((sender, args) =>
            {
                var allResult = args.Results.AllResults();
                foreach (var result in allResult) {
                    Console.WriteLine(result.Keys);
                    /* Update UI */
                }
            });
			
            // Start live query.
            query.Execute(); // <1>
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
            Database.SetLogLevel(LogDomain.Replicator, LogLevel.Verbose);
            Database.SetLogLevel(LogDomain.Network, LogLevel.Verbose);
            // end::replication-logging[]
        }
        
        private static void FileLogging()
        {
            // tag::file-logging[]
            var tempFolder = Path.Combine(Service.GetInstance<IDefaultDirectoryResolver>().DefaultDirectory(), "cbllog");
            Database.Log.File.Config = new LogFileConfiguration(tempFolder);
            Database.Log.File.Level = LogLevel.Info;
            // end::file-logging[]
        }

        private static void EnableCustomLogging()
        {
            // tag::set-custom-logging[]
            Database.Log.Custom = new LogTestLogger();
            // end::set-custom-logging[]
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
