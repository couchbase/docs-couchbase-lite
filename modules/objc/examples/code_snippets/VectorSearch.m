//
//  VectorSeach.m
//  CouchbaseLite
//
//  Copyright © 2024 couchbase. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import <NaturalLanguage/NLEmbedding.h>

// Placeholder for the vector not found error
#define VECTOR_NOT_FOUND_ERROR [NSError errorWithDomain: @"VectorSearch" code: 100 userInfo: nil]

@interface WordModel : NSObject <CBLPredictiveModel>

@end

@implementation WordModel {
    NLEmbedding* mlmodel;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        mlmodel = [NLEmbedding wordEmbeddingForLanguage: @"english"];
    }
    return self;
}

- (CBLDictionary*) predict: (CBLDictionary*)input {
    // Get word input from the input dictionary
    NSString* word = [input stringForKey: @"word"];
    NSAssert(word, @"Word not found");
    
    // Use ML model to get a vector (an array of numbers) for the input word.
    NSArray* vector = [mlmodel vectorForString: @"word"];
    
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
    NLEmbedding* mlmodel;
}

// MARK: Configuring a project to use Vector Search.

/*/
 Download Couchbase Lite iOS Obj-C and Couchbase Lite Vector Search libraries
 Extract the xcframeworks and copy them into the App Project Directory
 
 Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
 */

- (void) createVectorIndex {
    // tag::vs-create-default-config[]
    // Create a default Vector Index Configuration
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    // end::vs-create-default-config[]

    // tag::vs-create-custom-config[]
    // Set custom settings
    config.encoding = [CBLVectorEncoding scalarQuantizerWithType: kCBLSQ4];
    config.metric = kCBLDistanceMetricCosine;
    config.minTrainingSize = 50;
    config.maxTrainingSize = 300;
    // end::vs-create-custom-config[]
}

- (void) createVectorIndexWithEmbedding {
    // tag::vs-create-index[]
    // Create a vector index configuration from a document property named "vector" which
    // contains the vector embedding.
    NSError* error;
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    // end::vs-create-index[]
}

- (void) createVectorIndexWithPredictiveModel {
    // tag::vs-create-predictive-index[]
    // Register the predictive model named "WordEmbedding".
    [[CBLDatabase prediction] registerModel: [[WordModel alloc] init] withName: @"WordEmbedding"];
    
    // Create a vector index configuration with an expression using the prediction function
    // to get the vectors from the registered predictive model.
    NSString* expression = @"prediction(WordEmbedding, {\"word\": word}).vector";
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: expression dimensions: 300 centroids: 8];
    
    // Create vector index from the configuration
    NSError* error;
    [collection createIndexWithName: @"vector_pred_index" config: config error: &error];
    // end::vs-create-predictive-index[]
}

- (CBLQueryResultSet*) queryUsingVectorMatchForWord: (NSString*)word error: (NSError**)error {
    // tag::vs-use-vector-match[]
    // Create a query to search similar words by using the vector_match()
    // function to search word vectors in the vector index named "vector_index".
    NSString* sql = @"SELECT meta().id, word "
                     "FROM _default.words "
                     "WHERE vector_match(vector_index, $vector, 20)";
    CBLQuery* query = [database createQuery: sql error: error];
    
    // Use ML model to get a vector (an array of numbers) for the input word.
    NSArray<NSNumber*>* vector = [mlmodel vectorForString: word];
    if (!vector) {
        if (error) *error = VECTOR_NOT_FOUND_ERROR;
        return nil;
    }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    return [query execute: error];
    // end::vs-use-vector-match[]
}

- (CBLQueryResultSet*) queryUsingVectorDistanceForWord: (NSString*)word error: (NSError**)error {
    // tag::vs-use-vector-distance[]
    // Create a query to get vector distances by using the vector_distance() function.
    NSString* sql = @"SELECT meta().id, word, vector_distance(vector_index) "
                     "FROM _default.words "
                     "WHERE vector_match(vector_index, $vector, 20)";
    CBLQuery* query = [database createQuery: sql error: error];
    
    // Use ML model to get a vector (an array of numbers) for the input word.
    NSArray<NSNumber*>* vector = [mlmodel vectorForString: word];
    if (!vector) {
        if (error) *error = VECTOR_NOT_FOUND_ERROR;
        return nil;
    }
    
    // Set the vector array to the parameter "$vector".
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vector forName: @"vector"];
    [query setParameters: parameters];
    
    // Execute the query.
    return [query execute: error];
    // end::vs-use-vector-distance[]
}

@end
