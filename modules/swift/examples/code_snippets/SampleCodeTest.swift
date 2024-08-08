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
    /**
     For consistency in code snippets:
     1. we will use `self.database`/ `database` for database, query, replicator-db related code snippets.
     2. we will use `self.otherDB` / `otherDB` for listener-db
     */

    var database: Database!
    var otherDB: Database!
    var collection: Collection!

    /**
     For consistency:
     1. we will use replicator with `self.replicator` and listener with `self.listener`
     */
    var replicator: Replicator!
    var listener: URLEndpointListener!

    var replicatorsToPeers = [String: Replicator]()
    var replicatorListenerTokens = [String: Any]()

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
            try self.database.close()
        }
        // end::close-database[]
    }

    func dontTestDatabaseFullSync() throws {
        // tag::database-fullsync[]
        var config = DatabaseConfiguration()
        // This enables full sync
        config.fullSync = true
        // end::database-fullsync[]
    }

    

    // helper
    func isValidCredentials(_ u: String, password: String) -> Bool { return true }
    func isValidCertificates(_ certs: [SecCertificate]) -> Bool { return true }


#if COUCHBASE_ENTERPRISE

    func dontTestDatabaseEncryption() throws {
        // tag::database-encryption[]
        var config = DatabaseConfiguration()
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::initializer[]
        let doc = MutableDocument()
            .setString("task", forKey: "type")
            .setString("todo", forKey: "owner")
            .setDate(Date(), forKey: "createdAt")
        try collection.save(document: doc)
        // end::initializer[]
    }

    func dontTestMutability() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        
        // tag::update-document[]
        guard let doc = try collection.document(id: "xyz") else { return }
        let mutableDocument = doc.toMutable()
        mutableDocument.setString("apples", forKey: "name")
        try collection.save(document: mutableDocument)
        // end::update-document[]
    }

    func dontTestDateGetter() throws {
        // tag::date-getter[]
        let mutableDoc = MutableDocument(id: "xyz")
        mutableDoc.setValue(Date(), forKey: "createdAt")
        
        guard let doc = try collection.document(id: "xyz") else { return }
        let date = doc.date(forKey: "createdAt")
        // end::date-getter[]
        print("\(date!)")
    }

    func dontTestToDictionary() throws {
        // tag::to-dictionary[]
        guard let doc = try collection.document(id: "xyz") else { return }
        print(doc.toDictionary())
        // end::to-dictionary[]
    }
    
    func dontTestToJSON() throws {
        // tag::to-json[]
        guard let doc = try collection.document(id: "xyz") else { return }
        print(doc.toJSON())
        // end::to-json[]
    }

    func dontTestBatchOperations() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        
        // tag::batch[]
        do {
            try database.inBatch {
                for i in 0...10 {
                    let doc = MutableDocument()
                    doc.setValue("user", forKey: "type")
                    doc.setValue("user \(i)", forKey: "name")
                    doc.setBoolean(false, forKey: "admin")
                    try collection.save(document: doc)
                    print("saved user document \(doc.string(forKey: "name")!)")
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
        // end::batch[]
    }

    func dontTestChangeListener() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        
        // tag::document-listener[]
        weak var wCollection = collection
        let token = collection.addDocumentChangeListener(id: "user.john") { (change) in
            if let doc = try? wCollection?.document(id: change.documentID) {
                print("Status :: \(doc?.string(forKey: "verified_account") ?? "--")")
            }
        }
        // end::document-listener[]
        token.remove()
    }

    func dontTestDocumentExpiration() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        
        // tag::document-expiration[]
        // Purge the document one day from now
        let ttl = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        try collection.setDocumentExpiration(id: "doc123", expiration: ttl)

        // Reset expiration
        try collection.setDocumentExpiration(id: "doc1", expiration: nil)

        // Query documents that will be expired in less than five minutes
        let fiveMinutesFromNow = Date(timeIntervalSinceNow: 60 * 5).timeIntervalSince1970
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        
        let newTask = MutableDocument()
        var image: UIImage!

        // tag::blob[]
        let appleImage = UIImage(named: "avatar.jpg")!
        let imageData = UIImageJPEGRepresentation(appleImage, 1)! // <.>

        let blob = Blob(contentType: "image/jpeg", data: imageData) // <.>
        newTask.setBlob(blob, forKey: "avatar") // <.>
        try collection.save(document:newTask)

        if let taskBlob = newTask.blob(forKey: "image") {
            image = UIImage(data: taskBlob.content!)
        }
        // end::blob[]

        print("\(image)")
#endif
    }

    // MARK: Query

    func dontTestQueryGetAll() throws {
        // tag::query-get-all[]
        let collection = try self.database.createCollection(name: "hotel")
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.collection(collection))

        // end::query-get-all[]
        print(query)
    }

    func dontTestIndexing() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // N1QL and Querybuilder versions
        // tag::query-index[]
        let config = ValueIndexConfiguration(["type", "name"])
        try collection.createIndex(withName: "TypeNameIndex", config: config)
        // end::query-index[]

        // tag::query-index_Querybuilder[]
        let index = IndexBuilder.valueIndex(items: ValueIndexItem.expression(Expression.property("type")),
                                            ValueIndexItem.expression(Expression.property("name")))
        try collection.createIndex(index, name: "TypeNameIndex")
        // end::query-index_Querybuilder[]
    }

    func dontTestSelectMeta() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-select-meta[]
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))

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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-select-props[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("type"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(collection))

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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        var query: Query
        // tag::query-select-all[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
        // end::query-select-all[]

        // tag::live-query[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection)) // <.>

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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-where[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Meta.isDeleted)
        // end::query-deleted-documents[]
        print(query)
    }

    func dontTestCollectionOperatorContains() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-collection-operator-contains[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("public_likes")
            )
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))
                    .and(ArrayFunction.contains(Expression.property("public_likes"),
                                                value: Expression.string("Armani Langworth")))
            )

        do {
            for result in try query.execute() {
                print("public_likes :: \(result.array(forKey: "public_likes")!.toArray())")
            }
        }
        // end::query-collection-operator-contains[]
    }

    func dontTestCollectionOperatorIn() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-collection-operator-in[]
        let values = [
            Expression.property("first"),
            Expression.property("last"),
            Expression.property("username")
        ]

        let query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.string("Armani").in(values))
        // end::query-collection-operator-in[]

        print(query)
    }


    func dontTestLikeOperator() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-like-operator[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name"))
                            .like(Expression.string("royal engineers museum")))
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-like-operator-wildcard-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name"))
                            .like(Expression.string("eng%e%")))
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-like-operator-wildcard-character-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(collection))
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-regex-operator[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name")
            )
            .from(DataSource.collection(collection))
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
        guard let airlines = try self.database.collection(name: "airlines") else { return }
        guard let routes = try self.database.collection(name: "routes") else { return }
        let query = QueryBuilder
            .select(
                SelectResult.expression(Expression.property("name").from("airline")),
                SelectResult.expression(Expression.property("callsign").from("airline")),
                SelectResult.expression(Expression.property("destinationairport").from("route")),
                SelectResult.expression(Expression.property("stops").from("route")),
                SelectResult.expression(Expression.property("airline").from("route"))
            )
            .from(
                DataSource.collection(airlines).as("airline")
            )
            .join(
                Join.join(DataSource.collection(routes).as("route"))
                    .on(
                        Meta.id.from("airline")
                            .equalTo(Expression.property("airlineid").from("route"))
                    )
            )
            .where(
                Expression.property("type").from("route").equalTo(Expression.string("route"))
                    .and(Expression.property("type").from("airline")
                            .equalTo(Expression.string("airline")))
                    .and(Expression.property("sourceairport").from("route")
                            .equalTo(Expression.string("RIX")))
            )
        // end::query-join[]

        do {
            for result in try query.execute() {
                print("name property :: \(result.string(forKey: "name")!)")
            }
        }
    }

    func dontTestGroupBy() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-groupby[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Function.count(Expression.all())),
                SelectResult.property("country"),
                SelectResult.property("tz"))
            .from(DataSource.collection(collection))
            .where(
                Expression.property("type").equalTo(Expression.string("airport"))
                    .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.int(300)))
            ).groupBy(
                Expression.property("country"),
                Expression.property("tz")
            )

        do {
            for result in try query.execute() {
                print("""
                    There are \(result.int(forKey: "$1")) airports on
                                the \(result.string(forKey: "tz")!)timezone located
                                in \(result.string(forKey: "country")!) and above 300 ft
                """)
            }
        }
        // end::query-groupby[]
    }

    func dontTestOrderBy() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-orderby[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("title"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.property("title").ascending())
            .limit(Expression.int(10))
        // end::query-orderby[]

        print("\(query)")
    }

    func dontTestExplainAll() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-explain-all[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("university")))
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").ascending())  // <.>

        print(try query.explain()) // <.>
        // end::query-explain-all[]
    }

    func dontTestExplainLike() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-explain-like[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").like(Expression.string("%hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));

        print(try query.explain())

        // end::query-explain-like[]
    }

    func dontTestExplainNoOp() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-explain-nopfx[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));

        print(try query.explain());

        // end::query-explain-nopfx[]
    }

    func dontTestExplainFunction() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-explain-function[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))) // <.>

        print(try query.explain());

        // end::query-explain-function[]
    }

    func dontTestExplainNoFunction() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-explain-nofunction[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(
                Expression.property("type").equalTo(Expression.string("hotel"))); // <.>

        print(try query.explain());

        // end::query-explain-nofunction[]
    }


    func dontTestCreateFullTextIndex() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::fts-build-content[]
        // Insert documents
        let overviews = ["Handy for the nice beaches in Southport", "Close to Turnpike.", "By Michigan football's Big House"]
        for overview in overviews {
            let doc = MutableDocument()
            doc.setString("overview", forKey: "type")
            doc.setString(overview, forKey: "overview")
            try collection.save(document:doc)
        }
        // end::fts-build-content[]

        // tag::fts-index[]
        // Create index with N1QL
        do {
            let index = FullTextIndexConfiguration(["overview"])
            try collection.createIndex(withName: "overviewFTSIndex", config: index)
        } catch let error {
            print(error.localizedDescription)
        }
        // end::fts-index[]
    }

    func dontTestCreateFullTextIndex_Querybuilder() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::fts-index_Querybuilder[]
        // Create index with Querybuilder
        let index = IndexBuilder.fullTextIndex(items: FullTextIndexItem.property("overview")).ignoreAccents(false)
        try collection.createIndex(index, name: "overviewFTSIndex")
        // end::fts-index_Querybuilder[]
    }


    func dontTestFullTextSearch() throws {
        // tag::fts-query[]

        let ftsStr = "SELECT Meta().id FROM _ WHERE MATCH(overviewFTSIndex, 'Michigan') ORDER BY RANK(overviewFTSIndex)"

        let query = try database.createQuery(ftsStr)

        let rs = try query.execute()
        for result in rs {
            print("document id \(result.string(at: 0)!)")
        }

        // end::fts-query[]
    }



    func dontTestFullTextSearch_Querybuilder() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::fts-query_Querybuilder[]
        let whereClause = FullTextFunction.match(Expression.fullTextIndex("overviewFTSIndex"), query: "'michigan'")
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(whereClause)
        for result in try query.execute() {
            print("document id \(result.string(at: 0)!)")
        }
        // end::fts-query_Querybuilder[]
    }


    // MARK: toJSON

    func dontTestToJsonArrayObject() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // demonstrate use of JSON string
        // tag::tojson-array[]
        if let doc = try collection.document(id: "1000") {
            guard let array = doc.array(forKey: "list") else {
                return
            }

            let json = array.toJSON()
            print(json)
        }
        // end::tojson-array[]
    }

    func dontTestToJsonDictionary() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // demonstrate use of JSON string
        // tag::tojson-dictionary[]
        if let doc = try collection.document(id: "1000") {
            guard let dictionary = doc.dictionary(forKey: "dictionary") else {
                return
            }

            let json = dictionary.toJSON()
            print(json)
        }
        // end::tojson-dictionary[]
    }

    func dontTestToJsonDocument() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // demonstrate use of JSON string
        // tag::tojson-document[]
        if let doc = try collection.document(id: "doc-id") {
            let json = doc.toJSON()
            print(json)
        }
        // end::tojson-document[]
    }

    func dontTestQueryResultToJSON() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let query = QueryBuilder.select(SelectResult.all()).from(DataSource.collection(collection))

        // demonstrate use of JSON string
        // tag::tojson-result[]
        let resultSet = try query.execute()
        for result in resultSet {
            let json = result.toJSON()
            print(json)
            // end::tojson-result[]
        }
    }

    func dontTestBlobToJSON() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::tojson-blob[]
        // Get a document
        if let doc = try collection.document(id: "1000") {
            guard let blob = doc.blob(forKey: "avatar") else {
                return
            }

            let json = blob.toJSON()
            print(json)
        }
        // end::tojson-blob[]
    }

    func dontTestIsBlob() throws {
        let digest = ""

        // tag::[dictionary-isblob]
        if(Blob.isBlob(properties: [Blob.typeProperty: Blob.blobType,
                                    Blob.blobDigestProperty: digest])) { // <.>
            print("Yes! I am a blob");
        }
        // end::[dictionary-isblob]
    }
    // -- !!!

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

    func dontTestReplicationNetworkInterface() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::sgw-act-rep-network-interface[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
        config.networkInterface = "en0"

        // end::sgw-act-rep-network-interface[]
        self.replicator = Replicator(config: config)
        self.replicator.start()

    }

    func dontTestReplicationBasicAuthentication() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::basic-authentication[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
        config.authenticator = BasicAuthenticator(username: "john", password: "pass")

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::basic-authentication[]
    }

    func dontTestReplicationSessionAuthentication() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::session-authentication[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::replication-pendingdocuments[]

        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
        config.replicatorType = .push

        // tag::replication-push-pendingdocumentids[]
        self.replicator = Replicator(config: config)
        let myDocIDs = try self.replicator.pendingDocumentIds(collection: collection) // <.>

        // end::replication-push-pendingdocumentids[]
        if(!myDocIDs.isEmpty) {
            print("There are \(myDocIDs.count) documents pending")
            let thisID = myDocIDs.first!

            self.replicator.addChangeListener { (change) in
                print("Replicator activity level is \(change.status.activity)")
                // tag::replication-push-isdocumentpending[]
                do {
                    let isPending = try self.replicator.isDocumentPending(thisID, collection: collection)
                    if(!isPending) { // <.>
                        print("Doc ID \(thisID) now pushed")
                    }
                } catch {
                    print(error)
                }
                // end::replication-push-isdocumentpending[]
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        // tag::replication-custom-header[]
        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
        config.headers = ["CustomHeaderName": "Value"]
        // end::replication-custom-header[]
    }

    func dontTestReplicationChannels() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        // tag::replication-channels[]
        var config = ReplicatorConfiguration(target: target)
        var colConfig = CollectionConfiguration()
        colConfig.channels = ["channel_name"]
        config.addCollection(collection, config: colConfig)
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::replication-push-filter[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        var config = ReplicatorConfiguration(target: target)
        var colConfig = CollectionConfiguration()
        colConfig.pushFilter = { (document, flags) in // <1>
            if (document.string(forKey: "type") == "draft") {
                return false
            }
            return true
        }
        config.addCollection(collection, config: colConfig)

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-push-filter[]
    }

    func dontTestReplicationPullFilter() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::replication-pull-filter[]
        let url = URL(string: "ws://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        var config = ReplicatorConfiguration(target: target)
        var colConfig = CollectionConfiguration()
        colConfig.pullFilter = { (document, flags) in // <1>
            if (flags.contains(.deleted)) {
                return false
            }
            return true
        }
        config.addCollection(collection, config: colConfig)

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-pull-filter[]
    }

    //  Added 2/Feb/21 - Ian Bridge
    //  Changed for 3.0.0 - Ian Bridge 3/Mar/21
    func testCustomRetryConfig() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::replication-retry-config[]
        let target = URLEndpoint(url: URL(string: "ws://foo.couchbase.com/db")!)

        var config =  ReplicatorConfiguration(target: target)
        config.addCollection(collection)
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
        var config = ReplicatorConfiguration(target: targetDatabase)
        
        guard let collection1 = try database.collection(name: "collection1", scope: "scope1") else { return }
        config.addCollection(collection1)
        config.replicatorType = .push

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::database-replica[]

        try database2.delete()
    }
#endif

    func dontTestCertificatePinning() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::certificate-pinning[]
        let certURL = Bundle.main.url(forResource: "cert", withExtension: "cer")!
        let data = try! Data(contentsOf: certURL)
        let certificate = SecCertificateCreateWithData(nil, data as CFData)

        let url = URL(string: "wss://localhost:4985/db")!
        let target = URLEndpoint(url: url)

        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
        config.pinnedServerCertificate = certificate
        // end::certificate-pinning[]

        print("\(config)")
    }

    func dontTestGettingStarted() throws {
        // tag::getting-started[]
        // Get the database (and create it if it doesn’t exist).
        do {
            self.database = try Database(name: "mydb")
            let collection = try self.database.createCollection(name: "mycol", scope: "myscope")
        } catch {
            fatalError("Error opening database")
        }

        // Create a new document (i.e. a record) in the database.
        let mutableDoc = MutableDocument()
            .setFloat(2.0, forKey: "version")
            .setString("SDK", forKey: "type")

        // Save it to the database.
        do {
            try collection.save(document:mutableDoc)
        } catch {
            fatalError("Error saving document")
        }

        // Update a document.
        if let mutableDoc = try collection.document(id: mutableDoc.id)?.toMutable() {
            mutableDoc.setString("Swift", forKey: "language")
            do {
                try collection.save(document:mutableDoc)

                let document = try collection.document(id: mutableDoc.id)!
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
            .from(DataSource.collection(collection))
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
        var replConfig = ReplicatorConfiguration(target: targetEndpoint)
        replConfig.addCollection(collection)
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::register-model[]
        let model = ImageClassifierModel()
        Database.prediction.registerModel(model, withName: "ImageClassifier")
        // end::register-model[]

        // tag::predictive-query-value-index[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])
        let prediction = Function.prediction(model: "ImageClassifier", input: input)

        let index = IndexBuilder.valueIndex(items: ValueIndexItem.expression(prediction.property("label")))
        try collection.createIndex(index, name: "value-index-image-classifier")
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel(withName: "ImageClassifier")
        // end::unregister-model[]
    }

    func dontTestPredictiveIndex() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::predictive-query-predictive-index[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])

        let index = IndexBuilder.predictiveIndex(model: "ImageClassifier", input: input)
        try collection.createIndex(index, name: "predictive-index-image-classifier")
        // end::predictive-query-predictive-index[]
    }

    func dontTestPredictiveQuery() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::predictive-query[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])
        let prediction = Function.prediction(model: "ImageClassifier", input: input) // <1>

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
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
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::replication-conflict-resolver[]
        let url = URL(string: "wss://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        var config = ReplicatorConfiguration(target: target)
        var colConfig = CollectionConfiguration()
        colConfig.conflictResolver = LocalWinConflictResolver()
        config.addCollection(collection, config: colConfig)

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-conflict-resolver[]
    }

    func dontTestSaveWithConflictHandler() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::update-document-with-conflict-handler[]
        guard let document = try collection.document(id: "xyz") else { return }
        let mutableDocument = document.toMutable()
        mutableDocument.setString("apples", forKey: "name")
        let success = try collection.save(document:mutableDocument, conflictHandler: { (new, current) -> Bool in
            let currentDict = current!.toDictionary()
            let newDict = new.toDictionary()
            let result = newDict.merging(currentDict, uniquingKeysWith: { (first, _) in first })
            new.setData(result)
            return true
        })
        // end::update-document-with-conflict-handler[]
        print(success) // to avoid the warning to show up

    }

    func dontTestInitListener() throws {
        guard let otherCollection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::init-urllistener[]
        var config = URLEndpointListenerConfiguration(collections: [otherCollection])
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

    // MARK: -- URLEndpointListener
    func dontTestTLSIdentityCreate() throws {
        // tag::p2psync-act-tlsid-create[]
        try TLSIdentity.deleteIdentity(withLabel: "couchbaselite-server-cert-label");
        let attrs = [certAttrCommonName: "CBL-Server"]
        let identity = try TLSIdentity.createIdentity(forServer: true,
                                                      attributes: attrs,
                                                      expiration: nil,
                                                      label: "couchbaselite-server-cert-label")
        // end::p2psync-act-tlsid-create[]
        print(identity)
    }

    func dontTestDeleteIdentity() throws {
        // tag::p2psync-act-tlsid-delete[]
        try TLSIdentity.deleteIdentity(withLabel: "couchbaselite-client-cert-label")
        // end::p2psync-act-tlsid-delete[]
    }

    func dontTestImportTLSIdentity() throws {
        // tag::p2psync-act-tlsid-import[]

        let path = Bundle.main.path(forResource: "identity/client", ofType: "p12")
        let clientCertData = try NSData(contentsOfFile: path!, options: []) as Data
        let identity = try TLSIdentity.importIdentity(withData: clientCertData,
                                                      password: "123",
                                                      label: "couchbaselite-client-cert-label")
        // end::p2psync-act-tlsid-import[]
        print(identity)
    }

    // MARK: -- QUERY RESULT SET HANDLING EXAMPLES

    func donTestQuerySyntaxAll() throws {
        // tag::query-syntax-all[]
        let collection = try self.database.createCollection(name: "hotel")
        let query = QueryBuilder.select(SelectResult.all()).from(DataSource.collection(collection))

        // end::query-syntax-all[]

        print(query)
    }

    func dontTestQueryAccessAll() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let query = QueryBuilder.select(SelectResult.all()).from(DataSource.collection(collection))
        var hotels = [String: Any]()

        // tag::query-access-all[]
        let results = try query.execute()
        for row in results {
            let docsProps = row.dictionary(at: 0)! // <.>

            let docid = docsProps.string(forKey: "id")!
            let name = docsProps.string(forKey: "name")!
            let type = docsProps.string(forKey: "type")!
            let city = docsProps.string(forKey: "city")!

            print("\(docid): \(name), \(type), \(city)")
            let hotel = row.dictionary(at: 0)!  //<.>
            guard let hotelId = hotel.string(forKey: "id") else {
                continue
            }

            hotels[hotelId] = hotel
        }

        // end::query-access-all[]
    }



    func dontTestQueryAccessJSON() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let query = QueryBuilder.select(SelectResult.all()).from(DataSource.collection(collection))
        var hotels = [String:Hotel]()
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

        let results = try query.execute()
        for row in  results {

            // get the result into a JSON String
            let jsonString = row.toJSON()

            let thisJsonObj:Dictionary =
            try (JSONSerialization.jsonObject(
                with: jsonString.data(using: .utf8)!,
                options: .allowFragments)
                 as? [String: Any])!

            // Use Json Object to populate Native object
            // Use Codable class to unpack JSON data to native object
            var this_hotel: Hotel = try JSONDecoder().decode(Hotel.self, from: jsonString.data(using: .utf8)!) // <.>

            // ALTERNATIVELY unpack in steps
            this_hotel.id = thisJsonObj["id"] as! String
            this_hotel.name = thisJsonObj["name"] as? String
            this_hotel.type = thisJsonObj["type"] as? String
            this_hotel.city = thisJsonObj["city"] as? String
            hotels[this_hotel.id] = this_hotel

        } // end for

        // end::query-access-json[]
    }

    func dontTestQuerySyntaxProps() throws {
        // tag::query-syntax-props[]
        let collection = try self.database.createCollection(name: "hotel")
        
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"),
                    SelectResult.expression(Expression.property("id")),
                    SelectResult.expression(Expression.property("name")),
                    SelectResult.expression(Expression.property("city")),
                    SelectResult.expression(Expression.property("type")))
            .from(DataSource.collection(collection))

        // end::query-syntax-props[]
        print(query)
    }

    func dontTestQueryAccessProps () throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let query = QueryBuilder.select(SelectResult.all()).from(DataSource.collection(collection))
        var hotels = [String: Hotel]()

        // tag::query-access-props[]
        for result in try! query.execute() {
            let docID = result.string(forKey: "metaId")!
            print("processing doc: \(docID)")

            let id = result.string(forKey: "id")!
            var hotel = Hotel(id: id)
            hotel.name = result.string(forKey: "name")
            hotel.city = result.string(forKey: "city")
            hotel.type = result.string(forKey: "type")
            hotels[id] = hotel
        } // end for

        // end::query-access-props[]
    }// end func

    func dontTestQueryCount() throws {
        // tag::query-syntax-count-only[]
        let collection = try self.database.createCollection(name: "hotel")
        let query = QueryBuilder
            .select(SelectResult.expression(Function.count(Expression.all())).as("mycount"))
            .from (DataSource.collection(collection)).groupBy(Expression.property("type"))

        // end::query-syntax-count-only[]

        // tag::query-access-count-only[]
        for result in try query.execute() {
            let count = result.int(forKey: "mycount") // <.>
            print("There are ", count, " rows")
        }
        // end::query-access-count-only[]
    }

    func dontTestQueryId () throws {
        // tag::query-syntax-id[]
        let collection = try self.database.createCollection(name: "hotel")
        let query = QueryBuilder.select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.collection(collection))

        // end::query-syntax-id[]


        // tag::query-access-id[]
        let results = try query.execute()
        for result in results {

            print(result.toDictionary())

            let docId = result.string(forKey: "metaId")! // <.>
            print("Document Id is -- \(docId)")

            // Now you can get the document using the ID
            if let doc = try collection.document(id: docId) {
                let hotelId = doc.string(forKey: "id")!
                let name = doc.string(forKey: "name")!
                let city = doc.string(forKey: "city")!
                let type = doc.string(forKey: "type")!
                
                // ... process document properties as required
                print("Result properties are: \(hotelId), \(name), \(city), \(type)")
            }
        }
        // end::query-access-id[]
    }

    func query_pagination () throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        //tag::query-syntax-pagination[]
        let offset = 0;
        let limit = 20;
        //
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .limit(Expression.int(limit), offset: Expression.int(offset))

        // end::query-syntax-pagination[]
        print(query)
    }

    func dontTestQueryN1QL() throws {

        // tag::query-syntax-n1ql[]
        let database = try Database(name: "hotel")

        let query = try database.createQuery("SELECT META().id AS thisId FROM _ WHERE type = 'hotel'") // <.>

        let results: ResultSet = try query.execute()

        // end::query-syntax-n1ql[]

        print(results.allResults().count)
    }

    func dontTestQueryN1QLparams() throws {

        // tag::query-syntax-n1ql-params[]
        let database = try! Database(name: "hotel")

        let query = try database.createQuery("SELECT META().id AS thisId FROM _ WHERE type = $type") // <.>

        query.parameters = Parameters().setString("hotel", forName: "type") // <.>

        let results: ResultSet = try query.execute()

        // end::query-syntax-n1ql-params[]

        print(results.allResults().count)
    }

    func dontTestProcessResults(results: ResultSet) throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::query-access-n1ql[]
        // tag::query-process-results[]

        for row in results {
            print(row["thisId"].string!)

            let docsId = row["thisId"].string!

            // Now you can get the document using the ID
            if let doc = try collection.document(id: docsId) {
                
                let hotelId = doc.string(forKey: "id")!
                
                let name = doc.string(forKey: "name")!
                
                let city = doc.string(forKey: "city")!
                
                let type = doc.string(forKey: "type")!
                
                // ... process document properties as required
                print("Result properties are: \(hotelId), \(name), \(city), \(type)")
            }
        }
        // end::query-access-n1ql[]
        // end::query-process-results[]

    }

    // MARK: -- Listener

    func dontTestListenerSimple() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::listener-simple[]
        var config = URLEndpointListenerConfiguration(collections: [otherCollection]) // <.>
        config.authenticator = ListenerPasswordAuthenticator { username, password in
            return "valid.user" == username && "valid.password.string" == String(password)
        } // <.>

        let listener = URLEndpointListener(config: config) // <.>

        try listener.start()  // <.>

        // end::listener-simple[]
    }

    func dontTestListenerInitialize() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::listener-initialize[]

        // tag::listener-config-db[]
        var config = URLEndpointListenerConfiguration(collections: [otherCollection]) // <.>

        // end::listener-config-db[]
        // tag::listener-config-port[]
        /* optionally */ let wsPort: UInt16 = 55991
        /* optionally */ let wssPort: UInt16 = 55990
        config.port =  wssPort // <.>

        // end::listener-config-port[]
        // tag::listener-config-netw-iface[]
        config.networkInterface = "10.1.1.10"  // <.>

        // end::listener-config-netw-iface[]
        // tag::listener-config-delta-sync[]
        config.enableDeltaSync = true // <.>

        // end::listener-config-delta-sync[]
        // tag::listener-config-tls-enable[]
        config.disableTLS  = false // <.>

        // end::listener-config-tls-enable[]
        // tag::listener-config-tls-id-anon[]
        // Set the credentials the server presents the client
        // Use an anonymous self-signed cert
        config.tlsIdentity = nil // <.>

        // end::listener-config-tls-id-anon[]
        // tag::listener-config-client-auth-pwd[]
        // Configure how the client is to be authenticated
        // Here, use Basic Authentication
        config.authenticator = ListenerPasswordAuthenticator(authenticator: { uname, pword -> Bool in
            return self.isValidCredentials(uname, password: pword)
        }) // <.>

        // end::listener-config-client-auth-pwd[]

        // tag::listener-start[]
        // Initialize the listener
        self.listener = URLEndpointListener(config: config) // <.>
        if self.listener == nil {
            fatalError("ListenerError Not Initialized")
            // ... take appropriate actions
        }

        // Start the listener
        try self.listener.start() // <.>

        // end::listener-start[]
        // end::listener-initialize[]

        print(wsPort)
    }

    func dontTestReplicatorSimple() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::replicator-simple[]

        let tgtUrl = URL(string: "wss://10.1.1.12:8092/otherDB")!
        let targetEndpoint = URLEndpoint(url: tgtUrl) //  <.>

        var thisConfig = ReplicatorConfiguration(target: targetEndpoint) // <.>
        thisConfig.addCollection(collection)
        
        thisConfig.acceptOnlySelfSignedServerCertificate = true // <.>

        let thisAuthenticator = BasicAuthenticator(username: "valid.user", password: "valid.password.string")
        thisConfig.authenticator = thisAuthenticator // <.>

        self.replicator = Replicator(config: thisConfig) // <.>

        self.replicator.start(); // <.>

        // end::replicator-simple[]
    }


    // MARK: Append

    func dontTestGetURLList() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::listener-get-url-list[]
        let config = URLEndpointListenerConfiguration(collections: [otherCollection])
        let listener = URLEndpointListener(config: config)
        try listener.start()

        if let urls = listener.urls {
            print("URLs are: \(urls)")
        }

        // end::listener-get-url-list[]
    }


    func dontTestListenerConfigDisableTLSUpdate() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        var config = URLEndpointListenerConfiguration(collections: [otherCollection])
        // tag::listener-config-tls-full-enable[]
        config.disableTLS  = false // <.>

        // end::listener-config-tls-full-enable[]
        // tag::listener-config-tls-disable[]
        config.disableTLS  = true // <.>

        // end::listener-config-tls-disable[]
    }

    func dontTestListenerConfigTLSIdentity() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        var config = URLEndpointListenerConfiguration(collections: [otherCollection])

        // tag::listener-config-tls-id-full[]
        // tag::listener-config-tls-id-caCert[]
        guard let path = Bundle.main.path(forResource: "cert", ofType: "p12") else {
            /* process error */ return
        }

        guard let certData = try? NSData(contentsOfFile: path) as Data else {
            /* process error */ return
        } // <.>

        let tlsIdentity = try TLSIdentity.importIdentity(withData: certData,
                                                         password: "123",
                                                         label: "Server-Cert-Label") // <.>

        // end::listener-config-tls-id-caCert[]
        // tag::listener-config-tls-id-SelfSigned[]
        let attrs = [certAttrCommonName: "Couchbase Inc"] // <.>

        let identity = try TLSIdentity.createIdentity(forServer: true, /* isServer */
                                                      attributes: attrs,
                                                      expiration: Date().addingTimeInterval(86400),
                                                      label: "Server-Cert-Label") // <.>

        // end::listener-config-tls-id-SelfSigned[]
        // tag::listener-config-tls-id-full-set[]
        // Set the credentials the server presents the client
        config.tlsIdentity = tlsIdentity    // <.>

        // end::listener-config-tls-id-full-set[]
        // end::listener-config-tls-id-full[]

        print("To avoid waring: \(identity)")
    }

    func dontTestListenerConfigClientRootCA() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        var config = URLEndpointListenerConfiguration(collections: [otherCollection])
        let cert = self.listener.tlsIdentity!.certs[0]

        // tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Authenticate using Cert Authority

        // cert is a pre-populated object of type:SecCertificate representing a certificate
        let rootCertData = SecCertificateCopyData(cert) as Data // <.>
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)! //

        config.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert]) // <.> <.>

        // end::listener-config-client-auth-root[]
        // end::listener-config-client-root-ca[]
    }

    func dontTestClientAuthLambda() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        var config = URLEndpointListenerConfiguration(collections: [otherCollection])

        // tag::listener-config-client-auth-lambda[]
        // tag::listener-config-client-auth-self-signed[]
        // Authenticate self-signed cert using application logic

        config.authenticator = ListenerCertificateAuthenticator { certs -> Bool in // <.>
            // Validate the cert
            return self.isValidCertificates(certs)
        } // <.>

        // end::listener-config-client-auth-self-signed[]
        // end::listener-config-client-auth-lambda[]
    }

    func dontTestListenerConfigUpdate() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        var config = URLEndpointListenerConfiguration(collections: [otherCollection])
        let cert = self.listener.tlsIdentity!.certs[0]

        // tag::old-listener-config-tls-id-nil[]
        config.tlsIdentity = nil

        // end::old-listener-config-tls-id-nil[]
        // tag::old-listener-config-delta-sync[]
        config.enableDeltaSync = true

        // end::old-listener-config-delta-sync[]
        // tag::listener-status-check[]
        let totalConnections = self.listener.status.connectionCount
        let activeConnections = self.listener.status.activeConnectionCount

        // end::listener-status-check[]
        // tag::listener-stop[]
        self.listener.stop()

        // end::listener-stop[]
        // tag::old-listener-config-client-auth-root[]
        // cert is a pre-populated object of type:SecCertificate representing a certificate
        let rootCertData = SecCertificateCopyData(cert) as Data
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!

        config.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

        // end::old-listener-config-client-auth-root[]
        // tag::old-listener-config-client-auth-self-signed[]
        config.authenticator = ListenerCertificateAuthenticator { self.isValidCertificates($0) }
        // end::old-listener-config-client-auth-self-signed[]

        print("to avoid warnings: \(activeConnections)/\(totalConnections) ")
    }

    func dontTestURLEndpointListenerConstructor() throws {
        guard let otherCollection = try self.otherDB.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let enableTLS = Bool.random()
        let wssPort: UInt16 = 4985
        let wsPort: UInt16 = 4984
        let auth = ListenerPasswordAuthenticator { self.isValidCredentials($0, password: $1)}

        // tag::p2p-ws-api-urlendpointlistener-constructor[]
        var config = URLEndpointListenerConfiguration.init(collections: [otherCollection])
        config.port = enableTLS ? wssPort : wsPort
        config.disableTLS = !enableTLS
        config.authenticator = auth
        self.listener = URLEndpointListener.init(config: config) // <1>
        // end::p2p-ws-api-urlendpointlistener-constructor[]
    }
    
    func dontTestManageCollection() throws {
        guard let database = self.database else { return }
        
        // tag::scopes-manage-create-collection[]
        let collection = try database.createCollection(name: "myCollectionName", scope: "myScopeName")
        // end::scopes-manage-create-collection[]
        
        // tag::scopes-manage-index-collection[]
        let config = FullTextIndexConfiguration(["overview"])
        try collection.createIndex(withName: "overviewFTSIndex", config: config)
        // end::scopes-manage-index-collection[]
        
        // tag::scopes-manage-list[]
        let scopes = try database.scopes()
        let collections = try database.collections(scope: "myScopeName")
        print("I have \(scopes.count) scopes and \(collections.count) collections")
        // end::scopes-manage-list[]
        
        // tag::scopes-manage-drop-collection[]
        try database.deleteCollection(name: "myCollectionName", scope: "myScopeName")
        // end::scopes-manage-drop-collection[]
    }
    
    // MARK: --

    func fMyActPeer() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        // tag::p2p-act-rep-func[]

        // tag::p2p-act-rep-initialize[]
        guard let targetURL = URL(string: "wss://10.1.1.12:8092/otherDB") else {
            fatalError("Invalid URL")
        }
        let targetEndpoint = URLEndpoint(url: targetURL)
        var config = ReplicatorConfiguration(target: targetEndpoint) // <.>
        config.addCollection(collection)

        // end::p2p-act-rep-initialize[]
        // tag::p2p-act-rep-config[]
        // tag::p2p-act-rep-config-type[]
        config.replicatorType = .pushAndPull

        // end::p2p-act-rep-config-type[]
        // tag::autopurge-override[]
        // set auto-purge behavior (here we override default)
        config.enableAutoPurge = false // <.>

        // end::autopurge-override[]
        // tag::p2p-act-rep-config-cont[]
        // Configure Sync Mode
        config.continuous = true

        // end::p2p-act-rep-config-cont[]
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Security -- only accept self-signed certs
        config.acceptOnlySelfSignedServerCertificate = true; // <.>

        // end::p2p-act-rep-config-self-cert[]
        // Configure Client Security // <.>
        // tag::p2p-act-rep-auth[]
        //  Set Authentication Mode
        config.authenticator = BasicAuthenticator(username: "cbl-user-01",
                                                  password: "secret")

        // end::p2p-act-rep-auth[]
        // tag::p2p-act-rep-config-conflict[]
        /* Optionally set custom conflict resolver call back
         config.conflictResolver = LocalWinConflictResolver()  // <.>
         */

        // end::p2p-act-rep-config-conflict[]
        // end::p2p-act-rep-config[]
        // tag::p2p-act-rep-start-full[]
        // Apply configuration settings to the replicator
        self.replicator = Replicator.init( config: config) // <.>

        // tag::p2p-act-rep-add-change-listener[]
        // Optionally add a change listener
        // Retain token for use in deletion
        let token = self.replicator.addChangeListener { change in // <.>
            if change.status.activity == .stopped {
                print("Replication stopped")
            } else {
                // tag::p2p-act-rep-status[]
                print("Replicator is currently : \(self.replicator.status.activity)")
            }
        }
        // end::p2p-act-rep-status[]
        // end::p2p-act-rep-add-change-listener[]

        // tag::p2p-act-rep-start[]
        // Run the replicator using the config settings
        self.replicator.start()  // <.>

        // end::p2p-act-rep-start[]
        // end::p2p-act-rep-start-full[]


        // end::p2p-act-rep-func[]
        self.replicator.removeChangeListener(withToken: token)
    }


    func dontTestReplicatorStop() {
        let token = self.replicator.addChangeListener { change in }
        // tag::p2p-act-rep-stop[]

        // Remove the change listener
        self.replicator.removeChangeListener(withToken: token)

        // Stop the replicator
        self.replicator.stop()

        // end::p2p-act-rep-stop[]
    }

    func dontTestAdditionalListenerConfigs() throws {
        guard let collection = try self.database.defaultCollection() else {
            fatalError("For sample code snippet, collection should be present!")
        }
        let target = DatabaseEndpoint(database: otherDB)
        var config = ReplicatorConfiguration(target: target)
        config.addCollection(collection)
        
        let cert = self.listener.tlsIdentity!.certs[0]
        let validUsername = "cbl-user-01"
        let validPassword = "secret"
        // tag::p2p-act-rep-config-tls-full[]
        // tag::p2p-act-rep-config-cacert[]
        // Configure Server Security -- only accept CA Certs
        config.acceptOnlySelfSignedServerCertificate = false // <.>

        // end::p2p-act-rep-config-cacert[]
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Security -- only accept self-signed certs
        config.acceptOnlySelfSignedServerCertificate = true // <.>

        // end::p2p-act-rep-config-self-cert[]
        // tag::p2p-act-rep-config-pinnedcert[]
        // Return the remote pinned cert (the listener's cert)
        config.pinnedServerCertificate = cert // Get listener cert if pinned

        // end::p2p-act-rep-config-pinnedcert[]
        // Configure Client Security // <.>
        // tag::p2p-act-rep-auth[]
        //  Set Authentication Mode
        config.authenticator = BasicAuthenticator(username: validUsername, password: validPassword)

        // end::p2p-act-rep-auth[]
        // end::p2p-act-rep-config-tls-full[]

        // tag::p2p-tlsid-tlsidentity-with-label[]
        // Check if Id exists in keychain and if so, use that Id
        if let tlsIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") { // <.>
            print("An identity with label : doco-sync-server already exists in keychain")
            config.authenticator = ClientCertificateAuthenticator(identity: tlsIdentity) // <.>
        }

        // end::p2p-tlsid-check-keychain[]
        // end::p2p-tlsid-tlsidentity-with-label[]
    }

    // tag::p2p-tlsid-manage-func[]
    func myGetCert() throws -> TLSIdentity? {
        var osStatus: OSStatus
        let target = DatabaseEndpoint(database: self.otherDB)
        var config = ReplicatorConfiguration(target: target)
        let defaultCollection = try self.database.defaultCollection()!
        config.addCollection(defaultCollection)

        //var thisData : CFData?
        // tag::p2p-tlsid-check-keychain[]
        // USE KEYCHAIN IDENTITY IF EXISTS
        // Check if Id exists in keychain. If so use that Id
        if let tlsIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") {
            print("An identity with label : doco-sync-server already exists in keychain")
            return tlsIdentity
        }
        // end::p2p-tlsid-check-keychain[]

        // FIXME: since old-p2p-tlsid-tlsidentity-with-label[] is removed, this code is not under any tag?
        guard let tlsIdentity = try TLSIdentity.identity(withLabel: "doco-sync-server") else {
            return nil
        }
        config.authenticator = ClientCertificateAuthenticator(identity: tlsIdentity)

        // tag::p2p-tlsid-check-bundled[]
        // CREATE IDENTITY FROM BUNDLED RESOURCE IF FOUND

        // Check for a resource bundle with required label to generate identity from
        // return nil identify if not found
        guard let path = Bundle.main.path(forResource: "doco-sync-server", ofType: "p12"),
              let certData = NSData(contentsOfFile: path)
        else {
            return nil
        }
        // end::p2p-tlsid-check-bundled[]

        // tag::p2p-tlsid-import-from-bundled[]
        // Use SecPKCS12Import to import the contents (identities and certificates)
        // of the required resource bundle (PKCS #12 formatted blob).
        //
        // Set passphrase using kSecImportExportPassphrase.
        // This passphrase should correspond to what was specified when .p12 file was created
        var result : CFArray?
        osStatus = SecPKCS12Import(certData as CFData, [String(kSecImportExportPassphrase): "couchbase"] as CFDictionary, &result)
        if osStatus != errSecSuccess {
            print("Failed to import data from provided with error :\(osStatus) ")
            return nil
        }
        let importedItems = result! as NSArray
        let item = importedItems[0] as! [String: Any]

        // Get SecIdentityRef representing the item's id
        let secIdentity = item[String(kSecImportItemIdentity)]  as! SecIdentity

        // Get Id's Private Key, return nil id if fails
        var privateKey : SecKey?
        osStatus = SecIdentityCopyPrivateKey(secIdentity, &privateKey)
        if osStatus != errSecSuccess {
            print("Failed to import private key from provided with error :\(osStatus) ")
            return nil
        }

        // Get all relevant certs [SecCertificate] from the ID's cert chain using kSecImportItemCertChain
        let certChain = item[String(kSecImportItemCertChain)] as? [SecCertificate]


        // Return nil, if errors in key, certChain at this stage
        guard let privateKey = privateKey, let certChain = certChain else {
            return nil
        }
        // end::p2p-tlsid-import-from-bundled[]

        // tag::p2p-tlsid-store-in-keychain[]
        // STORE THE IDENTITY AND ITS CERT CHAIN IN THE KEYCHAIN
#if os(iOS)
        // For iOS, need to save the identity into the KeyChain.
        // Save or Update identity with a label so that it could be cleaned up easily
        // Store Private Key in Keychain
        let params: [String : Any] = [
            String(kSecClass):          kSecClassKey,
            String(kSecAttrKeyType):    kSecAttrKeyTypeRSA,
            String(kSecAttrKeyClass):   kSecAttrKeyClassPrivate,
            String(kSecValueRef):       privateKey
        ]
        osStatus = SecItemAdd(params as CFDictionary, nil)
        if osStatus != errSecSuccess {
            print("Unable to store private key")
            return nil
        }
        // Store all Certs for Id in Keychain:
        var i = 0;
        for cert in certChain {
            let params: [String : Any] = [
                String(kSecClass):      kSecClassCertificate,
                String(kSecValueRef):   cert,
                String(kSecAttrLabel):  "doco-sync-server"
            ]
            osStatus = SecItemAdd(params as CFDictionary, nil)
            if osStatus != errSecSuccess {
                print("Unable to store certs")
                return nil
            }
            i=i+1
        }
#else
        let query: [String : Any] = [
            String(kSecClass):          kSecClassCertificate,
            String(kSecValueRef):       certs[0]
        ]

        let update: [String: Any] = [
            String(kSecClass):          kSecClassCertificate,
            String(kSecValueRef):       certs[0],
            String(kSecAttrLabel):      label
        ]

        osStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if osStatus != errSecSuccess {
            print("Unable to update certs \(osStatus)")
            return nil
        }
#endif
        // end::p2p-tlsid-store-in-keychain[]

        // tag::p2p-tlsid-return-id-from-keychain[]

        // RETURN A TLSIDENTITY FROM THE KEYCHAIN FOR USE IN CONFIGURING TLS COMMUNICATION
        return try TLSIdentity.identity(withIdentity: secIdentity, certs: [certChain[1]])
        // end::p2p-tlsid-return-id-from-keychain[]
    }

    func dontTestDeleteIDFromKeychain() throws {
        // tag::p2p-tlsid-delete-id-from-keychain[]

        try TLSIdentity.deleteIdentity(withLabel: "doco-sync-server")

        // end::p2p-tlsid-delete-id-from-keychain[]

    }

    // tag::p2p-act-rep-config-cacert-pinned-func[]
    func myCaCertPinned() throws {
        let targetURL = URL(string: "wss://10.1.1.12:8092/otherDB")!
        let targetEndpoint = URLEndpoint(url: targetURL)
        var config = ReplicatorConfiguration(target: targetEndpoint)
        let defaultCollection = try self.database.defaultCollection()!
        config.addCollection(defaultCollection)
        // tag::p2p-act-rep-config-cacert-pinned[]

        // Get bundled resource and read into localcert
        guard
            let pathToCert = Bundle.main.path(forResource: "listener-pinned-cert", ofType: "cer"),
            let localCertificate:NSData = NSData(contentsOfFile: pathToCert)
        else { /* process error */ return }

        // Create certificate
        // using its DER representation as a CFData
        guard
            let pinnedCert = SecCertificateCreateWithData(nil, localCertificate)
        else { /* process error */  return }

        // Add `pinnedCert` and `acceptOnlySelfSignedServerCertificate=false`(by default)
        // to `ReplicatorConfiguration`
        config.pinnedServerCertificate = pinnedCert
        // end::p2p-act-rep-config-cacert-pinned[]
        // end::p2p-act-rep-config-cacert-pinned-func[]

    }

    func dontTestOldListenerConfigClientRootCA() throws {
        // tag::old-listener-config-client-root-ca[]
        // Configure the client authenticator to validate using ROOT CA <.>
        // end::old-listener-config-client-root-ca[]
    }

    // end::p2p-tlsid-manage-func[]

    // tag::replication-start-func[]
    enum PeerConnectionStatus: UInt8 {
        case stopped = 0;
        case offline
        case connecting
        case idle
        case busy
    }

    func dontTestReplicationStart(_ peer: String,
                                  peerDBName: String,
                                  user: String?,
                                  pass: String?,
                                  handler: @escaping (PeerConnectionStatus, Error?) -> Void) throws {
        
        guard let validUser = user, let validPassword = pass else {
            fatalError("UserCredentialsNotProvided")
            // ... take appropriate actions
        }

        // tag::replicator-start-func-config-init[]
        var replicator = self.replicatorsToPeers[peer]

        if replicator == nil {
            // Start replicator to connect to the URLListenerEndpoint
            guard let targetUrl = URL(string: "ws://\(peer)/\(peerDBName)") else {
                fatalError("URLInvalid")
                // ... take appropriate actions
            }

            var config = ReplicatorConfiguration.init(target: URLEndpoint.init(url:targetUrl)) //<1>
            config.addCollection(self.collection)
            // end::replicator-start-func-config-init[]

            // tag::replicator-start-func-config-more[]

            config.replicatorType = .pushAndPull // <2>
            config.continuous =  true // <3>

            // end::replicator-start-func-config-more[]

            // tag::replicator-start-func-config-auth[]
            config.authenticator = BasicAuthenticator(username: validUser, password: validPassword)
            // end::replicator-start-func-config-auth[]

            // tag::replicator-start-func-repl-init[]
            replicator = Replicator.init(config: config)
            self.replicatorsToPeers[peer] = replicator

            let token = registerForEventsForReplicator(replicator!, handler: handler)
            self.replicatorListenerTokens[peer] = token

            // end::replicator-start-func-repl-init[]
        }

        // tag::replicator-start-func-repl-start[]
        replicator?.start()
        // end::replicator-start-func-repl-start[]
    }
    // end::replication-start-func[]

    // tag::replicator-register-for-events[]
    func registerForEventsForReplicator(_ replicator: Replicator,
                                        handler: @escaping (PeerConnectionStatus, Error?) -> Void) -> ListenerToken {
        return replicator.addChangeListener { change in
            guard change.status.error == nil else {
                handler(.stopped, change.status.error)
                return
            }

            switch change.status.activity {
            case .connecting:
                print("Replicator Connecting to Peer")
            case .idle:
                print("Replicator in Idle state")
            case .busy:
                print("Replicator in busy state")
            case .offline:
                print("Replicator in offline state")
            case .stopped:
                print("Replicator is stopped")
            }

            let progress = change.status.progress
            if progress.completed == progress.total {
                print("All documents synced")
            }
            else {
                print("Documents \(progress.total - progress.completed) still pending sync")
            }

            if let customStatus = PeerConnectionStatus(rawValue: change.status.activity.rawValue) {
                handler(customStatus, nil)
            }
        }
    }
    // end::replicator-register-for-events[]

    func startListener() throws {
        
        var messageEndpointListener: MessageEndpointListener!

        // tag::listener[]
        let collection = try self.database.createCollection(name: "myCollection")
        let config = MessageEndpointListenerConfiguration(collections: [collection], protocolType: .messageStream)
        messageEndpointListener = MessageEndpointListener(config: config)
        // end::listener[]

        print(messageEndpointListener.connections.count)
    }
    
    func initialize() throws {
        guard let collection = try self.database.defaultCollection() else { return }
        
        // tag::sgw-act-rep-initialize[]
        let targetURL = URL(string: "wss://10.1.1.12:8092/travel-sample")!
        let targetEndpoint = URLEndpoint(url: targetURL)
        var config = ReplicatorConfiguration(target: targetEndpoint) // <.>
        config.addCollection(collection)

        // end::sgw-act-rep-initialize[]
    }
}

// tag::sgw-repl-pull[]
class MyClass {
    var database: Database!
    var collection: Collection!
    var replicator: Replicator! // <1>

    func startReplicator() {
        let url = URL(string: "ws://localhost:4984/db")! // <2>
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(target: target)
        config.addCollection(self.collection)
        config.replicatorType = .pull

        self.replicator = Replicator(config: config)
        self.replicator.start()
    }
}

// end::sgw-repl-pull[]

/*
 // tag::sgw-repl-pull-callouts[]

 <.> A replication is an asynchronous operation.
 To keep a reference to the `replicator` object, you can set it as an instance property.
 <.> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
 You should now use `ws:`, or `wss:` for SSL/TLS connections.


 // end::sgw-repl-pull-callouts[]



 */

// MARK: -- Conflict Resolver Helpers

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

// MARK: -- PredictiveModel Helpers

// tag::predictive-model[]
// `myMLModel` is a fake implementation
// this would be the implementation of the ml model you have chosen
class myMLModel {
    static func predictImage(data: Data) -> [String : AnyObject] { return [:] }
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

// MARK: Prediction Model
class TestPredictiveModel: PredictiveModel {

    class var name: String {
        return "Untitled"
    }

    var numberOfCalls = 0

    func predict(input: DictionaryObject) -> DictionaryObject? {
        numberOfCalls = numberOfCalls + 1
        return self.doPredict(input: input)
    }

    func doPredict(input: DictionaryObject) -> DictionaryObject? {
        return nil
    }

    func registerModel() {
        Database.prediction.registerModel(self, withName: type(of: self).name)
    }

    func unregisterModel() {
        Database.prediction.unregisterModel(withName: type(of: self).name)
    }

    func reset() {
        numberOfCalls = 0
    }
}

// MARK: -- Custom Logger

// tag::custom-logging[]
class LogTestLogger: Logger {

    // set the log level
    var level: LogLevel = .none

    // constructor for easiness
    init(_ level: LogLevel) {
        self.level = level
    }

    func log(level: LogLevel, domain: LogDomain, message: String) {
        // handle the message, for example piping it to
        // a third party framework
    }
}
// end::custom-logging[]

struct Hotel: Codable {
    var id: String
    var type: String?
    var name: String?
    var city: String?
}

#if os(macOS)
// tag::listener-get-network-interfaces[]
import SystemConfiguration
// . . .

class SomeClass {
    func SomeFunction() {
        for interface in SCNetworkInterfaceCopyAll() as! [SCNetworkInterface] {
            // do something with this `interface`
        }
    }

    // . . .
}

// end::listener-get-network-interfaces[]
#endif

// MARK -- P2p

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
class ActivePeer: MessageEndpointDelegate {

    init() throws {
        let id = ""
        let database = try Database(name: "dbname")
        

        // tag::message-endpoint[]
        let collection = try database.createCollection(name: "collectionName")

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        let messageEndpointTarget = MessageEndpoint(uid: "UID:123", target: id, protocolType: .messageStream, delegate: self)
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        var config = ReplicatorConfiguration(target: messageEndpointTarget)
        config.addCollection(collection)

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
        let data = message.toData()
        print(">> send \(data.count) bytes of data ")
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

    func startListener() throws {
        let database = try! Database(name: "mydb")
        // tag::listener[]
        let collection = try database.createCollection(name: "myCollection")
        let config = MessageEndpointListenerConfiguration(collections: [collection], protocolType: .messageStream)
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

public class Supporting_Datatypes
{

    func datatype_usage() throws {
        // tag::datatype_usage[]
        // tag::datatype_usage_createdb[]
        // Get the database (and create it if it doesn’t exist).
        let database = try Database(name: "hoteldb")
        let collection = try database.createCollection(name: "hotel")

        // end::datatype_usage_createdb[]
        // tag::datatype_usage_createdoc[]
        // Create your new document
        // The 'var' indicates this document instance can be mutated
        var mutableDoc = MutableDocument(id: "doc1")

        // end::datatype_usage_createdoc[]
        // tag::datatype_usage_mutdict[]
        // Create and populate mutable dictionary
        // Create a new mutable dictionary and populate some keys/values
        var address = MutableDictionaryObject()
        address.setString("1 Main st.", forKey: "street")
        address.setString("San Francisco", forKey: "city")
        address.setString("CA", forKey: "state")
        address.setString("USA", forKey: "country")
        address.setString("90210", forKey: "code")

        // end::datatype_usage_mutdict[]
        // tag::datatype_usage_mutarray[]
        // Create and populate mutable array
        var phones = MutableArrayObject()
        phones.addString("650-000-0000")
        phones.addString("650-000-0001")

        // end::datatype_usage_mutarray[]
        // tag::datatype_usage_populate[]
        // Initialize and populate the document

        // Add document type and hotel name as string
        mutableDoc.setString("hotel", forKey:"type")
        mutableDoc.setString("Hotel Java Mo", forKey:"name")

        // Add average room rate (float)
        mutableDoc.setFloat(121.75, forKey:"room_rate")

        // Add address (dictionary)
        mutableDoc.setDictionary(address, forKey: "address")

        // Add phone numbers(array)
        mutableDoc.setArray(phones, forKey:"phones")

        // end::datatype_usage_populate[]
        // tag::datatype_usage_persist[]
        try! collection.save(document:mutableDoc)

        // end::datatype_usage_persist[]
        // tag::datatype_usage_closedb[]
        do {
            try database.close()
        } catch {
            print(error)
        }

        // end::datatype_usage_closedb[]

        // end::datatype_usage[]

    } // end func datatype_usage()


    func datatype_dictionary() throws {

        let database = try Database(name: "mydb")
        guard let collection = try database.defaultCollection() else {
            return
        }

        // tag::datatype_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)
        guard let doc = try collection.document(id:"doc1") else { return }

        // Getting a dictionary from the document's properties
        guard let dict = doc.dictionary(forKey: "address") else { return }

        // Access a value with a key from the dictionary
        guard let street = dict.string(forKey: "street") else { return }

        // Iterate dictionary
        for key in dict.keys {
            print("Key \(key) = \(dict.value(forKey:key) ?? "--")")
        }

        // Create a mutable copy
        let mutableDict = dict.toMutable()
        // end::datatype_dictionary[]
        
        print("street \(street) dict \(mutableDict)")
    }

    func datatype_mutable_dictionary() throws {

        let database = try!Database(name: "mydb")
        guard let collection = try database.defaultCollection() else {
            return
        }

        // tag::datatype_mutable_dictionary[]
        // Create a new mutable dictionary and populate some keys/values
        let mutableDict = MutableDictionaryObject()
        mutableDict.setString("1 Main st.", forKey: "street")
        mutableDict.setString("San Francisco", forKey: "city")

        // Add the dictionary to a document's properties and save the document
        let mutableDoc = MutableDocument(id: "doc1")
        mutableDoc.setDictionary(mutableDict, forKey: "address")
        try! collection.save(document:mutableDoc)

        // end::datatype_mutable_dictionary[]
    }


    func datatype_array() throws {
        let database = try Database(name: "mydb")
        guard let collection = try database.defaultCollection() else {
            return
        }
        var phone = "--"

        // tag::datatype_array[]
        guard let doc = try collection.document(id:"doc1") else { return }

        // Getting a phones array from the document's properties
        guard let array = doc.array(forKey: "phones") else { return }

        // Access an array element by index
        if array.count >= 0, let val = array.string(at: 0) {
            phone = val
        }

        // Iterate dictionary
        for (index, element) in array.enumerated() {
            print("Index \(index) = \(element)")
        }

        // Create a mutable copy
        let mutableArray = array.toMutable()
        // end::datatype_array[]
        
        print("phone is \(phone). mutable array is \(mutableArray)")

    }

    func datatype_mutable_array() throws {
        let database = try!Database(name: "mydb")
        guard let collection = try database.defaultCollection() else {
            return
        }

        // tag::datatype_mutable_array[]
        // Create a new mutable array and populate data into the array
        var mutableArray = MutableArrayObject()
        mutableArray.addString("650-000-0000")
        mutableArray.addString("650-000-0001")

            // Set the array to document's properties and save the document
        let mutableDoc = MutableDocument(id: "doc1")
        mutableDoc.setArray(mutableArray, forKey:"phones")
        try collection.save(document:mutableDoc)
        // end::datatype_mutable_array[]
    }

} // end class supporting_datatypes
