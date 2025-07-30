open Satwrapper;;
open Z3;;

class z3Solver (timetable: Timing.timetable) =

  let ctx = mk_context [] in
  let solver = Solver.mk_simple_solver ctx in
  let exprres = ref (Boolean.mk_val ctx false) in
  let clsres = ref !exprres in
  let solres = ref Solver.UNKNOWN in
  
  let lits = ref 0 in
  (*  let result = ref None in *)
  let model = ref None in

  let time_prop = Timing.time timetable "proposition creation" in 
  let time_add = Timing.time timetable "clause addition" in
  let time_solve = Timing.time timetable "SAT solving" in 

  object (self) inherit abstractSolver

    method private litmap i =
      (if i >= 0 then
        time_prop (fun _ -> exprres := Boolean.mk_const ctx (Symbol.mk_int ctx i))
      else
        time_prop (fun _ -> exprres := Boolean.mk_not ctx (Boolean.mk_const ctx (Symbol.mk_int ctx (-i))))
      );
      !exprres

    method private translate_clause cls =
      match cls with
        [| |] -> time_prop (fun _ -> exprres := Boolean.mk_val ctx false); !exprres
      | [|p|] -> self#litmap p
      | a     -> let a' = List.map self#litmap (Array.to_list a) in
                 time_prop (fun _ -> exprres := Boolean.mk_or ctx a');
                 !exprres

    method dispose = ()

    method add_variable =
      incr lits;
      !lits

    method add_clause a =
      time_prop (fun _ -> clsres := self#translate_clause a);
      time_add (fun _ -> Solver.add solver [ !clsres ]) 

    method solve =
      time_solve (fun _ -> solres := Solver.check solver []);
      match !solres with
        Solver.SATISFIABLE   -> (match Solver.get_model solver with
                                   Some m -> model := Some m; SolveSatisfiable
                                 | None -> failwith "Z3 claims formula is satisfiable but cannot construct a model.") 
      | Solver.UNSATISFIABLE -> SolveUnsatisfiable
      | Solver.UNKNOWN       -> SolveFailure("Z3 could not determine satisfiability.")
                              
    method solve_with_assumptions lits =
      Solver.push solver;
      time_add (fun _ -> Solver.add solver (List.map self#litmap lits));
      let r = self#solve in
      Solver.pop solver 1;
      r

    method get_assignment v =
      match !model with
        Some m -> (match Model.eval m (self#litmap v) false with
                     None -> failwith "Z3 does not deliver an assignment even though there is a model."
                   | Some e -> Boolean.is_true e)
      | None -> failwith "Z3 does not deliver an assignment because there is no model."
              
    method print_dimacs _ = failwith "unsupported method: z3.print_dimacs"
end;;

class z3SolverFactory =
object inherit solverFactory

	method description = "Z3"
	method identifier = "z3"
	method short_identifier = "z3"
	method copyright = "Copyright (c) Microsoft Research"
	method url = "https://github.com/Z3Prover/z3"
	method new_timed_instance timetable = new z3Solver timetable
end;;
