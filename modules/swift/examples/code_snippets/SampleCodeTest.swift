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
        Database.setLogLevel(.verbose, domain: .replicator)
        Database.setLogLevel(.verbose, domain: .query)
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
        Database.log.custom = LogTestLogger(.warning) // <.>
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

    func dontTestSelectMeta() throws {
        database = self.db

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
        database = self.db

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
        let token = query.addChangeListener { (change) in // <.>
            for result in change.results! {
                print(result.keys)
                /* Update UI */
            }
        }

        // Start live query.
        query.execute(); // <.>
        // end::live-query[]

        // tag::stop-live-query[]
        query.removeChangeListener(withToken: token) // <.>

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
        let values = [
            Expression.property("first"),
            Expression.property("last"),
            Expression.property("username")
            ]

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

    func dontTestExplain() throws {
      database = self.db
      // tag::query-explain-all[]
      let thisQuery = QueryBuilder
          .select(SelectResult.all())
          .from(DataSource.database(database))
          .where(Expression.property("type").equalTo(Expression.string("university")))
          .groupBy(Expression.property("country"))
          .orderBy(Ordering.property("name").ascending())  // <.>

      print(try thisQuery.explain()) // <.>
      // end::query-explain-all[]

      // tag::query-explain-like[]
      let thisQuery = QueryBuilder
          .select(SelectResult.all())
          .from(DataSource.database(database))
          .where(Expression.property("type").like(Expression.string("%hotel%")) // <.>
            .and(Expression.property("name").like(Expression.string("%royal%"))));

      print(try thisQuery.explain())

      // end::query-explain-like[]

      // tag::query-explain-nopfx[]
      let thisQuery = QueryBuilder
          .select(SelectResult.all())
          .from(DataSource.database(database))
          .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
            .and(Expression.property("name").like(Expression.string("%royal%"))));

      print(try thisQuery.explain());

      // end::query-explain-nopfx[]

      // tag::query-explain-function[]
      let thisQuery = QueryBuilder
          .select(SelectResult.all())
          .from(DataSource.database(database))
          .where(
            Function.lower(Expression.property("type").equalTo(Expression.string("hotel"))); // <.>

      print(try thisQuery.explain());

      // end::query-explain-function[]

      // tag::query-explain-nofunction[]
      let thisQuery = QueryBuilder
          .select(SelectResult.all())
          .from(DataSource.database(database))
          .where(
            Expression.property("type").equalTo(Expression.string("hotel"))); // <.>

      print(try thisQuery.explain());

      // end::query-explain-nofunction[]

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


//  BEGIN PendingDocuments IB -- 11/Feb/21 --
    func dontTestReplicationPendingDocs() throws {
      // tag::replication-pendingdocuments[]

      let url = URL(string: "ws://localhost:4984/mydatabase")!
      let target = URLEndpoint(url: url)

      let config = ReplicatorConfiguration(database: database, target: target)
      config.replicatorType = .push

      // tag::replication-push-pendingdocumentids[]
      self.replicator = Replicator(config: config)
      let mydocids:Set = self.replicator.pendingDocumentIds() // <.>

      // end::replication-push-pendingdocumentids[]
      if(!mydocids.isEmpty) {
        print("There are \(mydocids.count) documents pending")

        self.replicator.addChangeListener { (change) in
          print("Replicator activity level is \(change.status.activity.toString())")
          // iterate and report-on previously
          // retrieved pending docids 'list'
          for thisId in mydocids.sorted() {
            // tag::replication-push-isdocumentpending[]
            if(!self.replicator.isDocumentPending(thisid)) { // <.>
              print("Doc ID \(thisId) now pushed")
            }
            // end::replication-push-isdocumentpending[]
          }
        }

        self.replicator.start()
        // end::replication-pendingdocuments[]
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
        let config = ReplicatorConfiguration(database: database, target: target)
        config.headers = ["CustomHeaderName": "Value"]
        // end::replication-custom-header[]
    }

    func dontTestReplicationChannels() throws {
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        // tag::replication-channels[]
        let config = ReplicatorConfiguration(database: database, target: target)
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

//  Added 2/Feb/21 - Ian Bridge
    func testCustomHeartbeat() {
        // tag::replication-set-heartbeat[]
        let target =
          URLEndpoint(url: URL(string: "ws://foo.couchbase.com/db")!)

        let config =  ReplicatorConfiguration(database: database, target: targetDatabase)
        config.type = .pushAndPull
        config.continuous = true
        config.heartbeat = 60 // <.>
        repl = Replicator(config: config)

        // end::replication-set-heartbeat[]
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
        let prediction = PredictiveModel.predict(model: "ImageClassifier", input: input)

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
        let prediction = PredictiveModel.predict(model: "ImageClassifier", input: input) // <1>

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
        let db: Database!

        // tag::init-urllistener[]
        let config = URLEndpointListenerConfiguration(database: db)
        config.tlsIdentity = nil; // Use with anonymous self signed cert
        config.authenticator = ListenerPasswordAuthenticator(authenticator:
            { (username, password) -> Bool in
                return self.isValidCredentials(username, password: password)
        })

        // end::init-urllistener[]
    }

    func dontTestListenerStart() throws {
        let listener: URLEndpointListener

        // tag::start-urllistener[]
        try listener.start()

        // end::start-urllistener[]
    }

    func dontTestListenerStop() throws {
        let listener: URLEndpointListener
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
class LocalWinConflictResolver: ConflictResolverProtocol {
    func resolve(conflict: Conflict) -> Document? {
        return conflict.localDocument
    }
}
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
class RemoteWinConflictResolver: ConflictResolverProtocol {
    func resolve(conflict: Conflict) -> Document? {
        return conflict.remoteDocument
    }
}
// end::remote-win-conflict-resolver[]

// tag::merge-conflict-resolver[]
class MergeConflictResolver: ConflictResolverProtocol {
    func resolve(conflict: Conflict) -> Document? {
        let localDict = conflict.localDocument!.toDictionary()
        let remoteDict = conflict.remoteDocument!.toDictionary()
        let result = localDict.merging(remoteDict) { (current, new) -> Any in
            return current // return current value in case of duplicate keys
        }
        return MutableDocument(id: conflict.documentID, data: result)
    }
}
// end::merge-conflict-resolver[]

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


// BEGIN URLENDPOINTLISTENER SAMPLES

//
//  URLEndpontListenerTest.swift
//  CouchbaseLite
//
//  Copyright (c) 2020 Couchbase, Inc. All rights reserved.
//
//  Licensed under the Couchbase License Agreement (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  https://info.couchbase.com/rs/302-GJY-034/images/2017-10-30_License_Agreement.pdf
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import CouchbaseLiteSwift

@available(macOS 10.12, iOS 10.0, *)
class URLEndpontListenerTest: ReplicatorTest {
    let wsPort: UInt16 = 4984
    let wssPort: UInt16 = 4985
    let serverCertLabel = "CBL-Server-Cert"
    let clientCertLabel = "CBL-Client-Cert"

    var listener: URLEndpointListener?

    @discardableResult
    func listen() throws -> URLEndpointListener {
        return try listen(tls: true, auth: nil)
    }

    @discardableResult
    func listen(tls: Bool) throws -> URLEndpointListener {
        return try! listen(tls: tls, auth: nil)
    }

    @discardableResult
    func listen(tls: Bool, auth: ListenerAuthenticator?) throws -> URLEndpointListener {
        // Stop:
        if let listener = self.listener {
            listener.stop()
        }

        // Listener:
        let config = URLEndpointListenerConfiguration.init(database: self.oDB)
        config.port = tls ? wssPort : wsPort
        config.disableTLS = !tls
        config.authenticator = auth

        return try listen(config: config)
    }

    @discardableResult
    func listen(config: URLEndpointListenerConfiguration) throws -> URLEndpointListener {
        self.listener = URLEndpointListener.init(config: config)

        // Start:
        try self.listener!.start()

        return self.listener!
    }

    func stopListen() throws {
        if let listener = self.listener {
            try stopListener(listener: listener)
        }
    }

    func stopListener(listener: URLEndpointListener) throws {
        let identity = listener.tlsIdentity
        listener.stop()
        if let id = identity {
            try id.deleteFromKeyChain()
        }
    }

    func cleanUpIdentities() throws {
        self.ignoreException {
            try URLEndpointListener.deleteAnonymousIdentities()
        }
    }

    func replicator(db: Database, continuous: Bool, target: Endpoint, serverCert: SecCertificate?) -> Replicator {
        let config = ReplicatorConfiguration(database: db, target: target)
        config.replicatorType = .pushAndPull
        config.continuous = continuous
        config.pinnedServerCertificate = serverCert
        return Replicator(config: config)
    }

    /// Two replicators, replicates docs to the self.listener; validates connection status
    func validateMultipleReplicationsTo() throws {
        let exp1 = expectation(description: "replicator#1 stop")
        let exp2 = expectation(description: "replicator#2 stop")
        let count = self.listener!.config.database.count

        // open DBs
        try deleteDB(name: "db1")
        try deleteDB(name: "db2")
        let db1 = try openDB(name: "db1")
        let db2 = try openDB(name: "db2")

        // For keeping the replication long enough to validate connection status, we will use blob
        let imageData = try dataFromResource(name: "image", ofType: "jpg")

        // DB#1
        let doc1 = createDocument()
        let blob1 = Blob(contentType: "image/jpg", data: imageData)
        doc1.setBlob(blob1, forKey: "blob")
        try db1.saveDocument(doc1)

        // DB#2
        let doc2 = createDocument()
        let blob2 = Blob(contentType: "image/jpg", data: imageData)
        doc2.setBlob(blob2, forKey: "blob")
        try db2.saveDocument(doc2)

        let repl1 = replicator(db: db1,
                               continuous: false,
                               target: self.listener!.localURLEndpoint,
                               serverCert: self.listener!.tlsIdentity!.certs[0])
        let repl2 = replicator(db: db2,
                               continuous: false,
                               target: self.listener!.localURLEndpoint,
                               serverCert: self.listener!.tlsIdentity!.certs[0])

        var maxConnectionCount: UInt64 = 0, maxActiveCount: UInt64 = 0
        let changeListener = { (change: ReplicatorChange) in
            if change.status.activity == .busy {
                maxConnectionCount = max(self.listener!.status.connectionCount, maxConnectionCount);
                maxActiveCount = max(self.listener!.status.activeConnectionCount, maxActiveCount);
            }

            if change.status.activity == .stopped {
                if change.replicator.config.database.name == "db1" {
                    exp1.fulfill()
                } else {
                    exp2.fulfill()
                }
            }

        }
        let token1 = repl1.addChangeListener(changeListener)
        let token2 = repl2.addChangeListener(changeListener)

        repl1.start()
        repl2.start()
        wait(for: [exp1, exp2], timeout: 5.0)

        // check both replicators access listener at same time
        XCTAssertEqual(maxConnectionCount, 2);
        XCTAssertEqual(maxActiveCount, 2);

        // all data are transferred to/from
        XCTAssertEqual(self.listener!.config.database.count, count + 2);
        XCTAssertEqual(db1.count, count + 1/* db2 doc*/);
        XCTAssertEqual(db2.count, count + 1/* db1 doc*/);

        repl1.removeChangeListener(withToken: token1)
        repl2.removeChangeListener(withToken: token2)

        try db1.close()
        try db2.close()
    }

    override func setUp() {
        super.setUp()
        try! cleanUpIdentities()
    }

    override func tearDown() {
        try! stopListen()
        try! cleanUpIdentities()
        super.tearDown()
    }

    func testTLSIdentity() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Disabled TLS:
        var config = URLEndpointListenerConfiguration.init(database: self.oDB)
        config.disableTLS = true
        var listener = URLEndpointListener.init(config: config)
        XCTAssertNil(listener.tlsIdentity)

        try listener.start()
        XCTAssertNil(listener.tlsIdentity)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)

        // Anonymous Identity:
        config = URLEndpointListenerConfiguration.init(database: self.oDB)
        listener = URLEndpointListener.init(config: config)
        XCTAssertNil(listener.tlsIdentity)

        try listener.start()
        XCTAssertNotNil(listener.tlsIdentity)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)

        // User Identity:
// tag::p2psync-act-tlsid-create[]
        try TLSIdentity.deleteIdentity(withLabel: serverCertLabel);
        let attrs = [certAttrCommonName: "CBL-Server"]
        let identity = try TLSIdentity.createIdentity(forServer: true,
                                                      attributes: attrs,
                                                      expiration: nil,
                                                      label: serverCertLabel)
// end::p2psync-act-tlsid-create[]
        config = URLEndpointListenerConfiguration.init(database: self.oDB)
        config.tlsIdentity = identity
        listener = URLEndpointListener.init(config: config)
        XCTAssertNil(listener.tlsIdentity)

        try listener.start()
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssert(identity === listener.tlsIdentity!)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)
    }

    func testPasswordAuthenticator() throws {
        // Listener:
        let listenerAuth = ListenerPasswordAuthenticator.init {
            (username, password) -> Bool in
            return (username as NSString).isEqual(to: "daniel") &&
                   (password as NSString).isEqual(to: "123")
        }
        let listener = try listen(tls: false, auth: listenerAuth)

        // Replicator - No Authenticator:
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: nil, expectedError: CBLErrorHTTPAuthRequired)

        // Replicator - Wrong Credentials:
        var auth = BasicAuthenticator.init(username: "daniel", password: "456")
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: auth, expectedError: CBLErrorHTTPAuthRequired)

        // Replicator - Success:
        auth = BasicAuthenticator.init(username: "daniel", password: "123")
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: auth)

        // Cleanup:
        try stopListen()
    }

    func testClientCertAuthenticatorWithClosure() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Listener:
        let listenerAuth = ListenerCertificateAuthenticator.init { (certs) -> Bool in
            XCTAssertEqual(certs.count, 1)
            var commongName: CFString?
            let status = SecCertificateCopyCommonName(certs[0], &commongName)
            XCTAssertEqual(status, errSecSuccess)
            XCTAssertNotNil(commongName)
            XCTAssertEqual((commongName! as String), "daniel")
            return true
        }
        let listener = try listen(tls: true, auth: listenerAuth)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)

        // Create client identity:
        let attrs = [certAttrCommonName: "daniel"]
        let identity = try TLSIdentity.createIdentity(forServer: false, attributes: attrs, expiration: nil, label: clientCertLabel)

        // Replicator:
        let auth = ClientCertificateAuthenticator.init(identity: identity)
        let serverCert = listener.tlsIdentity!.certs[0]
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false, auth: auth, serverCert: serverCert)

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)
        try stopListen()
    }

    func testClientCertAuthenticatorWithRootCerts() throws {
        if !self.keyChainAccessAllowed {
            return
        }
        // Root Cert:
        let rootCertData = try dataFromResource(name: "identity/client-ca", ofType: "der")
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!

        // Listener:
        let listenerAuth = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
        let listener = try listen(tls: true, auth: listenerAuth)

// tag::p2psync-act-tlsid-delete[]
        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)
// end::p2psync-act-tlsid-delete[]

        // Create client identity:
// tag::p2psync-act-tlsid-import[]
        let clientCertData = try dataFromResource(name: "identity/client", ofType: "p12")
        let identity = try TLSIdentity.importIdentity(withData: clientCertData, password: "123", label: clientCertLabel)
// end::p2psync-act-tlsid-import[]

        // Replicator:
        let auth = ClientCertificateAuthenticator.init(identity: identity)
        let serverCert = listener.tlsIdentity!.certs[0]

        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false, auth: auth, serverCert: serverCert)
        }

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)
        try stopListen()
    }

    func testServerCertVerificationModeSelfSignedCert() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Listener:
        let listener = try listen(tls: true)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)

        // Replicator - TLS Error:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .caCert, serverCert: nil, expectedError: CBLErrorTLSCertUnknownRoot)
        }

        // Replicator - Success:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .selfSignedCert, serverCert: nil)
        }

        // Cleanup
        try stopListen()
    }

    func testServerCertVerificationModeCACert() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Listener:
        let listener = try listen(tls: true)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)

        // Replicator - TLS Error:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .caCert, serverCert: nil, expectedError: CBLErrorTLSCertUnknownRoot)
        }

        // Replicator - Success:
        self.ignoreException {
            let serverCert = listener.tlsIdentity!.certs[0]
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: .caCert, serverCert: serverCert)
        }

        // Cleanup
        try stopListen()
    }

    func testPort() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = wsPort
        self.listener = URLEndpointListener(config: config)
        XCTAssertNil(self.listener!.port)

        // Start:
        try self.listener!.start()
        XCTAssertEqual(self.listener!.port, wsPort)

        try stopListen()
        XCTAssertNil(self.listener!.port)
    }

    func testEmptyPort() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        self.listener = URLEndpointListener(config: config)
        XCTAssertNil(self.listener!.port)

        // Start:
        try self.listener!.start()
        XCTAssertNotEqual(self.listener!.port, 0)

        try stopListen()
        XCTAssertNil(self.listener!.port)
    }

    func testBusyPort() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        try listen()

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = self.listener!.port
        let listener2 = URLEndpointListener(config: config)

        expectError(domain: NSPOSIXErrorDomain, code: Int(EADDRINUSE)) {
            try listener2.start()
        }
    }

    func testURLs() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = wsPort
        self.listener = URLEndpointListener(config: config)
        XCTAssertNil(self.listener!.urls)

        // Start:
        try self.listener!.start()
        XCTAssert(self.listener!.urls?.count != 0)

        try stopListen()
        XCTAssertNil(self.listener!.urls)
    }

    func testConnectionStatus() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.port = wsPort
        config.disableTLS = true
        self.listener = URLEndpointListener(config: config)
        XCTAssertEqual(self.listener!.status.connectionCount, 0)
        XCTAssertEqual(self.listener!.status.activeConnectionCount, 0)

        // Start:
        try self.listener!.start()
        XCTAssertEqual(self.listener!.status.connectionCount, 0)
        XCTAssertEqual(self.listener!.status.activeConnectionCount, 0)

        try generateDocument(withID: "doc-1")
        let rConfig = self.config(target: self.listener!.localURLEndpoint,
                                 type: .pushAndPull, continuous: false, auth: nil,
                                 serverCertVerifyMode: .caCert, serverCert: nil)
        var maxConnectionCount: UInt64 = 0, maxActiveCount:UInt64 = 0
        run(config: rConfig, reset: false, expectedError: nil) { (replicator) in
            replicator.addChangeListener { (change) in
                maxConnectionCount = max(self.listener!.status.connectionCount, maxConnectionCount)
                maxActiveCount = max(self.listener!.status.activeConnectionCount, maxActiveCount)
            }
        }
        XCTAssertEqual(maxConnectionCount, 1)
        XCTAssertEqual(maxActiveCount, 1)
        XCTAssertEqual(self.oDB.count, 1)

        try stopListen()
        XCTAssertEqual(self.listener!.status.connectionCount, 0)
        XCTAssertEqual(self.listener!.status.activeConnectionCount, 0)
    }

    func testMultipleListenersOnSameDatabase() throws {
        if !self.keyChainAccessAllowed { return }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        let listener1 = URLEndpointListener(config: config)
        let listener2 = URLEndpointListener(config: config)

        try listener1.start()
        try listener2.start()

        try generateDocument(withID: "doc-1")
        self.run(target: listener1.localURLEndpoint,
                 type: .pushAndPull,
                 continuous: false,
                 auth: nil,
                 serverCert: listener1.tlsIdentity!.certs[0])

        // since listener1 and listener2 are using same certificates, one listener only needs stop.
        listener2.stop()
        try stopListener(listener: listener1)
        XCTAssertEqual(self.oDB.count, 1)
    }

    func testReplicatorAndListenerOnSameDatabase() throws {
        if !self.keyChainAccessAllowed { return }

        let exp1 = expectation(description: "replicator#1 stop")
        let exp2 = expectation(description: "replicator#2 stop")

        // listener
        let doc = createDocument()
        try self.oDB.saveDocument(doc)
        try listen()

        // Replicator#1 (otherDB -> DB#1)
        let doc1 = createDocument()
        try self.db.saveDocument(doc1)
        let target = DatabaseEndpoint(database: self.db)
        let repl1 = replicator(db: self.oDB, continuous: true, target: target, serverCert: nil)

        // Replicator#2 (DB#2 -> Listener(otherDB))
        try deleteDB(name: "db2")
        let db2 = try openDB(name: "db2")
        let doc2 = createDocument()
        try db2.saveDocument(doc2)
        let repl2 = replicator(db: db2,
                               continuous: true,
                               target: self.listener!.localURLEndpoint,
                               serverCert: self.listener!.tlsIdentity!.certs[0])

        let changeListener = { (change: ReplicatorChange) in
            if change.status.activity == .idle &&
                change.status.progress.completed == change.status.progress.total {
                if self.oDB.count == 3 && self.db.count == 3 && db2.count == 3 {
                    change.replicator.stop()
                }
            }

            if change.status.activity == .stopped {
                if change.replicator.config.database.name == "db2" {
                    exp2.fulfill()
                } else {
                    exp1.fulfill()
                }
            }

        }
        let token1 = repl1.addChangeListener(changeListener)
        let token2 = repl2.addChangeListener(changeListener)

        repl1.start()
        repl2.start()
        wait(for: [exp1, exp2], timeout: 5.0)

        XCTAssertEqual(self.oDB.count, 3)
        XCTAssertEqual(self.db.count, 3)
        XCTAssertEqual(db2.count, 3)

        repl1.removeChangeListener(withToken: token1)
        repl2.removeChangeListener(withToken: token2)

        try db2.close()
        try stopListen()
    }

    func testCloseWithActiveListener() throws {
        if !self.keyChainAccessAllowed { return }

        try listen()

        // Close database should also stop the listener:
        try self.oDB.close()

        XCTAssertNil(self.listener!.port)
        XCTAssertNil(self.listener!.urls)

        try stopListen()
    }

    // TODO: https://issues.couchbase.com/browse/CBL-1008
    func _testEmptyNetworkInterface() throws {
        if !self.keyChainAccessAllowed { return }

        try listen()

        for (i, url) in self.listener!.urls!.enumerated() {
            // separate db instance!
            let db = try Database(name: "db-\(i)")
            let doc = createDocument()
            doc.setString(url.absoluteString, forKey: "url")
            try db.saveDocument(doc)

            // separate replicator instance
            let target = URLEndpoint(url: url)
            let rConfig = ReplicatorConfiguration(database: db, target: target)
            rConfig.pinnedServerCertificate = self.listener?.tlsIdentity!.certs[0]
            run(config: rConfig, expectedError: nil)

            // remove the db
            try db.delete()
        }

        XCTAssertEqual(self.oDB.count, UInt64(self.listener!.urls!.count))

        let q = QueryBuilder.select([SelectResult.all()]).from(DataSource.database(self.oDB))
        let rs = try q.execute()
        var result = [URL]()
        for res in rs.allResults() {
            let dict = res.dictionary(at: 0)
            result.append(URL(string: dict!.string(forKey: "url")!)!)
        }

        XCTAssertEqual(result, self.listener!.urls)
        try stopListen()

        // validate 0.0.0.0 meta-address should return same empty response.
        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.networkInterface = "0.0.0.0"
        try listen(config: config)
        XCTAssertEqual(self.listener!.urls!, result)
        try stopListen()
    }

    func testMultipleReplicatorsToListener() throws {
        if !self.keyChainAccessAllowed { return }

        try listen()

        let doc = createDocument()
        doc.setString("Tiger", forKey: "species")
        try self.oDB.saveDocument(doc)

        try validateMultipleReplicationsTo()

        try stopListen()
    }

    // TODO: https://issues.couchbase.com/browse/CBL-954
    func _testReadOnlyListener() throws {
        if !self.keyChainAccessAllowed { return }

        let config = URLEndpointListenerConfiguration(database: self.oDB)
        config.readOnly = true
        try listen(config: config)

        self.run(target: self.listener!.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: nil, serverCert: self.listener!.tlsIdentity!.certs[0],
                 expectedError: CBLErrorHTTPForbidden)
    }
}

@available(macOS 10.12, iOS 10.0, *)
extension URLEndpointListener {
    var localURL: URL {
        assert(self.port != nil && self.port! > UInt16(0))
        var comps = URLComponents()
        comps.scheme = self.config.disableTLS ? "ws" : "wss"
        comps.host = "localhost"
        comps.port = Int(self.port!)
        comps.path = "/\(self.config.database.name)"
        return comps.url!
    }

    var localURLEndpoint: URLEndpoint {
        return URLEndpoint.init(url: self.localURL)
    }
}

// END URLENDPOINTLISTENER SAMPLES


//
//  QueryResultSets.swift
//  sampleQueryResults
//
//  Created by Ian Bridge on 28/05/2021.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity
//import CoreML


class QueryResultSets {

    static var thisHotel = Hotel()

    let dbName = "hotel"
    //    let dbName = "hotel"
    var db = try! Database(name: "hotel")
    var hotels = [String:Any]()
    var thisDocsProperties = [String:Any]()
    var jsonbit = [String:Any]()

    func dontTestQueryAll() throws {

//        seedHotel()

// QUERY RESULT SET HANDLING EXAMPLES
// tag::query-syntax-all[]

        let listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database( db))

// end::query-syntax-all[]

// tag::query-access-all[]

        do {

            for (row) in try! listQuery.execute() {

                print(row.toDictionary())

                if let hotel = row.dictionary(forKey: "_doc") { // <.>

                    let hotelid = hotel["id"].string!

                    hotels[hotelid] = hotel.toDictionary()


                    if let thisDocsProperties =
                             hotel.toDictionary() as? [String:Any] { // <.>

                        let docid = thisDocsProperties["id"] as! String

                        let name = thisDocsProperties["name"] as! String

                        let type = thisDocsProperties["type"] as! String

                        let city = thisDocsProperties["city"] as! String

                        print("thisDocsProperties are: ", docid,name,type,city)

                    } // end if

                } // end if

            } // end for
        } catch let err {
            print(err.localizedDescription)
            // ... handle errors as required
        } //end do-block

    // end::query-access-all[]

//
    func dontTestQueryProps () throws {
        // tag::query-syntax-props[]
        let listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"),
                    SelectResult.expression(Expression.property("id")),
                    SelectResult.expression(Expression.property("name")),
                    SelectResult.expression(Expression.property("city")),
                    SelectResult.expression(Expression.property("type")))
                    .from(DataSource.database(db))

        // end::query-syntax-props[]

        // tag::query-access-props[]
        for (_, result) in try! listQuery.execute().enumerated() {

            print(result.toDictionary())

            if let thisDoc = result.toDictionary() as? [String:Any] {

                let docid = thisDoc["metaId"] as! String

                let hotelId = thisDoc["id"] as! String

                let name = thisDoc["name"] as! String

                let city = thisDoc["city"] as! String

                let type = thisDoc["type"] as! String

                // ... process document properties as required
                print("Result properties are: ", docid, hotelId,name, city, type)
          }
}

// end::query-access-props[]
    }

//
    func dontTestQueryCount () throws {

    // tag::query-syntax-count-only[]
        do {
            let listQuery = QueryBuilder
                .select(SelectResult.expression(Function.count(Expression.all())).as("mycount"))
                .from (DataSource.database(db)).groupBy(Expression.property("type"))

                // end::query-syntax-count-only[]


            // tag::query-access-count-only[]
            for result in try! listQuery.execute() {
                if let dict = result.toDictionary() as? [String: Int] {
                    let thiscount = dict["mycount"]! // <.>
                    print("There are ", thiscount, " rows")
                }
            }
        } // end do
    } // end function

// end::query-access-count-only[]

//
    func dontTestQueryId () throws {

        // tag::query-syntax-id[]
        let listQuery = QueryBuilder.select(SelectResult.expression(Meta.id).as("metaId"))
                    .from(DataSource.database(db))

        // end::query-syntax-id[]


        // tag::query-access-id[]
        for (_, result) in try! listQuery.execute().enumerated() {

            print(result.toDictionary())
            print("Document Id is -- ", result["metaId"].string!)

            let thisDocsId = result["metaId"].string! // <.>

            // Now you can get the document using the ID
            var thisDoc = db.document(withID: thisDocsId)!.toDictionary()

            let hotelId = thisDoc["id"] as! String

            let name = thisDoc["name"] as! String

            let city = thisDoc["city"] as! String

            let type = thisDoc["type"] as! String

            // ... process document properties as required
            print("Result properties are: ", hotelId,name, city, type)


        } // end for

// end::query-access-id[]
    } // end function dontTestQueryId

//
    func query_pagination () throws {

        //tag::query-syntax-pagination[]
        let thisOffset = 0;
        let thisLimit = 20;
        //
        let listQuery = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(db))
                .limit(Expression.int(thisLimit),
                  offset: Expression.int(thisOffset))

        // end::query-syntax-pagination[]

    } // end function
//
//


    func seedHotel () {

        try! db.delete()

        db = try! Database(name: "hotel")

        let key = ["id","name","type","city", "country","description"]
        let val = [
                    ["1000","Hotel Ted","hotel","Paris", "France","Very good and central"],
                    ["1001","Hotel Fred","hotel","London", "England","Very good and central"],
                    ["1002","Hotel Du Ville","hotel","Casablanca", "Morocco","Very good and central"],
                    ["1003","Hotel Ouzo","hotel","Athens", "Greece","Very good and central"]
                ]
        let maxrecs=val.count-1
        for i in 0 ... maxrecs {

            let hotel:MutableDocument = MutableDocument()

            for x in 0 ... key.count-1 {
                hotel.setString(val[i][x], forKey: key[x])
            }

            try! db.saveDocument(hotel)


        }

    }
//
//

} // end class



