type pico_sat_result = PicoUnknown | PicoSat | PicoUnsat

external pico_init: unit -> unit = "pico_init"

external pico_reset: unit -> unit = "pico_reset"

external pico_add: int -> unit = "pico_add"

external pico_assume: int -> unit = "pico_assume"

external pico_sat: int -> pico_sat_result = "pico_sat"

external pico_deref: int -> int = "pico_deref"
