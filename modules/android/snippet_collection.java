//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.codesnippets;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.Array;
import com.couchbase.lite.ArrayFunction;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.Blob;
import com.couchbase.lite.ClientCertificateAuthenticator;
import com.couchbase.lite.Conflict;
import com.couchbase.lite.ConflictResolver;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.DatabaseEndpoint;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.DocumentFlag;
import com.couchbase.lite.EncryptionKey;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.Expression;
import com.couchbase.lite.FullTextFunction;
import com.couchbase.lite.FullTextIndexConfiguration;
import com.couchbase.lite.FullTextIndexItem;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Join;
import com.couchbase.lite.ListenerCertificateAuthenticator;
import com.couchbase.lite.ListenerPasswordAuthenticator;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogFileConfiguration;
import com.couchbase.lite.LogLevel;
import com.couchbase.lite.Logger;
import com.couchbase.lite.Message;
import com.couchbase.lite.MessageEndpoint;
import com.couchbase.lite.MessageEndpointConnection;
import com.couchbase.lite.MessageEndpointDelegate;
import com.couchbase.lite.MessageEndpointListener;
import com.couchbase.lite.MessageEndpointListenerConfiguration;
import com.couchbase.lite.MessagingCloseCompletion;
import com.couchbase.lite.MessagingCompletion;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Parameters;
import com.couchbase.lite.PredictionFunction;
import com.couchbase.lite.PredictiveIndex;
import com.couchbase.lite.PredictiveModel;
import com.couchbase.lite.ProtocolType;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.ReplicatedDocument;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorConnection;
import com.couchbase.lite.ReplicatorStatus;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.SessionAuthenticator;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;
import com.couchbase.lite.ValueIndex;
import com.couchbase.lite.ValueIndexConfiguration;
import com.couchbase.lite.ValueIndexItem;
import com.couchbase.lite.Where;


@SuppressWarnings({"unused", "ConstantConditions"})
public class Examples {
    private static final String TAG = "EXAMPLE";

    private static final String DATABASE_NAME = "database";

    private final Context context;
    private final Database database;
    private Replicator replicator;

    public Examples(Context context, Database database) {
        this.context = context;
        this.database = database;
    }

    public void test1xAttachments(Document document) {
        // tag::1x-attachment[]
        Dictionary attachments = document.getDictionary("_attachments");
        Blob blob = attachments != null ? attachments.getBlob("avatar") : null;
        byte[] content = blob != null ? blob.getContent() : null;
        // end::1x-attachment[]
    }

    // ### Initializer
    public void testInitializer() {
        // tag::sdk-initializer[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context);
        // end::sdk-initializer[]
    }

    // ### New Database
    public void testNewDatabase() throws CouchbaseLiteException {
        // tag::new-database[]
        final DatabaseConfiguration config = new DatabaseConfiguration();
        config.setDirectory(context.getFilesDir().getAbsolutePath()); // <.>

        Database database = new Database("my-database", config);
        // end::new-database[]

        // tag::close-database[]
        database.close();

        // end::close-database[]

        database.delete();
    }

    // ### Database Encryption
    public void testDatabaseEncryption() throws CouchbaseLiteException {
        // tag::database-encryption[]
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setEncryptionKey(new EncryptionKey("PASSWORD"));
        Database database = new Database("mydb", config);
        // end::database-encryption[]
    }

    // ### Logging
    public void testLogging() {
        // tag::logging[]
        Database.log.getConsole().setLevel(LogLevel.VERBOSE);
        Database.log.getFile().setLevel(LogLevel.WARNING);
        // end::logging[]
    }

    public void testEnableCustomLogging() {
        // tag::set-custom-logging[]
        Database.log.setCustom(new LogTestLogger(LogLevel.WARNING)); // <.>
        // end::set-custom-logging[]
    }

    // ### Console logging
    public void testConsoleLogging() {
        // tag::console-logging[]
        Database.log.getConsole().setDomains(LogDomain.ALL_DOMAINS);  // <.>
        Database.log.getConsole().setLevel(LogLevel.VERBOSE); // <.>
        // end::console-logging[]
        // tag::console-logging-db[]
        Database.log.getConsole().setDomains(LogDomain.DATABASE, LogDomain.REPLICATOR);

        // end::console-logging-db[]
    }

    // ### File logging
    public void testFileLogging() {
        // tag::file-logging[]
        final File path = context.getCacheDir();

        LogFileConfiguration config =
            new LogFileConfiguration(path.toString()); // <.>
        config.setMaxSize(10240); // <.>
        config.setMaxRotateCount(5); // <.>
        config.setUsePlaintext(false); // <.>
        Database.log.getFile().setConfig(config);
        Database.log.getFile().setLevel(LogLevel.INFO); // <.>
        // end::file-logging[]
    }

    public void writeConsoleLog() {
        // tag::write-console-logmsg[]
        Database.log.getConsole().log(LogLevel.WARNING, LogDomain.REPLICATOR, "Any old log message");
        // end::write-console-logmsg[]
    }

    public void writeCustomLog() {
        // tag::write-custom-logmsg[]
        Database.log.getCustom().log(LogLevel.WARNING, LogDomain.REPLICATOR, "Any old log message");
        // end::write-custom-logmsg[]
    }


    public void writeFileLog() {
        // tag::write-file-logmsg[]
        Database.log.getFile().log(LogLevel.WARNING, LogDomain.REPLICATOR, "Any old log message");
        // end::write-file-logmsg[]
    }


    // ### Loading a pre-built database
    public void testPreBuiltDatabase() throws IOException, CouchbaseLiteException {
        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        // For Android you need to extract it from your
        // assets to a temporary directory and then pass that path to Database.copy()
        DatabaseConfiguration configuration = new DatabaseConfiguration();
        if (!Database.exists("travel-sample", context.getFilesDir())) {
            ZipUtils.unzip(context.getAssets().open("travel-sample.cblite2.zip"), context.getFilesDir());
            File path = new File(context.getFilesDir(), "travel-sample");
            Database.copy(path, "travel-sample", configuration);
        }
        // end::prebuilt-database[]
    }

    // helper methods

    // if db exist, delete it
    private void deleteDB(String name, File dir) {
        // database exist, delete it
        if (Database.exists(name, dir)) {
            // sometimes, db is still in used, wait for a while. Maximum 3 sec
            for (int i = 0; i < 10; i++) {
                try {
                    Database.delete(name, dir);
                    break;
                }
                catch (CouchbaseLiteException ex) {
                    try { Thread.sleep(300); }
                    catch (InterruptedException ignore) { }
                }
            }
        }
    }

    // ### Initializers
    public void testInitializers() {
        // tag::initializer[]
        MutableDocument newTask = new MutableDocument();
        newTask.setString("type", "task");
        newTask.setString("owner", "todo");
        newTask.setDate("createdAt", new Date());
        try {
            database.save(newTask);
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        // end::initializer[]
    }

    // ### Mutability
    public void testMutability() {
        try { database.save(new MutableDocument("xyz")); }
        catch (CouchbaseLiteException ignore) { }

        // tag::update-document[]
        Document document = database.getDocument("xyz");
        MutableDocument mutableDocument = document.toMutable();
        mutableDocument.setString("name", "apples");
        try {
            database.save(mutableDocument);
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        // end::update-document[]
    }

    // ### Typed Accessors
    public void testTypedAccessors() {
        MutableDocument newTask = new MutableDocument();

        // tag::date-getter[]
        newTask.setValue("createdAt", new Date());
        Date date = newTask.getDate("createdAt");
        // end::date-getter[]
    }

    // ### Batch operations
    public void testBatchOperations() {
        // tag::batch[]
        try {
            database.inBatch(() -> {
                for (int i = 0; i < 10; i++) {
                    MutableDocument doc = new MutableDocument();
                    doc.setValue("type", "user");
                    doc.setValue("name", "user " + i);
                    doc.setBoolean("admin", false);
                    try {
                        database.save(doc);
                    }
                    catch (CouchbaseLiteException e) {
                        Log.e(TAG, e.toString());
                    }
                    Log.i(TAG, String.format("saved user document %s", doc.getString("name")));
                }
            });
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        // end::batch[]
    }

    // ### Document Expiration
    public void DocumentExpiration() throws CouchbaseLiteException {
        // tag::document-expiration[]
        // Purge the document one day from now
        Instant ttl = Instant.now().plus(1, ChronoUnit.DAYS);
        database.setDocumentExpiration("doc123", new Date(ttl.toEpochMilli()));

        // Reset expiration
        database.setDocumentExpiration("doc1", null);

        // Query documents that will be expired in less than five minutes
        Instant fiveMinutesFromNow = Instant.now().plus(5, ChronoUnit.MINUTES);
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Meta.expiration.lessThan(Expression.doubleValue(fiveMinutesFromNow.toEpochMilli())));
        // end::document-expiration[]
    }

    public void testDocumentChangeListener() {
        // tag::document-listener[]
        database.addDocumentChangeListener(
            "user.john",
            change -> {
                Document doc = database.getDocument(change.getDocumentID());
                if (doc != null) {
                    Toast.makeText(context, "Status: " + doc.getString("verified_account"), Toast.LENGTH_SHORT).show();
                }
            });
        // end::document-listener[]
    }

    // ### Blobs
    public void testBlobs() throws IOException {
        MutableDocument newTask = new MutableDocument();

        // tag::blob[]
        InputStream is = context.getAssets().open("avatar.jpg"); // <.>
        if (is == null) { return; }
        try {
            Blob blob = new Blob("image/jpeg", is); // <.>
            newTask.setBlob("avatar", blob); // <.>
            database.save(newTask);

            Blob taskBlob = newTask.getBlob("avatar");
            byte[] bytes = taskBlob.getContent();
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, e.toString());
        }
        finally {
            try { is.close(); }
            catch (IOException ignore) { }
        }
        // end::blob[]
    }

    // ### Indexing
    public void testIndexing() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-index[]

            database.createIndex("TypeNameIndex", new ValueIndexConfiguration());

            // end::query-index[]
        }
    }

    public void testIndexingQueryBuilder() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-index_Querybuilder[]
            database.createIndex(
                "TypeNameIndex",
                IndexBuilder.valueIndex(
                    ValueIndexItem.property("type"),
                    ValueIndexItem.property("name")));
            // end::query-index_Querybuilder[]
        }
    }

    // ### SELECT statement
    public void testSelectStatement() {
        {
            // tag::query-select-props[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("type"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")))
                .orderBy(Ordering.expression(Meta.id));

            try {
                ResultSet rs = query.execute();
                for (Result result: rs) {
                    Log.i("Sample", String.format("hotel id -> %s", result.getString("id")));
                    Log.i("Sample", String.format("hotel name -> %s", result.getString("name")));
                }
            }
            catch (CouchbaseLiteException e) {
                Log.e("Sample", e.getLocalizedMessage());
            }
            // end::query-select-props[]
        }
    }

    // META function
    public void testMetaFunction() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-select-meta[]
            Query query = QueryBuilder
                .select(SelectResult.expression(Meta.id))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("airport")))
                .orderBy(Ordering.expression(Meta.id));
            ResultSet rs = query.execute();
            for (Result result: rs) {
                Log.w("Sample", String.format("airport id -> %s", result.getString("id")));
                Log.w("Sample", String.format("airport id -> %s", result.getString(0)));
            }
            // end::query-select-meta[]
        }
    }

    // ### all(*)
    public void testSelectAll() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-select-all[]
            Query queryAll = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")));
            // end::query-select-all[]

            // tag::live-query[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database)); // <.>

            // Adds a query change listener.
            // Changes will be posted on the main queue.
            ListenerToken token = query.addChangeListener(change -> { // <.>
                for (Result result: change.getResults()) {
                    Log.d(TAG, "results: " + result.getKeys());
                    /* Update UI */
                }
            });

            // end::live-query[]

            // tag::stop-live-query[]
            query.removeChangeListener(token); // <.>

            // end::stop-live-query[]

            try (ResultSet rs = query.execute()) {
                for (Result result: rs) {
                    Log.i(
                        "Sample",
                        String.format("hotel -> %s", result.getDictionary(DATABASE_NAME).toMap()));
                }
            }
        }
    }

    // ###　WHERE statement
    public void testWhereStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-where[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")))
                .limit(Expression.intValue(10));
            ResultSet rs = query.execute();
            for (Result result: rs) {
                Dictionary all = result.getDictionary(DATABASE_NAME);
                Log.i("Sample", String.format("name -> %s", all.getString("name")));
                Log.i("Sample", String.format("type -> %s", all.getString("type")));
            }
            // end::query-where[]
        }
    }

    public void testQueryDeletedDocuments() {
        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        Where query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Meta.deleted);
        // end::query-deleted-documents[]
    }


    // ####　Collection Operators
    public void testCollectionStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-collection-operator-contains[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("public_likes"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel"))
                    .and(ArrayFunction
                        .contains(Expression.property("public_likes"), Expression.string("Armani Langworth"))));
            ResultSet rs = query.execute();
            for (Result result: rs) {
                Log.i(
                    "Sample",
                    String.format("public_likes -> %s", result.getArray("public_likes").toList()));
            }
            // end::query-collection-operator-contains[]
        }
    }

    // IN operator
    public void testInOperator() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-collection-operator-in[]
            Expression[] values = new Expression[] {
                Expression.property("first"),
                Expression.property("last"),
                Expression.property("username")
            };

            Query query = QueryBuilder.select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.string("Armani").in(values));
            // end::query-collection-operator-in[]

            ResultSet rs = query.execute();
            for (Result result: rs) { Log.w("Sample", result.toMap().toString()); }
        }
    }

    // Pattern Matching
    public void testPatternMatching() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-like-operator[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name"))
                        .like(Expression.string("royal engineers museum"))));
            ResultSet rs = query.execute();
            for (Result result: rs) { Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-like-operator[]
        }
    }

    // ### Wildcard Match
    public void testWildcardMatch() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-like-operator-wildcard-match[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name")).like(Expression.string("eng%e%"))));
            ResultSet rs = query.execute();
            for (Result result: rs) { Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-like-operator-wildcard-match[]
        }
    }

    // Wildcard Character Match
    public void testWildCharacterMatch() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-like-operator-wildcard-character-match[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name")).like(Expression.string("eng____r"))));
            ResultSet rs = query.execute();
            for (Result result: rs) { Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-like-operator-wildcard-character-match[]
        }
    }

    // ### Regex Match
    public void testRegexMatch() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-regex-operator[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("country"),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(Function.lower(Expression.property("name")).regex(Expression.string("\\beng.*r\\b"))));
            ResultSet rs = query.execute();
            for (Result result: rs) { Log.i("Sample", String.format("name -> %s", result.getString("name"))); }
            // end::query-regex-operator[]
        }
    }

    // JOIN statement
    public void testJoinStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-join[]
            Query query = QueryBuilder.select(
                    SelectResult.expression(Expression.property("name").from("airline")),
                    SelectResult.expression(Expression.property("callsign").from("airline")),
                    SelectResult.expression(Expression.property("destinationairport").from("route")),
                    SelectResult.expression(Expression.property("stops").from("route")),
                    SelectResult.expression(Expression.property("airline").from("route")))
                .from(DataSource.database(database).as("airline"))
                .join(Join.join(DataSource.database(database).as("route"))
                    .on(Meta.id.from("airline").equalTo(Expression.property("airlineid").from("route"))))
                .where(Expression.property("type").from("route").equalTo(Expression.string("route"))
                    .and(Expression.property("type").from("airline").equalTo(Expression.string("airline")))
                    .and(Expression.property("sourceairport").from("route").equalTo(Expression.string("RIX"))));
            ResultSet rs = query.execute();
            for (Result result: rs) { Log.w("Sample", result.toMap().toString()); }
            // end::query-join[]
        }
    }

    // ### GROUPBY statement
    public void testGroupByStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-groupby[]
            Query query = QueryBuilder.select(
                    SelectResult.expression(Function.count(Expression.string("*"))),
                    SelectResult.property("country"),
                    SelectResult.property("tz"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("airport"))
                    .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300))))
                .groupBy(
                    Expression.property("country"),
                    Expression.property("tz"))
                .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending());
            ResultSet rs = query.execute();
            for (Result result: rs) {
                Log.i(
                    "Sample",
                    String.format(
                        "There are %d airports on the %s timezone located in %s and above 300ft",
                        result.getInt("$1"),
                        result.getString("tz"),
                        result.getString("country")));
            }
            // end::query-groupby[]
        }
    }

    // ### ORDER BY statement
    public void testOrderByStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-orderby[]
            Query query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel")))
                .orderBy(Ordering.property("name").ascending())
                .limit(Expression.intValue(10));
            ResultSet rs = query.execute();
            for (Result result: rs) { Log.i("Sample", String.format("%s", result.toMap())); }
            // end::query-orderby[]
        }
    }

    // ### EXPLAIN statement
    public void testExplainStatement() throws CouchbaseLiteException {
        // For Documentation
        {
            // tag::query-explain-all[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("university")))
                .groupBy(Expression.property("country"))
                .orderBy(Ordering.property("name").descending()); // <.>
            Log.i(TAG, query.explain()); // <.>
            // end::query-explain-all[]
        }
        {
            // tag::query-explain-like[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").like(Expression.string("%hotel%"))); // <.>
            Log.i(TAG, query.explain());
            // end::query-explain-like[]
        }
        {
            // tag::query-explain-nopfx[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));
            Log.i(TAG, query.explain());
            // end::query-explain-nopfx[]
        }
        {
            // tag::query-explain-function[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))); // <.>
            Log.i(TAG, query.explain());
            // end::query-explain-function[]
        }
        {
            // tag::query-explain-nofunction[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("hotel"))); // <.>
            Log.i(TAG, query.explain());
            // end::query-explain-nofunction[]
        }
    }
    // end query-explain

    void prepareIndex() throws CouchbaseLiteException {
        // tag::fts-index[]

        FullTextIndexConfiguration config = new FullTextIndexConfiguration("Overview").ignoreAccents(false);

        database.createIndex("overviewFTSIndex", config);

        // end::fts-index[]
    }

    void prepareIndexQueryBuilder() throws CouchbaseLiteException {
        // tag::fts-index_Querybuilder[]
        database.createIndex(
            "overviewFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("overview")).ignoreAccents(false));
        // end::fts-index_Querybuilder[]
    }

    public void testFTS() throws CouchbaseLiteException {
        // tag::fts-query[]

        Query ftsQuery =
            database.createQuery(
                "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK"
                    + "(overviewFTSIndex)");

        for (Result result: ftsQuery.execute().allResults()) {
            Log.i(TAG, result.getString("id") + ": " + result.getString("overview"));
        }

        // end::fts-query[]
    }

    public void testFTSQueryBuilder(String overview) throws CouchbaseLiteException {
        // tag::fts-query_Querybuilder[]
        Query ftsQuery =
            QueryBuilder.select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property(overview)
                )
                .from(DataSource.database(database))
                .where(FullTextFunction.match("overviewFTSIndex", "'michigan'"));

        for (Result result: ftsQuery.execute().allResults()) {
            Log.i(TAG, result.getString("id" + ": " + result.getString("overview")));
        }

        // end::fts-query_Querybuilder[]
    }

    /* The `tag::replication[]` example is inlined in java.adoc */

    public void testTroubleshooting() {
        // tag::replication-logging[]
        Database.log.getConsole().setLevel(LogLevel.VERBOSE);
        // end::replication-logging[]
    }

    public void testReplicationBasicAuthentication() throws URISyntaxException {
        // tag::basic-authentication[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setAuthenticator(new BasicAuthenticator("username", "password".toCharArray()));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::basic-authentication[]
    }

    public void testReplicationSessionAuthentication() throws URISyntaxException {
        // tag::session-authentication[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setAuthenticator(new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447"));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::session-authentication[]
    }

    public void testReplicationStatus() throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::replication-status[]
        replicator.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == ReplicatorActivityLevel.STOPPED) {
                Log.i(TAG, "Replication stopped");
            }
        });
        // end::replication-status[]
    }

    @SuppressWarnings({"unused", "ConstantConditions"})
    static class PendingDocsExample {
        private static final String TAG = "SCRATCH";

        private Database database;
        private Replicator replicator;

        //  BEGIN PendingDocuments IB -- 11/Feb/21 --
        public void testReplicationPendingDocs() throws URISyntaxException, CouchbaseLiteException {
            // nottag::replication-pendingdocuments[]
            // ... include other code as required
            //
            final Endpoint endpoint =
                new URLEndpoint(new URI("ws://localhost:4984/db"));

            final ReplicatorConfiguration config =
                new ReplicatorConfiguration(database, endpoint)
                    .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH);
            // tag::replication-push-pendingdocumentids[]

            replicator = new Replicator(config);
            final Set<String> pendingDocs =
                replicator.getPendingDocumentIds(); // <.>

            // end::replication-push-pendingdocumentids[]

            replicator.addChangeListener(change -> onStatusChanged(pendingDocs, change.getStatus()));

            replicator.start();

            // ... include other code as required
            // notend::replication-pendingdocuments[]
        }

        //
        // tag::replication-pendingdocuments[]
        //
        private void onStatusChanged(
            @NonNull final Set<String> pendingDocs,
            @NonNull final ReplicatorStatus status) {
            // ... sample onStatusChanged function
            //
            Log.i(TAG, "Replicator activity level is " + status.getActivityLevel());

            // iterate and report-on previously
            // retrieved pending docids 'list'
            for (Iterator<String> itr = pendingDocs.iterator(); itr.hasNext(); ) {
                final String docId = itr.next();
                try {
                    // tag::replication-push-isdocumentpending[]
                    if (!replicator.isDocumentPending(docId)) { continue; } // <.>
                    // end::replication-push-isdocumentpending[]

                    itr.remove();
                    Log.i(TAG, "Doc ID " + docId + " has been pushed");
                }
                catch (CouchbaseLiteException e) {
                    Log.w(TAG, "isDocumentPending failed", e);
                }
            }
        }
        // end::replication-pendingdocuments[]
        //  END PendingDocuments BM -- 19/Feb/21 --
    }


    public void testHandlingNetworkErrors() throws URISyntaxException {
        Endpoint endpoint = new URLEndpoint(new URI("ws://localhost:4984/db"));
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::replication-error-handling[]
        replicator.addChangeListener(change -> {
            CouchbaseLiteException error = change.getStatus().getError();
            if (error != null) { Log.w(TAG, "Error code:: %d", error); }
        });
        replicator.start();
        // end::replication-error-handling[]

        replicator.stop();
    }

    public void testReplicatorDocumentEvent() throws URISyntaxException {
        Endpoint endpoint = new URLEndpoint(new URI("ws://localhost:4984/db"));
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::add-document-replication-listener[]
        ListenerToken token = replicator.addDocumentReplicationListener(replication -> {

            Log.i(TAG, "Replication type: " + ((replication.isPush()) ? "Push" : "Pull"));
            for (ReplicatedDocument document: replication.getDocuments()) {
                Log.i(TAG, "Doc ID: " + document.getID());

                CouchbaseLiteException err = document.getError();
                if (err != null) {
                    // There was an error
                    Log.e(TAG, "Error replicating document: ", err);
                    return;
                }

                if (document.getFlags().contains(DocumentFlag.DELETED)) {
                    Log.i(TAG, "Successfully replicated a deleted document");
                }
            }
        });

        replicator.start();
        // end::add-document-replication-listener[]

        // tag::remove-document-replication-listener[]
        replicator.removeChangeListener(token);
        // end::remove-document-replication-listener[]
    }

    public void testReplicationCustomHeader() throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);

        // tag::replication-custom-header[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        Map<String, String> headers = new HashMap<>();
        headers.put("CustomHeaderName", "Value");
        config.setHeaders(headers);
        // end::replication-custom-header[]
    }

    // ### Certificate Pinning

    public void testCertificatePinning() throws URISyntaxException, KeyStoreException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);

        // tag::certificate-pinning[]
        KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
        Certificate cert = ks.getCertificate("certAlias");

        config.setPinnedServerX509Certificate((X509Certificate) cert);
        // end::certificate-pinning[]
    }

    // ### Reset replicator checkpoint
    public void testReplicationResetCheckpoint(boolean shouldReset) throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);

        // tag::replication-reset-checkpoint[]
        replicator.start(shouldReset); // <.>
        // end::replication-reset-checkpoint[]

        // ... at some later time

        replicator.stop();
    }

    public void testReplicationPushFilter() throws URISyntaxException {
        // tag::replication-push-filter[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setPushFilter((document, flags) -> flags.contains(DocumentFlag.DELETED)); // <1>

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::replication-push-filter[]
    }

    public void testReplicationPullFilter() throws URISyntaxException {
        // tag::replication-pull-filter[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setPullFilter((document, flags) -> "draft".equals(document.getString("type"))); // <1>

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(config);
        replicator.start();
        // end::replication-pull-filter[]
    }

    public void testCustomRetryConfig() throws URISyntaxException {
        // tag::replication-retry-config[]
        URLEndpoint target =
            new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config =
            new ReplicatorConfiguration(database, target);

        //  other config as required . . .
        // tag::replication-heartbeat-config[]
        config.setHeartbeat(150); // <.>
        // end::replication-heartbeat-config[]
        // tag::replication-maxattempts-config[]
        config.setMaxAttempts(20); // <.>
        // end::replication-maxattempts-config[]
        // tag::replication-maxattemptwaittime-config[]
        config.setMaxAttemptWaitTime(600); // <.>
        // end::replication-maxattemptwaittime-config[]

        Replicator repl = new Replicator(config);

        // end::replication-retry-config[]
    }


    public void docsSetAutoPurge(Endpoint target) throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database1 = new Database("mydb", config);

        ReplicatorConfiguration repcfg =
            new ReplicatorConfiguration(database, target);

        repcfg.setAutoPurgeEnabled(true); // <.>
    }


    public void testDatabaseReplica() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database1 = new Database("mydb", config);

        config = new DatabaseConfiguration();
        Database database2 = new Database("db2", config);

        /* EE feature: code below might throw a compilation error
           if it's compiled against CBL Android Community. */
        // tag::database-replica[]
        DatabaseEndpoint targetDatabase = new DatabaseEndpoint(database2);
        ReplicatorConfiguration replicatorConfig = new ReplicatorConfiguration(database1, targetDatabase);
        replicatorConfig.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH);

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        replicator = new Replicator(replicatorConfig);
        replicator.start();
        // end::database-replica[]
    }

    public void testPredictiveModel() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database = new Database("mydb", config);

        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", new ImageClassifierModel());
        // end::register-model[]

        // tag::predictive-query-value-index[]
        ValueIndex index = IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")));
        database.createIndex("value-index-image-classifier", index);
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier");
        // end::unregister-model[]
    }

    public void testPredictiveIndex() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database = new Database("mydb", config);

        // tag::predictive-query-predictive-index[]
        Map<String, Object> inputMap = new HashMap<>();
        inputMap.put("numbers", Expression.property("photo"));
        Expression input = Expression.map(inputMap);

        PredictiveIndex index = IndexBuilder.predictiveIndex("ImageClassifier", input, null);
        database.createIndex("predictive-index-image-classifier", index);
        // end::predictive-query-predictive-index[]
    }

    private static class MyModel implements PredictiveModel {

        @Nullable
        @Override
        public Dictionary predict(@NonNull Dictionary input) {
            return null;
        }
    }

    public void testPredictiveQuery() throws CouchbaseLiteException {
        DatabaseConfiguration config = new DatabaseConfiguration();
        Database database = new Database("mydb", config);

        // tag::predictive-query[]
        PredictiveModel model = new MyModel();
        Database.prediction.registerModel("myModel", model);

        Map<String, Object> inputProperties = new HashMap<>();
        inputProperties.put("photo", Expression.property("photo"));
        Expression input = Expression.map(inputProperties);
        PredictionFunction prediction = Function.prediction("myModel", input); // <1>

        Query query = QueryBuilder
            .select(SelectResult.expression(prediction))
            .from(DataSource.database(database))
            .where(Expression.property("label").equalTo(Expression.string("car"))
                .and(Expression.property("probability").greaterThanOrEqualTo(Expression.doubleValue(0.8))));

        // Run the query.
        ResultSet result = query.execute();
        Log.d(TAG, "Number of rows: " + result.allResults().size());
        // end::predictive-query[]
    }

    public void testReplicationWithCustomConflictResolver() throws URISyntaxException {
        // tag::replication-conflict-resolver[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, target);
        config.setConflictResolver(new LocalWinConflictResolver());

        Replicator replication = new Replicator(config);
        replication.start();
        // end::replication-conflict-resolver[]
    }

    public void testSaveWithCustomConflictResolver() throws CouchbaseLiteException {
        // tag::update-document-with-conflict-handler[]
        Document doc = database.getDocument("xyz");
        if (doc == null) { return; }
        MutableDocument mutableDocument = doc.toMutable();
        mutableDocument.setString("name", "apples");

        database.save(
            mutableDocument,
            (newDoc, curDoc) -> { // <.>
                if (curDoc == null) { return false; } // <.>
                Map<String, Object> dataMap = curDoc.toMap();
                dataMap.putAll(newDoc.toMap()); // <.>
                newDoc.setData(dataMap);
                return true; // <.>
            }); // <.>
        // end::update-document-with-conflict-handler[]
    }
}

// tag::update-document-with-conflict-handler-callouts[]

//<.> The conflict handler code is provided as a lambda.
//
//<.> If the handler cannot resolve a conflict, it can return false.
//In this case, the save method will cancel the save operation and return false the same way as using the save()
// method with the failOnConflict concurrency control.
//
//<.> Within the conflict handler, you can modify the document parameter which is the same instance of Document that
// is passed to the save() method. So in effect, you will be directly modifying the document that is being saved.
//
//<.> When handling is done, the method must return true (for  successful resolution) or false (if it was unable to
// resolve the conflict).
//
//<.> If there is an exception thrown in the handle() method, the exception will be caught and re-thrown in the save
// () method
// end::update-document-with-conflict-handler-callouts[]


@SuppressWarnings({"unused", "ConstantConditions"})
// tag::local-win-conflict-resolver[]
// Using replConfig.setConflictResolver(new LocalWinConflictResolver());
class LocalWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getLocalDocument();
    }
}
// end::local-win-conflict-resolver[]


@SuppressWarnings({"unused", "ConstantConditions"})
// tag::remote-win-conflict-resolver[]
// Using replConfig.setConflictResolver(new RemoteWinConflictResolver());
class RemoteWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getRemoteDocument();
    }
}
// end::remote-win-conflict-resolver[]


@SuppressWarnings({"unused", "ConstantConditions"})
// tag::merge-conflict-resolver[]
// Using replConfig.setConflictResolver(new MergeConflictResolver());
class MergeConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        Map<String, Object> merge = conflict.getLocalDocument().toMap();
        merge.putAll(conflict.getRemoteDocument().toMap());
        return new MutableDocument(conflict.getDocumentId(), merge);
    }
}
// end::merge-conflict-resolver[]


/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ----------------------------------------------------------- */

@SuppressWarnings({"unused", "ConstantConditions"})
class BrowserSessionManager implements MessageEndpointDelegate {
    public void initCouchbase() throws CouchbaseLiteException {
        // tag::message-endpoint[]
        DatabaseConfiguration databaseConfiguration = new DatabaseConfiguration();
        Database database = new Database("mydb", databaseConfiguration);

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        MessageEndpoint messageEndpointTarget = new MessageEndpoint(
            "UID:123",
            "active",
            ProtocolType.MESSAGE_STREAM,
            this);
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, messageEndpointTarget);

        // Create the replicator object.
        Replicator replicator = new Replicator(config);
        // Start the replication.
        replicator.start();
        // end::message-endpoint-replicator[]
    }

    // tag::create-connection[]
    /* implementation of MessageEndpointDelegate */
    @NonNull
    @Override
    public MessageEndpointConnection createConnection(@NonNull MessageEndpoint endpoint) {
        return new ActivePeerConnection(); /* implements MessageEndpointConnection */
    }
    // end::create-connection[]
}

@SuppressWarnings({"unused", "ConstantConditions"})
class ActivePeerConnection implements MessageEndpointConnection {

    private ReplicatorConnection replicatorConnection;

    public void disconnect() {
        // tag::active-replicator-close[]
        replicatorConnection.close(null);
        // end::active-replicator-close[]
    }

    // tag::active-peer-open[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void open(@NonNull ReplicatorConnection connection, @NonNull MessagingCompletion completion) {
        replicatorConnection = connection;
        completion.complete(true, null);
    }
    // end::active-peer-open[]

    // tag::active-peer-close[]
    @Override
    public void close(Exception error, @NonNull MessagingCloseCompletion completion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete();
    }
    // end::active-peer-close[]

    // tag::active-peer-send[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void send(@NonNull Message message, @NonNull MessagingCompletion completion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null);
    }
    // end::active-peer-send[]

    public void receive(Message message) {
        // tag::active-peer-receive[]
        replicatorConnection.receive(message);
        // end::active-peer-receive[]
    }
}

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ----------------------------------------------------------- */

@SuppressWarnings({"unused", "ConstantConditions"})
class PassivePeerConnection implements MessageEndpointConnection {
    private final Context context;

    private MessageEndpointListener messageEndpointListener;
    private ReplicatorConnection replicatorConnection;

    private PassivePeerConnection(Context context) { this.context = context; }

    public void startListener() throws CouchbaseLiteException {
        // tag::listener[]
        DatabaseConfiguration databaseConfiguration = new DatabaseConfiguration();
        Database database = new Database("mydb", databaseConfiguration);
        MessageEndpointListenerConfiguration listenerConfiguration = new MessageEndpointListenerConfiguration(
            database,
            ProtocolType.MESSAGE_STREAM);
        this.messageEndpointListener = new MessageEndpointListener(listenerConfiguration);
        // end::listener[]
    }

    public void stopListener() {
        // tag::passive-stop-listener[]
        messageEndpointListener.closeAll();
        // end::passive-stop-listener[]
    }

    public void accept() {
        // tag::advertizer-accept[]
        PassivePeerConnection connection = new PassivePeerConnection(context); /* implements
        MessageEndpointConnection */
        messageEndpointListener.accept(connection);
        // end::advertizer-accept[]
    }

    public void disconnect() {
        // tag::passive-replicator-close[]
        replicatorConnection.close(null);
        // end::passive-replicator-close[]
    }

    // tag::passive-peer-open[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void open(@NonNull ReplicatorConnection connection, @NonNull MessagingCompletion completion) {
        replicatorConnection = connection;
        completion.complete(true, null);
    }
    // end::passive-peer-open[]

    // tag::passive-peer-close[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void close(Exception error, @NonNull MessagingCloseCompletion completion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete();
    }
    // end::passive-peer-close[]

    // tag::passive-peer-send[]
    /* implementation of MessageEndpointConnection */
    @Override
    public void send(@NonNull Message message, @NonNull MessagingCompletion completion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null);
    }
    // end::passive-peer-send[]

    public void receive(Message message) {
        // tag::passive-peer-receive[]
        replicatorConnection.receive(message);
        // end::passive-peer-receive[]
    }
}

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::predictive-model[]
// tensorFlowModel is a fake implementation
// this would be the implementation of the ml model you have chosen
class ImageClassifierModel implements PredictiveModel {
    @Override
    public Dictionary predict(@NonNull Dictionary input) {
        Blob blob = input.getBlob("photo");
        if (blob == null) { return null; }

        // tensorFlowModel is a fake implementation
        // this would be the implementation of the ml model you have chosen
        return new MutableDictionary(TensorFlowModel.predictImage(blob.getContent())); // <1>
    }
}

@SuppressWarnings({"unused", "ConstantConditions"})
class TensorFlowModel {
    public static Map<String, Object> predictImage(byte[] data) {
        return null;
    }
}
// end::predictive-model[]

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::custom-logging[]
class LogTestLogger implements Logger {
    @NonNull
    private final LogLevel level;

    public LogTestLogger(@NonNull LogLevel level) { this.level = level; }

    @NonNull
    @Override
    public LogLevel getLevel() { return level; }

    @Override
    public void log(@NonNull LogLevel level, @NonNull LogDomain domain, @NonNull String message) {
    }
}
// end::custom-logging[]



@SuppressWarnings({"unused", "ConstantConditions"})
// tag::certAuthListener-full[]
class CertAuthListener {
    private static final String TAG = "PWD";

    private static final Map<String, String> CERT_ATTRIBUTES;
    static {
        final Map<String, String> m = new HashMap<>();
        m.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "CBL Test");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
        m.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "lite@couchbase.com");
        CERT_ATTRIBUTES = Collections.unmodifiableMap(m);
    }
    // start a server and connect to it with a replicator
    public void run() throws CouchbaseLiteException, IOException {
        final Database localDb = new Database("localDb");
        MutableDocument doc = new MutableDocument();
        doc.setString("dog", "woof");
        localDb.save(doc);

        Database remoteDb = new Database("remoteDb");
        doc = new MutableDocument();
        doc.setString("cat", "meow");
        localDb.save(doc);

        TLSIdentity serverIdentity = TLSIdentity.createIdentity(true, CERT_ATTRIBUTES, null, "server");
        TLSIdentity clientIdentity = TLSIdentity.createIdentity(false, CERT_ATTRIBUTES, null, "client");

        final URI uri = startServer(remoteDb, serverIdentity, clientIdentity.getCerts());
        if (uri == null) { throw new IOException("Failed to start the server"); }

        new Thread(() -> {
            try {
                startClient(uri, serverIdentity.getCerts().get(0), clientIdentity, localDb);
                Log.e(TAG, "Success!!");
                deleteIdentity("server");
                Log.e(TAG, "Alias deleted: server");
                deleteIdentity("client");
                Log.e(TAG, "Alias deleted: client");
            }
            catch (Exception e) { Log.e(TAG, "Failed!!", e); }
        }).start();
    }

    // start a client replicator
    public void startClient(
        @NonNull URI uri,
        @NonNull Certificate cert,
        @NonNull TLSIdentity clientIdentity,
        @NonNull Database db) throws CertificateEncodingException, InterruptedException {
        final ReplicatorConfiguration config = new ReplicatorConfiguration(db, new URLEndpoint(uri));
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);
        config.setContinuous(false);

        configureClientCerts(config, cert, clientIdentity);

        final CountDownLatch completionLatch = new CountDownLatch(1);
        final Replicator repl = new Replicator(config);
        repl.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == ReplicatorActivityLevel.STOPPED) {
                completionLatch.countDown();
            }
        });

        repl.start(false);
        completionLatch.await();
    }
    // tag::listener-config-auth-cert-full[]

    /**
     * Snippet 2: create a ListenerCertificateAuthenticator and configure the listener with it
     * <p>
     * Start a listener for db that accepts connections from a client identified by any of the passed certs
     *
     * @param db    the database to which the listener is attached
     * @param certs the name of the single valid user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Nullable
    public URI startServer(@NonNull Database db, @NonNull TLSIdentity serverId, @NonNull List<Certificate> certs)
        throws CouchbaseLiteException {
        final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(db);

        config.setPort(0); // this is the default
        config.setDisableTls(false);
        config.setTlsIdentity(serverId);
        config.setAuthenticator(new ListenerCertificateAuthenticator(certs));

        final URLEndpointListener listener = new URLEndpointListener(config);
        listener.start();

        final List<URI> urls = listener.getUrls();
        if (urls.isEmpty()) { return null; }
        return urls.get(0);
    }
    // end::listener-config-auth-cert-full[]
    // tag::listener-config-delete-cert-full[]

    /**
     * Delete an identity from the keystore
     *
     * @param alias the alias for the identity to be deleted
     */
    public void deleteIdentity(String alias)
        throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException {

        final KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);

        keyStore.deleteEntry(alias); // <.>
    }
    // end::listener-config-delete-cert-full[]

    // nottag::p2p-tlsid-tlsidentity-with-label[]
    /* Configure Client (active) side certificates
     * @param config         The replicator configuration
     * @param cert           The expected server side certificate
     * @param clientIdentity the identity offered to the server as authentication
     * @throws CertificateEncodingException on certifcate encoding error
     */
    private void configureClientCerts(
        ReplicatorConfiguration config,
        @NonNull Certificate cert,
        @NonNull TLSIdentity clientIdentity)
        throws CertificateEncodingException {

        // Create an authenticator that provides the client identity
        config.setAuthenticator(new ClientCertificateAuthenticator(clientIdentity));

        // Configure the pinned certificate passing a byte array.
        config.setPinnedServerCertificate(cert.getEncoded());
    }
    // notend::p2p-tlsid-tlsidentity-with-label[]

    /**
     * Copy a cert from a resource bundle
     *
     * @param context Android context
     * @param resId   resource id for resource: R.id.foo
     * @throws IOException on copy error
     */
    private byte[] readCertMaterialFromBundle(@NonNull Context context, int resId) throws IOException {
        final ByteArrayOutputStream out = new ByteArrayOutputStream();
        final InputStream in = context.getResources().openRawResource(resId);
        final byte[] buf = new byte[1024];
        int n;
        while ((n = in.read(buf)) >= 0) { out.write(buf, 0, n); }
        return out.toByteArray();
    }
}
// end::certAuthListener-full[]




@SuppressWarnings({"unused", "ConstantConditions"})
// tag::passwordAuthListener-full[]
class PasswordAuthListener {
    private static final String TAG = "PWD";

    // start a server and connect to it with a replicator
    public void run() throws CouchbaseLiteException, IOException {
        final Database localDb = new Database("localDb");
        MutableDocument doc = new MutableDocument();
        doc.setString("dog", "woof");
        localDb.save(doc);

        Database remoteDb = new Database("remoteDb");
        doc = new MutableDocument();
        doc.setString("cat", "meow");
        localDb.save(doc);

        final URI uri = startServer(remoteDb, "fox", "wa-pa-pa-pa-pa-pow".toCharArray());
        if (uri == null) { throw new IOException("Failed to start the server"); }

        new Thread(() -> {
            try {
                runClient(uri, "fox", "wa-pa-pa-pa-pa-pow".toCharArray(), localDb);
                Log.e(TAG, "Success!!");
            }
            catch (Exception e) { Log.e(TAG, "Failed!!", e); }
        }).start();
    }

    // start a client replicator
    public void runClient(
        @NonNull URI uri,
        @NonNull String username,
        @NonNull char[] password,
        @NonNull Database db) throws InterruptedException {
        final ReplicatorConfiguration config = new ReplicatorConfiguration(db, new URLEndpoint(uri));
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);
        config.setContinuous(false);
        config.setAuthenticator(new BasicAuthenticator(username, password));

        final CountDownLatch completionLatch = new CountDownLatch(1);
        final Replicator repl = new Replicator(config);
        repl.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == ReplicatorActivityLevel.STOPPED) {
                completionLatch.countDown();
            }
        });

        repl.start(false);
        completionLatch.await();
    }
    // tag::listener-config-client-auth-pwd-full[]

    /**
     * Start a listener for db that accepts connections using exactly the passed username and password
     *
     * @param db       the database to which the listener is attached
     * @param username the name of the single valid user
     * @param password the password for the user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Nullable
    public URI startServer(@NonNull Database db, @NonNull String username, @NonNull char[] password)
        throws CouchbaseLiteException {
        final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(db);

        config.setPort(0); // this is the default
        config.setDisableTls(true);
        config.setAuthenticator(new ListenerPasswordAuthenticator(
            (validUser, pwd) -> username.equals(validUser) && Arrays.equals(password, pwd)));

        final URLEndpointListener listener = new URLEndpointListener(config);
        listener.start();

        final List<URI> urls = listener.getUrls();
        if (urls.isEmpty()) { return null; }
        return urls.get(0);
    }
    // end::listener-config-client-auth-pwd-full[]
}


// end::passwordAuthListener-full[]


@SuppressWarnings({"unused", "ConstantConditions"})
class ReplicationExamples {
    private static final String TAG = "EXAMPLE ACTIVE PEER";
    private static final String VALID_USER = "sync9455";
    private static final String VALID_PASSWORD = "sync9455";


    private Context context;
    private Replicator thisReplicator;
    private Certificate cert;
    private Database thisDB;

    private boolean isWhitelistedUser(String s, char[] chars) { return true; }


    // PASSIVE PEER STUFF
// Stuff I adapted
//
// BEGIN new stuff 90420temp cache
    private URLEndpointListener createListener() {
        final URLEndpointListenerConfiguration listenerConfig = new URLEndpointListenerConfiguration(thisDB);

        listenerConfig.setDisableTls(false);

        listenerConfig.setEnableDeltaSync(true);

        listenerConfig.setTlsIdentity(null); // Use with anonymous self signed cert

        listenerConfig.setAuthenticator(new ListenerPasswordAuthenticator(this::isWhitelistedUser));

        return new URLEndpointListener(listenerConfig);
    }

    public void startListener(@NotNull URLEndpointListener listener) throws CouchbaseLiteException {
        listener.start();
    }

    private void stopListener(@NotNull URLEndpointListener listener) {
        listener.stop();
    }
// END new stuff 90420temp cache


    private void ibListenerSimple() throws CouchbaseLiteException {
        // tag::listener-simple[]
        final URLEndpointListenerConfiguration thisConfig =
            new URLEndpointListenerConfiguration(thisDB); // <.>

        thisConfig.setAuthenticator(
            new ListenerPasswordAuthenticator(
                (username, password) ->
                    username.equals("valid.User") &&
                        Arrays.equals(password, VALID_PASSWORD.toCharArray())
            )
        ); // <.>

        final URLEndpointListener thisListener =
            new URLEndpointListener(thisConfig); // <.>

        thisListener.start(); // <.>

        // end::listener-simple[]
    }

    private void ibReplicatorSimple() throws URISyntaxException {
        // tag::replicator-simple[]
        URI uri = new URI("wss://10.0.2.2:4984/db");
        Endpoint theListenerEndpoint = new URLEndpoint(uri); // <.>

        ReplicatorConfiguration thisConfig =
            new ReplicatorConfiguration(thisDB, theListenerEndpoint); // <.>

        thisConfig.setAcceptOnlySelfSignedServerCertificate(true); // <.>

        final BasicAuthenticator thisAuth
            = new BasicAuthenticator(
            "valid.user",
            VALID_PASSWORD.toCharArray());
        thisConfig.setAuthenticator(thisAuth); // <.>

        Replicator replicator = new Replicator(thisConfig); // <.>
        replicator.start(); // <.>

        // end::replicator-simple[]
    }


    private void ibPassListener() throws CouchbaseLiteException {
// EXAMPLE 1
        // tag::listener-initialize[]
        // tag::listener-config-db[]
        // Initialize the listener config
        final URLEndpointListenerConfiguration thisConfig
            = new URLEndpointListenerConfiguration(thisDB); // <.>

        // end::listener-config-db[]
        // tag::listener-config-port[]
        thisConfig.setPort(55990); //<.>

        // end::listener-config-port[]
        // tag::listener-config-netw-iface[]
        thisConfig.setNetworkInterface("10.1.1.10"); // <.>

        // end::listener-config-netw-iface[]
        // tag::listener-config-delta-sync[]
        thisConfig.setEnableDeltaSync(false); // <.>

        // end::listener-config-delta-sync[]
        // tag::listener-config-tls-full[]
        // Configure server security
        // tag::listener-config-tls-enable[]
        thisConfig.setDisableTls(false); // <.>

        // end::listener-config-tls-enable[]
        // tag::listener-config-tls-id-anon[]
        // Use an Anonymous Self-Signed Cert
        thisConfig.setTlsIdentity(null); // <.>

        // end::listener-config-tls-id-anon[]

        // tag::listener-config-client-auth-pwd[]
        // Configure Client Security using an Authenticator
        // For example, Basic Authentication <.>
        thisConfig.setAuthenticator(new ListenerPasswordAuthenticator(
            (username, password) ->
                VALID_USER.equals(username) &&
                    Arrays.equals(VALID_PASSWORD.toCharArray(), password)));

        // end::listener-config-client-auth-pwd[]
        // tag::listener-start[]
        // Initialize the listener
        final URLEndpointListener thisListener
            = new URLEndpointListener(thisConfig); // <.>

        // Start the listener
        thisListener.start(); // <.>

        // end::listener-start[]
        // end::listener-initialize[]
    }

    private void ibListenerGetNetworkInterfaces() throws CouchbaseLiteException {
        // tag::listener-get-network-interfaces[]
        final URLEndpointListenerConfiguration thisConfig =
            new URLEndpointListenerConfiguration(thisDB);
        final URLEndpointListener thisListener
            = new URLEndpointListener(thisConfig);
        thisListener.start();
        Log.i(TAG, "URLS are " + thisListener.getUrls());

        // end::listener-get-network-interfaces[]
    }

    private void ibListenerLocalDb() throws CouchbaseLiteException {
// tag::listener-local-db[]
// . . . preceding application logic . . .
        CouchbaseLite.init(context);  // <.>
        Database thisDB = new Database("passivepeerdb");

// end::listener-local-db[]
    }

    private void ibListenerConfigTlsDisable(URLEndpointListenerConfiguration thisConfig) {
// tag::listener-config-tls-disable[]
        thisConfig.setDisableTls(true); // <.>

// end::listener-config-tls-disable[]
    }

    private void ibListenerConfigTlsDisable2() throws CouchbaseLiteException {

        // tag::listener-config-tls-id-SelfSigned[]
        // Use a self-signed certificate
        // Create a TLSIdentity for the server using convenience API.
        // System generates self-signed cert
        // Work-in-progress. Code snippet coming soon.
        Map<String, String> attrs = new HashMap<>(); //<.>
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "Couchbase Demo");
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "noreply@couchbase.com");

        // Store the TLS identity in secure storage
        // under the label 'couchbase-docs-cert'
        TLSIdentity thisIdentity =
            TLSIdentity.createIdentity(
                true,
                attrs,
                null,
                "couchbase-docs-cert"); // <.>

        // end::listener-config-tls-id-SelfSigned[]
    }

    private void ibListenerConfigTlsIdFull(URLEndpointListenerConfiguration thisConfig, TLSIdentity thisIdentity) {
// tag::listener-config-tls-id-full[]

        // tag::listener-config-tls-id-set[]
        // Set the TLS Identity
        thisConfig.setTlsIdentity(thisIdentity); // <.>

        // end::listener-config-tls-id-set[]
// end::listener-config-tls-id-full[]
    }

    private void ibListenerConfigClientAuthRoot(URLEndpointListenerConfiguration thisConfig) throws CouchbaseLiteException {
// tag::listener-config-client-root-ca[]
        // tag::listener-config-client-auth-root[]
        // Configure the client authenticator
        // to validate using ROOT CA
        // thisClientID.certs is a list containing a client cert to accept
        // and any other certs needed to complete a chain between the client cert
        // and a CA
        final TLSIdentity validId =
            TLSIdentity.getIdentity("Our Corporate Id");  // get the identity <.>

        if (validId == null) { throw new IllegalStateException("Cannot find corporate id"); }

        thisConfig.setTlsIdentity(validId);

        thisConfig.setAuthenticator(
            new ListenerCertificateAuthenticator(validId.getCerts())); // <.> <.>
        // accept only clients signed by the corp cert

        final URLEndpointListener thisListener =
            new URLEndpointListener(thisConfig);

        // end::listener-config-client-auth-root[]
// end::listener-config-client-root-ca[]
    }

    private void ibListenerConfigClientAuthLambda(URLEndpointListenerConfiguration thisConfig) throws CouchbaseLiteException {
// tag::listener-config-client-auth-lambda[]
// Configure authentication using application logic
        final TLSIdentity thisCorpId = TLSIdentity.getIdentity("OurCorp"); // <.>
        if (thisCorpId == null) {
            throw new IllegalStateException("Cannot find corporate id");
        }
        thisConfig.setTlsIdentity(thisCorpId);
        thisConfig.setAuthenticator(
            new ListenerCertificateAuthenticator(certs -> true) {

                // use supplied logic that resolves to boolean
                // true=valid, false=invalid
            }
        ); // <.> <.>
        final URLEndpointListener thisListener =
            new URLEndpointListener(thisConfig);

        // end::listener-config-client-auth-lambda[]
    }


    private void ibListenerConfigTlsDisable2(URLEndpointListenerConfiguration thisConfig) {

        // tag::listener-config-tls-disable[]
        thisConfig.setDisableTls(true);

        // end::listener-config-tls-disable[]
    }


    private void ibListenerStatusCheck(URLEndpointListener thisListener) {
        // tag::listener-status-check[]
        int connectionCount =
            thisListener.getStatus().getConnectionCount(); // <.>

        int activeConnectionCount =
            thisListener.getStatus().getActiveConnectionCount();  // <.>

        // end::listener-status-check[]
    }

    private void ibListenerStop(URLEndpointListener thisListener) {

        // tag::listener-stop[]
        thisListener.stop();

        // end::listener-stop[]
    }

// Listener Callouts
/*
  // tag::listener-callouts-full[]

    // tag::listener-start-callouts[]
    <.> Initialize the listener instance using the configuration settings.
    <.> Start the listener, ready to accept connections and incoming data from active peers.

  // end::listener-start-callouts[]

  // tag::listener-status-check-callouts[]

  <.> `connectionCount` -- the total number of connections served by the listener
  <.> `activeConnectionCount` -- the number of active (BUSY) connections currently being served by the listener
  //
  // end::listener-status-check-callouts[]

// end::listener-callouts-full[]
*/
    /* END CALLOUTS TEXT */

// ACTIVE PEER STUFF
// Replication code
//

    //@Test
    public void testActPeerSync() throws URISyntaxException {
        // tag::p2p-act-rep-func[]
        // tag::p2p-act-rep-initialize[]
        // initialize the replicator configuration
        final ReplicatorConfiguration thisConfig
            = new ReplicatorConfiguration(
            thisDB,
            new URLEndpoint(new URI("wss://listener.com:8954"))); // <.> <.>

        // end::p2p-act-rep-initialize[]
        // tag::p2p-act-rep-config-type[]
        // Set replicator type
        thisConfig.setReplicatorType(
            ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);

        // end::p2p-act-rep-config-type[]
        // tag::p2p-act-rep-config-cont[]
        // Configure Sync Mode
        thisConfig.setContinuous(false); // default value

        // end::p2p-act-rep-config-cont[]
        // tag::autopurge-override[]
        // set auto-purge behavior (here we override default)
        thisConfig.setAutoPurgeEnabled(false); // <.>

        // end::autopurge-override[]
        // tag::p2p-act-rep-config-self-cert[]
        // Configure Server Authentication --
        // only accept self-signed certs
        thisConfig.setAcceptOnlySelfSignedServerCertificate(true); // <.>

        // end::p2p-act-rep-config-self-cert[]
        // tag::p2p-act-rep-auth[]
        // Configure the credentials the
        // client will provide if prompted
        final BasicAuthenticator thisAuth
            = new BasicAuthenticator(
            "Our Username",
            "Our PasswordValue".toCharArray()); // <.>

        thisConfig.setAuthenticator(thisAuth);

        // end::p2p-act-rep-auth[]
        // tag::p2p-act-rep-config-conflict[]
        /* Optionally set custom conflict resolver call back */
        thisConfig.setConflictResolver(Conflict::getLocalDocument); // <.>

        // end::p2p-act-rep-config-conflict[]
        // tag::p2p-act-rep-start-full[]
        // Create replicator
        // Consider holding a reference somewhere
        // to prevent the Replicator from being GCed
        final Replicator thisReplicator = new Replicator(thisConfig); // <.>

        // tag::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-add-change-listener-label[]
        // Optionally add a change listener <.>
        // end::p2p-act-rep-add-change-listener-label[]
        ListenerToken thisListener =
            new Replicator(thisConfig).addChangeListener(change -> {
                final CouchbaseLiteException err =
                    change.getStatus().getError();
                if (err != null) {
                    Log.i(TAG, "Error code ::  " + err.getCode(), err);
                }
            }); // <.>

        // end::p2p-act-rep-add-change-listener[]
        // tag::p2p-act-rep-start[]
        // Start replicator
        thisReplicator.start(false); // <.>

        // end::p2p-act-rep-start[]
        // end::p2p-act-rep-start-full[]
        // end::p2p-act-rep-func[]         ***** End p2p-act-rep-func
    }

    public void ibReplicatorConfig(ReplicatorConfiguration thisConfig) throws CertificateEncodingException, CouchbaseLiteException {
        // BEGIN additional snippets
        // tag::p2p-act-rep-config-tls-full[]
        // tag::p2p-act-rep-config-cacert[]
        // Configure Server Security
        // -- only accept CA attested certs
        thisConfig.setAcceptOnlySelfSignedServerCertificate(false); // <.>

        // end::p2p-act-rep-config-cacert[]
        // tag::p2p-act-rep-config-pinnedcert[]

        // Return the remote pinned cert (the listener's cert)
        X509Certificate returnedCert = thisConfig.getPinnedServerX509Certificate(); // Get listener cert if pinned
        // end::p2p-act-rep-config-pinnedcert[]

        // end::p2p-act-rep-config-tls-full[]
        // tag::p2p-tlsid-tlsidentity-with-label[]
        // ... your other replicator configuration

        // Provide a client certificate to the server for authentication
        final TLSIdentity thisClientId = TLSIdentity.getIdentity("clientId"); // <.>

        if (thisClientId == null) { throw new IllegalStateException("Cannot find client id"); }

        thisConfig.setAuthenticator(new ClientCertificateAuthenticator(thisClientId)); // <.>

        // ... your other replicator configuration
        Replicator thisReplicator = new Replicator(thisConfig);

        // end::p2p-tlsid-tlsidentity-with-label[]
        // tag::p2p-act-rep-config-cacert-pinned[]

        // Use the pinned certificate from the byte array (cert)
        thisConfig.setPinnedServerCertificate(cert.getEncoded()); // <.>
        // end::p2p-act-rep-config-cacert-pinned[]
    }
// END additional snippets


    // tag::p2p-act-rep-status[]
    public void p2pStatus() {
        Log.i(TAG, "The Replicator is currently " +
            thisReplicator.getStatus().getActivityLevel());

        if (thisReplicator.getStatus().getActivityLevel() == ReplicatorActivityLevel.BUSY) {
            Log.i(TAG, "Replication Processing");
        }
        Log.i(TAG, "It has completed " +
            thisReplicator.getStatus().getProgress().getCompleted() +
            " changes");
    }
    // end::p2p-act-rep-status[]

    public void p2pStop() {
        // tag::p2p-act-rep-stop[]
        // Stop replication.
        thisReplicator.stop(); // <.>
        // end::p2p-act-rep-stop[]
    }

    public void createIdentity() throws CouchbaseLiteException {
        // tag::createTlsIdentity[]
        Map<String, String> attrs = new HashMap<>();
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "Couchbase Demo");
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
        attrs.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "noreply@couchbase.com");

        TLSIdentity thisIdentity = TLSIdentity.createIdentity(true, attrs, null, "test-alias");
        // end::createTlsIdentity[]
    }
    // tag::p2p-tlsid-store-in-keychain[]
    // end::p2p-tlsid-store-in-keychain[]


    public void deleteIdentity() throws KeyStoreException, CertificateException, IOException, NoSuchAlgorithmException {
        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        String thisAlias = "alias-to-delete";
        final KeyStore thisKeyStore
            = KeyStore.getInstance("AndroidKeyStore");
        thisKeyStore.load(null);
        thisKeyStore.deleteEntry(thisAlias);

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]
    }

    public void retrieveIdentity() throws CouchbaseLiteException {

        // tag::retrieveTlsIdentity[]
        // OPTIONALLY:: Retrieve a stored TLS identity using its alias/label

        TLSIdentity thisIdentity =
            TLSIdentity.getIdentity("couchbase-docs-cert");
        // end::retrieveTlsIdentity[]
    }

    // tag::sgw-repl-pull[]
    public void pullReplicator(Database database) throws URISyntaxException {
        Endpoint endpoint = new URLEndpoint(new URI("wss://10.0.2.2:4984/db")); // <.>
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
        Replicator replicator = new Replicator(config); // <.>
        replicator.start();
    }
    // end::sgw-repl-pull[]

    public void sgwInit() throws URISyntaxException {

        // tag::sgw-act-rep-initialize[]
        // initialize the replicator configuration
        final ReplicatorConfiguration thisConfig
            = new ReplicatorConfiguration(
            thisDB,
            new URLEndpoint(new URI("wss://10.0.2.2:8954/travel-sample"))); // <.>

        // end::sgw-act-rep-initialize[]
    }

  /* C A L L O U T S

  // tag::p2p-act-rep-config-cacert-pinned-callouts[]
  <.> Configure the pinned certificate using data from the byte array `cert`
  // end::p2p-act-rep-config-cacert-pinned-callouts[]

  // tag::p2p-tlsid-tlsidentity-with-label-callouts[]
  <.> Attempt to get the identity from secure storage
  <.> Set the authenticator to ClientCertificateAuthenticator and configure it to use the retrieved identity

  // end::p2p-tlsid-tlsidentity-with-label-callouts[]

  // tag::sgw-repl-pull-callouts[]
  <.> A replication is an asynchronous operation.
  To keep a reference to the `replicator` object, you can set it as an instance property.
  <.> The URL scheme for remote database URLs uses `ws:`, or `wss:` for SSL/TLS connections over wb sockets.
  In this example the hostname is `10.0.2.2` because the Android emulator runs in a VM that is generally accessible
  on `10.0.2.2` from the host machine (see https://developer.android.com/studio/run/emulator-networking[Android
  Emulator networking] documentation).
  +
  NOTE: As of Android Pie, version 9, API 28, cleartext support is disabled, by default.
  Although `wss:` protocol URLs are not affected, in order to use the `ws:` protocol, applications must target API 27
   or lower, or must configure application network security as described https://developer.android
   .com/training/articles/security-config#CleartextTrafficPermitted[here].

  // end::sgw-repl-pull-callouts[]
  */
}

@SuppressWarnings({"unused", "ConstantConditions"})
class TestQueries {

    // For Documentation


    private final HashMap<String, Object> hotels = new HashMap<>();

    private Database database;

    private String thisDocsId;
    private String thisDocsName;

    public TestQueries(Database database) {
        this.database = database;
    }

    public void testQuerySyntaxAll() throws CouchbaseLiteException, JsonProcessingException {

        // tag::query-syntax-all[]
        database = new Database("hotels");

        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(database));
        // end::query-syntax-all[]

        // tag::query-access-all[]

        for (Result result: listQuery.execute().allResults()) {
            // get the k-v pairs from the 'hotel' key's value into a dictionary
            Dictionary thisDocsProps = result.getDictionary(0); // <.>
            final Hotel hotel = new Hotel();
            hotel.setId(thisDocsProps.getString("id"));
            hotel.setName(thisDocsProps.getString("Name"));
            hotel.setType(thisDocsProps.getString("Type"));
            hotel.setCity(thisDocsProps.getString("City"));
            hotels.put(hotel.getId(), hotel);
        }

        // end::query-access-all[]


// tag::query-access-json[]
        // Uses Jackson JSON processor
        ObjectMapper mapper = new ObjectMapper();

        List<Hotel> hotels = new ArrayList<>();
        for (Result result: listQuery.execute()) {

            // Get result as JSON string
            String thisJsonString = result.toJSON(); // <.>

            // Get Java  Hashmap from JSON string
            HashMap<String, Object> dictFromJSONstring =
                mapper.readValue(thisJsonString, HashMap.class); // <.>


            // Use created hashmap
            String hotelId = dictFromJSONstring.get("id").toString();
            String hotelType = dictFromJSONstring.get("type").toString();
            String hotelname = dictFromJSONstring.get("name").toString();


            // Get custom object from JSON string
            Hotel thisHotel =
                mapper.readValue(thisJsonString, Hotel.class); // <.>
            hotels.add(thisHotel);


            // end::query-access-json[]
        }
    }


    public void testQuerySyntaxProps() throws CouchbaseLiteException {
        // tag::query-select-props[]
        // tag::query-syntax-props[]

        database = new Database("hotels");

        Query listQuery =
            QueryBuilder.select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("Name"),
                    SelectResult.property("Type"),
                    SelectResult.property("City"))
                .from(DataSource.database(database));

        // end::query-syntax-props[]

        // tag::query-access-props[]

        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs.allResults()) {

                // get data direct from result k-v pairs
                final Hotel hotel = new Hotel();
                hotel.setId(result.getString("id"));
                hotel.setType(result.getString("Type"));
                hotel.setName(result.getString("Name"));
                hotel.setCity(result.getString("City"));

                // Store created hotel object in a hashmap of hotels
                hotels.put(hotel.getId(), hotel);

                // Get result k-v pairs into a 'dictionary' object
                Map<String, Object> thisDocsProps = result.toMap();
                thisDocsId =
                    thisDocsProps.getOrDefault("id", null).toString();
                thisDocsName =
                    thisDocsProps.getOrDefault("Name", null).toString();
                String thisDocsType = thisDocsProps.getOrDefault("Type", null).toString();
                String thisDocsCity = thisDocsProps.getOrDefault("City", null).toString();
            }
        }

        // end::query-access-props[]
        // end::query-select-props[]
    }


    public void testQuerySyntaxCount() throws CouchbaseLiteException {
        database = new Database("hotels");

        // tag::query-syntax-count-only[]
        Query listQuery = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
            .from(DataSource.database(database));

        // end::query-syntax-count-only[]


        // tag::query-access-count-only[]
        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs) {

                // Retrieve count using key 'mycount'
                Integer altDocId = result.getInt("mycount");

                // Alternatively, use the index
                Integer orDocId = result.getInt(0);
            }
            // Or even miss out the for-loop altogether
            Integer resultCount = listQuery.execute().next().getInt("mycount");
        }
        // end::query-access-count-only[]
    }


    public void testQuerySyntaxId() throws CouchbaseLiteException {
        // tag::query-syntax-id[]
        database = new Database("hotels");

        Query listQuery =
            QueryBuilder.select(SelectResult.expression(Meta.id).as("metaID"))
                .from(DataSource.database(database));

        // end::query-syntax-id[]


        // tag::query-access-id[]

        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs.allResults()) {

                // get the ID form the result's k-v pair array
                thisDocsId = result.getString("metaID"); // <.>

                // Get document from DB using retrieved ID
                Document thisDoc = database.getDocument(thisDocsId);

                // Process document as required
                thisDocsName = thisDoc.getString("Name");
            }
        }

        // end::query-access-id[]

    }


    // tag::query-syntax-pagination-all[]
    public void testQueryPagination() throws CouchbaseLiteException {


        // tag::query-syntax-pagination[]
        database = new Database("hotels");

        int thisOffset = 0;
        int thisLimit = 20;

        Query listQuery =
            QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .limit(
                    Expression.intValue(thisLimit),
                    Expression.intValue(thisOffset)); // <.>

        // end::query-syntax-pagination[]

    }

    // end::query-syntax-pagination-all[]


    public List<Result> docsonlyQuerySyntaxN1QL(Database thisDb) throws CouchbaseLiteException {
        // For Documentation -- N1QL Query using parameters
        // tag::query-syntax-n1ql[]
        //  Declared elsewhere: Database thisDb

        Query thisQuery =
            thisDb.createQuery(
                "SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.

        return thisQuery.execute().allResults();

        // end::query-syntax-n1ql[]
    }


    public List<Result> docsonlyQuerySyntaxN1QLParams(Database thisDb) throws CouchbaseLiteException {
        // For Documentation -- N1QL Query using parameters
        // tag::query-syntax-n1ql-params[]
        //  Declared elsewhere: Database thisDb

        Query thisQuery =
            thisDb.createQuery(
                "SELECT META().id AS thisId FROM _ WHERE type = $type"); // <.

        thisQuery.setParameters(
            new Parameters().setString("type", "hotel")); // <.>

        return thisQuery.execute().allResults();

        // end::query-syntax-n1ql-params[]
    }
} // class


@SuppressWarnings({"unused", "ConstantConditions"})
class SupportingDatatypes {
    private static final String TAG = "info";
    private final Context context;

    public SupportingDatatypes(Context context) { this.context = context; }

    public void datatypeUsage() throws CouchbaseLiteException {


        // tag::datatype_usage[]
        // tag::datatype_usage_createdb[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init(context);

        // Get the database (and create it if it doesn’t exist).
        DatabaseConfiguration config = new DatabaseConfiguration();

        config.setDirectory(context.getFilesDir().getAbsolutePath());

        Database database = new Database("getting-started", config);

        // end::datatype_usage_createdb[]
        // tag::datatype_usage_createdoc[]
        // Create your new document
        MutableDocument mutableDoc = new MutableDocument();

        // end::datatype_usage_createdoc[]
        // tag::datatype_usage_mutdict[]
        // Create and populate mutable dictionary
        // Create a new mutable dictionary and populate some keys/values
        MutableDictionary address = new MutableDictionary();
        address.setString("street", "1 Main st.");
        address.setString("city", "San Francisco");
        address.setString("state", "CA");
        address.setString("country", "USA");
        address.setString("code", "90210");

        // end::datatype_usage_mutdict[]
        // tag::datatype_usage_mutarray[]
        // Create and populate mutable array
        MutableArray phones = new MutableArray();
        phones.addString("650-000-0000");
        phones.addString("650-000-0001");

        // end::datatype_usage_mutarray[]
        // tag::datatype_usage_populate[]
        // Initialize and populate the document

        // Add document type to document properties <.>
        mutableDoc.setString("type", "hotel");

        // Add hotel name string to document properties <.>
        mutableDoc.setString("name", "Hotel Java Mo");

        // Add float to document properties <.>
        mutableDoc.setFloat("room_rate", 121.75f);

        // Add dictionary to document's properties <.>
        mutableDoc.setDictionary("address", address);


        // Add array to document's properties <.>
        mutableDoc.setArray("phones", phones);

        // end::datatype_usage_populate[]
        // tag::datatype_usage_persist[]
        // Save the document changes <.>
        database.save(mutableDoc);

        // end::datatype_usage_persist[]
        // tag::datatype_usage_closedb[]
        // Close the database <.>
        database.close();

        // end::datatype_usage_closedb[]

        // end::datatype_usage[]

    }


    public void datatypeDictionary() throws CouchbaseLiteException {
        Database database = new Database("mydb");

        // tag::datatype_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)
        Document document = database.getDocument("doc1");

        // Getting a dictionary from the document's properties
        Dictionary dict = document.getDictionary("address");

        // Access a value with a key from the dictionary
        String street = dict.getString("street");

        // Iterate dictionary
        for (String key: dict) {
            dict.getValue(key);
            Log.i(TAG, "Key " + key + " = " + dict.getValue(key));
        }

        // Create a mutable copy
        MutableDictionary mutableDict = dict.toMutable();
        // end::datatype_dictionary[]
    }

    public void datatypeMutableDictionary() throws CouchbaseLiteException {

        Database database = new Database("mydb");

        // tag::datatype_mutable_dictionary[]
        // NOTE: No error handling, for brevity (see getting started)

        // Create a new mutable dictionary and populate some keys/values
        MutableDictionary mutableDict = new MutableDictionary();
        mutableDict.setString("street", "1 Main st.");
        mutableDict.setString("city", "San Francisco");

        // Add the dictionary to a document's properties and save the document
        MutableDocument mutableDoc = new MutableDocument("doc1");
        mutableDoc.setDictionary("address", mutableDict);
        database.save(mutableDoc);

        // end::datatype_mutable_dictionary[]
    }


    public void datatypeArray() throws CouchbaseLiteException {
        Database database = new Database("mydb");

        // tag::datatype_array[]
        // NOTE: No error handling, for brevity (see getting started)

        Document document = database.getDocument("doc1");

        // Getting a phones array from the document's properties
        Array array = document.getArray("phones");

        // Get element count
        int count = array.count();

        // Access an array element by index
        if (count >= 0) { String phone = array.getString(1); }

        // Iterate dictionary
        for (int i = 0; i < count; i++) {
            Log.i(TAG, "Item " + i + " = " + array.getString(i));
        }

        // Create a mutable copy
        MutableArray mutableArray = array.toMutable();
        // end::datatype_array[]


    }

    public void datatypeMutableArray() throws CouchbaseLiteException {
        Database database = new Database("mydb");

        // tag::datatype_mutable_array[]
        // NOTE: No error handling, for brevity (see getting started)

        // Create a new mutable array and populate data into the array
        MutableArray mutableArray = new MutableArray();
        mutableArray.addString("650-000-0000");
        mutableArray.addString("650-000-0001");

        // Set the array to document's properties and save the document
        MutableDocument mutableDoc = new MutableDocument("doc1");
        mutableDoc.setArray("phones", mutableArray);
        database.save(mutableDoc);
        // end::datatype_mutable_array[]
    }
} // end  class supporting_datatypes

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::ziputils-unzip[]
class ZipUtils {
    public static void unzip(InputStream src, File dst) throws IOException {
        byte[] buffer = new byte[1024];
        try (InputStream in = src; ZipInputStream zis = new ZipInputStream(in)) {
            ZipEntry ze = zis.getNextEntry();
            while (ze != null) {
                File newFile = new File(dst, ze.getName());
                if (ze.isDirectory()) { newFile.mkdirs(); }
                else {
                    new File(newFile.getParent()).mkdirs();
                    try (FileOutputStream fos = new FileOutputStream(newFile)) {
                        int len;
                        while ((len = zis.read(buffer)) > 0) { fos.write(buffer, 0, len); }
                    }
                }
                ze = zis.getNextEntry();
            }
            zis.closeEntry();
        }
    }
}
// end::ziputils-unzip[]package com.couchbase.codesnippets;

import java.util.Objects;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;


public class Hotel {
    @Nullable
    private String description;
    @Nullable
    private String country;
    @Nullable
    private String city;
    @Nullable
    private String name;
    @Nullable
    private String type;
    @Nullable
    private String id;

    public Hotel() { }

    public Hotel(
        @Nullable String description,
        @Nullable String country,
        @Nullable String city,
        @Nullable String name,
        @Nullable String type,
        @Nullable String id) {
        this.description = description;
        this.country = country;
        this.city = city;
        this.name = name;
        this.type = type;
        this.id = id;
    }

    @Nullable
    public final String getDescription() { return this.description; }

    public final void setDescription(@Nullable String var1) { this.description = var1; }

    @Nullable
    public final String getCountry() { return this.country; }

    public final void setCountry(@Nullable String var1) { this.country = var1; }

    @Nullable
    public final String getCity() { return this.city; }

    public final void setCity(@Nullable String var1) { this.city = var1; }

    @Nullable
    public final String getName() { return this.name; }

    public final void setName(@Nullable String var1) { this.name = var1; }

    @Nullable
    public final String getType() { return this.type; }

    public final void setType(@Nullable String var1) { this.type = var1; }

    @Nullable
    public final String getId() { return this.id; }

    public final void setId(@Nullable String var1) { this.id = var1; }

    @NotNull
    @Override
    public String toString() {
        return "Hotel(description=" + this.description + ", country=" + this.country
            + ", city=" + this.city + ", " + "name=" + this.name + ", type=" + this.type + ", id=" + this.id + ")";
    }

    @Override
    public int hashCode() { return Objects.hash(description, country, city, name, type, id); }

    @Override
    public boolean equals(Object o) {
        if (this == o) { return true; }
        if (!(o instanceof Hotel)) { return false; }
        Hotel hotel = (Hotel) o;
        return Objects.equals(description, hotel.description)
            && Objects.equals(country, hotel.country)
            && Objects.equals(city, hotel.city)
            && Objects.equals(name, hotel.name)
            && Objects.equals(type, hotel.type)
            && Objects.equals(id, hotel.id);
    }
}//
// Copyright (c) 2021 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.codesnippets;

import android.util.Log;

import java.util.Map;

import org.json.JSONException;
import org.json.JSONObject;

import com.couchbase.lite.Array;
import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;


@SuppressWarnings({"unused", "ConstantConditions"})
public class JSONExamples {
    private static final String TAG = "SNIPPETS";

    public static final String JSON
        = "[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\","
        + "\"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},"
        + "{\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\","
        + "\"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},"
        + "{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\","
        + "\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\","
        + "\"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]";

    public void jsonArrayExample(Database db) throws CouchbaseLiteException {
        // tag::tojson-array[]
        // github tag=tojson-array
        final MutableArray mArray = new MutableArray(JSON); // <.>

        for (int i = 0; i < mArray.count(); i++) { // <.>
            final Dictionary dict = mArray.getDictionary(i);
            Log.i(TAG, dict.getString("name"));
            db.save(new MutableDocument(dict.getString("id"), dict.toMap()));
        }

        final Array features = db.getDocument("1002").getArray("features"); // <.>
        for (Object feature: features.toList()) { Log.i(TAG, feature.toString()); }
        Log.i(TAG, features.toJSON()); // <.>
        // end::tojson-array[]
    }

    public void jsonBlobExample(Database db) {
        // tag::tojson-blob[]
        // github tag=tojson-blob
        final Map<String, ?> thisBlob = db.getDocument("thisdoc-id").toMap();
        if (!Blob.isBlob(thisBlob)) { return; }

        final String blobType = thisBlob.get("content_type").toString();
        final Number blobLength = (Number) thisBlob.get("length");
        // end::tojson-blob[]
    }

    public void jsonDictionaryExample(Database db) {
        // tag::tojson-dictionary[]
        // github tag=tojson-dictionary
        final MutableDictionary mDict = new MutableDictionary(JSON); // <.>
        Log.i(TAG, mDict.toString());

        Log.i(TAG, "Details for: " + mDict.getString("name"));
        for (String key: mDict.getKeys()) {
            Log.i(TAG, key + " => " + mDict.getValue(key));
        }
        // end::tojson-dictionary[]
    }

    public void jsonDocumentExample(Database srcDb, Database dstDb) throws CouchbaseLiteException {
        // tag::tojson-document[]
        // github tag=tojson-document
        final Query listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(srcDb));

        for (Result row: listQuery.execute()) {
            final String thisId = row.getString("metaId");

            final String json = srcDb.getDocument(thisId).toJSON(); // <.>
            Log.i(TAG, "JSON String = " + json);

            final MutableDocument hotelFromJSON = new MutableDocument(thisId, json); // <.>

            dstDb.save(hotelFromJSON);

            for (Map.Entry<String, Object> entry: dstDb.getDocument(thisId).toMap().entrySet()) {
                Log.i(TAG, entry.getKey() + " => " + entry.getValue());
            } // <.>
        }
        // end::tojson-document[]
    }


    public void jsonQueryExample(Query query) throws CouchbaseLiteException, JSONException {
        for (Result row: query.execute()) {

            // get the result into a JSON String
            final String jsonString = row.toJSON();

            final JSONObject thisJsonObj = new JSONObject(jsonString);

            // Use Json Object to populate Native object
            // Use Codable class to unpack JSON data to native object
            final Hotel thisHotel = new Hotel(
                "this hotel",
                "Ghana, West Africa",
                thisJsonObj.getString("city"),
                thisJsonObj.getString("name"),
                thisJsonObj.getString("type"),
                thisJsonObj.getString("id"));
        }
    }
}
package com.couchbase.codesnippets;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;


public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
