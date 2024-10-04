//
//  Getting-Started.swift
//
//  Copyright (c) 2024 Couchbase, Inc. All rights reserved.
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
        let collection = try database.defaultCollection()

        // Create a new document (i.e. a record) in the database.
        var mutableDoc = MutableDocument()
            .setFloat(2.0, forKey: "version")
            .setString("SDK", forKey: "type")

        // Save document to default collection.
        try collection.save(document: mutableDoc)
        print("Created document id type \(mutableDoc.id)? with type = \(mutableDoc.string(forKey: "type")!)")
        
        // Update a document.
        mutableDoc = try collection.document(id: mutableDoc.id)!.toMutable()
        mutableDoc.setString("Swift", forKey: "language")
        try collection.save(document: mutableDoc)
        let document = try collection.document(id: mutableDoc.id)
        assert(document!.string(forKey: "language") == "Swift",
               "Updated document id \(document!.id), adding language \(document!.string(forKey: "language")!)")

        // Create a query to fetch documents of type SDK.
        print("Querying Documents of type=SDK")
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

        if replication {
            // Create replicators to push and pull changes to and from the cloud.
            let targetEndpoint = URLEndpoint(url: URL(string: "ws://localhost:4984/getting-started-db")!)
            var replConfig = ReplicatorConfiguration(target: targetEndpoint)
            replConfig.replicatorType = .pushAndPull
            
            // Add authentication.
            replConfig.authenticator = BasicAuthenticator(username: "john", password: "pass")

            // Add collection
            replConfig.addCollection(collection)
            
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
