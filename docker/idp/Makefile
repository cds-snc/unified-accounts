docker:
	docker build -t idp:latest .

pull_request: docker lint test

.PHONY: \
	docker \
	pull_request
