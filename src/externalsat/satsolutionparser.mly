%{

let parse_error s =
  print_endline "Parse error";
  print_endline s;
  flush stdout;;

%}

%token TResult
%token TValue
%token TSat
%token TUnsat
%token <string> TString
%token <int> TNumber
%token TEOL

%type <Satsolutionparserhelper.parsedSolution> program
%start program

%%
program :
  TResult TSat TValue solution TEOL {Satsolutionparserhelper.ParsedSat $4}
| TResult TString TEOL {Satsolutionparserhelper.ParsedError $2}
| TResult TUnsat TEOL {Satsolutionparserhelper.ParsedUnsat}
;

solution :
  TNumber {[$1]}
| TNumber solution {$1::$2}
| TValue solution {$2}
;

%%