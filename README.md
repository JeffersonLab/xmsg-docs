# xMsg documentation

Under construction...


### Dependencies

The xMsg documentation is generated using [Sphinx](http://sphinx-doc.org).
Install it with:

    sudo pip install sphinx

The Sphinx theme can be installed with:

    sudo pip install sphinx-rtd-theme

To generate a PDF version of the documentation, *LaTeX* is also required.

### Generating the docs

To generate the documentation, run:

    make clean html

or

    make clean latexpdf

The output files will be located in `build/html` or `build/latex`.
