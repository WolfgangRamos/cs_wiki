(TeX-add-style-hook
 "tlb_address"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("standalone" "tikz" "convert={density=72,outext=.png, outfile=tlb_adress.png}")))
   (TeX-run-style-hooks
    "latex2e"
    "standalone"
    "standalone10")))

