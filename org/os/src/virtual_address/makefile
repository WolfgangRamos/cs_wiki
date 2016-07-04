NAME=virtual_address

png: pdf
	convert -density 72 ${NAME}.pdf -quality 90 ../../${NAME}.png

pdf: virtual_address.tex
	latexmk -lualatex ${NAME}.tex
