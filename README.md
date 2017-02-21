SAT Solvers For OCaml
==================

Copyright (c) 2008-2017

This library contains an abstraction layer for integrating SAT Solvers into OCaml.

It is developed and maintained by:
- (c) Oliver Friedmann, University of Munich (http://oliverfriedmann.de)
- (c) Martin Lange, University of Kassel (http://carrick.fmv.informatik.uni-kassel.de/~mlange/)

We currently support the following SAT Solvers:
- zChaff (c) Princeton University (http://www.princeton.edu/~chaff/zchaff.html)
- MiniSAT (c) Niklas Eén, Niklas Sörensson (http://minisat.se)
- PicoSAT (c) JKU Linz (http://fmv.jku.at/picosat/)


## Installation

Install OCaml, OUnit, OPAM, Ocamlbuild.

Then:
```bash	
git clone https://github.com/tcsprojects/satsolversforocaml.git
cd satsolversforocaml
make
```


## Usage

- See the two test application for example use cases


### Sat Solvers

#### Picosat

```bash	
wget http://fmv.jku.at/picosat/picosat-965.tar.gz
tar xzvf picosat-965.tar.gz
cd picosat-965
./configure.sh && make
cd ..
echo "PICOSAT = `pwd`/picosat-965/libpicosat.a" >> satsolversforocaml/SatConfig
```
#### ZChaff

```bash	
wget https://www.princeton.edu/~chaff/zchaff/zchaff.64bit.2007.3.12.zip
tar xzvf zchaff.64bit.2007.3.12.zip 
cd zchaff64
make
cd ..
echo "ZCHAFF = `pwd`/zchaff64/libsat.a" >> satsolversforocaml/SatConfig
```

#### MiniSat

```bash
git clone https://github.com/niklasso/minisat
cd minisat
make
cd ..
echo "MINISAT = `pwd`/minisat/build/release/lib/libminisat.a" >> satsolversforocaml/SatConfig
echo "MINISAT_INC = `pwd`/minisat" >> satsolversforocaml/SatConfig
```

If you're on a Mac and make fails, please have a look at these resources:
- https://github.com/u-u-h/minisat/commit/e768238f8ecbbeb88342ec0332682ca8413a88f9
- http://web.cecs.pdx.edu/~hook/logicw11/Assignments/MinisatOnMac.html
