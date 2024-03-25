//
//  VectorSearch.swift
//  CouchbaseLite
//
//  Copyright © 2024 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import NaturalLanguage

var database: Database!
var collection: Collection!
var model: NLEmbedding!
// placeholder
var vectorArray: Array?  = []

class VectorSearchSnippets {
    // MARK: Configuring a project to use Vector Search.

    /*/
     Download Couchbase Lite iOS Swift and Couchbase Lite Vector Search libraries
     Extract the xcframeworks and copy them into the App Project Directory
     
     Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
     */

    func vectorIndex() throws {
        // MARK: Create a default Vector Index Configuration
        var config = VectorIndexConfiguration(expression: "string", dimensions: 300, centroids: 8)
        
        // MARK: Set custom optional settings
        config.encoding = .none
        config.metric = .cosine
        config.minTrainingSize = 50
        config.maxTrainingSize = 300
        
    }

    func vectorIndexEmbedding() throws -> ResultSet? {
        // MARK: Create Vector Index with Embedding
        let config = VectorIndexConfiguration(expression: "word", dimensions: 300, centroids: 8)
        try collection.createIndex(withName: "vector_index", config: config)
        
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
        
    func useVectorMatch() throws -> ResultSet? {
        // MARK: Use vector_match
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 300, centroids: 8)
        
        try collection.createIndex(withName: "vector_index", config: config)
        
        let sql = "select meta().id, word from _default.words where vector_match(vector_index, $vector, 20)"
        let query = try database.createQuery(sql)
        
        let parameters = Parameters()
        parameters.setValue(vectorArray, forName: "vector")
        query.parameters = parameters
        
        return try query.execute()
    }
        

    func useVectorDistance() throws -> ResultSet? {
        // MARK: Use vector_distance
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 300, centroids: 8)
        config.metric = .cosine
        try collection.createIndex(withName: "vector_index", config: config)
        
        let sql = "select meta().id, word, vector_distance(vector_index) from _default.words where vector_match(vector_index, $vector, 20)"
        let query = try database.createQuery(sql)
        
        let parameters = Parameters()
        parameters.setValue(vectorArray, forName: "vector")
        query.parameters = parameters
        
        return try query.execute()
    }
    
    // MARK: Create Vector Index with Predictive Model

    class WordModel: PredictiveModel {
        
        func predict(input: DictionaryObject) -> DictionaryObject? {
            model = NLEmbedding.wordEmbedding(for: .english)!
            
            guard let word = input.string(forKey: "word") else {
                fatalError("No word found !!!")
            }
            
            let vector = model.vector(for: word)
            let output = MutableDictionaryObject()
            output.setValue(vector, forKey: "vector")
            
            return output
        }
    }
    
    func createVectorIndex() throws {
        let model = WordModel()
        Database.prediction.registerModel(model, withName: "WordEmbedding")
        
        let expression = "prediction(WordEmbedding,{\"word\": word}).vector"
        let config = VectorIndexConfiguration(expression: expression, dimensions: 300, centroids: 8)
        
        try collection.createIndex(withName: "words_pred_index", config: config)
        
        Database.prediction.unregisterModel(withName: "WordEmbedding")
    }

}






