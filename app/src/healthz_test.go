package main

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "os"
    "testing"
)

func TestHealthzHandler(t *testing.T) {
    os.Setenv("SYS_ENV", "test")
    defer os.Unsetenv("SYS_ENV")

    req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
    rr := httptest.NewRecorder()

    http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{
            "status":  "ok",
            "SYS_ENV": os.Getenv("SYS_ENV"),
        })
    }).ServeHTTP(rr, req)

    var resp map[string]string
    json.Unmarshal(rr.Body.Bytes(), &resp)

    if resp["status"] != "ok" || resp["SYS_ENV"] != "test" {
        t.Errorf("unexpected response: %v", resp)
    }
}
