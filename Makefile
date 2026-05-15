BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
DIRTY  := $(shell git status --porcelain)

.PHONY: release
release: ## Create a GitHub release. Usage: make release VERSION=0.1.0
ifndef VERSION
	$(error VERSION is required. Usage: make release VERSION=0.1.0)
endif
ifneq ($(BRANCH),main)
	$(error Releases must be cut from main. Currently on: $(BRANCH))
endif
ifneq ($(DIRTY),)
	$(error Working tree has uncommitted changes. Clean up before releasing.)
endif
	gh release create "v$(VERSION)" \
		--title "v$(VERSION)" \
		--generate-notes \
		--target main
