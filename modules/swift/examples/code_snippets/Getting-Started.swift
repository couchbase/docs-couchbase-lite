//
//  ViewController.swift
//  threeBeta01prod
//
//  Created by Ian Bridge on 04/10/2021.
//

import UIKit
import CouchbaseLiteSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        getStarted(testReplication: false)
}


    func getStarted (testReplication: Bool) {
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
        print("Created document id type \(mutableDoc.id)? with type = \(mutableDoc.string(forKey: "type")!)")


        // Update a document.
        if let mutableDoc = database.document(withID: mutableDoc.id)?.toMutable() {
            mutableDoc.setString("Swift", forKey: "language")
            do {
                try database.saveDocument(mutableDoc)

                let document = database.document(withID: mutableDoc.id)!
                // Log the document ID (generated by the database)
                // and properties
                print("Updated document id \(document.id), adding language \(document.string(forKey: "language")!)")
            } catch {
                fatalError("Error updating document")
            }
        }

        // Create a query to fetch documents of type SDK.
        print("Querying Documents of type=SDK")
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

        if testReplication {
            // Create replicators to push and pull changes to and from the cloud.
            let targetEndpoint = URLEndpoint(url: URL(string: "ws://localhost:4984/getting-started-db")!)
            var replConfig = ReplicatorConfiguration(database: database, target: targetEndpoint)
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
            print("Not testing replication")
        }
    }
}
