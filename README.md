# xMsg documentation

### Dependencies

The xMsg documentation is generated using [MkDocs](https://www.mkdocs.org/),
with the [Material for MkDocs](https://squidfunk.github.io/mkdocs-material) theme.

Install [Docker](https://docs.docker.com/engine/installation/) to run
the required MkDocs version inside a container.

### Generating the docs

To update the documentation and watch the changes locally, start the MkDocs
server inside a Docker container:

    make serve


### Deploying the website

To deploy to <http://claraweb.jlab.org/xmsg> do:

    make build
    make deploy

The generated static files will be located in `site`
and copied into the server.
