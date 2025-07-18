ocaml-sat-solvers
==================

Copyright (c) 2008-2025

This library contains an abstraction layer for integrating SAT Solvers into OCaml.

It is developed and maintained by:
- (c) Oliver Friedmann, University of Munich (http://oliverfriedmann.de)
- (c) Martin Lange, University of Kassel (http://carrick.fmv.informatik.uni-kassel.de/~mlange/)

We currently support the following SAT Solvers:
- MiniSAT v1.4 (c) Niklas Eén, Niklas Sörensson (http://minisat.se)
- Z3 v4.8.11 (c) Microsoft Corporation (https://github.com/Z3Prover/z3)


## OPAM

You can install this package via OPAM under the name `ocaml-sat-solvers`.


## Commands


### Build

```
dune build
```

### Release

1. Change version in `dune-project`.
2. Update `CHANGES.md`.
3. Run `dune build`.
4. Commit
```
  git status
  git add -A
  git commit -m "message"
  git tag v0.x [--force]
  git push origin master --tags [--force]
```
5. Release
```
  dune-release tag
  dune-release distrib
  dune-release publish
  dune-release opam pkg
  dune-release opam submit
```  