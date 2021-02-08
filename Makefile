start_app:
	iex -S mix phx.server

.PHONY: lint
lint: ## Formating, linting and compiling
	mix format
	mix compile --all-warnings --force
	mix credo --strict

.PHONY: setup_app
setup_app: ## Formating, linting and compiling
	mix deps.clean --all
	mix deps.get
	mix compile --all-warnings --force