//
//  VectorSeachSnippets.m
//
//  Created by Vlad Velicu on 20/03/2024.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import <NaturalLanguage/NLEmbedding.h>

CBLDatabase* database;
CBLCollection* collection;
NLEmbedding* model;

// MARK: Configuring a project to use Vector Search.

/*/
 Download Couchbase Lite iOS Obj-C and Couchbase Lite Vector Search libraries
 Extract the xcframeworks and copy them into the App Project Directory
 
 Add both libraries to the *Frameworks, Libraries and Embedded Content* of your desired target
 */

@interface VectorSearch : NSObject 

@end

@implementation VectorSearch

- (void) createDefaultIndex {
    NSError* error;
    database = [[CBLDatabase alloc] initWithName:@"vectorDB" error:&error];
    collection = [database defaultCollection: &error];
    
    // MARK: Create a default Vector Index Configuration

    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 20];
    
    // Default values already set:
    NSLog(@"%@", config.encoding); // .scalarQuantizer(type: .SQ8)
    NSLog(@"%u", config.metric); // .euclidean
    NSLog(@"%u", config.minTrainingSize); // 25 * 20
    NSLog(@"%@", config.encoding); // 256 * 20
    
    // MARK: Set custom optional settings
    config.encoding = [CBLVectorEncoding none];
    config.metric = kCBLDistanceMetricCosine;
    config.minTrainingSize = 50;
    config.maxTrainingSize = 300;
}

// MARK: Create Vector Index with Embedding
- (CBLQueryResultSet*) vectorIndexEmbedding {
    NSError* error;
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 20];
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    
    model = [NLEmbedding wordEmbeddingForLanguage:@"english"];
    [model vectorForString: @"<word>"];
    
    NSString* sql = @"select meta().id, word from _default.words where vector_match(vector_index, $vector, 20)";
    CBLQuery* query = [database createQuery: sql error: &error];
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: <vectorArray> forName: @"vector"];
    [query setParameters: parameters];
    
    return [query execute: &error];
}

// MARK: Create Vector Index with Predictive Model
- (void) vectorIndexPredictiveModel {
    NSError* error;

    model = [NLEmbedding wordEmbeddingForLanguage:@"english"];
    [[CBLDatabase prediction] registerModel: model withName:@"WordEmbedding"];
    
    NSString* expression = @"prediction(WordEmbedding,{\"word\": word}).vector";
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: expression dimensions: 300 centroids: 8];
    
    [collection createIndexWithName: @"vector_pred_index" config: config error: &error];
}

// MARK: Use vector_match
- (CBLQueryResultSet*) useVectorMatch {
    NSError* error;
    
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    
    NSString* sql = @"select meta().id, word from _default.words where vector_match(vector_index, $vector, 20)";
    CBLQuery* query = [database createQuery: sql error: &error];
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: <inputArray> forName: @"vector"];
    [query setParameters: parameters];
    
    return [query execute: &error];
}

// MARK: Use vector_distance
- (CBLQueryResultSet*) useVectorDistance {
    NSError* error;
    
    CBLVectorIndexConfiguration* config = [[CBLVectorIndexConfiguration alloc] initWithExpression: @"vector" dimensions: 300 centroids: 8];
    
    [collection createIndexWithName: @"vector_index" config: config error: &error];
    
    NSString* sql = @"select meta().id, word, vector_distance(vector_index) from _default.words where vector_match(vector_index, $vector, 20)";
    CBLQuery* q = [database createQuery: sql error: &error];
    
    CBLQueryParameters* parameters = [[CBLQueryParameters alloc] init];
    [parameters setValue: <inputArray> forName: @"vector"];
    [q setParameters: parameters];
    
    return [q execute: &error];
}

@end
