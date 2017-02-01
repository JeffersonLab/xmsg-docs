# Makefile for xMsg documentation
#

BUILDDIR      = _site

# Docker variables
DOCKER_COMPOSE = docker-compose
DOCKER_SERVICE = jekyll

JEKYLL_BUILD   = jekyll build --verbose

# Deploy variables
WEBDIR = /group/clas/www/claraweb/html
MACHINE = claradm

.PHONY: build
build:
	@$(DOCKER_COMPOSE) run --rm $(DOCKER_SERVICE) $(JEKYLL_BUILD)

.PHONY: serve
serve:
	@$(DOCKER_COMPOSE) up || true

.PHONY: deploy
deploy:
	@echo "Deploying site..."
	@rsync -avP --exclude=/api/ --delete-after _site/ "$(MACHINE):$(WEBDIR)/xmsg/"
	@echo "Fixing permissions..."
	@ssh $(MACHINE) "find $(WEBDIR) -user $(USER) -exec chgrp clasweba {} \; -exec chmod g+w {} \;"
	@echo "Done"

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
