(defmodule types
  (export all)
  (import (rename erl_scan ((string 1) erl_scan_string))
	  (rename erl_parse ((parse 1) erl_parse_tokens))))

(defun ast (s)
  (let* (((tuple '|ok| tokens _) (erl_scan_string s))
	 ((tuple '|ok| parsed) (erl_parse_tokens tokens)))
    parsed))

(defmacro to-type-fun (t)
  "This function was taking the type atom 'atom and smooshing it into
\"atom()\" but this doesn't play well with how I've structured the fold
so I've left it for now whilst I tried other things."
  `(: lists concat (list t '"()"))) ;; Until further notice

(defun get-fun-sig (ts)
  (let ((fargs (parse-type-structures (car ts)))
	(freturn (parse-type-structures (cadr ts))))
    (list '"fun(" fargs '") -> " freturn)))

(defmacro type-of arg
  "This is the function spec macro for building the definition of the
function into a erlang tuple data structure"
  (let ((fname (car arg)) 		;function name
	(ftype (cadr arg))		;function types
	(fdef (caddr arg)))		;function definition
    (tuple
     ;; Function Type Spec
     (tuple
      '"-spec " fname
      '"(" `,(parse-type-structures (car ftype)) '") -> "
      `,(parse-type-structures (cadr ftype)))
     ;; Actual function definition.
     `(defun ,(list_to_atom (atom_to_list fname))
	,@fdef))))

(defun parse-type (t defs)
  (cons
   (case t
     ;; Base case is a single atom for a renamed type
     (ts (when (is_atom ts)) (to-type-fun ts))
     
     ;; Second case is function type. Either way, handle this in
     ;; the function spec def function, so we're consistent like a
     ;; boss. Additionally it must be checked prior to handling
     ;; parameterised types.
     ((cons f def) (when (is_atom f) (=:= f 'fun) (is_list def))
      (get-fun-sig def)) ;; <--- this needs to be unquoted and
     ;; evaluated, since it's another macro... there must be a
     ;; better way to do this, and it probably doesn't involve
     ;; macros. :P
     
     ;; Final case is a parameterised type such as (list 'int) or
     ;; (tuple 'int)
     (ts (when (is_list ts)) (list '"(list " (parse-type-structures ts) '")"))
     (ts (when (is_tuple ts)) (list '"(tuple " (parse-type-structures (tuple_to_list ts)) '")")))
   defs))

(defun parse-type-structures (types)
  "Given a list of types, parse the list from our expected syntax to
an erlang data structure"
  (: lists foldl (lambda (t acc) (parse-type t acc)) '() types))

(defmacro deftype arg
  (let ((tname (car arg))
	(tdefn (cadr arg)))
    (ast (: lists concat
	   (tuple_to_list
	    (tuple '"-type " tname '"() :: " tdefn))))))

;; (defmacro deftype args
;;   "Create a module type definition."
;;   `(tuple 'type (tuple
;; 		 ;; Type name provided as an atom
;; 		 (to-type-fun (car (list ,@args)))
;; 		 ;; Expect everything else to be type definitions
;; 		 (parse-type-structures (cdr (list ,@args))))))