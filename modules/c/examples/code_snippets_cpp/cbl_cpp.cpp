// Compilable source for the C++ code snippets shown on the Couchbase Lite C SDK
// documentation site. This mirrors code_snippets/main.cpp but uses the C++ API
// (the header-only `cbl++` wrapper, namespace `cbl`) instead of the C API.
//
// The docs pull regions out of this file via AsciiDoc tagged-region markers, so
// the published C++ examples are guaranteed to compile against the real API:
//
//   // tag::getting-started[]
//   ... example code ...
//   // end::getting-started[]
//
// The docs reference these tags by name from example$code_snippets_cpp/cbl_cpp.cpp.
//
// Snippets are ported from the C examples incrementally; for now this file is
// only the skeleton needed to wire up the build. Add snippets as tagged regions
// following the same conventions as main.cpp.

#include <cbl++/CouchbaseLite.hh>

// The snippets in this file exist only to be compile-checked and pulled into the
// docs via tagged regions; the project is never run, so main() is empty.
int main(int argc, char** argv) {
    return 0;
}
