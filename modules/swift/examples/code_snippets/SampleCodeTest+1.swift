//
//  SampleCodeTest2.swift
//  code-snippets
//
//  Created by Jayahari Vavachan on 11/9/21.
//  Copyright © 2021 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import CoreML

extension SampleCodeTest {
    // MARK: Database
    
    func dontTestNewDatabase() throws {
        let userDb: Database = self.database;
        
        // tag::new-database[]
        do {
            self.database = try Database(name: "my-database")
        } catch {
            print(error)
        }
        // end::new-database[]
        
        // tag::close-database[]
        do {
            try userDb.close()
        }
        
        // end::close-database[]
        
        
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
        // verbose / replicator
        Database.log.console.level = .verbose
        Database.log.console.domains = .replicator
        
        // verbose / query
        Database.log.console.level = .verbose
        Database.log.console.domains = .query
        // end::logging[]
    }
    
    func dontTestConsoleLogging() throws {
        // tag::console-logging[]
        Database.log.console.domains = .all // <.>
        Database.log.console.level = .verbose // <.>
        
        // end::console-logging[]
        // tag::console-logging-db[]
        
        Database.log.console.domains = .database
        
        // end::console-logging-db[]
    }
    
    func dontTestFileLogging() throws {
        // tag::file-logging[]
        let tempFolder = NSTemporaryDirectory().appending("cbllog")
        let config = LogFileConfiguration(directory: tempFolder) // <.>
        config.usePlainText = true // <.>
        config.maxSize = 1024 // <.>
        Database.log.file.config = config // <.>
        Database.log.file.level = .info // <.>
        // end::file-logging[]
    }
    
    func dontTestEnableCustomLogging() throws {
        // tag::set-custom-logging[]
        let logger = LogTestLogger(.warning)
        Database.log.custom =  logger // <.>
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
        // tag::initializer[]
        let newTask = MutableDocument()
            .setString("task", forKey: "type")
            .setString("todo", forKey: "owner")
            .setDate(Date(), forKey: "createdAt")
        try database.saveDocument(newTask)
        // end::initializer[]
    }
    
    func dontTestMutability() throws {
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
        print(newTask.toDictionary())  // <.>
        
        // end::to-dictionary[]
        
        // tag::to-json[]
        print(newTask.toJSON()) // <.>
        
        // end::to-json[]
        
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
        // tag::document-listener[]
        database.addDocumentChangeListener(withID: "user.john") { (change) in
            if let document = self.database.document(withID: change.documentID) {
                print("Status :: \(document.string(forKey: "verified_account")!)")
            }
        }
        // end::document-listener[]
    }
    
    func dontTestDocumentExpiration() throws {
        // tag::document-expiration[]
        // Purge the document one day from now
        let ttl = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        try database.setDocumentExpiration(withID: "doc123", expiration: ttl)
        
        // Reset expiration
        try database.setDocumentExpiration(withID: "doc1", expiration: nil)
        
        // Query documents that will be expired in less than five minutes
        let fiveMinutesFromNow = Date(timeIntervalSinceNow: 60 * 5).timeIntervalSince1970
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(
                Meta.expiration.lessThan(
                    Expression.double(fiveMinutesFromNow)
                )
            )
        // end::document-expiration[]
        print(query)
    }
    
    func dontTestBlob() throws {
#if TARGET_OS_IPHONE
        let newTask = MutableDocument()
        var image: UIImage!
        
        // tag::blob[]
        let appleImage = UIImage(named: "avatar.jpg")!
        let imageData = UIImageJPEGRepresentation(appleImage, 1)! // <.>
        
        let blob = Blob(contentType: "image/jpeg", data: imageData) // <.>
        newTask.setBlob(blob, forKey: "avatar") // <.>
        try database.saveDocument(newTask)
        
        if let taskBlob = newTask.blob(forKey: "image") {
            image = UIImage(data: taskBlob.content!)
        }
        // end::blob[]
        
        print("\(image)")
#endif
    }
    
    func dontTest1xAttachment() throws {
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
        // tag::query-index[]
        let index = IndexBuilder.valueIndex(items:
                                                ValueIndexItem.expression(Expression.property("type")),
                                            ValueIndexItem.expression(Expression.property("name")))
        try database.createIndex(index, withName: "TypeNameIndex")
        // end::query-index[]
    }
    
    func dontTestSelectMeta() throws {
        // tag::query-select-meta[]
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
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
    
    
    func dontTestSelectProps() throws {
        // tag::query-select-props[]
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
        // end::query-select-props[]
    }
    
    func dontTestSelectAll() throws {
        var query: Query
        
        // tag::query-select-all[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
        // end::query-select-all[]
        
        // tag::live-query[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database)) // <.>
        
        // Adds a query change listener.
        // Changes will be posted on the main queue.
        let token = query.addChangeListener { (change) in // <.>
            for result in change.results! {
                print(result.keys)
                /* Update UI */
            }
        } // <.>
        
        // end::live-query[]
        
        // tag::stop-live-query[]
        query.removeChangeListener(withToken: token) // <.>
        
        // end::stop-live-query[]
        
        print("\(query)")
    }
    
    func dontTestWhere() throws {
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
            .from(DataSource.database(database))
            .where(Meta.isDeleted)
        // end::query-deleted-documents[]
        print(query)
    }
    
    func dontTestCollectionOperatorContains() throws {
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
        // tag::query-collection-operator-in[]
        let values = [
            Expression.property("first"),
            Expression.property("last"),
            Expression.property("username")
        ]
        
        let query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.string("Armani").in(values))
        // end::query-collection-operator-in[]
        
        print(query)
    }
    
    
    func dontTestLikeOperator() throws {
        // tag::query-like-operator[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name")).like(Expression.string("royal engineers museum")))
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
        // tag::query-like-operator-wildcard-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name")).like(Expression.string("eng%e%")))
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
        // tag::query-regex-operator[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Expression.property("name").regex(Expression.string("\\bEng.*e\\b"))) // <.>
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
    
    func dontTestExplainAll() throws {
        // tag::query-explain-all[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("university")))
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").ascending())  // <.>
        
        print(try query.explain()) // <.>
        // end::query-explain-all[]
    }
    
    func dontTestExplainLike() throws {
        // tag::query-explain-like[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").like(Expression.string("%hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));
        
        print(try query.explain())
        
        // end::query-explain-like[]
    }
    
    func dontTestExplainNoOp() throws {
        // tag::query-explain-nopfx[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));
        
        print(try query.explain());
        
        // end::query-explain-nopfx[]
    }
    
    func dontTestExplainFunction() throws {
        // tag::query-explain-function[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))) // <.>
        
        print(try query.explain());
        
        // end::query-explain-function[]
    }
    
    func dontTestExplainNoFunction() throws {
        // tag::query-explain-nofunction[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("hotel"))); // <.>
        
        print(try query.explain());
        
        // end::query-explain-nofunction[]
    }
    
    
    func dontTestCreateFullTextIndex() throws {
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
        // tag::fts-query[]
        
        let whereClause = FullTextFunction.match(indexName: "nameFTSIndex", query: "'buy'")
        let query = QueryBuilder.select(SelectResult.expression(Meta.id))
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
    
    
    func dontTestToJsonArrayObject() throws {
        // demonstrate use of JSON string
        // tag::tojson-array[]
        
        
        
        
        // end::tojson-array[]
    }
    
    
    
    func dontTestGetBlobAsJSONstring() throws {
        // tag::tojson-getblobasstring[]
        
        let doc = database.document(withID: "doc-id")!.toDictionary();
        let blob =  doc["avatar"] as! Blob
        
        if Blob.isBlob(properties: blob.properties) {
            let blobType = blob.properties["content_type"]
            let blobLength = blob.properties["length"]
            
            print("\(blobType): \(blobLength)")
        }
        // end::tojson-getblobasstring[]
    }
    
    
    func dontTestToJsonDictionary() throws {
        // demonstrate use of JSON string
        // tag::tojson-dictionary[]
        
        
        // end::tojson-dictionary[]
    }
    
    
    func dontTestToJsonDocument() throws {
        // demonstrate use of JSON string
        // tag::tojson-document[]
        
        
        // end::tojson-document[]
    }
    
    
    func dontTestToJsonResult() throws {
        // demonstrate use of JSON string
        // tag::tojson-result[]
        let ourJSON =  "{{\"id\": \"hotel-ted\"},{\"name\": \"Hotel Ted\"},{\"city\": \"Paris\"},{\"type\": \"hotel\"}}"
        let ourDoc = try MutableDocument(id: "doc", json: ourJSON)
        try database.saveDocument(ourDoc)
        
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("id").equalTo(Expression.string("hotel-ted")))
        
        for result in try! query.execute() {
            let d1 = result.toJSON().data(using: .utf8)
            if let thisJSON = try JSONSerialization.jsonObject(with: d1!, options:[]) as? [String:Any] {
                // ... process document properties as required e.g.
                let docid = thisJSON["id"]
                let name = thisJSON["name"]
                let city = thisJSON["city"]
                let type = thisJSON["type"]
                //
            }
            
            // end::tojson-result[]
        }
    }
    
    // MARK: Replication
    
    /* The `tag::replication[]` example is inlined in swift.adoc */
    
    func dontTestEnableReplicatorLogging() throws {
        // tag::replication-logging[]
        // Verbose / Replicator
        Database.log.console.level = .verbose
        Database.log.console.domains = .replicator
        
        // Verbose / Network
        Database.log.console.level = .verbose
        Database.log.console.domains = .network
        // end::replication-logging[]
    }
    
    func dontTestReplicationBasicAuthentication() throws {
        // tag::basic-authentication[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(database: database, target: target)
        config.authenticator = BasicAuthenticator(username: "john", password: "pass")
        
        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::basic-authentication[]
    }
    
    func dontTestReplicationSessionAuthentication() throws {
        // tag::session-authentication[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(database: database, target: target)
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
    
    //  BEGIN PendingDocuments IB -- 11/Feb/21 --
    func dontTestReplicationPendingDocs() throws {
        // tag::replication-pendingdocuments[]
        
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        var config = ReplicatorConfiguration(database: database, target: target)
        config.replicatorType = .push
        
        // tag::replication-push-pendingdocumentids[]
        self.replicator = Replicator(config: config)
        let mydocids:Set = try self.replicator.pendingDocumentIds() // <.>
        
        // end::replication-push-pendingdocumentids[]
        if(!mydocids.isEmpty) {
            print("There are \(mydocids.count) documents pending")
            let thisid = mydocids.first!
            
            self.replicator.addChangeListener { (change) in
                print("Replicator activity level is \(change.status.activity)")
                // iterate and report-on previously
                // retrieved pending docids 'list'
                for thisId in mydocids.sorted() {
                    // tag::replication-push-isdocumentpending[]
                    do {
                        let isPending = try self.replicator.isDocumentPending(thisid)
                        if(!isPending) { // <.>
                            print("Doc ID \(thisId) now pushed")
                        }
                    } catch {
                        print(error)
                    }
                    // end::replication-push-isdocumentpending[]
                }
            }
            
            self.replicator.start()
            // end::replication-pendingdocuments[]
        }
    }
    
    //  END test PendingDocuments IB -- 11/Feb/21 --
    
    
    func dontTestReplicatorDocumentEvent() throws {
        // tag::add-document-replication-listener[]
        let token = self.replicator.addDocumentReplicationListener { (replication) in
            print("Replication type :: \(replication.isPush ? "Push" : "Pull")")
            for document in replication.documents {
                if (document.error == nil) {
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
        var config = ReplicatorConfiguration(database: database, target: target)
        config.headers = ["CustomHeaderName": "Value"]
        // end::replication-custom-header[]
    }
    
    func dontTestReplicationChannels() throws {
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        // tag::replication-channels[]
        var config = ReplicatorConfiguration(database: database, target: target)
        config.channels = ["channel_name"]
        // end::replication-channels[]
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
        let doResetCheckpointRequired = Bool.random()
        
        // tag::replication-reset-checkpoint[]
        
        if doResetCheckpointRequired {
            self.replicator.start(reset: true)  // <.>
        } else {
            self.replicator.start()
        }
        
        // end::replication-reset-checkpoint[]
    }
    
    func dontTestReplicationPushFilter() throws {
        // tag::replication-push-filter[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        var config = ReplicatorConfiguration(database: database, target: target)
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
        
        var config = ReplicatorConfiguration(database: database, target: target)
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
    
    //  Added 2/Feb/21 - Ian Bridge
    //  Changed for 3.0.0 - Ian Bridge 3/Mar/21
    func testCustomRetryConfig() {
        // tag::replication-retry-config[]
        let target = URLEndpoint(url: URL(string: "ws://foo.couchbase.com/db")!)
        
        var config =  ReplicatorConfiguration(database: database, target: target)
        config.replicatorType = .pushAndPull
        config.continuous = true
        // tag::replication-set-heartbeat[]
        config.heartbeat = 150 // <.>
        
        // end::replication-set-heartbeat[]
        // tag::replication-set-maxattempts[]
        config.maxAttempts = 20 // <.>
        
        // end::replication-set-maxattempts[]
        // tag::replication-set-maxattemptwaittime[]
        config.maxAttemptWaitTime = 600 // <.>
        self.replicator = Replicator(config: config)
        // end::replication-set-maxattemptwaittime[]
        
        // end::replication-retry-config[]
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
        
        var config = ReplicatorConfiguration(database: database, target: target)
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
        var replConfig = ReplicatorConfiguration(database: database, target: targetEndpoint)
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
        let url = URL(string: "wss://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        
        var config = ReplicatorConfiguration(database: database, target: target)
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
        try database.saveDocument(mutableDocument, conflictHandler: { (new, current) -> Bool in
            let currentDict = current!.toDictionary()
            let newDict = new.toDictionary()
            let result = newDict.merging(currentDict, uniquingKeysWith: { (first, _) in first })
            new.setData(result)
            return true
        })
        // end::update-document-with-conflict-handler[]
        
    }
    
    // helper
    func isValidCredentials(_ u: String, password: String) -> Bool { return true }
    
    func dontTestInitListener() throws {
        // tag::init-urllistener[]
        var config = URLEndpointListenerConfiguration(database: otherDB)
        config.tlsIdentity = nil; // Use with anonymous self signed cert
        config.authenticator = ListenerPasswordAuthenticator(authenticator: { (username, password) -> Bool in
            return self.isValidCredentials(username, password: password)
        })
        
        // end::init-urllistener[]
    }
    
    func dontTestListenerStart() throws {
        // tag::start-urllistener[]
        try listener.start()
        
        // end::start-urllistener[]
    }
    
    func dontTestListenerStop() throws {
        // tag::stop-urllistener[]
        listener.stop()
        
        // end::stop-urllistener[]
    }
    
    func dontTestCreateSelfSignedCert() throws {
        // <site-rooot>/objc/advance/objc-p2psync-websocket-using-passive.html
        // Example-6
        // tag::create-self-signed-cert[]
        // tag::listener-config-tls-id-SelfSigned[]
        let attrs = [certAttrCommonName: "Couchbase Inc"]
        let identity =
        try TLSIdentity.createIdentity(forServer: true,
                                       attributes: attrs,
                                       expiration: Date().addingTimeInterval(86400),
                                       label: "Server-Cert-Label")
        // end::listener-config-tls-id-SelfSigned[]
        // end::create-self-signed-cert[]
        print("\(identity.expiration)") // to avoid warning
    }
}
