docker:
	docker build -t alarms-slack:latest .

fmt:
	gofmt -s -w .

lint:
	go vet ./...

test:
	go test -v ./...

tidy:
	go mod tidy

pull_request: docker lint test

.PHONY: \
	docker \
	fmt \
	lint \
	pull_request \
	test \
	tidy