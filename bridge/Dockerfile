# Stage 1: Build the Go application
FROM golang:1.20 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY go.mod go.sum ./

RUN go mod download

# Download dependencies
RUN go mod download

# Copy the rest of the application code
COPY . .

# Build the application (statically linked binary for better portability)
RUN CGO_ENABLED=0 GOOS=linux go build -o k8s-nats-watcher main.go

# Stage 2: Create a minimal runtime image
FROM alpine:3.18

# Install necessary tools (e.g., ca-certificates for HTTPS/TLS support)
RUN apk add --no-cache bash

# Set the working directory
WORKDIR /root/

# Copy the compiled binary from the builder stage
COPY --from=builder /app/k8s-nats-watcher .

# Expose any ports if needed (optional, since this app doesn't listen on a port)
# EXPOSE 8080

# Command to run the application
CMD ["./k8s-nats-watcher", "-nats", "nats://localhost:4222"]
