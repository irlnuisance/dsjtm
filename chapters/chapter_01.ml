(* Chapter 1: How OCaml Sees the World
   ====================================

   Every value in OCaml lives in a single machine word — 64 bits.
   That's it. One word per value.

   But a word can only hold so much. How does OCaml fit integers,
   strings, tuples, functions, and everything else into the same
   64-bit box?

   With a trick.

   ┌─────────────────────────────────────────────────────────────────┐
   │ OxCaml note: This chapter describes standard OCaml. OxCaml     │
   │ (Jane Street's fork) extends this model with unboxed types,    │
   │ stack allocation, and a layout system. We'll note differences  │
   │ as we go — they're worth knowing if you need more control.     │
   │ https://oxcaml.org/documentation/                              │
   └─────────────────────────────────────────────────────────────────┘
*)

(* ---------------------------------------------------------------------
   The One-Bit Trick
   ---------------------------------------------------------------------

   Picture a 64-bit word:

   ┌────────────────────────────────────────────────────────────────┐
   │  63 bits of data                                            │ 1 │
   └────────────────────────────────────────────────────────────────┘
                                                                   ↑
                                                              tag bit

   The lowest bit decides everything:

     bit = 1  →  this word IS the value (an integer)
     bit = 0  →  this word POINTS to the value (on the heap)

   Heap memory is always aligned to word boundaries, so real pointers
   naturally end in 0. Integers get a 1 stamped on the end.

   The price: integers are 63 bits, not 64.
*)

let () = print_endline "=== The One-Bit Trick ===\n"

(* The Obj module lets us peek at runtime representation.
   It's unsafe — treat it like a microscope, not a tool. *)

let () =
  let x = 42 in
  let repr = Obj.repr x in
  Printf.printf "  42 is immediate (lives in the word): %b\n\n"
    (Obj.is_int repr)

(* ---------------------------------------------------------------------
   Immediate vs Boxed
   ---------------------------------------------------------------------

   Immediate — the value IS the word:

     ┌─────────────────────────────────┐
     │          42 (shifted)         │1│   ← integer, right here
     └─────────────────────────────────┘

   Boxed — the word POINTS to a heap block:

     ┌─────────────────────────────────┐
     │        pointer to heap        │0│   ← follow me...
     └─────────────────────────────────┘
                      │
                      ▼
              ┌───────────────────┐
              │ header │ data... │       ← ...to here
              └───────────────────┘

   What's immediate:
   - int, char, bool, unit
   - Constant constructors (None, [], etc.)

   What's boxed:
   - float, string, bytes
   - Tuples, records, arrays
   - Variants carrying data
   - Functions

   ┌─────────────────────────────────────────────────────────────────┐
   │ OxCaml: Unboxed numeric types (float#, int64#, int32#, etc.)   │
   │ skip the pointer entirely. A float# lives in a register, not   │
   │ a heap block. The # suffix means "unboxed."                    │
   │                                                                 │
   │   let f (x : float#) (y : float#) = Float_u.add x y            │
   │                                                                 │
   │ No allocation. Useful in hot loops and low-latency code.       │
   └─────────────────────────────────────────────────────────────────┘
*)

let () = print_endline "=== Immediate vs Boxed ===\n"

let show name value =
  let repr = Obj.repr value in
  let kind = if Obj.is_int repr then "immediate" else "boxed" in
  Printf.printf "  %-16s  %s\n" name kind

let () =
  show "42" 42;
  show "'a'" 'a';
  show "true" true;
  show "()" ();
  show "None" None;
  print_endline "";
  show "3.14" 3.14;
  show "\"hello\"" "hello";
  show "(1, 2)" (1, 2);
  show "Some 1" (Some 1);
  show "[1; 2]" [1; 2];
  print_endline ""

(* ---------------------------------------------------------------------
   Blocks
   ---------------------------------------------------------------------

   Every boxed value points to a block. Blocks look like this:

   ┌──────────────────┬─────────┬─────────┬─────────┬─────────┐
   │      header      │ field 0 │ field 1 │ field 2 │   ...   │
   └──────────────────┴─────────┴─────────┴─────────┴─────────┘
          1 word         1 word    1 word    1 word

   The header packs two things:
   - Size: how many fields follow
   - Tag: what kind of data (0–255)

   Some tags to know:
   - 0–245: regular data (tuples, records, variant cases)
   - 252: strings and bytes
   - 253: floats
   - 254: float arrays (special case — more on this in Chapter 4)

   ┌─────────────────────────────────────────────────────────────────┐
   │ OxCaml: Stack allocation lets you put blocks on the stack      │
   │ instead of the heap. No GC pressure, freed when function       │
   │ returns. The compiler tracks lifetimes to keep it safe.        │
   │                                                                 │
   │   let local_ point = (x, y) in ...                             │
   │                                                                 │
   │ That tuple lives on the stack, not the heap.                   │
   └─────────────────────────────────────────────────────────────────┘
*)

let () = print_endline "=== Inside Blocks ===\n"

let inspect name value =
  let repr = Obj.repr value in
  if Obj.is_block repr then
    Printf.printf "  %-16s  tag=%d  size=%d words\n"
      name (Obj.tag repr) (Obj.size repr)
  else
    Printf.printf "  %-16s  (immediate)\n" name

let () =
  inspect "(1, 2, 3)" (1, 2, 3);
  inspect "Some 42" (Some 42);
  inspect "[1]" [1];
  inspect "\"hello\"" "hello";
  inspect "[|1;2;3|]" [|1;2;3|];
  inspect "[|1.;2.;3.|]" [|1.;2.;3.|];
  print_endline ""

(* ---------------------------------------------------------------------
   Variants
   ---------------------------------------------------------------------

   type shape = Circle | Square | Triangle of int

   Constant constructors (no data) are immediate:

     Circle  →  0 (immediate)
     Square  →  1 (immediate)

   Constructors with data are blocks:

     Triangle 10  →  ┌────────┬────┐
                     │ header │ 10 │
                     └────────┴────┘
                      tag = 0

   Constants and non-constants are numbered separately.
*)

let () = print_endline "=== Variants ===\n"

type shape = Circle | Square | Triangle of int | Rectangle of int * int

let () =
  Printf.printf "  Circle           immediate, value = %d\n"
    (Obj.magic (Obj.repr Circle) : int);
  Printf.printf "  Square           immediate, value = %d\n"
    (Obj.magic (Obj.repr Square) : int);
  inspect "Triangle 10" (Triangle 10);
  inspect "Rectangle(3,4)" (Rectangle (3, 4));
  print_endline ""

(* ---------------------------------------------------------------------
   What This Means
   ---------------------------------------------------------------------

   - Passing an int? Free. It's already in the register.
   - Passing a float? Allocation. It's boxed.
   - A 3-tuple? 4 words on the heap (1 header + 3 fields).
   - Pattern match? Check a tag or compare an immediate. Fast.
   - Polymorphic (=)? Must traverse the structure. Slower.

   Every data structure we build sits on this foundation.
*)

let () = print_endline {|=== Summary ===

  ┌─────────────────────────────────────────────────────────┐
  │  Every value is one 64-bit word                         │
  │  Lowest bit: 1 = integer, 0 = pointer                   │
  │  Boxed values point to blocks (header + fields)         │
  │  Tags tell the runtime what's in the block              │
  └─────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────┐
  │ OxCaml extends this with "layouts" — a kind system for  │
  │ memory representation. Every type has a layout:         │
  │                                                         │
  │   value     — the standard OCaml representation         │
  │   immediate — values that need no pointer               │
  │   float64   — an unboxed 64-bit float                   │
  │   bits32    — an unboxed 32-bit integer                 │
  │   bits64    — an unboxed 64-bit integer                 │
  │                                                         │
  │ The type checker tracks layouts, preventing unboxed     │
  │ values from ending up where boxed ones are expected.    │
  └─────────────────────────────────────────────────────────┘
|}

(* ---------------------------------------------------------------------
   Exercises

   1. Is `None` immediate or boxed?

   2. A record { x: int; y: int; z: int } — how many words on the heap?

   3. The list [1; 2; 3] — how many blocks? What's in each?

   4. Why might float arrays get special treatment? (Chapter 4 spoiler)
*)

(* ---------------------------------------------------------------------
   References

   OCaml memory representation:
   - https://ocaml.org/docs/memory-representation
   - https://dev.realworldocaml.org/runtime-memory-layout.html

   OxCaml extensions:
   - https://oxcaml.org/documentation/
   - https://oxcaml.org/documentation/unboxed-types/01-intro/
   - https://oxcaml.org/documentation/stack-allocation/intro/

   Papers:
   - "Oxidizing OCaml with Modal Memory Management" (ICFP 2024)
     https://icfp24.sigplan.org/details/icfp-2024-papers/19/Oxidizing-OCaml-with-Modal-Memory-Management
   - "Unboxed types for OCaml" (ML Workshop 2022)
     https://icfp22.sigplan.org/details/mlfamilyworkshop-2022-papers/13/Unboxed-types-for-OCaml
*)

let () = print_endline "---\nRun: dune exec ./chapter_01.exe"
