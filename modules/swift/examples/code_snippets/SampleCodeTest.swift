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
    var otherDB: Database!
    
    var replicator: Replicator!
    var listener: URLEndpointListener!
}

// tag::sgw-repl-pull[]
class MyClass {
    var database: Database?
    var replicator: Replicator? // <1>

    func startReplicator() {
        let url = URL(string: "ws://localhost:4984/db")! // <2>
        let target = URLEndpoint(url: url)
        var config = ReplicatorConfiguration(database: database!, target: target)
        config.replicatorType = .pull

        self.replicator = Replicator(config: config)
        self.replicator?.start()
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

 // tag::sgw-act-rep-initialize[]
 let tgtUrl = URL(string: "wss://10.1.1.12:8092/travel-sample")!
 let targetEndpoint = URLEndpoint(url: tgtUrl)
 var config = ReplicatorConfiguration(database: actDb!, target: targetEndpoint) // <.>

 // end::sgw-act-rep-initialize[]

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

// MARK: -- QUESTIONS

// tag::listener[]
// FIXME: Not sure why we need a tag like this???

// end::start-replication[]
// FIXME: Not seeing where its started?

// FIXME: not used???
// tag::listener-config-tls-full[]

// tag::p2p-ws-api-urlendpointlistener[]
// FIXME: can we use the docsn site to show the interface of the Listener class?
// https://docs.couchbase.com/mobile/2.8.0/couchbase-lite-swift/Classes/URLEndpointListener.html
// end::p2p-ws-api-urlendpointlistener[]

