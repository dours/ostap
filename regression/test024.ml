(*
 * Test014: testing basic combinators.
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

open Ostap
open Printf

let a = function "A" :: tl -> Parsed ("A", fail, tl) | _ -> Failed []
let b = function "B" :: tl -> Parsed ("B", fail, tl) | _ -> Failed []
let c = function "C" :: tl -> Parsed ("C", fail, tl) | _ -> Failed []
let d = function "D" :: tl -> Parsed ("D", fail, tl) | _ -> Failed []
    
let pl = List.fold_left (^) ""

let _ = 
  let parse = seq (opt (alc a (alc b c))) d in
  let print = function
    | Parsed ((x, y), _, s) -> 
	printf "Parsed: (%s, %s), rest: %s\n" 
	  (match x with None -> "None" | Some x -> "Some " ^ x) 
	  y
	  (pl s)

    | Failed _ -> 
	printf "Failed\n"
  in
  print (parse ["D"]);
  print (parse ["C"; "D"]);
  print (parse ["A"; "D"]);
  print (parse ["B"; "D"]);
