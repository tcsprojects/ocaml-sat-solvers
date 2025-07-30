(* open Z3wrapper;; *)
open Minisatwrapper;;
open Internalsatwrapper;;

let _ =
    (*Satsolverregistry.register_solver (new z3SolverFactory);*)
    Satsolverregistry.register_solver (new minisatSolverFactory);
    Satsolverregistry.register_solver (new internalSatSolverFactory);;

let register_solver = Satsolverregistry.register_solver;;

let mem_solver = Satsolverregistry.mem_solver;;

let find_solver = Satsolverregistry.find_solver;;

let enum_solvers = Satsolverregistry.enum_solvers;;

let fold_solvers = Satsolverregistry.fold_solvers;;

let get_list = Satsolverregistry.get_list;;

let get_default = Satsolverregistry.get_default;;

let set_default = Satsolverregistry.set_default;;
