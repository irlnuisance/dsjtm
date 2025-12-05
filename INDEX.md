# Data Structures: A Journey Through Memory

> *"The purpose of abstraction is not to be vague, but to create a new semantic level in which one can be absolutely precise."* — Dijkstra

Data structures in OCaml, with a look at how bits arrange themselves in memory.

---

## Part I: Foundations

### [1. How OCaml Sees the World](chapters/chapter_01.ml)
- Words, tags, and the 1-bit trick
- Boxed vs immediate values
- Blocks: header + fields
- OxCaml: unboxed types, stack allocation, layouts

### [2. Choosing Your Weapon](chapters/chapter_02.ml)
- Access pattern, size, mutability
- Time vs space — the hidden constant factors
- A field guide: which structure for which job

### [3. The Humble Tuple (and Records)](chapters/chapter_03.ml)
- Product types and memory layout
- Why `(int * int)` and `{x: int; y: int}` look the same underneath
- Pattern matching — what happens at runtime

---

## Part II: Sequential Structures

### [4. Arrays: Memory in a Row](chapters/chapter_04.ml)
- Contiguous allocation, cache-friendly
- O(1) random access
- Bounds checking, GC interaction
- Float arrays: the special case

### [5. The List: Linked Cells](chapters/chapter_05.ml)
- Cons cells, head and tail
- O(n) length, no random access, pointer chasing
- Structural sharing — immutability's payoff
- When to reach for `Array` or `Seq` instead

### [6. Stacks & Queues](chapters/chapter_06.ml)
- LIFO / FIFO as access patterns
- The call stack
- Functional queues: two lists
- Ring buffers: fixed-size, mutable

---

## Part III: Trees

### [7. Binary Trees](chapters/chapter_07.ml)
- Nodes, leaves, recursion
- Variants as tree blueprints
- Traversal: pre / in / post-order
- How variants are tagged in memory

### [8. Binary Search Trees](chapters/chapter_08.ml)
- The ordering invariant
- Insert, lookup, delete
- Degenerate trees (the stick)

### [9. Balanced Trees: Map and Set](chapters/chapter_09.ml)
- Why balance matters
- What's inside OCaml's `Map`
- `Map` vs `Hashtbl` — when to use which

### [10. Heaps and Priority Queues](chapters/chapter_10.ml)
- Shape property: a tree stored in an array
- Bubble up, sink down
- Schedulers, event loops

---

## Part IV: Key-Value Structures

### [11. Hash Tables](chapters/chapter_11.ml)
- Hash functions: deterministic scatter
- Buckets, collisions, load factor
- OCaml's `Hashtbl`
- When hashing goes wrong

### [12. Tries](chapters/chapter_12.ml)
- Keys with structure (strings, paths)
- Prefix queries, autocomplete
- Sparse vs dense children

---

## Part V: Graphs

### [13. Representing Graphs](chapters/chapter_13.ml)
- Adjacency list vs matrix
- Directed, undirected, weighted
- Encoding graphs with modules

### [14. Traversal and Search](chapters/chapter_14.ml)
- BFS: level by level
- DFS: depth first
- Cycle detection, topological sort

---

## Part VI: The Runtime

### [15. Persistent Data Structures](chapters/chapter_15.ml)
- Structural sharing
- Path copying
- Immutability and the GC

### [16. The Garbage Collector](chapters/chapter_16.ml)
- Minor heap, major heap
- How structure shapes collection
- Allocation patterns that help

---

## Appendices

- **A.** Complexity at a Glance
- **B.** OCaml Runtime Representation — Quick Reference
- **C.** Peeking Under the Hood: `Obj.repr`
- **D.** Further Reading

---

*Each chapter: one `.ml` file, code that runs.*
