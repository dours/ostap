(*
 * Pretty: basic set of pretty-printing combinators.
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

open Format

type printer = formatter -> unit

let toString p =
  let buf = Buffer.create 1024 in
  let ppf = formatter_of_buffer buf in
  p ppf;
  pp_print_flush ppf ();
  Buffer.contents buf

let empty   ppf = ()
let newline ppf = fprintf ppf "@\n"
let break   ppf = fprintf ppf "@,"
let box     ppf = fprintf ppf "@["
let vbox    ppf = fprintf ppf "@[<v 0>"
let hbox    ppf = fprintf ppf "@[<h 0>"
let hovbox  ppf = fprintf ppf "@[<hov 0>"
let hvbox   ppf = fprintf ppf "@[<hv 0>"
let endbox  ppf = fprintf ppf "@]"

let string str   = fun ppf -> fprintf ppf "%s" str
let int    int   = fun ppf -> fprintf ppf "%d" int
let char   char  = fun ppf -> fprintf ppf "%c" char
let bool   bool  = fun ppf -> fprintf ppf "%b" bool
let float  float = fun ppf -> fprintf ppf "%f" float

let seq  elems = fun ppf -> List .iter (fun e -> e ppf) elems
let seqa elems = fun ppf -> Array.iter (fun e -> e ppf) elems

let listBy delim list =
  fun ppf ->
    ignore 
      (
       List.fold_left 
	 (fun flag e -> 
	   if flag then delim ppf;
           e ppf;
	   true
	 ) 
	 false 
	 list
      )

let listBySemicolon : printer list -> printer = listBy (string "; ")
let listByComma     : printer list -> printer = listBy (string ", ")
let listBySpace     : printer list -> printer = listBy (string " " )

let listBySemicolonBreak : printer list -> printer = listBy (seq [string "; "; break])
let listByCommaBreak     : printer list -> printer = listBy (seq [string ", "; break])
let listBySpaceBreak     : printer list -> printer = listBy (seq [string " " ; break]) 
let listByBreak          : printer list -> printer = listBy break

let enclose box p = fun ppf -> seq [box; p; endbox] ppf

let boxed    = enclose box
let hboxed   = enclose hbox
let vboxed   = enclose vbox
let hovboxed = enclose hovbox
let hvboxed  = enclose hvbox

let brboxed l r p = hvboxed (seq [l; hovboxed p; break; r])
let prboxed l p   = hvboxed (seq [l; hovboxed p])

let rboxed = brboxed (string "(") (string ")")
let sboxed = brboxed (string "[") (string "]")
let cboxed = brboxed (string "{") (string "}")
