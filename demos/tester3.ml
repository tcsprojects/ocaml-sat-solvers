open Satwrapper;;

let solver = new Satwrapper.satWrapper (Satsolvers.get_default ()) in
solver#add_clause_array [|Ne None|];
solver#add_clause_array [|Po None|];
solver#solve;;
