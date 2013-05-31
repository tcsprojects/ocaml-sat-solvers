type solve_result = SolveFailure of string | SolveUnsatisfiable | SolveSatisfiable

let format_solve_result = function
	SolveFailure s -> "SolveFailure: " ^ s
|	SolveUnsatisfiable -> "Unsatisfiable"
|	SolveSatisfiable -> "Satisfiable"

class virtual abstractSolver =
object
	method virtual dispose: unit
	method virtual add_variable: int
	method virtual add_clause: int array -> unit
	method virtual solve: solve_result
	method virtual solve_with_assumptions: int list -> solve_result
	method virtual get_assignment: int -> bool
	method incremental_reset = ()
	method virtual print_dimacs: out_channel -> unit
end

class virtual solverFactory =
object
	method virtual description: string
	method virtual identifier: string
	method virtual short_identifier: string
	method virtual copyright: string
	method virtual url: string
	method virtual new_instance: abstractSolver
end


type state = SolverInit | SolverSolved | SolverDisposed
type 'a literal = Po of 'a | Ne of 'a
type 'a formula = And of 'a formula array
                | Or of 'a formula array
                | Equiv of 'a formula * 'a formula
                | Not of 'a formula
                | Atom of 'a


class ['a] satWrapper (factory: solverFactory) =
let solver = factory#new_instance in
let state = ref SolverInit in
let variables = ref 0 in
let helper_variables = ref 0 in
let literals = ref 0 in
let helper_literals = ref 0 in
let clauses = ref 0 in
let helper_clauses = ref 0 in
let solve_result = ref SolveUnsatisfiable in
let hash = Hashtbl.create 10 in
object (self)
	method dispose =
		if !state = SolverDisposed
		then failwith "satWrapper.dispose: Already disposed."
		else (
			solver#dispose;
			state := SolverDisposed
		)

	method get_solver = solver

	method get_state = !state

	method get_solve_result =
		if !state = SolverSolved
		then !solve_result
		else failwith "satWrapper.get_solve_result: Either not solved or disposed."

	method incremental_reset =
		if !state = SolverSolved then (
			solver#incremental_reset;
			state := SolverInit
		)
		else failwith "satWrapper.incremental_reset: Wrong state"

	method solve =
		if !state = SolverInit
		then (
			state := SolverSolved;
			solve_result := solver#solve
		)
		else failwith "satWrapper.solve: Already solved or disposed."

	method solve_with_assumptions lits =
		if !state = SolverInit
		then (
			state := SolverSolved;
			solve_result := solver#solve_with_assumptions (List.map self#translate_literal lits)
		)
		else failwith "satWrapper.solve_with_assumptions: Already solved or disposed."

	method variable_count = !variables

	method helper_variable_count = !helper_variables

	method clause_count = !clauses

	method helper_clause_count = !helper_clauses

	method literal_count = !literals

	method helper_literal_count = !helper_literals

	method private assert_state (s: state) (funct: string) =
		if !state != s then failwith ("satWrapper." ^ funct ^ ": Wrong state.")

	method private get_var (v: 'a) =
		if Hashtbl.mem hash v
		then Hashtbl.find hash v
		else (
			let n = solver#add_variable in
			Hashtbl.add hash v n;
			variables := !variables + 1;
			n
		)

	method private translate_literal = function
		Po x -> self#get_var x
	|	Ne x -> - (self#get_var x)

	method add_clause_array a =
		self#assert_state SolverInit "add_clause";
		clauses := !clauses + 1;
		literals := !literals + (Array.length a);
		solver#add_clause (Array.map self#translate_literal a)

	method add_clause_list l =
		self#add_clause_array (Array.of_list l)

        method add_unit_clause c =
                self#add_clause_array [| c |]

	method mem_variable v = Hashtbl.mem hash v

	method get_variable v =
		self#assert_state SolverSolved "get_variable";
		if (!solve_result != SolveSatisfiable) then failwith ("satWrapper.get_variable: not in satisfiable state");
		if (Hashtbl.mem hash v) && (solver#get_assignment (Hashtbl.find hash v)) then 1 else 0

	method get_variable_bool v = self#get_variable v = 1

	method get_variable_first a =
		let n = Array.length a in
		let rec get_variable_helper i =
			if i >= n then -1
			else if self#get_variable_bool a.(i) then i
			else get_variable_helper (i + 1)
		in
			get_variable_helper 0

	method get_variable_count a =
		let c = ref 0 in
		for i = 0 to Array.length a - 1 do
			if self#get_variable_bool a.(i) then incr c
		done;
		!c


	method private create_helper_variable =
		let i = solver#add_variable in
		helper_variables := !helper_variables + 1;
		i

	method private create_helper_variables (n: int) =
		Array.init n (fun _ -> self#create_helper_variable)

	method private add_helper_clause_array (a: int array) =
		helper_clauses := !helper_clauses + 1;
		helper_literals := !helper_literals + (Array.length a);
		solver#add_clause a

	method add_helper_atleastone lo hi p f =
		self#assert_state SolverInit "add_clause";
		let p = Array.map (self#translate_literal) p in
		self#add_helper_clause_array (Array.append (Array.init (hi - lo + 1) (fun i -> self#translate_literal (f (i + lo)))) p)

	method private add_helper_lowereqone lo hi p f exact =
		self#assert_state SolverInit "add_helper_clause";
		let n = hi - lo + 1 in
		let helpers = self#create_helper_variables n in
		let p = Array.map self#translate_literal p in
		if exact then self#add_helper_clause_array [|helpers.(n - 1)|];
		let l = self#translate_literal (f lo) in
		self#add_helper_clause_array (Array.append [|l; -helpers.(0)|] p);
		self#add_helper_clause_array (Array.append [|-l; helpers.(0)|] p);
		for i = 1 to n - 1 do
			let h' = helpers.(i - 1) in
			let h = helpers.(i) in
			let l = self#translate_literal (f (lo + i)) in
			self#add_helper_clause_array (Array.append [|h'; l; -h|] p);
			self#add_helper_clause_array (Array.append [|-h'; l; h|] p);
			self#add_helper_clause_array (Array.append [|h'; -l; h|] p);
			self#add_helper_clause_array (Array.append [|-h'; -l|] p)
		done

	method add_helper_atmostone lo hi p f = self#add_helper_lowereqone lo hi p f false

	method add_helper_exactlyone lo hi p f = self#add_helper_lowereqone lo hi p f true

	method add_helper_conjunction lit conj =
		self#assert_state SolverInit "add_helper_clause";
		let n = Array.length conj in
		let lit = self#translate_literal lit in
		let conj = Array.map (self#translate_literal) conj in
		Array.iter (fun lit' ->	self#add_helper_clause_array [|-lit; lit'|]) conj;
		self#add_helper_clause_array (Array.init (n + 1) (fun i -> if i = n then lit else -conj.(i)))

	method add_helper_disjunction lit disj =
		self#assert_state SolverInit "add_helper_clause";
		let n = Array.length disj in
		let lit = self#translate_literal lit in
		let disj = Array.map (self#translate_literal) disj in
		Array.iter (fun lit' ->	self#add_helper_clause_array [|lit; -lit'|]) disj;
		self#add_helper_clause_array (Array.init (n + 1) (fun i -> if i = n then -lit else disj.(i)))

	method add_helper_equivalent l1 l2 =
		self#assert_state SolverInit "add_helper_clause";
		let l1 = self#translate_literal l1 in
		let l2 = self#translate_literal l2 in
		self#add_helper_clause_array [|-l1;l2|];
		self#add_helper_clause_array [|l1;-l2|]

	method add_helper_equivalent_to_counterequivalent x y z =
		self#assert_state SolverInit "add_helper_clause";
		let x = self#translate_literal x in
		let y = self#translate_literal y in
		let z = self#translate_literal z in
		self#add_helper_clause_array [|-y; z; x|];
		self#add_helper_clause_array [|-z; y; x|];
		self#add_helper_clause_array [|-y; -z; -x|];
		self#add_helper_clause_array [|y; z; -x|]

	method add_helper_atleastcount c lo hi p f =
		self#assert_state SolverInit "add_helper_clause";
		let n = hi - lo + 1 in
		let p = Array.map (self#translate_literal) p in
		let lits = Array.init (hi - lo + 1) (fun i -> self#translate_literal (f (i + lo))) in
		let helpers = Array.init c (fun _ -> self#create_helper_variables n) in
		for i = 0 to c - 1 do
			(* At least one helper variable is true *)
			self#add_helper_clause_array (helpers.(i));
			(* If a helper variable holds then lit holds too *)
			for j = 0 to n - 1 do
				self#add_helper_clause_array (Array.append p [|-helpers.(i).(j); lits.(j)|]);
			done
		done;
		for i = 0 to c - 2 do
			for j = i + 1 to c - 1 do
				for a = 0 to n - 1 do
					for b = 0 to a do
						self#add_helper_clause_array (Array.append p [|-helpers.(i).(a); -helpers.(j).(b)|])
					done
				done
			done
		done

	method add_helper_atmostcount c lo hi p f =
		self#assert_state SolverInit "add_helper_clause";
		let p = Array.map (self#translate_literal) p in
		let lits = Array.init (hi - lo + 1) (fun i -> self#translate_literal (f (i + lo))) in
		let rec work arr start idx =
			if idx > c
			then self#add_helper_clause_array arr
			else for i = start to hi - c + idx do
				work (Array.append [|-lits.(i)|] arr) (i + 1) (idx + 1)
			     done
		in
		work p lo 0

	method private add_helper_addition' x y z =
		let lenx = Array.length x in
		let leny = Array.length y in
		if lenx > leny then self#add_helper_addition' y x z else (
            let lenz = Array.length z in
            if lenz <= leny
            then failwith "add_helper_addition: target length to small!";
            let u = self#create_helper_variables leny in
            let p = self#create_helper_variables lenx in
            if lenx > 0 then (
				self#add_helper_clause_array [|-u.(0); y.(0)|];
				self#add_helper_clause_array [|-u.(0); x.(0)|];
				self#add_helper_clause_array [|u.(0); -x.(0); -y.(0)|];
				self#add_helper_clause_array [|x.(0); -y.(0); p.(0)|];
				self#add_helper_clause_array [|-x.(0); y.(0); p.(0)|];
				self#add_helper_clause_array [|-x.(0); -y.(0); -p.(0)|];
				self#add_helper_clause_array [|x.(0); y.(0); -p.(0)|];
				self#add_helper_clause_array [|-z.(0); p.(0)|];
				self#add_helper_clause_array [|-p.(0); z.(0)|]
            );
            for i = 1 to lenx - 1 do
				self#add_helper_clause_array [|x.(i); -y.(i); p.(i)|];
				self#add_helper_clause_array [|-x.(i); y.(i); p.(i)|];
				self#add_helper_clause_array [|-x.(i); -y.(i); -p.(i)|];
				self#add_helper_clause_array [|x.(i); y.(i); -p.(i)|];
				self#add_helper_clause_array [|u.(i-1); -p.(i); z.(i)|];
				self#add_helper_clause_array [|-u.(i-1); p.(i); z.(i)|];
				self#add_helper_clause_array [|-u.(i-1); -p.(i); -z.(i)|];
				self#add_helper_clause_array [|u.(i-1); p.(i); -z.(i)|];
				let xy = self#create_helper_variable in
				let up = self#create_helper_variable in
				self#add_helper_clause_array [|-xy; u.(i)|];
				self#add_helper_clause_array [|-up; u.(i)|];
				self#add_helper_clause_array [|up; xy; -u.(i)|];
				self#add_helper_clause_array [|-xy; x.(i)|];
				self#add_helper_clause_array [|-xy; y.(i)|];
				self#add_helper_clause_array [|xy; -x.(i); -y.(i)|];
				self#add_helper_clause_array [|-up; p.(i)|];
				self#add_helper_clause_array [|-up; u.(i-1)|];
				self#add_helper_clause_array [|up; -p.(i); -u.(i-1)|];
            done;
            if leny > lenx then (
                if lenx > 0 then (
                    self#add_helper_clause_array [|u.(lenx-1); -y.(lenx); z.(lenx)|];
                    self#add_helper_clause_array [|-u.(lenx-1); y.(lenx); z.(lenx)|];
                    self#add_helper_clause_array [|-u.(lenx-1); -y.(lenx); -z.(lenx)|];
                    self#add_helper_clause_array [|u.(lenx-1); y.(lenx); -z.(lenx)|];
                    self#add_helper_clause_array [|-u.(lenx); u.(lenx-1)|];
                    self#add_helper_clause_array [|-u.(lenx); y.(lenx)|];
                    self#add_helper_clause_array [|u.(lenx); -y.(lenx); -u.(lenx-1)|]
                )
                else (
                    self#add_helper_clause_array [|-z.(0); y.(0)|];
                    self#add_helper_clause_array [|z.(0); -y.(0)|];
                    self#add_helper_clause_array [|-u.(0)|]
                );
                for i = lenx + 1 to leny - 1 do
                    self#add_helper_clause_array [|u.(i-1); -y.(i); z.(i)|];
                    self#add_helper_clause_array [|-u.(i-1); y.(i); z.(i)|];
                    self#add_helper_clause_array [|-u.(i-1); -y.(i); -z.(i)|];
                    self#add_helper_clause_array [|u.(i-1); y.(i); -z.(i)|];
                    self#add_helper_clause_array [|-u.(i); u.(i-1)|];
                    self#add_helper_clause_array [|-u.(i); y.(i)|];
                    self#add_helper_clause_array [|u.(i); -y.(i); -u.(i-1)|]
                done
            );
    		if leny > 0 then (
	            self#add_helper_clause_array [|-z.(leny); u.(leny-1)|];
	            self#add_helper_clause_array [|z.(leny); -u.(leny-1)|]
    		)
    		else (
	            self#add_helper_clause_array [|-z.(leny)|]
    		);
            for i = leny + 1 to lenz - 1 do
	            self#add_helper_clause_array [|-z.(i)|]
            done
        )

	method add_helper_addition x y z =
		self#assert_state SolverInit "add_helper_clause";
		self#add_helper_addition' (Array.map (self#translate_literal) x) (Array.map (self#translate_literal) y) (Array.map (self#translate_literal) z)

	method private add_helper_multiplication' x y z =
		let lenx = Array.length x in
		let leny = Array.length y in
		if lenx > leny then self#add_helper_multiplication' y x z else (
			let lenz = Array.length z in
			if lenz < leny + lenx
			then failwith "add_helper_multiplication: target length to small!";
			let multmatrix = Array.init lenx (fun i -> self#create_helper_variables (lenx + i)) in
			for i = 0 to lenx - 1 do
				for j = 0 to i - 1 do
					self#add_helper_clause_array [|-multmatrix.(i).(j)|]
				done;
				for j = i to lenx + i - 1 do
					self#add_helper_clause_array [|y.(i); -multmatrix.(i).(j)|];
					self#add_helper_clause_array [|-y.(i); x.(j - i); -multmatrix.(i).(j)|];
					self#add_helper_clause_array [|-y.(i); -x.(j - i); multmatrix.(i).(j)|]
				done;
			done;
			let addmatrix = Array.init lenx (fun i -> self#create_helper_variables (lenx + i)) in
			for i = 0 to lenx - 1 do
				self#add_helper_clause_array [|-addmatrix.(0).(i)|]
			done;
			for i = 0 to lenx - 2 do
				self#add_helper_addition' multmatrix.(i) addmatrix.(i) addmatrix.(i + 1)
			done;
			self#add_helper_addition' multmatrix.(lenx-1) addmatrix.(lenx-1) z
        )

	method add_helper_multiplication x y z =
		self#assert_state SolverInit "add_helper_clause";
		self#add_helper_multiplication' (Array.map (self#translate_literal) x) (Array.map (self#translate_literal) y) (Array.map (self#translate_literal) z)

	method add_helper_not_equal_pairs l =
		self#assert_state SolverInit "add_helper_clause";
		let n = Array.length l in
		let u = self#create_helper_variables n in
		Array.iteri (fun i (l1, l2) ->
			let l1 = self#translate_literal l1 in
			let l2 = self#translate_literal l2 in
			let l3 = u.(i) in
			self#add_helper_clause_array [|-l1; l2; l3|];
			self#add_helper_clause_array [|l1; -l2; l3|];
			self#add_helper_clause_array [|-l1; -l2; -l3|];
			self#add_helper_clause_array [|l1; l2; -l3|]
		) l;
		self#add_helper_clause_array u

	method add_formula f =
		self#assert_state SolverInit "add_formula";
		let rec helper = function
			And f ->
				let vars = Array.map helper f in
				let l = self#create_helper_variable in
				Array.iter (fun v ->
					self#add_helper_clause_array [|-l; v|];
				) vars;
				self#add_helper_clause_array (Array.append (Array.map (fun v -> -v) vars) [|l|]);
				l
		|	Or f ->
				let vars = Array.map helper f in
				let l = self#create_helper_variable in
				Array.iter (fun v ->
					self#add_helper_clause_array [|l; -v|];
				) vars;
				self#add_helper_clause_array (Array.append vars [|-l|]);
				l
		|	Equiv (f1, f2) ->
				let (l1, l2) = (helper f1, helper f2) in
				let l = self#create_helper_variable in
				self#add_helper_clause_array [|l; -l1; -l2|];
				self#add_helper_clause_array [|l; l1; l2|];
				self#add_helper_clause_array [|-l; l1; -l2|];
				self#add_helper_clause_array [|-l; -l1; l2|];
				l
		|	Not f1 ->
				let l1 = helper f1 in
				-l1
		|	Atom l1 ->
				self#translate_literal (Po l1)
		in
			self#add_helper_clause_array [|helper f|]

end
