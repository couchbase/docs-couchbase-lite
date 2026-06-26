// Compilable source for the C++ vector-search code snippets shown on the
// Couchbase Lite C SDK documentation site. This is the C++ (cbl++) counterpart
// of code_snippets/VectorSearch.h, kept as its own translation unit and linked
// into the code-snippets-cpp executable alongside cbl_cpp.cpp.
//
// Examples are wrapped in AsciiDoc tagged regions and the docs reference them by
// name from example$code_snippets_cpp/vector_search.cpp. This file has no main()
// -- that lives in cbl_cpp.cpp; both compile into the same executable.

#include <cbl++/CouchbaseLite.hh>
#include <string>
#include <vector>
#include <stdexcept>

// Helper standing in for an ML model that turns a color string into a vector.
class Color {
public:
    static std::vector<float> getVector(const std::string& color) {
        return {};
    }
};

class TransientError : public std::exception {};

static void enable_vector_search_extension() {
    // tag::vs-setup-packaging[]
    // Enable the Vector Search extension. Throws cbl::Error if the extension
    // library is invalid or not found.
    cbl::Extension::enableVectorSearch("/path/to/extension_dir");
    // end::vs-setup-packaging[]
}

static void create_default_vector_index_config() {
    // tag::vs-create-default-config[]
    // Create a vector index configuration with a document property named "vector",
    // 3 dimensions, and 100 centroids.
    cbl::VectorIndexConfiguration config(kCBLN1QLLanguage, "vector", 3, 100);
    // end::vs-create-default-config[]
}

static void create_custom_vector_index_config() {
    // tag::vs-create-custom-config[]
    // Create a vector index configuration with a document property named "vector",
    // 3 dimensions, and 100 centroids. Customize the encoding, the distance metric,
    // the number of probes, and the training size.
    cbl::VectorIndexConfiguration config(kCBLN1QLLanguage, "vector", 3, 100);
    config.metric = kCBLDistanceMetricCosine;
    config.numProbes = 8;
    config.encoding = cbl::VectorEncoding::none();
    config.minTrainingSize = 2500;
    config.maxTrainingSize = 5000;
    // end::vs-create-custom-config[]
}

static void num_probes_config() {
    // tag::vs-numprobes-config[]
    // Create a vector index configuration with a document property named "vector",
    // 3 dimensions, and 100 centroids. Customize the number of probes.
    cbl::VectorIndexConfiguration config(kCBLN1QLLanguage, "vector", 3, 100);
    config.numProbes = 8;
    // end::vs-numprobes-config[]
}

static void create_vector_index() {
    cbl::Database database("my-database");
    // tag::vs-create-index[]
    // Get the collection object named "colors" in the default scope.
    cbl::Collection collection = database.getCollection("colors", "_default");

    // Create a vector index configuration with a document property named "vector",
    // 3 dimensions, and 100 centroids.
    cbl::VectorIndexConfiguration config(kCBLN1QLLanguage, "vector", 3, 100);

    // Create a vector index from the configuration with the name "colors_index".
    collection.createVectorIndex("colors_index", config);
    // end::vs-create-index[]
}

static void create_vector_index_with_predictive_model() {
    cbl::Database database("my-database");
    // tag::vs-predictive-model[]
    cbl::PredictiveModel model = [](fleece::Dict input) -> fleece::MutableDict {
        // Get the color input string
        std::string color = input["colorInput"].asstring();

        // Call the ML model to get an embedding:
        std::vector<float> colorVector = Color::getVector(color);

        // Construct a Fleece array for the color vector:
        fleece::MutableArray vectorArray = fleece::MutableArray::newArray();
        for (float val : colorVector) {
            vectorArray.append(val);
        }

        // Construct the Fleece dictionary output:
        fleece::MutableDict output = fleece::MutableDict::newDict();
        output["vector"] = vectorArray;
        return output;
    };
    // end::vs-predictive-model[]

    // tag::vs-create-predictive-index[]
    // Register the predictive model named "ColorModel".
    cbl::Prediction::registerModel("ColorModel", model);

    // Get the collection object named "colors" in the default scope.
    cbl::Collection collection = database.getCollection("colors", "_default");

    // Create a vector index configuration with an expression using the prediction
    // function to get the vectors from the registered predictive model.
    cbl::VectorIndexConfiguration config(kCBLN1QLLanguage,
        "prediction(ColorModel, {\"colorInput\": color}).vector", 3, 100);

    // Create a vector index from the configuration with the name "colors_index".
    collection.createVectorIndex("colors_index", config);
    // end::vs-create-predictive-index[]
}

static void query_apvd_prediction() {
    cbl::Database database("my-database");
    // tag::vs-apvd-prediction[]
    // Create a vector search query that uses prediction() for computing vectors.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT id, color "
        "FROM _default.colors "
        "ORDER BY approx_vector_distance(prediction(ColorModel, {\"colorInput\": color}).vector, $vector) "
        "LIMIT 8");

    // Use the ML model to get a vector (an array of floats) for the input color.
    std::vector<float> colorVector = Color::getVector("FF00AA");

    // Set the vector array to the parameter "$vector".
    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    // Execute the query:
    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-apvd-prediction[]
}

static void query_apvd_order_by() {
    cbl::Database database("my-database");
    // tag::vs-use-vector-match[]
    // tag::vs-apvd-order-by[]
    // Create a query using approx_vector_distance() in the ORDER BY clause.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT id, color "
        "FROM _default.colors "
        "ORDER BY approx_vector_distance(vector, $vector) "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-apvd-order-by[]
    // end::vs-use-vector-match[]
}

static void query_apvd_where() {
    cbl::Database database("my-database");
    // tag::vs-apvd-where[]
    // Create a query using approx_vector_distance() in the WHERE clause.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT id, color "
        "FROM _default.colors "
        "WHERE approx_vector_distance(vector, $vector) < 0.5 "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-apvd-where[]
}

static void query_vector_distance() {
    cbl::Database database("my-database");
    // tag::vs-use-vector-distance[]
    // Create a query using approx_vector_distance() to get vector distances.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT id, color, approx_vector_distance(vector, $vector) "
        "FROM _default.colors "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-use-vector-distance[]
}

static void query_hybrid_order_by() {
    cbl::Database database("my-database");
    // tag::vs-hybrid-order-by[]
    // Create a hybrid vector search query using ORDER BY and a WHERE clause.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT meta().id, color "
        "FROM _default.colors "
        "WHERE saturation > 0.5 "
        "ORDER BY approx_vector_distance(vector, $vector) "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-hybrid-order-by[]
}

static void query_hybrid_where() {
    cbl::Database database("my-database");
    // tag::vs-hybrid-where[]
    // Create a hybrid vector search query using a WHERE clause.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT meta().id, color "
        "FROM _default.colors "
        "WHERE saturation > 0.5 AND approx_vector_distance(vector, $vector) < 0.5 "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-hybrid-where[]
}

static void query_hybrid_prediction() {
    cbl::Database database("my-database");
    // tag::vs-hybrid-prediction[]
    // Create a hybrid vector search query using prediction() for computing vectors.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT meta().id, color "
        "FROM _default.colors "
        "WHERE saturation > 0.5 "
        "ORDER BY approx_vector_distance(prediction(ColorModel, {\"colorInput\": color}).vector, $vector) "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["vector"] = colorArray;
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-hybrid-prediction[]
}

static void query_hybrid_ft_match() {
    cbl::Database database("my-database");
    // tag::vs-hybrid-ftmatch[]
    // Create a hybrid vector search query combining a full-text MATCH() with
    // approx_vector_distance() in the ORDER BY clause.
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT meta().id, color "
        "FROM _default.colors "
        "WHERE MATCH(color_desc_index, $text) "
        "ORDER BY approx_vector_distance(vector, $vector) "
        "LIMIT 8");

    std::vector<float> colorVector = Color::getVector("FF00AA");

    fleece::MutableArray colorArray = fleece::MutableArray::newArray();
    for (float val : colorVector) {
        colorArray.append(val);
    }
    fleece::MutableDict params = fleece::MutableDict::newDict();
    // Set the vector array to the parameter "$vector".
    params["vector"] = colorArray;
    // Set the search text to the parameter "$text".
    params["text"] = "vibrant";
    query.setParameters(params);

    for (cbl::Result result : query.execute()) {
        // Process result
    }
    // end::vs-hybrid-ftmatch[]
}

static void create_lazy_index() {
    // tag::vs-lazy-index-config[]
    // Create a lazy vector index using the document's 'color' key. The value of
    // this key is used to compute a vector when updating the index.
    cbl::VectorIndexConfiguration config(kCBLN1QLLanguage, "color", 3, 100);
    config.isLazy = true;
    // end::vs-lazy-index-config[]
}

static void update_lazy_index() {
    cbl::Database database("my-database");
    // tag::vs-create-lazy-index-embedding[]
    // Get the collection and the index objects.
    cbl::Collection collection = database.getCollection("colors", "_default");
    cbl::QueryIndex index = collection.getIndex("colors_index");

    while (true) {
        // Start an update on the index (in this case, limit to 50 entries at a time).
        cbl::IndexUpdater updater = index.beginUpdate(50);
        // A falsy updater means there are no more entries to process.
        if (!updater) {
            break;
        }

        for (size_t i = 0; i < updater.count(); i++) {
            // The value type depends on the expression set in the index.
            // In this example, it is a string property.
            std::string colorString = updater.value(i).asstring();

            std::vector<float> vector;
            try {
                // Call an ML model to get a vector.
                vector = Color::getVector(colorString);
            } catch (const TransientError& e) {
                // The vector cannot be generated right now, so skip this entry;
                // it will be considered again the next time beginUpdate is called.
                updater.skipVector(i);
                continue;
            }

            if (!vector.empty()) {
                // The vector size must match the index's number of dimensions.
                updater.setVector(i, vector.data(), vector.size());
            } else {
                // No vector applicable: setting a null vector leaves the
                // underlying document out of the index.
                updater.setVector(i, nullptr, 0);
            }
        }

        // Write the vectors to the index. All entries must be set or skipped
        // before calling finish().
        updater.finish();
    }
    // end::vs-create-lazy-index-embedding[]
}
