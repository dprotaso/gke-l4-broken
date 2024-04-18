#!/usr/bin/env bash

set -x
set -e

kubectl delete -f pod.yaml --ignore-not-found=true
kubectl apply -f pod.yaml
kubectl wait pod/nginx \
  --timeout 30s \
  --for=condition=Ready

kubectl wait service/nginx \
  --timeout 60s \
  --for=jsonpath='{.status.loadBalancer.ingress}'


LB_IP=$(kubectl get service/nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Sanity check
curl --fail --max-time 5 "http://${LB_IP}"

# Handle 1m of traffic @ 20qps per second
go run github.com/rakyll/hey@latest \
  -disable-keepalive \
  -c 10 `# number of workers` \
  -q 2  `# qps per worker` \
  -z 1ms `# duration ` \
  "http://${LB_IP}"


# Run again in background
go run github.com/rakyll/hey@latest \
  -disable-keepalive \
  -c 10 `# number of workers` \
  -q 2  `# qps per worker` \
  -z 1m `# duration ` \
  "http://${LB_IP}" &


kubectl patch svc nginx \
  --type strategic -p '
  {"spec":
    {"ports":
      [{
        "name":"https",
        "port": 443,
        "targetPort": 80
      }]
    }
  }'

  wait
