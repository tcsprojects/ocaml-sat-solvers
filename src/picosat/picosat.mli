type pico_sat_result = PicoUnknown | PicoSat | PicoUnsat

type pico_sat_solver

external pico_init: unit -> pico_sat_solver = "pico_init"

external pico_reset: pico_sat_solver -> unit = "pico_reset"

external pico_add: pico_sat_solver -> int -> unit = "pico_add"

external pico_assume: pico_sat_solver -> int -> unit = "pico_assume"

external pico_sat: pico_sat_solver -> int -> pico_sat_result = "pico_sat"

external pico_deref: pico_sat_solver -> int -> int = "pico_deref"
