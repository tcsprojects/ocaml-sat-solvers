#define __STDC_FORMAT_MACROS

extern "C" {
#include <caml/mlvalues.h>
#include <caml/memory.h>
}

#include "minisat/simp/SimpSolver.h"

using namespace Minisat;

using Minisat::vec;
using Minisat::Lit;
using Minisat::toLit;
using Minisat::Solver;
using Minisat::Var;
using Minisat::mkLit;
using Minisat::lbool;

extern "C" value minisat_new_solver(value unit) {
  Solver *solver = new Solver();
  return (value)solver;
}

extern "C" value minisat_dispose_solver(value solv) {
  Solver *solver = (Solver *) solv;
  delete solver;
  return Val_unit;
}

extern "C" value minisat_solve(value solv) {
  value r;
  Solver *solver = (Solver *) solv;
  if(solver->solve()) {
    r = Val_int(0);
  } else {
    r = Val_int(1);
  }
  return r;
}

extern "C" value minisat_new_var(value solv) {
  Solver *solver = (Solver *) solv;
  Var var = solver->newVar();
  return Val_int(var);
}

extern "C" value minisat_value_of(value solv, value v) {
  Var var = Int_val(v);
  Solver *solver = (Solver *) solv;
  lbool val = solver->model[var];
  value r;
  if(val == l_False) {
    r = Val_int(0);
  } else if(val == l_True) {
    r = Val_int(1);
  } else if (val == l_Undef) {
    r = Val_int(2);
  } else {
    assert(0);
  }
  return r;
}

extern "C" value minisat_pos_lit(value solv, value v) {
  Solver *solver = (Solver *) solv;
  Var var = Int_val(v);
  Lit lit = mkLit(var, false);
  return Val_int(toInt(lit));
}

extern "C" value minisat_neg_lit(value solv, value v) {
  Solver *solver = (Solver *) solv;
  Var var = Int_val(v);
  Lit lit = mkLit(var, true);
  return Val_int(toInt(lit));
}

static void convert_literals(value l, vec<Lit> &r) {
  while(Int_val(l) != 0) {
    Lit lit = toLit(Int_val(Field(l, 0)));
    r.push(lit);
    l = Field(l, 1);
  }
}

extern "C" value minisat_add_clause(value solv, value c) {
  Solver *solver = (Solver *) solv;
  vec<Lit> clause;
  convert_literals(c, clause);
  solver->addClause(clause);
  return Val_unit;
}


extern "C" value minisat_solve_with_assumption(value solv, value a) {
  vec<Lit> assumption;
  convert_literals(a, assumption);
  value r;
  Solver *solver = (Solver *) solv;
  if(solver->solve(assumption)) {
    r = Val_int(0);
  } else {
    r = Val_int(1);
  }
  return r;
}

