(TeX-add-style-hook
 "package_diagram"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("standalone" "tikz" "convert={density=72,outext=.png, outfile=package_diagram.png}")))
   (TeX-run-style-hooks
    "latex2e"
    "standalone"
    "standalone10"
    "tikz-uml")))

