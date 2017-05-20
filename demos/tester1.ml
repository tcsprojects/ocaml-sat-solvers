open Satwrapper;;
open Arg;;
open Generatedsat;;

let msg s = output_string stdout s;;

let binlog n = int_of_float (ceil ((log (float_of_int n)) /. (log 2.)))

type vars = Z of int | X of int | Y of int

let factorize' z =
(*	let solver = new Satwrapper.satWrapper (new Preprocessor.preprocessorSolverFactory (Satsolvers.get_default ())) in *)
	let solver = new Satwrapper.satWrapper (Satsolvers.get_default ()) in
	let l = binlog z in
	let z = ref z in
	for i = 0 to l * 2 - 1 do
		solver#add_clause_array [|if !z mod 2 = 0 then Ne (Z i) else Po (Z i)|];
		z := !z / 2
	done;
	solver#add_clause_array (Array.init l (fun i -> if i > 0 then Po (X i) else Ne (X i)));
	solver#add_clause_array (Array.init l (fun i -> if i > 0 then Po (Y i) else Ne (Y i)));
	solver#add_helper_multiplication (Array.init l (fun i -> Po (X i))) (Array.init l (fun i -> Po (Y i))) (Array.init (l * 2) (fun i -> Po (Z i)));
	solver#solve;
	let x =
        match solver#get_solve_result with
            SolveSatisfiable -> Some (
            	let x = ref 0 in
            	let y = ref 0 in
            	for i = l - 1 downto 0 do
            		x := !x * 2;
            		y := !y * 2;
            		if solver#get_variable_bool (X i) then incr x;
            		if solver#get_variable_bool (Y i) then incr y
            	done;
            	(!x, !y)
            )
        |   SolveUnsatisfiable -> None
        |   SolveFailure s -> failwith s
    in
	solver#dispose;
	x

let rec factorize n =
	if n <= 10 then (
		if List.mem n [0; 1; 2; 3; 5; 7] then [n]
		else if n = 4 then [2;2] else if n = 6 then [2;3] else if n = 8 then [2;2;2] else if n = 9 then [3;3] else [2;5]
	)
	else
		match factorize' n with
			None -> [n]
		|	Some (a, b) -> List.sort compare ((factorize a) @ (factorize b))


let list_format formater = function
	[] -> "[]"
|   (h::t) -> (List.fold_left (fun s i -> s ^ ", " ^ (formater i)) ("[" ^ (formater h)) t) ^ "]";;

module CommandLine =
struct

  let satsolv = Satsolvers.get_list ()

  let speclist =  [("--changesat", String (fun s -> Satsolvers.set_default s),
                      "\n     select sat solver; " ^ if satsolv = [] then "no sat solvers included!" else (
			      "default is " ^ ((Satsolvers.get_default ())#identifier) ^
	              "\n     available: " ^ list_format (fun f -> f#identifier) (Satsolvers.get_list ())))]

  let header = "Factorizer\nAuthors: Oliver Friedmann and Martin Lange, 2008\n\n"

  let usage = (header ^ "Usage: tester [number]\n" ^
                        "Factorizes the given [number] using a SAT solver.\n\nOptions are")
end ;;

open CommandLine ;;


let _ =
    let numb = ref (-1) in
    Arg.parse speclist (fun n -> numb := int_of_string n) usage;
	let n = !numb in
	if n = -1 then failwith "no number given - try ./tester --help";
	(*
	msg ("Registered sat solvers:\n");
	Satsolvers.enum_solvers (fun fact ->
		msg (fact#identifier ^ "\n")
	);
	*)
	msg (string_of_int n ^ " = ");
	let l = Array.of_list (factorize n) in
	for i = 0 to Array.length l - 2 do
		msg (string_of_int l.(i) ^ " * ")
	done;
	msg (string_of_int l.(Array.length l - 1) ^ "\n");
