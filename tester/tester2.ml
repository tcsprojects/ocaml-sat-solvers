open Satwrapper;;
open Arg ;;
open Generatedsat;;

type rlgrammar = { start : string;
                   terminals : string list;
                   nonterminals: string list;
                   rules : (string * (string array list)) list
                 }

(*
let grammar = { start = "S";
                terminals = [ "a"; "b" ];
                rules = [ ("S", [ [|"a"; "A"|] ]);
                          ("A", [ [||]; [|"a"|]; [|"b"; "B"|] ]);
                          ("B", [ [|"b"; "b"; "S"|] ]) ]
              }
*)

(* must not contain epsilon productions 
   each right-hand side is of the form (terminal+ (nonterminal | "#")) *)

let grammar = { start = "S";
                terminals = [ "a"; "b" ];
                nonterminals = [ "S"; "A" ];
                rules = [ ("S", [ [|"a"; "A"|]; [|"a"; "#"|] ]);
                          ("A", [ [|"b"; "S"|] ]) ]
              }

let unordered_pairs l =
  let rec uo_pairs acc =
    function []     -> acc
           | (a::l) -> uo_pairs ((List.map (fun b -> (a,b)) l)@acc) l
  in
  uo_pairs [] l

let upto n =
  let rec down acc i = if i<0 then acc else down (i::acc) (i-1) in
  down [] (n-1)

let iteri f l = 
  let rec it f i = function [] -> ()
                          | (x::xs) -> (f i x); it f (i+1) xs
  in
  it f 0 l
 
type variable = D of string * int
              | R of string * int * int
	      | Start of int

let showVar = function D(a,i) -> "D(" ^ a ^ "," ^ string_of_int i ^ ")"
                     | R(a,i,j) -> "R(" ^ a ^ "," ^ string_of_int i ^ "," ^ string_of_int j ^ ")"
		     | Start(i) -> "S(" ^ string_of_int i ^ ")"
let show = function Po(v) -> showVar v
                  | Ne(v) -> "-" ^ showVar v

let check _ =
  let solver = new Satwrapper.satWrapper (Satsolvers.get_default ()) in

  let clauses = ref [] in

  let add_clause_array a = print_string ("Adding clause [ " ^ String.concat " , " (List.map show (Array.to_list a)) ^ " ]\n");
                           clauses := a :: !clauses
  in
  let add_clause_list l = add_clause_array (Array.of_list l) in

  let feed_clauses _ =
    List.iter (fun a -> solver#add_clause_array a) !clauses;
    clauses := []
  in

  let rec downfrom = function 0 -> []
                            | i -> i :: (downfrom (i-1))
  in

  let rec check_engine i =
    (* create constraints for terminal symbols *)
    add_clause_list (List.map (fun a -> Po (D(a,i))) grammar.terminals);
    add_clause_array [| Ne(D("#",i)) |];
    List.iter (fun (a,b) -> add_clause_array [| Ne (D(a,i)); Ne (D(b,i)) |])
              (unordered_pairs grammar.terminals);

    (* create constraints for all the rules *)
    List.iter 
      (fun (n,rls) -> 
         add_clause_list ((Ne(D(n,i))) :: (List.map (fun j -> Po(R(n,i,j))) (upto (List.length rls))));
         iteri 
           (fun j -> fun rl -> 
              if i + 1 - Array.length rl >= 0 then
                Array.iteri (fun k -> fun v -> add_clause_array [| Ne(R(n,i,j)); Po(D(v,i-k)) |]) rl
              else
                add_clause_array [| Ne(R(n,i,j)) |]
              )
            rls)
      grammar.rules ;

    (* create constraint for starting symbol *)
    add_clause_array [| Po(D(grammar.start,i)); Po(Start(i)) |];

    (* feed all collected clauses to the solver *)
    feed_clauses ();

    (* solve using assumptions to blind out the Start(i)-Literal and the clauses containing TooShort-Literals *)
    solver#solve_with_assumptions [ Ne(Start(i)) ];
    (match solver#get_solve_result with
      SolveSatisfiable -> let solution = List.map (fun j -> List.find (fun a -> 1 = solver#get_variable (D(a,j))) grammar.terminals) 
                                                  (downfrom i) 
                          in
                          print_string ("A derivable word of length " ^ string_of_int i ^ " is " ^ String.concat "" solution ^ ".\n")
    | SolveUnsatisfiable -> print_string ("No word of length " ^ string_of_int i ^ " can be derived.\n")
    | SolveFailure(s)    -> print_string ("Something has gone wrong at stage " ^ string_of_int i ^ ": " ^ s ^ "\n"));

    solver#incremental_reset;

    (* delete clause about starting symbol *)
    add_clause_array [| Po(Start(i)) |];

    (* if i < 10 then *) check_engine (i+1)
  in
  add_clause_array [| Po(D("#",0)) |];
  List.iter (fun a -> add_clause_array [| Ne(D(a,0)) |]) (grammar.terminals @ grammar.nonterminals);
  check_engine 1


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

  let header = "Right-linear grammar emptiness checker\nAuthors: Oliver Friedmann and Martin Lange, 2011\n\n"

  let usage = (header ^ "Usage: tester2\n" ^
                        "Computes a word recognised by a (hardcoded) right-linear grammar using an incremental SAT solver.\n\nOptions are")
end ;;

open CommandLine ;;


let _ =
    Arg.parse speclist (fun _ -> ()) usage;
    check () 
