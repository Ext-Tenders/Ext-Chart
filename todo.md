UI work
=======
here is a partial list of things the interface should provide, plus some other thoughts.
- click to add a class.
- click to add a polynomial family.  (tool settings on the left: specify a truncation degree?  alternatively, click and drag to specify a truncation degree?)
- click to specify multiplicative structure: need to pick two classes, then jump to matrix entry.
- apply Leibniz rule: pick a list of locations by a series of clicks, then perform some kind of release click to run the Leibniz tool.  (maybe the selected locations should be displayed in a list in an inspector pane, as well as highlighted in the View itself?)
- click to select a differential: also needs to pick two classes, but then can be done in two ways.  either the target class can be selected automatically based on the current page, or the target class can be specified manually (by a drag and release?) and then the active page changes to match.  if a differential doesn't exist, then add it.
- once a differential is selected, a pane should let you see its EXTPartialDefinitions, which can be added, deleted, and edited in some kind of matrix editor.
- an EXTPolynomialSSeq class lets you resize polynomial generators after they've been added.  this should also be advertised as a sometimes-active tool.  here you're selecting not just any EXTTerm but a specifically marked member --- maybe the selection process should just be completely different from clicking the thing on the page, i don't know.

anyway: i think that not only should there be a toolbar with a bunch of tools, but also there should be some kind of inspector / tool settings pane.

deleting classes will be tricky; there isn't support for this in the model yet.

another thing Mike would like in the model/view boundary: a change-of-basis matrix attached to each particular EXTTerm, which doesn't affect internal calculations but does affect how the user interacts (via input matrices) with the sseq.


backend work
============
- [x] add entire polynomial families at once, propagate products with existing classes
- [ ] allow for a SS to be a module over another SS of algebras
- [x] allow for a partially defined multiplicative structure
- [ ] handle stretching the window well, i.e., make the recalculation of the newly uncovered part of the SS computationally unintensive
- [ ] handle adding dimensions to the spectral sequence sanely --- right now the differentials and multiplicative structure matrices are unlinked in every real way to the EXTTerm they belong to, which means things can get badly out of sync.


goals
=====
- [ ] automatic computation of May SS
    + [ ] subgoal: get it to automatically compute Ext_A(1)(k, k).  the relevant filtration for A(1) looks like E[Q1] --> A(1) --> E[Sq1, Sq2] / Q1.  dually, this looks like F2[xi2] / xi2^2 <-- F2[xi1, xi2] / etc <-- F2[x1] / x1^4.  Lyndon-Hochschild-Serre computes the Ext over these two corner coalgebras as F2[v1] and F2[h0, h1] respectively.
    + [ ] subgoal: then, try Ext_A(2)(k, k).
- [ ] automatic propagation of differentials via...
    + Leibniz rule
    + Steenrod structure in the May and Serre spectral sequences


some other questions
====================
 + are there existing software packages for computing E_2^MSS?
 + should we perform internal consistency checks?

flowcharts for some other things
================================
When adding a fresh differential:
 + Modify the matrix of differentials
 + Iterate through the other terms
      + Multiply them together and apply the Leibniz rule
      + Apply the various squaring operations and Kudo's rule
      + Act by some ring and apply linearity.

When modifying the product structure of existing classes:
 + Check the Leibniz / Kudo / linearity rules.
 + If they match…
      + do nothing.
      + otherwise, ask what to do.
      + If we're told to accept a new definition, modify the differential and propagate.
 
Keep in mind the tensor ordering convention:
    e1 | f1, e1 | f2, e2 | f1, e2 | f2.