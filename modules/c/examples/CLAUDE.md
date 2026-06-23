# CLAUDE.md

## Purpose

This is the **compilable source** for the C/C++ code snippets shown on the
Couchbase Lite **C SDK** documentation site. The docs don't hand-write code
inline; instead they pull regions out of these real, buildable files so the
published examples are guaranteed to compile against the actual CBL API.

## How it works

- Snippets live in `code_snippets/` — primarily `main.cpp` (CRUD, query, sync,
  replication, peer-to-peer) and `VectorSearch.h` (vector search).
- Each example is delimited by AsciiDoc tagged-region markers:
  ```c
  // tag::getting-started[]
  ... example code ...
  // end::getting-started[]
  ```
  The docs reference these tags by name to include just that region. A function
  may carry multiple tags if it's reused across pages.
- `// Page=...` and `// url=...` comments map a function to the doc page where
  its snippet appears.

## Building

CMake project (`code_snippets/CMakeLists.txt`), C++17, links against the
`libcblite-<version>` SDK vendored in `code_snippets/libcblite-<version>/`.
The build exists only to verify the snippets compile — there's no real app.

```sh
cd code_snippets && cmake -B build && cmake --build build
```

## Editing guidance

- Keep `tag::`/`end::` markers intact and balanced — removing or renaming one
  breaks the doc include that references it.
- Snippets favor clarity over robustness: error handling is intentionally
  truncated or omitted after the first example. Match the surrounding style.
