NAME=tlb_address

png: pdf
	convert -density 72 ${NAME}.pdf -quality 90 ../../${NAME}.png

pdf: ${NAME}.tex
	latexmk -lualatex ${NAME}.tex
