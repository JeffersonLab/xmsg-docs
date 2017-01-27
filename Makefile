# Makefile for xMsg documentation
#

BUILDDIR      = _site
CONFIG_FILES  = _config.yml,_config_prod.yml

# Docker variables
DOCKER_COMPOSE = docker-compose
DOCKER_SERVICE = jekyll

JEKYLL_BUILD   = jekyll build --verbose --config $(CONFIG_FILES)

.PHONY: build
build:
	@$(DOCKER_COMPOSE) run $(DOCKER_SERVICE) $(JEKYLL_BUILD)

.PHONY: serve
serve:
	@$(DOCKER_COMPOSE) up || true

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
