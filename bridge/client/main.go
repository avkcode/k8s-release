package main

import (
    "fmt"
    "log"
    "os"
    "os/signal"
    "syscall"

    "github.com/nats-io/nats.go"
)

func main() {
    // Connect to the NATS server
    nc, err := nats.Connect("nats://localhost:4222")
    if err != nil {
        log.Fatalf("Failed to connect to NATS server: %v", err)
    }
    defer nc.Close()

    // Subscribe to all subjects using the ">" wildcard
    subscription, err := nc.Subscribe(">", func(msg *nats.Msg) {
        fmt.Printf("Received message on subject '%s': %s\n", msg.Subject, string(msg.Data))
    })
    if err != nil {
        log.Fatalf("Failed to subscribe: %v", err)
    }
    defer subscription.Unsubscribe()

    // Wait for interrupt signal to gracefully shut down
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    <-sigCh
    log.Println("Shutting down gracefully...")
}
