type token =
  | TResult
  | TValue
  | TSat
  | TUnsat
  | TString of (string)
  | TNumber of (int)
  | TEOL

open Parsing;;
# 1 "src/externalsat/satsolutionparser.mly"


let parse_error s =
  print_endline "Parse error";
  print_endline s;
  flush stdout;;

# 20 "src/externalsat/satsolutionparser.ml"
let yytransl_const = [|
  257 (* TResult *);
  258 (* TValue *);
  259 (* TSat *);
  260 (* TUnsat *);
  263 (* TEOL *);
    0|]

let yytransl_block = [|
  261 (* TString *);
  262 (* TNumber *);
    0|]

let yylhs = "\255\255\
\001\000\001\000\001\000\002\000\002\000\002\000\000\000"

let yylen = "\002\000\
\005\000\003\000\003\000\001\000\002\000\002\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\007\000\000\000\000\000\000\000\000\000\
\003\000\002\000\000\000\000\000\000\000\006\000\005\000\001\000"

let yydgoto = "\002\000\
\004\000\013\000"

let yysindex = "\002\000\
\007\255\000\000\002\255\000\000\008\255\004\255\005\255\254\254\
\000\000\000\000\254\254\254\254\006\255\000\000\000\000\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\009\255\000\000\000\000\000\000\000\000"

let yygindex = "\000\000\
\000\000\246\255"

let yytablesize = 16
let yytable = "\011\000\
\014\000\015\000\001\000\012\000\005\000\006\000\007\000\003\000\
\000\000\008\000\009\000\010\000\016\000\000\000\000\000\004\000"

let yycheck = "\002\001\
\011\000\012\000\001\000\006\001\003\001\004\001\005\001\001\001\
\255\255\002\001\007\001\007\001\007\001\255\255\255\255\007\001"

let yynames_const = "\
  TResult\000\
  TValue\000\
  TSat\000\
  TUnsat\000\
  TEOL\000\
  "

let yynames_block = "\
  TString\000\
  TNumber\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _4 = (Parsing.peek_val __caml_parser_env 1 : 'solution) in
    Obj.repr(
# 23 "src/externalsat/satsolutionparser.mly"
                                    (Satsolutionparserhelper.ParsedSat _4)
# 87 "src/externalsat/satsolutionparser.ml"
               : Satsolutionparserhelper.parsedSolution))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : string) in
    Obj.repr(
# 24 "src/externalsat/satsolutionparser.mly"
                       (Satsolutionparserhelper.ParsedError _2)
# 94 "src/externalsat/satsolutionparser.ml"
               : Satsolutionparserhelper.parsedSolution))
; (fun __caml_parser_env ->
    Obj.repr(
# 25 "src/externalsat/satsolutionparser.mly"
                      (Satsolutionparserhelper.ParsedUnsat)
# 100 "src/externalsat/satsolutionparser.ml"
               : Satsolutionparserhelper.parsedSolution))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 29 "src/externalsat/satsolutionparser.mly"
          ([_1])
# 107 "src/externalsat/satsolutionparser.ml"
               : 'solution))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'solution) in
    Obj.repr(
# 30 "src/externalsat/satsolutionparser.mly"
                   (_1::_2)
# 115 "src/externalsat/satsolutionparser.ml"
               : 'solution))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'solution) in
    Obj.repr(
# 31 "src/externalsat/satsolutionparser.mly"
                  (_2)
# 122 "src/externalsat/satsolutionparser.ml"
               : 'solution))
(* Entry program *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let program (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Satsolutionparserhelper.parsedSolution)
;;
