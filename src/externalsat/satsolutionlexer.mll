{
  open Satsolutionparser;;
  exception Eof
}

rule lexer = parse
    [' ' '\t' '\n' '\r'] {lexer lexbuf}
  | "c "[^'\n']* {lexer lexbuf}
  | "s " {TResult }
  | "v " {TValue }
  | "SATISFIABLE" {TSat }
  | "SAT" {TSat }
  | "UNSATISFIABLE" {TUnsat }
  | "UNSAT" {TUnsat }
  | ['0'-'9']+ {TNumber (int_of_string(Lexing.lexeme lexbuf))}
  | ['-']['0'-'9']+ {TNumber (int_of_string(Lexing.lexeme lexbuf))}
  | ['A'-'Z' 'a'-'z']['A'-'Z' 'a'-'z' '0'-'9']* {TString (Lexing.lexeme lexbuf)}
  | eof {TEOL}