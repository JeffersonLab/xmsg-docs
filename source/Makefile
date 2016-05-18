.PHONY: all clean pdf html

FILE := xmsg-java
VERSION := 2.3
OUTPUT := $(FILE)-$(VERSION)

FIGDIR := img
TEXFIGS := $(wildcard $(FIGDIR)/*.md)
PDFFIGS := $(TEXFIGS:.md=.pdf)
PNGFIGS := $(TEXFIGS:.md=.png)

TEXTMPL := template.latex

TEXENGINE := --latex-engine=xelatex
TEXOPTIONS := --highlight-style=pygments --default-image-extension=pdf
HTMLOPTIONS := --highlight-style=pygments --default-image-extension=png


all: pdf html

pdf: $(OUTPUT).pdf

html: $(OUTPUT).html


$(OUTPUT).pdf: $(FILE).md $(PDFFIGS) $(TEXTMPL)
	pandoc --template=$(TEXTMPL) $(TEXENGINE) $(TEXOPTIONS) -sS $< -o $@

$(OUTPUT).html: $(FILE).md $(PNGFIGS) style.css
	pandoc --css style.css $(HTMLOPTIONS) --toc -sS $< -o $@

$(FIGDIR)/%.pdf: $(FIGDIR)/%.md
	pandoc --template=$(TEXTMPL) $(TEXENGINE) -sS $< -o $@
	pdfcrop $@ $@

$(FIGDIR)/%.png: $(FIGDIR)/%.pdf
	convert -density 300 -units PixelsPerInch -quality 100 $< $@

clean:
	rm -f $(OUTPUT).pdf $(OUTPUT).html *.log *.aux
	rm -f $(FIGDIR)/*.pdf $(FIGDIR)/*.png $(FIGDIR)/*.log $(FIGDIR)/*.aux
