type token =
  | TResult
  | TValue
  | TSat
  | TUnsat
  | TString of (string)
  | TNumber of (int)
  | TEOL

val program :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Satsolutionparserhelper.parsedSolution
