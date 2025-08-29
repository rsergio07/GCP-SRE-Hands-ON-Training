# SRE Monitoring Queries for Production Use

## The Four Golden Signals

### 1. Latency
- **Request Duration P95**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
- **Request Duration P99**: `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))`
- **Average Response Time**: `rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])`

### 2. Traffic
- **Requests per Second**: `sum(rate(http_requests_total[5m]))`
- **Requests by Endpoint**: `sum(rate(http_requests_total[5m])) by (endpoint)`
- **Business Operations Rate**: `sum(rate(business_operations_total[5m])) by (operation_type)`

### 3. Errors
- **Error Rate Percentage**: `sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`
- **4xx Rate**: `sum(rate(http_requests_total{status_code=~"4.."}[5m]))`
- **Business Operation Errors**: `sum(rate(business_operations_total{status="error"}[5m]))`

### 4. Saturation
- **Active Connections**: `active_connections_current`
- **CPU Utilization**: `rate(container_cpu_usage_seconds_total{pod=~"sre-demo-app-.*"}[5m])`
- **Memory Usage**: `container_memory_working_set_bytes{pod=~"sre-demo-app-.*"}`

## SLI-Focused Queries

### Availability SLI
- **Uptime Percentage**: `(sum(rate(http_requests_total{status_code!~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100`

### Performance SLI
- **Fast Requests (< 200ms)**: `sum(rate(http_request_duration_seconds_bucket{le="0.2"}[5m])) / sum(rate(http_request_duration_seconds_count[5m])) * 100`

### Quality SLI
- **Successful Business Operations**: `sum(rate(business_operations_total{status="success"}[5m])) / sum(rate(business_operations_total[5m])) * 100`

## Advanced Queries

### Resource Efficiency
- **Memory Utilization Percentage**: `(container_memory_working_set_bytes{pod=~"sre-demo-app-.*"} / container_spec_memory_limit_bytes{pod=~"sre-demo-app-.*"}) * 100`
- **CPU Throttling**: `rate(container_cpu_cfs_throttled_seconds_total{pod=~"sre-demo-app-.*"}[5m])`

### Business Metrics
- **Store Operations by Status**: `sum(rate(business_operations_total[5m])) by (operation_type, status)`
- **Store Lookup Success Rate**: `sum(rate(business_operations_total{operation_type="store_lookup", status="success"}[5m])) / sum(rate(business_operations_total{operation_type="store_lookup"}[5m])) * 100`

### Capacity Planning
- **Request Rate Growth**: `increase(http_requests_total[1h])`
- **Peak Hour Traffic**: `max_over_time(sum(rate(http_requests_total[5m]))[1h:5m])`
- **Resource Usage Trend**: `predict_linear(container_memory_working_set_bytes{pod=~"sre-demo-app-.*"}[4h], 3600)`