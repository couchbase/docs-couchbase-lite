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
        // Create a vector index configuration with a document property named "vector", 
        // 3 dimensions, and 100 centroids.
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
        // end::vs-create-default-config[]
        try collection.createIndex(withName: "colors_index", config: config)
    }
    
    func createCustomVectorIndexConfig() throws {
        // tag::vs-create-custom-config[]
        // Create a vector index configuration with a document property named "vector", 
        // 3 dimensions, and 100 centroids. Customize the encoding, the distance metric,
        // the number of probes, and the training size.
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
        config.encoding = .none
        config.metric = .cosine
        config.numProbes = 8
        config.minTrainingSize = 2500
        config.maxTrainingSize = 5000
        // end::vs-create-custom-config[]
        try collection.createIndex(withName: "colors_index", config: config)
    }
    
    func numProbesConfig() throws {
        // tag::vs-numprobes-config[]
        // Create a vector index configuration with a document property named "vector",
        // 3 dimensions, and 100 centroids. Customize the the number of probes.
        var config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
        config.numProbes = 8
        // end::vs-numprobes-config[]
        try collection.createIndex(withName: "colors_index", config: config)
    }

    func createVectorIndex() throws {
        // tag::vs-create-index[]
        // Get the collection named "colors" in the default scope.
        let collection = try database.collection(name: "colors")!;
        
        // Create a vector index configuration with a document property named "vector",
        // 3 dimensions, and 100 centroids.
        let config = VectorIndexConfiguration(expression: "vector", dimensions: 3, centroids: 100)
        // Create a vector index from the configuration with the name "colors_index".
        try collection.createIndex(withName: "colors_index", config: config)
        // end::vs-create-index[]
    }
        
    func queryAPVDOrderBy() throws {
        // tag::vs-use-vector-match[]
        // tag::vs-apvd-order-by[]
        // Create a vector search query by using the approx_vector_distance() in ORDER BY clause.
        let sql = "SELECT meta().id, color " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-apvd-order-by[]
        // end::vs-use-vector-match[]
    }
    
    func queryAPVDWhere() throws {
        // tag::vs-apvd-where[]
        // Create a vector search query by using the approx_vector_distance() in WHERE clause.
        let sql = "SELECT meta().id, color " +
                  "FROM _default.colors " +
                  "WHERE approx_vector_distance(vector, $vector) < 0.5 " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-apvd-where[]
    }
        
    func queryVectorDistance() throws {
        // tag::vs-use-vector-distance[]
        // Create a query by using the approx_vector_distance() to get vector distances.
        let sql = "SELECT meta().id, color, approx_vector_distance(vector, $vector) " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-use-vector-distance[]
    }
    
    func queryHybridOrderBy() throws {
        // tag::vs-hybrid-order-by[]
        // Create a hybrid vector search query by using ORDER BY and WHERE clause.
        let sql = "SELECT meta().id, color, approx_vector_distance(vector, $vector) " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-hybrid-order-by[]
    }
    
    func queryHybridWhere() throws {
        // tag::vs-hybrid-where[]
        // Create a hybrid vector search query by using ORDER BY and WHERE clause.
        let sql = "SELECT meta().id, color " +
                  "WHERE saturation > 0.5 AND approx_vector_distance(vector, $vector) < 0.5 " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-hybrid-where[]
    }
    
    func queryHybridPrediction() throws {
        // tag::vs-hybrid-prediction[]
        // Create a hybrid vector search query that uses prediction() for computing vectors.
        let sql = 
        "SELECT meta().id, color " +
        "WHERE saturation > 0.5 " +
        "ORDER BY approx_vector_distance(prediction(ColorModel, {\"colorInput\": color}).vector, $vector) " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-hybrid-prediction[]
    }
    
    func queryHybridTMatch() throws {
        // tag::vs-hybrid-ftmatch[]
        // Create a hybrid vector search query with full-text's match() that
        // uses the the full-text index named "color_desc_index".
        let sql = "SELECT meta().id, color " +
                  "WHERE MATCH(color_desc_index, $text) " +
                  "ORDER BY approx_vector_distance(vector, $vector) " +
                  "LIMIT 8"
        
        let query = try database.createQuery(sql)
        
        // Get a vector, an array of float numbers, for the input color code (e.g. FF000AA).
        // Normally, you will get the vector from your ML model.
        guard let vector = try Color.getVector(color: "FF00AA") else {
            throw AppError.vectorNotFound
        }
        
        let parameters = Parameters()
        // Set the vector array to the parameter "$vector"
        parameters.setValue(vector, forName: "vector")
        // Set the vector array to the parameter "$text".
        parameters.setString("vibrant", forName: "text")
        query.parameters = parameters
        
        // Execute the query
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-hybrid-ftmatch[]
    }
    
    // MARK: Create Vector Index with Predictive Model
    // tag::vs-create-predictive-index[]
    class ColorModel: PredictiveModel {
        func predict(input: DictionaryObject) -> DictionaryObject? {
            // Get the color input from the input dictionary
            guard let color = input.string(forKey: "colorInput") else {
                fatalError("No input color found")
            }
            
            // Use ML model to get a vector (an array of floats) for the input color.
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
        let expression = "prediction(ColorModel, {\"colorInput\": color}).vector"
        let config = VectorIndexConfiguration(expression: expression, dimensions: 3, centroids: 100)
        
        // Create vector index from the configuration
        try collection.createIndex(withName: "colors_index", config: config)
    }
    // end::vs-create-predictive-index[]
    
    func queryAPVDPrediction() throws {
        // tag::vs-apvd-prediction[]
        // Create a vector search query that uses prediction() for computing vectors.
        let sql =
        "SELECT id, color " +
        "FROM _default.colors " +
        "ORDER BY approx_vector_distance(prediction(ColorModel, {\"colorInput\": color}).vector, $vector) " +
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
        let results = try query.execute()
        
        for r in results {
            // Process result
        }
        // end::vs-apvd-prediction[]
    }
    
    func createLazyIndex() throws {
        // tag::vs-lazy-index-config[]
        // Creating a lazy vector index using the document's property named "color".
        // The "color" property's value will be used to compute a vector when updating the index.
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
                    // this entry. The next time beginUpdate(limit:) is called,
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
