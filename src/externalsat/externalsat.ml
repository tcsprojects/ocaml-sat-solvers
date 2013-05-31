open Satwrapper;;

class externalSolver (filename: string) =

    let var_count = ref 0 in
    let clauses = ref [] in
    let clause_count = ref 0 in
    let vars = ref [||] in

object inherit abstractSolver

	method dispose =
		var_count := 0;
		clauses := [];
		clause_count := 0

	method add_variable =
		incr var_count;
		!var_count

	method add_clause a =
		clauses := a::!clauses;
		incr clause_count

	method solve =
	  let in_channel = open_in filename in
	  let lexbuf = Lexing.from_channel in_channel in
	  let parsed = Satsolutionparser.program Satsolutionlexer.lexer lexbuf in
	  match parsed with
	  	Satsolutionparserhelper.ParsedUnsat -> SolveUnsatisfiable
	  | Satsolutionparserhelper.ParsedError s -> SolveFailure s
	  | Satsolutionparserhelper.ParsedSat l -> (
	  		vars := Array.make (!var_count + 1) false;
	  		List.iter (fun i -> if i >= 0 then (!vars).(i) <- true) l;
	  		SolveSatisfiable
	  )

        method solve_with_assumptions _ = failwith ("externalsat.solve_with_assumptions not implemented yet")

	method get_assignment v = (!vars).(v)

	method print_dimacs  _ = failwith "unsupported method: externalsolver.print_dimacs"
end;;


class externalSolverFactory (filename: string) =
object inherit solverFactory

	method description = "ExternalSolver"
	method identifier = "externalsat"
	method short_identifier = "es"
	method copyright = "Copyright (c) University of Munich"
	method url = "http://www.tcs.ifi.lmu.de"

	method new_instance = new externalSolver filename
end;;
