# Makefile for xMsg documentation

# Docker variables
DOCKER_COMPOSE = docker-compose
DOCKER_SERVICE = mkdocs

MKDOCS_BUILD   = build --verbose

# Deploy variables
WEBDIR = /group/clas/www/claraweb/html
MACHINE = clara1601

.PHONY: build
build:
	@$(DOCKER_COMPOSE) run --rm $(DOCKER_SERVICE) $(MKDOCS_BUILD)

.PHONY: serve
serve:
	@$(DOCKER_COMPOSE) up || $(DOCKER_COMPOSE) stop

.PHONY: deploy
deploy:
	@echo "Deploying site..."
	@rsync -rlcvP --exclude=/api --delete-after site/ "$(MACHINE):$(WEBDIR)/xmsg/"
	@echo "Fixing permissions..."
	@ssh $(MACHINE) "find $(WEBDIR) -user $(USER) -exec chgrp clasweba {} \; -exec chmod g+w {} \;"
	@echo "Done"

.PHONY: clean
clean:
	rm -rf _site site
