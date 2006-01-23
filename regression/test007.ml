(*
 * Test007: testing basic combinators.
 * Copyright (C) 2006
 * Dmitri Boulytchev, St.Petersburg State University
 * 
 * This software is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License version 2, as published by the Free Software Foundation.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * See the GNU Library General Public License version 2 for more details
 * (enclosed in the file COPYING).
 *)

open Checked
open Ostap
open Printf

let a = function "A" :: tl -> Ok ("A", fail, tl) | _ -> Fail []
let b = function "B" :: tl -> Ok ("B", fail, tl) | _ -> Fail []
let c = function "C" :: tl -> Ok ("C", fail, tl) | _ -> Fail []
let d = function "D" :: tl -> Ok ("D", fail, tl) | _ -> Fail []
    
let pl = List.fold_left (^) ""

let _ = 
  let parse = map (fun (x, y) -> x) (seq (opt (seq a (opt (seq b (opt c))))) d) in
  let print = function
    | Ok (x, _, s) -> 
	printf "Parsed: (%s), rest: %s\n" 
	  (match x with
	  | None -> "None"
	  | Some (x, y) ->
	      sprintf 
		"Some %s, %s" x
		(match y with
		| None -> "None"
		| Some (b, c) -> 
		    sprintf 
		      "Some %s, %s" b
		      (match c with
		      | None -> "None"
		      | Some y -> sprintf "Some %s" y
		      )
		)
	  )
	  (pl s)

    | Fail _ -> 
	printf "Failed\n"
  in
  print (parse ["A"; "D"]);
  print (parse ["A"; "B"; "D"]);
  print (parse ["A"; "B"; "C"; "D"]);


