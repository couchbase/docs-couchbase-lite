package com.example.docsnippet;
import android.app.Application.*;
import android.content.Context;
import android.content.Context.*;
import java.lang.Object;
import java.security.Key;
import java.util.*;
import com.couchbase.lite.*;
import com.couchbase.lite.Dictionary;

public class TestQueries {

    // For Documentation

    Datastore ds = new Datastore();

    Database this_Db = ds.getDB();

    String dbName = this_Db.getName();

    HashMap<String, Object> hotels = new HashMap<>();

    Dictionary thisDocsProps;
    String thisDocsId;
    String thisDocsName;
    String thisDocsType;
    String thisDocsCity;



    static {
        init();
    }

    private Hotel hotel;

    private static void init() {
    }



    public void testQuerySyntaxAll() throws CouchbaseLiteException {

    // tag::query-syntax-all[]
        try {
            this_Db = new Database(dbName);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        Query listQuery = QueryBuilder.select(SelectResult.all())
                .from(DataSource.database(this_Db)); // <.>

    // end::query-syntax-all[]

    // tag::query-access-all[]
        try {
            for (Result result : listQuery.execute().allResults()) {
                int x = result.count();
                // get the k-v pairs from the 'hotel' key's value into a dictionary
                thisDocsProps = result.getDictionary(0); // <.>
                thisDocsId = thisDocsProps.getString("id");
                thisDocsName = thisDocsProps.getString("Name");
                thisDocsType = thisDocsProps.getString("Type");
                thisDocsCity = thisDocsProps.getString("City");

                // Alternatively, access results value dictionary directly
                final Hotel hotel = new Hotel();
                hotel.Id = result.getDictionary(0).getString("id"); // <.>
                hotel.Type = result.getDictionary(0).getString("Type");
                hotel.Name = result.getDictionary(0).getString("Name");
                hotel.City = result.getDictionary(0).getString("City");
                hotel.Country= result.getDictionary(0).getString("Country");
                hotel.Description = result.getDictionary(0).getString("Description");
                hotels.put(hotel.Id, hotel);
            }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

    // end::query-access-all[]
    }

    public void testQuerySyntaxProps() throws CouchbaseLiteException {

    // tag::query-syntax-props[]
        try {
            this_Db = new Database("hotels");
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        Query listQuery =
                QueryBuilder.select(SelectResult.expression(Meta.id),
                        SelectResult.property("name"),
                        SelectResult.property("Name"),
                        SelectResult.property("Type"),
                        SelectResult.property("City"))
                        .from(DataSource.database(this_Db));

    // end::query-syntax-props[]

    // tag::query-access-props[]

        try {
            for (Result result : listQuery.execute().allResults()) {

                // get data direct from result k-v pairs
                final Hotel hotel = new Hotel();
                hotel.Id = result.getString("id");
                hotel.Type = result.getString("Type");
                hotel.Name = result.getString("Name");
                hotel.City = result.getString("City");

                // Store created hotel object in a hashmap of hotels
                hotels.put(hotel.Id, hotel);

                // Get result k-v pairs into a 'dictionary' object
                Map <String, Object> thisDocsProps = result.toMap();
                thisDocsId =
                    thisDocsProps.getOrDefault("id",null).toString();
                thisDocsName =
                    thisDocsProps.getOrDefault("Name",null).toString();
                thisDocsType =
                    thisDocsProps.getOrDefault("Type",null).toString();
                thisDocsCity =
                    thisDocsProps.getOrDefault("City",null).toString();

            }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

    // end::query-access-props[]
    }


    public void testQuerySyntaxCount() throws CouchbaseLiteException {

    // tag::query-syntax-count-only[]
        try {
            this_Db = new Database("hotels");
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        Query listQuery = QueryBuilder.select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
                .from(DataSource.database(this_Db));

    // end::query-syntax-count-only[]


    // tag::query-access-count-only[]
        try {
            for (Result result : listQuery.execute()) {

                // Retrieve count using key 'mycount'
                Integer altDocId = result.getInt("mycount");

                // Alternatively, use the index
                Integer orDocId = result.getInt(0);
            }
            // Or even omit the for-loop altogether
            Integer resultCount = listQuery.execute().next().getInt("mycount");

        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    // end::query-access-count-only[]
    }


    public void testQuerySyntaxId() throws CouchbaseLiteException {
    // tag::query-syntax-id[]
        try {
            this_Db = new Database("hotels");
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }


        Query listQuery =
                QueryBuilder.select(SelectResult.expression(Meta.id).as("metaID"))
                        .from(DataSource.database(this_Db));

    // end::query-syntax-id[]


    // tag::query-access-id[]

        try {
            for (Result result : listQuery.execute().allResults()) {

                // get the ID form the result's k-v pair array
                thisDocsId = result.getString("metaID"); // <.>

                // Get document from DB using retrieved ID
                Document thisDoc = this_Db.getDocument(thisDocsId);

                // Process document as required
                thisDocsName = thisDoc.getString("Name");

            }
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

    // end::query-access-id[]

    }


    // tag::query-syntax-pagination-all[]
    public void testQueryPagination() throws CouchbaseLiteException {


    // tag::query-syntax-pagination[]
        int thisOffset = 0;
        int thisLimit = 20;

        try {
            this_Db = new Database("hotels");
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        Query listQuery =
                QueryBuilder
                        .select(SelectResult.all())
                        .from(DataSource.database(this_Db))
                        .limit(Expression.intValue(thisLimit), Expression.intValue(thisOffset)); // <.>

    // end::query-syntax-pagination[]

    }

    // end::query-syntax-pagination-all[]



} // class
