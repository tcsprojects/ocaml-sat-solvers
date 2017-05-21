#!/usr/bin/env bash
opam uninstall ocaml-sat-solvers
opam pin remove ocaml-sat-solvers
oasis setup
ocaml setup.ml -configure
ocaml setup.ml -build
oasis2opam --local -y
opam pin add ocaml-sat-solvers . -n -y
opam install ocaml-sat-solvers
