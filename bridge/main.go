// Kubernetes Event and Namespace Watcher with NATS Integration
//
// Overview:
// This program watches Kubernetes events and namespace resources and publishes
// relevant updates to a NATS messaging server. It uses the Kubernetes client-go
// library to interact with the Kubernetes API and the NATS Go client library to
// publish messages.
//
// Features:
// - Watches Kubernetes events (added, updated, deleted) across all namespaces.
// - Watches Kubernetes namespace resources (created, updated, deleted).
// - Publishes these events to NATS topics for further processing.
// - Supports both in-cluster and out-of-cluster Kubernetes configurations.
// - Gracefully shuts down on interrupt signals (SIGINT, SIGTERM).
//
// Usage:
// 1. Build the program:
//    go build -o k8s-nats-watcher main.go
//
// 2. Run the program:
//    ./k8s-nats-watcher [flags]
//
// Flags:
//   -kubeconfig string
//         Path to kubeconfig file (optional, defaults to in-cluster config if not specified).
//   -nats string
//         NATS server URL (default "nats://localhost:4222").
//
// Example:
//   # Run with default NATS server and in-cluster Kubernetes config
//   ./k8s-nats-watcher
//
//   # Run with custom kubeconfig and NATS server
//   ./k8s-nats-watcher -kubeconfig ~/.kube/config -nats nats://nats-server:4222
//
// Dependencies:
// - Kubernetes client-go library: https://github.com/kubernetes/client-go
// - NATS Go client library: https://github.com/nats-io/nats.go
//
// NATS Topics:
// - Kubernetes Events:
//   - "k8s.event.added": Published when a new event is added.
//   - "k8s.event.updated": Published when an existing event is updated.
//   - "k8s.event.deleted": Published when an event is deleted.
// - Kubernetes Namespaces:
//   - "k8s.namespace.created": Published when a new namespace is created.
//   - "k8s.namespace.updated": Published when a namespace is updated.
//   - "k8s.namespace.deleted": Published when a namespace is deleted.
//
// Notes:
// - Ensure the NATS server is running and accessible at the specified URL.
// - For in-cluster operation, the program must run inside a Kubernetes pod with appropriate RBAC permissions.
// - For out-of-cluster operation, provide a valid kubeconfig file.

package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "os/signal"
    "syscall"

    "github.com/nats-io/nats.go" // Import NATS client library
    corev1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/watch"
    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
    "k8s.io/client-go/tools/cache"
    "k8s.io/client-go/tools/clientcmd"
)

func main() {
    // Parse flags for kubeconfig and NATS server URL
    kubeconfig := flag.String("kubeconfig", "", "Path to kubeconfig file (optional, defaults to in-cluster config)")
    natsURL := flag.String("nats", "nats://localhost:4222", "NATS server URL")
    flag.Parse()

    // Create Kubernetes client configuration
    var config *rest.Config
    var err error
    if *kubeconfig != "" {
        config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)
    } else {
        config, err = rest.InClusterConfig()
    }
    if err != nil {
        log.Fatalf("Failed to create Kubernetes config: %v", err)
    }

    // Create Kubernetes clientset
    clientset, err := kubernetes.NewForConfig(config)
    if err != nil {
        log.Fatalf("Failed to create Kubernetes clientset: %v", err)
    }

    // Connect to NATS server
    nc, err := nats.Connect(*natsURL)
    if err != nil {
        log.Fatalf("Failed to connect to NATS server: %v", err)
    }
    defer nc.Close()

    // Watch Kubernetes Events
    go watchKubernetesEvents(clientset, nc)

    // Watch Namespace Resources
    go watchNamespaces(clientset, nc)

    // Graceful shutdown on interrupt signal
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    <-sigCh
    log.Println("Shutting down gracefully...")
}

// Watch Kubernetes Events
func watchKubernetesEvents(clientset *kubernetes.Clientset, nc *nats.Conn) {
    eventWatcher := cache.NewSharedInformer(
        cache.NewFilteredListWatchFromClient(
            clientset.CoreV1().RESTClient(),
            "events",
            corev1.NamespaceAll, // Watch all namespaces
            func(options *metav1.ListOptions) {}, // No filtering
        ),
        nil, // Object type (nil means use default Event type)
        0,   // Resync period (0 means no resync)
    )

    // Handle events from the informer
    eventWatcher.AddEventHandler(cache.ResourceEventHandlerFuncs{
        AddFunc: func(obj interface{}) {
            event, ok := obj.(*corev1.Event)
            if !ok {
                log.Printf("Unexpected object type: %T", obj)
                return
            }
            publishEvent(nc, "k8s.event.added", event)
        },
        UpdateFunc: func(oldObj, newObj interface{}) {
            newEvent, ok := newObj.(*corev1.Event)
            if !ok {
                log.Printf("Unexpected object type: %T", newObj)
                return
            }
            publishEvent(nc, "k8s.event.updated", newEvent)
        },
        DeleteFunc: func(obj interface{}) {
            event, ok := obj.(*corev1.Event)
            if !ok {
                log.Printf("Unexpected object type: %T", obj)
                return
            }
            publishEvent(nc, "k8s.event.deleted", event)
        },
    })

    // Start the informer
    stopCh := make(chan struct{})
    defer close(stopCh)
    go eventWatcher.Run(stopCh)

    // Wait for the informer to sync
    if !cache.WaitForCacheSync(stopCh, eventWatcher.HasSynced) {
        log.Fatalf("Failed to sync informer cache")
    }
}

// Watch Namespace Resources
func watchNamespaces(clientset *kubernetes.Clientset, nc *nats.Conn) {
    watcher, err := clientset.CoreV1().Namespaces().Watch(context.TODO(), metav1.ListOptions{})
    if err != nil {
        log.Fatalf("Failed to create Namespace watcher: %v", err)
    }
    defer watcher.Stop()

    for event := range watcher.ResultChan() {
        switch event.Type {
        case watch.Added:
            namespace, ok := event.Object.(*corev1.Namespace)
            if !ok {
                log.Printf("Unexpected object type: %T", event.Object)
                continue
            }
            publishNamespaceEvent(nc, "k8s.namespace.created", namespace)
        case watch.Modified:
            namespace, ok := event.Object.(*corev1.Namespace)
            if !ok {
                log.Printf("Unexpected object type: %T", event.Object)
                continue
            }
            publishNamespaceEvent(nc, "k8s.namespace.updated", namespace)
        case watch.Deleted:
            namespace, ok := event.Object.(*corev1.Namespace)
            if !ok {
                log.Printf("Unexpected object type: %T", event.Object)
                continue
            }
            publishNamespaceEvent(nc, "k8s.namespace.deleted", namespace)
        default:
            log.Printf("Unknown event type: %v", event.Type)
        }
    }
}

// Publish Kubernetes Event to NATS
func publishEvent(nc *nats.Conn, subject string, event *corev1.Event) {
    msg := fmt.Sprintf(
        `{"namespace": "%s", "name": "%s", "reason": "%s", "message": "%s", "involvedObject": {"kind": "%s", "name": "%s"}, "type": "%s", "firstTimestamp": "%s", "lastTimestamp": "%s"}`,
        event.Namespace,
        event.Name,
        event.Reason,
        event.Message,
        event.InvolvedObject.Kind,
        event.InvolvedObject.Name,
        event.Type,
        event.FirstTimestamp,
        event.LastTimestamp,
    )
    err := nc.Publish(subject, []byte(msg))
    if err != nil {
        log.Printf("Failed to publish event to NATS: %v", err)
    } else {
        log.Printf("Published event to NATS: %s", subject)
    }
}

// Publish Namespace Event to NATS
func publishNamespaceEvent(nc *nats.Conn, subject string, namespace *corev1.Namespace) {
    msg := fmt.Sprintf(
        `{"name": "%s", "status": "%s"}`,
        namespace.Name,
        namespace.Status.Phase,
    )
    err := nc.Publish(subject, []byte(msg))
    if err != nil {
        log.Printf("Failed to publish namespace event to NATS: %v", err)
    } else {
        log.Printf("Published namespace event to NATS: %s", subject)
    }
}
