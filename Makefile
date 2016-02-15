VERSION=0.0.5

all: diff-detector

.PHONY: diff-detector

gom:
	go get -u github.com/mattn/gom

bundle:
	gom install

diff-detector: diff-detector.go
	gom build -o diff-detector

linux: diff-detector.go
	GOOS=linux GOARCH=amd64 gom build -o diff-detector

fmt:
	go fmt ./...

dist:
	git archive --format tgz HEAD -o diff-detector-$(VERSION).tar.gz --prefix diff-detector-$(VERSION)/

clean:
	rm -rf diff-detector my-ec2-tag-*.tar.gz

