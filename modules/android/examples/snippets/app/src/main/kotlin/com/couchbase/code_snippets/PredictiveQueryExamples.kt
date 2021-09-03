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
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.DatabaseConfiguration
import com.couchbase.lite.Expression
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.PredictionFunction
import com.couchbase.lite.PredictiveIndex
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.Query
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.ResultSet
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndex
import com.couchbase.lite.ValueIndexItem



class PredictiveQueryExamples {
    @Throws(CouchbaseLiteException::class)
    fun testPredictiveModel() {
        val config = DatabaseConfiguration()
        val database = Database("mydb", config)

        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", Examples.ImageClassifierModel())
        // end::register-model[]

        // tag::predictive-query-value-index[]
        val index: ValueIndex =
            IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")))
        database.createIndex("value-index-image-classifier", index)
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier")
        // end::unregister-model[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testPredictiveIndex() {
        val config = DatabaseConfiguration()
        val database = Database("mydb", config)

        // tag::predictive-query-predictive-index[]
        val inputMap: MutableMap<String, Any> =
            HashMap()
        inputMap["numbers"] = Expression.property("photo")
        val input: Expression = Expression.map(inputMap)
        val index: PredictiveIndex = IndexBuilder.predictiveIndex("ImageClassifier", input, null)
        database.createIndex("predictive-index-image-classifier", index)
        // end::predictive-query-predictive-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testPredictiveQuery() {
        val config = DatabaseConfiguration()
        val database = Database("mydb", config)

        // tag::predictive-query[]
        val inputProperties: MutableMap<String, Any> =
            HashMap()
        inputProperties["photo"] = Expression.property("photo")
        val input: Expression = Expression.map(inputProperties)
        val prediction: PredictionFunction = PredictiveModel.predict(input) // <1>
        val query: Query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.property("label").equalTo(Expression.string("car"))
                    .and(
                        Expression.property("probability")
                            .greaterThanOrEqualTo(Expression.doubleValue(0.8))
                    )
            )

        // Run the query.
        val result: ResultSet = query.execute()
        Log.d(TAG, "Number of rows: " + result.allResults().size())
        // end::predictive-query[]
    }
}