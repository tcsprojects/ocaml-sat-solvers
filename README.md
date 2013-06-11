SAT Solvers For OCaml
==================

This library contains an abstraction layer for integrating SAT Solvers into OCaml.

It is developed and maintained by:
- (c) Oliver Friedmann, University of Munich (http://oliverfriedmann.de)
- (c) Martin Lange, University of Kassel (http://carrick.fmv.informatik.uni-kassel.de/~mlange/)

We currently support the following SAT Solvers:
- zChaff (c) Princeton University (http://www.princeton.edu/~chaff/zchaff.html)
- MiniSAT (c) Niklas Eén, Niklas Sörensson (http://minisat.se)
- PicoSAT (c) JKU Linz (http://fmv.jku.at/picosat/)


## Installation

- Install OCaml, Make and the SAT solvers that you'd like to use.
- Create a copy of Config.default, name it Config and modify it to fit your configuration
- Create a copy of Solvers.default, name it Solvers and modify it to fit your configuration
- Run make

## Usage

- See the two test application for example use cases
