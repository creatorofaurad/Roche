# Running Roche via Docker

## Quick Run

Run Roche instantly without installing compiler toolchains locally:

```bash
docker run --rm -v $(pwd):/workspace creatorofaurad/roche:v2.0 audit --target /workspace/contracts
```

## Building Custom Docker Image

```dockerfile
FROM alpine:3.19 AS builder
RUN apk add --no-grad zig git
WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseFast

FROM alpine:3.19
COPY --from=builder /app/zig-out/bin/roche /usr/local/bin/roche
ENTRYPOINT ["roche"]
```
