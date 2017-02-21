all: generatesat tester1 tester2

include ./SatCompile

tester1:
	ocamlbuild $(SATFLAGS) tester1.native
	mv tester1.native bin/tester1

tester2:
	ocamlbuild $(SATFLAGS) tester2.native
	mv tester2.native bin/tester2

clean:
	ocamlbuild -clean
