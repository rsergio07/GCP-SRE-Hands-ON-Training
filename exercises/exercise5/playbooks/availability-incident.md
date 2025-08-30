# Availability Incident Response Playbook

## Alert: ServiceUnavailable / HighErrorRate

### Immediate Response (First 5 minutes)

#### 1. Acknowledge and Assess
- [ ] Acknowledge alert in monitoring system
- [ ] Check service status dashboard: `https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID`
- [ ] Verify incident scope: Is this affecting all users or subset?

```bash
# Quick health check
kubectl get pods -l app=sre-demo-app
kubectl get services sre-demo-service
curl -I http://$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

#### 2. Initial Triage Questions
- **When did this start?** Check Prometheus alerts timeline
- **What changed recently?** Check deployment history
- **Is this a total outage or degradation?** Check error rate vs availability
- **Are dependencies healthy?** Check GKE cluster, network, external services

### Detailed Investigation (5-15 minutes)

#### 3. Check Application Health
```bash
# Pod status and recent events
kubectl describe pods -l app=sre-demo-app
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20

# Application logs
kubectl logs -l app=sre-demo-app --tail=100 --since=30m

# Resource utilization  
kubectl top pods -l app=sre-demo-app
kubectl top nodes
```

#### 4. Check Infrastructure
```bash
# Kubernetes cluster health
kubectl get nodes
kubectl cluster-info

# Service and ingress status
kubectl get services
kubectl describe service sre-demo-service

# HPA status (scaling issues?)
kubectl get hpa
kubectl describe hpa sre-demo-hpa
```

#### 5. Check Metrics and Patterns
Access Prometheus: `http://$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):9090`

Key queries to run:
```promql
# Error rate over time
sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# Request volume
sum(rate(http_requests_total[5m]))

# Response times
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Pod availability
up{job="sre-demo-app"}
```

### Common Root Causes and Solutions

#### Scenario A: Pod Crashes/Restarts
**Symptoms**: Pods restarting frequently, CrashLoopBackOff status
**Investigation**:
```bash
kubectl logs <failing-pod> --previous  # Get logs from crashed container
kubectl describe pod <failing-pod>     # Check events and conditions
```
**Common causes**:
- Memory/CPU resource limits exceeded
- Application startup failures
- Configuration errors
- Health check failures

**Immediate mitigation**:
```bash
# Increase resource limits temporarily
kubectl patch deployment sre-demo-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"sre-demo-app","resources":{"limits":{"memory":"512Mi","cpu":"1000m"}}}]}}}}'

# Scale up replicas for redundancy
kubectl scale deployment sre-demo-app --replicas=5
```

#### Scenario B: Network/Load Balancer Issues
**Symptoms**: Service unreachable, connection timeouts
**Investigation**:
```bash
# Check service endpoints
kubectl get endpoints sre-demo-service

# Test internal connectivity
kubectl run debug --image=busybox -it --rm -- wget -O- http://sre-demo-service:80/health

# Check load balancer status
kubectl describe service sre-demo-service
```
**Immediate mitigation**:
```bash
# Recreate service if needed
kubectl delete service sre-demo-service
kubectl apply -f k8s/service.yaml

# Check firewall rules in GCP console
```

#### Scenario C: Resource Exhaustion
**Symptoms**: High CPU/memory usage, slow responses
**Investigation**:
```bash
# Check resource usage trends
kubectl top pods -l app=sre-demo-app --sort-by=memory
kubectl top nodes

# Check HPA scaling
kubectl describe hpa sre-demo-hpa
```
**Immediate mitigation**:
```bash
# Manual scaling
kubectl scale deployment sre-demo-app --replicas=10

# Increase HPA limits temporarily
kubectl patch hpa sre-demo-hpa -p '{"spec":{"maxReplicas":15}}'
```

#### Scenario D: Configuration Issues
**Symptoms**: Application errors, startup failures
**Investigation**:
```bash
# Check configmaps and secrets
kubectl describe configmap sre-demo-config
kubectl get secrets

# Validate configuration
kubectl logs -l app=sre-demo-app | grep -i error
```

### Escalation Procedures

#### 15 minutes: No progress made
- [ ] Escalate to senior SRE on-call
- [ ] Notify engineering team lead
- [ ] Consider rollback to last known good version

#### 30 minutes: Still unresolved
- [ ] Escalate to engineering manager
- [ ] Activate incident bridge if business critical
- [ ] Consider emergency maintenance window

#### 60 minutes: Major incident
- [ ] Activate major incident response
- [ ] Notify executive team
- [ ] Engage external support if needed

### Recovery Actions

#### Once Service is Restored
1. **Verify recovery**:
```bash
# Confirm all pods healthy
kubectl get pods -l app=sre-demo-app

# Test external accessibility
curl -I http://$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Check error rate has returned to normal
# Use Prometheus query: sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100
```

2. **Monitor for stability** (30 minutes minimum):
   - Error rate < 1%
   - Response time < 500ms P95
   - All pods running and ready

3. **Update stakeholders**:
   - Send all-clear notification
   - Update status page if applicable
   - Notify affected teams

### Post-Incident Actions

#### Immediate (within 1 hour)
- [ ] Document timeline in incident tracking system
- [ ] Preserve logs and debugging artifacts
- [ ] Schedule post-incident review within 48 hours

#### Short-term (within 1 week)
- [ ] Complete detailed post-incident review
- [ ] Identify and implement immediate fixes
- [ ] Update monitoring and alerting if gaps identified
- [ ] Update this playbook based on lessons learned

#### Long-term (within 1 month)
- [ ] Implement systemic improvements
- [ ] Update SLO targets if needed
- [ ] Enhance automation and testing
- [ ] Share learnings with broader team

### Key Metrics to Track

**During Incident**:
- Mean Time to Detection (MTTD)
- Mean Time to Acknowledgment (MTTA)
- Mean Time to Resolution (MTTR)
- Customer impact (affected users, lost requests)

**Post-Incident**:
- Error budget consumption
- SLO compliance impact
- Incident frequency trends
- Playbook effectiveness

### Emergency Contacts

**Primary On-Call**: [Your on-call system]
**Escalation Chain**:
1. Senior SRE: [Contact info]
2. Engineering Manager: [Contact info] 
3. Product Manager: [Contact info]
4. VP Engineering: [Contact info]

**External Vendors**:
- Google Cloud Support: [Case management URL]
- DNS Provider: [Support contact]
- CDN Provider: [Support contact]

### Related Playbooks
- [Performance Incident Playbook](performance-incident.md)
- [Error Budget Depletion Playbook](error-budget-depletion.md)
- [Escalation Matrix](escalation-matrix.md)

---
**Last Updated**: 2024-01-15
**Version**: 1.2
**Owner**: SRE Team