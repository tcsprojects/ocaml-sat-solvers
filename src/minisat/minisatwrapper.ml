open Satwrapper;;


class minisatSolver (timetable: Timing.timetable) =

let solver = Minisat.create() in
let lits = ref 0 in
let result = ref None in
let litres = ref (Minisat.Lit.make 1) in
let solres = ref (SolveFailure("no attempt at solving made yet")) in

let time_prop = Timing.time timetable "proposition creation" in 
let time_add = Timing.time timetable "clause addition" in
let time_solve = Timing.time timetable "SAT solving" in 

object (self) inherit abstractSolver

  method private litmap i =
    (if i >= 0 then
      time_prop (fun _ -> litres := Minisat.Lit.make i)
    else
      time_prop (fun _ -> litres := Minisat.Lit.neg (Minisat.Lit.make (-i)))
    );
    !litres

  method dispose = ()

  method add_variable =
    incr lits;
    !lits

  method add_clause a =
    if !result = None then (
      try
	time_add (fun _ -> Minisat.add_clause_l solver (Array.to_list (Array.map self#litmap a)))
      with Minisat.Unsat -> result := Some SolveUnsatisfiable
    )

  method solve =
    match !result with
      Some r -> r
    | None -> time_solve (fun _-> solres := try
	                                     Minisat.solve solver;
	                                     SolveSatisfiable 
	                                    with Minisat.Unsat -> SolveUnsatisfiable);
              !solres

  method solve_with_assumptions lits =
    match !result with
      Some r -> r
    | None -> let lits' = Array.of_list (List.map self#litmap lits) in
              time_solve (fun _ -> solres := try
                                              Minisat.solve ~assumptions:lits' solver;
                                              SolveSatisfiable
                                             with Minisat.Unsat -> SolveUnsatisfiable);
              !solres
              
  method get_assignment v =
    Minisat.value solver (Minisat.Lit.make v) = Minisat.V_true

  method print_dimacs _ = failwith "unsupported method: minisat.print_dimacs"
end;;

class minisatSolverFactory =
object inherit solverFactory

	method description = "MiniSAT"
	method identifier = "minisat"
	method short_identifier = "ms"
	method copyright = "Copyright (c) Chalmers University"
	method url = "http://minisat.se/"
	method new_timed_instance timetable = new minisatSolver timetable
end;;
