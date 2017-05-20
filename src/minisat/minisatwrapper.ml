open Satwrapper;;


class minisatSolver _ =

let solver = Minisat.create() in
let lits = ref 0 in

let litmap i = if i >= 0 then (Minisat.Lit.make i) else Minisat.Lit.neg (Minisat.Lit.make (-i)) in

object inherit abstractSolver

	method dispose = ()

	method add_variable =
	    incr lits;
	    !lits

	method add_clause a = Minisat.add_clause_l solver (Array.to_list (Array.map litmap a))

	method solve =
	  try
	    Minisat.solve solver;
	    SolveSatisfiable
	  with Minisat.Unsat -> SolveUnsatisfiable

    method solve_with_assumptions lits =
        let lits' = Array.of_list (List.map litmap lits) in
        try
          Minisat.solve ~assumptions:lits' solver;
          SolveSatisfiable
        with Minisat.Unsat -> SolveUnsatisfiable

	method get_assignment v = Minisat.value solver (Minisat.Lit.make v) = Minisat.V_true

	method print_dimacs _ = failwith "unsupported method: minisat.print_dimacs"
end;;

class minisatSolverFactory =
object inherit solverFactory

	method description = "MiniSAT"
	method identifier = "minisat"
	method short_identifier = "ms"
	method copyright = "Copyright (c) Chalmers University"
	method url = "http://minisat.se/"

	method new_instance = new minisatSolver ()
end;;