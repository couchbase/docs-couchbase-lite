//
//  VectorSearch.m
//  CouchbaseLite
//
//  Copyright © 2024 couchbase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLColor : NSObject
+ (nullable NSArray<NSNumber*>*) vectorForColor:(NSString*)color error: (NSError**)error;
@end

@implementation CBLColor

+ (nullable NSArray<NSNumber*>*) vectorForColor:(NSString*)color error: (NSError**)error {
    return nil;
}
@end

@interface CBLColorModel : NSObject <CBLPredictiveModel>
@end

@implementation CBLColorModel

- (instancetype) init {
    self = [super init];
    return self;
}

- (CBLDictionary*) predict: (CBLDictionary*)input {
    // Get color input from the input dictionary
    NSString* color = [input stringForKey: @"colorInput"];
    NSAssert(color, @"Input color not found");
    
    // Use ML model to get a vector (an array of numbers) for the input color.
    NSError* error;
    NSArray* vector = [CBLColor vectorForColor: color error: &error];
    if (!vector) { return nil; }
    
    // Create an output dictionary by setting the vector result to
    // the dictionary key named "vector".
    CBLMutableDictionary* output = [[CBLMutableDictionary alloc] init];
    [output setValue: vector forKey: @"vector"];
    
    return output;
}

@end

@interface VectorSearchSnippets : NSObject

@end

@implementation VectorSearchSnippets {
    CBLDatabase* database;
    CBLCollection* collection;
}

- (instancetype) init {
    self = [super init];
    return self;
}

// MARK: Configuring a project to use Vector Search.

/*/
 Download Couchbase Lite iOS Obj-C and Couchbase Lite Vector Search libraries
 Extract the xcframeworks and copy them into the App Project Directory
 
 Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
 */

- (void) enableVectorSearchExtension {
    // tag::vs-setup-packaging[]
    NSError* error;
    [CBLExtension enableVectorSearch: &error];
    // end::vs-setup-packaging[]
}

- (void) createDefaultVectorIndexConfig {
    // tag::vs-create-default-config[]
    // Create a vector index configuration with a document property named "vector", 
    // 3 dimensions, and 100 centroids.
    CBLVectorIndexConfiguration* config =
        [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector"
                                                     dimensions: 3 centroids: 100];
    // end::vs-create-default-config[]
}

- (void) createCustomVectorIndexConfig {
    // tag::vs-create-custom-config[]
    // Create a vector index configuration with a document property named "vector", 
    // 3 dimensions, and 100 centroids. Customize the encoding, the distance metric,
    // the number of probes, and the training size.
    CBLVectorIndexConfiguration* config =
        [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector"
                                                     dimensions: 3 centroids: 100];
    config.encoding = [CBLVectorEncoding none];
    config.metric = kCBLDistanceMetricCosine;
    config.numProbes = 8;
    config.minTrainingSize = 2500;
    config.maxTrainingSize = 5000;
    // end::vs-create-custom-config[]
}

- (void) numProbesConfig {
    // tag::vs-numprobes-config[]
    // Create a vector index configuration with a document property named "vector", 
    // 3 dimensions, and 100 centroids. Customize the number of probes.
    CBLVectorIndexConfiguration* config =
        [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector"
                                                     dimensions: 3 centroids: 100];
    config.numProbes = 8;
    // end::vs-numprobes-config[]
}

- (void) createVectorIndex {
    // tag::vs-create-index[]
    NSError* error;
    // Get the collection named "colors" in the default scope.
    CBLCollection* collection = [database collectionWithName: @"colors" scope: nil error: &error];
    if (!collection) { return; }
    
    // Create a vector index configuration with a document property named "vector",
    // 3 dimensions, and 100 centroids.
    CBLVectorIndexConfiguration* config =
        [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector"
                                                     dimensions: 3 centroids: 100];
    
    // Create a vector index from the configuration with the name "colors_index".
    [collection createIndexWithName: @"colors_index" config: config error: &error];
    // end::vs-create-index[]
}

- (void) createVectorIndexWithPredictiveModel {
    // tag::vs-create-predictive-index[]
    NSError* error;
    // Get the collection named "colors" in the default scope.
    CBLCollection* collection = [database collectionWithName: @"colors" scope: nil error: &error];
    if (!collection) { return; }
    
    // Register the predictive model named "ColorModel".
    [[CBLDatabase prediction] registerModel: [[CBLColorModel alloc] init] withName: @"ColorModel"];
    
    // Create a vector index configuration with an expression using the prediction function
    // to get the vectors from the registered predictive model.
    NSString* expression = @"prediction(ColorModel, {\"colorInput\": color}).vector";
    CBLVectorIndexConfiguration* config =
        [[CBLVectorIndexConfiguration alloc] initWithExpression: expression
                                                     dimensions: 3 centroids: 100];
    
    // Create a vector index from the configuration with the name "colors_index".
    [collection createIndexWithName: @"colors_index" config: config error: &error];
    // end::vs-create-predictive-index[]
}

- (void) queryAPVDPrediction {
    // tag::vs-apvd-prediction[]
    // Create a vector search query that uses prediction() for computing vectors.
    NSString* sql =
    @"SELECT meta().id, color "
    "FROM _default.colors "
    "ORDER BY approx_vector_distance(prediction(ColorModel, {\"colorInput\": color}).vector, $vector) "
    "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of floats) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-apvd-prediction[]
}

- (void) queryAPVDOrderBy {
    // tag::vs-use-vector-match[]
    // tag::vs-apvd-order-by[]
    // Create a query by using the approx_vector_distance() in the ORDER BY clause.
    NSString* sql = @"SELECT meta().id, color "
                     "FROM _default.colors "
                     "ORDER BY approx_vector_distance(vector, $vector) "
                     "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of floats) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-apvd-order-by[]
    // end::vs-use-vector-match[]
}

- (void) queryAPVDWhere {
    // tag::vs-apvd-where[]
    // Create a query by using the approx_vector_distance() in the WHERE clause.
    NSString* sql = @"SELECT meta().id, color "
                     "FROM _default.colors "
                     "WHERE approx_vector_distance(vector, $vector) < 0.5 "
                     "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of floats) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-apvd-where[]
}

- (void) queryUseVectorDistance {
    // tag::vs-use-vector-distance[]
    // Create a query by using the approx_vector_distance() to get vector distances.
    NSString* sql = @"SELECT meta().id, color, approx_vector_distance(vector, $vector) "
                     "FROM _default.colors "
                     "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of numbers) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-use-vector-distance[]
}

- (void) queryHybridOrderBy {
    // tag::vs-hybrid-order-by[]
    // Create a hybrid vector search query by using ORDER BY and WHERE clause.
    NSString* sql = @"SELECT meta().id, color "
                     "FROM _default.colors "
                     "WHERE saturation > 0.5 "
                     "ORDER BY approx_vector_distance(vector, $vector) "
                     "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of numbers) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-hybrid-order-by[]
}

- (void) queryHybridWhere {
    // tag::vs-hybrid-where[]
    // Create a hybrid vector search query in the WHERE clause.
    NSString* sql = @"SELECT meta().id, color "
                     "FROM _default.colors "
                     "WHERE saturation > 0.5 AND approx_vector_distance(vector, $vector) < 0.5 "
                     "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of numbers) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-hybrid-where[]
}

- (void) queryHybridPrediction {
    // tag::vs-hybrid-prediction[]
    // Create a hybrid vector search query using ORDER BY and WHERE clause.
    NSString* sql = 
    @"SELECT meta().id, color "
     "FROM _default.colors "
     "WHERE saturation > 0.5 "
     "ORDER BY approx_vector_distance(prediction(ColorModel, {\"colorInput\": color}).vector, $vector) "
     "LIMIT 8";
    
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of numbers) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-hybrid-prediction[]
}

- (void) queryHybridFTMatch {
    // tag::vs-hybrid-ftmatch[]
    // Create a hybrid vector search query with full-text's match() that
    // uses the the full-text index named "color_desc_index".
    NSString* sql = @"SELECT meta().id, color "
                     "FROM _default.colors "
                     "WHERE MATCH(color_desc_index, $text) "
                     "ORDER BY approx_vector_distance(vector, $vector) "
                     "LIMIT 8";
    NSError* error;
    CBLQuery* query = [database createQuery: sql error: &error];
    if (!query) { /* handle error */ return; }
    
    // Use ML model to get a vector (an array of numbers) for the input color.
    NSArray<NSNumber*>* vector = [CBLColor vectorForColor: @"FF00AA" error: &error];
    if (!vector) { /* handle error */ return; }
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    // Set the vector array to the parameter "$vector".
    [parameters setValue: vector forName: @"vector"];
    // Set the vector array to the parameter "$text".
    [parameters setString: @"vibrant" forName: @"text"];
    [query setParameters: parameters];
    
    // Execute the query.
    CBLQueryResultSet* results = [query execute: &error];
    if (!results) { /* handle error */ return; }
    
    for (CBLQueryResult* r in results) {
        // Process result
    }
    // end::vs-hybrid-ftmatch[]
}

- (void) createLazyIndexConfig {
    // tag::vs-lazy-index-config[]
    // Creating a lazy vector index using the document's property named "color".
    // The "color" property's value will be used to compute a vector when updating the index.
    CBLVectorIndexConfiguration* config =
        [[CBLVectorIndexConfiguration alloc] initWithExpression: @"color"
                                                     dimensions: 3 centroids: 100];
    config.isLazy = YES;
    // end::vs-lazy-index-config[]
}

- (BOOL) updateLazyIndexWithError: (NSError**)outError {
    // tag::vs-create-lazy-index-embedding[]
    CBLQueryIndex* index = [collection indexWithName: @"colors_index" error: outError];
    if (!index) {
        return NO;
    }
    
    while (true) {
        // Start an update on it (in this case, limit to 50 entries at a time)
        NSError* error;
        CBLIndexUpdater* updater = [index beginUpdateWithLimit: 50 error: &error];
        if (!updater) {
            // If updater is nil and no error, that means there are no more entries to process
            if (outError) { *outError = error; }
            return (error == nil);
        }
        
        for (NSUInteger i = 0; i < updater.count; i++) {
            NSString* color = [updater stringAtIndex: i];
            assert(color);
            
            NSArray* vector = [CBLColor vectorForColor: color error: &error];
            if (error) {
                // Bad connection? Corrupted over the wire? Something bad happened
                // and the vector cannot be generated at the moment. So skip
                // this entry. The next time -beginUpdateWithLimit:error: is called,
                // it will be considered again.
                [updater skipVectorAtIndex: i];
            }
            
            // Set the computed vector here. If vector is nil, calling setVector
            // will cause the underlying document to NOT be indexed.
            if (![updater setVector: vector atIndex: i error: outError]) {
                return NO;
            }
        }
        
        if (![updater finishWithError: outError]) {
            return NO;
        }
    }
    // end::vs-create-lazy-index-embedding[]
}


@end
