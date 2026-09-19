# trembus-swift — every command goes through Scripts/swiftw, which picks a toolchain that
# can build SwiftUI (see that file for why plain `swift` may not).
#
#   make            list commands
#   make snap       see every component in every theme
#   make gallery    feel them
#   make validate   the gate — run before calling anything done

SWIFT  := Scripts/swiftw
PATHS  := Sources Tests Package.swift

.DEFAULT_GOAL := help
.PHONY: help build test snap neighbors forms gallery new format lint validate xcode doctor clean

help: ## list commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-z]+:.*## / {printf "  make %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "  options:  make snap NAME=Button          one entry"
	@echo "            make snap NAME=Button ARGS='--singles --scale 3'"
	@echo "            make neighbors NAME=Surface"
	@echo "            make gallery NAME=Button THEME=dark"
	@echo "            make new NAME=Tag LEAD=reveal-state"

build: ## compile everything
	@$(SWIFT) build

test: ## run the gate's tests: contrast, contracts, rendering, logic
	@$(SWIFT) test

snap: ## render PNG contact sheets → Snapshots/   (NAME=Button for one)
	@$(SWIFT) run TrembusSnap $(NAME) $(ARGS)

neighbors: ## what to re-look at when NAME changes — everything that builds on it
	@$(SWIFT) run TrembusSnap --neighbors $(NAME)

forms: ## every Form + what each Shape builds on, as JSON (for consumers / a Relay House)
	@$(SWIFT) run TrembusSnap --forms

gallery: ## open the live gallery app   (NAME=Button THEME=dark)
	@Scripts/gallery $(if $(NAME),--entry $(NAME)) $(if $(THEME),--theme $(THEME))

new: ## scaffold a component: make new NAME=Tag [LEAD=reveal-state|afford-action|acknowledge-input]
	@Scripts/new-component $(NAME) $(if $(LEAD),--lead $(LEAD))

format: ## rewrite sources to house style
	@$(SWIFT) format -i -r $(PATHS)

lint: ## check house style, change nothing
	@$(SWIFT) format lint --strict -r $(PATHS)

validate: lint build test ## THE GATE: lint + build + test
	@echo "✓ validate passed"

xcode: ## open the package in Xcode (canvas previews live in Sources/TrembusCatalog/Entries)
	@open -a Xcode Package.swift

doctor: ## which toolchain is being used, and why
	@$(SWIFT) --doctor

clean: ## delete build products and snapshots
	@rm -rf .build Snapshots
	@echo "cleaned"
