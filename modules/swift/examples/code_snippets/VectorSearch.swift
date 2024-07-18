//
//  VectorSearch.swift
//  CouchbaseLite
//
//  Copyright © 2024 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

var database: Database!
var collection: Collection!

enum AppError: Error {
    case vectorNotFound
}

class Color {
    static func getVector(color: String) throws -> [Float]? {
        return []
    }
}

class VectorSearchSnippets {
    // MARK: Configuring a project to use Vector Search.

    /*/
     Download Couchbase Lite iOS Swift and Couchbase Lite Vector Search libraries
     Extract the xcframeworks and copy them into the App Project Directory
     
     Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
     */
    
    func enableVectorSearchExtension() throws {
        // tag::vs-setup-packaging[]
        try Extension.enableVectorSearch()
        // end::vs-setup-packaging[]
    }

    func createDefaultVectorIndexConfig() throws {
        // tag::vs-create-default-config[]
        // Create a vector index configuration for indexing 3-dimensional vectors embedded
        // in the documents' key named "vector" using 2 centroids.
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 2)
        // end::vs-create-default-config[]
        try collection.createIndex(withName: "colors_index", config: config)
    }
    
    func createCustomVectorIndexConfig() throws {
        // tag::vs-create-custom-config[]
        // Create a vector index configuration for indexing 3-dimensional vectors embedded in
        // the documents' key named "vector" using 100 centroids. The configuration customizes
        // the encoding, the distance metric, the number of probes, and the training size.
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
        config.encoding = .none
        config.metric = .cosine
        config.numProbes = 8
        config.minTrainingSize = 2500
        config.maxTrainingSize = 5000
        // end::vs-create-custom-config[]
        try collection.createIndex(withName: "colors_index", config: config)
    }

    func createVectorIndex() throws {
        // tag::vs-create-index[]
        // Create a vector index configuration from a document property named "vector" which
        // contains the vector embedding.
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 2)
        try collection.createIndex(withName: "colors_index", config: config)
        // end::vs-create-index[]
    }
        
    func queryVectorSearch(color: String) throws -> ResultSet? {
        // tag::vs-use-vector-match[]
        // Create a query to search similar colors by using the approx_vector_distance() function
        // in the ORDER BY clause.
        let sql = "SELECT id, color " +
                  "FROM _default.colors " +
                  "ORDER BY approx_vector_distance(vector, $vector) " +
                  "LIMIT 8"
        
        let query = try database.createQuery(sql)
        
        // Get a vector, an array of float numbers, for the input color code (e.g. FF000AA).
        // Normally, you will get the vector from your ML model.
        guard let vector = try Color.getVector(color: "FF00AA") else {
            throw AppError.vectorNotFound
        }
        
        // Set the vector array to the parameter "$vector"
        let parameters = Parameters()
        parameters.setValue(vector, forName: "vector")
        query.parameters = parameters
        
        // Execute the query
        return try query.execute()
        // end::vs-use-vector-match[]
    }
        
    func queryVectorDistance(word: String) throws -> ResultSet? {
        // tag::vs-use-vector-distance[]
        // Create a query to get vector distances using the approx_vector_distance() function.
        let sql = "SELECT id, color, approx_vector_distance(vector, $vector) " +
                  "FROM _default.colors " +
                  "LIMIT 8"
        
        let query = try database.createQuery(sql)
        
        // Get a vector, an array of float numbers, for the input color code (e.g. FF000AA).
        // Normally, you will get the vector from your ML model.
        guard let vector = try Color.getVector(color: "FF00AA") else {
            throw AppError.vectorNotFound
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
    class ColorModel: PredictiveModel {
        func predict(input: DictionaryObject) -> DictionaryObject? {
            // Get word input from the input dictionary
            guard let color = input.string(forKey: "colorInput") else {
                fatalError("No input color found")
            }
            
            // Use ML model to get a vector (an array of numbers) for the input word.
            guard let vector = try! Color.getVector(color: color) else {
                return nil
            }
            
            // Create an output dictionary by setting the vector result to
            // the dictionary key named "vector".
            let output = MutableDictionaryObject()
            output.setValue(vector, forKey: "vector")
            return output
        }
    }
    
    func createVectorIndexFromPredictiveIndex() throws {
        // Register the predictive model named "ColorModel".
        Database.prediction.registerModel(ColorModel(), withName: "ColorModel")
        
        // Create a vector index configuration with an expression using the prediction
        // function to get the vectors from the registered predictive model.
        let expression = "prediction(WordEmbedding, {\"colorInput\": color}).vector"
        let config = VectorIndexConfiguration(expression: expression, dimensions: 300, centroids: 8)
        
        // Create vector index from the configuration
        try collection.createIndex(withName: "colors_index", config: config)
    }
    // end::vs-create-predictive-index[]
}
