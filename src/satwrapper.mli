type solve_result = SolveFailure of string | SolveUnsatisfiable | SolveSatisfiable

val format_solve_result: solve_result -> string

class virtual abstractSolver :
object
	method virtual dispose: unit
	method virtual add_variable: int
	method virtual add_clause: int array -> unit
	method virtual solve: solve_result
        method virtual solve_with_assumptions: int list -> solve_result
	method virtual get_assignment: int -> bool
	method incremental_reset: unit
	method virtual print_dimacs: out_channel -> unit
end

class virtual solverFactory :
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


class ['a] satWrapper : solverFactory ->
object
	method dispose: unit

	method get_solver: abstractSolver

	method get_state: state

	method get_solve_result: solve_result

	method incremental_reset: unit

	method solve: unit

	method solve_with_assumptions: ('a literal list) -> unit

	method variable_count: int

	method helper_variable_count: int

	method clause_count: int

	method helper_clause_count: int

	method literal_count: int

	method helper_literal_count: int

	method add_clause_array: ('a literal array) -> unit

	method add_clause_list: ('a literal list) -> unit

        method add_unit_clause: ('a literal) -> unit

	method mem_variable: 'a -> bool

	method get_variable: 'a -> int

	method get_variable_bool: 'a -> bool

	method get_variable_first: 'a array -> int

	method get_variable_count: 'a array -> int

	method add_helper_atleastone: int -> int -> 'a literal array -> (int -> 'a literal) -> unit

	method add_helper_atmostone: int -> int -> 'a literal array -> (int -> 'a literal) -> unit

	method add_helper_exactlyone: int -> int -> 'a literal array -> (int -> 'a literal) -> unit

	method add_helper_conjunction: 'a literal -> 'a literal array -> unit

	method add_helper_disjunction: 'a literal -> 'a literal array -> unit

	method add_helper_equivalent: 'a literal -> 'a literal -> unit

	method add_helper_equivalent_to_counterequivalent: 'a literal -> 'a literal -> 'a literal -> unit

	method add_helper_atleastcount: int -> int -> int -> 'a literal array -> (int -> 'a literal) -> unit

	method add_helper_atmostcount: int -> int -> int -> 'a literal array -> (int -> 'a literal) -> unit

	method add_helper_addition: 'a literal array -> 'a literal array -> 'a literal array -> unit

	method add_helper_multiplication: 'a literal array -> 'a literal array -> 'a literal array -> unit

	method add_helper_not_equal_pairs: ('a literal * 'a literal) array -> unit

	method add_formula: 'a formula -> unit
end
