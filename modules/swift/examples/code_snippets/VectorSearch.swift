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
var mlmodel: NLEmbedding!

enum VectorSearchError: Error {
    case vectorNotFound
}

class VectorSearchSnippets {
    // MARK: Configuring a project to use Vector Search.

    /*/
     Download Couchbase Lite iOS Swift and Couchbase Lite Vector Search libraries
     Extract the xcframeworks and copy them into the App Project Directory
     
     Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
     */

    func createVectorIndex() throws {

        // tag::vs-create-default-config[]
        // Create a default vector index configuration
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 300, centroids: 8)
        // end::vs-create-default-config[]
        
        // tag::vs-create-custom-config[]
        // Set custom optional settings
        config.encoding = .scalarQuantizer(type: .SQ4)
        config.metric = .cosine
        config.minTrainingSize = 50
        config.maxTrainingSize = 300
       
        
        // Create a vector index from the configuration
        try collection.createIndex(withName: "vector_index", config: config)
         // end::vs-create-custom-config[]
    }

    func createVectorIndexWithEmbedding() throws {

        // tag::vs-create-index[]
        // Create a vector index configuration from a document property named "vector" which
        // contains the vector embedding.
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 300, centroids: 8)
        try collection.createIndex(withName: "vector_index", config: config)
        // end::vs-create-index[]
    }
        
    func queryUsingVectorMatch(word: String) throws -> ResultSet? {
        // tag::vs-use-vector-match[]
        // Create a query to search similar words by using the vector_match()
        // function to search word vectors in the vector index named "vector_index".
        let sql = "SELECT meta().id, word " +
                  "FROM _default.words " +
                  "WHERE vector_match(vector_index, $vector, 20)"
        
        let query = try database.createQuery(sql)
        
        // Use ML model to get a vector (an array of numbers) for the input word.
        guard let vector = mlmodel.vector(for: word) else {
            throw VectorSearchError.vectorNotFound
        }
        
        // Set the vector array to the parameter "$vector"
        let parameters = Parameters()
        parameters.setValue(vector, forName: "vector")
        query.parameters = parameters
        
        // Execute the query
        return try query.execute()
        // end::vs-use-vector-match[]
    }
        
    func queryUsingVectorDistance(word: String) throws -> ResultSet? {

        // tag::vs-use-vector-distance[]
        // Create a query to get vector distances by using the vector_distance() function.
        let sql = "SELECT meta().id, word, vector_distance(vector_index) " +
                  "FROM _default.words " +
                  "WHERE vector_match(vector_index, $vector, 20)"
        
        let query = try database.createQuery(sql)
        
        // Use ML model to get a vector (an array of numbers) for the input word.
        guard let vector = mlmodel.vector(for: word) else {
            throw VectorSearchError.vectorNotFound
        }
        
        // Set the vector array to the parameter "$vector"
        let parameters = Parameters()
        parameters.setValue(vector, forName: "vector")
        query.parameters = parameters
        
        // Execute the query
        return try query.execute()
        // end::vs-use-vector-distance[]
    }
    
    // MARK: Create Vector Index with Predictive Model
    // tag::vs-create-predictive-index[]
    class WordModel: PredictiveModel {
        let mlmodel = NLEmbedding.wordEmbedding(for: .english)!
        
        func predict(input: DictionaryObject) -> DictionaryObject? {
            // Get word input from the input dictionary
            guard let word = input.string(forKey: "word") else {
                fatalError("No word found")
            }
            
            // Use ML model to get a vector (an array of numbers) for the input word.
            let vector = mlmodel.vector(for: word)
            
            // Create an output dictionary by setting the vector result to
            // the dictionary key named "vector".
            let output = MutableDictionaryObject()
            output.setValue(vector, forKey: "vector")
            return output
        }
    }
    
    func createVectorIndexFromPredictiveIndex() throws {
        // Register the predictive model named "WordEmbedding".
        Database.prediction.registerModel(WordModel(), withName: "WordEmbedding")
        
        // Create a vector index configuration with an expression using the prediction
        // function to get the vectors from the registered predictive model.
        let expression = "prediction(WordEmbedding, {\"word\": word}).vector"
        let config = VectorIndexConfiguration(expression: expression, dimensions: 300, centroids: 8)
        
        // Create vector index from the configuration
        try collection.createIndex(withName: "words_pred_index", config: config)
    }
    // end::vs-create-predictive-index[]
}
