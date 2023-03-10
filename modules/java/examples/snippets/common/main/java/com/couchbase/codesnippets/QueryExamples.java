//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jetbrains.annotations.NotNull;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.ArrayFunction;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.FullTextFunction;
import com.couchbase.lite.FullTextIndexConfiguration;
import com.couchbase.lite.FullTextIndexItem;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Join;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Meta;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Parameters;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.ValueIndexConfiguration;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "ConstantConditions", "UnusedAssignment"})
public class QueryExamples {
    public void indexingExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-index[]
        collection.createIndex("TypeNameIndex", new ValueIndexConfiguration("type", "name"));
        // end::query-index[]
    }

    public void selectStatementExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log("hotel id -> " + result.getString("id"));
                Logger.log("hotel name -> " + result.getString("name"));
            }
        }
        // end::query-select-props[]
    }

    public void whereStatementExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log("name -> " + all.getString("name"));
                Logger.log("type -> " + all.getString("type"));
            }
        }
        // end::query-where[]
    }

    public void collectionStatementExample(Collection collection) throws CouchbaseLiteException {

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
                Logger.log("public_likes -> " + result.getArray("public_likes").toList());
            }
        }
        // end::query-collection-operator-contains[]
    }

    public void patternMatchingExample(Collection collection) throws CouchbaseLiteException {

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
                Logger.log("name -> " + result.getString("name"));
            }
        }
        // end::query-like-operator[]
    }

    public void wildcardMatchExample(Collection collection) throws CouchbaseLiteException {

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
                Logger.log("name ->  " + result.getString("name"));
            }
        }
        // end::query-like-operator-wildcard-match[]
    }

    public void wildCharacterMatchExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log("name -> " + result.getString("name"));
            }
        }
        // end::query-like-operator-wildcard-character-match[]
    }

    public void regexMatchExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log("name -> " + result.getString("name"));
            }
        }
        // end::query-regex-operator[]
    }

    public void queryDeletedDocumentsExample(Collection collection) {

        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Meta.deleted);
        // end::query-deleted-documents[]
    }

    public void joinStatementExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log(result.toMap().toString());
            }
        }
        // end::query-join[]
    }

    public void groupByStatementExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log(String.format(
                    "There are %d airports on the %s timezone located in %s and above 300ft",
                    result.getInt("$1"),
                    result.getString("tz"),
                    result.getString("country")));
            }
        }
        // end::query-groupby[]
    }

    public void orderByStatementExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log(result.toMap().toString());
            }
        }
        // end::query-orderby[]
    }

    public void querySyntaxAllExample(Collection collection) throws CouchbaseLiteException {

        // tag::query-syntax-all[]
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
        // end::query-access-all[]
    }


    public void querySyntaxIdExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-syntax-id[]
        Query listQuery =
            QueryBuilder.select(SelectResult.expression(Meta.id).as("metaID"))
                .from(DataSource.collection(collection));
        // end::query-syntax-id[]

        // tag::query-access-id[]
        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs.allResults()) {

                // get the ID form the result's k-v pair array
                String thisDocsId = result.getString("metaID"); // <.>

                // Get document from DB using retrieved ID
                Document thisDoc = collection.getDocument(thisDocsId);

                // Process document as required
                String thisDocsName = thisDoc.getString("Name");
            }
        }
        // end::query-access-id[]
    }

    public void querySyntaxCountExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-syntax-count-only[]
        Query listQuery = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
            .from(DataSource.collection(collection));
        // end::query-syntax-count-only[]

        // tag::query-access-count-only[]
        try (ResultSet resultSet = listQuery.execute()) {
            for (Result result: resultSet) {

                // Retrieve count using key 'mycount'
                Integer altDocId = result.getInt("mycount");

                // Alternatively, use the index
                Integer orDocId = result.getInt(0);
            }
        }

        // Or even leave out the for-loop altogether
        int resultCount;
        try (ResultSet resultSet = listQuery.execute()) {
            resultCount = resultSet.next().getInt("mycount");
        }
        // end::query-access-count-only[]
    }

    public void querySyntaxPropsExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-syntax-props[]

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
        HashMap<String, Hotel> hotels = new HashMap<>();
        try (ResultSet resultSet = listQuery.execute()) {
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
        // end::query-access-props[]
    }

    public void inOperatorExample(Collection collection) throws CouchbaseLiteException {

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
                Logger.log(result.toMap().toString());
            }
        }
    }

    // tag::query-syntax-pagination-all[]
    public void queryPaginationExample(Collection collection) {
        // tag::query-syntax-pagination[]

        int thisOffset = 0;
        int thisLimit = 20;

        Query listQuery =
            QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(collection))
                .limit(
                    Expression.intValue(thisLimit),
                    Expression.intValue(thisOffset)); // <.>

        // end::query-syntax-pagination[]

    }
    // end::query-syntax-pagination-all[]


    public void selectAllExample(Collection collection) {
        // tag::query-select-all[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel")));
        // end::query-select-all[]

    }

    public void LiveQueryExample(Collection collection) {
        // tag::live-query[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection)); // <.>

        // Adds a query change listener.
        // Changes will be posted on the main queue.
        ListenerToken token = query.addChangeListener(change -> { // <.>
            for (Result result: change.getResults()) {
                Logger.log("results: " + result.getKeys());
                /* Update UI */
            }
        });

        // end::live-query[]

        // tag::stop-live-query[]
        token.remove(); // <.>
        // end::stop-live-query[]
    }

    public void metaFunctionExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-select-meta[]
        Query query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("airport")))
            .orderBy(Ordering.expression(Meta.id));

        try (ResultSet resultSet = query.execute()) {
            for (Result result: resultSet) {
                Logger.log("airport id -> " + result.getString("id"));
                Logger.log("airport id -> " + result.getString(0));
            }
        }
        // end::query-select-meta[]
    }

    // tag::query-explain[]
    public void explainAllExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-all[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("university")))
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").descending()); // <.>
        Logger.log(query.explain()); // <.>
        // end::query-explain-all[]
    }

    public void explainLikeExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-like[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").like(Expression.string("%hotel%"))) // <.>
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").descending()); // <.>
        Logger.log(query.explain());
        // end::query-explain-like[]
    }

    public void explainNoPFXExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-nopfx[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").like(Expression.string("hotel%")) // <.>
                .and(Expression.property("name").like(Expression.string("%royal%"))));
        Logger.log(query.explain());
        // end::query-explain-nopfx[]
    }

    public void explainFnExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-function[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))); // <.>
        Logger.log(query.explain());
        // end::query-explain-function[]
    }

    public void explainNoFnExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-explain-nofunction[]
        Query query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))); // <.>
        Logger.log(query.explain());
        // end::query-explain-nofunction[]
    }
    // end::query-explain[]

    public void prepareIndexExample(Collection collection) throws CouchbaseLiteException {
        // tag::fts-index[]
        FullTextIndexConfiguration config = new FullTextIndexConfiguration("Overview").ignoreAccents(false);
        collection.createIndex("overviewFTSIndex", config);
        // end::fts-index[]
    }

    public void prepareIndexQueryBuilderExample(Collection collection) throws CouchbaseLiteException {
        // tag::fts-index_Querybuilder[]
        collection.createIndex(
            "overviewFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("overviewFTSIndex")).ignoreAccents(false));
        // end::fts-index_Querybuilder[]
    }

    public void indexingQueryBuilderExample(Collection collection) throws CouchbaseLiteException {
        // tag::query-index_Querybuilder[]
        collection.createIndex(
            "TypeNameIndex",
            IndexBuilder.valueIndex(
                ValueIndexItem.property("type"),
                ValueIndexItem.property("name")));
        // end::query-index_Querybuilder[]
    }

    public void ftsExample(Collection collection) throws CouchbaseLiteException {
        final Database database = null;
        // tag::fts-query[]
        Query ftsQuery =
            database.createQuery(
                "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK"
                    + "(overviewFTSIndex)");


        try (ResultSet resultSet = ftsQuery.execute()) {
            for (Result result: resultSet) {
                Logger.log(result.getString("id") + ": " + result.getString("overview"));
            }
        }
        // end::fts-query[]
    }

    public void ftsQueryBuilderExample(Collection collection) throws CouchbaseLiteException {
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
                Logger.log(result.getString("id") + ": " + result.getString("overview"));
            }
        }
        // end::fts-query_Querybuilder[]
    }

    public void querySyntaxJsonExample(@NotNull Collection collection)
        throws CouchbaseLiteException, JsonProcessingException {
        // tag::query-syntax-json[]
        // Example assumes Hotel class object defined elsewhere
        Query listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.collection(collection));
        // end::query-syntax-json[]
        // tag::query-access-json[]
        // Uses Jackson JSON processor
        ObjectMapper mapper = new ObjectMapper();
        List<Hotel> hotels = new ArrayList<>();

        try (ResultSet rs = listQuery.execute()) {
            for (Result result: rs) {
                String json = result.toJSON();
                Map<String, String> dictFromJSONstring = mapper.readValue(json, HashMap.class);

                String hotelId = dictFromJSONstring.get("id");
                String hotelType = dictFromJSONstring.get("type");
                String hotelname = dictFromJSONstring.get("name");

                // Get custom object from JSON string
                Hotel thisHotel = mapper.readValue(json, Hotel.class);
                hotels.add(thisHotel);
            }
        }
    }

    public List<Result> docsOnlyQuerySyntaxN1QL(Database thisDb) throws CouchbaseLiteException {
        // For Documentation -- N1QL Query using parameters
        // tag::query-syntax-n1ql[]
        //  Declared elsewhere: Database thisDb
        Query thisQuery =
            thisDb.createQuery(
                "SELECT META().id AS thisId FROM _ WHERE type = \"hotel\""); // <.>
        try (ResultSet rs = thisQuery.execute()) {
            return rs.allResults();
        }
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

        try (ResultSet rs = thisQuery.execute()) {
            return rs.allResults();
        }
        // end::query-syntax-n1ql-params[]
    }
}

