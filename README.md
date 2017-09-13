# xMsg documentation

### Dependencies

The xMsg documentation is generated using [Jekyll](http://jekyllrb.com/).

Install [Docker](https://docs.docker.com/engine/installation/) to run
the required Jekyll version inside a container.

### Generating the docs

To update the documentation and watch the changes locally, start the Jekyll
server inside a Docker container:

    make serve

The generated static files will be located in `_site`.

### Deploying the website

To deploy to <http://claraweb.jlab.org/xmsg> do:

    make build
    make deploy

