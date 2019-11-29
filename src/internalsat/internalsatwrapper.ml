open Satwrapper;;

exception Unsat;;

(*
let show_clause cl = "{" ^ String.concat "," (List.map string_of_int cl) ^ "}"
let show_clauses cls = "{ " ^ String.concat ", " (List.map show_clause cls) ^ " }"
 *)

module LitSet = Set.Make(struct
                    type t = int
                    let compare = compare
                  end);;

class internalSatSolver _ =

(* let solver = Minisat.create() in
 * let result = ref None in
 * 
 * let litmap i = if i >= 0 then (Minisat.Lit.make i) else Minisat.Lit.neg (Minisat.Lit.make (-i)) in *)
  
let lits     = ref 0 in
let clauses  = ref [] in
let solution = ref LitSet.empty in
               
object (this) inherit abstractSolver

	method dispose = ()

	method add_variable =
            (* 
            print_string ("Adding variable " ^ (string_of_int (!lits + 1)) ^ "\n"); 
	    flush stdout;
             *)
            incr lits;
	    !lits

	method add_clause a =
          (* print_string ("Adding clause {" ^ String.concat "," (List.map string_of_int (Array.to_list a)) ^ "}\n"); *) 
          clauses := (Array.to_list a) :: !clauses

	method solve = this#solve_with_assumptions []
          
        method solve_with_assumptions lits =
          let replaceLitInClauses l cls =
            let checkClause cl = List.fold_left (fun (b,acc) -> fun x -> ((b || x=l), if x=(-l) then acc else x::acc)) (false,[]) cl in
            let rec traverseClauses acc = function []      -> acc
                                                 | cl::cls -> let (b,cl') = checkClause cl in
                                                              if b then
                                                                traverseClauses acc cls
                                                              else if cl' = [] then
                                                                raise Unsat
                                                              else
                                                                traverseClauses (cl'::acc) cls
            in
            traverseClauses [] cls
          in

          let rec dpll litmap cls =
            (* collect all literals forming unit clauses *)
            let find_units cls =
              let rec collect acc = function []       -> acc
                                           | []::_    -> raise Unsat
                                           | [x]::cls -> collect (x::acc) cls
                                           | _::cls   -> collect acc cls
              in
              collect [] cls
            in

            (* pick some literal, we simply take the first one *)
            let get_some_lit = function []        -> failwith "internalsat.solve_with_assumptions: can't find literal in empty clause set!"
                                      | []::_     -> raise Unsat 
                                      | (x::_)::_ -> x
            in

            let auxcls = ref cls in
            let auxlitmap = ref litmap in
            let continue = ref true in
            let rec doWhile c = c (); if !continue then doWhile c in

            (* unit propagation *)
            (*
            print_string ("Calling DPLL on clauses " ^ show_clauses !auxcls ^ "\n"); flush stdout;
            print_string "Unit propagation ... \n"; flush stdout;
            *)
            doWhile (fun _ -> continue := false;
                              auxlitmap := List.fold_left (fun lm -> fun l -> continue := true;
                                                                              auxcls := replaceLitInClauses l !auxcls;
                                                                              LitSet.add l lm)
                                             !auxlitmap
                                             (let units = find_units !auxcls in
                                              (* print_string ("Units: " ^ show_clause units ^ "\n"); *)
                                              units));
            (*
            print_string ("Current clauses: " ^ show_clauses !auxcls ^ "\n");
            print_string ("Current (partial) solution: " ^ show_clause (LitSet.elements !auxlitmap) ^ "\n"); flush stdout;
            *)            
            (* branch on some literal *)
            match !auxcls with
              []   -> solution := !auxlitmap; SolveSatisfiable
            | [[]] -> solution := LitSet.empty;
                      SolveUnsatisfiable
            | _    -> let l = get_some_lit !auxcls in
                      (* print_string ("Branching on literal " ^ string_of_int l ^ "\n"); flush stdout; *)
                      auxlitmap := LitSet.add l !auxlitmap;
                      match (try dpll !auxlitmap (replaceLitInClauses l !auxcls) with Unsat -> SolveUnsatisfiable) with
                        SolveUnsatisfiable -> auxlitmap := LitSet.add (-l) (LitSet.remove l !auxlitmap);
                                              (* print_string ("Backtracking. Now trying " ^ string_of_int (-l) ^ "\n"); flush stdout; *)
                                              dpll !auxlitmap (replaceLitInClauses (-l) !auxcls)
                      | result -> result
          in
                                
          try
            (* implement the assumptions *)
            (*
            print_string ("Current clauses: "  ^ show_clauses !clauses ^ "\n"); flush stdout;
            print_string ("Implementing assumptions { " ^ String.concat ", " (List.map (fun l -> "{" ^ string_of_int l ^ "}") lits) ^ " }\n"); flush stdout;
            *)
            let (litmap,initclauses) = List.fold_left (fun (lm,cls) -> fun l -> (LitSet.add l lm, replaceLitInClauses l cls))
                                         (LitSet.empty,!clauses)
                                         lits
            in
            (* start DPLL *)
            dpll litmap initclauses
          with Unsat -> solution := LitSet.empty;
                        SolveUnsatisfiable

	method get_assignment v = (LitSet.mem v !solution) && (not (LitSet.mem (-v) !solution))

	method print_dimacs _ = failwith "unsupported method: internalsat.print_dimacs"
end;;

class internalSatSolverFactory =
object inherit solverFactory

	method description = "InternalSAT"
	method identifier = "internal"
	method short_identifier = "in"
	method copyright = "Copyright (c) Oliver Friedmann, Martin Lange"
	method url = "https://github.com/tcsprojects/ocaml-sat-solvers"

	method new_instance = new internalSatSolver ()
end;;
