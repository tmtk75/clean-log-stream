COMMIT := $(shell git rev-parse HEAD)
VAR_COMMIT := main.Commit
LDFLAGS := -ldflags "-X $(VAR_COMMIT)=$(COMMIT)"
clean-log-stream: main.go
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o clean-log-stream main.go

