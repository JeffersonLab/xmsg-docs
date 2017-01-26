# Makefile for xMsg documentation
#

BUILDDIR      = _site

# Docker variables
DOCKER_COMPOSE = docker-compose
DOCKER_SERVICE = jekyll

.PHONY: build
build:
	@$(DOCKER_COMPOSE) run $(DOCKER_SERVICE) jekyll build --verbose

.PHONY: serve
serve:
	@$(DOCKER_COMPOSE) up || true

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
