/-
Copyright (c) 2024 David Loeffler. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Giulio Caflisch, David Loeffler, Yu Shao, Beibei Xiong, Weijie Jiang
-/
import Mathlib.Algebra.BigOperators.Pi
import Mathlib.Algebra.Group.AddChar
import Mathlib.Algebra.Module.Submodule.LinearMap
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.Abel

/-!
# Forward difference operators and Newton series

We define the forward difference operator, sending `f` to the function `x ↦ f (x + h) - f x` for
a given `h` (for any additive semigroup, taking values in an abelian group). The notation `Δ_[h]` is
defined for this operator, scoped in namespace `fwdDiff`.

We prove two key formulae about this operator:

* `shift_eq_sum_fwdDiff_iter`: the **Gregory-Newton formula**, expressing `f (y + n • h)` as a
  linear combination of forward differences of `f` at `y`, for `n ∈ ℕ`;
* `fwdDiff_iter_eq_sum_shift`: formula expressing the `n`-th forward difference of `f` at `y` as
  a linear combination of `f (y + k • h)` for `0 ≤ k ≤ n`.

We also prove some auxiliary results about iterated forward differences of the function
`n ↦ n.choose k`.
-/

open Finset Nat Function

variable {M G : Type*} [AddCommMonoid M] [AddCommGroup G] (h : M)

/--
Forward difference operator, `fwdDiff h f n = f (n + h) - f n`. The notation `Δ_[h]` for this
operator is available in the `fwdDiff` namespace.
-/
def fwdDiff (h : M) (f : M → G) : M → G := fun n ↦ f (n + h) - f n

@[inherit_doc] scoped[fwdDiff] notation "Δ_[" h "]" => fwdDiff h

open fwdDiff

@[simp] lemma fwdDiff_add (h : M) (f g : M → G) :
    Δ_[h] (f + g) = Δ_[h] f + Δ_[h] g :=
  add_sub_add_comm ..

@[simp] lemma fwdDiff_const (g : G) : Δ_[h] (fun _ ↦ g : M → G) = fun _ ↦ 0 :=
  funext fun _ ↦ sub_self g

section smul

lemma fwdDiff_smul {R : Type} [Ring R] [Module R G] (f : M → R) (g : M → G) :
    Δ_[h] (f • g) = Δ_[h] f • g + f • Δ_[h] g + Δ_[h] f • Δ_[h] g := by
  ext y
  simp only [fwdDiff, Pi.smul_apply', Pi.add_apply, smul_sub, sub_smul]
  abel

-- Note `fwdDiff_const_smul` is more general than `fwdDiff_smul` since it allows `R` to be a
-- semiring, rather than a ring; in particular `R = ℕ` is allowed.
@[simp] lemma fwdDiff_const_smul {R : Type*} [Monoid R] [DistribMulAction R G] (r : R) (f : M → G) :
    Δ_[h] (r • f) = r • Δ_[h] f :=
  funext fun _ ↦ (smul_sub ..).symm

@[simp] lemma fwdDiff_smul_const {R : Type} [Ring R] [Module R G] (f : M → R) (g : G) :
    Δ_[h] (fun y ↦ f y • g) = Δ_[h] f • fun _ ↦ g := by
  ext y
  simp only [fwdDiff, Pi.smul_apply', sub_smul]

end smul

namespace fwdDiff_aux
/-!
## Forward-difference and shift operators as linear endomorphisms

This section contains versions of the forward-difference operator and the shift operator bundled as
`ℤ`-linear endomorphisms. These are useful for certain proofs; but they are slightly annoying to
use, as the source and target types of the maps have to be specified each time, and various
coercions need to be un-wound when the operators are applied, so we also provide the un-bundled
version.
-/

variable (M G) in
/-- Linear-endomorphism version of the forward difference operator. -/
@[simps]
def fwdDiffₗ : Module.End ℤ (M → G) where
  toFun := fwdDiff h
  map_add' := fwdDiff_add h
  map_smul' := fwdDiff_const_smul h

lemma coe_fwdDiffₗ : ↑(fwdDiffₗ M G h) = fwdDiff h := rfl

lemma coe_fwdDiffₗ_pow (n : ℕ) : ↑(fwdDiffₗ M G h ^ n) = (fwdDiff h)^[n] := by
  ext; rw [Module.End.pow_apply, coe_fwdDiffₗ]

variable (M G) in
/-- Linear-endomorphism version of the shift-by-1 operator. -/
def shiftₗ : Module.End ℤ (M → G) := fwdDiffₗ M G h + 1

lemma shiftₗ_apply (f : M → G) (y : M) : shiftₗ M G h f y = f (y + h) := by simp [shiftₗ, fwdDiff]

lemma shiftₗ_pow_apply (f : M → G) (k : ℕ) (y : M) : (shiftₗ M G h ^ k) f y = f (y + k • h) := by
  induction' k with k IH generalizing f
  · simp
  · simp [pow_add, IH (shiftₗ M G h f), shiftₗ_apply, add_assoc, add_nsmul]

end fwdDiff_aux

open fwdDiff_aux

@[simp] lemma fwdDiff_finset_sum {α : Type*} (s : Finset α) (f : α → M → G) :
    Δ_[h] (∑ k ∈ s, f k) = ∑ k ∈ s, Δ_[h] (f k) :=
  map_sum (fwdDiffₗ M G h) f s

@[simp] lemma fwdDiff_iter_add (f g : M → G) (n : ℕ) :
    Δ_[h]^[n] (f + g) = Δ_[h]^[n] f + Δ_[h]^[n] g := by
  simpa only [coe_fwdDiffₗ_pow] using map_add (fwdDiffₗ M G h ^ n) f g

@[simp] lemma fwdDiff_iter_const_smul {R : Type*} [Monoid R] [DistribMulAction R G]
    (r : R) (f : M → G) (n : ℕ) : Δ_[h]^[n] (r • f) = r • Δ_[h]^[n] f := by
  induction' n with n IH generalizing f
  · simp only [iterate_zero, id_eq]
  · simp only [iterate_succ_apply, fwdDiff_const_smul, IH]

@[simp] lemma fwdDiff_iter_finset_sum {α : Type*} (s : Finset α) (f : α → M → G) (n : ℕ) :
    Δ_[h]^[n] (∑ k ∈ s, f k) = ∑ k ∈ s, Δ_[h]^[n] (f k) := by
  simpa only [coe_fwdDiffₗ_pow] using map_sum (fwdDiffₗ M G h ^ n) f s

section newton_formulae

/--
Express the `n`-th forward difference of `f` at `y` in terms of the values `f (y + k)`, for
`0 ≤ k ≤ n`.
-/
theorem fwdDiff_iter_eq_sum_shift (f : M → G) (n : ℕ) (y : M) :
    Δ_[h]^[n] f y = ∑ k ∈ range (n + 1), ((-1 : ℤ) ^ (n - k) * n.choose k) • f (y + k • h) := by
  -- rewrite in terms of `(shiftₗ - 1) ^ n`
  have : fwdDiffₗ M G h = shiftₗ M G h - 1 := by simp only [shiftₗ, add_sub_cancel_right]
  rw [← coe_fwdDiffₗ, this, ← Module.End.pow_apply]
  -- use binomial theorem `Commute.add_pow` to expand this
  have : Commute (shiftₗ M G h) (-1) := (Commute.one_right _).neg_right
  convert congr_fun (LinearMap.congr_fun (this.add_pow n) f) y using 3
  · simp only [sub_eq_add_neg]
  · rw [LinearMap.sum_apply, sum_apply]
    congr 1 with k
    have : ((-1) ^ (n - k) * n.choose k : Module.End ℤ (M → G))
              = ↑((-1) ^ (n - k) * n.choose k : ℤ) := by norm_cast
    rw [mul_assoc, Module.End.mul_apply, this, Module.End.intCast_apply, LinearMap.map_smul,
      Pi.smul_apply, shiftₗ_pow_apply]

/--
**Gregory-Newton formula** expressing `f (y + n • h)` in terms of the iterated forward differences
of `f` at `y`.
-/
theorem shift_eq_sum_fwdDiff_iter (f : M → G) (n : ℕ) (y : M) :
    f (y + n • h) = ∑ k ∈ range (n + 1), n.choose k • Δ_[h]^[k] f y := by
  convert congr_fun (LinearMap.congr_fun
      ((Commute.one_right (fwdDiffₗ M G h)).add_pow n) f) y using 1
  · rw [← shiftₗ_pow_apply h f, shiftₗ]
  · simp [Module.End.pow_apply, coe_fwdDiffₗ]

end newton_formulae

section choose

lemma fwdDiff_choose (j : ℕ) : Δ_[1] (fun x ↦ x.choose (j + 1) : ℕ → ℤ) = fun x ↦ x.choose j := by
  ext n
  simp only [fwdDiff, choose_succ_succ' n j, cast_add, add_sub_cancel_right]

lemma fwdDiff_iter_choose (j k : ℕ) :
    Δ_[1]^[k] (fun x ↦ x.choose (k + j) : ℕ → ℤ) = fun x ↦ x.choose j := by
  induction' k with k IH generalizing j
  · simp only [zero_add, iterate_zero, id_eq]
  · simp only [Function.iterate_succ_apply', add_assoc, add_comm 1 j, IH, fwdDiff_choose]

lemma fwdDiff_iter_choose_zero (m n : ℕ) :
    Δ_[1]^[n] (fun x ↦ x.choose m : ℕ → ℤ) 0 = if n = m then 1 else 0 := by
  rcases lt_trichotomy m n with hmn | rfl | hnm
  · rcases Nat.exists_eq_add_of_lt hmn with ⟨k, rfl⟩
    simp_rw [hmn.ne', if_false, (by ring : m + k + 1 = k + 1 + m), iterate_add_apply,
      add_zero m ▸ fwdDiff_iter_choose 0 m, choose_zero_right, iterate_one, cast_one, fwdDiff_const,
      fwdDiff_iter_eq_sum_shift, smul_zero, sum_const_zero]
  · simp only [if_true, add_zero m ▸ fwdDiff_iter_choose 0 m, choose_zero_right, cast_one]
  · rcases Nat.exists_eq_add_of_lt hnm with ⟨k, rfl⟩
    simp_rw [hnm.ne, if_false, add_assoc n k 1, fwdDiff_iter_choose, choose_zero_succ, cast_zero]

end choose

lemma fwdDiff_addChar_eq {M R : Type*} [AddCommMonoid M] [Ring R]
    (φ : AddChar M R) (x h : M) (n : ℕ) : Δ_[h]^[n] φ x = (φ h - 1) ^ n * φ x := by
  induction n generalizing x with
  | zero => simp
  | succ n IH =>
    simp only [pow_succ, Function.iterate_succ_apply', fwdDiff, IH, ← mul_sub, mul_assoc]
    rw [sub_mul, ← AddChar.map_add_eq_mul, add_comm h x, one_mul]


/-!
## Forward differences of Polynomials

This section develops the theory of forward differences for polynomial functions `P : R → R`,
where the step size `h` is `1`. We prove several key results:

* `fwdDiff_iter_pow_eq_zero_of_lt`: The `n`-th difference of `x ↦ x^j` is zero if `j < n`.
* `fwdDiff_iter_eq_factorial`: The `n`-th difference of `x ↦ x^n` is the constant `n!`.
* `fwdDiff_iter_succ_sum_eq_zero`: The `(d+1)`-th difference of a polynomial of degree `d` is zero.
* `fwdDiffTab_0th_diag_poly'`: **Newton's series** for a polynomial, expressing `P(x)` as a sum
  of its forward differences at `0` weighted by binomial coefficients.
* `sum_of_poly_sequence`: A formula for the sum of a polynomial sequence `∑_{i=0..p} P(i)`, which
  generalizes **Faulhaber's formula**.
-/

open fwdDiff
variable {R : Type*} [CommRing R]

/--
The `n`-th forward difference of the function `x ↦ x^j` is zero if `j < n`.
This is a building block for showing that the `(p+1)`-th difference of a polynomial of
degree `p` is zero.
-/
theorem fwdDiff_iter_pow_eq_zero_of_lt {j n : ℕ} (h : j < n) :
  ((fwdDiffₗ R R 1 ^ n) fun x ↦ x ^ j) = 0 := by
  induction' n with n ih generalizing j
  · contradiction
  · rw [pow_succ, Module.End.mul_apply]
    have : ((fwdDiffₗ R R 1) fun x ↦ x ^ j) =
        ∑ i ∈ Finset.range j, j.choose i • fun x : R ↦ x ^ i := by
      ext x
      simp only [fwdDiffₗ_apply, nsmul_eq_mul, sum_apply, Pi.mul_apply, Pi.natCast_apply, fwdDiff,
        add_pow, one_pow, Finset.sum_range_succ, mul_one, choose_self, cast_one,
        add_sub_cancel_right, mul_comm]
    rw [this, map_sum]
    exact Finset.sum_eq_zero fun i hi ↦ have _ := Finset.mem_range.1 hi; by
      rw [map_nsmul, ih (by omega)]; rw [nsmul_zero]


/-- The `n`-th forward difference of `x ↦ x^n` is the constant function `n!`. -/
theorem fwdDiff_iter_eq_factorial {n : ℕ} :
  ((fwdDiffₗ R R 1 ^ n) fun x ↦ x ^ n) = (fun _ ↦ (n.factorial : R))  := by
  induction' n with n ih
  · simp only [pow_zero, Module.End.one_apply, factorial_zero, cast_one]
  · simp at ih
    rw [pow_succ, Module.End.mul_apply]
    have : ((fwdDiffₗ R R 1) fun x ↦ x ^ (n + 1)) =
        ∑ k ∈ Finset.range (n + 1), (n + 1).choose k • fun x : R ↦ x ^ k := by
      ext x;
      simp only [fwdDiffₗ_apply, nsmul_eq_mul, sum_apply, Pi.mul_apply, Pi.natCast_apply,
        fwdDiff, add_pow, one_pow, Finset.sum_range_succ, Nat.choose_self, cast_one, mul_one,
        add_sub_assoc, sub_self, add_zero, ]
      simp only [choose_succ_self_right, cast_add, cast_one, mul_comm]
    rw [this, map_sum, Nat.factorial_succ, Nat.cast_mul]; ext x
    rw [funext_iff] at ih
    simp only [← ih x, Finset.sum_range_succ, choose_succ_self_right, cast_add, cast_one]
    have : (fwdDiffₗ R R 1 ^ n) ((n + 1) • fun x ↦ x ^ n) =
      ((n : R → R) + 1) * (fwdDiffₗ R R 1 ^ n) fun x ↦ x ^ n := by
      rw [map_nsmul]
      simp only [nsmul_eq_mul, cast_add, cast_one]
    simp only [this, Pi.add_apply, sum_apply, Pi.mul_apply,
      Pi.natCast_apply, Pi.one_apply, add_eq_right]
    exact Finset.sum_eq_zero fun i hi ↦ have _ := Finset.mem_range.1 hi; by
      rw [map_nsmul, fwdDiff_iter_pow_eq_zero_of_lt
        (by linarith), Pi.smul_apply, Pi.zero_apply, smul_zero]


/--
The `(n+1)`-th forward difference of a polynomial of degree at most `n` is zero.
A polynomial `P(x) = ∑_{k=0..n} aₖ xᵏ` has `Δ^[n+1] P = 0`.
-/
theorem fwdDiff_iter_succ_sum_eq_zero {n : ℕ} (a : ℕ → R):
    ((fwdDiffₗ R R 1 ^ (n + 1)) fun x ↦ ∑ k ∈ Finset.range (n + 1), a k * (x ^ k)) = 0 := by
  induction' n with n ih
  · unfold fwdDiffₗ
    simp; ext x
    simp only [Pi.zero_apply]
  · rw [pow_succ, Module.End.mul_apply]
    have :((fwdDiffₗ R R 1 ^ (n + 1)) (fun x => ∑ k ∈ range (n + 1), a k * x ^ k)) =
      ∑ k ∈ range (n + 1), (fwdDiffₗ R R 1 ^ (n + 1))
      ((fun x : R ↦ a k) * (fun x : R ↦  x ^ k)) := by
      ext x; simp
      have : (fun x => ∑ k ∈ range (n + 1), a k * x ^ k) =
        (∑ k ∈ range (n + 1), fun x =>  a k * x ^ k) := by
        ext x; simp only [Finset.sum_apply]
      simp only [this, map_sum, sum_apply]
      rfl
    rw [this] at ih
    have : ((fwdDiffₗ R R 1) fun x ↦ ∑ k ∈ range (n + 1 + 1), a k * x ^ k) =
      ∑ k ∈ range (n + 1 + 1), a k • (fun x : R ↦  (x + 1) ^ k) -
      ∑ k ∈ range (n + 1 + 1),a k • fun x : R ↦ x ^ k := by
      ext x; simp
      unfold fwdDiff
      rfl
    rw [this]
    simp only [map_sub, map_sum, coe_fwdDiffₗ_pow]
    ext x
    rw [Finset.sum_range_succ]
    nth_rw 2 [Finset.sum_range_succ]
    simp only [fwdDiff_iter_const_smul, Pi.sub_apply, Pi.add_apply, sum_apply, Pi.smul_apply,
      smul_eq_mul]
    rw [← add_sub, ← coe_fwdDiffₗ_pow]
    have :  ((fwdDiffₗ R R 1 ^ (n + 1)) fun x => x ^ (n + 1)) (x + 1) =
        ((fwdDiffₗ R R 1 ^ (n + 1)) fun x => (x + 1) ^ (n + 1)) x := by
      simp only [coe_fwdDiffₗ_pow, fwdDiff_iter_eq_sum_shift, fwdDiff_iter_eq_sum_shift,
        Int.reduceNeg, nsmul_eq_mul, mul_one, zsmul_eq_mul, Int.cast_mul, Int.cast_pow,
        Int.cast_neg, Int.cast_one, Int.cast_natCast,
        add_assoc (b := (1 : R)), add_comm (a := (1 : R)), ← add_assoc]
    simp only [← this, fwdDiff_iter_eq_factorial (n := n + 1) (R := R), sub_add_cancel_right, ←
      sub_eq_add_neg, ← Finset.sum_sub_distrib]
    exact Finset.sum_eq_zero fun k hk ↦ have _ := Finset.mem_range.1 hk; by
      rw [← mul_sub, fwdDiff_iter_pow_eq_zero_of_lt (by linarith) ]
      simp only [Pi.zero_apply, sub_zero]
      have : (fwdDiffₗ R R 1 ^ (n + 1)) (fun x => (x + 1) ^ k) x =
      (fwdDiffₗ R R 1 ^ (n + 1)) (fun x => x ^ k) (x + 1) := by
        rw [coe_fwdDiffₗ_pow, fwdDiff_iter_eq_sum_shift, fwdDiff_iter_eq_sum_shift]
        congr 1; ext k
        simp only [Int.reduceNeg, nsmul_eq_mul, mul_one,
          zsmul_eq_mul, Int.cast_mul, Int.cast_pow, Int.cast_neg, Int.cast_one, Int.cast_natCast]
        ring
      rw [this, fwdDiff_iter_pow_eq_zero_of_lt (by linarith)]
      simp only [Pi.zero_apply, mul_zero]

/--
**Newton's series** for a polynomial function.
Any function `f` defined by a polynomial can be expressed as a sum of its forward
differences at `0`, weighted by binomial coefficients.
`f(x) = ∑_{k=0..p} (p choose k) * (Δ^k f)(0)`.
-/
theorem fwdDiffTab_0th_diag_poly' {n p : ℕ} (a : ℕ → R):
    ∑ k ∈ Finset.range (n + 1), a k * (p ^ k) =
    ∑ k ∈ Finset.range (p + 1), p.choose k *
      ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ k ∈ Finset.range (n + 1), a k * (x ^ k)) 0 := by
  obtain h := shift_eq_sum_fwdDiff_iter (n := p) (y := 0)
    (f := (fun x => ∑ i ∈ Finset.range (n + 1), a i * (x ^ i))) (h := 1)
  simp only [mul_one, zero_add, nsmul_eq_mul] at h
  rw [h]
  exact Finset.sum_congr rfl fun k hk ↦ have _ := Finset.mem_range.1 hk; by
    congr 1
    simp only [coe_fwdDiffₗ_pow, fwdDiff_iter_eq_sum_shift, Int.reduceNeg, nsmul_eq_mul,
      mul_one, zsmul_eq_mul, Int.cast_mul, Int.cast_pow, Int.cast_neg, Int.cast_one,
      Int.cast_natCast]

/--
A formula for the sum of a polynomial sequence `∑_{i=0..p} P(i)`, which
generalizes **Faulhaber's formula**.
-/
theorem sum_of_poly_sequence {p n : ℕ} (a : ℕ → R) :
    ∑ i ∈ Finset.range (p + 1), (∑ k ∈ Finset.range (n + 1), a k * i ^ k) =
    ∑ k ∈ Finset.range (p + 1), ((p + 1).choose (k + 1)) *
      (((fwdDiffₗ R R 1 ^ k) fun y ↦ ∑ i ∈ Finset.range (n + 1), a i * y ^ i) 0) := by
    have sum_choose_eq_choose_succ_succ :
      ∀ n m, ∑ k ∈ Finset.range (n + 1), k.choose m = (n + 1).choose (m + 1) := by
      intro n m
      induction' n with n ih
      · exact rfl
      · rw [Finset.sum_range_succ, Nat.choose_succ_succ', ih, add_comm]
    obtain sum_choose := sum_choose_eq_choose_succ_succ p
    conv => enter [1, 2, x]; rw [fwdDiffTab_0th_diag_poly']; simp
    have sum_extend_inner_range : ∑ x ∈ Finset.range (p + 1), ∑ k ∈ Finset.range (x + 1),
      ↑(x.choose k) *
        ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ m ∈ Finset.range (n + 1), a m * ↑x ^ m) 0 =
      ∑ x ∈ Finset.range (p + 1), ∑ k ∈ Finset.range (p + 1),
      ↑(x.choose k) *
        ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ m ∈ Finset.range (n + 1), a m * ↑x ^ m) 0 := by
      apply Finset.sum_congr rfl
      intro x hx
      have sum_sum_eq_zero : ∑ k ∈ Finset.Ico (x + 1) (p + 1), ↑(x.choose k) *
        ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ m ∈ Finset.range (n + 1), a m * x ^ m) 0 = 0 := by
        rw [Finset.sum_Ico_eq_sum_range]
        simp
        simp at hx
        have : ∑ k ∈ Finset.range (p - x), 0 = (0 : R) := by simp only [Finset.sum_const_zero]
        rw [← this]
        apply Finset.sum_congr rfl
        intro y hy; simp only [mem_range] at hy
        have : x + 1 + y > x := by omega
        rw [Nat.choose_eq_zero_of_lt this]
        simp
      nth_rw 1 3 [Finset.range_eq_Ico]
      have sum_Ico_split : ∑ k ∈ Finset.Ico 0 (p + 1), ↑(x.choose k) *
          ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ m ∈ Finset.range (n + 1), a m * x ^ m) 0 =
        ∑ k ∈ Finset.Ico 0 (x + 1), ↑(x.choose k) *
          ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ m ∈ Finset.range (n + 1), a m * x ^ m) 0 +
        ∑ k ∈ Finset.Ico (x + 1) (p + 1), ↑(x.choose k) *
          ((fwdDiffₗ R R 1 ^ k) fun x ↦ ∑ m ∈ Finset.range (n + 1), a m * x ^ m) 0 := by
        rw [← Finset.sum_Ico_consecutive]
        · linarith
        · simp at hx
          linarith
      rw [sum_Ico_split, sum_sum_eq_zero, add_zero]
    rw [sum_extend_inner_range, Finset.sum_comm]
    simp_rw [← Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro k hk; simp only [mem_range] at hk
    congr 1
    norm_cast
    rw [sum_choose]
