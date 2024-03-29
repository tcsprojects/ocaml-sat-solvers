open Satwrapper;;

class externalSolverFactory: string -> object inherit solverFactory
	method description: string
	method identifier: string
	method short_identifier: string
	method copyright: string
	method url: string
	method new_timed_instance: Timing.timetable -> abstractSolver
	method new_instance: abstractSolver
end
