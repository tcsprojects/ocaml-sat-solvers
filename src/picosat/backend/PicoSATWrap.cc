#include <caml/mlvalues.h>
#include <caml/memory.h>
#include "picosat.h"


extern "C" value pico_init(value unit) {
  picosat_init ();

  return Val_unit;
}

extern "C" value pico_reset(value unit) {
  picosat_reset ();

  return Val_unit;
}

extern "C" value pico_add(value lit) {
  picosat_add (Int_val (lit));

  return Val_unit;
}

extern "C" value pico_assume(value lit) {
  picosat_assume(Int_val (lit));

  return Val_unit;
}

extern "C" value pico_sat(value decision_limit) {
  int r = picosat_sat (Int_val (decision_limit));
  int l = 0;
  if (r == PICOSAT_SATISFIABLE) {
	l = 1;
  }
  else if (r == PICOSAT_UNSATISFIABLE) {
	l = 2;
  }
  return Val_int (l);
}

extern "C" value pico_deref(value lit) {
  int r = picosat_deref (Int_val (lit));

  return Val_int (r);
}
