print_string "FOOBAR\n\n\n";

let parameters = [(
    "PICOSAT", "Picosat Library file (usually called libpicosat.a)", ref "", ["Picosat"; "Picosatwrapper"], "picosatSolverFactory"
); (
    "ZCHAFF", "ZChaff Library file (usually called libsat.a)", ref "", ["Zchaff"; "Zchaffwrapper"], "zchaffSolverFactory"
); (
    "MINISAT", "Minisat Library file (usually called libminisat.a)", ref "", ["Minisat"; "Minisatwrapper"], "minisatSolverFactory"
); (
    "MINISAT_INC", "Minisat Inclusion directory (usually the Minisat root diredtory)", ref "", [], ""
)] in

(*
let filename_config = "./SatConfig" in
*)

let filename_config = (Sys.getenv "HOME") ^ "/.satconfig" in


(try (
    let file_config = open_in filename_config in

    let strings = Hashtbl.create 10 in

    try
      while true do
        let line = input_line file_config in
        let split = Array.of_list (String.split_on_char '=' line) in
        if Array.length split = 2
        then Hashtbl.add strings (String.trim split.(0)) (String.trim split.(1))
      done
    with End_of_file -> ();

    close_in file_config;

    List.iter (fun (key, _, value, _, _) ->
        try
            value := Hashtbl.find strings key
        with Not_found -> ()
    ) parameters
) with Sys_error _ -> ());
(*
print_string "\ocaml-sat-solvers Configuration\n\n";

List.iter (fun (key, desc, value, _) ->
    print_string ("Configuring " ^ desc ^ "\n");
    print_string ("  Current value: " ^ !value ^ " (empty to disable)\n");
    print_string ("  Hit return to keep current value, 'null' to erase current value and path to set current value.\n");
    print_string ("  " ^ key ^ ": ");
    let new_value = String.trim (read_line ()) in
    print_string ("\n");
    if (new_value = "null")
    then value := ""
    else if (not (new_value = ""))
    then value := new_value
) parameters;

let file_config = open_out filename_config in

List.iter (fun (key, desc, value, _) ->
    output_string file_config ("# " ^ desc ^ "\n");
    if (not (!value = ""))
    then output_string file_config (key ^ " = " ^ !value ^ "\n")
    else output_string file_config ("# " ^ key ^ " = \n");
    output_string file_config "\n"
) parameters;

close_out file_config;
*)
let filename_include = "./src/local/generatedsat.ml" in

let file_include = open_out filename_include in

List.iter (fun (_, _, value, includes, _) ->
    List.iter (fun incl ->
        if (not (!value = ""))
        then output_string file_include ("open " ^ incl ^";;\n")
        else output_string file_include ("(*open " ^ incl ^";;*)\n")
    ) includes
) parameters;
output_string file_include "\nlet register_solvers register_solver =\n";
List.iter (fun (_, _, value, _, factory) ->
    if (not (!value = "") && not (factory = ""))
    then output_string file_include ("    register_solver (new " ^ factory ^ ");\n")
) parameters;

close_out file_include;





let stdlib = Sys.argv.(1) in (*`ocamlfind printconf stdlib`*)
let pwd = Sys.getcwd () in


let parameters = [(
    ["PICOSAT"],
    (fun (args) -> "gcc -c -g -I " ^ stdlib ^ " -o ./_build/PicoSATWrap.o ./src/picosat/backend/PicoSATWrap.cc"),
    (fun (args) -> "-lflag " ^ pwd ^ "/_build/PicoSATWrap.o -lflag " ^ args.(0))
); (
    ["ZCHAFF"],
    (fun (args) -> "gcc -c -g -I " ^ stdlib ^ " -o ./_build/ZchaffWrap.o ./src/zchaff/backend/ZchaffWrap.cc"),
    (fun (args) -> "-ocamlopt 'ocamlopt -cc g++' -lflag " ^ pwd ^ "/_build/ZchaffWrap.o -lflag " ^ args.(0))
); (
    ["MINISAT"; "MINISAT_INC"],
    (fun (args) -> "gcc -D__STDC_LIMIT_MACROS -c -I " ^ stdlib ^ " -I " ^ args.(1) ^ " -o ./_build/MiniSATWrap.o ./src/minisat/backend/MiniSATWrap.cc"),
    (fun (args) -> "-ocamlopt 'ocamlopt -cc g++' -lflag " ^ pwd ^ "/_build/MiniSATWrap.o -lflag " ^ args.(0))
)] in


let filename_config = (Sys.getenv "HOME") ^ "/.satconfig" in
let strings = Hashtbl.create 10 in

(try (
    let file_config = open_in filename_config in

    try
      while true do
        let line = input_line file_config in
        let split = Array.of_list (String.split_on_char '=' line) in
        if Array.length split = 2
        then Hashtbl.add strings (String.trim split.(0)) (String.trim split.(1))
      done
    with End_of_file -> ();

    close_in file_config
) with Sys_error _ -> ());

let compilelines = ref [] in
List.iter (fun (argkeys, f, g) ->
    try
        let argvalues = Array.of_list (List.map (Hashtbl.find strings) argkeys) in
        let cmd = f argvalues in
        print_string (cmd ^ "\n");
        let _ = Sys.command(cmd) in
        compilelines := (g argvalues)::!compilelines
    with Not_found -> ()
) parameters;

let compileline = String.concat " " !compilelines in

let filename_compileline = "./compile.include" in

let file_compileline = open_out filename_compileline in
output_string file_compileline compileline;
close_out file_compileline;;