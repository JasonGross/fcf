(* The El Gamal encryption scheme and a proof that it is IND-CPA-secure. *)

Set Implicit Arguments.

Require Import Crypto.
Require Import RndNat.
Require Import RndGrpElem.
Require Import Encryption_PK.
Require Import DiffieHellman.
Require Import OTP.

Local Open Scope group_scope.

Section ElGamal.

  Variable order : posnat.
  
  Context`{FCG : FiniteCyclicGroup order}.

  Hypothesis GroupElement_EqDec : EqDec GroupElement.

  Definition ElGamalKeygen :=
    m <-$ [0 .. order);
    ret (m, g^m).

  Definition ElGamalEncrypt(msg key : GroupElement) := 
    m <-$ [0 .. order);
    ret (g^m, key^m * msg).

  Variable A_State : Set.
  Hypothesis A_State_EqDec : EqDec A_State.

  Variable A1 : GroupElement -> Comp (GroupElement * GroupElement * A_State).
  Hypothesis wfA1 : forall x, well_formed_comp (A1 x).

  Variable A2 : (GroupElement * GroupElement * A_State) -> Comp bool.
  Hypothesis wfA2 : forall x, well_formed_comp (A2 x).  

  (* Build an adversary from A1 and A2 that can win DDH *)
  Definition B(g_xyz : (GroupElement * GroupElement * GroupElement)) : Comp bool :=
    [gx, gy, gz] <-3 g_xyz;
    [p0, p1, s] <-$3 A1(gx);
    b <-$ {0,1};
    pb <- if b then p0 else p1;
      c <- (gy, gz * pb);
      b' <-$ (A2 (c, s));
      ret (eqb b b').

  Theorem ElGamal_IND_CPA0 :
    Pr[IND_CPA_G ElGamalKeygen ElGamalEncrypt A1 A2] == 
    Pr[DDH0 B].
    
    unfold IND_CPA_G, DDH0, ElGamalKeygen, ElGamalEncrypt, B.

    inline_first.
    comp_skip.

    comp_at comp_inline rightc 1%nat.
    comp_swap rightc.
    comp_skip.

    comp_at comp_inline rightc 1%nat.
    comp_swap rightc.
    comp_skip.

    comp_inline leftc.
    comp_skip.

    comp_inline rightc.
    comp_skip.
    rewrite groupExp_mult; intuition.

    comp_simp.
    intuition.
  Qed.

  Definition G1 :=
    gx <-$ RndG;
    gy <-$ RndG;
    [p0, p1, s] <-$3 (A1 gx);
    b <-$ {0, 1};
    gz' <-$ (
    pb <- if b then p0 else p1;
    gz <-$ RndG ; ret (gz * pb));
    b' <-$ (A2 (gy, gz', s));
    ret (eqb b b').

  Definition G2 :=
    gx <-$ RndG;
    gy <-$ RndG;
    [p0, p1, s] <-$3 (A1 gx);
    gz <-$ RndG ;
    b' <-$ (A2 (gy, gz, s));
    b <-$ {0, 1};
    ret (eqb b b').

  Theorem ElGamal_G1_DDH1 :
    Pr [ G1] == Pr [ DDH1 B ].

    unfold G1, DDH1, B, RndGrpElem.

    inline_first.
    comp_skip.
    inline_first.
    comp_skip.

    comp_at comp_inline rightc 1%nat.
    comp_swap rightc.
    comp_skip.

    comp_at comp_inline leftc 1%nat.
    comp_at comp_inline leftc 1%nat.
    comp_swap leftc.
    comp_skip.
    
    comp_inline rightc.
    comp_skip.
    
    inline_first.
    comp_skip.

    comp_simp.
    intuition.
    
  Qed.   
   
  Theorem ElGamal_G1_G2 :
    Pr[G1] == Pr[G2].
    
    unfold G1, G2, B.
    
    do 3 comp_skip.
    comp_at comp_swap rightc 1%nat.
    comp_swap rightc.
    comp_skip.

    eapply group_OTP_r; intuition.
    subst.
    
    comp_skip.
  Qed.

  Theorem ElGamal_G2_OneHalf :
    Pr [G2] == 1 / 2.
   
    unfold G2.

    (* ignore the first 5 commands *)
    do 3 comp_irr_l.
    comp_simp.
    do 2 comp_irr_l.
    (* compute the probability *)
    comp_ute.
  Qed.
  
  Theorem ElGamal_IND_CPA_Advantage :
    (IND_CPA_Advantage ElGamalKeygen ElGamalEncrypt A1 A2) ==
    (DDH_Advantage B).

    unfold IND_CPA_Advantage, DDH_Advantage.
    eapply ratDistance_eqRat_compat.    
    eapply ElGamal_IND_CPA0.
    rewrite <- ElGamal_G1_DDH1.
    rewrite ElGamal_G1_G2.
    symmetry.
    eapply ElGamal_G2_OneHalf.
  Qed.

End ElGamal.