open Satwrapper;;
open Z3;;

class z3Solver _ =

  let ctx = mk_context [] in
  let solver = Solver.mk_simple_solver ctx in

  let lits = ref 0 in
  (*  let result = ref None in *)
  let model = ref None in
  
  let litmap i =
    if i >= 0 then
      Boolean.mk_const ctx (Symbol.mk_int ctx i)
    else
      Boolean.mk_not ctx (Boolean.mk_const ctx (Symbol.mk_int ctx (-i)))
  in

  let translate_clause = function
       [| |] -> Boolean.mk_val ctx false
     | [|p|] -> litmap p
     | a     -> Boolean.mk_or ctx (List.map litmap (Array.to_list a))
  in
    
  object (self) inherit abstractSolver

	method dispose = ()

	method add_variable =
	    incr lits;
	    !lits

	method add_clause a =
	  Solver.add solver [ translate_clause a ] 

	method solve =
          match Solver.check solver [] with
            SATISFIABLE   -> (match Solver.get_model solver with
                                Some m -> model := Some m; SolveSatisfiable
                              | None -> failwith "Z3 claims formula is satisfiable but cannot construct a model.") 
          | UNSATISFIABLE -> SolveUnsatisfiable
          | UNKNOWN       -> SolveFailure("Z3 could not determine satisfiability.")
            
        method solve_with_assumptions lits =
          Solver.push solver;
          Solver.add solver (List.map litmap lits);
          let r = self#solve in
          Solver.pop solver 1;
          r

	method get_assignment v =
          match !model with
            Some m -> (match Model.eval m (litmap v) false with
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

	method new_instance = new z3Solver ()
end;;
