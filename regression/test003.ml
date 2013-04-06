open Ostap
open Regexp
open Printf

let _ =
  let module S = View.List (View.String) in
  let rest  s = sprintf "%s..." (Ostream.takeStr 10 s) in 
  let print names s = 
    Ostream.iter 
      (fun (s, b) -> 
         printf "  stream: %s;\n  args  : %s\n" 
           (rest s) 
           (S.toString (List.map (fun n -> sprintf "%s=[%s]" n (b n)) names))
      ) 
      s 
  in
  let letter = Test ("letter", fun c -> (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) in
  let noid   = Test ("noid"  , fun c -> (c < 'a' || c > 'z') && (c < 'A' || c > 'Z') && (c < '0' || c > '9')) in
  let digit  = Test ("digit" , fun c -> c >= '0' && c <= '9'                            ) in
  let nodig  = Test ("nodig" , fun c -> c < '0' || c > '9'                              ) in
  let ws     = Test ("ws"    , fun c -> c = ' '                                         ) in
  let nows   = Test ("nows"  , fun c -> c != ' '                                        ) in
  
  let quote   = Test ("quote"  , fun c -> c = '\'' || c = '"'                           ) in
  let noquote = Test ("noquote", fun c -> c != '\'' && c != '"'                         ) in

  let string          = Bind ("S", Juxt [Bind ("Q", quote); Aster noquote; Arg "Q"]) in
  let stringNotLetter = Juxt [string; Before letter]                                 in

  let m0 = matchAllStr string          in
  let m1 = matchAllStr stringNotLetter in

  (*  printf "%s" (Diagram.toDOT (Diagram.make string)); *)
  printf "Matching \"string\" against \"\"abc\" and the rest\"\n";
  print ["Q"; "S"] (m0 (Ostream.fromString "\"abc\" and the rest"));
  printf "Matching \"stringNotLetter\" against \"\"abc\" and the rest\":\n";
  print ["Q"; "S"] (m1 (Ostream.fromString "\"abc\" and the rest"));
  printf "Matching \"stringNotLetter\" against \"\"abc\"and the rest\":\n";
  print ["Q"; "S"] (m1 (Ostream.fromString "\"abc\"and the rest"))
;;