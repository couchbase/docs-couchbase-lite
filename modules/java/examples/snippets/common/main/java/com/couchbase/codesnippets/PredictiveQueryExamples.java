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

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.PredictionFunction;
import com.couchbase.lite.PredictiveIndex;
import com.couchbase.lite.PredictiveModel;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.ValueIndexItem;


@SuppressWarnings({"unused", "ConstantConditions"})
public class PredictiveQueryExamples {

    // tag::predictive-model[]
    // tensorFlowModel is a fake implementation
    // this would be the implementation of the ml model you have chosen
    public static class TensorFlowModel {
        public static Map<String, Object> predictImage(byte[] data) {
            return null;
        }
    }

    public class ImageClassifierModel implements PredictiveModel {
        @Override
        public Dictionary predict(@NonNull Dictionary input) {
            Blob blob = input.getBlob("photo");

            // tensorFlowModel is a fake implementationq
            // this would be the implementation of the ml model you have chosen
            return (blob == null)
                ? null
                : new MutableDictionary(TensorFlowModel.predictImage(blob.getContent())); // <1>
        }
    }
    // end::predictive-model[]


    public void predictiveModelExamples(Collection collection) throws CouchbaseLiteException {
        // tag::register-model[]
        Database.prediction.registerModel("ImageClassifier", new ImageClassifierModel());
        // end::register-model[]

        // tag::predictive-query-value-index[]
        collection.createIndex(
            "value-index-image-classifier",
            IndexBuilder.valueIndex(ValueIndexItem.expression(Expression.property("label"))));
        // end::predictive-query-value-index[]

        // tag::unregister-model[]
        Database.prediction.unregisterModel("ImageClassifier");
        // end::unregister-model[]
    }

    public void predictiveIndexExamples(Collection collection) throws CouchbaseLiteException {
        // tag::predictive-query-predictive-index[]
        Map<String, Object> inputMap = new HashMap<>();
        inputMap.put("numbers", Expression.property("photo"));
        Expression input = Expression.map(inputMap);

        PredictiveIndex index = IndexBuilder.predictiveIndex("ImageClassifier", input, null);
        collection.createIndex("predictive-index-image-classifier", index);
        // end::predictive-query-predictive-index[]
    }

    public void predictiveQueryExamples(Collection collection) throws CouchbaseLiteException {
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
            Logger.log("Number of rows: " + result.allResults().size());
        }
        // end::predictive-query[]
    }

    private Collection getCollection() { return null; }
}
