# Cloud Deployment & Serverless Guide for Roche Engine

## AWS Lambda & Cloud Workers

Roche binary compiles to a single, dependency-free native binary, ideal for serverless execution.

### Deployment Payload

```bash
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall
zip function.zip zig-out/bin/roche
```

### AWS ECS / Kubernetes Deployment

Deploy Roche security workers in automated cluster pools:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: roche-security-worker
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: roche
        image: creatorofaurad/roche:v2.0
        command: ["roche", "worker", "--queue", "amqp://rabbitmq:5672"]
```
