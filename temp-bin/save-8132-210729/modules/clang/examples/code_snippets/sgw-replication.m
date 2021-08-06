// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
@interface MyClass : NSObject
@property (nonatomic) CBLDatabase *database;
@property (nonatomic) CBLReplicator *replicator; // <1>
@end

@implementation MyClass
@synthesize database=_database;
@synthesize replicator=_replicator;

- (void) startReplication {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"]; // <2>
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:_database
                                                                                       target:target];
    config.replicatorType = kCBLReplicatorTypePull;
    _replicator = [[CBLReplicator alloc] initWithConfig:config];
    [_replicator start];
}
@end

// end::sgw-repl-pull[]

// tag::sgw-repl-pull-callouts[]
<1> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<2> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
You should now use `ws:`, or `wss:` for SSL/TLS connections.


// end::sgw-repl-pull-callouts[]


// END -- snippets --