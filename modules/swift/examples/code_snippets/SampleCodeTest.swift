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
        let newTask = Document()

        // tag::date-getter[]
        newTask.setValue(Date(), forKey: "createdAt")
        let date = newTask.date(forKey: "createdAt")
        // end::date-getter[]

        // tag::to-dictionary[]
        newTask.toDictionary() // <.>

        // end::to-dictionary[]

        // tag::to-json[]
        newTask.toJSON() // <.>

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


    func dontTestToJson-ArrayObject() throws {
        database = self.db
        // demonstrate use of JSON string
        // tag::tojson-array[]




        // end::tojson-array[]
    }


    func dontTestToJson-Blob() throws {
        database = self.db
        // demonstrate use of JSON string
        // add notes showing:
        // 1 - retrieval of document
        // 2 - test for blobness
        // 3 - conversion to Json (metadata only)
        // 4 - use of retrieved json data
        // tag::tojson-blob[]

        var thisdoc =
              database.document(withID: "thisdoc-id").toDictionary(); // <.>

        // var image: UIImage!

        // let appleImage = UIImage(named: "avatar.jpg")!
        // let imageData = UIImageJPEGRepresentation(appleImage, 1)!

        // let blob = Blob(contentType: "image/jpeg", data: imageData)
        // newTask.setBlob(blob, forKey: "avatar")
        // try database.saveDocument(newTask)

        if thisdoc.isBlob() { // <.>
          let blobdata = thisdoc.toJson() // <.>
          var blobtype = blobdata["type"] // <.>
          var bloblength = blobdata["length"]
        }
        // end::tojson-blob[]
    }


    func dontTestToJson-Dictionary() throws {
        database = self.db
        // demonstrate use of JSON string
        // tag::tojson-dictionary[]


        // end::tojson-dictionary[]
    }


    func dontTestToJson-Document() throws {
        database = self.db
        // demonstrate use of JSON string
        // tag::tojson-document[]


        // end::tojson-document[]
    }


    func dontTestToJson-Result() throws {
        database = self.db
        // demonstrate use of JSON string
        // tag::tojson-result[]
        let ourJSON =  "{{\"id\": \"hotel-ted\"},{\"name\": \"Hotel Ted\"},{\"city\": \"Paris\"},{\"type\": \"hotel\"}}"
        let ourDoc = try MutableDocument(id: "doc", json: ourJSON)
        try database.saveDocument(ourDoc)

        let query = QueryBuilder
                      .select(SelectResult.all)
                      .from(DataSource.database(database)))
                      .where(Expression.property("id").equalTo(Expression.string("hotel-ted"))))

        for (_,result) in try! query.execute().enumerated() {
          if let thisJSON = result.toJSON().toJSONObj() as? [String:Any] {
              // ... process document properties as required e.g.
              let docid = thisJSON["id"]
              let name = thisJSON["name"]
              let city = thisJSON["city"]
              let type = thisJSON["type"]
              //
          }

        // end::tojson-result[]
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
//  Changed for 3.0.0 - Ian Bridge 3/Mar/21
    func testCustomRetryConfig() {
        // tag::replication-retry-config[]
        let target =
          URLEndpoint(url: URL(string: "ws://foo.couchbase.com/db")!)

        let config =  ReplicatorConfiguration(database: database, target: targetDatabase)
        config.type = .pushAndPull
        config.continuous = true
        // tag::replication-set-heartbeat[]
        config.heartbeat = 150 // <.>

        // end::replication-set-heartbeat[]
        // tag::replication-set-maxretries[]
        config.maxretries = 20 // <.>

        // end::replication-set-maxretries[]
        // tag::replication-set-maxretrywaittime[]
        config.maxretrywaittime = 600 // <.>
        repl = Replicator(config: config)

        // end::replication-set-maxretrywaittime[]

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
//  Created by Ian Bridge on 28/07/2021.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

//import CoreML


class Query {

    var this_hotel:Hotel = Hotel()

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
        let db = try! Database(name: "hotel")
        var hotels = [String:Any]()

        let listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database( db))

    // end::query-syntax-all[]

    // tag::query-access-all[]

        do {

            for row in try! listQuery.execute() {

                let thisDocsProps =
                    row.dictionary(at: 0)?.toDictionary() // <.>

                let docid = thisDocsProps!["id"] as! String

                let name = thisDocsProps!["name"] as! String

                let type = thisDocsProps!["type"] as! String

                let city = thisDocsProps!["city"] as! String

                let hotel = row.dictionary(at: 0)?.toDictionary()  //<.>
                let hotelId = hotel!["id"] as! String
                hotels[hotelId] = hotel
            } // end for

        } //end do-block

    // end::query-access-all[]

    // tag::query-access-json[]

    // In this example the Hotel class is defined using Codable
    //
    // class Hotel : Codable {
    //   var id : String = "undefined"
    //   var type : String = "hotel"
    //   var name : String = "undefined"
    //   var city : String = "undefined"
    //   var country : String = "undefined"
    //   var description : String? = ""
    //   var text : String? = ""
    //   ... other class content
    // }


        do {
            var results = try! listQuery.execute()
            for row in  results {

                // If Query selected ALL,
                //    unpack items from encompassing dictionary // <.>
                let jsonString = row.dictionary(at: 0)!.toJSON()
                // ALTERNATIVELY: If Query selected specific items
                let jsonString = row.toJSON()

                let thisJsonObj:Dictionary =
                    try! (JSONSerialization.jsonObject(
                            with: jsonString.data(using: .utf8)!,
                                                  options: .allowFragments)
                            as? [String: Any])! // <.>

                // Use Json Object to populate Native object
                // Use Codable class to unpack JSON data to native object // <.>
                let this_hotel:Hotel =
                    (try JSONDecoder().decode(
                        Hotel.self,
                        from: jsonString.data(using: .utf8)!
                        )
                    )

                // ALTERNATIVELY unpack in steps
                this_hotel.id = thisJsonObj["id"] as! String
                this_hotel.name = thisJsonObj["name"] as! String
                this_hotel.type = thisJsonObj["type"] as! String
                this_hotel.city = thisJsonObj["city"] as! String
                hotels[this_hotel.id] = this_hotel


            } // end for

            // end::query-access-json[]

        } catch let err {
            print(err.localizedDescription)

        } // end do



    } // end func dontTestQueryAll



    func dontTestQueryProps () throws {
        // tag::query-syntax-props[]
        let db = try! Database(name: "hotel")
        var hotels = [String:Any]()
        var hotel:Hotel = Hotel.init()

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


            let thisDoc = result.toDictionary() as? [String:Any]  // <.>
                // Store dictionary data in hotel object and save in arry
            hotel.id = thisDoc!["id"] as! String
            hotel.name = thisDoc!["name"] as! String
            hotel.city = thisDoc!["city"] as! String
            hotel.type = thisDoc!["type"] as! String
            hotels[hotel.id] = hotel

            // Use result content directly
            let docid = result.string(forKey: "metaId")
            let hotelId = result.string(forKey: "id")
            let name = result.string(forKey: "name")
            let city = result.string(forKey: "city")
            let type = result.string(forKey: "type")

            // ... process document properties as required
            print("Result properties are: ", docid, hotelId,name, city, type)
          } // end for

// end::query-access-props[]
    }// end func

//
    func dontTestQueryCount () throws {

    // tag::query-syntax-count-only[]
        let db = try! Database(name: "hotel")
        do {
            let listQuery = QueryBuilder
                .select(SelectResult.expression(Function.count(Expression.all())).as("mycount"))
                .from (DataSource.database(db)).groupBy(Expression.property("type"))

                // end::query-syntax-count-only[]


            // tag::query-access-count-only[]

            for result in try! listQuery.execute() {
                let dict = result.toDictionary() as? [String: Int]
                let thiscount = dict!["mycount"]! // <.>
                print("There are ", thiscount, " rows")

                // Alternatively
                print ( result["mycount"] )

            } // end for

        } // end do
    } // end function

// end::query-access-count-only[]

//
    func dontTestQueryId () throws {

        // tag::query-syntax-id[]
        let db = try! Database(name: "hotel")
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

            let hotel:MutableDocument = MutableDocument(id: val[0][i])

            for x in 0 ... key.count-1 {
                hotel.setString(val[i][x], forKey: key[x])
            }

            try! db.saveDocument(hotel)


        }

    }

//
// N1QL QUERY EXAMPLES
//

    func dontTestQueryN1QL() throws {


    // tag::query-syntax-n1ql[]
        let db = try! Database(name: "hotel")

        let listQuery =  db.createQuery( query:
            "SELECT META().id AS thisId FROM \(db.name) WHERE type = 'hotel'" // <.>
        )

        let results: ResultSet = try listQuery.execute()

    // end::query-syntax-n1ql[]

        if (results.allResults().count>0) {
            try! dontTestProcessResults(results: results)
        }

    } // dontTestQueryN1QL


    func dontTestQueryN1QLparams() throws {

    // tag::query-syntax-n1ql-params[]
        let db = try! Database(name: "hotel")

        let listQuery =
            db.createQuery( query:
                   "SELECT META().id AS thisId FROM _ WHERE type = $type" // <.>
                )

        listQuery.parameters =
            Parameters().setString("hotel", forName: "type") // <.>

        let results: ResultSet = try listQuery.execute()

    // end::query-syntax-n1ql-params[]

        if (results.allResults().count>0) {
            try! dontTestProcessResults(results: results)
        }

    } // dontTestQueryN1QLparams()


    func dontTestProcessResults(results: ResultSet) throws {
        // tag::query-access-n1ql[]
        // tag::query-process-results[]

        do {

            for row in results {

                print(row["thisId"].string!)

                let thisDocsId = row["thisId"].string!

                // Now you can get the document using the ID
                var thisDoc = db.document(withID: thisDocsId)!.toDictionary()

                let hotelId = thisDoc["id"] as! String

                let name = thisDoc["name"] as! String

                let city = thisDoc["city"] as! String

                let type = thisDoc["type"] as! String

                // ... process document properties as required
                print("Result properties are: ", hotelId,name, city, type)

            } // end for
            // end::query-access-n1ql[]
            // end::query-process-results[]

        } //end do-block

    } // end dontTestProcessResults

} // end class






//  JSAON API SNIPPETS


    func dontTestJSONdocument() {
        // tag::query-get-all[]
        let db = try! Database(name: "hotel")
        let dbnew = try! Database(name: "newhotels")
        var hotels = [String:Any]()

        let listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(db))


        for row in try! listQuery.execute() {
        // end::query-get-all[]

        // tag::tojson-document[]
            var thisId = row.string(forKey: "metaId")! as String

            var thisJSONstring = try! db.document(withID: thisId)!.toJSON() // <.>

            print("JSON String = ", thisJSONstring as! String)

            let hotelFromJSON:MutableDocument = // <.>
                    try! MutableDocument(id: thisId as? String, json: thisJSONstring)

            try! dbnew.saveDocument(hotelFromJSON)

            let newhotel = dbnew.document(withID: thisId)

            let keys = newhotel!.keys
            for key in keys { // <.>
                print(key, newhotel!.value(forKey: key) as! String)
            }

            // end::tojson-document[]

        /*
        // tag::tojson-document-output[]
             JSON String =  {"description":"Very good and central","id":"1000","country":"France","name":"Hotel Ted","type":"hotel","city":"Paris"}
             type hotel
             id 1000
             country France
             city Paris
             description Very good and central
             name Hotel Ted
        // end::tojson-document-output[]
         */
        } // end  query for loop


        // tag::tojson-array[]

        let thisJSONstring = """
            [{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\",
            \"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},
            {\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\",
            \"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},
            {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
            \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\",
            \"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]
            """
        let myArray:MutableArrayObject =
            try! MutableArrayObject.init(json: thisJSONstring) // <.>

        for i in 0...myArray.count-1 {

            print(i+1, myArray.dictionary(at: i)!.string(forKey: "name")!)

            var docid = myArray.dictionary(at: i)!.string(forKey: "id")

            var newdoc:MutableDocument = // <.>
                try! MutableDocument(id: docid,
                         data: (myArray.dictionary(at: i)?.toDictionary())! )

            try! dbnew.saveDocument(newdoc)

        }

        let extendedDoc = dbnew.document(withID: "1002")
        let features =
            extendedDoc!.array(forKey: "features")?.toArray() // <.>
        for i in 0...features!.count-1 {
            print(features![i])
        }

        print( extendedDoc!.array(
                forKey: "features")?.toJSON() as! String) // <.>

        // end::tojson-array[]

        /*
        // tag::tojson-array-output[]

         1 Hotel Ted
         2 Hotel Fred
         3 Hotel Ned

         Cable TV
         Toaster
         Microwave

         ["Cable TV","Toaster","Microwave"]
         // end::tojson-array-output[]
        */


        // tag::tojson-dictionary[]

        var aJSONstring = """
            {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
            \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\"}
            """

        let myDict:MutableDictionaryObject =
            try! MutableDictionaryObject(json: aJSONstring) // <.>
        print(myDict)

        let name = myDict.string(forKey: "name")
        print("Details for: ", name!)

        for key in myDict {

            print(key, myDict.value(forKey: key) as! String)

        }


        // end::tojson-dictionary[]

        /*
        // tag::tojson-dictionary-output[]

         Details for:  Hotel Ned
         description Undefined description for Hotel Ned
         id 1002
         name Hotel Ned
         country Australia
         type hotel
         city Balmain

         // end::tojson-dictionary-output[]
        */
    public func JsonApiBlob() throws {


        // tag::tojson-blob[]

        // Get a document
        let thisDoc = db.document(withID: "1000")?.toMutable() // <.>


        // Get the image and add as a blob to the document
        let contentType = "";
        let ourImage = UIImage(named: "couchbaseimage.png")!
        let imageData = ourImage.jpegData(compressionQuality: 1)! // <.>
        thisDoc?.setBlob(
            Blob(contentType: contentType, data: imageData), forKey: "avatar") //<.>

       let theBlobAsJSONstringFails =
              thisDoc?.blob(forKey: "avatar")!.toJSON(); // <.>

        // Save blob as part of doc or alternatively as a blob

        try! db.saveDocument(thisDoc!);
        try! db.saveBlob(
                blob: Blob(contentType: contentType, data: imageData)); //<.>;

        // Retrieve saved blob as a JSON, reconstitue and check still blob
        let sameDoc = db.document(withID: "1000")?.toMutable()
        let theBlobAsJSONstring = sameDoc?.blob(forKey: "avatar")!.toJSON(); // <.>
        let reconstitutedBlob =
             MutableDictionaryObject().
                setDictionary(try MutableDictionaryObject().
                    setJSON(theBlobAsJSONstring!), forKey: "blobCOPY")
        for (key, value) in sameDoc!.toDictionary() {
             print( "Data -- {0) = {1}", key, value);
        }

        if(Blob.isBlob(properties: reconstitutedBlob.dictionary(forKey: "blobCOPY")!.toDictionary())) // <.>
        {
            print(theBlobAsJSONstring);
        }

        // end::tojson-blob[]


    }





//    } // end func testjson

//        } // end query loop


    } // end jsonapi func


}

    extension String {

        func toJSONObj() -> Any {

            let d1 = self.data(using: .utf8)

            return try! JSONSerialization.jsonObject(
                with: d1!, options:[])
        }
    }



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

// tag::listener[]

// tag::listener-simple[]
val config =
  URLEndpointListenerConfiguration(database) // <.>

config.setAuthenticator(
    ListenerPasswordAuthenticator {
      username, password ->
        "valid.user" == username &&
        ("valid.password.string" == String(password))
    }
) // <.>

val listener =
  URLEndpointListener(config) // <.>

listener.start()  // <.>

// end::listener-simple[]



// tag::replicator-simple[]

let tgtUrl = URL(string: "wss://10.1.1.12:8092/actDb")!
let targetEndpoint = URLEndpoint(url: tgtUrl) //  <.>

var thisConfig = ReplicatorConfiguration(database: actDb!, target: targetEndpoint) // <.>

thisConfig.acceptOnlySelfSignedServerCertificate = true; <.>

let thisAuthenticator = BasicAuthenticator(username: "valid.user", password: "valid.password.string")
thisConfig.authenticator = thisAuthenticator // <.>

this.replicator = new Replicator(config); // <.>

this.replicator.start(); // <.>

// end::replicator-simple[]



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
    // tag::xctListener-start-func[]
    func listen(tls: Bool, auth: ListenerAuthenticator?) throws -> URLEndpointListener {
        // Stop:
        if let listener = self.listener {
            listener.stop()
        }

        // Listener:
    // tag::xctListener-start[]
    // tag::xctListener-config[]
    //  ... fragment preceded by other user code, including
    //  ... Couchbase Lite Database initialization that returns `thisDB`

    guard let db = thisDB else {
      throw print("DatabaseNotInitialized")
      // ... take appropriate actions
    }
    var listener: URLEndpointListener?
    let config = URLEndpointListenerConfiguration.init(database: db)
    config.port = tls ? wssPort : wsPort
    config.disableTLS = !tls
    config.authenticator = auth
    self.listener = URLEndpointListener.init(config: config)
//  ... fragment followed by other user code
    // end::xctListener-config[]

        // Start:
        try self.listener!.start()
    // end::xctListener-start[]

        return self.listener!
    }
    // end::xctListener-start-func[]

    func stopListen() throws {
        if let listener = self.listener {
            try stopListener(listener: listener)
        }
    }

    func stopListener(listener: URLEndpointListener) throws {
    // tag::xctListener-stop-func[]
    var listener: URLEndpointListener?
        let identity = listener.tlsIdentity
        listener.stop()
        if let id = identity {
            try id.deleteFromKeyChain()
    // end::xctListener-stop-func[]
        }
    }

    func cleanUpIdentities() throws {
// tag::xctListener-delete-anon-ids[]
        try URLEndpointListener.deleteAnonymousIdentities()
// end::xctListener-delete-anon-ids[]
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

// tag::xctListener-auth-tls-tlsidentity-anon[]
        // Anonymous Identity:

        config = URLEndpointListenerConfiguration.init(database: self.oDB)
        listener = URLEndpointListener.init(config: config)
        XCTAssertNil(listener.tlsIdentity)

        try listener.start()
        XCTAssertNotNil(listener.tlsIdentity)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)

// end::xctListener-auth-tls-tlsidentity-anon[]

// tag::xctListener-auth-tls-tlsidentity-ca[]
        // User Identity:
        try TLSIdentity.deleteIdentity(withLabel: serverCertLabel);
        let attrs = [certAttrCommonName: "CBL-Server"]
        let identity = try TLSIdentity.createIdentity(forServer: true,
                                                      attributes: attrs,
                                                      expiration: nil,
                                                      label: serverCertLabel)
        config = URLEndpointListenerConfiguration.init(database: self.oDB)
        config.tlsIdentity = identity
        listener = URLEndpointListener.init(config: config)
        var(listener.tlsIdentity)

        try listener.start()
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssert(identity === listener.tlsIdentity!)
        try stopListener(listener: listener)
        XCTAssertNil(listener.tlsIdentity)
// end::xctListener-auth-tls-tlsidentity-ca[]
    }

    func testPasswordAuthenticator() throws {
// tag::xctListener-auth-basic-pwd-full[]
        // Listener:
// tag::xctListener-auth-basic-pwd[]
        let thisAuth = ListenerPasswordAuthenticator.init {
            (validUser, validPassword) -> Bool in
            return (username as NSString).isEqual(to: "daniel") &&
                   (password as NSString).isEqual(to: "123")
        }
        let listener = try listen(tls: false, auth: thisAuth)

        auth = BasicAuthenticator.init(username: "daniel", password: "123")
        self.run(target: listener.localURLEndpoint, type: .pushAndPull,    continuous: false,
                 auth: auth)
// end::xctListener-auth-basic-pwd[]

        // Replicator - No Authenticator:
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: nil, expectedError: CBLErrorHTTPAuthRequired)

        // Replicator - Wrong Credentials:
        var auth = BasicAuthenticator.init(username: "daniel", password: "456")
        self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                 auth: auth, expectedError: CBLErrorHTTPAuthRequired)


        // Cleanup:
        try stopListen()
    }
// end::xctListener-auth-basic-pwd-full[]

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

// tag::xctListener-auth-tls-CCA-Root-full[]
// tag::xctListener-auth-tls-CCA-Root[]
        // Root Cert:
        let rootCertData = try dataFromResource(name: "identity/client-ca", ofType: "der")
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!

        // Listener:
        let listenerAuth = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
        let listener = try listen(tls: true, auth: listenerAuth)
// end::xctListener-auth-tls-CCA-Root[]

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)

        // Create client identity:
        let clientCertData = try dataFromResource(name: "identity/client", ofType: "p12")
        let identity = try TLSIdentity.importIdentity(withData: clientCertData, password: "123", label: clientCertLabel)

        // Replicator:
        let auth = ClientCertificateAuthenticator.init(identity: identity)
        let serverCert = listener.tlsIdentity!.certs[0]

        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false, auth: auth, serverCert: serverCert)
// end::xctListener-auth-tls-CCA-Root-full[]
        }

        // Cleanup:
        try TLSIdentity.deleteIdentity(withLabel: clientCertLabel)
        try stopListen()
    }

    func testServerCertVerificationModeSelfSignedCert() throws {
        if !self.keyChainAccessAllowed {
            return
        }
// tag::xctListener-auth-tls-self-signed-full[]
// tag::xctListener-auth-tls-self-signed[]
        // Listener:
        let listener = try listen(tls: true)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)


        // Replicator - Success:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: true, serverCert: nil)
        }
// end::xctListener-auth-tls-self-signed[]
        // Replicator - TLS Error:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: false, serverCert: nil, expectedError: CBLErrorTLSCertUnknownRoot)
        }

        // Cleanup
        try stopListen()
// end::xctListener-auth-tls-self-signed-full[]
    }

// tag::xctListener-auth-tls-ca-cert-full[]
    func testServerCertVerificationModeCACert() throws {
        if !self.keyChainAccessAllowed {
            return
        }

        // Listener:
// tag::xctListener-auth-tls-ca-cert[]
        let listener = try listen(tls: true)
        XCTAssertNotNil(listener.tlsIdentity)
        XCTAssertEqual(listener.tlsIdentity!.certs.count, 1)

        // Replicator - Success:
        self.ignoreException {
            let serverCert = listener.tlsIdentity!.certs[0]
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: false, serverCert: serverCert)
        }
// end::xctListener-auth-tls-ca-cert[]

        // Replicator - TLS Error:
        self.ignoreException {
            self.run(target: listener.localURLEndpoint, type: .pushAndPull, continuous: false,
                     serverCertVerifyMode: false, serverCert: nil, expectedError: CBLErrorTLSCertUnknownRoot)
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
// tag::xctListener-status-check-full[]
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
                                 serverCertVerifyMode: false, serverCert: nil)
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
// end::xctListener-status-check-full[]

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
// end::start-replication[]

// tag::xctListener-auth-password-basic[]
listenerConfig.authenticator = ListenerPasswordAuthenticator.init {
  (username, password) -> Bool in
    (["password" : password, "name":username])
    if (self._allowListedUsers.contains(["password" : password, "name":username])) {
        return true
    }
    return false
}
// end::xctListener-auth-password-basic[]

// tag::xctListener-auth-cert-roots[]
let rootCertData = try dataFromResource(name: "identity/client-ca", ofType: "der")
let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
let listenerAuth = ListenerCertificateAuthenticator.init(rootCerts: [rootCert])
let listener = try listen(tls: true, auth: listenerAuth)// end::xctListener-auth-cert-roots[]

// tag::xctListener-auth-cert-auth[]
let listenerAuth = ListenerCertificateAuthenticator.init { (certs) -> Bool in
    XCTAssertEqual(certs.count, 1)
    var commongName: CFString?
    let status = SecCertificateCopyCommonName(certs[0], &commongName)
    XCTAssertEqual(status, errSecSuccess)
    XCTAssertNotNil(commongName)
    XCTAssertEqual((commongName! as String), "daniel")
    return true
}
// end::xctListener-auth-cert-auth[]

// tag::xctListener-config-basic-auth[]
let listenerConfig = URLEndpointListenerConfiguration(database: db)
listenerConfig.disableTLS  = true // Use with anonymous self signed cert
listenerConfig.enableDeltaSync = true
listenerConfig.tlsIdentity = nil

listenerConfig.authenticator = ListenerPasswordAuthenticator.init {
            (validUser, validPassword) -> Bool in
    if (self._whitelistedUsers.contains(["password" : validPassword, "name":validUser])) {
        return true
    }
    return false
        }

_thisListener = URLEndpointListener(config: listenerConfig)
// end::xctListener-config-basic-auth[]





// tag::replication-start-func[]
    func startP2PReplicationWithUserDatabaseToRemotePeer(_ peer:PeerHost, handler:@escaping(_ status:PeerConnectionStatus)->Void) throws{
        print("\(#function) with ws://\(peer)/\(kUserDBName)")
        guard let userDb = thisDB else {
          throw print("DatabaseNotInitialized")
          // ... take appropriate actions
        }
        guard let user = self.currentUserCredentials?.user, let password = self.currentUserCredentials?.password else {
          throw print("UserCredentialsNotProvided")
          // ... take appropriate actions
        }

// tag::replicator-start-func-config-init[]
        var replicatorForUserDb = _replicatorsToPeers[peer]

        if replicatorForUserDb == nil {
            // Start replicator to connect to the URLListenerEndpoint
            guard let targetUrl = URL(string: "ws://\(peer)/\(kUserDBName)") else {
                throw print("URLInvalid")
                // ... take appropriate actions
            }


            let config = ReplicatorConfiguration.init(database: userDb, target: URLEndpoint.init(url:targetUrl)) //<1>
// end::replicator-start-func-config-init[]

// tag::replicator-start-func-config-more[]

            config.replicatorType = .pushAndPull // <2>
            config.continuous =  true // <3>

// end::replicator-start-func-config-more[]

// tag::replicator-start-func-config-auth[]

            config.acceptOnlySelfSignedServerCertificate = true
            let authenticator = BasicAuthenticator(username: validUser, password: validPassword)
            config.authenticator = authenticator
// end::replicator-start-func-config-auth[]

// tag::replicator-start-func-repl-init[]
replicatorForUserDb = Replicator.init(config: config)
_replicatorsToPeers[peer] = replicatorForUserDb
// end::replicator-start-func-repl-init[]
          }


// tag::replicator-start-func-repl-start[]
if let pushPullReplListenerForUserDb = registerForEventsForReplicator(replicatorForUserDb,handler:handler) {
    _replicatorListenersToPeers[peer] = pushPullReplListenerForUserDb

}
replicatorForUserDb?.start()
handler(PeerConnectionStatus.Connecting)
// end::replicator-start-func-repl-start[]

      }
// end::replication-start-func[]


// tag::replicator-register-for-events[]
fileprivate func registerForEventsForReplicator(_ replicator:Replicator?,
  handler:@escaping(_ status:PeerConnectionStatus)->Void )->ListenerToken? {
    let pushPullReplListenerForUserDb = replicator?.addChangeListener({ (change) in

      let s = change.status
      if s.error != nil {
          handler(PeerConnectionStatus.Error)
          return
      }

      switch s.activity {
      case .connecting:
          print("Replicator Connecting to Peer")
          handler(PeerConnectionStatus.Connecting)
      case .idle:
          print("Replicator in Idle state")
          handler(PeerConnectionStatus.Connected)
      case .busy:
          print("Replicator in busy state")
          handler(PeerConnectionStatus.Busy)
      case .offline:
          print("Replicator in offline state")
      case .stopped:
          print("Completed syncing documents")
          handler(PeerConnectionStatus.Error)

      }

      if s.progress.completed == s.progress.total {
          print("All documents synced")
      }
      else {
          print("Documents \(s.progress.total - s.progress.completed) still pending sync")
      }
  })
  return pushPullReplListenerForUserDb
// end::replicator-register-for-events[]




//
// Stuff I adapted
//


import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class cMyPassListener {
  fileprivate var _allowlistedUsers:[[String:String]] = []
  // tag::listener-initialize[]
  fileprivate var _thisListener:URLEndpointListener?
  fileprivate var thisDB:Database?

    // tag::listener-config-db[]
    let listenerConfig =
      URLEndpointListenerConfiguration(database: thisDB!) // <.>

    // end::listener-config-db[]
    // tag::listener-config-port[]
    /* optionally */ let wsPort: UInt16 = 55991
    /* optionally */ let wssPort: UInt16 = 55990
    listenerConfig.port =  wssPort // <.>

    // end::listener-config-port[]
    // tag::listener-config-netw-iface[]
    listenerConfig.networkInterface = "10.1.1.10"  // <.>

    // end::listener-config-netw-iface[]
    // tag::listener-config-delta-sync[]
    listenerConfig.enableDeltaSync = true // <.>

    // end::listener-config-delta-sync[]
    // tag::listener-config-tls-enable[]
    listenerConfig.disableTLS  = false // <.>

    // end::listener-config-tls-enable[]
     // tag::listener-config-tls-id-anon[]
    // Set the credentials the server presents the client
    // Use an anonymous self-signed cert
    listenerConfig.tlsIdentity = nil // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-client-auth-pwd[]
    // Configure how the client is to be authenticated
    // Here, use Basic Authentication
    listenerConfig.authenticator =
      ListenerPasswordAuthenticator(authenticator: {
        (validUser, validPassword) -> Bool in
          if (self._allowlistedUsers.contains {
                $0 == validPassword && $1 == validUser
              }) {
              return true
              }
            return false
          }) // <.>

    // end::listener-config-client-auth-pwd[]

    // tag::listener-start[]
    // Initialize the listener
    _thisListener = URLEndpointListener(config: listenerConfig) // <.>
    guard let thisListener = _thisListener else {
      throw ListenerError.NotInitialized
      // ... take appropriate actions
    }
    // Start the listener
    try thisListener.start() // <.>

    // end::listener-start[]
// end::listener-initialize[]
  }
}


// BEGIN Additonal listener options



// tag::listener-get-network-interfaces[]
import SystemConfiguration
// . . .

  #if os(macOS)
  for interface in SCNetworkInterfaceCopyAll() as! [SCNetworkInterface] {
      // do something with this `interface`
  }
  #endif
// . . .

// end::listener-get-network-interfaces[]

// tag::listener-get-url-list[]
let config =
  URLEndpointListenerConfiguration(database: self.oDB)
let listener = URLEndpointListener(config: config)
try listener.start()

print("urls: \(listener.urls)")

// end::listener-get-url-list[]


    // tag::listener-config-tls-full[]
    // tag::listener-config-tls-full-enable[]
    listenerConfig.disableTLS  = false // <.>

    // end::listener-config-tls-full-enable[]
    // tag::listener-config-tls-disable[]
    listenerConfig.disableTLS  = true // <.>

    // end::listener-config-tls-disable[]

    // tag::listener-config-tls-id-full[]
    // tag::listener-config-tls-id-caCert[]
    guard let pathToCert =
      Bundle.main.path(forResource: "cert", ofType: "p12")
    else { /* process error */ return }

    guard let localCertificate =
      try? NSData(contentsOfFile: pathToCert) as Data
    else { /* process error */ return } // <.>

    let thisIdentity =
      try TLSIdentity.importIdentity(withData: localCertificate,
                                    password: "123",
                                    label: thisSecId) // <.>

    // end::listener-config-tls-id-caCert[]
    // tag::listener-config-tls-id-SelfSigned[]
    let attrs = [certAttrCommonName: "Couchbase Inc"] // <.>

    let thisIdentity =
      try TLSIdentity.createIdentity(forServer: true, /* isServer */
            attributes: attrs,
            expiration: Date().addingTimeInterval(86400),
            label: "Server-Cert-Label") // <.>

    // end::listener-config-tls-id-SelfSigned[]
    // tag::listener-config-tls-id-full-set[]
    // Set the credentials the server presents the client
    listenerConfig.tlsIdentity = thisIdentity    // <.>

    // end::listener-config-tls-id-full-set[]
    // end::listener-config-tls-id-full[]
    // tag::listener-config-client-root-ca[]
    // tag::listener-config-client-auth-root[]
    // Authenticate using Cert Authority

    // cert is a pre-populated object of type:SecCertificate representing a certificate
    let rootCertData = SecCertificateCopyData(cert) as Data // <.>
    let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)! //

    listenerConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert]) // <.> <.>

    // end::listener-config-client-auth-root[]
    // end::listener-config-client-root-ca[]
    // tag::listener-config-client-auth-lambda[]
    // tag::listener-config-client-auth-self-signed[]
    // Authenticate self-signed cert using application logic

    // cert is a user-supplied object of type:SecCertificate representing a certificate
    let rootCertData = SecCertificateCopyData(cert) as Data // <.>
    let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!

    listenerConfig.authenticator = ListenerCertificateAuthenticator.init { // <.>
      (certs) -> Bool in
        var certs:SecCertificate
        var certCommonName:CFString?
        let status=SecCertificateCopyCommonName(certs[0], &certCommonName)
        if (self._allowedCommonNames.contains(["name": certCommonName! as String])) {
            return true
        }
        return false
    } // <.>

    // end::listener-config-client-auth-self-signed[]
    // end::listener-config-client-auth-lambda[]
// END Additonal listener options





// tag::old-listener-config-tls-id-nil[]
listenerConfig.tlsIdentity = nil

// end::old-listener-config-tls-id-nil[]
// tag::old-listener-config-delta-sync[]
listenerConfig.enableDeltaSync = true

// end::old-listener-config-delta-sync[]
// tag::listener-status-check[]
let totalConnections = thisListener.status.connectionCount
let activeConnections = thisListener.status.activeConnectionCount

// end::listener-status-check[]
// tag::listener-stop[]
        thisListener.stop()

// end::listener-stop[]
// tag::old-listener-config-client-auth-root[]
  // cert is a pre-populated object of type:SecCertificate representing a certificate
  let rootCertData = SecCertificateCopyData(cert) as Data
  let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
  // Listener:
  listenerConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

// end::old-listener-config-client-auth-root[]
// tag::old-listener-config-client-auth-self-signed[]
listenerConfig.authenticator = ListenerCertificateAuthenticator.init {
  (cert) -> Bool in
    var cert:SecCertificate
    var certCommonName:CFString?
    let status=SecCertificateCopyCommonName(cert, &certCommonName)
    if (self._allowlistedUsers.contains(["name": certCommonName! as String])) {
        return true
    }
    return false
}
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
config.port = tls ? wssPort : wsPort
config.disableTLS = !tls
config.authenticator = auth
self.listener = URLEndpointListener.init(config: config) // <1>
// end::p2p-ws-api-urlendpointlistener-constructor[]


// Active Peer Connection Snippets

//
//  my Other Bits.swift
//  doco-sync
//
//  Created by Ian Bridge on 19/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class myActPeerClass {

  func fMyActPeer() {
    // tag::p2p-act-rep-func[]
    let validUser = "syncuser"
    let validPassword = "sync9455"
    let cert:SecCertificate?
    let passivePeerEndpoint = "10.1.1.12:8920"
    let passivePeerPort = "8920"
    let passiveDbName = "userdb"
    var actDb:Database?
    var thisReplicator:Replicator?
    var replicatorListener:ListenerToken?


    // tag::p2p-act-rep-initialize[]
    let tgtUrl = URL(string: "wss://10.1.1.12:8092/actDb")!
    let targetEndpoint = URLEndpoint(url: tgtUrl)
    var config = ReplicatorConfiguration(database: actDb!, target: targetEndpoint) // <.>

    // end::p2p-act-rep-initialize[]
    // tag::p2p-act-rep-config[]
    // tag::p2p-act-rep-config-type[]
    config.replicatorType = .pushAndPull

    // end::p2p-act-rep-config-type[]
    // tag::p2p-act-rep-config-cont[]
    // Configure Sync Mode
    config.continuous = true

    // end::p2p-act-rep-config-cont[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Security -- only accept self-signed certs
    config.acceptOnlySelfSignedServerCertificate = true; <.>

    // end::p2p-act-rep-config-self-cert[]
    // Configure Client Security // <.>
    // tag::p2p-act-rep-auth[]
    //  Set Authentication Mode
    let thisAuthenticator = BasicAuthenticator(username: "Our Username", password: "Our Password")
    config.authenticator = thisAuthenticator

    // end::p2p-act-rep-auth[]
    // tag::p2p-act-rep-config-conflict[]
    /* Optionally set custom conflict resolver call back */
    config.conflictResolver = ( /* define resolver function */); // <.>

    // end::p2p-act-rep-config-conflict[]
    // end::p2p-act-rep-config[]
    // tag::p2p-act-rep-start-full[]
    // Apply configuration settings to the replicator
    thisReplicator = Replicator.init( config: config) // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // Optionally add a change listener
    // Retain token for use in deletion
    let pushPullReplListener:ListenerToken? = thisReplicator?.addChangeListener({ (change) in // <.>
      if change.status.activity == .stopped {
          print("Replication stopped")
      }
      else {
      // tag::p2p-act-rep-status[]
          print("Replicator is currently ", thisReplicator?.status.activity)
      }
    })

    // end::p2p-act-rep-status[]
    // end::p2p-act-rep-add-change-listener[]

    // tag::p2p-act-rep-start[]
        // Run the replicator using the config settings
        thisReplicator?.start()  // <.>

    // end::p2p-act-rep-start[]
    // end::p2p-act-rep-start-full[]


    // end::p2p-act-rep-func[]
    }

    func mystopfunc() {
// tag::p2p-act-rep-stop[]
    // Remove the change listener

    thisReplicator?.removeChangeListener(withToken: pushPullReplListener)
    // Stop the replicator
    thisReplicator?.stop()

// end::p2p-act-rep-stop[]
}


// BEGIN Additional p2p-avt-rep options
    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security -- only accept CA Certs
    config.acceptOnlySelfSignedServerCertificate = false // <.>

    // end::p2p-act-rep-config-cacert[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Security -- only accept self-signed certs
    config.acceptOnlySelfSignedServerCertificate = true; <.>

    // end::p2p-act-rep-config-self-cert[]
    // tag::p2p-act-rep-config-pinnedcert[]
    // Return the remote pinned cert (the listener's cert)
    config.pinnedServerCertificate = thisCert; // Get listener cert if pinned

    // end::p2p-act-rep-config-pinnedcert[]
    // Configure Client Security // <.>
    // tag::p2p-act-rep-auth[]
    //  Set Authentication Mode
    let thisAuthenticator = BasicAuthenticator(username: validUser, password: validPassword)
    config.authenticator = thisAuthenticator

    // end::p2p-act-rep-auth[]
    // end::p2p-act-rep-config-tls-full[]

    // tag::p2p-tlsid-tlsidentity-with-label[]
      // Check if Id exists in keychain and if so, use that Id
      if let thisIdentity =
        (try? TLSIdentity.identity(withLabel: "doco-sync-server")) ?? nil { // <.>
          print("An identity with label : doco-sync-server already exists in keychain")
          thisAuthenticator = ClientCertificateAuthenticator(identity: thisIdentity)  // <.>
          config.authenticator = thisAuthenticator
          }

      // end::p2p-tlsid-check-keychain[]
    // end::p2p-tlsid-tlsidentity-with-label[]
// END Additional p2p-avt-rep options




// tag::p2p-tlsid-manage-func[]
//
//  cMyGetCert.swift
//  doco-sync
//
//  Created by Ian Bridge on 20/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

import Foundation
import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity


class cMyGetCert1{

    let kListenerCertLabel = "doco-sync-server"
    let kListenerCertKeyP12File = "listener-cert-pkey"
    let kListenerPinnedCertFile = "listener-pinned-cert"
    let kListenerCertKeyExportPassword = "couchbase"
    //var importedItems : NSArray
    let thisData : CFData?
    var items : CFArray?

    func fMyGetCert() ->TLSIdentity? {
        var kcStatus = errSecSuccess // Zero
        let thisLabel : String? = "doco-sync-server"

        //var thisData : CFData?
    // tag::old-p2p-tlsid-tlsidentity-with-label[]
    // tag::p2p-tlsid-check-keychain[]
        // USE KEYCHAIN IDENTITY IF EXISTS
        // Check if Id exists in keychain. If so use that Id
        do {
            if let thisIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") {
                print("An identity with label : doco-sync-server already exists in keychain")
                return thisIdentity
                }
        } catch
          {return nil}
        // end::p2p-tlsid-check-keychain[]
        thisAuthenticator.ClientCertificateAuthenticator(identity: thisIdentity )
        config.thisAuthenticator
    // end::old-p2p-tlsid-tlsidentity-with-label[]


// tag::p2p-tlsid-check-bundled[]
// CREATE IDENTITY FROM BUNDLED RESOURCE IF FOUND

        // Check for a resource bundle with required label to generate identity from
        // return nil identify if not found
        guard let pathToCert = Bundle.main.path(forResource: "doco-sync-server", ofType: "p12"),
                let thisData = NSData(contentsOfFile: pathToCert)
            else
                {return nil}
// end::p2p-tlsid-check-bundled[]

// tag::p2p-tlsid-import-from-bundled[]
        // Use SecPKCS12Import to import the contents (identities and certificates)
        // of the required resource bundle (PKCS #12 formatted blob).
        //
        // Set passphrase using kSecImportExportPassphrase.
        // This passphrase should correspond to what was specified when .p12 file was created
        kcStatus = SecPKCS12Import(thisData as CFData, [String(kSecImportExportPassphrase): "couchbase"] as CFDictionary, &items)
            if kcStatus != errSecSuccess {
             print("failed to import data from provided with error :\(kcStatus) ")
             return nil
            }
        let importedItems = items! as NSArray
        let thisItem = importedItems[0] as! [String: Any]

        // Get SecIdentityRef representing the item's id
        let thisSecId = thisItem[String(kSecImportItemIdentity)]  as! SecIdentity

        // Get Id's Private Key, return nil id if fails
        var thisPrivateKey : SecKey?
        kcStatus = SecIdentityCopyPrivateKey(thisSecId, &thisPrivateKey)
            if kcStatus != errSecSuccess {
                print("failed to import private key from provided with error :\(kcStatus) ")
                return nil
            }

        // Get all relevant certs [SecCertificate] from the ID's cert chain using kSecImportItemCertChain
        let thisCertChain = thisItem[String(kSecImportItemCertChain)] as? [SecCertificate]

        // Return nil Id if errors in key or cert chain at this stage
        guard let pKey = thisPrivateKey, let pubCerts = thisCertChain else {
            return nil
        }
// end::p2p-tlsid-import-from-bundled[]

// tag::p2p-tlsid-store-in-keychain[]
// STORE THE IDENTITY AND ITS CERT CHAIN IN THE KEYCHAIN

        // Store Private Key in Keychain
        let params: [String : Any] = [
            String(kSecClass):          kSecClassKey,
            String(kSecAttrKeyType):    kSecAttrKeyTypeRSA,
            String(kSecAttrKeyClass):   kSecAttrKeyClassPrivate,
            String(kSecValueRef):       pKey
        ]
        kcStatus = SecItemAdd(params as CFDictionary, nil)
            if kcStatus != errSecSuccess {
                print("Unable to store private key")
                return nil
            }
       // Store all Certs for Id in Keychain:
       var i = 0;
       for cert in thisCertChain! {
            let params: [String : Any] = [
                String(kSecClass):      kSecClassCertificate,
                String(kSecValueRef):   cert,
                String(kSecAttrLabel):  "doco-sync-server"
                ]
            kcStatus = SecItemAdd(params as CFDictionary, nil)
                if kcStatus != errSecSuccess {
                    print("Unable to store certs")
                    return nil
                }
            i=i+1
        }
// end::p2p-tlsid-store-in-keychain[]

// tag::p2p-tlsid-return-id-from-keychain[]
// RETURN A TLSIDENTITY FROM THE KEYCHAIN FOR USE IN CONFIGURING TLS COMMUNICATION
do {
    return try TLSIdentity.identity(withIdentity: thisSecId, certs: [pubCerts[0]])
} catch {
    print("Error while loading self signed cert : \(error)")
    return nil
}
// end::p2p-tlsid-return-id-from-keychain[]
    } // fMyGetCert
} // cMyGetCert

// tag::p2p-tlsid-delete-id-from-keychain[]

try TLSIdentity.deleteIdentity(withLabel: serverCertLabel);

// end::p2p-tlsid-delete-id-from-keychain[]


// end::p2p-tlsid-manage-func[]
// tag::old-p2p-act-rep-config-self-cert[]
// acceptOnlySelfSignedServerCertificate = true -- accept Slf-Signed Certs
config.disableTLS = false
config.acceptOnlySelfSignedServerCertificate = true

// end::old-p2p-act-rep-config-self-cert[]

// tag::p2p-act-rep-config-cacert-pinned-func[]
func fMyCaCertPinned() {
  // do {
  let tgtUrl = URL(string: "wss://10.1.1.12:8092/actDb")!
  let targetEndpoint = URLEndpoint(url: tgtUrl)
  let actDb:Database?
  let config = ReplicatorConfiguration(database: actDb!, target: targetEndpoint)
  // tag::p2p-act-rep-config-cacert-pinned[]

  // Get bundled resource and read into localcert
  guard let pathToCert = Bundle.main.path(forResource: "listener-pinned-cert", ofType: "cer")
    else { /* process error */ }
  guard let localCertificate:NSData =
               NSData(contentsOfFile: pathToCert)
    else { /* process error */ }

  // Create certificate
  // using its DER representation as a CFData
  guard let pinnedCert = SecCertificateCreateWithData(nil, localCertificate)
    else { /* process error */ }

  // Add `pinnedCert` and `acceptOnlySelfSignedServerCertificate=false` to `ReplicatorConfiguration`
  config.acceptOnlySelfSignedServerCertificate = false
  config.pinnedServerCertificate = pinnedCert
  // end::p2p-act-rep-config-cacert-pinned[]
  // end::p2p-act-rep-config-cacert-pinned-func[]
}

    // optionally  listenerConfig.tlsIdentity = TLSIdentity(withIdentity:serverSelfCert-id)


        // tag::old-listener-config-client-root-ca[]
    // Configure the client authenticator to validate using ROOT CA <.>

    // end::old-listener-config-client-root-ca[]

    // For replications

// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
class MyClass {
    var database: Database?
    var replicator: Replicator? // <1>

    func startReplicator() {
        let url = URL(string: "ws://localhost:4984/db")! // <2>
        let target = URLEndpoint(url: url)
        let config = ReplicatorConfiguration(database: database!, target: target)
        config.replicatorType = .pull

        self.replicator = Replicator(config: config)
        self.replicator?.start()
    }
}

// end::sgw-repl-pull[]

// tag::sgw-repl-pull-callouts[]

<.> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<.> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
You should now use `ws:`, or `wss:` for SSL/TLS connections.


// end::sgw-repl-pull-callouts[]

    // tag::sgw-act-rep-initialize[]
    let tgtUrl = URL(string: "wss://10.1.1.12:8092/travel-sample")!
    let targetEndpoint = URLEndpoint(url: tgtUrl)
    var config = ReplicatorConfiguration(database: actDb!, target: targetEndpoint) // <.>

    // end::sgw-act-rep-initialize[]
