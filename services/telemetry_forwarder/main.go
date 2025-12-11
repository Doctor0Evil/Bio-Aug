package main

import (
    "bytes"
    "encoding/json"
    "log"
    "net/http"
    "time"
)

// Metric is a simplified, IEEE 11073 like metric.
type Metric struct {
    DeviceID string  `json:"device_id"`
    Code     string  `json:"code"`
    Value    float64 `json:"value"`
    Unit     string  `json:"unit"`
    Time     string  `json:"time"`
}

func toFhirObservation(m Metric) map[string]interface{} {
    return map[string]interface{}{
        "resourceType": "Observation",
        "status": "final",
        "code": map[string]interface{}{"coding": []map[string]string{{"system": "http://loinc.org", "code": m.Code}}},
        "valueQuantity": map[string]interface{}{"value": m.Value, "unit": m.Unit},
        "effectiveDateTime": m.Time,
    }
}

func publishFHIR(observation map[string]interface{}) error {
    body, err := json.Marshal(observation)
    if err != nil { return err }
    // Replace with the actual FHIR endpoint and proper authentication.
    resp, err := http.Post("https://fhir.example.org/Observation", "application/json", bytes.NewReader(body))
    if err != nil { return err }
    defer resp.Body.Close()
    if resp.StatusCode < 200 || resp.StatusCode >= 300 {
        return &httpError{StatusCode: resp.StatusCode}
    }
    return nil
}

type httpError struct{ StatusCode int }
func (h *httpError) Error() string { return "http status: " + http.StatusText(h.StatusCode) }

func main() {
    // Example: simulate forwarding a Metric
    metric := Metric{DeviceID: "dev-001", Code: "8480-6", Value: 98.6, Unit: "degF", Time: time.Now().UTC().Format(time.RFC3339)}
    obs := toFhirObservation(metric)
    if err := publishFHIR(obs); err != nil {
        log.Printf("Failed to publish fhir: %v", err)
    } else {
        log.Printf("Published observation for device %s", metric.DeviceID)
    }
}
