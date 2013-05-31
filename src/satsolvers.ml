open Satwrapper;;

module String_for_set =
struct
  type t = string
  let compare = compare
end ;;
module StringMap = Map.Make(String_for_set) ;;

let solvermap = ref StringMap.empty;;

let default = ref None;;

let register_solver solver_factory =
	let identifier = solver_factory#identifier in
	if StringMap.mem identifier !solvermap
	then failwith ("Solver `" ^ identifier ^ "' already registered!\n")
	else (
		solvermap := StringMap.add identifier solver_factory !solvermap;
		default := Some solver_factory
	);;
	
let mem_solver identifier = StringMap.mem identifier !solvermap;;

let find_solver identifier = StringMap.find identifier !solvermap;;

let enum_solvers it = StringMap.iter (fun _ f -> it f) !solvermap;;

let fold_solvers fo b = StringMap.fold (fun _ f x -> fo f x) !solvermap b;;

let get_list _ = fold_solvers (fun s l -> s::l) []

let get_default _ =
	match !default with
		Some f -> f
	|	None -> failwith "no sat solvers registered!"

let set_default identifier =
	default := Some (find_solver identifier)