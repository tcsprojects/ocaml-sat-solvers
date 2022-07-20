type timetable

exception UnknownTimingCategory

(* use this to obtain a new timetable with any counter set to 0 [msec] *)
val initial_timetable : unit -> timetable

(* can be used anywhere where there is no use for it *)
val dummy_timetable : timetable
  
(* `time table cat stm´ records the time [msec] needed to execute the statement stm
   under the category cat in the timetable table *)
val time : timetable -> string -> (unit -> unit) -> unit

(* `get_time table cat´ obtains the time stored in table under the category cat *)
val get_time : timetable -> string -> int
  
(* produces a string representation with all entries from the table displayed 
   in the form `category: time[msec]´, one per line *)
val report_times : timetable -> string
  

