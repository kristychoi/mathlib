/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Mario Carneiro

Multisets.
-/
import data.list.basic data.list.perm data.list.sort order.boolean_algebra
       algebra.functions data.quot algebra.group_power algebra.ordered_group
open list subtype nat lattice

local attribute [simp] mul_comm mul_assoc mul_left_comm and.comm and.left_comm and.assoc
  or.comm or.left_comm or.assoc

variables {α : Type*} {β : Type*} {γ : Type*}

local infix ` • `:73 := add_monoid.smul

instance list.perm.setoid (α : Type*) : setoid (list α) :=
setoid.mk perm ⟨perm.refl, @perm.symm _, @perm.trans _⟩

def {u} multiset (α : Type u) : Type u :=
quotient (list.perm.setoid α)

namespace multiset

instance : has_coe (list α) (multiset α) := ⟨quot.mk _⟩

@[simp] theorem quot_mk_to_coe (l : list α) : @eq (multiset α) ⟦l⟧ l := rfl

@[simp] theorem quot_mk_to_coe' (l : list α) : @eq (multiset α) (quot.mk (≈) l) l := rfl

@[simp] theorem quot_mk_to_coe'' (l : list α) : @eq (multiset α) (quot.mk setoid.r l) l := rfl

@[simp] theorem coe_eq_coe (l₁ l₂ : list α) : (l₁ : multiset α) = l₂ ↔ l₁ ~ l₂ := quotient.eq

instance has_decidable_eq [decidable_eq α] : decidable_eq (multiset α)
| s₁ s₂ := quotient.rec_on_subsingleton₂ s₁ s₂ $ λ l₁ l₂,
  decidable_of_iff' _ quotient.eq

/- empty multilist -/
protected def zero : multiset α := @nil α

instance : has_zero (multiset α)   := ⟨multiset.zero⟩
instance : has_emptyc (multiset α) := ⟨0⟩
instance : inhabited (multiset α)  := ⟨0⟩

@[simp] theorem coe_nil_eq_zero : (@nil α : multiset α) = 0 := rfl

/- cons -/
def cons (a : α) (s : multiset α) : multiset α :=
quot.lift_on s (λ l, (a :: l : multiset α))
  (λ l₁ l₂ p, quot.sound ((perm_cons a).2 p))

notation a :: b := cons a b

instance : has_insert α (multiset α) := ⟨cons⟩

@[simp] theorem insert_eq_cons (a : α) (s : multiset α) :
  insert a s = a::s := rfl

@[simp] theorem cons_coe (a : α) (l : list α) :
  (a::l : multiset α) = (a::l : list α) := rfl

theorem singleton_coe (a : α) : (a::0 : multiset α) = ([a] : list α) := rfl

@[simp] theorem cons_inj_left {a b : α} (s : multiset α) :
  a::s = b::s ↔ a = b :=
⟨quot.induction_on s $ λ l e,
  have [a] ++ l ~ [b] ++ l, from quotient.exact e,
  eq_singleton_of_perm $ (perm_app_right_iff _).1 this, congr_arg _⟩

@[simp] theorem cons_inj_right (a : α) {s t : multiset α} :
  a::s = a::t ↔ s = t :=
quotient.induction_on₂ s t $ λ l₁ l₂, by simp [perm_cons]

@[recursor 5] protected theorem induction {p : multiset α → Prop}
  (h₁ : p 0) (h₂ : ∀ ⦃a : α⦄ {s : multiset α}, p s → p (a :: s)) (s) : p s :=
quot.induction_on s $ λ l, by induction l; [exact h₁, exact h₂ ih_1]

@[elab_as_eliminator] protected theorem induction_on {p : multiset α → Prop}
  (s : multiset α) (h₁ : p 0) (h₂ : ∀ ⦃a : α⦄ {s : multiset α}, p s → p (a :: s)) : p s :=
multiset.induction h₁ h₂ s

theorem cons_swap (a b : α) (s : multiset α) : a :: b :: s = b :: a :: s :=
quot.induction_on s $ λ l, quotient.sound $ perm.swap _ _ _

section mem

def mem (a : α) (s : multiset α) : Prop :=
quot.lift_on s (λ l, a ∈ l) (λ l₁ l₂ (e : l₁ ~ l₂), propext $ mem_of_perm e)

instance : has_mem α (multiset α) := ⟨mem⟩

@[simp] lemma mem_coe {a : α} {l : list α} : a ∈ (l : multiset α) ↔ a ∈ l := iff.rfl

instance decidable_mem [decidable_eq α] (a : α) (s : multiset α) : decidable (a ∈ s) :=
quot.rec_on_subsingleton s $ list.decidable_mem a

@[simp] theorem mem_cons {a b : α} {s : multiset α} : a ∈ b :: s ↔ a = b ∨ a ∈ s :=
quot.induction_on s $ λ l, iff.rfl

@[simp] theorem mem_cons_self (a : α) (s : multiset α) : a ∈ a :: s :=
mem_cons.2 (or.inl rfl)

theorem exists_cons_of_mem {s : multiset α} {a : α} : a ∈ s → ∃ t, s = a :: t :=
quot.induction_on s $ λ l (h : a ∈ l),
let ⟨l₁, l₂, e⟩ := mem_split h in
e.symm ▸ ⟨(l₁++l₂ : list α), quot.sound perm_middle⟩

@[simp] theorem not_mem_zero (a : α) : a ∉ (0 : multiset α) := id

theorem eq_zero_of_forall_not_mem {s : multiset α} : (∀x, x ∉ s) → s = 0 :=
quot.induction_on s $ λ l H, by rw eq_nil_of_forall_not_mem H; refl

theorem exists_mem_of_ne_zero {s : multiset α} : s ≠ 0 → ∃ a : α, a ∈ s :=
quot.induction_on s $ assume l hl,
  match l, hl with
  | [] := assume h, false.elim $ h rfl
  | (a :: l) := assume _, ⟨a, by simp⟩
  end

end mem


/- subset -/
section subset

protected def subset (s t : multiset α) : Prop := ∀ ⦃a : α⦄, a ∈ s → a ∈ t

instance : has_subset (multiset α) := ⟨multiset.subset⟩

@[simp] theorem coe_subset {l₁ l₂ : list α} : (l₁ : multiset α) ⊆ l₂ ↔ l₁ ⊆ l₂ := iff.rfl

@[simp] theorem subset.refl (s : multiset α) : s ⊆ s := λ a h, h

theorem subset.trans {s t u : multiset α} : s ⊆ t → t ⊆ u → s ⊆ u :=
λ h₁ h₂ a m, h₂ (h₁ m)

theorem subset_iff {s t : multiset α} : s ⊆ t ↔ (∀⦃x⦄, x ∈ s → x ∈ t) := iff.rfl

theorem mem_of_subset {s t : multiset α} {a : α} (h : s ⊆ t) : a ∈ s → a ∈ t := @h _

@[simp] theorem zero_subset (s : multiset α) : 0 ⊆ s :=
λ a, (not_mem_nil a).elim

@[simp] theorem cons_subset {a : α} {s t : multiset α} : (a :: s) ⊆ t ↔ a ∈ t ∧ s ⊆ t :=
by simp [subset_iff, or_imp_distrib, forall_and_distrib]

theorem eq_zero_of_subset_zero {s : multiset α} (h : s ⊆ 0) : s = 0 :=
eq_zero_of_forall_not_mem h

theorem subset_zero {s : multiset α} : s ⊆ 0 ↔ s = 0 :=
⟨eq_zero_of_subset_zero, λ xeq, xeq.symm ▸ subset.refl 0⟩

end subset

/- multiset order -/

protected def le (s t : multiset α) : Prop :=
quotient.lift_on₂ s t (<+~) $ λ v₁ v₂ w₁ w₂ p₁ p₂,
  propext (p₂.subperm_left.trans p₁.subperm_right)

instance : partial_order (multiset α) :=
{ le := multiset.le,
  le_refl := λ s, quot.induction_on s $ λ l, subperm.refl _,
  le_trans := λ s t u, quotient.induction_on₃ s t u $ @subperm.trans _,
  le_antisymm := λ s t, quotient.induction_on₂ s t $
    λ l₁ l₂ h₁ h₂, quot.sound (subperm.antisymm h₁ h₂) }

theorem subset_of_le {s t : multiset α} : s ≤ t → s ⊆ t :=
quotient.induction_on₂ s t $ λ l₁ l₂, subset_of_subperm

theorem mem_of_le {s t : multiset α} {a : α} (h : s ≤ t) : a ∈ s → a ∈ t :=
mem_of_subset (subset_of_le h)

@[simp] theorem coe_le {l₁ l₂ : list α} : (l₁ : multiset α) ≤ l₂ ↔ l₁ <+~ l₂ := iff.rfl

@[elab_as_eliminator] theorem le_induction_on {C : multiset α → multiset α → Prop}
  {s t : multiset α} (h : s ≤ t)
  (H : ∀ {l₁ l₂ : list α}, l₁ <+ l₂ → C l₁ l₂) : C s t :=
quotient.induction_on₂ s t (λ l₁ l₂ ⟨l, p, s⟩,
  (show ⟦l⟧ = ⟦l₁⟧, from quot.sound p) ▸ H s) h

theorem zero_le (s : multiset α) : 0 ≤ s :=
quot.induction_on s $ λ l, subperm_of_sublist $ nil_sublist l

theorem le_zero {s : multiset α} : s ≤ 0 ↔ s = 0 :=
⟨λ h, le_antisymm h (zero_le _), le_of_eq⟩

theorem lt_cons_self (s : multiset α) (a : α) : s < a :: s :=
quot.induction_on s $ λ l,
suffices l <+~ a :: l ∧ (¬l ~ a :: l),
  by simpa [lt_iff_le_and_ne],
⟨subperm_of_sublist (sublist_cons _ _),
 λ p, ne_of_lt (lt_succ_self (length l)) (perm_length p)⟩


theorem le_cons_self (s : multiset α) (a : α) : s ≤ a :: s :=
le_of_lt $ lt_cons_self _ _

theorem cons_le_cons_iff (a : α) {s t : multiset α} : a :: s ≤ a :: t ↔ s ≤ t :=
quotient.induction_on₂ s t $ λ l₁ l₂, subperm_cons a

theorem cons_le_cons (a : α) {s t : multiset α} : s ≤ t → a :: s ≤ a :: t :=
(cons_le_cons_iff a).2

theorem le_cons_of_not_mem {a : α} {s t : multiset α} (m : a ∉ s) : s ≤ a :: t ↔ s ≤ t :=
begin
  refine ⟨_, λ h, le_trans h $ le_cons_self _ _⟩,
  suffices : ∀ {t'} (_ : s ≤ t') (_ : a ∈ t'), a :: s ≤ t',
  { exact λ h, (cons_le_cons_iff a).1 (this h (mem_cons_self _ _)) },
  introv h, revert m, refine le_induction_on h _,
  introv s m₁ m₂,
  rcases mem_split m₂ with ⟨r₁, r₂, rfl⟩,
  exact perm_middle.subperm_left.2 ((subperm_cons _).2 $ subperm_of_sublist $
    (sublist_or_mem_of_sublist s).resolve_right m₁)
end

/- cardinality -/
def card (s : multiset α) : ℕ :=
quot.lift_on s length $ λ l₁ l₂, perm_length

@[simp] theorem coe_card (l : list α) : card (l : multiset α) = length l := rfl

@[simp] theorem card_zero : @card α 0 = 0 := rfl

@[simp] theorem card_cons (a : α) (s : multiset α) : card (a :: s) = card s + 1 :=
quot.induction_on s $ λ l, rfl

theorem card_le_of_le {s t : multiset α} (h : s ≤ t) : card s ≤ card t :=
le_induction_on h $ λ l₁ l₂, length_le_of_sublist

theorem eq_of_le_of_card_le {s t : multiset α} (h : s ≤ t) : card t ≤ card s → s = t :=
le_induction_on h $ λ l₁ l₂ s h₂, congr_arg coe $ eq_of_sublist_of_length_le s h₂

theorem card_lt_of_lt {s t : multiset α} (h : s < t) : card s < card t :=
lt_of_not_ge $ λ h₂, ne_of_lt h $ eq_of_le_of_card_le (le_of_lt h) h₂

theorem lt_iff_cons_le {s t : multiset α} : s < t ↔ ∃ a, a :: s ≤ t :=
⟨quotient.induction_on₂ s t $ λ l₁ l₂ h,
  subperm.exists_of_length_lt (le_of_lt h) (card_lt_of_lt h),
λ ⟨a, h⟩, lt_of_lt_of_le (lt_cons_self _ _) h⟩

@[simp] theorem card_eq_zero {s : multiset α} : card s = 0 ↔ s = 0 :=
⟨λ h, (eq_of_le_of_card_le (zero_le _) (le_of_eq h)).symm, λ e, by simp [e]⟩

theorem card_pos {s : multiset α} : 0 < card s ↔ s ≠ 0 :=
pos_iff_ne_zero.trans $ not_congr card_eq_zero

theorem card_pos_iff_exists_mem {s : multiset α} : 0 < card s ↔ ∃ a, a ∈ s :=
quot.induction_on s $ λ l, length_pos_iff_exists_mem

/- singleton -/
@[simp] theorem mem_singleton {a b : α} : b ∈ a::0 ↔ b = a :=
by simp

theorem mem_singleton_self (a : α) : a ∈ (a::0 : multiset α) := mem_cons_self _ _

theorem singleton_inj {a b : α} : a::0 = b::0 ↔ a = b := cons_inj_left _

@[simp] theorem singleton_ne_zero (a : α) : a::0 ≠ 0 :=
ne_of_gt (lt_cons_self _ _)

@[simp] theorem singleton_le {a : α} {s : multiset α} : a::0 ≤ s ↔ a ∈ s :=
⟨λ h, mem_of_le h (mem_singleton_self _),
 λ h, let ⟨t, e⟩ := exists_cons_of_mem h in e.symm ▸ cons_le_cons _ (zero_le _)⟩

/- add -/
protected def add (s₁ s₂ : multiset α) : multiset α :=
quotient.lift_on₂ s₁ s₂ (λ l₁ l₂, ((l₁ ++ l₂ : list α) : multiset α)) $
  λ v₁ v₂ w₁ w₂ p₁ p₂, quot.sound $ perm_app p₁ p₂

instance : has_add (multiset α) := ⟨multiset.add⟩

@[simp] theorem coe_add (s t : list α) : (s + t : multiset α) = (s ++ t : list α) := rfl

protected theorem add_comm (s t : multiset α) : s + t = t + s :=
quotient.induction_on₂ s t $ λ l₁ l₂, quot.sound perm_app_comm

protected theorem zero_add (s : multiset α) : 0 + s = s :=
quot.induction_on s $ λ l, rfl

theorem singleton_add (a : α) (s : multiset α) : ↑[a] + s = a::s := rfl

protected theorem add_le_add_left (s) {t u : multiset α} : s + t ≤ s + u ↔ t ≤ u :=
quotient.induction_on₃ s t u $ λ l₁ l₂ l₃, subperm_app_left _

protected theorem add_left_cancel (s) {t u : multiset α} (h : s + t = s + u) : t = u :=
le_antisymm ((multiset.add_le_add_left _).1 (le_of_eq h))
  ((multiset.add_le_add_left _).1 (le_of_eq h.symm))

instance : ordered_cancel_comm_monoid (multiset α) :=
{ zero                  := 0,
  add                   := (+),
  add_comm              := multiset.add_comm,
  add_assoc             := λ s₁ s₂ s₃, quotient.induction_on₃ s₁ s₂ s₃ $ λ l₁ l₂ l₃,
    congr_arg coe $ append_assoc l₁ l₂ l₃,
  zero_add              := multiset.zero_add,
  add_zero              := λ s, by rw [multiset.add_comm, multiset.zero_add],
  add_left_cancel       := multiset.add_left_cancel,
  add_right_cancel      := λ s₁ s₂ s₃ h, multiset.add_left_cancel s₂ $
    by simpa [multiset.add_comm] using h,
  add_le_add_left       := λ s₁ s₂ h s₃, (multiset.add_le_add_left _).2 h,
  le_of_add_le_add_left := λ s₁ s₂ s₃, (multiset.add_le_add_left _).1,
  ..@multiset.partial_order α }

@[simp] theorem cons_add (a : α) (s t : multiset α) : a :: s + t = a :: (s + t) :=
by rw [← singleton_add, ← singleton_add, add_assoc]

@[simp] theorem add_cons (a : α) (s t : multiset α) : s + a :: t = a :: (s + t) :=
by rw [add_comm, cons_add, add_comm]

theorem le_add_right (s t : multiset α) : s ≤ s + t :=
by simpa using add_le_add_left (zero_le t) s

theorem le_add_left (s t : multiset α) : s ≤ t + s :=
by simpa using add_le_add_right (zero_le t) s

@[simp] theorem card_add (s t : multiset α) : card (s + t) = card s + card t :=
quotient.induction_on₂ s t length_append

@[simp] theorem mem_add {a : α} {s t : multiset α} : a ∈ s + t ↔ a ∈ s ∨ a ∈ t :=
quotient.induction_on₂ s t $ λ l₁ l₂, mem_append

theorem le_iff_exists_add {s t : multiset α} : s ≤ t ↔ ∃ u, t = s + u :=
⟨λ h, le_induction_on h $ λ l₁ l₂ s,
  let ⟨l, p⟩ := exists_perm_append_of_sublist s in ⟨l, quot.sound p⟩,
λ⟨u, e⟩, e.symm ▸ le_add_right s u⟩

instance : canonically_ordered_monoid (multiset α) :=
{ lt_of_add_lt_add_left := @lt_of_add_lt_add_left _ _,
  le_iff_exists_add     := @le_iff_exists_add _,
  ..multiset.ordered_cancel_comm_monoid }

/- repeat -/
def repeat (a : α) (n : ℕ) : multiset α := repeat a n

@[simp] lemma card_repeat : ∀ (a : α) n, card (repeat a n) = n := length_repeat

theorem eq_of_mem_repeat {a b : α} {n} : b ∈ repeat a n → b = a := eq_of_mem_repeat

theorem eq_repeat' {a : α} {s : multiset α} : s = repeat a s.card ↔ ∀ b ∈ s, b = a :=
quot.induction_on s $ λ l, iff.trans ⟨λ h,
  (perm_repeat.1 $ (quotient.exact h).symm).symm, congr_arg coe⟩ eq_repeat'

theorem eq_repeat_of_mem {a : α} {s : multiset α} : (∀ b ∈ s, b = a) → s = repeat a s.card :=
eq_repeat'.2

theorem eq_repeat {a : α} {n} {s : multiset α} : s = repeat a n ↔ card s = n ∧ ∀ b ∈ s, b = a :=
⟨λ h, h.symm ▸ ⟨card_repeat _ _, λ b, eq_of_mem_repeat⟩,
 λ ⟨e, al⟩, e ▸ eq_repeat_of_mem al⟩

theorem repeat_subset_singleton : ∀ (a : α) n, repeat a n ⊆ a::0 := repeat_subset_singleton

theorem repeat_le_coe {a : α} {n} {l : list α} : repeat a n ≤ l ↔ list.repeat a n <+ l :=
⟨λ ⟨l', p, s⟩, (perm_repeat.1 p.symm).symm ▸ s, subperm_of_sublist⟩

/- range -/
def range (n : ℕ) : multiset ℕ := range n

@[simp] theorem range_zero (n : ℕ) : range 0 = 0 := rfl

@[simp] theorem range_succ (n : ℕ) : range (succ n) = n :: range n :=
by rw [range, range_concat, ← coe_add, add_comm]; refl

@[simp] theorem card_range (n : ℕ) : card (range n) = n := length_range _

theorem range_subset {m n : ℕ} : range m ⊆ range n ↔ m ≤ n := range_subset

@[simp] theorem mem_range {m n : ℕ} : m ∈ range n ↔ m < n := mem_range

@[simp] theorem not_mem_range_self {n : ℕ} : n ∉ range n := not_mem_range_self


/- erase -/
section erase
variables [decidable_eq α] {s t : multiset α} {a b : α}

def erase (s : multiset α) (a : α) : multiset α :=
quot.lift_on s (λ l, (l.erase a : multiset α))
  (λ l₁ l₂ p, quot.sound (erase_perm_erase a p))

@[simp] theorem coe_erase (l : list α) (a : α) :
  erase (l : multiset α) a = l.erase a := rfl

@[simp] theorem erase_zero (a : α) : (0 : multiset α).erase a = 0 := rfl

@[simp] theorem erase_cons_head (a : α) (s : multiset α) : (a :: s).erase a = s :=
quot.induction_on s $ λ l, congr_arg coe $ erase_cons_head a l

@[simp] theorem erase_cons_tail {a b : α} (s : multiset α) (h : b ≠ a) : (b::s).erase a = b :: s.erase a :=
quot.induction_on s $ λ l, congr_arg coe $ erase_cons_tail l h

@[simp] theorem erase_of_not_mem {a : α} {s : multiset α} : a ∉ s → s.erase a = s :=
quot.induction_on s $ λ l h, congr_arg coe $ erase_of_not_mem h

@[simp] theorem cons_erase {s : multiset α} {a : α} : a ∈ s → a :: s.erase a = s :=
quot.induction_on s $ λ l h, quot.sound (perm_erase h).symm

theorem le_cons_erase (s : multiset α) (a : α) : s ≤ a :: s.erase a :=
if h : a ∈ s then le_of_eq (cons_erase h).symm
else by rw erase_of_not_mem h; apply le_cons_self

@[simp] theorem card_erase_of_mem {a : α} {s : multiset α} : a ∈ s → card (s.erase a) = pred (card s) :=
quot.induction_on s $ λ l, length_erase_of_mem

theorem erase_add_left_pos {a : α} {s : multiset α} (t) : a ∈ s → (s + t).erase a = s.erase a + t :=
quotient.induction_on₂ s t $ λ l₁ l₂ h, congr_arg coe $ erase_append_left l₂ h

theorem erase_add_right_pos {a : α} (s) {t : multiset α} (h : a ∈ t) : (s + t).erase a = s + t.erase a :=
by rw [add_comm, erase_add_left_pos s h, add_comm]

theorem erase_add_right_neg {a : α} {s : multiset α} (t) : a ∉ s → (s + t).erase a = s + t.erase a :=
quotient.induction_on₂ s t $ λ l₁ l₂ h, congr_arg coe $ erase_append_right l₂ h

theorem erase_add_left_neg {a : α} (s) {t : multiset α} (h : a ∉ t) : (s + t).erase a = s.erase a + t :=
by rw [add_comm, erase_add_right_neg s h, add_comm]

theorem erase_le (a : α) (s : multiset α) : s.erase a ≤ s :=
quot.induction_on s $ λ l, subperm_of_sublist (erase_sublist a l)

theorem erase_subset (a : α) (s : multiset α) : s.erase a ⊆ s :=
subset_of_le (erase_le a s)

theorem mem_erase_of_ne {a b : α} {s : multiset α} (ab : a ≠ b) : a ∈ s.erase b ↔ a ∈ s :=
quot.induction_on s $ λ l, list.mem_erase_of_ne ab

theorem mem_of_mem_erase {a b : α} {s : multiset α} : a ∈ s.erase b → a ∈ s :=
mem_of_subset (erase_subset _ _)

theorem erase_comm (s : multiset α) (a b : α) : (s.erase a).erase b = (s.erase b).erase a :=
quot.induction_on s $ λ l, congr_arg coe $ l.erase_comm a b

theorem erase_le_erase {s t : multiset α} (a : α) (h : s ≤ t) : s.erase a ≤ t.erase a :=
le_induction_on h $ λ l₁ l₂ h, subperm_of_sublist (erase_sublist_erase _ h)

theorem erase_le_iff_le_cons {s t : multiset α} {a : α} : s.erase a ≤ t ↔ s ≤ a :: t :=
⟨λ h, le_trans (le_cons_erase _ _) (cons_le_cons _ h),
 λ h, if m : a ∈ s
  then by rw ← cons_erase m at h; exact (cons_le_cons_iff _).1 h
  else le_trans (erase_le _ _) ((le_cons_of_not_mem m).1 h)⟩

end erase

@[simp] theorem coe_reverse (l : list α) : (reverse l : multiset α) = l :=
quot.sound $ reverse_perm _

/- map -/
def map (f : α → β) (s : multiset α) : multiset β :=
quot.lift_on s (λ l : list α, (l.map f : multiset β))
  (λ l₁ l₂ p, quot.sound (perm_map f p))

@[simp] theorem coe_map (f : α → β) (l : list α) : map f ↑l = l.map f := rfl

@[simp] theorem map_zero (f : α → β) : map f 0 = 0 := rfl

@[simp] theorem map_cons (f : α → β) (a s) : map f (a::s) = f a :: map f s :=
quot.induction_on s $ λ l, rfl

@[simp] theorem map_add (f : α → β) (s t) : map f (s + t) = map f s + map f t :=
quotient.induction_on₂ s t $ λ l₁ l₂, congr_arg coe $ map_append _ _ _

@[simp] theorem mem_map {f : α → β} {b : β} {s : multiset α} :
  b ∈ map f s ↔ ∃ a, a ∈ s ∧ f a = b :=
quot.induction_on s $ λ l, mem_map

theorem mem_map_of_mem (f : α → β) {a : α} {s : multiset α} (h : a ∈ s) : f a ∈ map f s :=
mem_map.2 ⟨_, h, rfl⟩

@[simp] theorem mem_map_of_inj {f : α → β} (H : function.injective f) {a : α} {s : multiset α} :
  f a ∈ map f s ↔ a ∈ s :=
quot.induction_on s $ λ l, mem_map_of_inj H

@[simp] theorem map_map (g : β → γ) (f : α → β) (s : multiset α) : map g (map f s) = map (g ∘ f) s :=
quot.induction_on s $ λ l, congr_arg coe $ map_map _ _ _

@[simp] theorem map_const (s : multiset α) (b : β) : map (function.const α b) s = repeat b s.card :=
quot.induction_on s $ λ l, congr_arg coe $ map_const _ _

@[congr] theorem map_congr {f g : α → β} {s : multiset α} : (∀ x ∈ s, f x = g x) → map f s = map g s :=
quot.induction_on s $ λ l H, congr_arg coe $ map_congr H

theorem eq_of_mem_map_const {b₁ b₂ : β} {l : list α} (h : b₁ ∈ map (function.const α b₂) l) : b₁ = b₂ :=
eq_of_mem_repeat $ by rwa map_const at h

@[simp] theorem map_le_map {f : α → β} {s t : multiset α} (h : s ≤ t) : map f s ≤ map f t :=
le_induction_on h $ λ l₁ l₂ h, subperm_of_sublist $ map_sublist_map f h

@[simp] theorem map_subset_map {f : α → β} {s t : multiset α} (H : s ⊆ t) : map f s ⊆ map f t :=
λ b m, let ⟨a, h, e⟩ := mem_map.1 m in mem_map.2 ⟨a, H h, e⟩

/- fold -/
def foldl (f : β → α → β) (H : right_commutative f) (b : β) (s : multiset α) : β :=
quot.lift_on s (λ l, foldl f b l)
  (λ l₁ l₂ p, foldl_eq_of_perm H p b)

@[simp] theorem foldl_zero (f : β → α → β) (H b) : foldl f H b 0 = b := rfl

@[simp] theorem foldl_cons (f : β → α → β) (H b a s) : foldl f H b (a :: s) = foldl f H (f b a) s :=
quot.induction_on s $ λ l, rfl

@[simp] theorem foldl_add (f : β → α → β) (H b s t) : foldl f H b (s + t) = foldl f H (foldl f H b s) t :=
quotient.induction_on₂ s t $ λ l₁ l₂, foldl_append _ _ _ _

def foldr (f : α → β → β) (H : left_commutative f) (b : β) (s : multiset α) : β :=
quot.lift_on s (λ l, foldr f b l)
  (λ l₁ l₂ p, foldr_eq_of_perm H p b)

@[simp] theorem foldr_zero (f : α → β → β) (H b) : foldr f H b 0 = b := rfl

@[simp] theorem foldr_cons (f : α → β → β) (H b a s) : foldr f H b (a :: s) = f a (foldr f H b s) :=
quot.induction_on s $ λ l, rfl

@[simp] theorem foldr_add (f : α → β → β) (H b s t) : foldr f H b (s + t) = foldr f H (foldr f H b t) s :=
quotient.induction_on₂ s t $ λ l₁ l₂, foldr_append _ _ _ _

@[simp] theorem coe_foldr (f : α → β → β) (H : left_commutative f) (b : β) (l : list α) :
  foldr f H b l = l.foldr f b := rfl

@[simp] theorem coe_foldl (f : β → α → β) (H : right_commutative f) (b : β) (l : list α) :
  foldl f H b l = l.foldl f b := rfl

theorem coe_foldr_swap (f : α → β → β) (H : left_commutative f) (b : β) (l : list α) :
  foldr f H b l = l.foldl (λ x y, f y x) b :=
(congr_arg (foldr f H b) (coe_reverse l)).symm.trans $ foldr_reverse _ _ _

theorem foldr_swap (f : α → β → β) (H : left_commutative f) (b : β) (s : multiset α) :
  foldr f H b s = foldl (λ x y, f y x) (λ x y z, (H _ _ _).symm) b s :=
quot.induction_on s $ λ l, coe_foldr_swap _ _ _ _

theorem foldl_swap (f : β → α → β) (H : right_commutative f) (b : β) (s : multiset α) :
  foldl f H b s = foldr (λ x y, f y x) (λ x y z, (H _ _ _).symm) b s :=
(foldr_swap _ _ _ _).symm

def prod [comm_monoid α] : multiset α → α :=
foldr (*) (λ x y z, by simp) 1
attribute [to_additive multiset.sum._proof_1] prod._proof_1
attribute [to_additive multiset.sum] prod

@[to_additive multiset.sum_eq_foldr]
theorem prod_eq_foldr [comm_monoid α] (s : multiset α) :
  prod s = foldr (*) (λ x y z, by simp) 1 s := rfl

@[to_additive multiset.sum_eq_foldl]
theorem prod_eq_foldl [comm_monoid α] (s : multiset α) :
  prod s = foldl (*) (λ x y z, by simp) 1 s :=
(foldr_swap _ _ _ _).trans (by simp)

@[simp, to_additive multiset.coe_sum]
theorem coe_prod [comm_monoid α] (l : list α) : prod ↑l = l.prod :=
prod_eq_foldl _

@[simp, to_additive multiset.sum_zero]
theorem prod_zero [comm_monoid α] : @prod α _ 0 = 1 := rfl

@[simp, to_additive multiset.sum_cons]
theorem prod_cons [comm_monoid α] (a : α) (s) : prod (a :: s) = a * prod s :=
foldr_cons _ _ _ _ _

@[simp, to_additive multiset.sum_add]
theorem prod_add [comm_monoid α] (s t : multiset α) : prod (s + t) = prod s * prod t :=
quotient.induction_on₂ s t $ λ l₁ l₂, by simp

@[simp, to_additive multiset.sum_repeat]
theorem prod_repeat [comm_monoid α] (a : α) (n : ℕ) : prod (multiset.repeat a n) = monoid.pow a n :=
by simp [repeat, list.prod_repeat]

/- join -/
def join : multiset (multiset α) → multiset α := sum

theorem coe_join : ∀ L : list (list α),
  join (L.map (@coe _ (multiset α) _) : multiset (multiset α)) = L.join
| []       := rfl
| (l :: L) := congr_arg (λ s : multiset α, ↑l + s) (coe_join L)

@[simp] theorem join_zero : @join α 0 = 0 := rfl

@[simp] theorem join_cons (s S) : @join α (s :: S) = s + join S :=
sum_cons _ _

@[simp] theorem join_add (S T) : @join α (S + T) = join S + join T :=
sum_add _ _

@[simp] theorem mem_join {a S} : a ∈ @join α S ↔ ∃ s ∈ S, a ∈ s :=
multiset.induction_on S (by simp) $
  by simp [and_or_distrib_left, exists_or_distrib] {contextual := tt}

/- bind -/
def bind (s : multiset α) (f : α → multiset β) : multiset β :=
join (map f s)

@[simp] theorem coe_bind (l : list α) (f : α → list β) :
  @bind α β l (λ a, f a) = l.bind f :=
by rw [list.bind, ← coe_join, list.map_map]; refl

@[simp] theorem zero_bind (f : α → multiset β) : bind 0 f = 0 := rfl

@[simp] theorem cons_bind (a s) (f : α → multiset β) : bind (a::s) f = f a + bind s f :=
by simp [bind]

@[simp] theorem add_bind (s t) (f : α → multiset β) : bind (s + t) f = bind s f + bind t f :=
by simp [bind]

@[simp] theorem mem_bind {b s} {f : α → multiset β} : b ∈ bind s f ↔ ∃ a ∈ s, b ∈ f a :=
by simp [bind]; simp [exists_and_distrib_left.symm]; rw exists_swap; simp

/- product -/
def product (s : multiset α) (t : multiset β) : multiset (α × β) :=
s.bind $ λ a, t.map $ prod.mk a

@[simp] theorem coe_product (l₁ : list α) (l₂ : list β) :
  @product α β l₁ l₂ = l₁.product l₂ :=
by rw [product, list.product, ← coe_bind]; simp

@[simp] theorem zero_product (t) : @product α β 0 t = 0 := rfl

@[simp] theorem cons_product (a : α) (s : multiset α) (t : multiset β) :
  product (a :: s) t = map (prod.mk a) t + product s t :=
by simp [product]

@[simp] theorem product_singleton (a : α) (b : β) : product (a::0) (b::0) = (a,b)::0 := rfl

@[simp] theorem add_product (s t : multiset α) (u : multiset β) :
  product (s + t) u = product s u + product t u :=
by simp [product]

@[simp] theorem product_add (s : multiset α) : ∀ t u : multiset β,
  product s (t + u) = product s t + product s u :=
multiset.induction_on s (λ t u, rfl) $ λ a s IH t u,
  by rw [cons_product, IH]; simp

@[simp] theorem mem_product {s t} : ∀ {p : α × β}, p ∈ @product α β s t ↔ p.1 ∈ s ∧ p.2 ∈ t
| (a, b) := by simp [product]

/- sigma -/
section
variable {σ : α → Type*}

protected def sigma (s : multiset α) (t : Π a, multiset (σ a)) : multiset (Σ a, σ a) :=
s.bind $ λ a, (t a).map $ sigma.mk a

@[simp] theorem coe_sigma (l₁ : list α) (l₂ : Π a, list (σ a)) :
  @multiset.sigma α σ l₁ (λ a, l₂ a) = l₁.sigma l₂ :=
by rw [multiset.sigma, list.sigma, ← coe_bind]; simp

@[simp] theorem zero_sigma (t) : @multiset.sigma α σ 0 t = 0 := rfl

@[simp] theorem cons_sigma (a : α) (s : multiset α) (t : Π a, multiset (σ a)) :
  (a :: s).sigma t = map (sigma.mk a) (t a) + s.sigma t :=
by simp [multiset.sigma]

@[simp] theorem sigma_singleton (a : α) (b : α → β) :
  (a::0).sigma (λ a, b a::0) = ⟨a, b a⟩::0 := rfl

@[simp] theorem add_sigma (s t : multiset α) (u : Π a, multiset (σ a)) :
  (s + t).sigma u = s.sigma u + t.sigma u :=
by simp [multiset.sigma]

@[simp] theorem sigma_add (s : multiset α) : ∀ t u : Π a, multiset (σ a),
  s.sigma (λ a, t a + u a) = s.sigma t + s.sigma u :=
multiset.induction_on s (λ t u, rfl) $ λ a s IH t u,
  by rw [cons_sigma, IH]; simp

@[simp] theorem mem_sigma {s t} : ∀ {p : Σ a, σ a},
  p ∈ @multiset.sigma α σ s t ↔ p.1 ∈ s ∧ p.2 ∈ t p.1
| ⟨a, b⟩ := by simp [multiset.sigma]

end

/- map for partial functions -/

@[simp] def pmap {p : α → Prop} (f : Π a, p a → β) (s : multiset α) : (∀ a ∈ s, p a) → multiset β :=
quot.rec_on s (λ l H, ↑(pmap f l H)) $ λ l₁ l₂ (pp : l₁ ~ l₂),
funext $ λ (H₂ : ∀ a ∈ l₂, p a),
have H₁ : ∀ a ∈ l₁, p a, from λ a h, H₂ a ((mem_of_perm pp).1 h),
have ∀ {s₂ e H}, @eq.rec (multiset α) l₁
  (λ s, (∀ a ∈ s, p a) → multiset β) (λ _, ↑(pmap f l₁ H₁))
  s₂ e H = ↑(pmap f l₁ H₁), by intros s₂ e _; subst e,
this.trans $ quot.sound $ perm_pmap f pp

@[simp] theorem coe_pmap {p : α → Prop} (f : Π a, p a → β)
  (l : list α) (H : ∀ a ∈ l, p a) : pmap f l H = l.pmap f H := rfl

def attach (s : multiset α) : multiset {x // x ∈ s} := pmap subtype.mk s (λ a, id)

@[simp] theorem coe_attach (l : list α) :
 @eq (multiset {x // x ∈ l}) (@attach α l) l.attach := rfl

theorem pmap_eq_map (p : α → Prop) (f : α → β) (s : multiset α) :
  ∀ H, @pmap _ _ p (λ a _, f a) s H = map f s :=
quot.induction_on s $ λ l H, congr_arg coe $ pmap_eq_map p f l H

theorem pmap_congr {p q : α → Prop} {f : Π a, p a → β} {g : Π a, q a → β}
  (s : multiset α) {H₁ H₂} (h : ∀ a h₁ h₂, f a h₁ = g a h₂) :
  pmap f s H₁ = pmap g s H₂ :=
quot.induction_on s (λ l H₁ H₂, congr_arg coe $ pmap_congr l h) H₁ H₂

theorem map_pmap {p : α → Prop} (g : β → γ) (f : Π a, p a → β)
  (s) : ∀ H, map g (pmap f s H) = pmap (λ a h, g (f a h)) s H :=
quot.induction_on s $ λ l H, congr_arg coe $ map_pmap g f l H

theorem pmap_eq_map_attach {p : α → Prop} (f : Π a, p a → β)
  (s) : ∀ H, pmap f s H = s.attach.map (λ x, f x.1 (H _ x.2)) :=
quot.induction_on s $ λ l H, congr_arg coe $ pmap_eq_map_attach f l H

theorem attach_map_val (s : multiset α) : s.attach.map subtype.val = s :=
quot.induction_on s $ λ l, congr_arg coe $ attach_map_val l

@[simp] theorem mem_attach (s : multiset α) : ∀ x, x ∈ s.attach :=
quot.induction_on s $ λ l, mem_attach _

@[simp] theorem mem_pmap {p : α → Prop} {f : Π a, p a → β}
  {s H b} : b ∈ pmap f s H ↔ ∃ a (h : a ∈ s), f a (H a h) = b :=
quot.induction_on s (λ l H, mem_pmap) H

/- subtraction -/
section
variables [decidable_eq α] {s t u : multiset α} {a b : α}

protected def sub (s t : multiset α) : multiset α :=
quotient.lift_on₂ s t (λ l₁ l₂, (l₁.diff l₂ : multiset α)) $ λ v₁ v₂ w₁ w₂ p₁ p₂,
  quot.sound $ perm_diff_right w₁ p₂ ▸ perm_diff_left _ p₁

instance : has_sub (multiset α) := ⟨multiset.sub⟩

@[simp] theorem coe_sub (s t : list α) : (s - t : multiset α) = (s.diff t : list α) := rfl

theorem sub_eq_fold_erase (s t : multiset α) : s - t = foldl erase erase_comm s t :=
quotient.induction_on₂ s t $ λ l₁ l₂,
show ↑(l₁.diff l₂) = foldl erase erase_comm ↑l₁ ↑l₂,
by rw diff_eq_foldl l₁ l₂; exact foldl_hom _ _ _ _ (λ x y, rfl) _

@[simp] theorem sub_zero (s : multiset α) : s - 0 = s :=
quot.induction_on s $ λ l, rfl

@[simp] theorem sub_cons (a : α) (s t : multiset α) : s - a::t = s.erase a - t :=
quotient.induction_on₂ s t $ λ l₁ l₂, congr_arg coe $ diff_cons _ _ _

theorem add_sub_of_le (h : s ≤ t) : s + (t - s) = t :=
begin
  revert t,
  refine multiset.induction_on s (by simp) (λ a s IH t h, _),
  have := cons_erase (mem_of_le h (mem_cons_self _ _)),
  rw [cons_add, sub_cons, IH, this],
  exact (cons_le_cons_iff a).1 (this.symm ▸ h)
end

theorem sub_add' : s - (t + u) = s - t - u :=
quotient.induction_on₃ s t u $
λ l₁ l₂ l₃, congr_arg coe $ diff_append _ _ _

theorem sub_add_cancel (h : t ≤ s) : s - t + t = s :=
by rw [add_comm, add_sub_of_le h]

theorem add_sub_cancel_left (s : multiset α) : ∀ t, s + t - s = t :=
multiset.induction_on s (by simp)
  (λ a s IH t, by rw [cons_add, sub_cons, erase_cons_head, IH])

theorem add_sub_cancel (s t : multiset α) : s + t - t = s :=
by rw [add_comm, add_sub_cancel_left]

theorem sub_le_sub_right (h : s ≤ t) (u) : s - u ≤ t - u :=
by revert s t h; exact
multiset.induction_on u (by simp {contextual := tt})
  (λ a u IH s t h, by simp [IH, erase_le_erase a h])

theorem sub_le_sub_left (h : s ≤ t) : ∀ u, u - t ≤ u - s :=
le_induction_on h $ λ l₁ l₂ h, begin
  induction h with l₁ l₂ a s IH l₁ l₂ a s IH; intro u,
  { refl },
  { rw [← cons_coe, sub_cons],
    exact le_trans (sub_le_sub_right (erase_le _ _) _) (IH u) },
  { rw [← cons_coe, sub_cons, ← cons_coe, sub_cons],
    exact IH _ }
end

theorem sub_le_iff_le_add : s - t ≤ u ↔ s ≤ u + t :=
by revert s; exact
multiset.induction_on t (by simp)
  (λ a t IH s, by simp [IH, erase_le_iff_le_cons])

theorem le_sub_add (s t : multiset α) : s ≤ s - t + t :=
sub_le_iff_le_add.1 (le_refl _)

theorem sub_le_self (s t : multiset α) : s - t ≤ s :=
sub_le_iff_le_add.2 (le_add_right _ _)

@[simp] theorem card_sub {s t : multiset α} (h : t ≤ s) : card (s - t) = card s - card t :=
(nat.sub_eq_of_eq_add $ by rw [add_comm, ← card_add, sub_add_cancel h]).symm

/- union -/
def union (s t : multiset α) : multiset α := s - t + t

instance : has_union (multiset α) := ⟨union⟩

theorem union_def (s t : multiset α) : s ∪ t = s - t + t := rfl

theorem le_union_left (s t : multiset α) : s ≤ s ∪ t := le_sub_add _ _

theorem le_union_right (s t : multiset α) : t ≤ s ∪ t := le_add_left _ _

theorem eq_union_left : t ≤ s → s ∪ t = s := sub_add_cancel

theorem union_le_union_right (h : s ≤ t) (u) : s ∪ u ≤ t ∪ u :=
add_le_add_right (sub_le_sub_right h _) u

theorem union_le (h₁ : s ≤ u) (h₂ : t ≤ u) : s ∪ t ≤ u :=
by rw ← eq_union_left h₂; exact union_le_union_right h₁ t

@[simp] theorem mem_union : a ∈ s ∪ t ↔ a ∈ s ∨ a ∈ t :=
⟨λ h, (mem_add.1 h).imp_left (mem_of_le $ sub_le_self _ _),
 or.rec (mem_of_le $ le_union_left _ _) (mem_of_le $ le_union_right _ _)⟩

/- inter -/
def inter (s t : multiset α) : multiset α :=
quotient.lift_on₂ s t (λ l₁ l₂, (l₁.bag_inter l₂ : multiset α)) $ λ v₁ v₂ w₁ w₂ p₁ p₂,
  quot.sound $ perm_bag_inter_right w₁ p₂ ▸ perm_bag_inter_left _ p₁

instance : has_inter (multiset α) := ⟨inter⟩

@[simp] theorem inter_zero (s : multiset α) : s ∩ 0 = 0 :=
quot.induction_on s $ λ l, congr_arg coe l.bag_inter_nil

@[simp] theorem zero_inter (s : multiset α) : 0 ∩ s = 0 :=
quot.induction_on s $ λ l, congr_arg coe l.nil_bag_inter

@[simp] theorem cons_inter_of_pos {a} (s : multiset α) {t} :
  a ∈ t → (a :: s) ∩ t = a :: s ∩ t.erase a :=
quotient.induction_on₂ s t $ λ l₁ l₂ h,
congr_arg coe $ cons_bag_inter_of_pos _ h

@[simp] theorem cons_inter_of_neg {a} (s : multiset α) {t} :
  a ∉ t → (a :: s) ∩ t = s ∩ t :=
quotient.induction_on₂ s t $ λ l₁ l₂ h,
congr_arg coe $ cons_bag_inter_of_neg _ h

theorem inter_le_left (s t : multiset α) : s ∩ t ≤ s :=
quotient.induction_on₂ s t $ λ l₁ l₂,
subperm_of_sublist $ bag_inter_sublist_left _ _

theorem inter_le_right (s : multiset α) : ∀ t, s ∩ t ≤ t :=
multiset.induction_on s (λ t, (zero_inter t).symm ▸ zero_le _) $
λ a s IH t, if h : a ∈ t
  then by simpa [h] using cons_le_cons a (IH (t.erase a))
  else by simp [h, IH]

theorem le_inter (h₁ : s ≤ t) (h₂ : s ≤ u) : s ≤ t ∩ u :=
begin
  revert s u, refine multiset.induction_on t _ (λ a t IH, _); intros,
  { simp [h₁] },
  by_cases a ∈ u,
  { rw [cons_inter_of_pos _ h, ← erase_le_iff_le_cons],
    exact IH (erase_le_iff_le_cons.2 h₁) (erase_le_erase _ h₂) },
  { rw cons_inter_of_neg _ h,
    exact IH ((le_cons_of_not_mem $ mt (mem_of_le h₂) h).1 h₁) h₂ }
end

@[simp] theorem mem_inter : a ∈ s ∩ t ↔ a ∈ s ∧ a ∈ t :=
⟨λ h, ⟨mem_of_le (inter_le_left _ _) h, mem_of_le (inter_le_right _ _) h⟩,
 λ ⟨h₁, h₂⟩, by rw [← cons_erase h₁, cons_inter_of_pos _ h₂]; apply mem_cons_self⟩

instance : lattice (multiset α) :=
{ sup          := (∪),
  sup_le       := @union_le _ _,
  le_sup_left  := le_union_left,
  le_sup_right := le_union_right,
  inf          := (∩),
  le_inf       := @le_inter _ _,
  inf_le_left  := inter_le_left,
  inf_le_right := inter_le_right,
  ..@multiset.partial_order α }

@[simp] theorem sup_eq_union (s t : multiset α) : s ⊔ t = s ∪ t := rfl
@[simp] theorem inf_eq_inter (s t : multiset α) : s ⊓ t = s ∩ t := rfl

@[simp] theorem le_inter_iff : s ≤ t ∩ u ↔ s ≤ t ∧ s ≤ u := le_inf_iff
@[simp] theorem union_le_iff : s ∪ t ≤ u ↔ s ≤ u ∧ t ≤ u := sup_le_iff

instance : semilattice_inf_bot (multiset α) :=
{ bot := 0, bot_le := zero_le, ..multiset.lattice.lattice }

theorem union_comm (s t : multiset α) : s ∪ t = t ∪ s := sup_comm
theorem inter_comm (s t : multiset α) : s ∩ t = t ∩ s := inf_comm

theorem eq_union_right (h : s ≤ t) : s ∪ t = t :=
by rw [union_comm, eq_union_left h]

theorem union_le_union_left (h : s ≤ t) (u) : u ∪ s ≤ u ∪ t :=
sup_le_sup_left h _

theorem union_le_add (s t : multiset α) : s ∪ t ≤ s + t :=
union_le (le_add_right _ _) (le_add_left _ _)

theorem union_add_distrib (s t u : multiset α) : (s ∪ t) + u = (s + u) ∪ (t + u) :=
by simpa [(∪), union, eq_comm] using show s + u - (t + u) = s - t,
by rw [add_comm t, sub_add', add_sub_cancel]

theorem add_union_distrib (s t u : multiset α) : s + (t ∪ u) = (s + t) ∪ (s + u) :=
by rw [add_comm, union_add_distrib, add_comm s, add_comm s]

theorem cons_union_distrib (a : α) (s t : multiset α) : a :: (s ∪ t) = (a :: s) ∪ (a :: t) :=
by simpa using add_union_distrib (a::0) s t

theorem inter_add_distrib (s t u : multiset α) : (s ∩ t) + u = (s + u) ∩ (t + u) :=
begin
  by_contra h,
  cases lt_iff_cons_le.1 (lt_of_le_of_ne (le_inter
    (add_le_add_right (inter_le_left s t) u)
    (add_le_add_right (inter_le_right s t) u)) h) with a hl,
  rw ← cons_add at hl,
  exact not_le_of_lt (lt_cons_self (s ∩ t) a) (le_inter
    (le_of_add_le_add_right (le_trans hl (inter_le_left _ _)))
    (le_of_add_le_add_right (le_trans hl (inter_le_right _ _))))
end

theorem add_inter_distrib (s t u : multiset α) : s + (t ∩ u) = (s + t) ∩ (s + u) :=
by rw [add_comm, inter_add_distrib, add_comm s, add_comm s]

theorem cons_inter_distrib (a : α) (s t : multiset α) : a :: (s ∩ t) = (a :: s) ∩ (a :: t) :=
by simp

theorem union_add_inter (s t : multiset α) : s ∪ t + s ∩ t = s + t :=
begin
  apply le_antisymm,
  { rw union_add_distrib,
    refine union_le (add_le_add_left (inter_le_right _ _) _) _,
    rw add_comm, exact add_le_add_right (inter_le_left _ _) _ },
  { rw [add_comm, add_inter_distrib],
    refine le_inter (add_le_add_right (le_union_right _ _) _) _,
    rw add_comm, exact add_le_add_right (le_union_left _ _) _ }
end

theorem sub_add_inter (s t : multiset α) : s - t + s ∩ t = s :=
begin
  rw [inter_comm],
  revert s, refine multiset.induction_on t (by simp) (λ a t IH s, _),
  by_cases a ∈ s,
  { rw [cons_inter_of_pos _ h, sub_cons, add_cons, IH, cons_erase h] },
  { rw [cons_inter_of_neg _ h, sub_cons, erase_of_not_mem h, IH] }
end

theorem sub_inter (s t : multiset α) : s - (s ∩ t) = s - t :=
add_right_cancel $
by rw [sub_add_inter s t, sub_add_cancel (inter_le_left _ _)]

end


/- filter -/
section
variables {p : α → Prop} [decidable_pred p]

def filter (p : α → Prop) [h : decidable_pred p] (s : multiset α) : multiset α :=
quot.lift_on s (λ l, (filter p l : multiset α))
  (λ l₁ l₂ h, quot.sound $ perm_filter p h)

@[simp] theorem coe_filter (p : α → Prop) [h : decidable_pred p]
  (l : list α) : filter p (↑l) = l.filter p := rfl

@[simp] theorem filter_zero (p : α → Prop) [h : decidable_pred p] : filter p 0 = 0 := rfl

@[simp] theorem filter_cons_of_pos {a : α} (s) : p a → filter p (a::s) = a :: filter p s :=
quot.induction_on s $ λ l h, congr_arg coe $ filter_cons_of_pos l h

@[simp] theorem filter_cons_of_neg {a : α} (s) : ¬ p a → filter p (a::s) = filter p s :=
quot.induction_on s $ λ l h, @congr_arg _ _ _ _ coe $ filter_cons_of_neg l h

@[simp] theorem filter_add (s t : multiset α) :
  filter p (s + t) = filter p s + filter p t :=
quotient.induction_on₂ s t $ λ l₁ l₂, congr_arg coe $ filter_append _ _

@[simp] theorem filter_le (s : multiset α) : filter p s ≤ s :=
quot.induction_on s $ λ l, subperm_of_sublist $ filter_sublist _

@[simp] theorem filter_subset (s : multiset α) : filter p s ⊆ s :=
subset_of_le $ filter_le _

@[simp] theorem mem_filter {a : α} {s} : a ∈ filter p s ↔ a ∈ s ∧ p a :=
quot.induction_on s $ λ l, mem_filter

theorem of_mem_filter {a : α} {s} (h : a ∈ filter p s) : p a :=
(mem_filter.1 h).2

theorem mem_of_mem_filter {a : α} {s} (h : a ∈ filter p s) : a ∈ s :=
(mem_filter.1 h).1

theorem mem_filter_of_mem {a : α} {l} (m : a ∈ l) (h : p a) : a ∈ filter p l :=
mem_filter.2 ⟨m, h⟩

theorem filter_eq_self {s} : filter p s = s ↔ ∀ a ∈ s, p a :=
quot.induction_on s $ λ l, iff.trans ⟨λ h,
  eq_of_sublist_of_length_eq (filter_sublist _) (@congr_arg _ _ _ _ card h),
  congr_arg coe⟩ filter_eq_self

theorem filter_eq_nil {s} : filter p s = 0 ↔ ∀ a ∈ s, ¬p a :=
quot.induction_on s $ λ l, iff.trans ⟨λ h,
  eq_nil_of_length_eq_zero (@congr_arg _ _ _ _ card h),
  congr_arg coe⟩ filter_eq_nil

theorem filter_le_filter {s t} (h : s ≤ t) : filter p s ≤ filter p t :=
le_induction_on h $ λ l₁ l₂ h, subperm_of_sublist $ filter_sublist_filter h

theorem le_filter {s t} : s ≤ filter p t ↔ s ≤ t ∧ ∀ a ∈ s, p a :=
⟨λ h, ⟨le_trans h (filter_le _), λ a m, of_mem_filter (mem_of_le h m)⟩,
 λ ⟨h, al⟩, filter_eq_self.2 al ▸ filter_le_filter h⟩

@[simp] theorem filter_sub [decidable_eq α] (s t : multiset α) :
  filter p (s - t) = filter p s - filter p t :=
begin
  revert s, refine multiset.induction_on t (by simp) (λ a t IH s, _),
  rw [sub_cons, IH],
  by_cases p a,
  { rw [filter_cons_of_pos _ h, sub_cons], congr,
    by_cases a ∈ s with m,
    { rw [← cons_inj_right a, ← filter_cons_of_pos _ h,
          cons_erase (mem_filter_of_mem m h), cons_erase m] },
    { rw [erase_of_not_mem m, erase_of_not_mem (mt mem_of_mem_filter m)] } },
  { rw [filter_cons_of_neg _ h],
    by_cases a ∈ s with m,
    { rw [(by rw filter_cons_of_neg _ h : filter p (erase s a) = filter p (a :: erase s a)),
          cons_erase m] },
    { rw [erase_of_not_mem m] } }
end

@[simp] theorem filter_union [decidable_eq α] (s t : multiset α) :
  filter p (s ∪ t) = filter p s ∪ filter p t :=
by simp [(∪), union]

@[simp] theorem filter_inter [decidable_eq α] (s t : multiset α) :
  filter p (s ∩ t) = filter p s ∩ filter p t :=
le_antisymm (le_inter
    (filter_le_filter $ inter_le_left _ _)
    (filter_le_filter $ inter_le_right _ _)) $ le_filter.2
⟨inf_le_inf (filter_le _) (filter_le _),
  λ a h, of_mem_filter (mem_of_le (inter_le_left _ _) h)⟩

/- filter_map -/

def filter_map (f : α → option β) (s : multiset α) : multiset β :=
quot.lift_on s (λ l, (filter_map f l : multiset β))
  (λ l₁ l₂ h, quot.sound $perm_filter_map f h)

@[simp] theorem coe_filter_map (f : α → option β) (l : list α) : filter_map f l = l.filter_map f := rfl

@[simp] theorem filter_map_zero (f : α → option β) : filter_map f 0 = 0 := rfl

@[simp] theorem filter_map_cons_none {f : α → option β} (a : α) (s : multiset α) (h : f a = none) :
  filter_map f (a :: s) = filter_map f s :=
quot.induction_on s $ λ l, @congr_arg _ _ _ _ coe $ filter_map_cons_none a l h

@[simp] theorem filter_map_cons_some (f : α → option β)
  (a : α) (s : multiset α) {b : β} (h : f a = some b) :
  filter_map f (a :: s) = b :: filter_map f s :=
quot.induction_on s $ λ l, @congr_arg _ _ _ _ coe $ filter_map_cons_some f a l h

theorem filter_map_eq_map (f : α → β) : filter_map (some ∘ f) = map f :=
funext $ λ s, quot.induction_on s $ λ l,
@congr_arg _ _ _ _ coe $ congr_fun (filter_map_eq_map f) l

theorem filter_map_eq_filter (p : α → Prop) [decidable_pred p] :
  filter_map (option.guard p) = filter p :=
funext $ λ s, quot.induction_on s $ λ l,
@congr_arg _ _ _ _ coe $ congr_fun (filter_map_eq_filter p) l

theorem filter_map_filter_map (f : α → option β) (g : β → option γ) (s : multiset α) :
  filter_map g (filter_map f s) = filter_map (λ x, (f x).bind g) s :=
quot.induction_on s $ λ l, congr_arg coe $ filter_map_filter_map f g l

theorem map_filter_map (f : α → option β) (g : β → γ) (s : multiset α) :
  map g (filter_map f s) = filter_map (λ x, (f x).map g) s :=
quot.induction_on s $ λ l, congr_arg coe $ map_filter_map f g l

theorem filter_map_map (f : α → β) (g : β → option γ) (s : multiset α) :
  filter_map g (map f s) = filter_map (g ∘ f) s :=
quot.induction_on s $ λ l, congr_arg coe $ filter_map_map f g l

theorem filter_filter_map (f : α → option β) (p : β → Prop) [decidable_pred p] (s : multiset α) :
  filter p (filter_map f s) = filter_map (λ x, (f x).filter p) s :=
quot.induction_on s $ λ l, congr_arg coe $ filter_filter_map f p l

theorem filter_map_filter (p : α → Prop) [decidable_pred p] (f : α → option β) (s : multiset α) :
  filter_map f (filter p s) = filter_map (λ x, if p x then f x else none) s :=
quot.induction_on s $ λ l, congr_arg coe $ filter_map_filter p f l

@[simp] theorem filter_map_some (s : multiset α) : filter_map some s = s :=
quot.induction_on s $ λ l, congr_arg coe $ filter_map_some l

@[simp] theorem mem_filter_map (f : α → option β) (s : multiset α) {b : β} :
  b ∈ filter_map f s ↔ ∃ a, a ∈ s ∧ f a = some b :=
quot.induction_on s $ λ l, mem_filter_map f l

theorem map_filter_map_of_inv (f : α → option β) (g : β → α)
  (H : ∀ x : α, (f x).map g = some x) (s : multiset α) :
  map g (filter_map f s) = s :=
quot.induction_on s $ λ l, congr_arg coe $ map_filter_map_of_inv f g H l

theorem filter_map_le_filter_map (f : α → option β) {s t : multiset α}
  (h : s ≤ t) : filter_map f s ≤ filter_map f t :=
le_induction_on h $ λ l₁ l₂ h,
subperm_of_sublist $ filter_map_sublist_filter_map _ h

/- countp -/

def countp (p : α → Prop) [decidable_pred p] (s : multiset α) : ℕ :=
quot.lift_on s (countp p) (λ l₁ l₂, perm_countp p)

@[simp] theorem coe_countp (l : list α) : countp p l = l.countp p := rfl

@[simp] theorem countp_zero (p : α → Prop) [decidable_pred p] : countp p 0 = 0 := rfl

@[simp] theorem countp_cons_of_pos {a : α} (s) : p a → countp p (a::s) = countp p s + 1 :=
quot.induction_on s countp_cons_of_pos

@[simp] theorem countp_cons_of_neg {a : α} (s) : ¬ p a → countp p (a::s) = countp p s :=
quot.induction_on s countp_cons_of_neg

theorem countp_eq_card_filter (s) : countp p s = card (filter p s) :=
quot.induction_on s $ λ l, countp_eq_length_filter _

@[simp] theorem countp_add (s t) : countp p (s + t) = countp p s + countp p t :=
by simp [countp_eq_card_filter]

theorem countp_pos {s} : 0 < countp p s ↔ ∃ a ∈ s, p a :=
by simp [countp_eq_card_filter, card_pos_iff_exists_mem]

@[simp] theorem countp_sub [decidable_eq α] {s t : multiset α} (h : t ≤ s) :
  countp p (s - t) = countp p s - countp p t :=
by simp [countp_eq_card_filter, h, filter_le_filter]

theorem countp_pos_of_mem {s a} (h : a ∈ s) (pa : p a) : 0 < countp p s :=
countp_pos.2 ⟨_, h, pa⟩

theorem countp_le_of_le {s t} (h : s ≤ t) : countp p s ≤ countp p t :=
by simpa [countp_eq_card_filter] using card_le_of_le (filter_le_filter h)
end

/- count -/

section
variable [decidable_eq α]

def count (a : α) : multiset α → ℕ := countp (eq a)

@[simp] theorem coe_count (a : α) (l : list α) : count a (↑l) = l.count a := coe_countp _

@[simp] theorem count_zero (a : α) : count a 0 = 0 := rfl

@[simp] theorem count_cons_self (a : α) (s : multiset α) : count a (a::s) = succ (count a s) :=
countp_cons_of_pos _ rfl

@[simp] theorem count_cons_of_ne {a b : α} (h : a ≠ b) (s : multiset α) : count a (b::s) = count a s :=
countp_cons_of_neg _ h

theorem count_le_of_le (a : α) {s t} : s ≤ t → count a s ≤ count a t :=
countp_le_of_le

theorem count_le_count_cons (a b : α) (s : multiset α) : count a s ≤ count a (b :: s) :=
count_le_of_le _ (le_cons_self _ _)

theorem count_singleton (a : α) : count a (a::0) = 1 :=
by simp

@[simp] theorem count_add (a : α) : ∀ s t, count a (s + t) = count a s + count a t :=
countp_add

@[simp] theorem count_smul (a : α) (s n) : count a (s • n) = count a s * n :=
by induction n; simp [*, smul_succ', mul_succ]

theorem count_pos {a : α} {s : multiset α} : 0 < count a s ↔ a ∈ s :=
by simp [count, countp_pos]

@[simp] theorem count_eq_zero_of_not_mem {a : α} {l : list α} (h : a ∉ l) : count a l = 0 :=
by_contradiction $ λ h', h $ count_pos.1 (nat.pos_of_ne_zero h')

theorem count_eq_zero {a : α} {s : multiset α} : count a s = 0 ↔ a ∉ s :=
iff_not_comm.1 $ count_pos.symm.trans pos_iff_ne_zero

@[simp] theorem count_repeat (a : α) (n : ℕ) : count a (repeat a n) = n :=
by simp [repeat]

@[simp] theorem count_erase_self (a : α) (s : multiset α) : count a (erase s a) = pred (count a s) :=
begin
  by_cases a ∈ s,
  { rw [(by rw cons_erase h : count a s = count a (a::erase s a)),
        count_cons_self]; refl },
  { rw [erase_of_not_mem h, count_eq_zero.2 h]; refl }
end

@[simp] theorem count_erase_of_ne {a b : α} (ab : a ≠ b) (s : multiset α) : count a (erase s b) = count a s :=
begin
  by_cases b ∈ s,
  { rw [← count_cons_of_ne ab, cons_erase h] },
  { rw [erase_of_not_mem h] }
end

@[simp] theorem count_sub (a : α) (s t : multiset α) : count a (s - t) = count a s - count a t :=
begin
  revert s, refine multiset.induction_on t (by simp) (λ b t IH s, _),
  rw [sub_cons, IH],
  by_cases a = b with ab,
  { subst b, rw [count_erase_self, count_cons_self, sub_succ, pred_sub] },
  { rw [count_erase_of_ne ab, count_cons_of_ne ab] }
end

@[simp] theorem count_union (a : α) (s t : multiset α) : count a (s ∪ t) = max (count a s) (count a t) :=
by simp [(∪), union, sub_add_eq_max, -add_comm]

@[simp] theorem count_inter (a : α) (s t : multiset α) : count a (s ∩ t) = min (count a s) (count a t) :=
begin
  apply @nat.add_left_cancel (count a (s - t)),
  rw [← count_add, sub_add_inter, count_sub, sub_add_min],
end

theorem le_count_iff_repeat_le {a : α} {s : multiset α} {n : ℕ} : n ≤ count a s ↔ repeat a n ≤ s :=
quot.induction_on s $ λ l, le_count_iff_repeat_sublist.trans repeat_le_coe.symm

theorem ext {s t : multiset α} : s = t ↔ ∀ a, count a s = count a t :=
quotient.induction_on₂ s t $ λ l₁ l₂, quotient.eq.trans perm_iff_count

theorem le_iff_count {s t : multiset α} : s ≤ t ↔ ∀ a, count a s ≤ count a t :=
⟨λ h a, count_le_of_le a h, λ al,
 by rw ← (ext.2 (λ a, by simp [max_eq_right (al a)]) : s ∪ t = t);
    apply le_union_left⟩

instance : distrib_lattice (multiset α) :=
{ le_sup_inf := λ s t u, le_of_eq $ eq.symm $
    ext.2 $ λ a, by simp [max_min_distrib_left],
  ..multiset.lattice.lattice }
end

/- disjoint -/
def disjoint (s t : multiset α) : Prop := ∀ ⦃a⦄, a ∈ s → a ∈ t → false

@[simp] theorem coe_disjoint (l₁ l₂ : list α) : @disjoint α l₁ l₂ ↔ l₁.disjoint l₂ := iff.rfl

theorem disjoint.symm {s t : multiset α} (d : disjoint s t) : disjoint t s
| a i₂ i₁ := d i₁ i₂

@[simp] theorem disjoint_comm {s t : multiset α} : disjoint s t ↔ disjoint t s :=
⟨disjoint.symm, disjoint.symm⟩

theorem disjoint_left {s t : multiset α} : disjoint s t ↔ ∀ {a}, a ∈ s → a ∉ t := iff.rfl

theorem disjoint_right {s t : multiset α} : disjoint s t ↔ ∀ {a}, a ∈ t → a ∉ s :=
disjoint_comm

theorem disjoint_iff_ne {s t : multiset α} : disjoint s t ↔ ∀ a ∈ s, ∀ b ∈ t, a ≠ b :=
by simp [disjoint_left, imp_not_comm]

theorem disjoint_of_subset_left {s t u : multiset α} (h : s ⊆ u) (d : disjoint u t) : disjoint s t
| x m₁ := d (h m₁)

theorem disjoint_of_subset_right {s t u : multiset α} (h : t ⊆ u) (d : disjoint s u) : disjoint s t
| x m m₁ := d m (h m₁)

theorem disjoint_of_le_left {s t u : multiset α} (h : s ≤ u) : disjoint u t → disjoint s t :=
disjoint_of_subset_left (subset_of_le h)

theorem disjoint_of_le_right {s t u : multiset α} (h : t ≤ u) : disjoint s u → disjoint s t :=
disjoint_of_subset_right (subset_of_le h)

@[simp] theorem zero_disjoint (l : multiset α) : disjoint 0 l
| a := (not_mem_nil a).elim

@[simp] theorem singleton_disjoint {l : multiset α} {a : α} : disjoint (a::0) l ↔ a ∉ l :=
by simp [disjoint]; refl

@[simp] theorem disjoint_singleton {l : multiset α} {a : α} : disjoint l (a::0) ↔ a ∉ l :=
by rw disjoint_comm; simp

@[simp] theorem disjoint_add_left {s t u : multiset α} :
  disjoint (s + t) u ↔ disjoint s u ∧ disjoint t u :=
by simp [disjoint, or_imp_distrib, forall_and_distrib]

@[simp] theorem disjoint_add_right {s t u : multiset α} :
  disjoint s (t + u) ↔ disjoint s t ∧ disjoint s u :=
disjoint_comm.trans $ by simp [disjoint_append_left]

@[simp] theorem disjoint_cons_left {a : α} {s t : multiset α} :
  disjoint (a::s) t ↔ a ∉ t ∧ disjoint s t :=
(@disjoint_add_left _ (a::0) s t).trans $ by simp

@[simp] theorem disjoint_cons_right {a : α} {s t : multiset α} :
  disjoint s (a::t) ↔ a ∉ s ∧ disjoint s t :=
disjoint_comm.trans $ by simp [disjoint_cons_left]

theorem inter_eq_zero_iff_disjoint [decidable_eq α] {s t : multiset α} : s ∩ t = 0 ↔ disjoint s t :=
by rw ← subset_zero; simp [subset_iff, disjoint]

/- nodup -/
def nodup (s : multiset α) : Prop :=
quot.lift_on s nodup (λ s t p, propext $ perm_nodup p)

@[simp] theorem coe_nodup {l : list α} : @nodup α l ↔ l.nodup := iff.rfl

@[simp] theorem forall_mem_ne {a : α} {l : list α} : (∀ (a' : α), a' ∈ l → ¬a = a') ↔ a ∉ l :=
⟨λ h m, h _ m rfl, λ h a' m e, h (e.symm ▸ m)⟩

@[simp] theorem nodup_zero : @nodup α 0 := pairwise.nil _

@[simp] theorem nodup_cons {a : α} {s : multiset α} : nodup (a::s) ↔ a ∉ s ∧ nodup s :=
quot.induction_on s $ λ l, nodup_cons

theorem nodup_cons_of_nodup {a : α} {s : multiset α} (m : a ∉ s) (n : nodup s) : nodup (a::s) :=
nodup_cons.2 ⟨m, n⟩

theorem nodup_singleton : ∀ a : α, nodup (a::0) := nodup_singleton

theorem nodup_of_nodup_cons {a : α} {s : multiset α} (h : nodup (a::s)) : nodup s :=
(nodup_cons.1 h).2

theorem not_mem_of_nodup_cons {a : α} {s : multiset α} (h : nodup (a::s)) : a ∉ s :=
(nodup_cons.1 h).1

theorem nodup_of_le {s t : multiset α} (h : s ≤ t) : nodup t → nodup s :=
le_induction_on h $ λ l₁ l₂, nodup_of_sublist

theorem not_nodup_pair : ∀ a : α, ¬ nodup (a::a::0) := not_nodup_pair

theorem nodup_iff_le {s : multiset α} : nodup s ↔ ∀ a : α, ¬ a::a::0 ≤ s :=
quot.induction_on s $ λ l, nodup_iff_sublist.trans $ forall_congr $ λ a,
not_congr (@repeat_le_coe _ a 2 _).symm

theorem nodup_iff_count_le_one [decidable_eq α] {s : multiset α} : nodup s ↔ ∀ a, count a s ≤ 1 :=
quot.induction_on s $ λ l, nodup_iff_count_le_one

@[simp] theorem count_eq_one_of_mem [decidable_eq α] {a : α} {s : multiset α}
  (d : nodup s) (h : a ∈ s) : count a s = 1 :=
le_antisymm (nodup_iff_count_le_one.1 d a) (count_pos.2 h)

theorem nodup_add {s t : multiset α} : nodup (s + t) ↔ nodup s ∧ nodup t ∧ disjoint s t :=
quotient.induction_on₂ s t $ λ l₁ l₂, nodup_append

theorem disjoint_of_nodup_add {s t : multiset α} (d : nodup (s + t)) : disjoint s t :=
(nodup_add.1 d).2.2

theorem nodup_add_of_nodup {s t : multiset α} (d₁ : nodup s) (d₂ : nodup t) : nodup (s + t) ↔ disjoint s t :=
by simp [nodup_add, d₁, d₂]

theorem nodup_of_nodup_map (f : α → β) {s : multiset α} : nodup (map f s) → nodup s :=
quot.induction_on s $ λ l, nodup_of_nodup_map f

theorem nodup_map_on {f : α → β} {s : multiset α} : (∀x∈s, ∀y∈s, f x = f y → x = y) →
  nodup s → nodup (map f s) :=
quot.induction_on s $ λ l, nodup_map_on

theorem nodup_map {f : α → β} {s : multiset α} (hf : function.injective f) : nodup s → nodup (map f s) :=
nodup_map_on (λ x _ y _ h, hf h)

theorem nodup_filter (p : α → Prop) [decidable_pred p] {s} : nodup s → nodup (filter p s) :=
quot.induction_on s $ λ l, nodup_filter p

@[simp] theorem nodup_attach {s : multiset α} : nodup (attach s) ↔ nodup s :=
quot.induction_on s $ λ l, nodup_attach

theorem nodup_pmap {p : α → Prop} {f : Π a, p a → β} {s : multiset α} {H}
  (hf : ∀ a ha b hb, f a ha = f b hb → a = b) : nodup s → nodup (pmap f s H) :=
quot.induction_on s (λ l H, nodup_pmap hf) H

instance nodup_decidable [decidable_eq α] (s : multiset α) : decidable (nodup s) :=
quotient.rec_on_subsingleton s $ λ l, l.nodup_decidable

theorem nodup_erase_eq_filter [decidable_eq α] (a : α) {s} : nodup s → s.erase a = filter (≠ a) s :=
quot.induction_on s $ λ l d, congr_arg coe $ nodup_erase_eq_filter a d

theorem nodup_erase_of_nodup [decidable_eq α] (a : α) {l} : nodup l → nodup (l.erase a) :=
nodup_of_le (erase_le _ _)

theorem mem_erase_iff_of_nodup [decidable_eq α] {a b : α} {l} (d : nodup l) :
  a ∈ l.erase b ↔ a ≠ b ∧ a ∈ l :=
by rw nodup_erase_eq_filter b d; simp

theorem mem_erase_of_nodup [decidable_eq α] {a : α} {l} (h : nodup l) : a ∉ l.erase a :=
by rw mem_erase_iff_of_nodup h; simp

theorem nodup_product {s : multiset α} {t : multiset β} : nodup s → nodup t → nodup (product s t) :=
quotient.induction_on₂ s t $ λ l₁ l₂ d₁ d₂, by simp [nodup_product d₁ d₂]

theorem nodup_sigma {σ : α → Type*} {s : multiset α} {t : Π a, multiset (σ a)} :
  nodup s → (∀ a, nodup (t a)) → nodup (s.sigma t) :=
quot.induction_on s $ λ l₁,
let l₂ (a) : list (σ a) := classical.some (quotient.exists_rep (t a)) in
have t = λ a, l₂ a, from eq.symm $ funext $ λ a,
  classical.some_spec (quotient.exists_rep (t a)),
by rw [this]; simpa using nodup_sigma

theorem nodup_filter_map (f : α → option β) {s : multiset α}
  (H : ∀ (a a' : α) (b : β), b ∈ f a → b ∈ f a' → a = a') :
  nodup s → nodup (filter_map f s) :=
quot.induction_on s $ λ l, nodup_filter_map H

theorem nodup_range (n : ℕ) : nodup (range n) := nodup_range _

theorem nodup_inter_left [decidable_eq α] {s : multiset α} (t) : nodup s → nodup (s ∩ t) :=
nodup_of_le $ inter_le_left _ _

theorem nodup_inter_right [decidable_eq α] (s) {t : multiset α} : nodup t → nodup (s ∩ t) :=
nodup_of_le $ inter_le_right _ _

@[simp] theorem nodup_union [decidable_eq α] {s t : multiset α} : nodup (s ∪ t) ↔ nodup s ∧ nodup t :=
⟨λ h, ⟨nodup_of_le (le_union_left _ _) h, nodup_of_le (le_union_right _ _) h⟩,
 λ ⟨h₁, h₂⟩, nodup_iff_count_le_one.2 $ λ a, by rw [count_union]; exact
   max_le (nodup_iff_count_le_one.1 h₁ a) (nodup_iff_count_le_one.1 h₂ a)⟩

theorem nodup_ext {s t : multiset α} : nodup s → nodup t → (s = t ↔ ∀ a, a ∈ s ↔ a ∈ t) :=
quotient.induction_on₂ s t $ λ l₁ l₂ d₁ d₂, quotient.eq.trans $ perm_ext d₁ d₂

theorem le_iff_subset {s t : multiset α} : nodup s → (s ≤ t ↔ s ⊆ t) :=
quotient.induction_on₂ s t $ λ l₁ l₂ d, ⟨subset_of_le, subperm_of_subset_nodup d⟩

theorem range_le {m n : ℕ} : range m ≤ range n ↔ m ≤ n :=
(le_iff_subset (nodup_range _)).trans range_subset

theorem mem_sub_of_nodup [decidable_eq α] {a : α} {s t : multiset α} (d : nodup s) :
  a ∈ s - t ↔ a ∈ s ∧ a ∉ t :=
⟨λ h, ⟨mem_of_le (sub_le_self _ _) h, λ h',
  by refine count_eq_zero.1 _ h; rw [count_sub a s t, nat.sub_eq_zero_iff_le];
     exact le_trans (nodup_iff_count_le_one.1 d _) (count_pos.2 h')⟩,
 λ ⟨h₁, h₂⟩, or.resolve_right (mem_add.1 $ mem_of_le (le_sub_add _ _) h₁) h₂⟩

section
variable [decidable_eq α]

/- erase_dup -/
def erase_dup (s : multiset α) : multiset α :=
quot.lift_on s (λ l, (l.erase_dup : multiset α))
  (λ s t p, quot.sound (perm_erase_dup_of_perm p))

@[simp] theorem coe_erase_dup (l : list α) : @erase_dup α _ l = l.erase_dup := rfl

@[simp] theorem erase_dup_zero : @erase_dup α _ 0 = 0 := rfl

@[simp] theorem mem_erase_dup {a : α} {s : multiset α} : a ∈ erase_dup s ↔ a ∈ s :=
quot.induction_on s $ λ l, mem_erase_dup

@[simp] theorem erase_dup_cons_of_mem {a : α} {s : multiset α} : a ∈ s →
  erase_dup (a::s) = erase_dup s :=
quot.induction_on s $ λ l m, @congr_arg _ _ _ _ coe $ erase_dup_cons_of_mem m

@[simp] theorem erase_dup_cons_of_not_mem {a : α} {s : multiset α} : a ∉ s →
  erase_dup (a::s) = a :: erase_dup s :=
quot.induction_on s $ λ l m, congr_arg coe $ erase_dup_cons_of_not_mem m

theorem erase_dup_le (s : multiset α) : erase_dup s ≤ s :=
quot.induction_on s $ λ l, subperm_of_sublist $ erase_dup_sublist _

theorem erase_dup_subset (s : multiset α) : erase_dup s ⊆ s :=
subset_of_le $ erase_dup_le _

theorem subset_erase_dup (s : multiset α) : s ⊆ erase_dup s :=
λ a, mem_erase_dup.2

@[simp] theorem erase_dup_subset' {s t : multiset α} : erase_dup s ⊆ t ↔ s ⊆ t :=
⟨subset.trans (subset_erase_dup _), subset.trans (erase_dup_subset _)⟩

@[simp] theorem subset_erase_dup' {s t : multiset α} : s ⊆ erase_dup t ↔ s ⊆ t :=
⟨λ h, subset.trans h (erase_dup_subset _), λ h, subset.trans h (subset_erase_dup _)⟩

@[simp] theorem nodup_erase_dup (s : multiset α) : nodup (erase_dup s) :=
quot.induction_on s nodup_erase_dup

theorem erase_dup_eq_self {s : multiset α} : erase_dup s = s ↔ nodup s :=
⟨λ e, e ▸ nodup_erase_dup s,
 quot.induction_on s $ λ l h, congr_arg coe $ erase_dup_eq_self.2 h⟩

theorem le_erase_dup {s t : multiset α} : s ≤ erase_dup t ↔ s ≤ t ∧ nodup s :=
⟨λ h, ⟨le_trans h (erase_dup_le _), nodup_of_le h (nodup_erase_dup _)⟩,
 λ ⟨l, d⟩, (le_iff_subset d).2 $ subset.trans (subset_of_le l) (subset_erase_dup _)⟩

theorem erase_dup_ext {s t : multiset α} : erase_dup s = erase_dup t ↔ ∀ a, a ∈ s ↔ a ∈ t :=
by simp [nodup_ext]

theorem erase_dup_map_erase_dup_eq [decidable_eq β] (f : α → β) (s : multiset α) :
  erase_dup (map f (erase_dup s)) = erase_dup (map f s) := by simp [erase_dup_ext]

/- finset insert -/

def ndinsert (a : α) (s : multiset α) : multiset α :=
quot.lift_on s (λ l, (l.insert a : multiset α))
  (λ s t p, quot.sound (perm_insert a p))

@[simp] theorem coe_ndinsert (a : α) (l : list α) : ndinsert a l = (insert a l : list α) := rfl

@[simp] theorem ndinsert_zero (a : α) : ndinsert a 0 = a::0 := rfl

@[simp] theorem ndinsert_of_mem {a : α} {s : multiset α} : a ∈ s → ndinsert a s = s :=
quot.induction_on s $ λ l h, congr_arg coe $ insert_of_mem h

@[simp] theorem ndinsert_of_not_mem {a : α} {s : multiset α} : a ∉ s → ndinsert a s = a :: s :=
quot.induction_on s $ λ l h, congr_arg coe $ insert_of_not_mem h

@[simp] theorem mem_ndinsert {a b : α} {s : multiset α} : a ∈ ndinsert b s ↔ a = b ∨ a ∈ s :=
quot.induction_on s $ λ l, mem_insert_iff

@[simp] theorem le_ndinsert_self (a : α) (s : multiset α) : s ≤ ndinsert a s :=
quot.induction_on s $ λ l, subperm_of_sublist $ sublist_of_suffix $ suffix_insert _ _

@[simp] theorem mem_ndinsert_self (a : α) (s : multiset α) : a ∈ ndinsert a s :=
mem_ndinsert.2 (or.inl rfl)

@[simp] theorem mem_ndinsert_of_mem {a b : α} {s : multiset α} (h : a ∈ s) : a ∈ ndinsert b s :=
mem_ndinsert.2 (or.inr h)

@[simp] theorem length_ndinsert_of_mem {a : α} [decidable_eq α] {s : multiset α} (h : a ∈ s) :
  card (ndinsert a s) = card s :=
by simp [h]

@[simp] theorem length_ndinsert_of_not_mem {a : α} [decidable_eq α] {s : multiset α} (h : a ∉ s) :
  card (ndinsert a s) = card s + 1 :=
by simp [h]

theorem erase_dup_cons {a : α} {s : multiset α} :
  erase_dup (a::s) = ndinsert a (erase_dup s) :=
by by_cases a ∈ s; simp [h]

theorem nodup_ndinsert (a : α) {s : multiset α} : nodup s → nodup (ndinsert a s) :=
quot.induction_on s $ λ l, nodup_insert

theorem ndinsert_le {a : α} {s t : multiset α} : ndinsert a s ≤ t ↔ s ≤ t ∧ a ∈ t :=
⟨λ h, ⟨le_trans (le_ndinsert_self _ _) h, mem_of_le h (mem_ndinsert_self _ _)⟩,
 λ ⟨l, m⟩, if h : a ∈ s then by simp [h, l] else
   by rw [ndinsert_of_not_mem h, ← cons_erase m, cons_le_cons_iff,
          ← le_cons_of_not_mem h, cons_erase m]; exact l⟩

/- finset union -/

def ndunion (s t : multiset α) : multiset α :=
quotient.lift_on₂ s t (λ l₁ l₂, (l₁.union l₂ : multiset α)) $ λ v₁ v₂ w₁ w₂ p₁ p₂,
  quot.sound $ perm_union p₁ p₂

@[simp] theorem coe_ndunion (l₁ l₂ : list α) : @ndunion α _ l₁ l₂ = (l₁ ∪ l₂ : list α) := rfl

@[simp] theorem zero_ndunion (s : multiset α) : ndunion 0 s = s :=
quot.induction_on s $ λ l, rfl

@[simp] theorem cons_ndunion (s t : multiset α) (a : α) : ndunion (a :: s) t = ndinsert a (ndunion s t) :=
quotient.induction_on₂ s t $ λ l₁ l₂, rfl

@[simp] theorem mem_ndunion {s t : multiset α} {a : α} : a ∈ ndunion s t ↔ a ∈ s ∨ a ∈ t :=
quotient.induction_on₂ s t $ λ l₁ l₂, list.mem_union

theorem le_ndunion_right (s t : multiset α) : t ≤ ndunion s t :=
quotient.induction_on₂ s t $ λ l₁ l₂,
subperm_of_sublist $ sublist_of_suffix $ suffix_union_right _ _

theorem ndunion_le_add (s t : multiset α) : ndunion s t ≤ s + t :=
quotient.induction_on₂ s t $ λ l₁ l₂, subperm_of_sublist $ union_sublist_append _ _

theorem ndunion_le {s t u : multiset α} : ndunion s t ≤ u ↔ s ⊆ u ∧ t ≤ u :=
multiset.induction_on s (by simp) (by simp [ndinsert_le] {contextual := tt})

theorem subset_ndunion_left (s t : multiset α) : s ⊆ ndunion s t :=
λ a h, mem_ndunion.2 $ or.inl h

theorem le_ndunion_left {s} (t : multiset α) (d : nodup s) : s ≤ ndunion s t :=
(le_iff_subset d).2 $ subset_ndunion_left _ _

theorem ndunion_le_union (s t : multiset α) : ndunion s t ≤ s ∪ t :=
ndunion_le.2 ⟨subset_of_le (le_union_left _ _), le_union_right _ _⟩

theorem nodup_ndunion (s : multiset α) {t : multiset α} : nodup t → nodup (ndunion s t) :=
quotient.induction_on₂ s t $ λ l₁ l₂, list.nodup_union _

@[simp] theorem ndunion_eq_union {s t : multiset α} (d : nodup s) : ndunion s t = s ∪ t :=
le_antisymm (ndunion_le_union _ _) $ union_le (le_ndunion_left _ d) (le_ndunion_right _ _)

theorem erase_dup_add (s t : multiset α) : erase_dup (s + t) = ndunion s (erase_dup t) :=
quotient.induction_on₂ s t $ λ l₁ l₂, congr_arg coe $ erase_dup_append _ _

/- finset inter -/

def ndinter (s t : multiset α) : multiset α := filter (∈ t) s

@[simp] theorem coe_ndinter (l₁ l₂ : list α) : @ndinter α _ l₁ l₂ = (l₁ ∩ l₂ : list α) := rfl

@[simp] theorem zero_ndinter (s : multiset α) : ndinter 0 s = 0 := rfl

@[simp] theorem cons_ndinter_of_mem {a : α} (s : multiset α) {t : multiset α} (h : a ∈ t) :
  ndinter (a::s) t = a :: (ndinter s t) := by simp [ndinter, h]

@[simp] theorem ndinter_cons_of_not_mem {a : α} (s : multiset α) {t : multiset α} (h : a ∉ t) :
  ndinter (a::s) t = ndinter s t := by simp [ndinter, h]

@[simp] theorem mem_ndinter {s t : multiset α} {a : α} : a ∈ ndinter s t ↔ a ∈ s ∧ a ∈ t :=
mem_filter

theorem nodup_ndinter {s : multiset α} (t : multiset α) : nodup s → nodup (ndinter s t) :=
nodup_filter _

theorem le_ndinter {s t u : multiset α} : s ≤ ndinter t u ↔ s ≤ t ∧ s ⊆ u :=
by simp [ndinter, le_filter, subset_iff]

theorem ndinter_le_left (s t : multiset α) : ndinter s t ≤ s :=
(le_ndinter.1 (le_refl _)).1

theorem ndinter_subset_right (s t : multiset α) : ndinter s t ⊆ t :=
(le_ndinter.1 (le_refl _)).2

theorem ndinter_le_right {s} (t : multiset α) (d : nodup s) : ndinter s t ≤ t :=
(le_iff_subset $ nodup_ndinter _ d).2 (ndinter_subset_right _ _)

theorem inter_le_ndinter (s t : multiset α) : s ∩ t ≤ ndinter s t :=
le_ndinter.2 ⟨inter_le_left _ _, subset_of_le $ inter_le_right _ _⟩

@[simp] theorem ndinter_eq_inter {s t : multiset α} (d : nodup s) : ndinter s t = s ∩ t :=
le_antisymm (le_inter (ndinter_le_left _ _) (ndinter_le_right _ d)) (inter_le_ndinter _ _)

theorem ndinter_eq_zero_iff_disjoint {s t : multiset α} : ndinter s t = 0 ↔ disjoint s t :=
by rw ← subset_zero; simp [subset_iff, disjoint]

end

/- fold -/
section fold
variables (op : α → α → α) [hc : is_commutative α op] [ha : is_associative α op]
local notation a * b := op a b
include hc ha

def fold : α → multiset α → α := foldr op (left_comm _ hc.comm ha.assoc)

theorem fold_eq_foldr (b : α) (s : multiset α) : fold op b s = foldr op (left_comm _ hc.comm ha.assoc) b s := rfl

@[simp] theorem coe_fold_r (b : α) (l : list α) : fold op b l = l.foldr op b := rfl

theorem coe_fold_l (b : α) (l : list α) : fold op b l = l.foldl op b :=
(coe_foldr_swap op _ b l).trans $ by simp [hc.comm]

theorem fold_eq_foldl (b : α) (s : multiset α) : fold op b s = foldl op (right_comm _ hc.comm ha.assoc) b s :=
quot.induction_on s $ λ l, coe_fold_l _ _ _

@[simp] theorem fold_zero (b : α) : (0 : multiset α).fold op b = b := rfl

@[simp] theorem fold_cons_left : ∀ (b a : α) (s : multiset α),
  (a :: s).fold op b = a * s.fold op b := foldr_cons _ _

theorem fold_cons_right (b a : α) (s : multiset α) : (a :: s).fold op b = s.fold op b * a :=
by simp [hc.comm]

theorem fold_cons'_right (b a : α) (s : multiset α) : (a :: s).fold op b = s.fold op (b * a) :=
by rw [fold_eq_foldl, foldl_cons, ← fold_eq_foldl]

theorem fold_cons'_left (b a : α) (s : multiset α) : (a :: s).fold op b = s.fold op (a * b) :=
by rw [fold_cons'_right, hc.comm]

theorem fold_add (b₁ b₂ : α) (s₁ s₂ : multiset α) : (s₁ + s₂).fold op (b₁ * b₂) = s₁.fold op b₁ * s₂.fold op b₂ :=
multiset.induction_on s₂
  (by rw [add_zero, fold_zero, ← fold_cons'_right, ← fold_cons_right op])
  (by simp {contextual := tt}; cc)

theorem fold_singleton (b a : α) : (a::0 : multiset α).fold op b = a * b := by simp

theorem fold_distrib {f g : β → α} (u₁ u₂ : α) (s : multiset β) :
  (s.map (λx, f x * g x)).fold op (u₁ * u₂) = (s.map f).fold op u₁ * (s.map g).fold op u₂ :=
multiset.induction_on s (by simp) (by simp {contextual := tt}; cc)

theorem fold_hom {op' : β → β → β} [is_commutative β op'] [is_associative β op']
  {m : α → β} (hm : ∀x y, m (op x y) = op' (m x) (m y)) (b : α) (s : multiset α) :
  (s.map m).fold op' (m b) = m (s.fold op b) :=
multiset.induction_on s (by simp) (by simp [hm] {contextual := tt})

theorem fold_union_inter [decidable_eq α] (s₁ s₂ : multiset α) (b₁ b₂ : α) :
  (s₁ ∪ s₂).fold op b₁ * (s₁ ∩ s₂).fold op b₂ = s₁.fold op b₁ * s₂.fold op b₂ :=
by rw [← fold_add op, union_add_inter, fold_add op]

@[simp] theorem fold_erase_dup_idem [decidable_eq α] [hi : is_idempotent α op] (s : multiset α) (b : α) :
  (erase_dup s).fold op b = s.fold op b :=
multiset.induction_on s (by simp) $ λ a s IH, begin
  by_cases a ∈ s; simp [IH, h],
  show fold op b s = op a (fold op b s),
  rw [← cons_erase h, fold_cons_left, ← ha.assoc, hi.idempotent],
end

end fold

theorem le_smul_erase_dup [decidable_eq α] (s : multiset α) :
  ∃ n : ℕ, s ≤ erase_dup s • n :=
⟨(s.map (λ a, count a s)).fold max 0, le_iff_count.2 $ λ a, begin
  rw count_smul, by_cases a ∈ s,
  { refine le_trans _ (mul_le_mul_right _ $ count_pos.2 $ mem_erase_dup.2 h),
    have : count a s ≤ fold max 0 (map (λ a, count a s) (a :: erase s a));
    [simp [le_max_left], simpa [cons_erase h]] },
  { simp [count_eq_zero.2 h, nat.zero_le] }
end⟩

section sort
variables (r : α → α → Prop) [decidable_rel r]
  [tr : is_trans α r] [an : is_antisymm α r] [to : is_total α r]
include tr an to

def sort (s : multiset α) : list α :=
quot.lift_on s (merge_sort r) $ λ a b h,
eq_of_sorted_of_perm tr.trans an.antisymm
  ((perm_merge_sort _ _).trans $ h.trans (perm_merge_sort _ _).symm)
  (sorted_merge_sort r to.total tr.trans _)
  (sorted_merge_sort r to.total tr.trans _)

@[simp] theorem coe_sort (l : list α) : sort r l = merge_sort r l := rfl

@[simp] theorem sort_sorted (s : multiset α) : sorted r (sort r s) :=
quot.induction_on s $ λ l, sorted_merge_sort r to.total tr.trans _

@[simp] theorem sort_eq (s : multiset α) : ↑(sort r s) = s :=
quot.induction_on s $ λ l, quot.sound $ perm_merge_sort _ _

end sort

end multiset
