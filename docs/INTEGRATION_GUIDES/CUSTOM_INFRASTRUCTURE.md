# Integrating Roche into Custom Infrastructure

## Embedded C-ABI Integration

Roche exports a clean dynamic library interface (`libroche.so` / `roche.dll` / `libroche.dylib`) for seamless integration into Rust, Go, Python, or C++ security infra.

### C API Header (`roche.h`)

```c
#ifndef ROCHE_H
#define ROCHE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t findings_count;
    uint32_t critical_count;
    uint32_t high_count;
} RocheSummary;

int32_t roche_analyze_bytecode(const uint8_t* code_ptr, size_t code_len, RocheSummary* summary_out);

#ifdef __cplusplus
}
#endif

#endif // ROCHE_H
```
