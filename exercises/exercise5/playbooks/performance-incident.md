# Performance Incident Response Playbook

## Alert: HighLatency / ExtremeLatency

### Immediate Response (First 5 minutes)
- [ ] Acknowledge alert and assess scope
- [ ] Check current P95/P99 latency metrics
- [ ] Verify if this affects all users or specific regions/endpoints

### Investigation Steps
1. **Check Resource Usage**: `kubectl top pods -l app=sre-demo-app`
2. **Review Recent Changes**: Check deployment history and configuration changes
3. **Analyze Traffic Patterns**: Look for unusual request volumes or patterns
4. **Check Dependencies**: Verify external service health and database performance

### Common Mitigation Strategies
- Scale up replicas: `kubectl scale deployment sre-demo-app --replicas=10`
- Increase resource limits if CPU/memory bound
- Check for memory leaks or garbage collection issues
- Review database query performance

### Escalation**: 15 minutes if no improvement, escalate to senior SRE
