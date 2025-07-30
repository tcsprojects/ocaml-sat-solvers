(lang dune 3.10)
(name ocaml-sat-solvers)
(version 0.8)

(generate_opam_files true)

(source (github tcsprojects/ocaml-sat-solvers))

(package
 (name ocaml-sat-solvers)
 (synopsis "An abstraction layer for integrating SAT Solvers into OCaml")
 (description "An abstraction layer for integrating SAT Solvers into OCaml.")
 (depends
   (ocaml (>= 4.8))
   dune
   (minisat (>= 0.4))
   (z3 (>= 4.13.2))
 )
 (license "BSD-3-clause")
 (authors "Oliver Friedmann" "Martin Lange") 
 (maintainers "Oliver Friedmann" "Martin Lange")
 (homepage "https://github.com/tcsprojects/ocaml-sat-solvers")
 (bug_reports "https://github.com/tcsprojects/ocaml-sat-solvers/issues")
)


