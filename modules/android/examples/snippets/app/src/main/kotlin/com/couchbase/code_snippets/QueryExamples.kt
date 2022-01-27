//
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
package com.couchbase.code_snippets

import android.util.Log
import com.couchbase.lite.*
import com.couchbase.lite.Function
import com.fasterxml.jackson.databind.ObjectMapper
import org.json.JSONException


private const val TAG = "QUERY"
private const val DATABASE_NAME = "database"

data class Hotel(
    var description: String? = null,
    var country: String? = null,
    var city: String? = null,
    var name: String? = null,
    var type: String? = null,
    var id: String? = null
)

@Suppress("unused")
class QueryExamples(private val database: Database) {

    // ### Indexing
    @Throws(CouchbaseLiteException::class)
    fun testIndexing() {
        // tag::query-index[]
        database.createIndex( "TypeNameIndex",
              ValueIndexConfiguration( "type", "name")
        // end::query-index[]
    }

    fun testIndexing_Querybuilder() {
        // tag::query-index_Querybuilder[]
        database.createIndex(
            "TypeNameIndex",
            IndexBuilder.valueIndex(
                ValueIndexItem.property("type"),
                ValueIndexItem.property("name")
            )
        )
        // end::query-index_Querybuilder[]
    }

    // ### SELECT statement
    fun testSelectStatement() {
        // tag::query-select-props[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("type")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.expression(Meta.id))
            .execute()

        for (result in rs) {
            Log.i(TAG, "hotel id ->${result.getString("id")}")
            Log.i(TAG, "hotel name -> ${result.getString("name")}")
        }
        // end::query-select-props[]
      }

      // META function
      @Throws(CouchbaseLiteException::class)
      fun testMetaFunction() {
        // tag::query-select-meta[]
        val rs = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.database(database))
        .where(Expression.property("type").equalTo(Expression.string("airport")))
        .orderBy(Ordering.expression(Meta.id))
        .execute()

        for (result in rs) {
          Log.w(TAG, "airport id ->${result.getString("id")}")
          Log.w(TAG, "airport id -> ${result.getString(0)}")
        }
        // end::query-select-meta[]
      }

      // ### all(*)
    @Throws(CouchbaseLiteException::class)
    fun testSelectAll() {
        // tag::query-select-all[]
        val queryAll = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
        // end::query-select-all[]

        // tag::live-query[]
        val query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database)) // <.>

        // Adds a query change listener.
        // Changes will be posted on the main queue.
        val token = query.addChangeListener { change ->
            change.results?.let {
                for (result in it) {
                    Log.d(TAG, "results: ${result.keys}")
                    /* Update UI */
                }
            } // <.>
        }

        // end::live-query[]

        // tag::stop-live-query[]
        query.removeChangeListener(token)
        // end::stop-live-query[]

        for (result in query.execute()) {
            Log.i(TAG, "hotel -> ${result.getDictionary(DATABASE_NAME)?.toMap()}")
        }
    }


    // ###　WHERE statement
    @Throws(CouchbaseLiteException::class)
    fun testWhereStatement() {
        // tag::query-where[]
        val rs = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .limit(Expression.intValue(10))
            .execute()
        for (result in rs) {
            result.getDictionary(DATABASE_NAME)?.let {
                Log.i(TAG, "name -> ${it.getString("name")}")
                Log.i(TAG, "type -> ${it.getString("type")}")
            }
        }
        // end::query-where[]
    }

    fun testQueryDeletedDocuments() {
        // tag::query-deleted-documents[]
        // Query documents that have been deleted
        val query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Meta.deleted)
        // end::query-deleted-documents[]
    }

    // ####　Collection Operators
    @Throws(CouchbaseLiteException::class)
    fun testCollectionStatement() {
        // tag::query-collection-operator-contains[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name"),
                SelectResult.property("public_likes")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("hotel"))
                    .and(
                        ArrayFunction.contains(
                            Expression.property("public_likes"),
                            Expression.string("Armani Langworth")
                        )
                    )
            )
            .execute()
        for (result in rs) {
            Log.i(TAG, "public_likes -> ${result.getArray("public_likes")?.toList()}")
        }
        // end::query-collection-operator-contains[]
    }

    // IN operator
    @Throws(CouchbaseLiteException::class)
    fun testInOperator() {
        // tag::query-collection-operator-in[]
        val rs = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.string("Armani").`in`(
                    Expression.property("first"),
                    Expression.property("last"),
                    Expression.property("username")
                )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "public_likes -> ${result.toMap()}")
        }
        // end::query-collection-operator-in[]
    }

    // Pattern Matching
    @Throws(CouchbaseLiteException::class)
    fun testPatternMatching() {
        // tag::query-like-operator[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .like(Expression.string("royal engineers museum"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-like-operator[]
    }

    // ### Wildcard Match
    @Throws(CouchbaseLiteException::class)
    fun testWildcardMatch() {
        // tag::query-like-operator-wildcard-match[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .like(Expression.string("eng%e%"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-like-operator-wildcard-match[]
    }

    // Wildcard Character Match
    @Throws(CouchbaseLiteException::class)
    fun testWildCharacterMatch() {
        // tag::query-like-operator-wildcard-character-match[]

        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .like(Expression.string("eng____r"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-like-operator-wildcard-character-match[]
    }

    // ### Regex Match
    @Throws(CouchbaseLiteException::class)
    fun testRegexMatch() {
        // tag::query-regex-operator[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("landmark"))
                    .and(
                        Function.lower(Expression.property("name"))
                            .regex(Expression.string("\\beng.*r\\b"))
                    )
            )
            .execute()
        for (result in rs) {
            Log.i(TAG, "name -> ${result.getString("name")}")
        }
        // end::query-regex-operator[]
    }

    // JOIN statement
    @Throws(CouchbaseLiteException::class)
    fun testJoinStatement() {
        // tag::query-join[]
        val rs = QueryBuilder.select(
            SelectResult.expression(Expression.property("name").from("airline")),
            SelectResult.expression(Expression.property("callsign").from("airline")),
            SelectResult.expression(Expression.property("destinationairport").from("route")),
            SelectResult.expression(Expression.property("stops").from("route")),
            SelectResult.expression(Expression.property("airline").from("route"))
        )
            .from(DataSource.database(database).`as`("airline"))
            .join(
                Join.join(DataSource.database(database).`as`("route"))
                    .on(
                        Meta.id.from("airline")
                            .equalTo(Expression.property("airlineid").from("route"))
                    )
            )
            .where(
                Expression.property("type").from("route").equalTo(Expression.string("route"))
                    .and(
                        Expression.property("type").from("airline")
                            .equalTo(Expression.string("airline"))
                    )
                    .and(
                        Expression.property("sourceairport").from("route")
                            .equalTo(Expression.string("RIX"))
                    )
            )
            .execute()

        for (result in rs) {
            Log.i(TAG, "name -> ${result.toMap()}")
        }
        // end::query-join[]
    }


    // ### GROUPBY statement
    @Throws(CouchbaseLiteException::class)
    fun testGroupByStatement() {
        // tag::query-groupby[]
        val rs = QueryBuilder.select(
            SelectResult.expression(Function.count(Expression.string("*"))),
            SelectResult.property("country"),
            SelectResult.property("tz")
        )
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo(Expression.string("airport"))
                    .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300)))
            )
            .groupBy(
                Expression.property("country"), Expression.property("tz")
            )
            .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending())
            .execute()

        for (result in rs) {
            result.let {
                Log.i(
                    TAG,
                    "There are ${it.getInt("$1")} airports on the ${
                        it.getString("tz")
                    } timezone located in ${
                        it.getString("country")
                    } and above 300ft"
                )
            }
            // end::query-groupby[]
        }
    }

    // ### ORDER BY statement
    @Throws(CouchbaseLiteException::class)
    fun testOrderByStatement() {
        // tag::query-orderby[]
        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel")))
            .orderBy(Ordering.property("name").ascending())
            .limit(Expression.intValue(10))
            .execute()

        for (result in rs) {
            Log.i(TAG, "${result.toMap()}")
        }
        // end::query-orderby[]
    }


    // ### EXPLAIN statement
    // tag::query-explain[]
    @Throws(CouchbaseLiteException::class)
    fun testExplainStatement() {
        // tag::query-explain-all[]
        var query: Query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("university")))
            .groupBy(Expression.property("country"))
            .orderBy(Ordering.property("name").descending()) // <.>
        Log.i(TAG, query.explain()) // <.>
        // end::query-explain-all[]

        // tag::query-explain-like[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").like(Expression.string("%hotel%"))) // <.>
        Log.i(TAG, query.explain())
        // end::query-explain-like[]

        // tag::query-explain-nopfx[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.property("type").like(Expression.string("hotel%")) // <.>
                    .and(Expression.property("name").like(Expression.string("%royal%")))
            )
        Log.i(TAG, query.explain())
        // end::query-explain-nopfx[]

        // tag::query-explain-function[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Function.lower(
                    Expression.property("type").equalTo(Expression.string("hotel"))
                )
            ) // <.>
        Log.i(TAG, query.explain())
        // end::query-explain-function[]

        // tag::query-explain-nofunction[]
        query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property("type").equalTo(Expression.string("hotel"))) // <.>
        Log.i(TAG, query.explain())
        // end::query-explain-nofunction[]
    }
// end::query-explain[]

    @Throws(CouchbaseLiteException::class)
    fun prepareIndex() {
        // tag::fts-index[]
        val config = FullTextIndexConfiguration("overview").ignoreAccents(false)

        database.createIndex( "overviewFTSIndex", config);
        // end::fts-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testFTS() {
        // tag::fts-query[]

        val ftsQuery =
              database.createQuery(
                "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK(overviewFTSIndex)")

        ftsQuery.execute().allResults().forEach {
          Log.i(TAG, "${result.getString("id")}: ${result.getString("overview")}")
        }

        // end::fts-query[]
    }

    @Throws(CouchbaseLiteException::class)
    fun prepareIndex_Querybuilder() {
        // tag::fts-index_Querybuilder[]
        database.createIndex(
            "overviewFTSIndex",
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("overview")).ignoreAccents(false)
        )
        // end::fts-index_Querybuilder[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testFTS_Querybuilder() {
        // tag::fts-query_Querybuilder[]

        val ftsQuery =
              QueryBuilder.select(SelectResult.expression(Meta.id),
                                  SelectResult.expression(overview))
                          .from(DataSource.database(database))
                          .where(FullTextFunction.match("overviewFTSIndex", "michigan"))
                          .execute()

        ftsQuery.execute().allResults().forEach {
          Log.i(TAG, "${result.getString("Meta.id")}: ${result.getString("overview")}")
          }



        // end::fts-query_Querybuilder[]
    }


    fun testQuerySyntaxAll(currentUser: String) {
        // tag::query-syntax-all[]
        val listQuery: Query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(openOrCreateDatabaseForUser(currentUser)))

            // end::query-syntax-all[]
        // tag::query-access-all[]
        val hotels: HashMap<String, Hotel> = HashMap()

        for (result in listQuery.execute().allResults()) {
            // get the k-v pairs from the 'hotel' key's value into a dictionary
            val thisDocsProps = result.getDictionary(0) // <.>
            val thisDocsId = thisDocsProps!!.getString("id")
            val thisDocsName = thisDocsProps.getString("name")
            val thisDocsType = thisDocsProps.getString("type")
            val thisDocsCity = thisDocsProps.getString("city")

            // Alternatively, access results value dictionary directly
            val id = result.getDictionary(0)?.getString("id").toString() // <.>
            hotels[id] = Hotel(
                id,
                result.getDictionary(0)?.getString("type"),
                result.getDictionary(0)?.getString("name"),
                result.getDictionary(0)?.getString("city"),
                result.getDictionary(0)?.getString("country"),
                result.getDictionary(0)?.getString("description")
            )
        }

        // end::query-access-all[]
    }

    @Throws(CouchbaseLiteException::class, JSONException::class)
    fun testQuerySyntaxJson(currentUser: String, argDb: Database) {
        val db = argDb
        // tag::query-syntax-json[]
        // Example assumes Hotel class object defined elsewhere

        // Build the query
        val listQuery: Query = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database(db))

        // end::query-syntax-json[]
        // tag::query-access-json[]
        // Uses Jackson JSON processor
        val mapper = ObjectMapper()
        val hotels: ArrayList<Hotel> = ArrayList()

        for (result in listQuery.execute()) {

            // Get result as JSON string
            val json = result.toJSON() // <.>

            // Get Hashmap from JSON string
            val dictFromJSONstring = mapper.readValue(json, HashMap::class.java) // <.>

            // Use created hashmap
            val hotelId = dictFromJSONstring["id"].toString() //
            val hotelType = dictFromJSONstring["type"].toString()
            val hotelname = dictFromJSONstring["name"].toString()


            // Get custom object from JSON string
            val thisHotel = mapper.readValue(json, Hotel::class.java) // <.>
            hotels.add(thisHotel)
        }
        // end::query-access-json[]
    }
/* end func testQuerySyntaxJson */



    fun testQuerySyntaxProps(currentUser: String) {
        // tag::query-select-props[]
        // tag::query-syntax-props[]

        val rs = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property("country"),
                SelectResult.property("name")
            )
            .from(DataSource.database(database))

        // end::query-syntax-props[]

        // tag::query-access-props[]
        for (result in rs.execute().allResults()) {
            Log.i(TAG, "Hotel name -> ${result.getString("name")}, in ${result.getString("country")}" )
        }
        // end::query-access-props[]
        // end::query-select-props[]
    }

    fun testQuerySyntaxCount(currentUser: String) {
        // tag::query-syntax-count-only[]

        val rs = QueryBuilder
            .select(
                SelectResult.expression(Function.count(Expression.string("*"))).as("mycount")) // <.>
            .from(DataSource.database(database))

        // end::query-syntax-count-only[]

        // tag::query-access-count-only[]
        for (result in rs.execute().allResults()) {
            Log.i(TAG, "name -> ${result.getInt("mycount").toString()}")
        }
        // end::query-access-count-only[]
    }


    fun testQuerySyntaxId(currentUser: String) {
        // tag::query-select-meta
        // tag::query-syntax-id[]

        val rs = QueryBuilder
        .select(
          SelectResult.expression(Meta.id).as("hotelId"))
          .from(DataSource.database(database))

          // end::query-syntax-id[]

        // tag::query-access-id[]
        for (result in rs.execute().allResults()) {
          Log.i(TAG, "hotel id ->${result.getString("hotelId")}")
        }
        // end::query-access-id[]
        // end::query-select-meta
    }


    fun docsOnlyQuerySyntaxN1QL(argDb: Database): List<Result> {
      // For Documentation -- N1QL Query using parameters
      val db = argDb
      // tag::query-syntax-n1ql[]
      val thisQuery = db.createQuery(
            "SELECT META().id AS id FROM _ WHERE type = \"hotel\"") // <.>

      return thisQuery.execute().allResults()

      // end::query-syntax-n1ql[]
  }

  fun docsOnlyQuerySyntaxN1QLParams(argDb: Database): List<Result> {
      // For Documentation -- N1QL Query using parameters
      val db = argDb
      // tag::query-syntax-n1ql-params[]
      val thisQuery = db.createQuery(
            "SELECT META().id AS id FROM _ WHERE type = \$type") // <.>

      thisQuery.parameters = Parameters().setString("type", "hotel") // <.>

      return thisQuery.execute().allResults()

      // end::query-syntax-n1ql-params[]
  }

  fun testQuerySyntaxPagination(currentUser: String) {
    // tag::query-syntax-pagination[]
    val limit = 20
    val offset = 0

    val rs = QueryBuilder
      .select(SelectResult.all())
      .from(DataSource.database(database))
      .where(Expression.property("type").equalTo(Expression.string("hotel")))
      .limit(Expression.intValue(limit), Expression.intValue(offset))

    // end::query-syntax-pagination[]
  }

    fun openOrCreateDatabaseForUser(argUser: String): Database = Database(argUser) {

    }
