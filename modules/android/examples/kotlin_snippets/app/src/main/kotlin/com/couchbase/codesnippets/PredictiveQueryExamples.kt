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
@file:Suppress("UNUSED_VARIABLE", "unused")

package com.couchbase.codesnippets

import com.couchbase.codesnippets.util.Logger.Companion.log
import com.couchbase.lite.Collection
import com.couchbase.lite.DataSource
import com.couchbase.lite.Database
import com.couchbase.lite.Dictionary
import com.couchbase.lite.Expression
import com.couchbase.lite.Function
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.PredictionFunction
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.QueryBuilder
import com.couchbase.lite.SelectResult
import com.couchbase.lite.ValueIndexItem


private const val TAG = "PREDICT"

// tag::predictive-model[]
// tensorFlowModel is a fake implementation
object TensorFlowModel {
    fun predictImage(data: ByteArray?): Map<String, Any?> = TODO()
}

object ImageClassifierModel : PredictiveModel {
    const val name = "ImageClassifier"

    // this would be the implementation of the ml model you have chosen
    override fun predict(input: Dictionary) = input.getBlob("photo")?.let {
        MutableDictionary(TensorFlowModel.predictImage(it.content)) // <1>
    }
}
// end::predictive-model[]


fun predictiveModelExamples(collection: Collection) {

    // tag::register-model[]
    Database.prediction.registerModel("ImageClassifier", ImageClassifierModel)
    // end::register-model[]

    // tag::predictive-query-value-index[]
    collection.createIndex(
        "value-index-image-classifier",
        IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label")))
    )
    // end::predictive-query-value-index[]

    // tag::unregister-model[]
    Database.prediction.unregisterModel("ImageClassifier")
    // end::unregister-model[]
}


fun predictiveIndexExamples(collection: Collection) {

    // tag::predictive-query-predictive-index[]
    val inputMap: Map<String, Any?> = mutableMapOf("numbers" to Expression.property("photo"))
    collection.createIndex(
        "predictive-index-image-classifier",
        IndexBuilder.predictiveIndex("ImageClassifier", Expression.map(inputMap), null)
    )
    // end::predictive-query-predictive-index[]
}


fun predictiveQueryExamples(collection: Collection) {

    // tag::predictive-query[]
    val inputMap: Map<String, Any?> = mutableMapOf("photo" to Expression.property("photo"))
    val prediction: PredictionFunction = Function.prediction(
        ImageClassifierModel.name,
        Expression.map(inputMap) // <1>
    )

    val query = QueryBuilder
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            prediction.propertyPath("label").equalTo(Expression.string("car"))
                .and(
                    prediction.propertyPath("probability")
                        .greaterThanOrEqualTo(Expression.doubleValue(0.8))
                )
        )

    query.execute().use {
        log("Number of rows: ${it.allResults().size}")
    }
    // end::predictive-query[]
}
