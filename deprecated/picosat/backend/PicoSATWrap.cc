#include <caml/mlvalues.h>
#include <caml/memory.h>


#define PICOSAT_SATISFIABLE	10
#define PICOSAT_UNSATISFIABLE	20

extern "C" void* picosat_init (void);
extern "C" void picosat_reset (void* solver);
extern "C" void picosat_add (void* solver, int lit);
extern "C" void picosat_assume (void* solver, int lit);
extern "C" int picosat_sat (void* solver, int decision_limit);
extern "C" int picosat_deref (void* solver, int lit);


extern "C" value pico_init(value unit) {
  void* solver = picosat_init ();
  return (value) solver;
}

extern "C" value pico_reset(value solver) {
  picosat_reset ((void*) solver);
  return Val_unit;
}

extern "C" value pico_add(value solver, value lit) {
  picosat_add ((void*) solver, Int_val (lit));
  return Val_unit;
}

extern "C" value pico_assume(value solver, value lit) {
  picosat_assume((void*) solver, Int_val (lit));
  return Val_unit;
}

extern "C" value pico_sat(value solver, value decision_limit) {
  int r = picosat_sat ((void*) solver, Int_val (decision_limit));
  if (r == PICOSAT_SATISFIABLE)
	  return Val_int(1);
  if (r == PICOSAT_UNSATISFIABLE)
	  return Val_int(2);
  return Val_int(0);
}

extern "C" value pico_deref(value solver, value lit) {
  int r = picosat_deref ((void*) solver, Int_val (lit));
  return Val_int (r);
}
