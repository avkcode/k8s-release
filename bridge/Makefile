.DEFAULT_GOAL := help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@echo "  all           - Start a NATS server container in detached mode."
	@echo "  install-golang - Download and install the latest version of Golang."
	@echo "  install-nats-cli - Download and install the latest version of NATS CLI."
	@echo "  help          - Show this help message."

all:
	@docker run -p 4222:4222 -d nats:latest

install-golang:
	@echo "Downloading and installing the latest version of Golang..."
	@GO_VERSION=$$(curl -s https://go.dev/VERSION?m=text | head -n 1) && \
	echo "Latest Go version: $$GO_VERSION" && \
	curl -LO https://golang.org/dl/$$GO_VERSION.linux-amd64.tar.gz && \
	sudo tar -C /usr/local -xzf $$GO_VERSION.linux-amd64.tar.gz && \
	rm -f $$GO_VERSION.linux-amd64.tar.gz && \
	if ! grep -q 'export PATH=$$PATH:/usr/local/go/bin' ~/.bashrc; then \
		echo 'export PATH=$$PATH:/usr/local/go/bin' >> ~/.bashrc; \
	fi && \
	echo "Go installation complete. Run 'source ~/.bashrc' to update your PATH."

install-nats-cli:
	@echo "Downloading and installing NATS CLI..."
	@NATS_CLI_VERSION=0.1.6 \
	curl -fLO https://github.com/nats-io/natscli/releases/download/v$$NATS_CLI_VERSION/nats-$$NATS_CLI_VERSION-amd64.deb && \
	sudo dpkg -i nats-$$NATS_CLI_VERSION-amd64.deb && \
	rm -f nats-$$NATS_CLI_VERSION-amd64.deb && \
	echo "NATS CLI installation complete. Run 'nats --version' to verify."
