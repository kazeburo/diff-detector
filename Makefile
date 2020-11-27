VERSION=0.0.10
LDFLAGS=-ldflags "-w -s -X main.version=${VERSION}"
GO111MODULE=on

all: diff-detector

.PHONY: diff-detector

diff-detector: diff-detector.go
	go build $(LDFLAGS) -o diff-detector

linux: diff-detector.go
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o diff-detector

clean:
	rm -rf diff-detector

check:
	go test ./...

tag:
	git tag v${VERSION}
	git push origin v${VERSION}
	git push origin master
