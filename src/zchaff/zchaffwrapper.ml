open Zchaff;;
open Satwrapper;;

class zchaffSolver _ =
let solver = zchaff_InitManager () in
let _ = zchaff_SetTimeLimit solver (60.0 *. 60.0 *. 24.0 *. 31.0) in
let permanentGID = zchaff_AllocClauseGroupID solver in
let temporaryGID = ref (zchaff_AllocClauseGroupID solver) in
object(self) inherit abstractSolver

	method dispose = zchaff_ReleaseManager solver

	method add_variable = zchaff_AddVariable solver

	method private add_clause_aux a id = zchaff_AddClause solver a id

        method add_clause a = self#add_clause_aux a permanentGID 

	method solve = self#solve_with_assumptions []

        method solve_with_assumptions lits =
          zchaff_DeleteClauseGroup solver !temporaryGID;
          temporaryGID := zchaff_AllocClauseGroupID solver;
          List.iter (fun l -> self#add_clause_aux [|l|] !temporaryGID) lits;
          match zchaff_Solve solver with
	    2 -> SolveSatisfiable
	  | 1 -> SolveUnsatisfiable
	  | i -> SolveFailure ("zchaff reported " ^ string_of_int i ^ " instead of 1 / 2");
          

	method get_assignment v = zchaff_GetVarAsgnment solver v = 1

	method incremental_reset = zchaff_Reset solver

	method print_dimacs _ = failwith "unsupported method: zchaff.print_dimacs"
end;;

class zchaffSolverFactory =
object inherit solverFactory

	method description = "Zchaff"
	method identifier = "zchaff"
	method short_identifier = "zc"
	method copyright = "Copyright (c) Princeton University"
	method url = "http://www.princeton.edu/~chaff/zchaff.html"

	method new_instance = new zchaffSolver ()
end;;

Satsolvers.register_solver (new zchaffSolverFactory)
