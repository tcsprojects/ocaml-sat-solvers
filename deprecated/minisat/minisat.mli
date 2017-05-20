type minisat_solution = SAT | UNSAT
type minisat_solver

external new_solver : unit -> minisat_solver = "minisat_new_solver"
external dispose_solver : minisat_solver -> unit = "minisat_dispose_solver"
external solve : minisat_solver -> minisat_solution = "minisat_solve"

type minisat_var = int

external new_var : minisat_solver -> minisat_var = "minisat_new_var"

type minisat_value = NegValue | PosValue | UndefValue

external value_of : minisat_solver -> minisat_var -> minisat_value = "minisat_value_of"

type minisat_lit = int

external pos_lit : minisat_solver -> minisat_var -> minisat_lit = "minisat_pos_lit"
external neg_lit : minisat_solver -> minisat_var -> minisat_lit = "minisat_neg_lit"
external add_clause : minisat_solver -> minisat_lit list -> unit = "minisat_add_clause"
external solve_with_assumption : minisat_solver -> minisat_lit list -> minisat_solution = "minisat_solve_with_assumption"
