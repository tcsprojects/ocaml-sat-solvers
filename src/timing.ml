module StringMap = Map.Make(String);;

exception UnknownTimingCategory
        
type timetable = int StringMap.t ref

let dummy_timetable = ref StringMap.empty
                    
let get_time table cat =
  match StringMap.find_opt cat !table with
    Some v -> v
  | None -> raise UnknownTimingCategory

let report_times table =
  let times = StringMap.bindings !table in
  let (lcat,ltim) = List.fold_left
                      (fun (i,j) -> fun (cat,t) ->
                                    (max i (String.length cat), max j (String.length (string_of_int t))))
                      (0,0)
                      times
  in
  String.concat "\n" (List.map (fun (cat,t) -> let st = string_of_int t in
                                               cat ^ (String.make (lcat-(String.length cat)) ' ') ^ ": " ^
                                                 (String.make (ltim-(String.length st)) ' ') ^ string_of_int t ^ " msec")
                        times)
                       
let initial_timetable _ = ref StringMap.empty
                           
let time table cat stm =
  let rec_time t =
    table := let oldval = match StringMap.find_opt cat !table with
                 Some v -> v
               | None -> 0
             in
             StringMap.add cat (t + oldval) !table
  in
  let start = Sys.time () in
  stm ();
  let exec = ((Sys.time ()) -. start) *. 1000. in
  rec_time (int_of_float exec)
