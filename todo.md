UI work
=======
allow manual specification of differentials
allow control over which bases are used to display a particular EXTTerm


backend work
============
replace EXTPair with some general grading object
add entire polynomial families at once, propagate products with existing classes
allow for a SS to be a module over another SS of algebras
allow for a partially defined multiplicative structure
handle stretching the window well, i.e., make the recalculation of the newly uncovered part of the SS computationally unintensive
handle adding dimensions to the spectral sequence sanely --- right now the differentials and multiplicative structure matrices are unlinked in every real way to the EXTTerm they belong to, which means things can get badly out of sync.


goals
=====
automatic computation of May SS
 + subgoal: get it to automatically compute Ext_A(1)(k, k).  the relevant filtration for A(1) looks like E[Q1] --> A(1) --> E[Sq1, Sq2] / Q1.  dually, this looks like F2[xi2] / xi2^2 <-- F2[xi1, xi2] / etc <-- F2[x1] / x1^4.  Lyndon-Hochschild-Serre computes the Ext over these two corner coalgebras as F2[v1] and F2[h0, h1] respectively.
 + subgoal: then, try Ext_A(2)(k, k).
automatic propagation of differentials via...
 + Leibniz rule
 + Steenrod structure in the May and Serre spectral sequences


some other questions
====================
are there existing software packages for computing E_2^MSS?