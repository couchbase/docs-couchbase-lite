//
//  Getting-Started.swift
//  code-snippets
//
//  Copyright © 2025 couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        try! getStartedWithReplication(replication: false)
}

    func getStartedWithReplication (replication: Bool) throws {
        // Get the database (and create it if it doesn’t exist).
        let database = try Database(name: "mydb")
        let defaultCol = try database.defaultCollection()

        // Create a new document (i.e. a record) in the database.
        var mutableDoc = MutableDocument()
            .setFloat(2.0, forKey: "version")
            .setString("SDK", forKey: "type")

        // Save document to default collection.
        try defaultCol.save(document: mutableDoc)
        print("Created document id type \(mutableDoc.id)? with type = \(mutableDoc.string(forKey: "type")!)")
        
        // Update a document.
        mutableDoc = try defaultCol.document(id: mutableDoc.id)!.toMutable()
        mutableDoc.setString("Swift", forKey: "language")
        try defaultCol.save(document: mutableDoc)
        let document = try defaultCol.document(id: mutableDoc.id)
        assert(document!.string(forKey: "language") == "Swift",
               "Updated document id \(document!.id), adding language \(document!.string(forKey: "language")!)")

        // Create a query to fetch documents of type SDK.
        print("Querying Documents of type=SDK")
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(defaultCol))
            .where(Expression.property("type").equalTo(Expression.string("SDK")))

        // Run the query.
        do {
            let result = try query.execute()
            print("Number of rows :: \(result.allResults().count)")
        } catch {
            fatalError("Error running the query")
        }

        if replication {
            // Create replicators to push and pull changes to and from the cloud.
            let targetEndpoint = URLEndpoint(url: URL(string: "ws://localhost:4984/getting-started-db")!)
            
            // Create Collection configuration.
            let colConfig = CollectionConfiguration(collection: defaultCol)
            
            // Create replicator configuration with the target endpoint and collection configuration.
            var replConfig = ReplicatorConfiguration(collections: [colConfig], target: targetEndpoint)
            replConfig.replicatorType = .pushAndPull
            
            // Add authentication.
            replConfig.authenticator = BasicAuthenticator(username: "john", password: "pass")
            
            // Create replicator (make sure to add an instance or static variable named replicator)
            let replicator = Replicator(config: replConfig)

            // Listen to replicator change events.
            replicator.addChangeListener { (change) in
                if let error = change.status.error as NSError? {
                    print("Error code :: \(error.code)")
                }
            }

            // Start replication.
            replicator.start()
        } else {
            print("Not running replication")
        }
    }
}
