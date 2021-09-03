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
import com.couchbase.lite.Blob
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.Dictionary
import com.couchbase.lite.Expression
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.PredictionFunction
import com.couchbase.lite.PredictiveIndex
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndex
import com.couchbase.lite.ValueIndexItem


private const val TAG = "PREDICT"

// `tensorFlowModel` is a fake implementation
object TensorFlowModel {
    fun predictImage(data: ByteArray?) = mapOf<String, Any?>()
}

object ImageClassifierModel : PredictiveModel {
    const val name = "ImageClassifier"

    override fun predict(input: Dictionary): Dictionary? {
        val blob: Blob = input.getBlob("photo") ?: return null

        // this would be the implementation of the ml model you have chosen
        return MutableDictionary(TensorFlowModel.predictImage(blob.content)) // <1>
    }
} // end::predictive-model[]


@Suppress("unused")
class PredictiveQueryExamples {
    @Throws(CouchbaseLiteException::class)
    fun testPredictiveModel() {
        val database = Database("mydb")

        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", ImageClassifierModel)
        // end::register-model[]

        // tag::predictive-query-value-index[]
        val index: ValueIndex = IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")))
        database.createIndex("value-index-image-classifier", index)
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier")
        // end::unregister-model[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testPredictiveIndex() {
        val database = Database("mydb")

        // tag::predictive-query-predictive-index[]
        val inputMap: MutableMap<String, Any> = mutableMapOf()
        inputMap["numbers"] = Expression.property("photo")
        val input: Expression = Expression.map(inputMap)
        val index: PredictiveIndex = IndexBuilder.predictiveIndex("ImageClassifier", input, null)
        database.createIndex("predictive-index-image-classifier", index)
        // end::predictive-query-predictive-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun testPredictiveQuery() {
        val database = Database("mydb")

        // tag::predictive-query[]
        val prediction: PredictionFunction = Function.prediction(
            ImageClassifierModel.name,
            Expression.map(mutableMapOf("photo" to Expression.property("photo")) as Map<String, Any>?) // <1>
        )

        // !!! Is this query using that prediction function, at all?
        val rs = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.property("label").equalTo(Expression.string("car"))
                    .and(
                        Expression.property("probability")
                            .greaterThanOrEqualTo(Expression.doubleValue(0.8))
                    )
            )
            .execute()

        Log.d(TAG, "Number of rows: ${rs.allResults().size}")
        // end::predictive-query[]
    }
}