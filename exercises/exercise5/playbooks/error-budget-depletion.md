# Error Budget Depletion Response Playbook

## Alert: Error Budget Burn Rate Alerts

### Immediate Assessment
- [ ] Check current error budget consumption rate
- [ ] Identify primary contributors (availability vs latency vs quality)
- [ ] Assess timeline to budget exhaustion

### Response Strategy
**Fast Burn (budget exhausted in <2 hours)**:
- Immediate incident response
- Consider rollback of recent changes
- Implement circuit breakers or traffic throttling

**Slow Burn (budget exhausted in 6-24 hours)**:
- Investigate root causes
- Plan controlled mitigation
- Review recent deployments and changes

### Error Budget Policy Actions
- **Budget >50%**: Normal operations, focus on feature development
- **Budget 25-50%**: Increased focus on reliability, review SLO targets
- **Budget <25%**: Freeze risky deployments, mandatory reliability improvements
- **Budget exhausted**: Full deployment freeze until budget recovers
