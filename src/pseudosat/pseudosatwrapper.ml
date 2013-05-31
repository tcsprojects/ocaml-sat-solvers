open Satwrapper;;


class pseudoSolver _ =
let vars = ref 0 in
let clauses = ref [] in
let clause_count = ref 0 in
object inherit abstractSolver

	method dispose =
		vars := 0;
		clauses := [];
		clause_count := 0

	method add_variable =
		incr vars;
		!vars

	method add_clause a =
		clauses := a::!clauses;
		incr clause_count

	method solve = SolveFailure ("pseudo solver cannot solve")

    method solve_with_assumptions _ = SolveFailure ("pseudo solver cannot solve at all, especially not under some silly assumptions")

	method get_assignment v = failwith "pseudo solver get assignment"

	method print_dimacs outhandle =
		let write s = output_string outhandle s in
		let writeln s = write (s ^ "\n") in
		writeln ("p cnf " ^ string_of_int !vars ^ " " ^ string_of_int !clause_count);
		List.iter (fun c ->
			Array.iter (fun l -> write (string_of_int l ^ " ")) c;
			writeln ("0")
		) !clauses
end;;


class pseudoSolverFactory =
object inherit solverFactory

	method description = "PseudoSolver"
	method identifier = "pseudosat"
	method short_identifier = "pe"
	method copyright = "Copyright (c) University of Munich"
	method url = "http://www.tcs.ifi.lmu.de"

	method new_instance = new pseudoSolver ()
end;;


let pseudo_factory = ref (new pseudoSolverFactory)

let get_pseudo_factory = !pseudo_factory

(* Satsolvers.register_solver (new pseudoSolverFactory) *)
