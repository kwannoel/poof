;; Appendix A: A Digression about type notation

;; We will use lowercase letters, such as a, f, x, to denote variables,
;; that may be bound any value in the language.
;; We will use uppercase letters, such as A, F, X, to denote *type variables*.
;; That is, variables representing a type, that is not currently specified,
;; but such that the formulas we write must hold for any type,
;; in a hypothetical type system that one could layer on top of the language.
;;
;; We will write a ... for a "row" of multiple values, such as may be used
;; as input arguments to a function, or return values of a function.
;; We will write A ... for a "row" of multiple types, such as may be used
;; to type the inputs or outputs of a function.
;; Indeed, in Scheme, a function may take multiple inputs arguments and
;; and return multiple output values.
;;
;; For instance, a row of types could be:
;;   Integer
;; for the single type of integers, or:
;;   String
;; for the single type of strings, or:
;;   Integer String
;; for the two types (in order) Integer and String, or:
;;   Integer Symbol ...
;; for the types of one integer followed by zero or many symbols.
;;
;; The type of functions that take inputs I ... and return outputs O ...
;; we will write as any one of the following:
;;   I ... -> O ...
;;   O ... <- I ...
;;   (I ... -> O ...)
;;   (O ... <- I ...)
;;   (Fun I ... -> O ...)
;;   (Fun O ... <- I ...)
;; As usual, the arrows are associative such that these denote the same type:
;;   A -> B -> C
;;   A -> (B -> C)
;;   C <- B <- A
;;   (C <- B) <- A

