open Satwrapper;;
open Minisat;;


class minisatSolver _ =
let solver = new_solver () in
object inherit abstractSolver

	method dispose = dispose_solver solver

	method add_variable =
		let i = new_var solver in
		if i = 0 then new_var solver else i

	method add_clause a = add_clause solver (Array.to_list (Array.map (fun i -> if i >= 0 then pos_lit solver i else neg_lit solver (-i)) a))

	method solve =
	  match Minisat.solve solver with
	    SAT -> SolveSatisfiable
	  | UNSAT -> SolveUnsatisfiable

        method solve_with_assumptions lits =
        	let lits' = List.map (fun l ->
        		if l >= 0 then Minisat.pos_lit solver l else Minisat.neg_lit solver (-l)
        	) lits in
          match Minisat.solve_with_assumption solver lits' with
	    SAT -> SolveSatisfiable
	  | UNSAT -> SolveUnsatisfiable

	method get_assignment v = value_of solver v = PosValue

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

Satsolvers.register_solver (new minisatSolverFactory)
