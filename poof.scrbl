#lang scribble/acmart @acmsmall @10pt @review @anonymous @natbib

@; To be submitted to OOPSLA 2021? https://2021.splashcon.org/track/splash-2021-oopsla

@(require scriblib/bibtex
          (only-in scribble/core make-paragraph make-style)
          (only-in scribble/manual racket racketblock code codeblock litchar itemize item)
          (only-in scribble/example examples make-base-eval)
          (only-in scriblib/footnote note)
          (only-in scribble-abbrevs appendix)
          (only-in scribble-math/dollar $)
@;          scribble/minted
          syntax/parse/define
          "util/examples-module.rkt"
          (for-label racket))

@;@(current-pygmentize-default-style 'colorful)
@(define (minted x . foo) (apply verbatim foo))

@(define (pretitle #:raw (raw #f) content)
  (make-paragraph
   (make-style 'pretitle (if raw '(exact-chars) '()))
   content))
@(pretitle @elem[#:style (make-style "setcopyright" '())]{none})
@;@(pretitle @elem[#:style (make-style "setcounter{tocdepth}" '())]{2})

@(define (~nocite . x) (let ((_ (apply @~cite x))) (void)))

@(declare-examples/module poof racket
   (provide (all-defined-out)))
@examples/module[poof #:hidden
(require (only-in racket/base [define def])
         srfi/1
         "util/eval-check.rkt")
@;{TODO:
Some lighter syntax than code:comment.
Get scribble/comment-reader to work?
Manual traversal of the syntax object?
}
]


@(define-simple-macro (r a ...) (racket a ...))
@(define-simple-macro (Definitions a ...) (examples/module poof #:no-result a ...))
@(define-simple-macro (Examples a ...) (examples #:eval poof #:no-result a ...))
@(define-simple-macro (Checks a ...) (examples #:eval poof #:label #f a ...))

@;{TODO: For Checks, instead of
> (+ 1 1)
2
rather have
(+ 1 1)
;=> 2
}

@(define (section1) @seclink["Prototypes_bottom_up"]{section 1})
@(define (section2) @seclink["pure_objective_fun"]{section 2})
@(define (section3) @seclink["beyond_objects"]{section 3})
@(define (section4) @seclink["Better_objects"]{section 4})
@(define (section5) @seclink["Classes"]{section 5})
@(define (section6) @seclink["Mutability"]{section 6})

@title{Prototype Object-Orientation Functionally}

@author[
  #:email (email "fare@mukn.io")
  #:affiliation (affiliation #:institution @institution{@emph{Mutual Knowledge Systems, Inc.}})
]{Francois-Rene Rideau}
@author[
  #:email (email "alexknauth@mukn.io")
  #:affiliation (affiliation #:institution @institution{@emph{Mutual Knowledge Systems, Inc.}})
]{Alex Knauth}
@author[
  #:email (email "namin@seas.harvard.edu")
  #:affiliation (affiliation #:institution @institution{@emph{Harvard University}})
]{Nada Amin}

@(define-bibtex-cite "poof.bib" ~cite citet generate-bibliography)

@abstract{

This paper elucidates the essence of Object-Oriented Programming (OOP), independent of idiosyncrasies of past incarnations.
We reconstruct OOP in a pure lazy functional style with dynamic or dependent types. We build protototype-based objects first, then class-based objects as a special case.
We illustrate our reconstruction in Scheme.

Using our approach, any language that contains the untyped lambda calculus can now implement an object system in handful of functions or roughly 20 lines of code. Multiple inheritance can be implemented in an additional 30 lines of code.
}

@section[#:tag "Prototypes_bottom_up"]{Prototypes, bottom up}

@subsection{The Essence of OOP}

@subsubsection{Object Orientation in 109 characters of standard Scheme}

@Definitions[
(define (fix p b) (define f (p (lambda i (apply f i)) b)) f)
(define (mix c p) (lambda (f b) (c f (p f b))))
]

We will make the case that the above two definitions summarize
the essence of Object-Oriented Programming (OOP), and that
all the usual OOP concepts can be easily recovered from them—all while
staying within the framework of pure Functional Programming (FP).

@subsubsection{Plan of this Essay}

In @(section1), we explain how the above functions
implement a minimal but recognizable model of OOP,
with open recursion and inheritance.
In @(section2), we illustrate this OOP model actually enables
incremental definition of complex data structures.
In @(section3), we show how prototypes are useful beyond traditional notions of objects,
and identify how they have a special place in computer science.
In @(section4), we examine how our model can be extended to support
more advanced features of OOP.
In @(section5), we demonstrate how classes are “just” prototypes for type descriptors.
Finally, in @(section6), we discuss our pure functional model relates
to models with mutable objects.
Along the way, we relate our approach to both OOP and FP traditions, both decades-old and recent,
and propose a path for further research (notably in @(section4)).

@subsubsection{Modular Increments of Computation}
OOP consists in specifying computations in modular increments
each contributing their part based on the combined whole and the computation so far.

We will realize these increments as @emph{prototypes}:
functions of two arguments, @r[self] and @r[super]
(or, above, @r[f] and @r[b], for fixed-point and base value).
Function @r[fix] @emph{instantiates} a prototype @r[p]
given a super/base value @r[b].
Function @r[mix] has @emph{child} prototype @r[c] @emph{inherit}
from @emph{parent} prototype @r[p]
so they operate on a same fixed-point @r[f]
while chaining their effects on @r[b].

Given some arbitrary instance type @r[Self],
and a super-type @r[Super] of @r[Self],
a prototype for @r[Self] from @r[Super] will thus be
a function from @r[Self] and @r[Super] to @r[Self].
@racketblock[
(code:comment "(deftype (Proto Self Super) (Fun Self Super -> Self st: (<: Self Super)))")
(code:comment "fix : (Fun (Proto Self Super) Super -> Self st: (<: Self Super))")
(code:comment "mix : (Fun (Proto Self Super) (Proto Super Sup2) -> (Proto Self Sup2)")
(code:comment "        st: (<: Self Super Sup2))")
]

The first argument @r[self] of type @r[Self] will hold the instance
resulting as a fixed point from the entire computation.
When composing multiple prototypes, every prototype will receive
the @emph{same} value as their @r[self] argument:
the complete instance that results from applying each prototype in order.
This allows prototypes to “cooperate” with each other
on @emph{different} aspects of the computation,
wherein one prototype defines some aspect (e.g. a “method” in some dictionary)
while relying on aspects to be defined by other prototypes (e.g. other methods),
accessed through the @r[self] argument in what is called “late binding”.

The second argument @r[super] by contrast holds the partial result of the
fixed-point computation after applying only the “next” prototypes.
When composing multiple prototypes, each prototype will (presumably) receive
a different value. The last prototype in the list (rightmost, most ancestral
parent) will receive the “base” or “bottom” value from the fix function
(often literally the bottom value or function in the language), then the
"previous" prototype (its child, to the left) will receive ("inherit")
the result of that “next” computation (its parent, to the right), and so on
until the first prototype (leftmost, most recent child) inherits
its @r[super] value from the rest and computes the final instance.
This allows prototypes to cooperate with other prototypes on a @emph{same} aspect
of the instance computation, wherein children prototypes can accumulate, modify
or override the method values inherited from the parent prototypes.

@subsubsection{Applicability to other Programming Languages}

The two definitions above can be easily translated to any language with closures
and either dynamic types or dependent types. However, their potential is not
fully realized in languages with mere parametric polymorphism.
@; TODO: insert above reference to type discussion?
Furthermore, for an @emph{efficient} implementation of objects with our formulas,
we will also require lazy evaluation (see @(section3)),
whether an ubiquitous language feature or an optional one
(possibly user-implemented with side-effects).
We do not otherwise require side-effects---though they can be used
for the usual optimizations in the common “linear” case (see @(section6)).

@subsection{A minimal object system}

@subsubsection{Records as functions}

Let us relate the above two functions to objects,
by first encoding “records” of multiple named values as functions
from symbol (the name of a slot) to value (bound to the slot).
In accordance with Lisp tradition,
we will say “slot” where others may say “field” or “member” or “method”,
and say that the slot is bound to the given value
rather than it “containing” the value or any such thing.

Thus function @r[x1-y2] below encodes a record with two slots
@r[x], @r[y] bound respectively to @r[1] and @r[2].

@Examples[
(code:comment "x1-y2 : (Fun 'x -> Nat | 'y -> Nat)")
(define (x1-y2 msg) (case msg ((x) 1)
                              ((y) 2)
                              (else (error "unbound slot" msg))))
]

We can check that we can indeed access the record slots
and get the expected values:

@Checks[
(eval:check (list (x1-y2 'x) (x1-y2 'y)) '(1 2))
]

Note that we use Scheme symbols for legibility.
Poorer languages could instead use any large enough type with decidable equality,
such as integers or strings.
Richer languages (e.g. Racket or Gerbil Scheme) could use resolved hygienic identifiers,
thereby avoiding accidental clashes.

@subsubsection{Prototypes for Records}

A @emph{prototype} for a record is a function of two record arguments @r[self],
@r[super] that returns a record extending @r[super].
To easily distinguish prototypes from instances and other values,
we will follow the convention of prefixing with @litchar{$} the names of prototypes.
Thus, the following prototype extends or overrides its super-record with
slot @r[x] bound to @r[3]:
@Examples[
(code:comment "$x3 : (Proto (Fun 'x -> Nat | A) A)")
(define ($x3 self super) (λ (msg) (if (eq? msg 'x) 3 (super msg))))
]

This prototype computes a complex number slot @r[z] based on real and
imaginary values bound to the respective slots @r[x] and @r[y] of its
@r[self]:
@Examples[
(code:comment "$z<-xy : (Proto (Fun (Or 'x 'y) -> Real | 'z -> Complex | A)")
(code:comment "                (Fun (Or 'x 'y) -> Real | A))")
(define ($z<-xy self super)
  (λ (msg) (case msg
             ((z) (+ (self 'x) (* 0+1i (self 'y))))
             (else (super msg)))))
]

That prototype doubles the number in slot @r[x] that it @emph{inherits} from its @r[super] record:
@Examples[
(code:comment "$double-x : (Proto (Fun 'x -> Number | A) (Fun 'x -> Number | A))")
(define ($double-x self super)
  (λ (msg) (if (eq? msg 'x) (* 2 (super 'x)) (super msg))))
]

More generally a record prototype extends its @r[super] record with new slots
and/or overrides the values bound to its existing slots, and may in the
process refer to both the records @r[self] and @r[super] and their slots,
with some obvious restrictions to avoid infinite loops from circular definitions.

@subsubsection{Basic testing} How to test these prototypes?
With the @r[fix] operator using the above record @r[x1-y2] as base value:

@Checks[
(code:comment "x3-y2 : (Fun 'x -> Nat | 'y -> Nat)")
(define x3-y2 (fix $x3 x1-y2))
(eval:check (list (x3-y2 'x) (x3-y2 'y)) '(3 2))

(code:comment "z1+2i : (Fun 'x -> Nat | 'y -> Nat | 'z -> Complex)")
(define z1+2i (fix $z<-xy x1-y2))
(eval:check (list (z1+2i 'x) (z1+2i 'y) (z1+2i 'z)) '(1 2 1+2i))

(code:comment "x2-y2 : (Fun 'x -> Nat | 'y -> Nat)")
(define x2-y2 (fix $double-x x1-y2))
(eval:check (list (x2-y2 'x) (x2-y2 'y)) '(2 2))
]

We can also @r[mix] these prototypes together before to compute the @r[fix]:
@Checks[
(code:comment "z6+2i : (Fun 'x -> Nat | 'y -> Nat | 'z -> Complex)")
(define z6+2i (fix (mix $z<-xy (mix $double-x $x3)) x1-y2))
(eval:check (map z6+2i '(x y z)) '(6 2 6+2i))
]

And since the @r[$z<-xy] prototype got the @r[x] and @r[y] values
from @r[self] and not @r[super], we can freely commute it with the other two prototypes
that do not affect either override slot @r[z] or inherit from it:
@Checks[
(eval:check (list ((fix (mix $z<-xy (mix $double-x $x3)) x1-y2) 'z)
                  ((fix (mix $double-x (mix $z<-xy $x3)) x1-y2) 'z)
                  ((fix (mix $double-x (mix $x3 $z<-xy)) x1-y2) 'z))
            '(6+2i 6+2i 6+2i))
]

@r[mix] is associative, and therefore the following forms are equivalent to the previous ones,
though the forms above (fold right) are slightly more efficient than the forms below (fold left):
@Checks[
(eval:check (list ((fix (mix (mix $z<-xy $double-x) $x3) x1-y2) 'z)
                  ((fix (mix (mix $double-x $z<-xy) $x3) x1-y2) 'z)
                  ((fix (mix (mix $double-x $x3) $z<-xy) x1-y2) 'z))
            '(6+2i 6+2i 6+2i))
]

Now, since @r[$double-x] inherits slot @r[x] that @r[$x3] overrides,
there is clearly a dependency between the two that prevents them from commuting:
@Checks[
(code:comment "x6-y2 : (Fun 'x -> Nat | 'y -> Nat)")
(define x6-y2 (fix (mix $double-x $x3) x1-y2))
(code:comment "x3-y2 : (Fun 'x -> Nat | 'y -> Nat)")
(define x3-y2 (fix (mix $x3 $double-x) x1-y2))
(eval:check (list (x6-y2 'x) (x3-y2 'x)) '(6 3))
]

@subsubsection{Record prototype generators}

Now that we understand record prototypes, we can look at various utility
functions to build them.

To define an object with a slot @r[k] mapped to a value @r[v], use:
@Definitions[
(code:comment "$slot : (Fun k:Symbol V -> (Proto (Fun 'k -> V | A) A))")
(define ($slot k v) (code:comment "k v: constant key and value for this defined slot")
  (λ (self super) (code:comment "self super: usual prototype variables")
    (λ (msg) (code:comment "msg: message received by the object, a.k.a. method name.")
      (if (equal? msg k) v (code:comment "if the message matches the key, return the value")
        (super msg))))) (code:comment "otherwise, recur to the object's super object")
]

What of inheritance? Well, we can modify an inherited slot using:
@Definitions[
(code:comment "$slot-modify : (Fun k:Symbol (Fun V -> W)")
(code:comment "  -> (Proto (Fun 'k -> W | A) (Fun 'k -> V | A) A) st: (<: V W))")
(define ($slot-modify k modify) (code:comment "modify: function from super-value to value")
  (λ (self super) (λ (msg)
    (if (equal? msg k) (modify (super msg))
      (super msg)))))
]

What if a slot depends on other slots? We can use this function
@Definitions[
(code:comment "$slot-compute : (Fun k:Symbol (Fun A -> V) -> (Proto (Fun 'k -> V | A) A))")
(define ($slot-compute k fun) (code:comment "fun: function from self to value.")
  (λ (self super)
    (λ (msg)
      (if (equal? msg k) (fun self)
        (super msg)))))
]

A general function to compute and override a slot would take as arguments both @r[self]
and a function to @r[inherit] the @r[super] slot value,
akin to @r[call-next-method] in CLOS@~cite{gabriel1991clos}.
@Definitions[
(code:comment "$slot-gen : (Fun k:Symbol (Fun A (Fun -> V) -> W)")
(code:comment "  -> (Proto (Fun 'k -> W | A) (Fun 'k -> V | A) A) st: (<: V W))")
(define ($slot-gen k fun) (code:comment "fun: from self and super-value thunk to value.")
  (λ (self super)
    (λ (msg)
      (define (inherit) (super msg))
      (if (equal? msg k) (fun self inherit) (inherit)))))
]

We could redefine the former ones in terms of that latter:
@Examples[
(define ($slot k v) ($slot-gen k (λ (__self __inherit) v)))
(define ($slot-modify k modify) ($slot-gen k (λ (__ inherit) (modify (inherit)))))
(define ($slot-compute k fun) ($slot-gen k (λ (self __) (fun self))))
]

Thus you can re-define the above prototypes as:
@Examples[
(define $x3 ($slot 'x 3))
(define $double-x ($slot-modify 'x (λ (x) (* 2 x))))
(define $z<-xy ($slot-compute 'z (λ (self) (+ (self 'x) (* 0+1i (self 'y))))))
]

Here is a universal bottom function to use as the base for fix:
@Definitions[
(code:comment "bottom-record : (Fun Symbol -> _)")
(define (bottom-record msg) (error "unbound slot" msg))
]

To define a record with a single slot @r[foo] bound to @r[0], we can use:
@Checks[
(code:comment "x3 : (Fun 'x -> Nat)")
(define x3 (fix $x3 bottom-record))
(eval:check (x3 'x) 3)
]

To define a record with two slots @r[x] and @r[y] bound to @r[1]
and @r[2] respectively, we can use:
@Checks[
(code:comment "x1-y2 : (Fun 'x -> Nat | 'y -> Nat)")
(define x1-y2 (fix (mix ($slot 'x 1) ($slot 'y 2)) bottom-record))
(eval:check (map x1-y2 '(x y)) '(1 2))
]

@subsubsection{Back to 1981!}

Interestingly, the above approach to objects is essentially equivalent,
though not exactly isomorphic, to what Yale T had in 1981@~cite{Adams89object-orientedprogramming}.
T was notably reprised by YASOS in 1992@~cite{dickey1992scheming}
and distributed with SLIB since.
There are minor differences: what we call “instance”, T calls “object” or “instance”,
but instead of “prototypes” it has “components” with a slightly different API.
Also T assumes methods are all function-valued, to be immediately called
when methods are looked up, as if all accesses to an object went through the @r[operate] function below.
Methods in T can be directly represented as slots with a function value in our approach.
Non-function-valued slots in our approach above can be represented in T
by nullary methods returning a constant value.
@Definitions[
(define (operate instance selector . args) (apply (instance selector) args))
]

@subsection{Prototype Basics}

@subsubsection{Long-form Basics}

Let's rewrite @r[fix] and @r[mix] in long-form
with variables @r[self] and @r[super] instead of @r[f] and @r[b], etc.
Thus, the instantiation function @r[(fix p b)] becomes:
@Definitions[
(code:comment "instantiate-prototype : (Fun (Proto Self Super) Super -> Self)")
(define (instantiate-prototype prototype base-super)
  (define self (prototype (λ i (apply self i)) base-super))
  self)
]

A more thorough explanation of the above fixed-point function is in @seclink["Appendix_B"]{Appendix B}.
Meanwhile, the composition function @r[(mix p q)] becomes:
@Definitions[
(code:comment "compose-prototypes : (Fun (Proto Self Super) (Proto Super Super2)")
(code:comment "  -> (Proto Self Super2) st: (<: Self Super Super2))")
(define (compose-prototypes child parent)
  (λ (self super2) (child self (parent self super2))))
]

Note the types of the variables and intermediate expressions:
@tabular[
(list (list
@racketblock[
child : (Proto Self Super)
self : Self
(child self (parent self super2)) : Self]
@racketblock[
parent : (Proto Super Super2)
super2 : Super2
(parent self super2) : Super]))]

When writing long-form functions, instead of vying for conciseness, we will
use the same naming conventions as in the function above:
@itemize[
 @item{@r[child] (or @r[this]) for a @emph{prototype} at hand, in leftmost position;}
 @item{@r[parent] for a @emph{prototype} that is being mixed with, in latter position;}
 @item{@r[self] for the @emph{instance} that is a fixed point of the computation;}
 @item{@r[super] for the base (or so-far accumulated) @emph{instance} of the computation.}
]

Note the important distinction between @emph{prototypes} and @emph{instances}.
Instances are the non-composable complete outputs of instantiation,
whereas prototypes are the composable partial inputs of instantiation.
Prototypes, increments of computation, are functions from an instance (of a
subtype @r[Self]) and another instance (of a supertype @r[Super])
to yet another instance of the subtype @r[Self].

@subsubsection{Composing prototypes}

The identity prototype as follows is neutral element for mix.
It doesn't override any information from the super/base object,
but only passes it through. It also doesn't consult information in
the final fixed-point nor refers to it.
@Definitions[
(code:comment "identity-prototype : (Proto Instance Instance)")
(define (identity-prototype self super) super)
]

Now, prototypes are interesting because @r[compose-prototypes] (a.k.a. @r[mix])
is an associative operator with neutral element @r[identity-prototype].
Thus prototypes form a monoid, and you can compose
or instantiate a list of prototypes:
@Definitions[
(code:comment "compose-prototype-list : (Fun (IndexedList I (λ (i)")
(code:comment "  (Proto (A_ i) (A_ (1+ i))))) -> (Proto (A_ 0) (A_ (Card I))))")
(define (compose-prototype-list l)
  (cond
   ((null? l) identity-prototype)
   ((null? (cdr l)) (car l))
   ((null? (cddr l)) (compose-prototypes (car l) (cadr l)))
   (else (compose-prototypes (car l) (compose-prototype-list (cdr l))))))
]
@; TODO: if we need space, delete the above or move it to an appendix.

A more succint way to write the same function is:
@Examples[
(define (compose-prototype-list prototype-list)
  (foldr compose-prototypes identity-prototype prototype-list))
]

@Definitions[
(code:comment "instantiate-prototype-list : (Fun (IndexedList I (λ (i)")
(code:comment "  (Proto (A_ i) (A_ (1+ i))))) (A_ (Card I)) -> (A_ 0))")
(define (instantiate-prototype-list prototype-list base-super)
  (instantiate-prototype (compose-prototype-list prototype-list) base-super))
]

Prototype composition is notably more expressive than “single inheritance”
as commonly used in many “simple” object systems:
Object systems with “single inheritance” require programmers to @r[cons]
objects (or classes) one component at a time in the front of a rigid list of
"parent" objects (or classes), where the base object (or class) is set.
Prototype object systems enable programmers to @r[append] lists of prototypes
independently from any base object, to compose and recompose prototypes
in different orders and combinations.
Prototypes are thus more akin to the “mixins” or “traits” of more advanced
objects systems@~cite{Cannon82 bracha1990mixin Flatt06schemewith}.
@; TODO: cite Flavors for mixins? Some PLT paper? The one from asplas06? What about traits?
Prototype composition however, does not by itself subsume multiple
inheritance. We will show in @(section4) how to combine the two.

@subsubsection{The Bottom of it}

In a language with partial functions, such as Scheme, there is a practical
choice for a universal base super instance to pass to
@r[instantiate-prototype]: the @r[bottom] function, that never returns,
but instead, for enhanced usability, may throw a helpful error.
@Definitions[
(code:comment "bottom : (Fun I ... -> O ...)")
(define (bottom . args) (error "bottom" args))
]

Thus, in dialects with optional arguments, we could make @r[bottom] the default
value for @r[base-super]. Furthermore, in any variant of Scheme, we can define
the following function @r[instance] that takes the rest of its arguments as
a list of prototypes, and instantiates the composition of them:
@Definitions[
(code:comment "instance : (Fun (IndexedList I (λ (i) (Proto (A_ i) (A_ (1+ i)))))...")
(code:comment "  -> (A_ 0)))")
(define (instance . prototype-list)
  (instantiate-prototype-list prototype-list bottom))
]

What if you @emph{really} wanted to instantiate your list of prototypes with some
value @r[b] as the base super instance? “Just” tuck
@r[(constant-prototype b)] at the tail end of your prototype list:
@Definitions[
(code:comment "constant-prototype : (Fun A -> (Proto A _))")
(define (constant-prototype base-super) (λ (__self __super) base-super))
]

Or the same with a shorter name and a familiar definition as a combinator
@Definitions[
(code:comment "$const : (Fun A -> (Proto A _))")
(define ($const b) (λ _ b))
]

Small puzzle for the points-free Haskellers reading this essay:
what change of representation will enable prototypes to be composed like regular functions
without having to apply a binary function like @r[mix]? Solution in footnote.@note{
A general purpose trick to embed an arbitrary monoid into usual composable functions is
to curry the composition function (here, @r[mix]) with the object to be composed.
Thus, the functional embedding of prototype @r[p] will be
@r[(λ (q) (mix p q)) : (Fun (Proto Super S2) -> (Proto Self S2))].
To recover @r[p] from that embedding, just apply it to @r[identity-prototype].
}

@section[#:tag "pure_objective_fun"]{Pure Objective Fun}

@subsection{Using prototypes to incrementally define simple data structures}

@subsubsection{Prototypes for Order}

Let's use prototypes to build some simple data structures.
First, we'll write prototypes that offer an abstraction for the ability
to compare elements of a same type at hand, in this case,
either numbers or strings.
@Definitions[
(define ($number-order self super)
  (λ (msg) (case msg
             ((<) (λ (x y) (< x y)))
             ((=) (λ (x y) (= x y)))
             ((>) (λ (x y) (> x y)))
             (else (super msg)))))
(define ($string-order self super)
  (λ (msg) (case msg
             ((<) (λ (x y) (string<? x y)))
             ((=) (λ (x y) (string=? x y)))
             ((>) (λ (x y) (string>? x y)))
             (else (super msg)))))
]

We can add a “mixin” for a @r[compare] operator that summarizes in one call
the result of comparing two elements of the type being described.
A mixin is a prototype meant to extend other prototypes.
See how this mixin can be used to extend either of the prototypes above.
Also notice how, to refer to other slots in the eventual instance,
we call @r[(self '<)] and suches.
@Definitions[
(define ($compare<-order self super)
  (λ (msg) (case msg
             ((compare) (λ (x y)
                          (cond (((self '<) x y) '<)
                                (((self '>) x y) '>)
                                (((self '=) x y) '=)
                                (else (error "incomparable" x y)))))
             (else (super msg)))))
(define number-order (instance $number-order $compare<-order))
(define string-order (instance $string-order $compare<-order))]
@Checks[
(eval:check ((number-order '<) 23 42) #t)
(eval:check ((number-order 'compare) 8 4) '>)
(eval:check ((string-order '<) "Hello" "World") #t)
(eval:check ((string-order 'compare) "Foo" "FOO") '>)
(eval:check ((string-order 'compare) "42" "42") '=)
]

We can define a order on symbols by delegating to strings!
@Definitions[
(define ($symbol-order self super)
  (λ (msg) (case msg
             ((< = > compare)
              (λ (x y) ((string-order msg) (symbol->string x) (symbol->string y))))
             (else (super msg)))))
(define symbol-order (instance $symbol-order))]
@Checks[
(eval:check ((symbol-order '<) 'aardvark 'aaron) #t)
(eval:check ((symbol-order '=) 'zzz 'zzz) #t)
(eval:check ((symbol-order '>) 'aa 'a) #t)
(eval:check ((symbol-order 'compare) 'alice 'bob) '<)
(eval:check ((symbol-order 'compare) 'b 'c) '<)
(eval:check ((symbol-order 'compare) 'a 'c) '<)]

@subsubsection{Prototypes for Binary Trees}

We can use the above @r[order] prototypes to build binary trees
over a suitable ordered key type @r[Key].
We'll represent a tree as a list of left-branch,
list of key-value pair and ancillary data, and right-branch,
which preserves the order of keys when printed:
@Definitions[
(define ($binary-tree-map self super)
  (λ (msg)
    (define (node l kv r) ((self 'node) l kv r))
    (case msg
      ((empty) '())
      ((empty?) null?)
      ((node) (λ (l kv r) (list l (list kv) r)))
      ((singleton) (λ (k v) (node '() (cons k v) '())))
      ((acons)
       (λ (k v t)
         (if ((self 'empty?) t) ((self 'singleton) k v)
             (let* ((tl (car t)) (tkv (caadr t)) (tk (car tkv)) (tr (caddr t)))
               (case (((self 'Key) 'compare) k tk)
                 ((=) (node tl (cons k v) tr))
                 ((<) (node ((self 'acons) k v tl) tkv tr))
                 ((>) (node tl tkv ((self 'acons) k v tr))))))))
      ((ref)
       (λ (t k e)
         (if ((self 'empty?) t) (e)
             (let ((tl (car t)) (tk (caaadr t)) (tv (cdaadr t)) (tr (caddr t)))
               (case (((self 'Key) 'compare) k tk)
                 ((=) tv)
                 ((<) ((self 'ref) tl k e))
                 ((>) ((self 'ref) tr k e)))))))
      ((afoldr)
       (λ (acons empty t)
         (if ((self 'empty?) t) empty
           (let ((tl (car t)) (tk (caaadr t)) (tv (cdaadr t)) (tr (caddr t)))
             ((self 'afoldr)
              acons (acons tk tv ((self 'afoldr) acons empty tl)) tr)))))
      (else (super msg)))))]

With this scaffolding, we can define a dictionary data structure
that we can use later to differently represent objects:
@Definitions[
(define symbol-tree-map (instance ($slot 'Key symbol-order) $binary-tree-map))
]
However, when we use it, we immediately find an issue:
trees will too often be skewed, leading to long access times,
especially so when building them from an already ordered list:
@Checks[
(define my-binary-dict (code:comment "heavily skewed right, height 5")
  (foldl (λ (kv t) ((symbol-tree-map 'acons) (car kv) (cdr kv) t))
         (symbol-tree-map 'empty)
         '((a . "I") (b . "II") (c . "III") (d . "IV") (e . "V"))))
(eval:check my-binary-dict '(() ((a . "I")) (() ((b . "II")) (() ((c . "III")) (() ((d . "IV")) (() ((e . "V")) ()))))))]

But binary trees otherwise work:
@Checks[
(eval:check (map (λ (k) ((symbol-tree-map 'ref) my-binary-dict k (λ () #f))) '(a b c d e z))
            '("I" "II" "III" "IV" "V" #f))]

@subsubsection{Prototypes for @emph{Balanced} Binary Trees}

We can incrementally define a balanced tree data structure
(in this case, using the AVL balancing algorithm)
by overriding a single method of the original binary tree prototype:
@Definitions[
(define ($avl-tree-rebalance self super)
  (λ (msg)
    (define (left t) (car t))
    (define (kv t) (caadr t))
    (define (height t) (if (null? t) 0 (cdadr t)))
    (define (right t) (caddr t))
    (define (balance t) (if (null? t) 0 (- (height (right t)) (height (left t)))))
    (define (mk l kv r)
      (let ((lh (height l)) (rh (height r)))
        (or (member (- rh lh) '(-1 0 1)) (error "tree unbalanced!"))
        (list l (cons kv (+ 1 (max lh rh))) r)))
    (define (node l ckv r)
      (case (- (height r) (height l))
        ((-1 0 1) (mk l ckv r))
        ((-2) (case (balance l)
                ((-1 0) (mk (left l) (kv l) (mk (right l) ckv r))) ;; LL rebalance
                ((1) (mk (mk (left l) (kv l) (left (right l))) ;; LR rebalance
                         (kv (right l)) (mk (right (right l)) ckv r)))))
        ((2) (case (balance r)
               ((-1) (mk (mk l ckv (left (left r))) ;; RL rebalance
                         (kv (left r)) (mk (right (left r)) (kv r) (right r))))
               ((0 1) (mk (mk l ckv (left r)) (kv r) (right r))))))) ;; RR rebalance
    (case msg ((node) node) (else (super msg)))))
(define Dict
  (instance $avl-tree-rebalance $binary-tree-map ($slot 'Key symbol-order)))]

Our dictionary is now well-balanced, height 3, and the tests still pass:
@Checks[
(define my-avl-dict
  (foldl (λ (kv t) ((Dict 'acons) (car kv) (cdr kv) t))
         (Dict 'empty)
         '((a . "I") (b . "II") (c . "III") (d . "IV") (e . "V"))))
(eval:check my-avl-dict
                '((() ((a . "I") . 1) ()) ((b . "II") . 3)
                  ((() ((c . "III") . 1) ()) ((d . "IV") . 2) (() ((e . "V") . 1) ()))))
(eval:check (map (λ (k) ((Dict 'ref) my-avl-dict k (λ () #f))) '(a b c d e z))
            '("I" "II" "III" "IV" "V" #f))
]

@section[#:tag "beyond_objects"]{Beyond Objects and back}

Prototypes are not just for records as functions from symbol to value:
they can be used to incrementally specify any kind of functions!

@subsection{Prototypes for Numeric Functions}

Let's see how prototypes can be used to build functions from real numbers to real numbers.
The following prototype is a mixin for an even function,
that delegates to other prototypes the images of positive values
and returns the image of the opposite for negative values:
@Examples[
(define ($even self super)
  (λ (x) (if (< x 0) (self (- x)) (super x))))
]
The following prototype is a mixin for taking the cube of the parent value:
@Examples[
(define ($cube self super)
  (λ (x) (let ((y (super x))) (* y y y))))
]
We can instantiate a function out of those of prototypes, and test it:
@Checks[
(define absx3 (instance $even $cube ($const (λ (x) x))))
(eval:check (map absx3 '(3 -2 0 -1)) '(27 8 0 1))
]

@subsubsection{Number Thunks}

Now, the simplest numeric functions are thunks: nullary functions that yield a number.
@Checks[
(define (p1+ __ b) (λ () (+ 1 (b))))
(define (p2* __ b) (λ () (* 2 (b))))
(eval:check (list ((fix (mix p1+ p2*) (λ () 30)))
                  ((fix (mix p2* p1+) (λ () 30))))
            '(61 62))
]

@subsection[#:tag "computations_not_values"]{Prototypes are for Computations not Values}

Prototypes for number thunks can be generalized to prototypes for any kind of thunks:
you may incrementally specify instances of arbitrary types using prototypes,
by first wrapping values of that type into a thunk.
An alternative to thunks would be to use Scheme's @r[delay] special form,
or whatever form of @emph{lazy evaluation} is available in the language at hand.

To reprise the Call-By-Push-Value paradigm@~cite{conf/tlca/Levy99},
prototypes incrementally specify @emph{computations} rather than @emph{values}.
In applicative languages we can reify these computations as values
either as functions (as in @(section1)), or as delayed values as follows:

@Definitions[
(code:comment "(deftype (δProto Self Super) (Fun (Delayed Self) (Delayed Super) -> Self))")
(code:comment "δfix : (Fun (δProto Self Super) (Delayed Super) -> (Delayed Self))")
(define (δfix p b) (define f (delay (p f b))) f)
(code:comment "δmix : (Fun (δProto Self Mid) (δProto Mid Super) -> (δProto Self Super))")
(define (δmix c p) (λ (f b) (c f (delay (p f b)))))
(code:comment "δ$id : (δProto X X)")
(define (δ$id f b) (λ (__self super) (force super)))
]

Now, most interesting prototypes will only lead to error or divergence if you try
to instantiate them by themselves---they are “mixins”,
just like @r[$compare<-order] or @r[$avl-tree-rebalance] above,
designed to be combined with other prototypes.
Indeed, the whole entire point of incrementally specifying computations is
that you want to manipulate fragments that are not complete specifications.
To use these fragments in a total language where all computations terminates
will require attaching to each prototype some side-condition as to
which aspects of a computation it provides that other prototypes may rely on,
and which aspects of a computation it requires that other prototypes must provide.
This side-condition may well be a type in one of the many existing type systems
for objects@~cite{Abadi97atheory tapl}.

@subsection{Prototypes in Lazy Pure Functional Dynamic Languages}

@subsubsection{Prototypes in Nix}
Interestingly, prototypes for lazy mappings from keys to values
is exactly how objects are encoded in
the pure lazy functional dynamically typed language Nix@~cite{dolstra2008nixos}.

Since 2015, the Nix standard library contains variants of the @r[fix] et @r[mix] functions,
wherein “attribute sets” or attrsets, mapping from strings to values,
are defined as fixed-points of functions obtained from a “base” function
and a list of composable “extensions”.
These “extensions” are functions from attribute sets @r[self] and @r[super] to
an attribute set that is meant to extend and override @r[super]
as incremental contribution to the computation of the @r[self] fixed-point.
This is a reasonable restriction on how prototypes may affect super values,
that totally matches usual object-oriented practice, and suggests where
an extension point could be in a general meta-object protocol@~cite{amop}.
The “base” function is a function from attrset @r[self] to attrset;
this makes the API slightly less uniform than ours and introduces an extra type,
but is otherwise isomorphic to our approach of using @r[bottom] as an base @r[super] argument
that gets ignored by the last prototype in the list to be instantiated.

Apart from the minor details above,
this is the very same design as the one we are presenting,
even though Nix's extension system was not even consciously meant
as an object system when it was designed.
This is not a coincidence, since the present essay emerged from
an effort to formalize the essence of objects as understood from Nix and Jsonnet.
We also simplify their approach (e.g. with respect to the base case of open-recursion)
and generalize it to arbitrary instance types (i.e. not just attrsets);
and in the following @(section4)
we further improve on it.

@subsubsection{Prototypes in Jsonnet}
Now, Jsonnet@~cite{jsonnet}, another lazy pure functional dynamic language,
sports an object system that is semantically equivalent to that of Nix,
published one year before Nix's extension system was invented.
Jsonnet itself was invented as a simplified semantic reconstruction of the essential ideas
behind GCL, the decade-older Google Configuration Language used everywhere inside the company.
GCL also wasn't explicitly designed as an object system, yet ended up having discovered
an excellent point in the design space, despite the overall clunkiness of the language.

A notable difference between Nix and Jsonnet is that
Jsonnet supports objects as builtins with a nice syntax, when
in Nix they are implemented as a handful library functions in under 20 lines of code.
Also, Jsonnet uses the empty object as the implicit base super object for inheritance;
this is equivalent to the bottom function in the representation from our
@seclink["Prototypes_bottom_up"]{section 1}—but not in theirs!
Unlike the representation from our @(section1),
Jsonnet's representation (as Nix's) also allows for introspection of what slots are bound.
Finally, Jsonnet has builtin support for fields being either visible or hidden when printing.

The fact that, across several decades, closely matching designs were independently reinvented many times
without the intention to do so, is a good sign that this design is a “fixed point in design space”,
akin to the notion of “fixed point in time” in Dr Who@~cite{DrWhoFPIT}:
however you may try to reach a different conclusion, you still end-up with that fixed-point eventually.

@subsubsection{A Pure Lazy Fit}
Still, there are ways in which Jsonnet and Nix improved upon
the prototype object systems as initially designed in ThingLab@~cite{Borning77 Borning86}
or T@~cite{Rees82t:a Adams89object-orientedprogramming},
or later made popular by SELF@~cite{chambers1989efficient} or JavaScript @; TODO: cite for JS
As in these previous inventions, Jsonnet and Nix use first-class functions to construct objects.
They also rely on dynamic types to avoid the need for dependent types and internal type theories
required to statically type first-class prototypes in the most general case.
But unlike previous incarnations, they also rely on lazy evaluation as a way to express
first-class computations that can be manipulated whether or not they terminate,
without a clumsy explicit wrapping in a thunk or a lazy constructor.
They also do without having to resort to side-effects;
the pure functional semantics are thus not only especially clean and simple,
fitting in a few hundreds of characters,
but reveal an underlying mathematical structure of universal interest.

The success of Jsonnet and Nix at modularly managing complex configurations
through object extensions suggest that pure lazy functional programming is useful
way beyond the popular package offered by Haskell, of this programming model
with ML-like static typesystem that sports parametric polymorphism but no dependent types.
That typesystem rejects most interesting uses of prototypes,
thereby neglecting an important application domain for pure lazy functional programming.
Thus, though some claim the ML typesystem is at a "sweet spot",
wherein it provides good expressiveness while still being computable
and providing understandable error messages@~cite{minsky08},
maybe the spot is too sweet to be healthy, and
is lacking in proteins, or at least in prototypes.

Now, there is another special way in which Jsonnet and Nix improve upon T's objects,
that provides insight into Object-Oriented Programming:
they unify instances and prototypes as objects.
We'll come back to that in @(section4).

@subsection{Prototypes are Useful Even Without Subtyping}

The above example of prototypes for numeric functions also illustrate that
even if you language's only subtyping relationship is
the identity whereby each type is the one and only subtype or itself
(or something slightly richer with syntactic variable substitution in parametric polymorphism),
then you can use prototypes to incrementally specify computations,
with the following monomorphic types:
@racketblock[
(code:comment "(deftype (MProto A) (Fun A A -> A))")
(code:comment "fix : (Fun (MProto A) A -> A)")
(code:comment "mix : (Fun (MProto A) (MProto A) -> (MProto A))")
]
As per the previous discussion, if your language doesn't use lazy evaluation,
you may have to constrain the @r[A]'s to be functions, or to
wrap the @r[A]'s in naked input position inside a @r[Lazy] type constructor.

Lack of subtyping greatly reduces the expressive power of prototypes;
yet, as we'll see in @(section5),
the most popular use of prototypes in Object-Oriented Programming is completely monomorphic:
prototypes for type descriptors, a.k.a. classes;
only this common use of prototypes happens at the meta-level,
classes being second-class objects (pun not intended by the clueless practitioners).

@section[#:tag "Better_objects"]{Better objects, still pure}

In @(section1),
we implemented a rudimentary object system on top of prototypes.
Compared to mainstream object systems, it not only was much simpler to define,
but also enabled mixins, making it more powerful than common single-inheritance systems.
Still, many bells and whistles found in other object systems are missing.
Now that we have a nice and simple semantic framework for “objects”,
can we also reimplement the more advanced features of object systems of yore?

@subsection[#:tag "field_introspection"]{Field Introspection}

@subsubsection{Both feature and bug in OOP snake-oil literature}
When representing objects as functions from symbol to value,
it isn't generally possible to access the list of symbols that constitute valid keys.
Most “object” systems do not allow for this kind of introspection at runtime,
and a 1990s marketing department would probably tout that
as some kind of “encapsulation” or “information hiding” feature to be sold as part of
the “object-oriented” package deal of the day.
Yet, introspection can be useful to e.g. automatically
input and output human-readable or network-exchangeable representations of an instance.
Thus, the same 1990s marketing departments have long sold “reflection” as
an extra feature counter-acting their previous “feature”.

@subsubsection{Same concrete representation, abstract constructor}
Field introspection can be achieved while keeping instances as functions from keys to values,
by adding a “special” key, e.g. @r[keys],
that will be bound to the list of valid keys.
To save themselves the error-prone burden of maintaining the list of keys by hand,
programmers would then use a variant of @r[$slot-gen] that maintains this list, as in:
@Definitions[
(define ($slot-gen/keys k fun)
  (λ (self super)
    (λ (msg)
      (cond ((equal? msg k) (fun self (λ () (super msg))))
            ((equal? msg 'keys) (cons k (super 'keys)))
            (else (super msg))))))
]

@subsubsection{Different instance representation}
Field introspection can also be achieved by using a different representation for instances.
Just like in Nix, instances could be mappings from symbols to value,
internally implemented as hash-tables, or, preferrably for pure usage, balanced trees.
Purposefully, we included an implementation of such balanced trees in
@seclink["pure_objective_fun"]{section 2}.
Thus, we could represent objects as thunks that return @r[symbol-avl-map], as follows:
@Definitions[
(define ($slot-gen/dict k fun)
  (λ (self super)
    (define (inherit) (Dict 'ref (super) k bottom))
    (λ () (Dict 'acons k (fun self inherit) (super)))))
]
However, while the above definition yields the correct result,
it potentially recomputes the entire dictionary @r[(super)] twice at every symbol lookup,
with exponential explosion as the number of super prototypes increases.
We could carefully implement sharing by precomputing @r[(define super-dict (super))].
But the instance is itself a thunk that would recomputing the entire dictionary at every call,
and is better evaluated only once.
Now, if we adopt lazy evaluation as in Nix, we can automatically share results
across both copies of computations and multiple consumers of a same copy of computation,
without having to manually reimplement this caching every time.
Thus, using @r[δfix] and @r[δmix] instead of @r[fix] and @r[mix], we can have:
@Definitions[
(define (δ$slot-gen/dict k fun)
  (λ (self super)
    (delay (let ((inherit (Dict 'ref (force super) k (λ () (delay (bottom))))))
             (Dict 'acons k (delay (fun self inherit)) (force super))))))
]

@subsubsection[#:tag "different_prototype"]{Same instance representation, different prototype representation}
Finally, field introspection can be achieved while preserving the same instance representation
by instead changing the representation for @emph{prototypes}.
Though the concise functional representation we offered gives an enlightening
expression of the essence of object systems, we can maintain equivalent semantics
with a more efficient implementation, for instance a pair @r[pk] of
the same prototype as before and a list of keys. The @r[mix] and @r[fix] functions become:
@Definitions[
(define (mix/pk child parent)
  (cons (mix (car child) (car parent))
        (append (cdr child) (cdr parent))))
(define (fix/pk proto base)
  (fix (mix ($slot 'keys (cdr proto)) (car proto)) base))
]
One could also put @r[$slot] invocation after the @r[(car proto)] rather than before it,
to allow prototypes to intercept field introspection.

@subsubsection{Abstracting over representations}
We can generalize the above solutions by realizing that
both instances and prototypes may be represented in a variety of ways.
The representation given in @(section1) is a good guide for object semantics,
but instance and prototype as functions may be wrapped or unwrapped in various ways,
and augmented with various other information,
when designing and implementing an object system for usability and performance.
Still, the distinction between instance and prototype
is essential to understanding and simplifying the semantics of object systems.

@subsection{Unifying Instances and Prototypes}

@subsubsection{OOP without Objects}
While the distinction between instance and prototype is essential
to simplify and understand the semantics of objects,
neither instances nor prototypes are arguably “object”.
We are thus in a strange situation wherein we have been doing
“Object-Oriented Programming” without any actual object!

This is a practical problem, as having to maintain this distinction means that
all APIs may have to be doubled at every point that may be either one or the other.
In particular, writing extensible configurations for recursive data structures this way is painful:
you need to decide for each field of each data structure at each stage of computation
whether it contains an extensible prototype or an instance to call the proper API.
This incurs both a psychological cost to programmers and a runtime cost to evaluation,
that in the worst case might recompute some sub-expressions exponentially often.

@subsubsection{Conflation without confusion}
Jsonnet and Nix both confront and elegantly solve the above issue,
and in the very same way, with one small trick:
they bundle and conflate together instance and prototype in a same single entity, the “object”.
Indeed, in a pure context, and given the base super value for the given prototype representation,
there is one and only one instance associated to a prototype up to any testable equality,
and so we may usefully cache the computation of this instance together with the prototype.
The same “object” entity can thus be seen as an instance and queried for method values,
or seen as a prototype and composed with other objects (also seen as prototypes) into a new object.

Thanks to the conflation of instance and prototype as two aspects of a same object,
configurations can be written in either language
that can refer to other parts of the configuration
without having to track and distinguish which parts are instantiated at which point,
and it all just works.
Still, distinguishing the two concepts of instance and prototype is important
to dispel the confusion that can often reign in even the most experienced OO practitioner
regarding the fine behavior of objects when trying to assemble or debug programs.

In Jsonnet, this conflation is done implicitly as part of the builtin object system implementation.
In Nix, interestingly, there are several unassuming variants of the same object system,
that each store the prototype information in one or several special fields of the @r[attrset]
that is otherwise used for instance information.
Thus, in the simplest Nix object system, one could write:
@minted["nix"]|{
fix' (self: { x = 1; y = 2 + self.x; })
}|
and it would evaluate to an attrset equivalent to:
@minted["nix"]|{
{ x = 1; y = 3; __unfix__ = self: { x = 1; y = 2 + self.x; }; }
}|
Nix contains many variants of the same object system, that use one or several of
@r[extend], @r[override], @r[overrideDerivation], @r[meta], etc., instead of @tt{__unfix__}
to store composable prototype information.

@subsubsection{Practical Conflation for Fun and Profit}
For the sake of this article, we'll represent an object as a pair of an instance and a prototype:
@Definitions[
(define (make-object instance prototype) (cons instance prototype))
(define (object-instance object) (car object))
(define (object-prototype object) (cdr object))
]

In a more robust implementation, we would use an extension to the language Scheme
to define a special structure type for objects as pairs of instance and prototype,
disjoint from the regular pair type.
Thus, we can distinguish objects from regular lists, and
hook into the printer to offer a nice way to print instance information
that users are usually interested in while skipping prototype information
that they usually aren't.

To reproduce the semantics of Jsonnet@~cite{jsonnet},
instances will be a delayed @r[Dict] (as per @(section2)),
mapping symbols as slot names to delayed values as slot computations;
meanwhile the prototype will be a prototype function of type @r[(δProto Object Object)]
(as in @seclink["computations_not_values"]{section 4.1.3}),
that preserves the prototype while acting on the instance.
Thus the basic function to access a slot, and the basic prototype to define one,
are as follow:
@Definitions[
(define (slot-ref object slot)
  (force (Dict 'ref (force (object-instance object)) slot bottom)))
(define ($slot-gen/object k fun)
  (λ (self super)
    (make-object (Dict 'acons k (fun self (delay (slot-ref super k)))
                  (object-instance (force super)))
                 (object-prototype (force super)))))
]

@subsection{Multiple Inheritance}

@; TODO: citations required on modularity, inheritance, multiple inheritance
@subsubsection{The inheritance modularity issue}
To write incremental OO programs, developers need to be able to express dependencies
between objects, such that an object @r[Z]
depends on super objects @r[K1], @r[K2], @r[K3] being present after it
in the list of prototypes to be instantiated.
We'll also say that @r[Z] @emph{inherits from} from these super objects,
or @emph{extends} them, or that they are its direct super objects.
But what if @r[K1], @r[K2], @r[K3] themselves inherit from super objects @r[A], @r[B], @r[C], @r[D], @r[E],
e.g. with @r[K1] inheriting from direct supers @r[A B C],
@r[K2] inheriting from direct supers @r[D B E], and
@r[K3] inheriting from direct supers @r[D A], and what more
each of @r[A], @r[B], @r[C], @r[D], @r[E] inheriting from a base super object @r[O]?

With the basic object model offered by Nix and Jsonnet and our code so far,
these dependencies couldn't be represented in the prototype itself.
If the programmer tried to “always pre-mix” its dependencies into a prototype,
then @r[K1] would be a pre-mix @r[K1 A B C O],
@r[K2] would be a pre-mix @r[K2 D B E O],
@r[K3] would be a pre-mix @r[K3 D A O],
and when trying to specify @r[Z], the pre-mix
@r[Z K1 A B C O K2 D B E O K3 D A O] would be incorrect,
with unwanted repetitions of @r[A], @r[B], @r[D], @r[O]
redoing their effects too many times and possibly undoing overrides made by @r[K2] and @r[K3].
Instead, the programmer would have to somehow remember and track those dependencies,
such that when he decides instantiates @r[Z], he won't write just @r[Z],
but @r[Z] followed a topologically sorted @emph{precedence list}
where each of the transitive dependencies appears once and only once,
e.g. @r[Z K1 K2 K3 D A B C E O].

Not only does this activity entail a lot of tedious and error-prone bookkeeping,
it is not modular.
If these various objects are maintained by different people as part of separate libraries,
each object's author must keep track not just of their direct dependencies,
but all their transitive indirect dependencies, with a proper ordering.
Then they must not only propagate those changes to their own objects,
but notify the authors of objects that depend on theirs.
To get a change fully propagated might required hundreds of modifications
being sent and accepted by tens of different maintainers, some of whom might not be responsive.
Even when the sets of dependencies are properly propagated, inconsistencies between
the orders chosen by different maintainers at different times may cause subtle miscalculations
that are hard to detect or debug.
In other words, while possible, manual maintenance of precedence lists is a modularity nightmare.

@subsubsection{Multiple inheritance to the rescue}
With multiple inheritance, programmers only need declare the dependencies
between objects and their direct super objects:
the object system will automatically compute
a suitable precedence list in which order to compose the object prototypes.
Thus, defining objects with dependencies becomes modular.

The algorithm that computes this precedence list is called a linearization:
It considers the dependencies as defining a directed acyclic graph (DAG),
or equivalently, a partial order, and
it completes this partial order into a total (or linear) order,
that is a superset of the ordering relations in the partial order.
The algorithm can also detect any ordering inconsistency or circular dependency
whereby the dependencies as declared fail to constitute a DAG;
in such a situation, no precedence list can satisfy all the ordering constraints,
and instead an error is raised.
Recent modern object systems seem to have settled on the C3 linearization algorithm,
as described in @seclink["Appendix_C"]{Appendix C}.

@(define/local-expand c3-definitions @Definitions[
(code:comment "not-null? : Any -> Bool")
(define (not-null? l) (not (null? l)))

(code:comment "remove-nulls : (List (List X)) -> (List (NonEmptyList X))")
(define (remove-nulls l) (filter not-null? l))

(code:comment "remove-next : X (List (NonEmptyList X)) -> (List (NonEmptyList X))")
(define (remove-next next tails)
  (remove-nulls (map (λ (l) (if (equal? (car l) next) (cdr l) l)) tails)))

(code:comment "c3-compute-precedence-list : A (A -> (List A)) (A -> (NonEmptyList A))")
(code:comment "  -> (NonEmptyList A)")
(define (c3-compute-precedence-list x get-supers get-precedence-list)
  (define supers (get-supers x)) ;; : (List A)
  (define super-precedence-lists (map get-precedence-list supers)) ;; : (List (NonEmptyList A))
  (define (c3-select-next tails) ;; : (NonEmptyList (NonEmptyList A)) -> A
    (define (candidate? c) (every (λ (tail) (not (member c (cdr tail)))) tails)) ;; : A -> Bool
    (let loop ((ts tails))
      (when (null? ts) (error "Inconsistent precedence graph"))
      (define c (caar ts))
      (if (candidate? c) c (loop (cdr ts)))))
  (let loop ((rhead (list x)) ;; : (NonEmptyList X)
             (tails (remove-nulls (append super-precedence-lists [supers])))) ;; : (List (NonEmptyList X))
    (cond ((null? tails) (reverse rhead))
          ((null? (cdr tails)) (append-reverse rhead (car tails)))
          (else (let ((next (c3-select-next tails)))
                  (loop (cons next rhead) (remove-next next tails)))))))
])

@(define/local-expand c3-extra-definitions @Definitions[
(define (pair-tree-for-each! x f)
  (let loop ((x x))
    (cond ((pair? x) (loop (car x)) (loop (cdr x)))
          ((null? x) (void))
          (else (f x)))))

(define (call-with-list-builder f)
  (define l '())
  (f (λ (x) (set! l (cons x l))))
  (reverse l))

(define (flatten-pair-tree x)
  (call-with-list-builder (λ (c) (pair-tree-for-each! x c))))

(define (alist->Dict alist)
  (foldl (λ (kv a) ((Dict 'acons) (car kv) (cdr kv) a)) (Dict 'empty) alist))

(define (Dict->alist dict)
  ((Dict 'afoldr) (λ (k v a) (cons (cons k v) a)) '() dict))

(define (Dict-merge override-dict base-dict)
  ((Dict 'afoldr) (Dict 'acons) base-dict override-dict))
])

@subsubsection{A prototype is more than a function}
But where is the inheritance information to be stored?
A prototype must contain more than the function being composed to implement open-recursion;
@italic{A minima} it must also contain the list of direct super objects
that the current object depends on.
We saw in @seclink["different_prototype"]{4.1.4} that and how we can and sometimes must indeed
include additional information in a prototype.
Such additional information will include a precomputed cache for the precedence list below,
but could also conceivably include
type declarations, method combinations, and support for any imaginable future feature.

We could start by making the prototype a pair of prototype function and list of supers;
if more data elements are later needed, we could use a vector with every element at a fixed location.
But since we may be adding further features to the object system,
we will instead make the prototype itself an object,
with a special base case to break the infinite recursion.
Thus, the same functions as used to query the slot values of an object's instance
can be used to query the data elements of the prototype (modulo this special case).
But also, the functions used to construct an object can be used to construct a prototype,
which lays the foundation for a meta-object protocol@~cite{amop},
wherein object implementation can be extended from the inside.

When it is an object, a prototype will have
slot @r[function] bound to a prototype function as previously, and
slot @r[supers] bound to a list of super objects to inherit from,
as well as a slot @r[precedence-list] bound to a precomputed cache of the precedence list.
When it is the special base case, for which we below chose the empty list,
slots @r[supers] and @r[precedence-list] are bound to empty lists, and slot @r[function]
is bound to a function that overrides its super with constant fields from the instance.

@Definitions[
(define (Dict->Object dict) (make-object dict '()))
(define (object-prototype-function object)
  (define prototype (object-prototype object))
  (if (null? prototype)
    (λ (self super)
      (make-object (Dict-merge (object-instance object) (object-instance super))
                   (object-prototype super)))
    (slot-ref prototype 'precedence-list)))
(define (object-supers object)
  (define prototype (object-prototype object))
  (if (null? prototype) '() (slot-ref prototype 'supers)))
(define (object-precedence-list object)
  (define prototype (object-prototype object))
  (if (null? prototype) '() (slot-ref prototype 'precedence-list)))
(define (compute-precedence-list object)
  (c3-compute-precedence-list object object-supers object-precedence-list))
(define base-dict (Dict 'empty))
(define (object supers function)
  (define proto
    (Dict->Object (Dict 'acons 'function (delay function)
                   (Dict 'acons 'supers (delay supers)
                    (Dict 'acons 'precedence-list (delay precedence-list)
                     (Dict 'empty))))))
  (define base (make-object base-dict proto))
  (define precedence-list (compute-precedence-list base))
  (define prototype-functions (map object-prototype-function precedence-list))
  (instantiate-prototype-list prototype-functions base))
]

@subsection{Multiple Dispatch}

@subsubsection{Generic Functions}
Some object systems, starting with CommonLoops@~cite{bobrow86commonloops}
then CLOS@~cite{bobrow88clos},
feature the ability to define “generic functions” the behavior of which
can be specialized on each of multiple arguments.
For instance, a generic multiplication operation
will invoke different methods when called with two integers, two complex numbers,
an integer and a floating-point number, a complex number and a vector of complex numbers, etc.

Selection of behavior based on multiple arguments is called “multiple dispatch”,
as contrasted with “single dispatch” which is selection of behavior based on a single argument.
Methods that may specialize on multiple arguments are sometimes called “multi-methods”
to distinguish them from single dispatch methods.
It is possible to macro-expand multiple dispatch into single dispatch,
@; TODO @~cite{} double dispatch?
by chaining dispatch of the first argument into a collection of functions
that each dispatch on the second argument, and so on.
But the process is tedious and non-local, and better left to be
handled by an automated implementation of multiple dispatch.

Since this feature is rather involved yet was already implemented in
previous prototype systems@~cite{chambers92objectoriented Salzman05prototypeswith},
we'll restrict our discussion to additional challenges presented in
a pure or mostly pure functional setting.

@subsubsection{Extending previous objects}
Generic functions and their multi-methods are associated to multiple objects,
thus they cannot be defined as part of the definition of a single object;
these methods, and the generic function that they are part of,
are necessarily defined outside of (some) objects.
Therefore, language designers and implementers must resolve a first issue
before they may implement generic functions:
adding “multi-methods” to existing functions or objects
after they have been initially defined.
Indeed, generic functions when introduced, involve adding new methods
that specialize the behavior of the new function on existing objects;
and when new objects are introduced, they often involve adding new methods
to specialized the behavior of the existing functions on the new objects.

Moreover, when generic functions and objects are introduced in independent code libraries
(e.g. some graphical user-interface library and some data structure library),
the specialized behavior might be introduced in yet another library
(e.g. that defines a graphical interface for this data structure).
Worse, there might be conflicts between several such libraries.
Even without conflicting definitions,
a definition might conflict in time with the absence of the same definition,
if there is any chance that some code depending on its presence is compiled or run
both before and after the definition was evaluated.

That is why, for instance, the Glasgow Haskell Compiler @;TODO @~cite{GHC}
issues warnings if you declare an “orphan instance”:
a typeclass instance (rough analogue to methods of generic functions)
in a file other than one where either the typeclass is defined (analogous to generic functions)
or the type is defined (analogous to objects).
The language offers weak guarantees in such situations.
One way to avoid orphan situations might be to declare
either new typeclasses (new generic functions) or newtype aliases (new objects)
that will shadow or replace the previous ones in the rest of the program;
but this is a non-local and non-composable transformation
that potentially involves wrapping over all the transitive dependencies of an application,
and defeat the purpose of incremental program specification.
Another approach suitable in a more dynamic language would be to maintain at runtime
a “negative” cache of methods previously assumed to be absent,
and issue a warning or error when a new method is introduced that conflicts with such an assumption.

Then again, a solution might be to eschew purity and embrace side-effects:
the original T just didn't cache method invocation results, and
re-ran fixed-point computations, with their possible side-effects,
at every method invocation (objects can specify their own explicit cache when desired).
The behavior of new generic functions on previously existing objects would be optionally specified
in a default method, to be called in lieu of raising a “method not found” error.
The T object paper@~cite{Adams89object-orientedprogramming} mentions an alternate approach
that was rejected in its implementation, though it is essentially equivalent in behavior,
wherein default methods are added to a “default” object used as the base super value
instead of an empty object when (re)computing instance fixed-points.

@subsection{Method Combinations}

@subsubsection{Combining Method Fragments}
With method combination, as pioneered in Flavors@~cite{Cannon82},
then standardized by CLOS@~cite{bobrow88clos} via @~cite{bobrow86commonloops}
and made slightly popular outside the Lisp tradition by Aspect-Oriented Programming@~cite{aop97},
object methods to be specified in multiple fragments
that can be subsequently combined into the “effective method” that will be called.

Thus, in CLOS, “primary” methods are composed the usual way,
but “before” methods are executed beforehand for side-effects from most-specific to least-specific,
and “after” methods are executed afterwards for side-effects from least-specific to most-specific,
and “around” methods wrap all the above, with from most-specific wrapper outermost
to least-specific inner-most.

Furthermore, programmers may override the above standard “method combinations”
with alternative method combinations, either builtin or user-specified.
The builtin method combinations, @r[progn + list nconc and max or append min] in CLOS,
behave as if the calls to the (suitably sorted) methods had been wrapped in
one of the corresponding Lisp special form or function.
User-specified method combinations allow for arbitrary behavior based on
an arbitrary set of sorted, labelled (multi)methods
(though, in CLOS, with a fixed finite set of labels).

@subsubsection{Generalized Prototype Combination}

As determined above, generic functions are made of many labelled fragments (multi-methods);
fragments of a same label are sorted according to some partial or total order;
they are then composed via some representation-dependent mixing function;
a fixed-point is extracted from the composed fragments, with some base value;
finally a representation-dependent wrapper is applied to the fixed-point
to instantiate the effective method...
this is very much like an object!
Actually, since we have accepted in @(section3) that prototypes and “object orientation”
are not just to compute records that map field names to values, but for arbitrary computations,
then we realize there is a more general protocol for computing with prototypes.

A full treatment of generalized prototypes is a topic for future work.
Still, here are a few hints as to what they would be.
A generalized prototype would involve:
(a) a @emph{lens}@~cite{Foster2007CombinatorsFB Pickering_2017}
@; TODO: re-cite Kmett, Laarhoven from the Pickering_2017 article? Cite 2006 Pierce on Lens rather than 2007, see later Gibbons article
that can extract or update the method from the current partial computation
of the raw prototype fixed-point;
(b) an object-setter that “cooks” the raw prototype fixed-point into a referenceable
@r[self] object;
(c) a method-wrapper that turns the user-provided “method” into a composable prototype.

The lens, passed below as two function arguments @r[getter] and @r[setter],
generalizes the fetching or storing of a method as the entry in a @r[Dict],
or as the response to a message;
it expresses how a prototype overrides some specific fragment of some specific method
in some specific sub-sub-object, encoded in some specific way.
The object-setter may apply a method combination to extract a function from fragments;
it may transcode an object from a representation suitable for object production
to a representation suitable for object consumption;
it may be the setter from a lens making the prototype-based computation
that of a narrow component in a wider computation,
at which point the corresponding getter allows a method to retrieve the computation at hand
from the overall computation;
it may be a composition of some of the above and more.
The method-wrapper may to automate some of the builtin method combinations;
for instance, in a @r[+] combination, it would, given an number,
return the prototype that increments the super result by that number;
it may also handle the merging of a @r[Dict] override returned by the method
into the super @r[Dict] provided by its super method; etc.

Here then is a generalization that subsumes the above @r[$slot-gen] or @r[$slot-gen/object]:
@Definitions[
(define ($lens-gen setter getter wrapper method)
  (λ (cooked-self raw-super)
    (setter ((wrapper method) cooked-self (delay (getter raw-super)))
            raw-super)))
]

@;{ @para{
The types might look a bit as follows:
@Definitions[
(code:comment "(deftype (ObjectWrapper Raw Cooked)")
(code:comment "  (Forall (Object) (Fun (Raw Object) -> (Cooked Object))))")
(code:comment "(deftype (CookedProto Cooked)")
(code:comment "  (Forall (ObjectSuper ObjectSelf MethodSuper MethodSelf) ; s t a b")
(code:comment "    (Fun (Cooked ObjectSelf) (Delayed MethodSuper) -> MethodSelf)))")
(code:comment "(deftype (MethodSetter Raw)")
(code:comment "  (Forall (ObjectSuper ObjectSelf MethodSelf) ; s t b")
(code:comment "    (Fun MethodSelf (Raw ObjectSuper) -> (Raw ObjectSelf))))")
(code:comment "(deftype (MethodGetter Raw)")
(code:comment "  (Forall (Object Method) ; s a")
(code:comment "    (Fun (Raw Object) -> Method)))")
(code:comment "(deftype (MethodWrapper Cooked RawProto)")
(code:comment "  (Fun (RawProto Cooked) -> (CookedProto Cooked)))")
]
}}

@section{Classes}

Classes are “just” prototypes for type descriptors.
Usually done at the meta-level in languages without “first-class” classes,
only “second-class” classes.
At the meta-level, type descriptors are themselves of a same concrete type,
so the meta-language only needs and uses monomorphic prototypes!

@section[#:tag "Mutability"]{Mutability}

@subsection{Mutability as Pure Linearity}
@subsubsection{From Pure to Mutable and Back}
Note how all the objects and functions defined in the previous sections were pure,
as contrasted with all OOP literature from the 1960s to the early 1990s and most since:
They didn't use any side-effect whatsoever.
No @r[set!], no tricky use of @r[call/cc]. Only laziness at times, which still counts as pure.
But what if we are OK with using side-effects? How much does that simplify computations?
What insights does the pure case offer on the mutable case, and vice versa?

A simple implementation of mutable objects is to store pure object values into mutable cells.
Conversely, a mutable object can be viewed as a monadic thread of pure object state references,
with an enforced linearity constraint wherein effectful operations return a new state reference
after invalidating the previous one.
Indeed, this isomorphism is not just a curiosity from category theory,
it is a pair of transformations that can be and have been automated
for practical purposes@~cite{LIL2012}.

@subsubsection{Combining Mutable and Functional Wins}
Mutability allows for various optimizations,
wherein objects follow common linearity constraints of consuming some arguments
that are never referenced again after use, at which point their parts
can be transformed or recycled “in place” with local modifications in @${O(1)} machine operations,
rather than global copies in @${O(\log n)} or @${O(n)} machine operations.
@;TODO cite regarding state vs linearity
As a notable simplification, the “super” computation as inherited by a prototype is linear
(or more precisely, affine: the prototype may either consume the super value, or ignore it).
Thus, the entire fixed-point computation can be done in-place by updating slots as they are defined.
This is a win for mutability over purity.

Yet, even mutable (or linear) rather than pure (and persistent),
the functional approach solves an important problem with the traditional imperative approach:
traditionally, programmers must be very careful to initialize object slots in a suitable order,
even though there is no universal solution that possibly works
for all future definitions of inheriting objects.
The traditional approach is thus programmer-intensive in a subtle way, which leads to many
errors from handling of unbound slots, or worse, if slot accesses are unchecked,
to @emph{null pointer} exceptions or the local programming language's equivalent,
whereby some default value is propagated along the program until it is detected, too late,
by a catastrophic error with little explanation.
By defining objects functionally or lazily rather than imperatively and eagerly,
programmers can let the implementation gracefully handle mutual references between slots;
an initialization order can be automatically inferred wherein slots are defined before they are used,
with a useful error detected and raised (at runtime) if no such order exists.
@; TODO: cite Tony Hoare regarding the billion-dollar mistake of NULL?

@subsubsection{Simplified Prototype Protocol}
A prototype for a mutable object can be implemented
with a single mutable data structure argument @r[self]
instead of two immutable value arguments @r[self] and @r[super]:
the @emph{identity} of that data structure
provides the handle to future complete computation,
as previously embodied in the @r[self] argument;
and the current @emph{storage} of the data structure provides state of the computation so far,
as previously embodied in the @r[super] argument.

A prototype function would then be of type @r[(deftype μProto (Fun Object ->))],
where the @r[Object]'s instance component would typically contain a mutable hash-table
mapping slot names (symbols) to effective methods to compute each slot value.
These effective methods would be either thunks or lazy computations,
and would already close over the identity of the object as well as reuse its previous state.
Overriding a slot would update the effective method in place,
based on the new method, the self (identity of the object) and
super method (previous entry in the hash-table).

@;
@Definitions[
(define ($slot-gen/hash k fun)
  (λ (self) (let ((super-slot-computation (λ () ((hash-ref self k)))))
              (hash-set! self k (λ () (fun self super-slot-computation))))
              self))
]

@subsection{Cache invalidation}
@italic{There are two hard things in computer science:
cache invalidation, naming things, and off-by-one errors} (Phil Karton).
One issue with making objects mutable is that modifications may make
some previously computed results invalid. There are several options then,
none universally satisfactory.

The object system may embrace mutation and just
never implicitly cache the result of any computation,
as in T, and let the users deal with the issue.
But constant recomputation can be extremely expensive, and
many heavy computations, like that of precedence lists for multiple inheritance,
may be below the level at which users may intervene.

At the opposite end of the spectrum, the object system may assume purity-by-default
and cache all the computations it can.
It is then up to users to explicitly create cells to make some things mutable,
or flush some caches when appropriate.
@; , as in the Gerbil-POO system@~cite{GerbilPOO}.

In between these two opposites, the system can automatically track which mutations happen,
and invalidate those caches that need be, with a tradeoff between how cheap it will be
to use caches versus to mutate objects.
However, to be completely correct, this mutation tracking and cache invalidation
must be pervasive in the entire language, not just the object system implementation,
at which point the language is more in the style of higher-order
reactive or incremental programming. @;TODO: @~cite{}

@;;; Here, we silently cite things that only appear in the appendices,
@;;; so they appear in the bibliography, that is being computed before the appendices.
@~nocite{Barrett96amonotonic}

@(generate-bibliography)

@section[#:tag "Appendix_A"]{Digression about type notation} @appendix

@section[#:tag "Appendix_B"]{Fixed-Point functions}

@section[#:tag "Appendix_C"]{Code Library}

The object system implementation in our article above relies on the following code library
of relatively obvious or well-known functions, that have provide no original insight,
but are included here for the sake of completeness and reproducibility.

@subsection{C3 Linearization Algorithm}

Below is the C3 Linearization algorithm to topologically sort an inheritance DAG
into a precedence list such that direct supers are all included before indirect supers.
Initially introduced in Dylan@~cite{Barrett96amonotonic},
it has since been adopted by many modern languages, including
Python, Raku, Parrot, Solidity, PGF/TikZ.

The algorithm ensures that the precedence list of an object always contains as ordered sub-lists
(though not necessarily with consecutive elements) the precedence list of
each of the object's super-objects, as well as the list of direct supers.
It also favors direct supers appearing as early as possible in the precedence list.

@c3-definitions

@subsection{More Helper Functions}

To help with defining multiple inheritance, we'll also define the following helper functions:

@c3-extra-definitions

@section[#:tag "Appendix_D"]{Note for code minimalists}

In our introduction, we described the @r[fix] and @r[mix] functions
in only 109 characters of Scheme.
We can do even shorter with various extensions.
MIT Scheme and after it Racket, Gerbil Scheme, and more,
allow you to curried function definitions:
@Examples[
(define ((mix p q) f b) (p f (q f b)))
]
And then we'd have Object Orientation in 100 characters only.

Then again, in Gerbil Scheme, we could get it down to only 86, counting newline:
@racketblock[
(def (fix p b) (def f (p (lambda i (apply f i)) b)) f)
]

Or, compressing spaces, to 78,
not counting newline, since we elide spaces:
@racketblock[
(def(fix p b)(def f(p(lambda i(apply f i))b))f)(def((mix p q)f b)(p f(q f b)))
]

@(finalize-examples/module poof)

@; TODO: comment out before to submit:
@table-of-contents[]
@;only works for HTML output: @local-table-of-contents[#:style 'immediate-only]
