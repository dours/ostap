(*
 * Matcher: simple lexer pattern.
 * Copyright (C) 2006-2008
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

open Combinators
open String
open Printf
open Str
open Reason
	
module Token =
  struct

    type t = string * Msg.Coord.t

    let toString (t, c) = sprintf "%s at %s" t (Msg.Coord.toString c)

    let loc (t, c) = Msg.Locator.Interval (c, ((fst c), (snd c)+(length t)-1))
    let repr       = fst

  end

let shiftPos (line, col) s b n =
  let rec inner i (line, col) =
    if i = n 
    then (line, col)
    else
      match s.[i] with
      | '\n' -> inner (i+1) (line+1, 1)
      | _    -> inner (i+1) (line, col+1)
  in
  inner b (line, col)

let except str =
  let n = String.length str - 1 in
  let b = Buffer.create 64 in
  Buffer.add_string b "\(";
  for i=0 to n do	  
    Buffer.add_string b "\(";
    for j=0 to i-1 do
      Buffer.add_string b (quote (String.sub str j 1))
    done;
    Buffer.add_string b (sprintf "[^%s]\)" (quote (String.sub str i 1)));
    if i < n then Buffer.add_string b "\|"
  done;
  Buffer.add_string b "\)*";
  Buffer.contents b
    
let checkPrefix prefix s p =
  try
    for i=0 to (String.length prefix) - 1 
    do
      if prefix.[i] <> s.[p+i] then raise (Invalid_argument "")
    done;
    true
  with Invalid_argument _ -> false
      
module Skip =
  struct

    type t = string -> int -> [`Skipped of int | `Failed of string] 

    let comment start stop = 
      let pattern = regexp ((except start) ^ (quote stop)) in
      let l       = String.length start in
      (fun s p ->
	if checkPrefix start s p 
	then
	  if string_match pattern s (p+l) then `Skipped (p+(String.length (matched_string s))+l)
	  else `Failed (sprintf "unterminated comment ('%s' not detected)" stop)
	else `Skipped p
      )
    
    let nestedComment start stop =      
      let n = String.length start  in
      let m = String.length stop   in
      let d = regexp (sprintf "\\(%s\\)\\|\\(%s\\)" (quote start) (quote stop)) in
      (fun s p ->
	let rec inner p =
	  if checkPrefix start s p 
	  then
	    let rec jnner p c =
	      try
		let j       = search_forward d s p in
		let nest, l = (try ignore (matched_group 1 s); true, n with Not_found -> false, m) in
		let c       = if nest then c+1 else c-1 in
		if c = 0 
		then `Skipped (j+l)
		else jnner (j+l) c
	      with Not_found -> `Failed (sprintf "unterminated comment ('%s' not detected)" stop)
	    in
	    jnner (p+n) 1
	  else `Skipped p
	in
	inner p
      )
	
    let lineComment start =
      let e = regexp ".*$" in
      let n = String.length start in
      (fun s p ->
	if checkPrefix start s p 
	then
	  if string_match e s (p+n)
	  then `Skipped (p+n+(String.length (matched_string s)))
	  else `Skipped (String.length s)
	else `Skipped p
      )
	
    let whitespaces symbols =
      let e = regexp (sprintf "[%s]*" (quote symbols)) in
      (fun s p ->
	try 
	  if string_match e s p 
	  then `Skipped (p+(String.length (matched_string s)))
	  else `Skipped p  
	with Not_found -> `Skipped p
      )

    let rec create skippers = 
      let f =
	List.fold_left 
	  (fun acc g ->
	    (fun s p ->
	      match acc s p with
	      | `Skipped p -> g s p
	      | x -> x
	    )
	  )
	  (fun s p -> `Skipped p)
	  skippers
      in
      (fun s p coord ->
	let rec iterate s p =
	  match f s p with
	  | (`Skipped p') as x when p = p' -> x
	  | `Skipped p' -> iterate s p'
	  | x -> x
	in
	match iterate s p with
	| `Skipped p' -> `Skipped (p', shiftPos coord s p p')
	| `Failed msg -> `Failed (Msg.make msg [||] (Msg.Locator.Point coord))
      )	

  end

type aux = [`Skipped of int * Msg.Coord.t | `Failed of Msg.t | `Init]

let defaultSkipper = fun (p : int) (c : Msg.Coord.t) -> (`Skipped (p, c) :> [`Skipped of int * Msg.Coord.t | `Failed of Msg.t])

class t s =   
  object (self)
    val regexps = Hashtbl.create 256
    val p       = 0
    val coord   = (1, 1)
    val skipper = defaultSkipper
    val context : aux = `Init
  
    method skip = skipper
    method private changeSkip sk =
      let newContext =
      match context with
      | `Failed msg -> `Failed msg
      | `Init -> ((sk p coord) :> aux)
      | `Skipped (p, coord) -> ((sk p coord) :> aux)
      in {< skipper = sk; context = newContext >}

 
    method private parsed x y c = Parsed (((x, c), y), None)
    method private failed x c   = Failed (reason (Msg.make x [||] (Msg.Locator.Point c)))

    method pos   = p
    method coord = coord
    method line  = fst coord
    method col   = snd coord

    method private proceed f =
      match context with 
      | `Failed msg -> Failed (reason msg)
      | `Init ->
	  (match self#skip p coord with
	  | `Skipped (p, coord) -> f p coord
	  | `Failed msg -> Failed (reason msg)
	  )
      | `Skipped (p, coord) -> f p coord

    method prefix n =
      if p + n < String.length s 
      then String.sub s p n
      else String.sub s p (String.length s - p)

    method regexp name str = self#get name 
      (try Hashtbl.find regexps str with Not_found ->
         let regexp = Str.regexp str in
         Hashtbl.add regexps str regexp;
         regexp 
      )

    method get name regexp = self#proceed 
      (fun p coord ->
        if string_match regexp s p
        then 
          let m = matched_string s in
          let l = length m in
          let p = p + l in
          let c = shiftPos coord m 0 l in
          self#parsed m {< p = p;  coord = c; context = ((self#skip p c) :> aux) >} coord
        else self#failed (sprintf "\"%s\" expected" name) coord
      )

    method look str = self#proceed 
      (fun p coord ->
         try 
	   let l = String.length str in
	   let m = String.sub s p l in
	   let p = p + l in
	   let c = shiftPos coord m 0 (length m) in
	   if str = m 
	   then self#parsed m {< p = p; coord = c; context = ((self#skip p c) :> aux) >} coord
	   else self#failed (sprintf "\"%s\" expected" str) coord
         with Invalid_argument _ -> self#failed (sprintf "\"%s\" expected" str) coord
      )

   method getEOF = self#proceed 
     (fun p coord ->
	if p = length s 
	then self#parsed "<EOF>" {< p = p; coord = coord>} coord
	else self#failed "<EOF> expected" coord
     )

    method loc = Msg.Locator.Point coord

  end
    
