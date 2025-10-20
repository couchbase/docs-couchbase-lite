//
//  SampleCodeTest.swift
//  code-snippets
//
//  Copyright © 2025 couchbase. All rights reserved.
//

import CouchbaseLiteSwift
import MultipeerConnectivity
import CoreML

// MARK: -- PredictiveModel Class

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

// MARK: -- Troubleshooting Page - Logging

    // tag::new-custom-logging[]
class TestLogSink: LogSinkProtocol {
    func writeLog(level: LogLevel, domain: LogDomain, message: String) {
        // handle the message, for example piping it to
        // a third party framewor
    }
    // end::new-custom-logging[]

    func dontTestLoggingApi() throws {
        //tag::console-logging-db[]
        LogSinks.console = ConsoleLogSink(level: .verbose, domains: .database)
        //end::console-logging-db[]
        
        // tag::new-console-logging[]
        LogSinks.console = ConsoleLogSink(level: .verbose, domains: .all)
        // end::new-console-logging[]

        // tag::new-file-logging[]
        let tempFolder = NSTemporaryDirectory().appending("cbllog")
        LogSinks.file = FileLogSink(level: .verbose, directory: tempFolder, usePlainText: false, maxKeptFiles: 12, maxFileSize: 524288)
        // end::new-file-logging[]

        // tag::set-new-custom-logging[]
        LogSinks.custom = CustomLogSink(level: .warning, logSink: TestLogSink())
        // end::set-new-custom-logging[]
    }
}

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

// MARK: -- Identify available network interfaces

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

// MARK: -- Query Hotel
struct Hotel: Codable {
    var id: String
    var type: String?
    var name: String?
    var city: String?
}

// MARK: -- !!!Snippets
class SampleCodeTest {
    /**
     For consistency in code snippets:
     1. we will use `self.database`
     2. we will use `self.collection`
     3. we will use `self.otherDB`
     4. we will use `self.otherCollection`
     */

    var database: Database!
    var collection: Collection!
    
    var otherDB: Database!
    var otherCollection: Collection!

    /**
     For consistency:
     1. we will use replicator with `self.replicator` and listener with `self.listener`
     */
    var replicator: Replicator!
    var listener: URLEndpointListener!

    var replicatorsToPeers = [String: Replicator]()
    var replicatorListenerTokens = [String: Any]()

    // MARK: -- Database page

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
        var config = DatabaseConfiguration()
        // tag::database-fullsync[]
        config.fullSync = true
        // end::database-fullsync[]
    }
    
    func dontTestManageCollection() throws {
        // tag::scopes-manage-create-collection[]
        let collection = try self.database.createCollection(name: "myCollectionName", scope: "myScopeName")
        // end::scopes-manage-create-collection[]

        // tag::scopes-manage-index-collection[]
        let config = FullTextIndexConfiguration(["overview"])
        try collection.createIndex(withName: "overviewFTSIndex", config: config)
        // end::scopes-manage-index-collection[]

        // tag::scopes-manage-list[]
        let scopes = try self.database.scopes()
        let collections = try self.database.collections(scope: "myScopeName")
        print("I have \(scopes.count) scopes and \(collections.count) collections")
        // end::scopes-manage-list[]

        // tag::scopes-manage-drop-collection[]
        try self.database.deleteCollection(name: "myCollectionName", scope: "myScopeName")
        // end::scopes-manage-drop-collection[]
    }

    func dontTestDatabaseEncryption() throws {
        // tag::database-encryption[]
        var config = DatabaseConfiguration()
        config.encryptionKey = EncryptionKey.password("secretpassword")

        self.database = try Database(name: "my-database", config: config)
        // end::database-encryption[]
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

    // MARK: -- Document page

    func dontTestInitializer() throws {
        // tag::initializer[]
        let doc = MutableDocument()
            .setString("task", forKey: "type")
            .setString("todo", forKey: "owner")
            .setDate(Date(), forKey: "createdAt")
        try collection.save(document: doc)
        // end::initializer[]
    }

    func dontTestMutability() throws {
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

    func dontTestBatchOperations() throws {
        // tag::batch[]
        do {
            try self.database.inBatch {
                for i in 0...10 {
                    let doc = MutableDocument()
                    doc.setValue("user", forKey: "type")
                    doc.setValue("user \(i)", forKey: "name")
                    doc.setBoolean(false, forKey: "admin")
                    try self.collection.save(document: doc)
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
        weak var wCollection = collection
        let token = collection.addDocumentChangeListener(id: "user.john") { (change) in
            if let doc = try? wCollection?.document(id: change.documentID) {
                print("Status :: \(doc?.string(forKey: "verified_account") ?? "--")")
            }
        }
        // end::document-listener[]
        
        print(token)
    }

    func dontTestDocumentExpiration() throws {
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
            .from(DataSource.collection(self.collection))
            .where(
                Meta.expiration.lessThan(
                    Expression.double(fiveMinutesFromNow)
                )
            )
        // end::document-expiration[]
        
        print(query)
    }
    
    func datatype_usage() throws {
        // tag::datatype_usage[]
        // tag::datatype_usage_createdb[]
        // Get the database (and create it if it doesn’t exist).
        let database = try Database(name: "hoteldb")
        let collection = try database.createCollection(name: "hotel")
        // end::datatype_usage_createdb[]
        
        // tag::datatype_usage_createdoc[]
        // Create your new document
        let mutableDoc = MutableDocument(id: "doc1")
        // end::datatype_usage_createdoc[]
        
        // tag::datatype_usage_mutdict[]
        // Create and populate mutable dictionary
        // Create a new mutable dictionary and populate some keys/values
        let address = MutableDictionaryObject()
        address.setString("1 Main st.", forKey: "street")
        address.setString("San Francisco", forKey: "city")
        address.setString("CA", forKey: "state")
        address.setString("USA", forKey: "country")
        address.setString("90210", forKey: "code")
        // end::datatype_usage_mutdict[]
        
        // tag::datatype_usage_mutarray[]
        // Create and populate mutable array
        let phones = MutableArrayObject()
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
    }

    func datatype_dictionary() throws {
        // tag::datatype_dictionary[]
        guard let doc = try self.collection.document(id:"doc1") else { return }

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
        // tag::datatype_mutable_dictionary[]
        // Create a new mutable dictionary and populate some keys/values
        let mutableDict = MutableDictionaryObject()
        mutableDict.setString("1 Main st.", forKey: "street")
        mutableDict.setString("San Francisco", forKey: "city")

        // Add the dictionary to a document's properties and save the document
        let mutableDoc = MutableDocument(id: "doc1")
        mutableDoc.setDictionary(mutableDict, forKey: "address")
        try self.collection.save(document:mutableDoc)
        // end::datatype_mutable_dictionary[]
    }

    func datatype_array() throws {
        // tag::datatype_array[]
        var phone = "--"
        guard let doc = try self.collection.document(id:"doc1") else { return }

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
        
        print(phone)
        print(mutableArray)
    }

    func datatype_mutable_array() throws {
        // tag::datatype_mutable_array[]
        // Create a new mutable array and populate data into the array
        let mutableArray = MutableArrayObject()
        mutableArray.addString("650-000-0000")
        mutableArray.addString("650-000-0001")

        // Set the array to document's properties and save the document
        let mutableDoc = MutableDocument(id: "doc1")
        mutableDoc.setArray(mutableArray, forKey:"phones")
        try self.collection.save(document:mutableDoc)
        // end::datatype_mutable_array[]
    }

#if os(iOS)
    func dontTestBlob() throws {
        // tag::blob[]
        let appleImage = UIImage(named: "avatar.jpg")!
        let imageData = appleImage.jpegData(compressionQuality: 1)! // <.>

        let newTask = MutableDocument()
        let blob = Blob(contentType: "image/jpeg", data: imageData) // <.>
        newTask.setBlob(blob, forKey: "avatar") // <.>
        try collection.save(document: newTask)

        var image: UIImage!
        if let taskBlob = newTask.blob(forKey: "image") {
            image = UIImage(data: taskBlob.content!)
        }
        // end::blob[]
        
        print(image)
    }
#endif
    
    // MARK: -- Query

    func dontTestIndexing() throws {
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

    func dontTestPartialValueIndex() throws {
        // tag::partial-value-index[]
        let config = ValueIndexConfiguration(["city"], where: "type = \"hotel\"")
        try collection.createIndex(withName: "HotelCityIndex", config: config)
        // end::partial-value-index[]
    }

    func dontTestPartialFTSIndex() throws {
        // tag::partial-full-text-index[]
        let config = FullTextIndexConfiguration(["description"], where: "type = \"hotel\"")
        try collection.createIndex(withName: "HotelDescIndex", config: config)
        // end::partial-full-text-index[]
    }

    func dontTestSelectProps() throws {
        // tag::query-select-props[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("type"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(self.collection))

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
            .from(DataSource.collection(self.collection))
        // end::query-select-all[]

        // tag::live-query[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection)) // <.>

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
        token.remove() // <.>
        // end::stop-live-query[]

        print("\(query)")
    }

    func dontTestWhere() throws {
        // tag::query-where[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection))
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
            .from(DataSource.collection(self.collection))
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
            .from(DataSource.collection(self.collection))
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
        // tag::query-collection-operator-in[]
        let properties = [
            Expression.property("first"),
            Expression.property("last"),
            Expression.property("username")
        ]

        let query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(self.collection))
            .where(Expression.string("Armani").in(properties))
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
            .from(DataSource.collection(self.collection))
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
        // tag::query-like-operator-wildcard-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(self.collection))
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
        // tag::query-like-operator-wildcard-character-match[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.collection(self.collection))
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
            .from(DataSource.collection(self.collection))
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
        // tag::query-groupby[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Function.count(Expression.all())),
                SelectResult.property("country"),
                SelectResult.property("tz"))
            .from(DataSource.collection(self.collection))
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
        // tag::query-orderby[]
        let query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("title"))
            .from(DataSource.collection(self.collection))
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
            .from(DataSource.collection(self.collection))
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
            .from(DataSource.collection(self.collection))
            .where(Expression.property("type").like(Expression.string("%hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));

        print(try query.explain())
        // end::query-explain-like[]
    }

    func dontTestExplainNoOp() throws {
        // tag::query-explain-nopfx[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection))
            .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));

        print(try query.explain());
        // end::query-explain-nopfx[]
    }

    func dontTestExplainFunction() throws {
        // tag::query-explain-function[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection))
            .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))) // <.>

        print(try query.explain());
        // end::query-explain-function[]
    }

    func dontTestExplainNoFunction() throws {
        // tag::query-explain-nofunction[]
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection))
            .where(
                Expression.property("type").equalTo(Expression.string("hotel"))); // <.>

        print(try query.explain());
        // end::query-explain-nofunction[]
    }

    func dontTestCreateFullTextIndex() throws {
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
        // tag::fts-index_Querybuilder[]
        // Create index with IndexBuilder
        let index = IndexBuilder.fullTextIndex(items: FullTextIndexItem.property("overview")).ignoreAccents(false)
        try collection.createIndex(index, name: "overviewFTSIndex")
        // end::fts-index_Querybuilder[]
    }

    func dontTestFullTextSearch() throws {
        // tag::fts-query[]
        let ftsStr = "SELECT Meta().id FROM _ WHERE MATCH(overviewFTSIndex, 'Michigan') ORDER BY RANK(overviewFTSIndex)"

        let query = try self.database.createQuery(ftsStr)

        let rs = try query.execute()
        for result in rs {
            print("document id \(result.string(at: 0)!)")
        }
        // end::fts-query[]
    }

    func dontTestFullTextSearch_Querybuilder() throws {
        // tag::fts-query_Querybuilder[]
        let whereClause = FullTextFunction.match(Expression.fullTextIndex("overviewFTSIndex"), query: "'michigan'")
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(self.collection))
            .where(whereClause)
        for result in try query.execute() {
            print("document id \(result.string(at: 0)!)")
        }
        // end::fts-query_Querybuilder[]
    }
    
    func dontTestPredictiveModel() throws {
        // tag::register-model[]
        let model = ImageClassifierModel()
        Database.prediction.registerModel(model, withName: "ImageClassifier")
        // end::register-model[]

        // tag::predictive-query-value-index[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])
        let prediction = Function.prediction(model: "ImageClassifier", input: input)

        let index = IndexBuilder.valueIndex(items: ValueIndexItem.expression(prediction.property("label")))
        try self.collection.createIndex(index, name: "value-index-image-classifier")
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel(withName: "ImageClassifier")
        // end::unregister-model[]
    }

    func dontTestPredictiveIndex() throws {
        // tag::predictive-query-predictive-index[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])

        let index = IndexBuilder.predictiveIndex(model: "ImageClassifier", input: input)
        try self.collection.createIndex(index, name: "predictive-index-image-classifier")
        // end::predictive-query-predictive-index[]
    }

    func dontTestPredictiveQuery() throws {
        // tag::predictive-query[]
        let input = Expression.dictionary(["photo": Expression.property("photo")])
        let prediction = Function.prediction(model: "ImageClassifier", input: input) // <1>

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection))
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
    
    func dontTestQuerySyntaxJson() throws {
        var hotels = [String: Any]()
        var results: ResultSet
        // tag::query-syntax-all[]
        let query = QueryBuilder.select(SelectResult.all()).from(DataSource.collection(self.collection))
        // end::query-syntax-all[]

        // tag::query-access-all[]
        results = try query.execute()
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

        results = try query.execute()
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
            var this_hotel: Hotel = try JSONDecoder().decode(Hotel.self, from:jsonString.data(using: .utf8)!) // <.>

            // ALTERNATIVELY unpack in steps
            this_hotel.id = thisJsonObj["id"] as! String
            this_hotel.name = thisJsonObj["name"] as? String
            this_hotel.type = thisJsonObj["type"] as? String
            this_hotel.city = thisJsonObj["city"] as? String
            hotels[this_hotel.id] = this_hotel
        }
        // end::query-access-json[]
    }

    func dontTestQuerySyntaxProps() throws {
        var hotels = [String: Hotel]()
        // tag::query-syntax-props[]
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"),
                    SelectResult.expression(Expression.property("id")),
                    SelectResult.expression(Expression.property("name")),
                    SelectResult.expression(Expression.property("city")),
                    SelectResult.expression(Expression.property("type")))
            .from(DataSource.collection(self.collection))
        // end::query-syntax-props[]
        
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
        }
        // end::query-access-props[]
    }

    func dontTestQueryCount() throws {
        // tag::query-syntax-count-only[]
        let query = QueryBuilder
            .select(SelectResult.expression(Function.count(Expression.all())).as("mycount"))
            .from (DataSource.collection(self.collection)).groupBy(Expression.property("type"))
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
            .from(DataSource.collection(self.collection))
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
        //tag::query-syntax-pagination[]
        let offset = 0;
        let limit = 20;
        
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(self.collection))
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

    // MARK: -- JSON
    
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

    func dontTestToJsonArrayObject() throws {
        // tag::tojson-array[]
        let doc = MutableDocument()
        let json = "[\"1000\",\"1001\",\"1002\",\"1003\"]"
        
        let initArray = try MutableArrayObject(json: json)

        let setArray = MutableArrayObject()
        try setArray.setJSON(json)
        // end::tojson-array[]
        
        print(doc, initArray)
    }

    func dontTestToJsonDictionary() throws {
        // demonstrate use of JSON string
        // tag::tojson-dictionary[]
        let json = """
        {
            "id": "1002",
            "type": "hotel",
            "name": "Hotel Ned",
            "city": "Balmain",
            "country": "Australia",
            "description": "Undefined description for Hotel Ned"
        }
        """
        // Create dictionary from JSON
        let initDictionary = try MutableDictionaryObject(json: json)
        
        // Create a new dictionary using JSON
        let setDictionary = MutableDictionaryObject()
        try setDictionary.setJSON(json)
        
        if let doc = try collection.document(id: "1002") {
            guard let dictionary = doc.dictionary(forKey: "dictionary") else {
                return
            }

            let json = dictionary.toJSON()
            print(json)
        }
        // end::tojson-dictionary[]
        
        print(initDictionary)
    }

    func dontTestToJsonDocument() throws {
        // tag::tojson-document[]
        if let doc = try collection.document(id: "doc-id") {
            let json = doc.toJSON()
            print(json)
        }
        // end::tojson-document[]
    }

    func dontTestBlobToJSON() throws {
        // tag::tojson-blob[]
        // Get a document
        if let doc = try collection.document(id: "1000") {
            guard let blob = doc.blob(forKey: "avatar") else {
                return
            }
            let json = blob.toJSON()
            print(json)
            
            let maybeBlob = doc.toDictionary()
            print(Blob.isBlob(properties: maybeBlob))
        }
        // end::tojson-blob[]
    }

    // MARK: -- Replication

    func dontTestEnableReplicatorLogging() throws {
        // tag::replication-logging[]
        // Verbose / Replicator
        LogSinks.console = ConsoleLogSink(level: .verbose, domains: .replicator)

        // Verbose / Network
        LogSinks.console = ConsoleLogSink(level: .verbose, domains: .network)
        // end::replication-logging[]
    }
    
    func dontTestReplicatorSimple() throws {
        // tag::replicator-simple[]
        let tgtUrl = URL(string: "wss://10.1.1.12:8092/otherDB")!
        let targetEndpoint = URLEndpoint(url: tgtUrl) //  <.>

        let colConfig = CollectionConfiguration(collection: self.collection)
        var replConfig = ReplicatorConfiguration(collections: [colConfig], target: targetEndpoint) // <.>

        replConfig.acceptOnlySelfSignedServerCertificate = true // <.>

        let authenticator = BasicAuthenticator(username: "valid.user", password: "valid.password.string")
        replConfig.authenticator = authenticator // <.>

        self.replicator = Replicator(config: replConfig) // <.>

        self.replicator.start(); // <.>
        // end::replicator-simple[]
    }
    
    // MARK: Data Sync page - Remote Sync Gateway

    func dontTestRemoteSyncGateway() throws {
        // tag::sgw-rep-func[]
        // tag::sgw-rep-configure-target[]
        // tag::sgw-rep-target
        let targetURL = URL(string: "wss://10.1.1.12:8092/travel-sample") // <.>
        let targetEndpoint = URLEndpoint(url: targetURL!)
        // end::sgw-rep-target
        let collConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [collConfig], target: targetEndpoint)
        // end::sgw-rep-configure-target[]
        
        // tag::sgw-rep-network-interface[]
        config.networkInterface = "en0"
        // end::sgw-rep-network-interface[]
        
        // tag::sgw-act-rep-config-type[]
        config.replicatorType = .pushAndPull
        // end::sgw-act-rep-config-type[]
        
        // tag::sgw-act-rep-config-cont[]
        // Configure Sync Mode
        config.continuous = true
        // end::sgw-act-rep-config-cont[]
        
        // tag::replication-retry-config[]
        config.heartbeat = 150 // <.>
        config.maxAttempts = 20 // <.>
        config.maxAttemptWaitTime = 600 // <.>
        // end::replication-retry-config[]
        
        // tag::sgw-rep-config-cacert[]
        // Only accept CA Certs
        config.acceptOnlySelfSignedServerCertificate = false // <.>
        // end::sgw-rep-config-cacert[]
        
        // tag::sgw-rep-config-self-cert[]
        // Only accept self-signed certs
        config.acceptOnlySelfSignedServerCertificate = true // <.>
        // end::sgw-rep-config-self-cert[]
        
        // tag::sgw-rep-config-cacert-pinned[]
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

        config.acceptOnlySelfSignedServerCertificate = false
        config.pinnedServerCertificate = pinnedCert
        // end::sgw-rep-config-cacert-pinned[]
        
        // tag::sgw-config-autopurge[]
        // Default is `true`
        config.enableAutoPurge = false // <.>
        // end::sgw-config-autopurge[]
        
        // tag::sgw-start-repl[]
        // Apply configuration settings
        replicator = Replicator(config: config) // <.>
        // Run the repliator with the applied config settings
        replicator.start() // <.>
        // end::sgw-start-repl[]
        // end::sgw-rep-func[]
    }

    func dontTestReplicationBasicAuthentication() throws {
        let target = URLEndpoint(url: URL(string: "ws://localhost:4984/mydatabase")!)
        
        // tag::basic-authentication[]
        let colConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [colConfig], target: target)
        config.authenticator = BasicAuthenticator(username: "john", password: "pass")
        // end::basic-authentication[]
    }

    func dontTestReplicationSessionAuthentication() throws {
        let target = URLEndpoint(url: URL(string: "ws://localhost:4984/mydatabase")!)
        // tag::session-authentication[]
        let colConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [colConfig], target: target)
        config.authenticator = SessionAuthenticator(sessionID: "904ac010862f37c8dd99015a33ab5a3565fd8447")
        // end::session-authentication[]
    }

    func dontTestReplicatorStatus() throws {
        // tag::replication-status[]
        replicator.addChangeListener { (change) in
            if change.status.activity == .stopped {
                print("Replication stopped")
            }
        }
        // end::replication-status[]
    }
    func dontTestReplicationPendingDocs() throws {
        let target = URLEndpoint(url: URL(string: "ws://localhost:4984/mydatabase")!)
        // tag::replication-pendingdocuments[]
        let colConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [colConfig], target: target)
        config.replicatorType = .push

        // tag::replication-push-pendingdocumentids[]
        replicator = Replicator(config: config)
        let myDocIDs = try replicator.pendingDocumentIds(collection: self.collection) // <.>
        // end::replication-push-pendingdocumentids[]
        if(!myDocIDs.isEmpty) {
            print("There are \(myDocIDs.count) documents pending")
            let thisID = myDocIDs.first!

            replicator.addChangeListener { [self] (change) in
                print("Replicator activity level is \(change.status.activity)")
                // tag::replication-push-isdocumentpending[]
                do {
                    let isPending = try replicator.isDocumentPending(thisID, collection: self.collection)
                    if(!isPending) { // <.>
                        print("Doc ID \(thisID) now pushed")
                    }
                } catch {
                    print(error)
                }
                // end::replication-push-isdocumentpending[]
            }
            replicator.start()
            // end::replication-pendingdocuments[]
        }
    }
    
    func dontTestReplicationCustomHeader() throws {
        let target = URLEndpoint(url: URL(string: "ws://localhost:4984/mydatabase")!)
        // tag::replication-custom-header[]
        let colConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [colConfig], target: target)
        config.headers = ["CustomHeaderName": "Value"]
        // end::replication-custom-header[]
    }
    
    func dontTestReplicationPushFilter() throws {
        // tag::replication-push-filter[]
        var colConfig = CollectionConfiguration(collection: self.collection)
        colConfig.pushFilter = { (document, flags) in // <1>
            if (document.string(forKey: "type") == "draft") {
                return false
            }
            return true
        }
        // end::replication-push-filter[]
    }

    func dontTestReplicationPullFilter() throws {
        // tag::replication-pull-filter[]
        var colConfig = CollectionConfiguration(collection: self.collection)
        colConfig.pullFilter = { (document, flags) in // <1>
            if (flags.contains(.deleted)) {
                return false
            }
            return true
        }
        // end::replication-pull-filter[]
    }
    
    func dontTestReplicationResetCheckpoint() throws {
        let doResetCheckpointRequired = Bool.random()
        // tag::replication-reset-checkpoint[]
        if doResetCheckpointRequired {
            replicator.start(reset: true)  // <.>
        } else {
            replicator.start()
        }
        // end::replication-reset-checkpoint[]
    }

    func dontTestReplicatorDocumentEvent() throws {
        // tag::add-document-replication-listener[]
        let token = replicator.addDocumentReplicationListener { (replication) in
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
        replicator.start()
        // end::add-document-replication-listener[]

        // tag::remove-document-replication-listener[]
        token.remove()
        // end::remove-document-replication-listener[]
    }

    func dontTestHandlingReplicationError() throws {
        // tag::replication-error-handling[]
        replicator.addChangeListener { (change) in
            if let error = change.status.error as NSError? {
                print("Error code :: \(error.code)")
            }
        }
        // end::replication-error-handling[]
    }

    // EE feature: code below might throw a compilation error
    // if it's compiled against CBL Swift Community.
    func dontTestDatabaseReplica() throws {
        let database2 = self.database!

        // tag::database-replica[]
        let targetDatabase = DatabaseEndpoint(database: database2)

        guard let collection1 = try self.database.collection(name: "collection1", scope: "scope1") else { return }
        
        let colConfig = CollectionConfiguration(collection: collection1)
        var config = ReplicatorConfiguration(collections: [colConfig], target: targetDatabase)
        config.replicatorType = .push

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::database-replica[]
    }

    func dontTestCertificatePinning() throws {
        // tag::certificate-pinning[]
        let certURL = Bundle.main.url(forResource: "cert", withExtension: "cer")!
        let data = try! Data(contentsOf: certURL)
        let certificate = SecCertificateCreateWithData(nil, data as CFData)

        let url = URL(string: "wss://localhost:4985/db")!
        let target = URLEndpoint(url: url)

        let colConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [colConfig], target: target)
        config.pinnedServerCertificate = certificate
        // end::certificate-pinning[]
    }
    
    // MARK: Data Sync Page - Pasive Peer

    func isValidCredentials(_ u: String, password: String) -> Bool { return true }
    func isValidCertificates(_ certs: [SecCertificate]) -> Bool { return true }

    func dontTestListenerSimple() throws {
        // tag::listener-simple[]
        var config = URLEndpointListenerConfiguration(collections: [self.otherCollection]) // <.>
        config.authenticator = ListenerPasswordAuthenticator { username, password in
            return "valid.user" == username && "valid.password.string" == String(password)
        } // <.>

        let listener = URLEndpointListener(config: config) // <.>

        try listener.start()  // <.>
        // end::listener-simple[]
    }

    func dontTestListenerInitialize() throws {
        // tag::listener-initialize[]
        // tag::listener-config-db[]
        var config = URLEndpointListenerConfiguration(collections: [self.otherCollection]) // <.>
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
            fatalError("ListenerError: Not Initialized")
            // ... take appropriate actions
        }

        // Start the listener
        try self.listener.start() // <.>
        // end::listener-start[]
        // end::listener-initialize[]

        // tag::listener-stop[]
        self.listener.stop()
        // end::listener-stop[]

        print(wsPort)
    }
    
    func dontTestListenerConfigTLSIdentity() throws {
        var config = URLEndpointListenerConfiguration(collections: [self.otherCollection])
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

        let identity = try TLSIdentity.createIdentity(for: .serverAuth,
                                                      attributes: attrs,
                                                      expiration: Date().addingTimeInterval(86400),
                                                      label: "Server-Cert-Label") // <.>

        // end::listener-config-tls-id-SelfSigned[]

        // tag::listener-config-tls-id-full-set[]
        // Set the credentials the server presents the client
        config.tlsIdentity = tlsIdentity    // <.>

        // end::listener-config-tls-id-full-set[]
        // end::listener-config-tls-id-full[]

        print(identity)
    }
    
    func dontTestListenerConfigClientRootCA() throws {
        var config = URLEndpointListenerConfiguration(collections: [self.otherCollection])
        let cert = self.listener.tlsIdentity!.certs[0]
        
        // tag::listener-config-client-auth-root[]
        // Authenticate using Cert Authority
        // cert is a pre-populated object of type:SecCertificate representing a certificate
        let rootCertData = SecCertificateCopyData(cert) as Data // <.>
        let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)! //

        config.authenticator = ListenerCertificateAuthenticator(rootCerts: [rootCert]) // <.> <.>
        // end::listener-config-client-auth-root[]
        
        // tag::listener-config-client-auth-lambda[]
        // Authenticate self-signed cert using application logic
        config.authenticator = ListenerCertificateAuthenticator { certs -> Bool in // <.>
            // Validate the cert
            return self.isValidCertificates(certs)
        } // <.> <.>
        // end::listener-config-client-auth-lambda[]
    }
    
    func dontTestDeleteIDFromKeychain() throws {
        // tag::p2p-tlsid-delete-id-from-keychain[]
        try TLSIdentity.deleteIdentity(withLabel: "alias")
        // end::p2p-tlsid-delete-id-from-keychain[]
    }
    
    func dontTestListenerStatus() throws {
        // tag::listener-status-check[]
        let totalConnections = self.listener.status.connectionCount
        let activeConnections = self.listener.status.activeConnectionCount
        // end::listener-status-check[]
        
        print(activeConnections, totalConnections)
    }
    
    // MARK: Data Sync page - Active Peer
    
    func dontTestActivePeer() throws {
        // tag::p2p-act-rep-func[]
        // tag::p2p-act-rep-target[]
        // Set listener DB endpoint
        let targetURL = URL(string: "wss://10.1.1.12:8092/otherDB")
        let targetEndpoint = URLEndpoint(url: targetURL!)
        
        var colConfig = CollectionConfiguration(collection: self.collection)
        // tag::p2p-act-rep-config-conflict[]
        colConfig.conflictResolver = LocalWinConflictResolver() // <.>
        // end::p2p-act-rep-config-conflict[]
        var config = ReplicatorConfiguration(collections: [colConfig], target: targetEndpoint)
        // end::p2p-act-rep-target[]
        
        // tag::p2p-act-rep-config-type[]
        config.replicatorType = .pushAndPull
        // end::p2p-act-rep-config-type[]

        // tag::p2p-act-rep-config-cont[]
        // Configure Sync Mode
        config.continuous = true
        // end::p2p-act-rep-config-cont[]
        
        // tag::p2p-act-rep-config-cacert[]
        // Only accept CA Certs
        config.acceptOnlySelfSignedServerCertificate = false // <.>
        // end::p2p-act-rep-config-cacert[]
        
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Security -- only accept self-signed certs
        config.acceptOnlySelfSignedServerCertificate = true // <.>
        // end::p2p-act-rep-config-self-cert[]
        
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

        config.acceptOnlySelfSignedServerCertificate = false
        config.pinnedServerCertificate = pinnedCert
        // end::p2p-act-rep-config-cacert-pinned[]
        
        // tag::p2p-act-rep-auth[]
        // Set Authentication Mode // <.>
        config.authenticator = BasicAuthenticator(username: "cbl-user-01",
                                                  password: "secret")
        // end::p2p-act-rep-auth[]

        // tag::p2p-act-rep-start-full[]
        // Apply configuration settings to the replicator
        self.replicator = Replicator(config: config) // <.>

        // tag::p2p-act-rep-add-change-listener[]
        // Optionally add a change listener
        // Retain token for use in deletion
        let token = self.replicator.addChangeListener { change in // <.>
            if change.status.activity == .stopped {
                print("Replication stopped")
            } else {
                print("Replicator is currently : \(self.replicator.status.activity)")
            }
        }
        // end::p2p-act-rep-add-change-listener[]
        
        // Run the replicator using the config settings
        self.replicator.start()  // <.>
        // end::p2p-act-rep-start-full[]
        // end::p2p-act-rep-func[]

        // tag::p2p-act-rep-stop[]
        replicator.stop()
        // end::p2p-act-rep-stop[]
        
        print(token)
    }
    
    func dontTestTLSIdentity() throws {
        let targetEndpoint = URLEndpoint(url: URL(string: "wss://10.1.1.12:8092/otherDB")!)
        let colConfig = CollectionConfiguration(collection: self.collection)
        var config = ReplicatorConfiguration(collections: [colConfig], target: targetEndpoint)
        // tag::p2p-tlsid-tlsidentity-with-label[]
        // Check if Id exists in keychain and if so, use that Id
        if let tlsIdentity = try TLSIdentity.identity(withLabel: "alias") { // <.>
            print("An identity with label: alias already exists in keychain")
            config.authenticator = ClientCertificateAuthenticator(identity: tlsIdentity) // <.>
        }
        // end::p2p-tlsid-tlsidentity-with-label[]
    }
    
    // MARK: -- Handling Data Conflicts page
    
    func dontTestReplicatorConflictResolver() throws {
        // tag::replication-conflict-resolver[]
        let url = URL(string: "wss://localhost:4984/mydatabase")!
        let target = URLEndpoint(url: url)

        var colConfig = CollectionConfiguration(collection: self.collection)
        colConfig.conflictResolver = LocalWinConflictResolver()
        let config = ReplicatorConfiguration(collections: [colConfig], target: target)

        self.replicator = Replicator(config: config)
        self.replicator.start()
        // end::replication-conflict-resolver[]
    }
    
    func dontTestSaveWithConflictHandler() throws {
        // tag::update-document-with-conflict-handler[]
        guard let document = try self.collection.document(id: "xyz") else { return }
        let mutableDocument = document.toMutable()
        mutableDocument.setString("apples", forKey: "name")
        let success = try self.collection.save(document:mutableDocument, conflictHandler: { (new, current) -> Bool in
            let currentDict = current!.toDictionary()
            let newDict = new.toDictionary()
            let result = newDict.merging(currentDict, uniquingKeysWith: { (first, _) in first })
            new.setData(result)
            return true
        })
        // end::update-document-with-conflict-handler[]
        print(success)
    }
}

// MARK: Data Sync page - Integrate Custom Listener

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
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
        let collConfig = CollectionConfiguration(collection: collection)
        let config = ReplicatorConfiguration(collections: [collConfig], target: messageEndpointTarget)

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
