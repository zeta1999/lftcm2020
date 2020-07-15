import tactic
import data.set.finite
import data.real.basic -- for metrics

/-
# (Re)-Building topological spaces in Lean

Mathlib has a large library of results on topological spaces, including various
constructions, separation axioms, Tychonoff's theorem, sheaves, Stone-Čech
compactification, Heine-Cantor, to name but a few.
See https://leanprover-community.github.io/theories/topology.html which for a
(subset) of what's in library.

But today we will ignore all that, and build our own version of topological
spaces from scratch!
(On Friday morning Patrick Massot will lead a session exploring the existing
mathlib library in more detail)

To get this file run either `leanproject get lftcm2020`, if you didn't already or cd to
that folder and run `git pull; leanproject get-mathlib-cache`, this is
`src/exercise_sources/wednesday/afternoon/topological_spaces.lean`.

The exercises are spread throughout, you needn't do them in order! They are marked as
short, medium and long, so I suggest you try some short ones first.

First a little setup, we will be making definitions involving the real numbers,
the theory of which is not computable, and we'll use sets.
-/
noncomputable theory
open set

/-!
## What is a topological space:

There are many definitions: one from Wikipedia:
  A topological space is an ordered pair (X, τ), where X is a set and τ is a
  collection of subsets of X, satisfying the following axioms:
  - The empty set and X itself belong to τ.
  - Any arbitrary (finite or infinite) union of members of τ still belongs to τ.
  - The intersection of any finite number of members of τ still belongs to τ.

We can formalize this as follows: -/

class topological_space_wiki :=
  (X : Type)  -- the underlying Type that the topology will be on
  (τ : set (set X))  -- the set of open subsets of X
  (empty_mem : ∅ ∈ τ)  -- empty set is open
  (univ_mem : univ ∈ τ)  -- whole space is open
  (union : ∀ B ⊆ τ, ⋃₀ B ∈ τ)  -- arbitrary unions (sUnions) of members of τ are open
  (inter : ∀ (B ⊆ τ) (h : finite B), ⋂₀ B ∈ τ)  -- finite intersections of
                                                -- members of τ are open

/-
Before we go on we should be sure we want to use this as our definition.
-/


@[ext]
class topological_space (X : Type) :=
  (is_open : set X → Prop) -- why set X → Prop not set (set X)? former plays
                           -- nicer with typeclasses later
  (empty_mem : is_open ∅)
  (univ_mem : is_open univ)
  (union : ∀ (B : set (set X)) (h : ∀ b ∈ B, is_open b), is_open (⋃₀ B))
  (inter : ∀ (A B : set X) (hA : is_open A) (hB : is_open B), is_open (A ∩ B))

namespace topological_space

/- ## Exercise 0 [short]:
One of the axioms of a topological space we have here is unnecessary, it follows
from the others. If we remove it we'll have less work to do each time we want to
create a new topological space so:

1. Identify and remove the unneeded axiom, make sure to remove it throughout the file.
2. Add the axiom back as a lemma with the same name and prove it based on the
   others, so that the _interface_ is the same. -/


/- Defining a basic topology now works like so: -/
def discrete (X : Type) : topological_space X :=
{ is_open := univ, -- everything is open
  empty_mem := trivial,
  univ_mem := trivial,
  union := begin intros B h, trivial, end,
  inter := begin intros A hA B hB, trivial, end }

/- As mentioned, there are many definitions of a topological space, for instance
one can define them via specifying a set of closed sets satisfying various
axioms, this is equivalent and sometimes more convenient.

We _could_ create two distinct Types defined by different data and provide an
equivalence between theses types, e.g. `topological_space_via_open_sets` and
`topological_space_via_closed_sets`, but this would quickly get unwieldy.
What's better is to make an alternative _constructor_ for our original
topological space. This is a function takes a set of subsets satisfying the
axioms to be the closed sets of a topological space and creates the
topological space defined by the corresponding set of open sets.

## Exercise 1 [medium]:
Complete the following constructor of a topological space from a set of subsets
of a given type `X` satisfying the axioms for the closed sets of a topology.
Hint: there are many useful lemmas about complements in mathlib, with names
involving `compl`, like `compl_empty`, `compl_univ`, `compl_compl`, `compl_sUnion`,
`mem_compl_image`, `compl_inter`, `compl_compl'`, `you can #check them to see what they say. -/

def mk_closed_sets
  (X : Type)
  (σ : set (set X))
  (empty_mem : ∅ ∈ σ)
  (univ_mem : univ ∈ σ)
  (inter : ∀ B ⊆ σ, ⋂₀ B ∈ σ)
  (union : ∀ (A ∈ σ) (B ∈ σ), A ∪ B ∈ σ) :
topological_space X := {
  is_open := λ U, U ∈ compl '' σ, -- the corresponding `is_open`
  empty_mem :=
    sorry
  ,
  univ_mem :=
    sorry
  ,
  union :=
    sorry
  ,
  inter :=
    sorry
    }

/- ## Exercise 2 [medium]:
Another way me might want to create topological spaces in practice is to take
the coarsest possible topological space containing a given set of is_open.
To define this we might say we want to define what `is_open` is given the set
of generators.
So we want to define the predicate `is_open` by declaring that each generator
will be open, the intersection of two opens will be open, and each union of a
set of opens will be open, and finally the empty and whole space (`univ`) must
be open. The cleanest way to do this is as an inductive definition.

The exercise is to make this definition of the topological space generated by a
given set in Lean.

### Hint:
As a hint for this exercise take a look at the following definition of a
constructible set of a topological space, defined by saying that an intersection
of an open and a closed set is constructible and that the union of any pair of
constructible sets is constructible.

(Bonus exercise: mathlib doesn't have any theory of constructible sets, make one and PR
it! [arbitrarily long!], or just prove that open and closed sets are constructible for now) -/

inductive is_constructible {X : Type} (T : topological_space X) : set X → Prop
/- Given two open sets in `T`, the intersection of one with the complement of
   the other open is locally closed, hence constructible: -/
| locally_closed : ∀ (A B : set X), is_open A → is_open B → is_constructible (A ∩ Bᶜ)
-- Given two constructible sets their union is constructible:
| union : ∀ A B, is_constructible A → is_constructible B → is_constructible (A ∪ B)

-- For example we can now use this definition to prove the empty set is constructible
example {X : Type} (T : topological_space X) : is_constructible T ∅ :=
begin
  -- The intersection of the whole space (open) with the empty set (closed) is
  -- locally closed, hence constructible
  have := is_constructible.locally_closed univ univ T.univ_mem T.univ_mem,
  -- but simp knows that's just the empty set
  simpa using this,
end

/-- The open sets of the least topology containing a collection of basic sets. -/
inductive generated_open (X : Type) (g : set (set X)) : set X → Prop


/-- The smallest topological space containing the collection `g` of basic sets -/
def generate_from (X : Type) (g : set (set X)) : topological_space X :=
{ is_open   := sorry,
  empty_mem := sorry,
  univ_mem  := sorry,
  inter     := sorry,
  union     := sorry }

/- ## Exercise 3 [short]:
Define the indiscrete topology on any type using this.
(To do it without this it is surprisingly fiddly to prove that the set `{∅, univ}`
actually forms a topology) -/
def indiscrete (X : Type) : topological_space X :=
  sorry

end topological_space

open topological_space
/- Now it is quite easy to give a topology on the product of a pair of
   topological spaces. -/
instance prod.topological_space (X Y : Type) [topological_space X]
  [topological_space Y] : topological_space (X × Y) :=
topological_space.generate_from (X × Y) {U | ∃ (Ux : set X) (Uy : set Y)
  (hx : is_open Ux) (hy : is_open Uy), U = set.prod Ux Uy}

lemma is_open_prod_iff (X Y : Type) [topological_space X] [topological_space Y]
  {s : set (X × Y)} :
is_open s ↔ (∀a b, (a, b) ∈ s → ∃u v, is_open u ∧ is_open v ∧
                                  a ∈ u ∧ b ∈ v ∧ set.prod u v ⊆ s) := sorry

/- # Metric spaces -/

open_locale big_operators

class metric_space_basic (X : Type) :=
  (dist : X → X → ℝ)
  (dist_eq_zero_iff : ∀ x y, dist x y = 0 ↔ x = y)
  (dist_symm : ∀ x y, dist x y = dist y x)
  (triangle : ∀ x y z, dist x z ≤ dist x y + dist y z)

namespace metric_space_basic
open topological_space

/- ## Exercise 4 [short]:
We have defined a metric space with a metric landing in ℝ, and made no mention of
nonnegativity, (this is in line with the philosophy of using the easiest axioms for our
definitions as possible, to make it easier to define individual metrics). Show that we
really did define the usual notion of metric space. -/
lemma dist_nonneg {X : Type} [metric_space_basic X] (x y : X) : 0 ≤ dist x y :=
sorry

/- From a metric space we get an induced topological space structure like so: -/

instance {X : Type} [metric_space_basic X] : topological_space X :=
generate_from X { B | ∃ (x : X) r, B = {y | dist x y < r} }

end metric_space_basic

open metric_space_basic

/- So far so good, now lets define the product of two metric spaces:

## Exercise 5 [medium]:
Fill in the proofs here.
Hint: the computer can do boring casework you would never dream of in real life.
`max` is defined as `if x < y then y else x` and the `split_ifs` tactic will
break apart if statements. -/
instance prod.metric_space_basic (X Y : Type) [metric_space_basic X] [metric_space_basic Y] :
metric_space_basic (X × Y) :=
{ dist := λ u v, max (dist u.fst v.fst) (dist u.snd v.snd),
  dist_eq_zero_iff :=
  sorry
  ,
  dist_symm := sorry,
  triangle :=
  sorry
  }

/- ☡ Let's try to prove a simple lemma involving the product topology: ☡
   Once you have filled in Exercise 5, this won't work!! -/

example (X : Type) [metric_space_basic X] : is_open {xy : X × X | dist xy.fst xy.snd < 100 } :=
begin
  rw is_open_prod_iff X X,
  -- this fails, why? Because we have two subtly different topologies on the product
  -- they are equal but the proof that they are equal is nontrivial and the
  -- typeclass mechanism can't see that they automatically to apply. We need to change
  -- our set-up.
  sorry,
end

/- Note that lemma works fine when there is only one topology involved. -/
lemma diag_closed (X : Type) [topological_space X] : is_open {xy : X × X | xy.fst ≠ xy.snd } :=
begin
  rw is_open_prod_iff X X,
  intros x y h,
  sorry,
end

/- ## Exercise 6 [short]:
The previous lemma isn't true! It requires a separation axiom. Define a `class`
that posits that the topology on a type `X` satisfies this axiom. Mathlib uses
`T_i` naming scheme for these axioms. -/
class t2_space (X : Type) [topological_space X] :=
(t2 : sorry)

/- (Bonus exercises [medium], the world is your oyster: prove the correct
version of the above lemma `diag_closed`, prove that the discrete topology is t2,
or that any metric topology is t2, ). -/


/- Let's fix the broken example from earlier, by redefining the topology on a metric space.
We have unfortunately created two topologies on `X × Y`, one via `prod.topology`
that we defined earlier as the product of the two topologies coming from the
respective metric space structures. And one coming from the metric on the product.

These are equal, i.e. the same topology (otherwise mathematically the product
would not be a good definition). However they are not definitionally equal, there
is as nontrivial proof to show they are the same. The typeclass system (which finds
the relevant topological space instance when we use lemmas involving topological
spaces) isn't able to check that topological space structures which are equal
for some nontrivial reason are equal on the fly so it gets stuck.

We can use `extends` to say that a metric space is an extra structure on top of
being a topological space so we are making a choice of topology for each metric space.
This may not be *definitionally* equal to the induced topology, but we should add the
axiom that the metric and the topology are equal to stop us from creating a metric
inducing a different topology to the topological structure we chose. -/
class metric_space (X : Type) extends topological_space X, metric_space_basic X :=
  (compatible : ∀ U, is_open U ↔ generated_open X { B | ∃ (x : X) r, B = {y | dist x y < r}} U)

namespace metric_space

open topological_space

/- This might seem a bit inconvenient to have to define a topological space each time
we want a metric space.

We would still like a way of making a `metric_space` just given a metric and some
properties it satisfies, i.e. a `metric_space_basic`, so we should setup a metric space
constructor from a `metric_space_basic` by setting the topology to be the induced one. -/

def of_basic {X : Type} (m : metric_space_basic X) : metric_space X :=
{ compatible := begin intros, refl, end,
  ..m,
  ..@metric_space_basic.topological_space X m }

/- Now lets define the product of two metric spaces properly -/
instance {X Y : Type} [metric_space X] [metric_space Y] : metric_space (X × Y) :=
{ compatible :=
  begin
  -- Let's not fill this in for the demo, let me know if you do it!
  sorry
  end,
  ..prod.topological_space X Y,
  ..prod.metric_space_basic X Y, }

/- Now this will work, there is only one topological space on the product, we can
rewrite like we tried to before a lemma about topologies our result on metric spaces,
as there is only one topology here.

## Exercise 7 [long?]:
Complete the proof of the example (you can generalise the 100 too if it makes it
feel less silly). -/

example (X : Type) [metric_space X] : is_open {xy : X × X | dist xy.fst xy.snd < 100 } :=
begin
  rw is_open_prod_iff X X,
  sorry
end

end metric_space

/- Here are some more exercises:

## Exercise 9 [medium/long]:
Define the cofinite topology on any type (PR it to mathlib?).

## Exercise 10 [medium/long]:
Define a normed space?

## Exercise 11 [medium/long]:
Define more separation axioms?

-/

