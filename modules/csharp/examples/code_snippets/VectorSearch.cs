//
// VectorSearch.cs
//
// Copyright (c) 2024 Couchbase, Inc All rights reserved.
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

using Couchbase.Lite;
using Couchbase.Lite.Enterprise.Query;
using Couchbase.Lite.Extensions;
using Couchbase.Lite.Query;

namespace api_walkthrough
{
    class Color
    {
        public static float[] GetVector(string color)
        {
            return new float[] { 0.0f, 0.0f, 0.0f };
        }

        public string Name { get; set; }
    }

    public sealed class ColorModel : IPredictiveModel
    {
        public DictionaryObject Predict(DictionaryObject input)
        {
            // Get the input color code 
            var inputColor = input.GetString("colorInput");
            if (inputColor == null)
            {
                return null;
            }

            // Get a vector, an array of float numbers, for the input color code.
            // Normally, you will get the vector from your ML model.
            float[] vector;
            try
            {
                vector = Color.GetVector(inputColor);
            }
            catch (Exception)
            {
                return null;
            }

            // Create an output dictionary by setting the vector result to
            // the dictionary key named "vector".
            var retVal = new MutableDictionaryObject();
            retVal.SetValue("vector", vector);
            return retVal;
        }

        public static void Register()
        {
            Database.Prediction.RegisterModel("ColorModel", new ColorModel());
        }

        public static void Unregister()
        {
            Database.Prediction.UnregisterModel("ColorModel");
        }
    }

    public class VectorSearch
    {
        private readonly Database _database = null;
        private readonly Collection _collection = null;

        public VectorSearch() {
            _database = new Database("my-database");
            _collection = _database.CreateCollection("colors");
        }

        private static void EnableVectorSearchExtension()
        {
            Extension.Load(new VectorSearchExtension());
        }

        private void CreateVectorIndex()
        {
            // Create and customize a vector index configuration
            var config = new VectorIndexConfiguration("vector", 3, 2)
            {
                DistanceMetric = DistanceMetric.Euclidean,
                Encoding = VectorEncoding.None(),
                MinTrainingSize = 50,
                MaxTrainingSize = 200
            };

            // Create a vector index from the configuration
            _collection.CreateIndex("colors_index", config);
        }

        private void CreateVectorIndexWithEmbedding()
        {
            // Create a vector index configuration from a document property named "vector" which
            // contains the vector embedding.
            var config = new VectorIndexConfiguration("vector", 3, 2);
            _collection.CreateIndex("colors_index", config);
        }

        private IResultSet QueryUsingVectorMatch(string color)
        {
            // Create a query to search similar colors by using the vector_match()
            // function to search color vectors in the vector index named "colors_index".
            var sql = "SELECT id, color " +
                      "FROM _default.colors " +
                      "WHERE vector_match(colors_index, $vector, 8)";
            var query = _database.CreateQuery(sql);

            // Get a vector, an array of float numbers, for the input color code.
            // Normally, you will get the vector from your ML model.
            var vector = Color.GetVector(color);

            // Set the vector array to the parameter "$vector"
            var queryParams = new Parameters();
            queryParams.SetValue("vector", vector);
            query.Parameters = queryParams;

            // Execute the query
            return query.Execute();
        }

        private IResultSet QueryVectorDistance(string color)
        {
            // Create a query to get vector distances by using the vector_distance() function.
            var sql = "SELECT id, color, vector_distance(colors_index) " +
                      "FROM _default.colors " +
                      "WHERE vector_match(colors_index, $vector, 8)";
            var query = _database.CreateQuery(sql);

            // Get a vector, an array of float numbers, for the input color code.
            // Normally, you will get the vector from your ML model.
            var vector = Color.GetVector(color);

            // Set the vector array to the parameter "$vector"
            var queryParams = new Parameters();
            queryParams.SetValue("vector", vector);
            query.Parameters = queryParams;

            // Execute the query
            return query.Execute();
        }

        private void CreateVectorIndexFromPredictiveIndex()
        {
            // Register the predictive model named "ColorModel".
            Database.Prediction.RegisterModel("ColorModel", new ColorModel());

            // Create a vector index configuration with an expression using the prediction
            // function to get the vectors from the registered predictive model.
            var expression = "predict(ColorModel, {\"colorInput\": color})";
            var config = new VectorIndexConfiguration(expression, 3, 2);

            // Create a vector index from the configuration
            _collection.CreateIndex("colors_index", config);
        }
    }
}

