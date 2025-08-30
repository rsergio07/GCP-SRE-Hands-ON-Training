#!/bin/bash
# Chaos testing script for validating alerting
set -e

OPERATION=${1:-"help"}
DURATION=${2:-300}

case $OPERATION in
    "unavailable")
        echo "Making service unavailable for $DURATION seconds..."
        kubectl scale deployment sre-demo-app --replicas=0
        sleep $DURATION
        kubectl scale deployment sre-demo-app --replicas=2
        ;;
    "slow")
        echo "Injecting latency for $DURATION seconds..."
        # Create high CPU load to slow responses
        kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do echo 'generating load'; done"
        sleep $DURATION
        kubectl delete pod load-generator
        ;;
    "errors")
        echo "Increasing error rate for $DURATION seconds..."
        # This would require modifying the app or using a proxy to inject errors
        echo "Error injection not implemented - modify application or use service mesh"
        ;;
    *)
        echo "Usage: $0 [unavailable|slow|errors] [duration_seconds]"
        ;;
esac
