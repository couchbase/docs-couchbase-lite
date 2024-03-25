//
//  VectorSeach.m
//  CouchbaseLite
//
//  Copyright © 2024 couchbase. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import <NaturalLanguage/NLEmbedding.h>

CBLDatabase* database;
CBLCollection* collection;
NLEmbedding* model;
// placeholder
NSArray* vectorArray;

@interface VectorSearchSnippets : NSObject

@end

@implementation VectorSearchSnippets

// MARK: Configuring a project to use Vector Search.

/*/
 Download Couchbase Lite iOS Obj-C and Couchbase Lite Vector Search libraries
 Extract the xcframeworks and copy them into the App Project Directory
 
 Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
 */

- (void) createDefaultIndex {
    
    // MARK: Create a default Vector Index Configuration
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    
    // MARK: Set custom settings
    config.encoding = [CBLVectorEncoding none];
    config.metric = kCBLDistanceMetricCosine;
    config.minTrainingSize = 50;
    config.maxTrainingSize = 300;
}

- (CBLQueryResultSet*) vectorIndexEmbedding {
    
    // MARK: Create Vector Index with Embedding
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    
    NSError* error;
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    
    NSArray<NSNumber*>* vectorArray = [model vectorForString: @"word"];
    
    NSString* sql = @"select meta().id, word from _default.words where vector_match(vector_index, $vector, 20)";
    CBLQuery* query = [database createQuery: sql error: &error];
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vectorArray forName: @"vector"];
    [query setParameters: parameters];
    
    return [query execute: &error];
}

- (CBLQueryResultSet*) useVectorMatch {
    
    // MARK: Use vector_match
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    
    NSError* error;
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    
    NSString* sql = @"select meta().id, word from _default.words where vector_match(vector_index, $vector, 20)";
    CBLQuery* query = [database createQuery: sql error: &error];
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vectorArray forName: @"vector"];
    [query setParameters: parameters];
    
    return [query execute: &error];
}

- (CBLQueryResultSet*) useVectorDistance {
    
    // MARK: Use vector_distance
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    
    NSError* error;
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    
    NSString* sql = @"select meta().id, word, vector_distance(vector_index) from _default.words where vector_match(vector_index, $vector, 20)";
    CBLQuery* q = [database createQuery: sql error: &error];
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: vectorArray forName: @"vector"];
    [q setParameters: parameters];
    
    return [q execute: &error];
}

@end


// MARK: Create Vector Index with Predictive Model

@interface WordModel : NSObject <CBLPredictiveModel>
@end

@implementation WordModel


- (CBLDictionary*) predict: (CBLDictionary*)input {
    model = [NLEmbedding wordEmbeddingForLanguage: @"english"];
   
    NSString* word = [input stringForKey: @"word"];
    if (!word) {
        NSLog(@"No word found !!!");
        return nil;
    }
    
    NSArray* vector = [model vectorForString: @"word"];
    CBLMutableDictionary* output = [[CBLMutableDictionary alloc] init];
    [output setValue: vector forKey: @"vector"];
    
    return output;
}

- (void) createVectorIndex {
    WordModel* model = [[WordModel alloc] init];
    [[CBLDatabase prediction] registerModel: model withName: @"WordEmbedding"];
    
    NSString* expression = @"prediction(WordEmbedding,{\"word\": word}).vector";
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: expression dimensions: 300 centroids: 8];
    
    NSError* error;
    [collection createIndexWithName: @"vector_pred_index" config: config error: &error];
    
    [[CBLDatabase prediction] unregisterModelWithName: @"WordEmbedding"];
}

@end
