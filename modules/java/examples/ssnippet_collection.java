package com.couchbase.codesnippets;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.couchbase.lite.ArrayFunction;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CollectionConfiguration;
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
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
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
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.SessionAuthenticator;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.ValueIndex;
import com.couchbase.lite.ValueIndexConfiguration;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "ConstantConditions"})
public class Examples {
    @NonNull
    private final Database database;
    @NonNull
    private final Collection defaultCollection;

    private Examples(@NonNull Database db) throws CouchbaseLiteException {
        this.database = db;
        this.defaultCollection = db.getDefaultCollection();
    }

    private static final String DB_NAME = "getting-started";
    private static final String DB_NAME2 = "other";

    private InputStream getAsset(String path) {
        return null;
    }

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

    public void test1xAttachments() throws CouchbaseLiteException, IOException {
        // if db exist, delete it
        final String DB_NAME = "cbl-sqlite";
        final File filesDir = new File(database.getPath());
        deleteDB(DB_NAME, filesDir);

        ZipUtils.unzip(getAsset("replacedb/android140-sqlite.cblite2.zip"), filesDir);

        Database db = new Database(DB_NAME, new DatabaseConfiguration());
        Collection collection = db.getDefaultCollection();
        try {

            Document doc = collection.getDocument("doc1");

            // For Validation
            Dictionary attachments = doc.getDictionary("_attachments");
            Blob blob = attachments.getBlob("attach1");
            byte[] content = blob.getContent();
            // For Validation

            byte[] attach = "attach1".getBytes();
            assert Arrays.equals(attach, content);
        }
        finally {
            // close db
            db.close();
            // if db exist, delete it
            deleteDB(DB_NAME, filesDir);
        }

        Document document = new MutableDocument();

        // tag::1x-attachment[]
        Dictionary attachments = document.getDictionary("_attachments");
        Blob blob = attachments != null ? attachments.getBlob("avatar") : null;
        byte[] content = blob != null ? blob.getContent() : null;
        // end::1x-attachment[]
    }

    public void testInitializer() {
        // tag::sdk-initializer[]
        // Initialize the Couchbase Lite system
        CouchbaseLite.init();
        // end::sdk-initializer[]
    }

    public void testNewDatabase() throws CouchbaseLiteException {
        final String customDir = "/foo/bar";
        // tag::new-database[]
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setDirectory(customDir);
        Database database = new Database(DB_NAME, config);
        // end::new-database[]

        // tag::close-database[]
        database.close();
        // end::close-database[]

        database.delete();
    }

    public void testDatabaseEncryption() throws CouchbaseLiteException {
        // tag::database-encryption[]
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setEncryptionKey(new EncryptionKey("PASSWORD"));
        Database database = new Database(DB_NAME, config);
        // end::database-encryption[]
    }

    public void testLogging() {
        // tag::logging[]

        // Set the overall logging level
        Database.log.getConsole().setLevel(LogLevel.VERBOSE);

        // Enable or disable specific domains
        Database.log.getConsole().setDomains(LogDomain.REPLICATOR, LogDomain.QUERY);
        // end::logging[]
    }

    public void testEnableCustomLogging() {
        // tag::set-custom-logging[]
        Database.log.setCustom(new LogTestLogger(LogLevel.WARNING)); // <.>
        // end::set-custom-logging[]
    }

    public void testConsoleLogging() {
        // tag::console-logging[]
        Database.log.getConsole().setDomains(LogDomain.ALL_DOMAINS); // <.>
        Database.log.getConsole().setLevel(LogLevel.VERBOSE); // <.>
        // end::console-logging[]

        // tag::console-logging-db[]
        Database.log.getConsole().setDomains(LogDomain.DATABASE);
        // end::console-logging-db[]
    }

    public void testFileLogging() {
        // tag::file-logging[]
        LogFileConfiguration LogCfg = new LogFileConfiguration(
            (System.getProperty("user.dir") + "/MyApp/logs")); // <.>
        LogCfg.setMaxSize(10240); // <.>
        LogCfg.setMaxRotateCount(5); // <.>
        LogCfg.setUsePlaintext(false); // <.>
        Database.log.getFile().setConfig(LogCfg);
        Database.log.getFile().setLevel(LogLevel.INFO); // <.>
        // end::file-logging[]
    }

    public void testPreBuiltDatabase() throws IOException {
        final File appDbDir = new File(database.getPath());

        // tag::prebuilt-database[]
        // Note: Getting the path to a database is platform-specific.
        DatabaseConfiguration configuration = new DatabaseConfiguration();
        if (!Database.exists("travel-sample", appDbDir)) {
            File tmpDir = new File(System.getProperty("java.io.tmpdir"));
            ZipUtils.unzip(getAsset("travel-sample.cblite2.zip"), tmpDir);
            File path = new File(tmpDir, "travel-sample");
            try {
                Database.copy(path, "travel-sample", configuration);
            }
            catch (CouchbaseLiteException e) {
                e.printStackTrace();
            }
        }
        // end::prebuilt-database[]
    }

    public void testInitializers() {
        final Collection collection = null;

        // tag::initializer[]
        MutableDocument newTask = new MutableDocument();
        newTask.setString("type", "task");
        newTask.setString("owner", "todo");
        newTask.setDate("createdAt", new Date());
        try {
            collection.save(newTask);
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::initializer[]
    }

    public void testMutability() {
        final Collection collection = null;

        // tag::update-document[]
        Document document;

        try {
            document = collection.getDocument("xyz");
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
            return;
        }

        MutableDocument mutableDocument = document.toMutable();
        mutableDocument.setString("name", "apples");
        try {
            collection.save(mutableDocument);
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::update-document[]
    }

    public void testTypedAccessors() {
        MutableDocument newTask = new MutableDocument();

        // tag::date-getter[]
        newTask.setValue("createdAt", new Date());
        Date date = newTask.getDate("createdAt");
        // end::date-getter[]
    }

    public void testBatchOperations() {
        final Database database = null;
        final Collection collection = null;

        // tag::batch[]
        try {
            database.inBatch(() -> {
                for (int i = 0; i < 10; i++) {
                    MutableDocument doc = new MutableDocument();
                    doc.setValue("type", "user");
                    doc.setValue("name", "user " + i);
                    doc.setBoolean("admin", false);
                    try {
                        collection.save(doc);
                    }
                    catch (CouchbaseLiteException e) {
                        e.printStackTrace();
                    }
                    System.out.println("saved user document " + doc.getString("name"));
                }
            });
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::batch[]
    }

    public void DocumentExpiration() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::document-expiration[]
        // Purge the document one day from now
        Instant ttl = Instant.now().plus(1, ChronoUnit.DAYS);
        collection.setDocumentExpiration("doc123", new Date(ttl.toEpochMilli()));

        // Reset expiration
        collection.setDocumentExpiration("doc1", null);

        // Query documents that will be expired in less than five minutes
        Instant fiveMinutesFromNow = Instant.now().plus(5, ChronoUnit.MINUTES);
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Meta.expiration.lessThan(Expression.doubleValue(fiveMinutesFromNow.toEpochMilli())));
        // end::document-expiration[]
    }

    public void testDocumentChangeListener() {
        final Collection collection = null;

        // tag::document-listener[]
        collection.addDocumentChangeListener(
            "user.john",
            change -> {
                try {
                    Document doc = collection.getDocument(change.getDocumentID());
                    if (doc != null) {
                        System.out.println("Status: " + doc.getString("verified_account"));
                    }
                }
                catch (CouchbaseLiteException e) {
                    e.printStackTrace();
                }
            });
        // end::document-listener[]
    }

    public void testBlobs() {
        final Collection collection = null;
        MutableDocument newTask = new MutableDocument();

        // tag::blob[]
        InputStream is = getAsset("avatar.jpg"); // <.>
        if (is == null) { return; }
        try {
            Blob blob = new Blob("image/jpeg", is);  // <.>
            newTask.setBlob("avatar", blob); // <.>
            collection.save(newTask);

            Blob taskBlob = newTask.getBlob("avatar");
            byte[] bytes = taskBlob.getContent();
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        finally {
            try { is.close(); }
            catch (IOException ignore) { }
        }
        // end::blob[]
    }

    public void testIndexing() throws CouchbaseLiteException {
        final Collection collection = null;

        // tag::query-index[]
        collection.createIndex("TypeNameIndex", new ValueIndexConfiguration("type", "name"));
        // end::query-index[]
    }

    public void testIndexing_Querybuilder() throws CouchbaseLiteException {
        final Collection collection = null;

        // tag::query-index_Querybuilder[]
        collection.createIndex(
            "TypeNameIndex",
            IndexBuilder.valueIndex(
                ValueIndexItem.property("type"),
                ValueIndexItem.property("name")));
        // end::query-index_Querybuilder[]
    }

    public void testSelectStatement() {
        final Collection collection = getCollection();

        // tag::query-select-props[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("type"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.expression(Meta.id));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println("hotel id -> " + result.getString("id"));
                System.out.println("hotel name -> " + result.getString("name"));
            }
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::query-select-props[]
    }

    public void testMetaFunction() {
        final Collection collection = getCollection();

        // tag::query-select-meta[]
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("airport")))
            .orderBy(Ordering.expression(Meta.id));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println("airport id -> " + result.getString("id"));
                System.out.println("airport id -> " + result.getString(0));
            }
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::query-select-meta[]
    }

    public void testSelectAll() {
        final Collection collection = getCollection();

        {
            // tag::query-select-all[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .where(Expression.property("type").equalTo(Expression.string("hotel")));
            // end::query-select-all[]
        }

        {
            // tag::live-query[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection)); // <.>

            // Adds a query change listener.
            // Changes will be posted on the main queue.
            ListenerToken token = query.addChangeListener(change -> { // <.>
                for (Result result: change.getResults()) {
                    System.out.println("results: " + result.getKeys());
                    /* Update UI */
                }
            });

            // end::live-query[]

            // tag::stop-live-query[]
            token.remove(); // <.>
            // end::stop-live-query[]
        }
    }

    public void testWhereStatement() {
        final Collection collection = getCollection();
        final String collectionName = "theStuff";

        // tag::query-where[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .limit(Expression.intValue(10));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Dictionary all = result.getDictionary(collectionName);
                System.out.println("name -> " + all.getString("name"));
                System.out.println("type -> " + all.getString("type"));
            }
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        // end::query-where[]
    }

    public void testQueryDeletedDocuments() {
        final Collection collection = getCollection();

        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Meta.deleted);
        // end::query-deleted-documents[]
    }

    public void testCollectionStatement() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::query-collection-operator-contains[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("public_likes"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))
                .and(ArrayFunction
                    .contains(Expression.property("public_likes"), Expression.string("Armani Langworth"))));
        try (ResultSet results = query.execute()) {
            for (Result result: results) {
                System.out.println("public_likes -> " + result.getArray("public_likes").toList());
            }
        }
        // end::query-collection-operator-contains[]
    }

    public void testInOperator() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::query-collection-operator-in[]
        Expression[] values = new Expression[] {
            Expression.property("first"),
            Expression.property("last"),
            Expression.property("username")
        };

        Query query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.string("Armani").in(values));
        // end::query-collection-operator-in[]

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println(result.toMap());
            }
        }
    }

    public void testPatternMatching() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::query-like-operator[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("royal engineers museum"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println("name -> " + result.getString("name"));
            }
        }
        // end::query-like-operator[]
    }

    public void testWildcardMatch() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::query-like-operator-wildcard-match[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("eng%e%"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println("name ->  " + result.getString("name"));
            }
        }
        // end::query-like-operator-wildcard-match[]
    }

    public void testWildCharacterMatch() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        // tag::query-like-operator-wildcard-character-match[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).like(Expression.string("eng____r"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println("name -> " + result.getString("name"));
            }
        }
        // end::query-like-operator-wildcard-character-match[]
    }

    public void testRegexMatch() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        // tag::query-regex-operator[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("landmark"))
                .and(Function.lower(Expression.property("name")).regex(Expression.string("\\beng.*r\\b"))));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println("name -> " + result.getString("name"));
            }
        }
        // end::query-regex-operator[]
    }

    public void testJoinStatement() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        // tag::query-join[]
        Query query = QueryBuilder.select(
                SelectResult.expression(Expression.property("name").from("airline")),
                SelectResult.expression(Expression.property("callsign").from("airline")),
                SelectResult.expression(Expression.property("destinationairport").from("route")),
                SelectResult.expression(Expression.property("stops").from("route")),
                SelectResult.expression(Expression.property("airline").from("route")))
            .from(DataSource.collection(collection).as("airline"))
            .join(Join.join(DataSource.collection(collection).as("route"))
                .on(Meta.id.from("airline").equalTo(Expression.property("airlineid").from("route"))))
            .where(Expression.property("type").from("route").equalTo(Expression.string("route"))
                .and(Expression.property("type").from("airline").equalTo(Expression.string("airline")))
                .and(Expression.property("sourceairport").from("route").equalTo(Expression.string("RIX"))));


        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println(result.toMap());
            }
        }
        // end::query-join[]
    }

    public void testGroupByStatement() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        // tag::query-groupby[]
        Query query = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))),
                SelectResult.property("country"),
                SelectResult.property("tz"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("airport"))
                .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300))))
            .groupBy(
                Expression.property("country"),
                Expression.property("tz"))
            .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending());


        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println(String.format(
                    "There are %d airports on the %s timezone located in %s and above 300ft",
                    result.getInt("$1"),
                    result.getString("tz"),
                    result.getString("country")));
            }
        }
        // end::query-groupby[]
    }

    public void testOrderByStatement() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        // tag::query-orderby[]
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.property("name").ascending())
            .limit(Expression.intValue(10));


        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                System.out.println(result.toMap());
            }
        }
        // end::query-orderby[]
    }

    public void testExplainStatement() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        {
            // tag::query-explain-all[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .where(Expression.property("type").equalTo(Expression.string("university")))
                .groupBy(Expression.property("country"))
                .orderBy(Ordering.property("name").descending()); // <.>
            System.out.println(query.explain()); // <.>
            // end::query-explain-all[]
        }

        {
            // tag::query-explain-like[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .where(Expression.property("type").like(Expression.string("%hotel%"))); // <.>
            System.out.println(query.explain());
            // end::query-explain-like[]
        }

        {
            // tag::query-explain-nopfx[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%"))));
            System.out.println(query.explain());
            // end::query-explain-nopfx[]
        }

        {
            // tag::query-explain-function[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))); // <.>
            System.out.println(query.explain());
            // end::query-explain-function[]
        }

        {
            // tag::query-explain-nofunction[]
            Query query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .where(Expression.property("type").equalTo(Expression.string("hotel"))); // <.>
            System.out.println(query.explain());
            // end::query-explain-nofunction[]
        }
        // end query-explain
    }

    public void prepareIndex() throws CouchbaseLiteException {
        final Collection collection = null;
        // tag::fts-index[]
        FullTextIndexConfiguration config = new FullTextIndexConfiguration("Overview").ignoreAccents(false);
        collection.createIndex("overviewFTSIndex", config);
        // end::fts-index[]
    }

    public void prepareIndex_Querybuilder() throws CouchbaseLiteException {
        final Collection collection = null;
        // tag::fts-index_Querybuilder[]
        collection.createIndex(
            "overviewFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("overviewFTSIndex")).ignoreAccents(false));
        // end::fts-index_Querybuilder[]
    }

    public void testFTS() throws CouchbaseLiteException {
        final Database database = null;
        // tag::fts-query[]
        Query ftsQuery =
            database.createQuery(
                "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK"
                    + "(overviewFTSIndex)");


        try (ResultSet resultSet = ftsQuery.execute()) {
            for (Result result: resultSet) {
                System.out.println(result.getString("id") + ": " + result.getString("overview"));
            }
        }
        // end::fts-query[]
    }

    public void testFTS_Querybuilder() throws CouchbaseLiteException {
        final Collection collection = getCollection();
        // tag::fts-query_Querybuilder[]
        Expression whereClause = FullTextFunction.match(
            Expression.fullTextIndex("overviewFTSIndex"),
            "'michigan'");
        Query ftsQuery =
            QueryBuilder.select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("overview"))
                .from(DataSource.collection(collection))
                .where(whereClause);


        try (ResultSet resultSet = ftsQuery.execute()) {
            for (Result result: resultSet) {
                System.out.println(result.getString("id") + ": " + result.getString("overview"));
            }
        }
        // end::fts-query_Querybuilder[]
    }

    public void testTroubleshooting() {
        // tag::replication-logging[]
        Database.log.getConsole().setDomains(LogDomain.REPLICATOR);
        Database.log.getConsole().setLevel(LogLevel.VERBOSE);
        // end::replication-logging[]
    }

    public void testReplicationBasicAuthentication() throws URISyntaxException {
        final Collection collection = getCollection();
        // tag::basic-authentication[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(target);
        config.addCollection(collection, null);
        config.setAuthenticator(new BasicAuthenticator("username", "password".toCharArray()));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);
        replicator.start();
        // end::basic-authentication[]

        replicator.close();
    }

    public void testReplicationSessionAuthentication() throws URISyntaxException {
        final Collection collection = getCollection();
        // tag::session-authentication[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config = new ReplicatorConfiguration(target);
        config.addCollection(collection, null);
        config.setAuthenticator(new SessionAuthenticator("904ac010862f37c8dd99015a33ab5a3565fd8447"));

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);
        replicator.start();
        // end::session-authentication[]

        replicator.close();
    }

    public void testReplicationStatus() throws URISyntaxException {
        final Collection collection = getCollection();
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);
        config.setType(ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);

        // tag::replication-status[]
        replicator.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == ReplicatorActivityLevel.STOPPED) {
                System.out.println("Replication stopped");
            }
        });
        // end::replication-status[]

        replicator.close();
    }

    public void testReplicationPendingDocs() throws URISyntaxException, CouchbaseLiteException {
        final Collection collection = getCollection();
        final Endpoint endpoint =
            new URLEndpoint(new URI("ws://localhost:4984/db"));

        final ReplicatorConfiguration config =
            new ReplicatorConfiguration(endpoint)
                .setType(ReplicatorType.PUSH);
        config.addCollection(collection, null);

        // tag::replication-push-pendingdocumentids[]
        Replicator replicator = new Replicator(config);
        final Set<String> pendingDocs =
            replicator.getPendingDocumentIds(collection); // <.>
        // end::replication-push-pendingdocumentids[]

        replicator.close();
    }

    public void testHandlingNetworkErrors() throws URISyntaxException {
        final Collection collection = getCollection();
        Endpoint endpoint = new URLEndpoint(new URI("ws://localhost:4984/db"));
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);
        config.setType(ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);

        // tag::replication-error-handling[]
        replicator.addChangeListener(change -> {
            CouchbaseLiteException error = change.getStatus().getError();
            if (error != null) { System.out.println("Error code:: " + error); }
        });
        replicator.start();
        // end::replication-error-handling[]

        replicator.stop();
        replicator.close();
    }

    public void testReplicatorDocumentEvent() throws URISyntaxException {
        final Collection collection = getCollection();
        Endpoint endpoint = new URLEndpoint(new URI("ws://localhost:4984/db"));
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);
        config.setType(ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);

        // tag::add-document-replication-listener[]
        ListenerToken token = replicator.addDocumentReplicationListener(replication -> {
            System.out.println("Replication type: " + ((replication.isPush()) ? "Push" : "Pull"));
            for (ReplicatedDocument document: replication.getDocuments()) {
                System.out.println("Doc ID: " + document.getID());

                CouchbaseLiteException err = document.getError();
                if (err != null) {
                    // There was an error
                    System.out.println("Error replicating document: ");
                    err.printStackTrace();
                    return;
                }

                if (document.getFlags().contains(DocumentFlag.DELETED)) {
                    System.out.println("Successfully replicated a deleted document");
                }
            }
        });

        replicator.start();
        // end::add-document-replication-listener[]

        // tag::remove-document-replication-listener[]
        token.remove();
        // end::remove-document-replication-listener[]

        replicator.close();
    }

    public void testReplicationCustomHeader() throws URISyntaxException {
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        final Collection collection = getCollection();

        // tag::replication-custom-header[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);
        Map<String, String> headers = new HashMap<>();
        headers.put("CustomHeaderName", "Value");
        config.setHeaders(headers);
        // end::replication-custom-header[]
    }

    public void testCertificatePinning() throws URISyntaxException, CertificateException {
        final Collection collection = getCollection();
        URI uri = new URI("wss://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);

        // tag::certificate-pinning[]
        InputStream is = getAsset("cert.cer");
        X509Certificate cert = (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(is);
        config.setPinnedServerX509Certificate(cert);
        // end::certificate-pinning[]
    }

    public void testReplicationResetCheckpoint() throws URISyntaxException {
        boolean resetCheckpointExample = false;
        final Collection collection = getCollection();
        URI uri = new URI("ws://localhost:4984/db");
        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(endpoint);
        config.addCollection(collection, null);
        config.setType(ReplicatorType.PULL);
        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(config);

        // tag::replication-reset-checkpoint[]
        replicator.start(resetCheckpointExample);
        // end::replication-reset-checkpoint[]

        replicator.stop();
        replicator.close();
    }

    public void testReplicationPushFilter() throws URISyntaxException {
        final Collection collection = getCollection();
        // tag::replication-push-filter[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        CollectionConfiguration collectionConfig = new CollectionConfiguration()
            .setPushFilter((document, flags) -> flags.contains(DocumentFlag.DELETED)); // <1>

        ReplicatorConfiguration replConfig = new ReplicatorConfiguration(target);
        replConfig.addCollection(collection, collectionConfig);

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(replConfig);
        replicator.start();
        // end::replication-push-filter[]

        replicator.close();
    }

    public void testReplicationPullFilter() throws URISyntaxException {
        final Collection collection = getCollection();
        // tag::replication-pull-filter[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        CollectionConfiguration collectionConfig = new CollectionConfiguration()
            .setPullFilter((document, flags) -> "draft".equals(document.getString("type"))); // <1>

        ReplicatorConfiguration replConfig = new ReplicatorConfiguration(target);
        replConfig.addCollection(collection, collectionConfig);

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(replConfig);
        replicator.start();
        // end::replication-pull-filter[]

        replicator.close();
    }

    public void testCustomRetryConfig() throws URISyntaxException {
        final Collection collection = getCollection();
        // tag::replication-retry-config[]
        URLEndpoint target =
            new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        ReplicatorConfiguration config =
            new ReplicatorConfiguration(target);
        config.addCollection(collection, null);

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

        //  other config as required . . .

        Replicator repl = new Replicator(config);
        // end::replication-retry-config[]

        repl.close();
    }

    public void testDatabaseReplica() throws CouchbaseLiteException {
        Database database2 = new Database(DB_NAME2);
        final Collection collection = getCollection();

        /* EE feature: code below will throw a compilation error
           if it's compiled against CBL Android Community. */
        // tag::database-replica[]
        DatabaseEndpoint targetDatabase = new DatabaseEndpoint(database2);
        ReplicatorConfiguration replicatorConfig = new ReplicatorConfiguration(targetDatabase);
        replicatorConfig.addCollection(collection, null);
        replicatorConfig.setType(ReplicatorType.PUSH);

        // Create replicator (be sure to hold a reference somewhere that will prevent the Replicator from being GCed)
        Replicator replicator = new Replicator(replicatorConfig);
        replicator.start();
        // end::database-replica[]

        replicator.close();
    }

    public void testPredictiveModel() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", new ImageClassifierModel());
        // end::register-model[]

        // tag::predictive-query-value-index[]
        ValueIndex index = IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")));
        collection.createIndex("value-index-image-classifier", index);
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier");
        // end::unregister-model[]
    }

    public void testPredictiveIndex() throws CouchbaseLiteException {
        final Collection collection = null;

        // tag::predictive-query-predictive-index[]
        Map<String, Object> inputMap = new HashMap<>();
        inputMap.put("numbers", Expression.property("photo"));
        Expression input = Expression.map(inputMap);

        PredictiveIndex index = IndexBuilder.predictiveIndex("ImageClassifier", input, null);
        collection.createIndex("predictive-index-image-classifier", index);
        // end::predictive-query-predictive-index[]
    }

    public void testPredictiveQuery() throws CouchbaseLiteException {
        final Collection collection = getCollection();

        // tag::predictive-query[]
        Map<String, Object> inputProperties = new HashMap<>();
        inputProperties.put("photo", Expression.property("photo"));
        Expression input = Expression.map(inputProperties);
        PredictionFunction prediction = Function.prediction("ImageClassifier", input); // <1>

        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("label").equalTo(Expression.string("car"))
                .and(prediction.propertyPath("probability").greaterThanOrEqualTo(Expression.doubleValue(0.8))));

        // Run the query.
        try (ResultSet result = query.execute()) {
            System.out.println("Number of rows: " + result.allResults().size());
        }
        // end::predictive-query[]
    }

    public void testReplicationWithCustomConflictResolver() throws URISyntaxException {
        final Collection collection = getCollection();
        // tag::replication-conflict-resolver[]
        URLEndpoint target = new URLEndpoint(new URI("ws://localhost:4984/mydatabase"));

        CollectionConfiguration collectionConfig = new CollectionConfiguration()
            .setConflictResolver(new LocalWinConflictResolver());

        ReplicatorConfiguration config = new ReplicatorConfiguration(target);
        config.addCollection(collection, collectionConfig);

        Replicator replication = new Replicator(config);
        replication.start();
        // end::replication-conflict-resolver[]

        replication.close();
    }

    public void testSaveWithCustomConflictResolver() throws CouchbaseLiteException {
        final Collection collection = null;
        // tag::update-document-with-conflict-handler[]
        Document doc = collection.getDocument("xyz");
        if (doc == null) { return; }
        MutableDocument mutableDocument = doc.toMutable();
        mutableDocument.setString("name", "apples");

        collection.save(
            mutableDocument,
            (newDoc, curDoc) -> {
                if (curDoc == null) { return false; }
                Map<String, Object> dataMap = curDoc.toMap();
                dataMap.putAll(newDoc.toMap());
                newDoc.setData(dataMap);
                return true;
            });
        // end::update-document-with-conflict-handler[]
    }

    public void testQuerySyntaxAll() throws CouchbaseLiteException {
        // tag::query-syntax-all[]
        Database database;
        try {
            database = new Database("hotels");
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
            return;
        }

        Collection collection = database.getDefaultCollection();
        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection));
        // end::query-syntax-all[]

        // tag::query-access-all[]
        Map<String, Hotel> hotels = new HashMap<>();
        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {
                // get the k-v pairs from the 'hotel' key's value into a dictionary
                Dictionary docsProp = result.getDictionary(0); // <.>
                String docsId = docsProp.getString("id");
                String docsName = docsProp.getString("Name");
                String docsType = docsProp.getString("Type");
                String docsCity = docsProp.getString("City");

                // Alternatively, access results value dictionary directly
                final Hotel hotel = new Hotel();
                hotel.setId(result.getDictionary(0).getString("id")); // <.>
                hotel.setType(result.getDictionary(0).getString("Type"));
                hotel.setName(result.getDictionary(0).getString("Name"));
                hotel.setCity(result.getDictionary(0).getString("City"));
                hotel.setCountry(result.getDictionary(0).getString("Country"));
                hotel.setDescription(result.getDictionary(0).getString("Description"));
                hotels.put(hotel.getId(), hotel);
            }
        }
        finally {
            database.close();
        }
        // end::query-access-all[]
    }

    public void testQueryAccessJson() throws CouchbaseLiteException, JsonProcessingException {
        Database database;
        try {
            database = new Database("hotels");
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
            return;
        }

        Collection collection = database.getDefaultCollection();
        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection));

        // tag::query-access-json[]
        ObjectMapper mapper = new ObjectMapper();
        ArrayList<Hotel> hotels = new ArrayList<>();
        HashMap<String, Object> dictFromJSONstring;

        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {

                // Get result as JSON string
                String thisJsonString = result.toJSON(); // <.>

                // Get Java  Hashmap from JSON string
                dictFromJSONstring =
                    mapper.readValue(thisJsonString, HashMap.class); // <.>


                // Use created hashmap
                String hotelId = dictFromJSONstring.get("id").toString();
                String hotelType = dictFromJSONstring.get("type").toString();
                String hotelname = dictFromJSONstring.get("name").toString();


                // Get custom object from Native 'dictionary' object
                Hotel thisHotel =
                    mapper.readValue(thisJsonString, Hotel.class); // <.>
                hotels.add(thisHotel);
            }
        }
        // end::query-access-json[]

        database.close();
    }

    public void testQuerySyntaxProps() throws CouchbaseLiteException {

        // tag::query-syntax-props[]
        Database database;
        try {
            database = new Database("hotels");
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
            return;
        }

        Collection collection = database.getDefaultCollection();

        Query listQuery =
            QueryBuilder.select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property("name"),
                    SelectResult.property("Name"),
                    SelectResult.property("Type"),
                    SelectResult.property("City"))
                .from(DataSource.collection(collection));

        // end::query-syntax-props[]

        // tag::query-access-props[]
        ResultSet resultSet = listQuery.execute();
        HashMap<String, Hotel> hotels = new HashMap<>();
        try {
            for (Result result: resultSet) {

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
                String docId =
                    thisDocsProps.getOrDefault("id", null).toString();
                String docName =
                    thisDocsProps.getOrDefault("Name", null).toString();
                String docType =
                    thisDocsProps.getOrDefault("Type", null).toString();
                String docCity =
                    thisDocsProps.getOrDefault("City", null).toString();
            }
        }
        finally {
            if (resultSet != null) { resultSet.close(); }
            database.close();
        }
        // end::query-access-props[]
    }

    public void testQuerySyntaxCount() throws CouchbaseLiteException {
        Database database;
        try {
            database = new Database("hotels");
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
            return;
        }

        Collection collection = database.getDefaultCollection();

        // tag::query-syntax-count-only[]
        Query listQuery = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
            .from(DataSource.collection(collection));

        // end::query-syntax-count-only[]


        // tag::query-access-count-only[]
        ResultSet resultSet = listQuery.execute();
        ResultSet resultSet2 = null;
        try {
            for (Result result: resultSet) {

                // Retrieve count using key 'mycount'
                Integer altDocId = result.getInt("mycount");

                // Alternatively, use the index
                Integer orDocId = result.getInt(0);
            }
            // Or even miss out the for-loop altogether
            resultSet2 = listQuery.execute();
            Integer resultCount = resultSet2.next().getInt("mycount");
        }
        catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        finally {
            if (resultSet != null) { resultSet.close(); }
            if (resultSet2 != null) { resultSet2.close(); }
        }
        // end::query-access-count-only[]

        database.close();
    }


    @NonNull
    private Collection getCollection() { return defaultCollection; }
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
// end::ziputils-unzip[]

@SuppressWarnings({"unused", "ConstantConditions"})
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

@SuppressWarnings({"unused", "ConstantConditions"})
class TensorFlowModel {
    public static Map<String, Object> predictImage(byte[] data) {
        return null;
    }
}
// end::predictive-model[]

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::local-win-conflict-resolver[]
class LocalWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getLocalDocument();
    }
}
// end::local-win-conflict-resolver[]

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::remote-win-conflict-resolver[]
class RemoteWinConflictResolver implements ConflictResolver {
    public Document resolve(Conflict conflict) {
        return conflict.getRemoteDocument();
    }
}
// end::remote-win-conflict-resolver[]

@SuppressWarnings({"unused", "ConstantConditions"})
// tag::merge-conflict-resolver[]
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
    private Replicator replicator;

    public void initCouchbase() throws CouchbaseLiteException {
        // tag::message-endpoint[]
        Database database = new Database("dbName");

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        MessageEndpoint messageEndpointTarget = new MessageEndpoint(
            "UID:123",
            "active",
            ProtocolType.MESSAGE_STREAM,
            this);
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        ReplicatorConfiguration config = new ReplicatorConfiguration(messageEndpointTarget);
        config.addCollection(database.getDefaultCollection(), null);

        // Create the replicator object.
        replicator = new Replicator(config);
        // Start the replication.
        replicator.start();
        // end::message-endpoint-replicator[]

        database.close();
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
// Check context validity for JVM cf Android
class PassivePeerConnection implements MessageEndpointConnection {
    private MessageEndpointListener messageEndpointListener;
    private ReplicatorConnection replicatorConnection;

    public void startListener() throws CouchbaseLiteException {
        // tag::listener[]
        Database database = new Database("dbName");
        MessageEndpointListenerConfiguration listenerConfiguration = new MessageEndpointListenerConfiguration(
            new HashSet<>(Arrays.asList(database.getDefaultCollection())),
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
        PassivePeerConnection connection = new PassivePeerConnection(); /* implements
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
}package com.couchbase.codesnippets;

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
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;


@SuppressWarnings({"unused", "ConstantConditions"})
public class JSONExamples {
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
            System.out.println(dict.getString("name"));
            db.save(new MutableDocument(dict.getString("id"), dict.toMap()));
        }

        final Array features = db.getDocument("1002").getArray("features");
        for (Object feature: features.toList()) { System.out.println(feature.toString()); }
        System.out.println(features.toJSON()); // <.>
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
        System.out.println(mDict);

        System.out.println("Details for: " + mDict.getString("name"));
        for (String key: mDict.getKeys()) {
            System.out.println(key + " => " + mDict.getValue(key));
        }
        // end::tojson-dictionary[]
    }

    public void jsonDocumentExample(Database srcDb, Database dstDb) throws CouchbaseLiteException {
        // tag::tojson-document[]
        // github tag=tojson-document
        final Query listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(srcDb));

        try (ResultSet results = listQuery.execute()) {
            for (Result row: results) {
                final String thisId = row.getString("metaId");

                final String json = srcDb.getDocument(thisId).toJSON(); // <.>
                System.out.println("JSON String = " + json);

                final MutableDocument hotelFromJSON = new MutableDocument(thisId, json); // <.>

                dstDb.save(hotelFromJSON);

                for (Map.Entry<String, Object> entry: dstDb.getDocument(thisId).toMap().entrySet()) {
                    System.out.println(entry.getKey() + " => " + entry.getValue()); // <.>
                }
            }
        }
        // end::tojson-document[]
    }

    public void jsonQueryExample(Query query) throws CouchbaseLiteException, JSONException {
        try (ResultSet results = query.execute()) {
            for (Result row: results) {

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
}

