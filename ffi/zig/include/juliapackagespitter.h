/* SPDX-License-Identifier: MPL-2.0
 *
 * C interface to the JuliaPackageSpitter.jl FFI (template; see src/main.zig).
 * Hand-written to match the exports in ffi/zig/src/main.zig. Keep them in sync.
 */
#ifndef JULIAPACKAGESPITTER_H
#define JULIAPACKAGESPITTER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque library handle. Its layout is private to the library. */
typedef struct juliapackagespitter_handle juliapackagespitter_handle;

typedef enum {
    JULIAPACKAGESPITTER_OK = 0,
    JULIAPACKAGESPITTER_ERROR = 1,
    JULIAPACKAGESPITTER_INVALID_PARAM = 2,
    JULIAPACKAGESPITTER_OUT_OF_MEMORY = 3,
    JULIAPACKAGESPITTER_NULL_POINTER = 4
} juliapackagespitter_result;

typedef uint32_t (*juliapackagespitter_callback)(uint64_t, uint32_t);

/* Lifecycle. init returns NULL on failure. free(NULL) is a no-op. */
juliapackagespitter_handle *juliapackagespitter_init(void);
void juliapackagespitter_free(juliapackagespitter_handle *handle);
uint32_t juliapackagespitter_is_initialized(juliapackagespitter_handle *handle);

/* Operations. process and process_array are placeholders (see main.zig). */
juliapackagespitter_result juliapackagespitter_process(juliapackagespitter_handle *handle, uint32_t input);
juliapackagespitter_result juliapackagespitter_process_array(juliapackagespitter_handle *handle, const uint8_t *buffer, uint32_t len);
juliapackagespitter_result juliapackagespitter_register_callback(juliapackagespitter_handle *handle, juliapackagespitter_callback callback);

/* Strings. The caller must free the result of get_string with free_string. */
const char *juliapackagespitter_get_string(juliapackagespitter_handle *handle);
void juliapackagespitter_free_string(const char *str);

/* Static strings: do NOT free. last_error returns NULL when there is no error. */
const char *juliapackagespitter_last_error(void);
const char *juliapackagespitter_version(void);
const char *juliapackagespitter_build_info(void);

#ifdef __cplusplus
}
#endif

#endif /* JULIAPACKAGESPITTER_H */
