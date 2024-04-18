### GKE L4 LB has downtime


Run the test using `./run-test.sh`

You'll see the connection failures to port 80

```
Error distribution:
  [10]	Get "http://35.237.90.58": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```

Full test output:

```
% ./run-test.sh
+ set -e
+ kubectl delete -f pod.yaml --ignore-not-found=true
pod "nginx" deleted
service "nginx" deleted
+ kubectl apply -f pod.yaml
pod/nginx created
service/nginx created
+ kubectl wait pod/nginx --timeout 30s --for=condition=Ready
pod/nginx condition met
+ kubectl wait service/nginx --timeout 60s '--for=jsonpath={.status.loadBalancer.ingress}'
service/nginx condition met
++ kubectl get service/nginx -o 'jsonpath={.status.loadBalancer.ingress[0].ip}'
+ LB_IP=35.237.90.58
+ curl --fail --max-time 5 http://35.237.90.58
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
+ go run github.com/rakyll/hey@latest -disable-keepalive -c 10 -q 2 -z 1ms http://35.237.90.58

Summary:
  Total:	0.0014 secs
  Slowest:	0.0000 secs
  Fastest:	0.0000 secs
  Average:	 NaN secs
  Requests/sec:	0.0000


Response time histogram:


Latency distribution:

Details (average, fastest, slowest):
  DNS+dialup:	 NaN secs, 0.0000 secs, 0.0000 secs
  DNS-lookup:	 NaN secs, 0.0000 secs, 0.0000 secs
  req write:	 NaN secs, 0.0000 secs, 0.0000 secs
  resp wait:	 NaN secs, 0.0000 secs, 0.0000 secs
  resp read:	 NaN secs, 0.0000 secs, 0.0000 secs

Status code distribution:



+ kubectl patch svc nginx --type strategic -p '
  {"spec":
    {"ports":
      [{
        "name":"https",
        "port": 443,
        "targetPort": 80
      }]
    }
  }'
+ go run github.com/rakyll/hey@latest -disable-keepalive -c 10 -q 2 -z 1m http://35.237.90.58
service/nginx patched
+ wait

Summary:
  Total:	60.1219 secs
  Slowest:	19.1553 secs
  Fastest:	0.0978 secs
  Average:	0.3568 secs
  Requests/sec:	9.4308

  Total data:	340884 bytes
  Size/request:	612 bytes

Response time histogram:
  0.098 [1]	|
  2.004 [546]	|■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  3.909 [0]	|
  5.815 [0]	|
  7.721 [0]	|
  9.627 [0]	|
  11.532 [8]	|■
  13.438 [0]	|
  15.344 [0]	|
  17.250 [0]	|
  19.155 [2]	|


Latency distribution:
  10% in 0.1090 secs
  25% in 0.1134 secs
  50% in 0.1179 secs
  75% in 0.1244 secs
  90% in 0.1526 secs
  95% in 0.2475 secs
  99% in 11.1237 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.2912 secs, 0.0978 secs, 19.1553 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0002 secs
  resp wait:	0.0650 secs, 0.0471 secs, 0.4151 secs
  resp read:	0.0005 secs, 0.0001 secs, 0.0036 secs

Status code distribution:
  [200]	557 responses

Error distribution:
  [10]	Get "http://35.237.90.58": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```
