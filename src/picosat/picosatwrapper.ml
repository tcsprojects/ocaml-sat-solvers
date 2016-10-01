open Satwrapper;;
open Picosat;;


class picosatSolver _ =
let solver = pico_init () in
let vars = ref 0 in
object(self) inherit abstractSolver

	method dispose = pico_reset solver

	method add_variable =
		incr vars;
		!vars

	method add_clause a =
		Array.iter (fun lit -> pico_add solver lit) a;
		pico_add solver 0

	method solve = self#solve_with_assumptions []

        method solve_with_assumptions lits =
          List.iter (pico_assume solver) lits;
	  match pico_sat solver (-1) with
	    PicoSat -> SolveSatisfiable
	  | PicoUnsat -> SolveUnsatisfiable
	  | PicoUnknown -> SolveFailure ("picosat reported UNKNOWN")

          
	method get_assignment v = pico_deref solver v = 1

	method print_dimacs _ = failwith "unsupported method: picosat.print_dimacs"
end;;


class picosatSolverFactory =
object inherit solverFactory

	method description = "PicoSAT"
	method identifier = "picosat"
	method short_identifier = "ps"
	method copyright = "Copyright (c) Johannes Kepler University, Linz"
	method url = "http://fmv.jku.at/picosat/"

	method new_instance = new picosatSolver ()
end;;

Satsolvers.register_solver (new picosatSolverFactory)
