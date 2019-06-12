//
//  SampleCodeTest.swift
//  CouchbaseLite
//
//  Copyright (c) 2018 Couchbase, Inc All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CouchbaseLiteSwift
import MultipeerConnectivity
import CoreML


class SampleCodeTest {
    
    var database: Database!
    var db: Database!
    
    var replicator: Replicator!
    
    // MARK: Database
    
    func dontTestNewDatabase() throws {
        // tag::new-database[]
        do {
            self.database = try Database(name: "my-database")
        } catch {
            print(error)
        }
        // end::new-database[]
    }

    #if COUCHBASE_ENTERPRISE
    func dontTestDatabaseEncryption() throws {
        // tag::database-encryption[]
        let config = DatabaseConfiguration()
        config.encryptionKey = EncryptionKey.password("secretpassword")
        self.database = try Database(name: "my-database", config: config)
        // end::database-encryption[]
    }
    #endif

    func dontTestLogging() throws {
        // tag::logging[]
        Database.setLogLevel(.verbose, domain: .replicator)
        Database.setLogLevel(.verbose, domain: .query)
        // end::logging[]
    }
    
    func dontTestFileLogging() throws {
        // tag::file-logging[]
        let tempFolder = NSTemporaryDirectory().appending("cbllog")
        Database.log.file.config = LogFileConfiguration(directory: tempFolder)
        Database.log.file.level = .info
        // end::file-logging[]
    }

    func dontTestEnableCustomLogging() throws {
        // tag::set-custom-logging[]
        Database.log.custom = LogTestLogger()
        // end::set-custom-logging[]
    }

    func dontTestLoadingPrebuilt() throws {
        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        // For iOS you need to get the path from the main bundle.
        let path = Bundle.main.path(forResource: "travel-sample", ofType: "cblite2")!
        if !Database.exists(withName: "travel-sample") {
            do {
                try Database.copy(fromPath: path, toDatabase: "travel-sample", withConfig: nil)
            } catch {
                fatalError("Could not load pre-built database")
            }
        }
        // end::prebuilt-database[]
    }

    // MARK: Document

    func dontTestInitializer() throws {
        database = self.db

        // tag::initializer[]
        let newTask = MutableDocument()
            .setString("task", forKey: "type")
            .setString("todo", forKey: "owner")
            .setDate(Date(), forKey: "createdAt")
        try database.saveDocument(newTask)
        // end::initializer[]
    }

    func dontTestMutability() throws {
        database = self.db

        // tag::update-document[]
        guard let document = database.document(withID: "xyz") else { return }
        let mutableDocument = document.toMutable()
        mutableDocument.setString("apples", forKey: "name")
        try database.saveDocument(mutableDocument)
        // end::update-document[]
    }

    func dontTestTypedAcessors() throws {
        let newTask = MutableDocument()

        // tag::date-getter[]
        newTask.setValue(Date(), forKey: "createdAt")
        let date = newTask.date(forKey: "createdAt")
        // end::date-getter[]
        
        // tag::to-dictionary[]
        newTask.toDictionary() // returns a Dictionary<String, Any>
        // end::to-dictionary[]

        print("\(date!)")
    }

    func dontTestBatchOperations() throws {
        // tag::batch[]
        do {
            try database.inBatch {
                for i in 0...10 {
                    let doc = MutableDocument()
                    doc.setValue("user", forKey: "type")
                    doc.setValue("user \(i)", forKey: "name")
                    doc.setBoolean(false, forKey: "admin")
                    try database.saveDocument(doc)
                    print("saved user document \(doc.string(forKey: "name")!)")
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
        // end::batch[]
    }
    
    func dontTestChangeListener() throws {
        database = self.db
        
        // tag::document-listener[]
        database.addDocumentChangeListener(withID: "user.john") { (change) in
            if let document = self.database.document(withID: change.documentID) {
                print("Status :: \(document.string(forKey: "verified_account")!)")
            }
        }
        // end::document-listener[]
    }
    
    func dontTestDocumentExpiration() throws {
        database = self.db
        
        // tag::document-expiration[]
        // Purge the document one day from now
        let ttl = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        try database.setDocumentExpiration(withID: "doc123", expiration: ttl)
        
        // Reset expiration
        try db.setDocumentExpiration(withID: "doc1", expiration: nil)
        
        // Query documents that will be expired in less than five minutes
        let fiveMinutesFromNow = Date(timeIntervalSinceNow: 60 * 5).timeIntervalSince1970
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(db))
            .where(
                Meta.expiration.lessThan(
                    Expression.double(fiveMinutesFromNow)
                )
            )
        // end::document-expiration[]
        
    }
    
    func dontTestBlob() throws {
    #if TARGET_OS_IPHONE
        database = self.db
        let newTask = MutableDocument()
        var image: UIImage!

        // tag::blob[]
        let appleImage = UIImage(named: "avatar.jpg")!
        let imageData = UIImageJPEGRepresentation(appleImage, 1)!

        let blob = Blob(contentType: "image/jpeg", data: imageData)
        newTask.setBlob(blob, forKey: "avatar")
        try database.saveDocument(newTask)

        if let taskBlob = newTask.blob(forKey: "image") {
            image = UIImage(data: taskBlob.content!)
        }
        // end::blob[]

        print("\(image)")
    #endif
    }

    func dontTest1xAttachment() throws {
        database = self.db
        let document = MutableDocument()

        // tag::1x-attachment[]
        let attachments = document.dictionary(forKey: "_attachments")
        let avatar = attachments?.blob(forKey: "avatar")
        let content = avatar?.content
        // end::1x-attachment[]
        
        print("\(content!)")
    }

    // MARK: Query

    func dontTestIndexing() throws {
        database = self.db

        // tag::query-index[]
        let index = IndexBuilder.valueIndex(items:
            ValueIndexItem.expression(Expression.property("type")),
            ValueIndexItem.expression(Expression.property("name")))
        try database.createIndex(index, withName: "TypeNameIndex")
        // end::query-index[]
    }

    func dontTestSelect() throws {
        database = self.db

        // tag::query-select-meta[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("type"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))

        do {
            for result in try query.execute() {
                print("document id :: \(result.string(forKey: "id")!)")
                print("document name :: \(result.string(forKey: "name")!)")
            }
        } catch {
            print(error)
        }
        // end::query-select-meta[]
    }

    func dontTestSelectAll() throws {
        database = self.db

        // tag::query-select-all[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
        // end::query-select-all[]
        
        // tag::live-query[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
        
        // Adds a query change listener.
        // Changes will be posted on the main queue.
        let token = query.addChangeListener { (change) in
            for result in change.results! {
                print(result.keys)
                /* Update UI */
            }
        }
        
        // Start live query.
        query.execute(); // <1>
        // end::live-query[]
        
        // tag::stop-live-query[]
        query.removeChangeListener(withToken: token)
        // end::stop-live-query[]

        print("\(query)")
    }

    func dontTestWhere() throws {
        database = self.db

        // tag::query-where[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .limit(Expression.int(10))

        do {
            for result in try query.execute() {
                if let dict = result.dictionary(forKey: "travel-sample") {
                    print("document name :: \(dict.string(forKey: "name")!)")
                }
            }
        } catch {
            print(error)
        }
        // end::query-where[]
    }
    
    func dontTestQueryDeletedDocuments() throws {
        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(db))
            .where(Meta.isDeleted)
        // end::query-deleted-documents[]
    }
    
    func dontTestCollectionOperatorContains() throws {
        database = self.db

        // tag::query-collection-operator-contains[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("public_likes")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))
                .and(ArrayFunction.contains(Expression.property("public_likes"), value: Expression.string("Armani Langworth")))
        )

        do {
             for result in try query.execute() {
                print("public_likes :: \(result.array(forKey: "public_likes")!.toArray())")
            }
        }
        // end::query-collection-operator-contains[]
    }
    
    func dontTestCollectionOperatorIn() throws {
        database = self.db
        
        // tag::query-collection-operator-in[]
        let values = [Expression.property("first"), Expression.property("last"), Expression.property("username")]
        
        QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.string("Armani").in(values))
        // end::query-collection-operator-in[]
    }
    

    func dontTestLikeOperator() throws {
        database = self.db

        // tag::query-like-operator[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and( Expression.property("name").like(Expression.string("Royal engineers museum")))
            )
            .limit(Expression.int(10))

        do {
            for result in try query.execute() {
                print("name property :: \(result.string(forKey: "name")!)")
            }
        }
        // end::query-like-operator[]
    }

    func dontTestWildCardMatch() throws {
        database = self.db

        // tag::query-like-operator-wildcard-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Expression.property("name").like(Expression.string("eng%e%")))
            )
            .limit(Expression.int(10))
        // end::query-like-operator-wildcard-match[]

        do {
            for result in try query.execute() {
                print("name property :: \(result.string(forKey: "name")!)")
            }
        }
    }

    func dontTestWildCardCharacterMatch() throws {
        database = self.db

        // tag::query-like-operator-wildcard-character-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Expression.property("name").like(Expression.string("eng____r")))
            )
            .limit(Expression.int(10))
        // end::query-like-operator-wildcard-character-match[]

        do {
            for result in try query.execute() {
                print("name property :: \(result.string(forKey: "name")!)")
            }
        }
    }

    func dontTestRegexMatch() throws {
        database = self.db

        // tag::query-regex-operator[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Expression.property("name").regex(Expression.string("\\bEng.*e\\b")))
            )
            .limit(Expression.int(10))
        // end::query-regex-operator[]

        do {
            for result in try query.execute() {
                print("name property :: \(result.string(forKey: "name")!)")
            }
        }
    }

    func dontTestJoin() throws {
        database = self.db

        // tag::query-join[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Expression.property("name").from("airline")),
                SelectResult.expression(Expression.property("callsign").from("airline")),
                SelectResult.expression(Expression.property("destinationairport").from("route")),
                SelectResult.expression(Expression.property("stops").from("route")),
                SelectResult.expression(Expression.property("airline").from("route"))
            )
            .from(
                DataSource.database(database!).as("airline")
            )
            .join(
                Join.join(DataSource.database(database!).as("route"))
                    .on(
                        Meta.id.from("airline")
                            .equalTo(Expression.property("airlineid").from("route"))
                )
            )
            .where(
                Expression.property("type").from("route").equalTo(Expression.string("route"))
                    .and(Expression.property("type").from("airline").equalTo(Expression.string("airline")))
                    .and(Expression.property("sourceairport").from("route").equalTo(Expression.string("RIX")))
        )
        // end::query-join[]

        do {
            for result in try query.execute() {
                print("name property :: \(result.string(forKey: "name")!)")
            }
        }
    }

    func dontTestGroupBy() throws {
        database = self.db

        // tag::query-groupby[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Function.count(Expression.all())),
                SelectResult.property("country"),
                SelectResult.property("tz"))
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("airport"))
                    .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.int(300)))
            ).groupBy(
                Expression.property("country"),
                Expression.property("tz")
        )

        do {
            for result in try query.execute() {
                print("There are \(result.int(forKey: "$1")) airports on the \(result.string(forKey: "tz")!) timezone located in \(result.string(forKey: "country")!) and above 300 ft")
            }
        }
        // end::query-groupby[]
    }

    func dontTestOrderBy() throws {
        database = self.db

        // tag::query-orderby[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("title"))
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.property("title").ascending())
            .limit(Expression.int(10))
        // end::query-orderby[]

        print("\(query)")
    }

    func dontTestCreateFullTextIndex() throws {
        database = self.db

        // tag::fts-index[]
        // Insert documents
        let tasks = ["buy groceries", "play chess", "book travels", "buy museum tickets"]
        for task in tasks {
            let doc = MutableDocument()
            doc.setString("task", forKey: "type")
            doc.setString(task, forKey: "name")
            try database.saveDocument(doc)
        }

        // Create index
        do {
            let index = IndexBuilder.fullTextIndex(items: FullTextIndexItem.property("name")).ignoreAccents(false)
            try database.createIndex(index, withName: "nameFTSIndex")
        } catch let error {
            print(error.localizedDescription)
        }
        // end::fts-index[]
    }

    func dontTestFullTextSearch() throws {
        database = self.db

        // tag::fts-query[]
        let whereClause = FullTextExpression.index("nameFTSIndex").match("'buy'")
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(whereClause)

        do {
            for result in try query.execute() {
                print("document id \(result.string(at: 0)!)")
            }
        } catch let error {
            print(error.localizedDescription)
        }
        // end::fts-query[]
    }

    // MARK: Replication

    /* The `tag::replication[]` example is inlined in swift.adoc */

    func dontTestEnableReplicatorLogging() throws {
        // tag::replication-logging[]
        // Replicator
        Database.setLogLevel(.verbose, domain: .replicator)
        // Network
        Database.setLogLevel(.verbose, domain: .network)
        // end::replication-logging[]
    }

    func dontTestReplicationBasicAuthentication() throws {
        // tag::basic-authentication[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        let config = ReplicatorConfiguration(database: database, target: target)
        config.authenticator = BasicAuthenticator(username: "john", password: "pass")

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::basic-authentication[]
    }

    func dontTestReplicationSessionAuthentication() throws {
        // tag::session-authentication[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        let config = ReplicatorConfiguration(database: database, target: target)
        config.authenticator = SessionAuthenticator(sessionID: "904ac010862f37c8dd99015a33ab5a3565fd8447")

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::session-authentication[]
    }

    func dontTestReplicatorStatus() throws {
        // tag::replication-status[]
        self.replicator.addChangeListener { (change) in
            if change.status.activity == .stopped {
                print("Replication stopped")
            }
        }
        // end::replication-status[]
    }
    
    func dontTestReplicatorDocumentEvent() throws {
        // tag::add-document-replication-listener[]
        let token = self.replicator.addDocumentReplicationListener { (replication) in
            print("Replication type :: \(replication.isPush ? "Push" : "Pull")")
            for document in replication.documents {
                if (document.error != nil) {
                    print("Doc ID :: \(document.id)")
                    if (document.flags.contains(.deleted)) {
                        print("Successfully replicated a deleted document")
                    }
                } else {
                    // There was an error
                }
            }
        }
        
        self.replicator.start()
        // end::add-document-replication-listener[]
        
        // tag::remove-document-replication-listener[]
        self.replicator.removeChangeListener(withToken: token)
        // end::remove-document-replication-listener[]
    }
    
    func dontTestReplicationCustomHeader() throws {
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        // tag::replication-custom-header[]
        let config = ReplicatorConfiguration(database: database, target: target)
        config.headers = ["CustomHeaderName": "Value"]
        // end::replication-custom-header[]
    }

    func dontTestHandlingReplicationError() throws {
        // tag::replication-error-handling[]
        self.replicator.addChangeListener { (change) in
            if let error = change.status.error as NSError? {
                print("Error code :: \(error.code)")
            }
        }
        // end::replication-error-handling[]
    }

    func dontTestReplicationResetCheckpoint() throws {
        // tag::replication-reset-checkpoint[]
        self.replicator.resetCheckpoint()
        self.replicator.start()
        // end::replication-reset-checkpoint[]
    }
    
    func dontTestReplicationPushFilter() throws {
        // tag::replication-push-filter[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        let config = ReplicatorConfiguration(database: database, target: target)
        config.pushFilter = { (document, flags) in // <1>
            if (document.string(forKey: "type") == "draft") {
                return false
            }
            return true
        }
        
        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-push-filter[]
    }

    func dontTestReplicationPullFilter() throws {
        // tag::replication-pull-filter[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        let config = ReplicatorConfiguration(database: database, target: target)
        config.pullFilter = { (document, flags) in // <1>
            if (flags.contains(.deleted)) {
                return false
            }
            return true
        }
        
        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-pull-filter[]
    }

    #if COUCHBASE_ENTERPRISE
    func dontTestDatabaseReplica() throws {
        let database2 = try self.openDB(name: "db2")
        
        /* EE feature: code below might throw a compilation error
           if it's compiled against CBL Swift Community. */
        // tag::database-replica[]
        let targetDatabase = DatabaseEndpoint(database: database2)
        let config = ReplicatorConfiguration(database: database, target: targetDatabase)
        config.replicatorType = .push

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::database-replica[]
        
        try database2.delete()
    }
    #endif

    func dontTestCertificatePinning() throws {

        // tag::certificate-pinning[]
        let certURL = Bundle.main.url(forResource: "cert", withExtension: "cer")!
        let data = try! Data(contentsOf: certURL)
        let certificate = SecCertificateCreateWithData(nil, data as CFData)

        let url = URL(string: "wss://localhost:4985/db")!
        let target = URLEndpoint(url: url)

        let config = ReplicatorConfiguration(database: database, target: target)
        config.pinnedServerCertificate = certificate
        // end::certificate-pinning[]

        print("\(config)")
    }
    
    func dontTestGettingStarted() throws {
        // tag::getting-started[]
        // Get the database (and create it if it doesn’t exist).
        let database: Database
        do {
            database = try Database(name: "mydb")
        } catch {
            fatalError("Error opening database")
        }
        
        // Create a new document (i.e. a record) in the database.
        let mutableDoc = MutableDocument()
            .setFloat(2.0, forKey: "version")
            .setString("SDK", forKey: "type")
        
        // Save it to the database.
        do {
            try database.saveDocument(mutableDoc)
        } catch {
            fatalError("Error saving document")
        }
        
        // Update a document.
        if let mutableDoc = database.document(withID: mutableDoc.id)?.toMutable() {
            mutableDoc.setString("Swift", forKey: "language")
            do {
                try database.saveDocument(mutableDoc)
                
                let document = database.document(withID: mutableDoc.id)!
                // Log the document ID (generated by the database)
                // and properties
                print("Document ID :: \(document.id)")
                print("Learning \(document.string(forKey: "language")!)")
            } catch {
                fatalError("Error updating document")
            }
        }
        
        // Create a query to fetch documents of type SDK.
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("SDK")))
        
        // Run the query.
        do {
            let result = try query.execute()
            print("Number of rows :: \(result.allResults().count)")
        } catch {
            fatalError("Error running the query")
        }
        
        // Create replicators to push and pull changes to and from the cloud.
        let targetEndpoint = URLEndpoint(url: URL(string: "ws://localhost:4984/getting-started-db")!)
        let replConfig = ReplicatorConfiguration(database: database, target: targetEndpoint)
        replConfig.replicatorType = .pushAndPull
        
        // Add authentication.
        replConfig.authenticator = BasicAuthenticator(username: "john", password: "pass")
        
        // Create replicator (make sure to add an instance or static variable named replicator)
        self.replicator = Replicator(config: replConfig)
        
        // Listen to replicator change events.
        self.replicator.addChangeListener { (change) in
            if let error = change.status.error as NSError? {
                print("Error code :: \(error.code)")
            }
        }
        
        // Start replication.
        self.replicator.start()
        // end::getting-started[]
    }
    
    func dontTestPredictiveModel() throws {
        let database: Database
        do {
            database = try Database(name: "mydb")
        } catch {
            fatalError("Error opening database")
        }

        // tag::register-model[]
        let model = ImageClassifierModel()
        Database.prediction.registerModel(model, withName: "ImageClassifier")
        // end::register-model[]
        
        // tag::predictive-query-value-index[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])
        let prediction = Function.prediction(model: "ImageClassifier", input: input)
        
        let index = IndexBuilder.valueIndex(items: ValueIndexItem.expression(prediction.property("label")))
        try database.createIndex(index, withName: "value-index-image-classifier")
        // end::predictive-query-value-index[]
        
        // tag::unregister-model[]
        Database.prediction.unregisterModel(withName: "ImageClassifier")
        // end::unregister-model[]
    }
    
    func dontTestPredictiveIndex() throws {
        let database: Database
        do {
            database = try Database(name: "mydb")
        } catch {
            fatalError("Error opening database")
        }

        // tag::predictive-query-predictive-index[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])

        let index = IndexBuilder.predictiveIndex(model: "ImageClassifier", input: input)
        try database.createIndex(index, withName: "predictive-index-image-classifier")
        // end::predictive-query-predictive-index[]
    }
    
    func dontTestPredictiveQuery() throws {
        let database: Database
        do {
            database = try Database(name: "mydb")
        } catch {
            fatalError("Error opening database")
        }
        
        // tag::predictive-query[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])
        let prediction = Function.prediction(model: "ImageClassifier", input: input) // <1>
        
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                prediction.property("label").equalTo(Expression.string("car"))
                .and(
                    prediction.property("probablity")
                        .greaterThanOrEqualTo(Expression.double(0.8))
                )
            )
        
        // Run the query.
        do {
            let result = try query.execute()
            print("Number of rows :: \(result.allResults().count)")
        } catch {
            fatalError("Error running the query")
        }
        // end::predictive-query[]
    }
    
    func dontTestCoreMLPredictiveModel() throws {
        // tag::coreml-predictive-model[]
        // Load MLModel from `ImageClassifier.mlmodel`
        let modelURL = Bundle.main.url(forResource: "ImageClassifier", withExtension: "mlmodel")!
        let compiledModelURL = try MLModel.compileModel(at: modelURL)
        let model = try MLModel(contentsOf: compiledModelURL)
        let predictiveModel = CoreMLPredictiveModel(mlModel: model)
        
        // Register model
        Database.prediction.registerModel(predictiveModel, withName: "ImageClassifier")
        // end::coreml-predictive-model[]
    }

    func dontTestReplicatorConflictResolver() throws {
        // tag::replication-conflict-resolver[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        let config = ReplicatorConfiguration(database: database, target: target)
        config.conflictResolver = LocalWinConflictResolver()
        
        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-conflict-resolver[]
    }
    
    func dontTestSaveWithConflictHandler() throws {
        // tag::update-document-with-conflict-handler[]
        guard let document = database.document(withID: "xyz") else { return }
        let mutableDocument = document.toMutable()
        mutableDocument.setString("apples", forKey: "name")
        try database.saveDocument(mutableDocument, conflictHandler: ExampleConflictHandler.handle)
        // end::update-document-with-conflict-handler[]

    }
    
}


// tag::predictive-model[]
// `myMLModel` is a fake implementation
// this would be the implementation of the ml model you have chosen
class myMLModel {
    static func predictImage(data: Data) -> [String : AnyObject] {}
}

class ImageClassifierModel: PredictiveModel {
    func predict(input: DictionaryObject) -> DictionaryObject? {
        guard let blob = input.blob(forKey: "photo") else {
            return nil
        }
        
        let imageData = blob.content!
        // `myMLModel` is a fake implementation
        // this would be the implementation of the ml model you have chosen
        let modelOutput = myMLModel.predictImage(data: imageData)
        
        let output = MutableDictionaryObject(data: modelOutput)
        return output // <1>
    }
}
// end::predictive-model[]

// tag::custom-logging[]
fileprivate class LogTestLogger: Logger {
    
    // set the log level
    var level: LogLevel = .none
    
    func log(level: LogLevel, domain: LogDomain, message: String) {
        // handle the message, for example piping it to
        // a third party framework
    }
    
}
// end::custom-logging[]

// tag::local-win-conflict-resolver[]
class LocalWinConflictResolver: ConflictResolver {
    func resolve(conflict: Conflict) -> Document? {
        return conflict.localDocument
    }
}
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
class RemoteWinConflictResolver: ConflictResolver {
    func resolve(conflict: Conflict) -> Document? {
        return conflict.remoteDocument
    }
}
// end::remote-win-conflict-resolver[]

// tag::merge-conflict-resolver[]
class MergeConflictResolver: ConflictResolver {
    func resolve(conflict: Conflict) -> Document? {
        return self.merge(conflict.localDocument, conflict.remoteDocument)
    }
}
// end::merge-conflict-resolver[]

// tag::example-conflict-handler[]
class ExampleConflictHandler {
    static func handle(document: MutableDocument, oldDocument: Document?) -> Bool {
        self.merge(document, from: oldDocument)
        return true
    }
}
// end::example-conflict-handler[]

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
class ActivePeer: MessageEndpointDelegate {
    
    init() throws {
        let id = ""

        // tag::message-endpoint[]
        let database = try Database(name: "dbname")
        
        // The delegate must implement the `MessageEndpointDelegate` protocol.
        let messageEndpointTarget = MessageEndpoint(uid: "UID:123", target: id, protocolType: .messageStream, delegate: self)
        // end::message-endpoint[]
        
        // tag::message-endpoint-replicator[]
        let config = ReplicatorConfiguration(database: database, target: messageEndpointTarget)
        
        // Create the replicator object.
        let replicator = Replicator(config: config)
        // Start the replication.
        replicator.start()
        // end::message-endpoint-replicator[]
    }
    
    // tag::create-connection[]
    /* implementation of MessageEndpointDelegate */
    func createConnection(endpoint: MessageEndpoint) -> MessageEndpointConnection {
        let connection = ActivePeerConnection() /* implements MessageEndpointConnection */
        return connection
    }
    // end::create-connection[]

}

class ActivePeerConnection: MessageEndpointConnection {
    
    var replicatorConnection: ReplicatorConnection?
    
    init() {}
    
    func disconnect() {
        // tag::active-replicator-close[]
        replicatorConnection?.close(error: nil)
        // end::active-replicator-close[]
    }

    // tag::active-peer-open[]
    /* implementation of MessageEndpointConnection */
    func open(connection: ReplicatorConnection, completion: @escaping (Bool, MessagingError?) -> Void) {
        replicatorConnection = connection
        completion(true, nil)
    }
    // end::active-peer-open[]

    // tag::active-peer-send[]
    /* implementation of MessageEndpointConnection */
    func send(message: Message, completion: @escaping (Bool, MessagingError?) -> Void) {
        var data = message.toData()
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion(true, nil)
    }
    // end::active-peer-send[]
    
    func receive(data: Data) {
        // tag::active-peer-receive[]
        let message = Message.fromData(data)
        replicatorConnection?.receive(message: message)
        // end::active-peer-receive[]
    }

    // tag::active-peer-close[]
    /* implementation of MessageEndpointConnection */
    func close(error: Error?, completion: @escaping () -> Void) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion()
    }
    // end::active-peer-close[]

}

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
class PassivePeerConnection: NSObject, MessageEndpointConnection {
    
    var messageEndpointListener: MessageEndpointListener?
    var replicatorConnection: ReplicatorConnection?
    
    override init() {
        super.init()
    }
    
    func startListener() {
        // tag::listener[]
        let database = try! Database(name: "mydb")
        let config = MessageEndpointListenerConfiguration(database: database, protocolType: .messageStream)
        messageEndpointListener = MessageEndpointListener(config: config)
        // end::listener[]
    }
    
    func stopListener() {
        // tag::passive-stop-listener[]
        messageEndpointListener?.closeAll()
        // end::passive-stop-listener[]
    }
    
    func acceptConnection() {
        // tag::advertizer-accept[]
        let connection = PassivePeerConnection() /* implements MessageEndpointConnection */
        messageEndpointListener?.accept(connection: connection)
        // end::advertizer-accept[]
    }
    
    func disconnect() {
        // tag::passive-replicator-close[]
        replicatorConnection?.close(error: nil)
        // end::passive-replicator-close[]
    }
    
    // tag::passive-peer-open[]
    /* implementation of MessageEndpointConnection */
    func open(connection: ReplicatorConnection, completion: @escaping (Bool, MessagingError?) -> Void) {
        replicatorConnection = connection
        completion(true, nil)
    }
    // end::passive-peer-open[]
    
    // tag::passive-peer-send[]
    /* implementation of MessageEndpointConnection */
    func send(message: Message, completion: @escaping (Bool, MessagingError?) -> Void) {
        var data = Data()
        data.append(message.toData())
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion(true, nil)
    }
    // end::passive-peer-send[]
    
    func receive(data: Data) {
        // tag::passive-peer-receive[]
        let message = Message.fromData(data)
        replicatorConnection?.receive(message: message)
        // end::passive-peer-receive[]
    }
    
    // tag::passive-peer-close[]
    /* implementation of MessageEndpointConnection */
    func close(error: Error?, completion: @escaping () -> Void) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion()
    }
    // end::passive-peer-close[]
}

