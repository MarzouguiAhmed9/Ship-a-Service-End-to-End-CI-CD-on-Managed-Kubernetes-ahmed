package main

import (
    "encoding/json"
    "net/http"
    "os"
)

func main() {
    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        sysEnv := os.Getenv("SYS_ENV")
        payload := map[string]string{
            "status":  "ok",
            "SYS_ENV": sysEnv,
        }
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(payload)
    })

    http.ListenAndServe(":8080", nil)
}
// trigger CI test
// trigger CI test
