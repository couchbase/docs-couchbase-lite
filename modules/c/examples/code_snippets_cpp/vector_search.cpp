// Compilable source for the C++ vector-search code snippets shown on the
// Couchbase Lite C SDK documentation site. This is the C++ (cbl++) counterpart
// of code_snippets/VectorSearch.h, kept as its own translation unit and linked
// into the code-snippets-cpp executable alongside cbl_cpp.cpp.
//
// As with cbl_cpp.cpp, examples are wrapped in AsciiDoc tagged regions, e.g.
//   // tag::vs-create-index[]
//   ... example code ...
//   // end::vs-create-index[]
// and the docs include regions by name from
// example$code_snippets_cpp/vector_search.cpp.
//
// This file has NO main() -- that lives in cbl_cpp.cpp; both compile into the
// same executable. Snippets are ported from VectorSearch.h incrementally; for
// now this is only the skeleton needed to wire up the build.

#include <cbl++/CouchbaseLite.hh>
