open Satwrapper;;

module Int_for_set =
struct
  type t = int
  let compare = compare
end ;;
module IntSet = Set.Make(Int_for_set) ;;

type vartype = VarUndef | VarTrue | VarFalse

class preprocessorSolver (solver: abstractSolver) =

	let variables = Hashtbl.create 10 in
	let clauses = Hashtbl.create 10 in
	let vartrans = Hashtbl.create 10 in
	let is_unsat = ref false in
	let var_counter = ref 0 in
	let clause_counter = ref 0 in
	let clause_num = ref 0 in
	let clausetrans = Hashtbl.create 10 in

object (self) inherit abstractSolver

	method dispose =
		solver#dispose;
		Hashtbl.clear variables;
		Hashtbl.clear clauses;
		Hashtbl.clear vartrans;
		Hashtbl.clear clausetrans;
		is_unsat := false;
		var_counter := 0;
		clause_counter := 0;
		clause_num := 0

	method incremental_reset = solver#incremental_reset

	method add_variable =
		incr var_counter;
		Hashtbl.add variables !var_counter (ref VarUndef, ref IntSet.empty, ref IntSet.empty);
		!var_counter

	method private get_singleton (ps, ns) =
		if IntSet.is_empty !ps then - (IntSet.min_elt !ns) else IntSet.min_elt !ps

	method private remove_clause c =
		let (p, n) = Hashtbl.find clauses c in
		IntSet.iter (fun i -> let (_, ps, _) = Hashtbl.find variables i in ps := IntSet.remove c !ps) !p;
		IntSet.iter (fun i -> let (_, _, ns) = Hashtbl.find variables i in ns := IntSet.remove c !ns) !n;
		Hashtbl.remove clauses c;
		decr clause_num

	method private propagate_bindings alist =
		if (not !is_unsat) && (alist != []) then (
			let (l, alist) = (List.hd alist, List.tl alist) in
			let k = if l > 0 then l else -l in
			let (v, ps, ns) = Hashtbl.find variables k in
			v := if l > 0 then VarTrue else VarFalse;
			let flp (x, y) = if l > 0 then (x, y) else (y, x) in
			let (ps, ns) = flp (ps, ns) in
			let cop = !ps in
			ps := IntSet.empty;
			IntSet.iter self#remove_clause cop;
			let alist = ref alist in
			IntSet.iter (fun c -> if not !is_unsat then (
				let (cp, cn) = flp (Hashtbl.find clauses c) in
				cn := IntSet.remove k !cn;
				match IntSet.cardinal !cp + IntSet.cardinal !cn with
					0 -> is_unsat := true
				|	1 -> alist := (self#get_singleton (flp (cp, cn)))::!alist
				|	_ -> ()
			)) !ns;
			ns := IntSet.empty;
			self#propagate_bindings !alist
		)

	method add_clause a =
		if not !is_unsat then (
			let ps = ref IntSet.empty in
			let ns = ref IntSet.empty in
			let is_true = ref false in
			let i = ref 0 in
			let n = Array.length a in
			while (not !is_true) && (!i < n) do
				let l = a.(!i) in
				let (valu, se, ind) = if l > 0 then (VarTrue, ps, l) else (VarFalse, ns, -l) in
				let (v, _, _) = Hashtbl.find variables ind in
				if !v = VarUndef
				then se := IntSet.add ind !se
				else if !v = valu
				then is_true := true;
				incr i
			done;
			if not !is_true
			then self#internal_add ps ns
		)


	method private internal_add ps ns = match IntSet.cardinal !ps + IntSet.cardinal !ns with
				0 -> is_unsat := true
			     |  1 -> self#propagate_bindings [self#get_singleton (ps, ns)]
			     |  _ -> if IntSet.is_empty (IntSet.inter !ps !ns) then (
					incr clause_counter;
					incr clause_num;
					Hashtbl.add clauses !clause_counter (ps, ns);
					IntSet.iter (fun v ->
						let (_, p, _) = Hashtbl.find variables v in
						p := IntSet.add !clause_counter !p
					) !ps;
					IntSet.iter (fun v ->
						let (_, _, n) = Hashtbl.find variables v in
						n := IntSet.add !clause_counter !n
					) !ns
				)

	method private is_simple_clause c =
		let (ps, ns) = Hashtbl.find clauses c in
		(IntSet.exists (fun i -> let (_, _, n) = Hashtbl.find variables i in IntSet.is_empty !n) !ps) ||
		(IntSet.exists (fun i -> let (_, p, _) = Hashtbl.find variables i in IntSet.is_empty !p) !ns)


	method private prepare_solver solver ht ct =
		if (not !is_unsat) && (!clause_num > 0) then (
			Hashtbl.iter (fun c (ps, ns) -> if not (Hashtbl.mem ct c || self#is_simple_clause c) then (
				let l = ref [] in
				IntSet.iter (fun v -> l := v::!l) !ps;
				IntSet.iter (fun v -> l := (-v)::!l) !ns;
				List.iter (fun l ->
					let l = if l > 0 then l else -l in
					if not (Hashtbl.mem ht l) then (
						let i = solver#add_variable in
						Hashtbl.add ht l i
					)
				) !l;
				let l = List.map (fun l ->
					if l > 0 then Hashtbl.find ht l
						 else - (Hashtbl.find ht (-l))
				) !l in
				Hashtbl.add ct c true;
				solver#add_clause (Array.of_list l);
			)) clauses
		)

	method solve =
		(*
		self#prepare_solver solver vartrans clausetrans;
		if !is_unsat then SolveUnsatisfiable
		else if !clause_num = 0 then SolveSatisfiable
		else solver#solve
		*)
		if !is_unsat then SolveUnsatisfiable
		else if !clause_num = 0 then SolveSatisfiable
		else (
			self#prepare_solver solver vartrans clausetrans;
			solver#solve
		)

    method solve_with_assumptions assumptions = 
		if !is_unsat then SolveUnsatisfiable
		else if !clause_num = 0 then SolveSatisfiable
		else (
			self#prepare_solver solver vartrans clausetrans;
			let real_assum = ref [] in
			let now_unsat = ref false in
			List.iter (fun v ->
				let v' = if v >= 0 then v else -v in
				if Hashtbl.mem vartrans v' then real_assum := v::!real_assum
				else let (s, _, _) = Hashtbl.find variables v' in
					 now_unsat := !now_unsat || ((!s == VarTrue) && (v < 0)) || ((!s == VarFalse) && (v >= 0))
			) assumptions;
			if !now_unsat then SolveUnsatisfiable
			else solver#solve_with_assumptions !real_assum
		)

	method get_assignment v =
		if !is_unsat then failwith "unsat!"
		else let (w, ps, ns) = Hashtbl.find variables v in
		     match !w with
			VarTrue -> true
		     |  VarFalse -> false
		     |  VarUndef -> if IntSet.is_empty !ns then true
				    else if IntSet.is_empty !ps then false
				    else if !clause_num = 0 then false
				    else solver#get_assignment (Hashtbl.find vartrans v)

	method print_dimacs s =
		let pseudo = Pseudosatwrapper.get_pseudo_factory#new_instance in
		self#prepare_solver pseudo (Hashtbl.create 10) (Hashtbl.create 10);
		pseudo#print_dimacs s;
		pseudo#dispose

end;;


(*
class preprocessorSolver (solver: abstractSolver) =

	let variables = Hashtbl.create 10 in
	let clauses = ref [] in
	let vartrans = Hashtbl.create 10 in
	let is_unsat = ref false in
	let var_counter = ref 0 in

object (self) inherit abstractSolver

	method dispose =
		if !clauses != [] then solver#dispose;
		Hashtbl.clear variables;
		clauses := [];
		Hashtbl.clear vartrans;
		is_unsat := false;
		var_counter := 0

	method add_variable =
		incr var_counter;
		Hashtbl.add variables !var_counter VarUndef;
		!var_counter

	method private get_literal l =
		if l > 0 then Hashtbl.find variables l
		else match Hashtbl.find variables (-l) with
			VarUndef -> VarUndef | VarTrue -> VarFalse | VarFalse -> VarTrue

	method private add_clause a =
		clauses := (Array.to_list a)::!clauses

	method private add_binding l =
		let (v, b) = if l > 0 then (l, VarTrue) else (-l, VarFalse) in
		Hashtbl.replace variables v b

	method private simplify_clause l bdgs =
		let fnd = ref false in
		let l = List.map (fun l ->
			((if IntSet.mem l bdgs then (fnd := true; VarTrue) else if IntSet.mem (-l) bdgs then VarFalse else VarUndef), l)) l in
		if !fnd then None
		else Some (List.map (fun (_, l) -> l) (List.filter (fun (v, _) -> v = VarUndef) l))

	method private preprocess =
		if not !is_unsat then (
			let (unary, rest) = List.partition (fun l -> List.length l <= 1) !clauses in
			clauses := rest;
			if unary != [] then (
				let bdgs = ref IntSet.empty in
				List.iter (fun l -> match l with
					[x] -> if IntSet.mem (-x) !bdgs then is_unsat := true
					       else (
							bdgs := IntSet.add x !bdgs;
							self#add_binding x
						)
				|	_ -> is_unsat := true
				) unary;
				if not !is_unsat then (
					let tmp = ref [] in
					List.iter (fun l -> match (self#simplify_clause l !bdgs) with
						None -> ()
					|	Some [x] -> (
							tmp := [x]::!tmp;
							if IntSet.mem (-x) !bdgs then is_unsat := true
							else (
									bdgs := IntSet.add x !bdgs;
									self#add_binding x
								)
						)
					|	Some l -> tmp := l::!tmp
					) !clauses;
					clauses := !tmp;
					self#preprocess
				)
			);
		)

	method private prepare_solver solver =
		self#preprocess;
		if (not !is_unsat) && (!clauses != []) then (
			List.iter (fun c ->
				List.iter (fun l ->
					let l = if l > 0 then l else -l in
					if not (Hashtbl.mem vartrans l) then (
						let i = solver#add_variable in
						Hashtbl.add vartrans l i
					)
				) c;
				let c = List.map (fun l ->
					if l > 0 then Hashtbl.find vartrans l
						 else - (Hashtbl.find vartrans (-l))
				) c in
				solver#add_clause (Array.of_list c);
			) !clauses
		)

	method solve =
		self#prepare_solver solver;
		self#preprocess;
		if !is_unsat then SolveUnsatisfiable
		else if !clauses = [] then SolveSatisfiable
		else solver#solve

	method get_assignment v =
		if !is_unsat then failwith "unsat!"
		else match self#get_literal v with VarTrue -> true | VarFalse -> false
		     | VarUndef -> if !clauses = [] then false
				   else solver#get_assignment (Hashtbl.find vartrans v)

	method print_dimacs s =
		let pseudo = Pseudosatwrapper.get_pseudo_factory#new_instance in
		self#prepare_solver pseudo;
		pseudo#print_dimacs s;
		pseudo#dispose

end;;

*)

class preprocessorSolverFactory (factory: solverFactory) =
object inherit solverFactory

	method description = "PreprocessorSolver"
	method identifier = "preprocessorsat"
	method short_identifier = "pp"
	method copyright = "Copyright (c) University of Munich"
	method url = "http://www.tcs.ifi.lmu.de"

	method new_instance = new preprocessorSolver (factory#new_instance)
end;;
