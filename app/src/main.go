package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "sync/atomic"
)

var requestCount uint64 // counter

func main() {
    // Health endpoint
    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        sysEnv := os.Getenv("SYS_ENV")
        payload := map[string]string{
            "status":  "ok",
            "SYS_ENV": sysEnv,
        }
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(payload)
    })

    http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "text/plain")
        fmt.Fprintf(w, "my_app_requests_total %d\n", atomic.LoadUint64(&requestCount))
    })

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        atomic.AddUint64(&requestCount, 1)
        w.Write([]byte("Hello World!\n"))
    })

    http.ListenAndServe("0.0.0.0:8080", nil)
}
