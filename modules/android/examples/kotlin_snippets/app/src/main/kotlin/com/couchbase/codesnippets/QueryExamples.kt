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
@file:Suppress("UNUSED_VARIABLE", "unused", "UNUSED_PARAMETER")

package com.couchbase.codesnippets

import com.couchbase.codesnippets.util.log
import com.couchbase.lite.ArrayFunction
import com.couchbase.lite.Collection
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.Expression
import com.couchbase.lite.FullTextFunction
import com.couchbase.lite.FullTextIndexConfigurationFactory
import com.couchbase.lite.FullTextIndexItem
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.Join
import com.couchbase.lite.Meta
import com.couchbase.lite.Ordering
import com.couchbase.lite.Parameters
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.Result
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndexConfigurationFactory
import com.couchbase.lite.ValueIndexItem
import com.couchbase.lite.newConfig
import com.fasterxml.jackson.databind.ObjectMapper


private const val TAG = "QUERY"

// ### Indexing
fun indexingExample(collection: Collection) {

    // tag::query-index[]
    collection.createIndex(
        "TypeNameIndex",
        ValueIndexConfigurationFactory.newConfig("type", "name")
    )
    // end::query-index[]
}

// ### SELECT statement
fun selectStatementExample(collection: Collection) {

    // tag::query-select-props[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("name"),
            SelectResult.property("type")
        )
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
        .orderBy(Ordering.expression(Meta.id))

    query.execute().use { rs ->
        rs.forEach {
            log("hotel id ->${it.getString("id")}")
            log("hotel name -> ${it.getString("name")}")
        }
    }
    // end::query-select-props[]
}

fun whereStatementExample(collection: Collection) {

    // tag::query-where[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
        .limit(Expression.intValue(10))

    query.execute().use { rs ->
        rs.forEach { result ->
            result.getDictionary("myDatabase")?.let {
                log("name -> ${it.getString("name")}")
                log("type -> ${it.getString("type")}")
            }
        }
    }
    // end::query-where[]
}

// ####　Collection Operators
fun collectionStatementExample(collection: Collection) {
    // tag::query-collection-operator-contains[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("name"),
            SelectResult.property("public_likes")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("hotel"))
                .and(
                    ArrayFunction.contains(
                        Expression.property("public_likes"),
                        Expression.string("Armani Langworth")
                    )
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("public_likes -> ${it.getArray("public_likes")?.toList()}")
        }
    }
    // end::query-collection-operator-contains[]
}

// Pattern Matching
fun patternMatchingExample(collection: Collection) {
    // tag::query-like-operator[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .like(Expression.string("royal engineers museum"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-like-operator[]
}

// ### Wildcard Match
fun wildcardMatchExample(collection: Collection) {
    // tag::query-like-operator-wildcard-match[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .like(Expression.string("eng%e%"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-like-operator-wildcard-match[]
}

// Wildcard Character Match
fun wildCharacterMatchExample(collection: Collection) {
    // tag::query-like-operator-wildcard-character-match[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .like(Expression.string("eng____r"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-like-operator-wildcard-character-match[]
}

// ### Regex Match
fun regexMatchExample(collection: Collection) {
    // tag::query-regex-operator[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("landmark"))
                .and(
                    Function.lower(Expression.property("name"))
                        .regex(Expression.string("\\beng.*r\\b"))
                )
        )
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.getString("name")}")
        }
    }
    // end::query-regex-operator[]
}

// ###　WHERE statement
fun queryDeletedDocumentsExample(collection: Collection) {
    // tag::query-deleted-documents[]
    // Query documents that have been deleted
    val query = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.collection(collection))
        .where(Meta.deleted)
    // end::query-deleted-documents[]
}

// JOIN statement
fun joinStatementExample(collection: Collection) {
    // tag::query-join[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Expression.property("name").from("airline")),
            SelectResult.expression(Expression.property("callsign").from("airline")),
            SelectResult.expression(Expression.property("destinationairport").from("route")),
            SelectResult.expression(Expression.property("stops").from("route")),
            SelectResult.expression(Expression.property("airline").from("route"))
        )
        .from(DataSource.collection(collection).`as`("airline"))
        .join(
            Join.join(DataSource.collection(collection).`as`("route"))
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
    query.execute().use { rs ->
        rs.forEach {
            log("name -> ${it.toMap()}")
        }
    }
    // end::query-join[]
}

// ### GROUPBY statement
fun groupByStatementExample(collection: Collection) {
    // tag::query-groupby[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Function.count(Expression.string("*"))),
            SelectResult.property("country"),
            SelectResult.property("tz")
        )
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").equalTo(Expression.string("airport"))
                .and(Expression.property("geo.alt").greaterThanOrEqualTo(Expression.intValue(300)))
        )
        .groupBy(
            Expression.property("country"), Expression.property("tz")
        )
        .orderBy(Ordering.expression(Function.count(Expression.string("*"))).descending())
    query.execute().use { rs ->
        rs.forEach {
            log(
                "There are ${it.getInt("$1")} airports on the ${
                    it.getString("tz")
                } timezone located in ${
                    it.getString("country")
                } and above 300ft"
            )
        }
    }
    // end::query-groupby[]
}

// ### ORDER BY statement
fun orderByStatementExample(collection: Collection) {
    // tag::query-orderby[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
        .orderBy(Ordering.property("name").ascending())
        .limit(Expression.intValue(10))

    query.execute().use { rs ->
        rs.forEach {
            log("${it.toMap()}")
        }
    }
    // end::query-orderby[]
}

fun querySyntaxAllExample(collection: Collection) {
    // tag::query-syntax-all[]
    val listQuery = QueryBuilder.select(SelectResult.all())
        .from(DataSource.collection(collection))
    // end::query-syntax-all[]

    // tag::query-access-all[]
    val hotels = mutableMapOf<String, Hotel>()
    listQuery.execute().use { rs ->
        rs.allResults().forEach {
            // get the k-v pairs from the 'hotel' key's value into a dictionary
            val thisDocsProps = it.getDictionary(0) // <.>
            val thisDocsId = thisDocsProps!!.getString("id")
            val thisDocsName = thisDocsProps.getString("name")
            val thisDocsType = thisDocsProps.getString("type")
            val thisDocsCity = thisDocsProps.getString("city")

            // Alternatively, access results value dictionary directly
            val id = it.getDictionary(0)?.getString("id").toString() // <.>
            hotels[id] = Hotel(
                id,
                it.getDictionary(0)?.getString("type"),
                it.getDictionary(0)?.getString("name"),
                it.getDictionary(0)?.getString("city"),
                it.getDictionary(0)?.getString("country"),
                it.getDictionary(0)?.getString("description")
            )
        }
    }
    // end::query-access-all[]
}

fun querySyntaxIdExample(collection: Collection) {
    // tag::query-select-meta
    // tag::query-syntax-id[]
    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id).`as`("hotelId")
        )
        .from(DataSource.collection(collection))

    // end::query-syntax-id[]

    // tag::query-access-id[]
    query.execute().use { rs ->
        rs.allResults().forEach {
            log("hotel id ->${it.getString("hotelId")}")
        }
    }
    // end::query-access-id[]
    // end::query-select-meta
}

fun querySyntaxCountExample(collection: Collection) {
    // tag::query-syntax-count-only[]

    val query = QueryBuilder
        .select(
            SelectResult.expression(Function.count(Expression.string("*"))).`as`("mycount")
        ) // <.>
        .from(DataSource.collection(collection))

    // end::query-syntax-count-only[]

    // tag::query-access-count-only[]
    query.execute().use { rs ->
        rs.allResults().forEach {
            log("name -> ${it.getInt("mycount")}")
        }
    }
    // end::query-access-count-only[]
}

fun querySyntaxPropsExample(collection: Collection) {
    // tag::query-syntax-props[]

    val query = QueryBuilder
        .select(
            SelectResult.expression(Meta.id),
            SelectResult.property("country"),
            SelectResult.property("name")
        )
        .from(DataSource.collection(collection))

    // end::query-syntax-props[]

    // tag::query-access-props[]
    query.execute().use { rs ->
        rs.allResults().forEach {
            log("Hotel name -> ${it.getString("name")}, in ${it.getString("country")}")
        }
    }
    // end::query-access-props[]
}

// IN operator
fun inOperatorExample(collection: Collection) {
    // tag::query-collection-operator-in[]
    val query = QueryBuilder.select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            Expression.string("Armani").`in`(
                Expression.property("first"),
                Expression.property("last"),
                Expression.property("username")
            )
        )

    query.execute().use { rs ->
        rs.forEach {
            log("public_likes -> ${it.toMap()}")
        }
    }
    // end::query-collection-operator-in[]
}


// tag::query-syntax-pagination-all[]
fun queryPaginationExample(collection: Collection) {
    // tag::query-syntax-pagination[]
    val thisOffset = 0
    val thisLimit = 20
    val listQuery = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .limit(
            Expression.intValue(thisLimit),
            Expression.intValue(thisOffset)
        ) // <.>

    // end::query-syntax-pagination[]
}
// end::query-syntax-pagination-all[]

// ### all(*)
fun selectAllExample(collection: Collection) {
    // tag::query-select-all[]
    val queryAll = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel")))
    // end::query-select-all[]

}

fun liveQueryExample(collection: Collection) {
    // tag::live-query[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection)) // <.>

    // Adds a query change listener.
    // Changes will be posted on the main queue.
    val token = query.addChangeListener { change ->
        change.results?.let { rs ->
            rs.forEach {
                log("results: ${it.keys}")
                /* Update UI */
            }
        } // <.>
    }

    // end::live-query[]

    // tag::stop-live-query[]
    token.remove()
    // end::stop-live-query[]
}

// META function
fun metaFunctionExample(collection: Collection) {
    // tag::query-select-meta[]
    val query = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("airport")))
        .orderBy(Ordering.expression(Meta.id))

    query.execute().use { rs ->
        rs.forEach {
            log("airport id ->${it.getString("id")}")
            log("airport id -> ${it.getString(0)}")
        }
    }
    // end::query-select-meta[]
}

// ### EXPLAIN statement
// tag::query-explain[]
fun explainAllExample(collection: Collection) {
    // tag::query-explain-all[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("university")))
        .groupBy(Expression.property("country"))
        .orderBy(Ordering.property("name").descending()) // <.>

    log(query.explain()) // <.>
    // end::query-explain-all[]
}

fun explainLikeExample(collection: Collection) {
    // tag::query-explain-like[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").like(Expression.string("%hotel%"))) // <.>
        .groupBy(Expression.property("country"))
        .orderBy(Ordering.property("name").descending()) // <.>
    log(query.explain())
    // end::query-explain-like[]
}

fun explainNoPFXExample(collection: Collection) {
    // tag::query-explain-nopfx[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            Expression.property("type").like(Expression.string("hotel%")) // <.>
                .and(Expression.property("name").like(Expression.string("%royal%")))
        )
    log(query.explain())
    // end::query-explain-nopfx[]
}

fun explainFnExample(collection: Collection) {
    // tag::query-explain-function[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Function.lower(Expression.property("type").equalTo(Expression.string("hotel")))) // <.>
    log(query.explain())
    // end::query-explain-function[]

}

fun explainNoFnExample(collection: Collection) {
    // tag::query-explain-nofunction[]
    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property("type").equalTo(Expression.string("hotel"))) // <.>
    log(query.explain())
    // end::query-explain-nofunction[]
}
// end::query-explain[]

fun prepareIndex(collection: Collection) {
    // tag::fts-index[]
    collection.createIndex("overviewFTSIndex", FullTextIndexConfigurationFactory.newConfig("overview"))
    // end::fts-index[]
}

fun prepareIndexBuilderExample(collection: Collection) {
    // tag::fts-index_Querybuilder[]
    collection.createIndex(
        "overviewFTSIndex",
        IndexBuilder.fullTextIndex(FullTextIndexItem.property("overview")).ignoreAccents(false)
    )
    // end::fts-index_Querybuilder[]
}

fun indexingQueryBuilderExample(collection: Collection) {
    // tag::query-index_Querybuilder[]
    collection.createIndex(
        "TypeNameIndex",
        IndexBuilder.valueIndex(
            ValueIndexItem.property("type"),
            ValueIndexItem.property("name")
        )
    )
    // end::query-index_Querybuilder[]
}

fun ftsExample(database: Database) {
    // tag::fts-query[]
    val ftsQuery = database.createQuery(
        "SELECT _id, overview FROM _ WHERE MATCH(overviewFTSIndex, 'michigan') ORDER BY RANK(overviewFTSIndex)"
    )
    ftsQuery.execute().use { rs ->
        rs.allResults().forEach {
            log("${it.getString("id")}: ${it.getString("overview")}")
        }
    }
    // end::fts-query[]
}

fun ftsQueryBuilderExample(collection: Collection) {
    // tag::fts-query_Querybuilder[]
    val ftsQuery =
        QueryBuilder.select(
            SelectResult.expression(Meta.id),
            SelectResult.property("overview")
        )
            .from(DataSource.collection(collection))
            .where(FullTextFunction.match(Expression.fullTextIndex("overviewFTSIndex"), "michigan"))

    ftsQuery.execute().use { rs ->
        rs.allResults().forEach {
            log("${it.getString("Meta.id")}: ${it.getString("overview")}")
        }
    }
    // end::fts-query_Querybuilder[]
}

fun querySyntaxJsonExample(collection: Collection) {
    // tag::query-syntax-json[]
    // Example assumes Hotel class object defined elsewhere
    // Build the query
    val listQuery = QueryBuilder.select(SelectResult.all())
        .from(DataSource.collection(collection))
    // end::query-syntax-json[]
    // tag::query-access-json[]
    // Uses Jackson JSON processor
    val mapper = ObjectMapper()
    val hotels = mutableListOf<Hotel>()

    listQuery.execute().use { rs ->
        rs.forEach {

            // Get result as JSON string
            val json = it.toJSON() // <.>

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
    }
    // end::query-access-json[]
}

fun docsOnlyQuerySyntaxN1QL(thisDb: Database): List<Result> {
    // For Documentation -- N1QL Query using parameters
    // tag::query-syntax-n1ql[]
    val thisQuery = thisDb.createQuery(
        "SELECT META().id AS id FROM _ WHERE type = \"hotel\""
    ) // <.>

    return thisQuery.execute().use { rs -> rs.allResults() }
    // end::query-syntax-n1ql[]
}

fun docsOnlyQuerySyntaxN1QLParams(database: Database): List<Result> {
    // For Documentation -- N1QL Query using parameters
    // tag::query-syntax-n1ql-params[]
    val thisQuery = database.createQuery(
        "SELECT META().id AS id FROM _ WHERE type = \$type"
    ) // <.>

    thisQuery.parameters = Parameters().setString("type", "hotel") // <.>

    return thisQuery.execute().allResults()

    // end::query-syntax-n1ql-params[]
}

