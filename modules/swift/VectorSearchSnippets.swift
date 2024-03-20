//
//  VectorSearchSnippets.swift
//
//  Created by Vlad Velicu on 20/03/2024.
//

import Foundation
import CouchbaseLiteSwift
import NaturalLanguage

var database: Database!
var collection: Collection!
var model: NLEmbedding!

// MARK: Configuring a project to use Vector Search.

/*/
 Download Couchbase Lite iOS Swift and Couchbase Lite Vector Search libraries
 Extract the xcframeworks and copy them into the App Project Directory
 
 Add both libraries to the *Frameworks, Libraries and Embedded Content* to your desired target
 */

func vectorIndex() throws {
    database = try Database(name: "vectorDB")
    collection = try database.defaultCollection()
    
    // MARK: Create a default Vector Index Configuration
    
    var config = VectorIndexConfiguration(expression: "string", dimensions: 300, centroids: 20)
    
    // Default values already set:
    print(config.encoding) // .scalarQuantizer(type: .SQ8)
    print(config.metric) // .euclidean
    print(config.minTrainingSize) // 25 * 20
    print(config.maxTrainingSize) // 256 * 20
    
    // MARK: Set custom optional settings
    config.encoding = .none
    config.metric = .cosine
    config.minTrainingSize = 50
    config.maxTrainingSize = 300
    
    // MARK: Create Vector Index with Embedding
    func vectorIndexEmbedding() throws -> ResultSet? {
        try collection.createIndex(withName: "vector_index", config: config)
        
        model = NLEmbedding.wordEmbedding(for: .english)!
        guard let wordVector = model.vector(for: "<word>") else {
            NSLog("Cannot generate vector for <word>")
            return nil
        }
        
        let sql = "SELECT word FROM words WHERE vector_match(vector_index, $vector, 20)"
        let query = try database.createQuery(sql)
        
        let params = Parameters()
        params.setValue(wordVector, forName: "vector")
        query.parameters = params
        
        return try query.execute()
    }
    
    // MARK: Create Vector Index with Predictive Model
    func vectorIndexPredictiveModel() throws {
        let model = NLEmbedding.wordEmbedding(for: .english)!
        Database.prediction.registerModel(model as! PredictiveModel, withName: "WordEmbedding")
        let expression = "prediction(WordEmbedding,{\"word\": word}).vector"
        let config = VectorIndexConfiguration(expression: expression, dimensions: 300, centroids: 8)
        try collection.createIndex(withName: "words_pred_index", config: config)
    }
    
    // MARK: Use vector_match
    func useVectorMatch() throws -> ResultSet? {
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 300, centroids: 8)
        
        try collection.createIndex(withName: "vector_index", config: config)
        
        let sql = "select meta().id, word from _default.words where vector_match(vector_index, $vector, 20)"
        let query = try database.createQuery(sql)
        
        let parameters = Parameters()
        parameters.setValue(<inputArray>, forName: "vector")
        query.parameters = parameters
        
        return try query.execute()
    }
    
    // MARK: Use vector_distance
    func useVectorDistance() throws -> ResultSet? {
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 300, centroids: 8)
        config.metric = .cosine
        try collection.createIndex(withName: "vector_index", config: config)
        
        let sql = "select meta().id, word, vector_distance(vector_index) from _default.words where vector_match(vector_index, $vector, 20)"
        let query = try database.createQuery(sql)
        
        let parameters = Parameters()
        parameters.setValue(<inputArray>, forName: "vector")
        query.parameters = parameters
        
        return try query.execute()
    }
}
