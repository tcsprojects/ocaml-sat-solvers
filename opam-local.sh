#!/usr/bin/env bash
opam uninstall SATSolversForOcaml
opam pin remove SATSolversForOcaml
oasis setup
ocaml setup.ml -configure
ocaml setup.ml -build
oasis2opam --local -y
opam pin add SATSolversForOcaml . -n -y
opam install SATSolversForOcaml
