open Satwrapper;;

val register_solver: solverFactory -> unit

val mem_solver: string -> bool

val find_solver: string -> solverFactory

val enum_solvers: (solverFactory -> unit) -> unit

val fold_solvers: (solverFactory -> 'a -> 'a) -> 'a -> 'a

val get_list: unit -> solverFactory list

val get_default: unit -> solverFactory

val set_default: string -> unit