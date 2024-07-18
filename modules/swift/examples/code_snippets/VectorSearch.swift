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
    case indexdNotFound
    case vectorNotFound
}

enum ColorError: Error {
    case transient
}

class Color {
    static func getVector(color: String) throws -> [Float]? {
        return []
    }
    
    static func getVectorAsync(color: String) async throws -> [Float]? {
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
        // in the documents' key named "vector" with 100 centroids.
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
        // end::vs-create-default-config[]
        try collection.createIndex(withName: "colors_index", config: config)
    }
    
    func createCustomVectorIndexConfig() throws {
        // tag::vs-create-custom-config[]
        // Create a vector index configuration for indexing 3-dimensional vectors embedded in
        // the documents' key named "vector" with 100 centroids. The configuration customizes
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
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
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
        let config = VectorIndexConfiguration(expression: expression, dimensions: 3, centroids: 100)
        
        // Create vector index from the configuration
        try collection.createIndex(withName: "colors_index", config: config)
    }
    // end::vs-create-predictive-index[]
    
    func createLazyIndex() throws {
        // tag::vs-lazy-index-config[]
        // Creating a lazy vector index using the document's 'color' key.
        // The value of this key will be used to compute a vector when updating the index.
        var config = VectorIndexConfiguration(expression: "color", dimensions: 3, centroids: 100)
        config.isLazy = true;
        // end::vs-lazy-index-config[]
    }
    
    func updateLazyIndex() async throws {
        // tag::vs-create-lazy-index-embedding[]
        guard let index = try collection.index(withName: "colors_index") else {
            throw AppError.indexdNotFound
        }
        
        while (true) {
            // Start an update on it (in this case, limit to 50 entries at a time)
            guard let updater = try index.beginUpdate(limit: 50) else {
                // If updater is nil and no error, that means there are no more entries to process
                break
            }
            
            for i in 0..<updater.count {
                // The value type will depend on the expression you have set in your index.
                // In this example, it is a string property.
                let color = updater.string(at: i)!
                
                var vector: [Float]? = nil
                do {
                    vector = try await Color.getVectorAsync(color: color)
                } catch ColorError.transient {
                    // Bad connection? Corrupted over the wire? Something bad happened
                    // and the vector cannot be generated at the moment. So skip
                    // this entry. The next time CBLQueryIndex_BeginUpdate is called,
                    // it will be considered again.
                    updater.skipVector(at: i)
                }
                
                // Set the computed vector here. If vector is nil, calling setVector
                // will cause the underlying document to NOT be indexed.
                try updater.setVector(vector, at: i)
            }
            
            // This writes the vectors to the index. You MUST have either set or
            // skipped all the values inside the updater or this call will throw an error.
            try updater.finish()
        }
        // end::vs-create-lazy-index-embedding[]
    }
}
