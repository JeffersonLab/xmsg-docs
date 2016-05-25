.PHONY: all clean pdf html figs

FILE := xmsg-java
VERSION := 2.3
OUTPUT := $(FILE)-$(VERSION)

FIGDIR := img
TEXFIGS := $(wildcard $(FIGDIR)/*.md)
PDFFIGS := $(TEXFIGS:.md=.pdf)
PNGFIGS := $(TEXFIGS:.md=.png)

METADATA := -M title='xMsg $(VERSION) (Java)' \
            -M fontsize=11pt \
            -M lang=en \
            -M logo=true

TEXTMPL := template.latex

TEXENGINE := --latex-engine=xelatex
TEXOPTIONS := --highlight-style=pygments --default-image-extension=pdf
HTMLOPTIONS := --highlight-style=pygments --default-image-extension=png


all: pdf html

pdf: $(OUTPUT).pdf

html: $(OUTPUT).html

figs: $(PNGFIGS)


$(OUTPUT).pdf: $(FILE).rst $(PDFFIGS) $(TEXTMPL)
	sed -e 's/^.. note:://' \
	    -e 's/^\(.. figure:: .*\)\.\*$$/\1.pdf/' \
	$< | pandoc -f rst $(METADATA) \
	    --template=$(TEXTMPL) $(TEXENGINE) $(TEXOPTIONS) -sS -o $@

$(OUTPUT).html: $(FILE).rst $(PNGFIGS) style.css
	sed -e 's/^.. note:://' \
	    -e 's/^.. figure:: \(.*\)\.\*$$/.. image:: \1.png/' \
	$< | pandoc -f rst $(METADATA) \
	    --css style.css $(HTMLOPTIONS) --toc -sS -o $@

$(FIGDIR)/%.pdf: $(FIGDIR)/%.md
	pandoc --template=$(TEXTMPL) $(TEXENGINE) -sS $< -o $@
	pdfcrop $@ $@

$(FIGDIR)/%.png: $(FIGDIR)/%.pdf
	convert \
	    -density 300 -units PixelsPerInch \
	    -gravity center -extent 1100x110 -background none \
	    -quality 100 $< $@

clean:
	rm -f $(OUTPUT).pdf $(OUTPUT).html *.log *.aux
	rm -f $(FIGDIR)/*.pdf $(FIGDIR)/*.png $(FIGDIR)/*.log $(FIGDIR)/*.aux
