# SPDX-License-Identifier: MPL-2.0

"""
    JuliaPackageSpitter

Automated Julia package scaffolding. `generate_package(spec, target_dir)` writes
a package skeleton (Project.toml, src/, test/ and README templates) for a
`PackageSpec` into `target_dir`.

`ci_profile` and `ffi_enabled` are stored on the spec but do not yet change the
generated output. Reuse auditing (scanning existing packages for reusable code)
is planned work for v0.3.0 and is not implemented; see ROADMAP.adoc.

# Example
```julia
using JuliaPackageSpitter
spec = PackageSpec("MyPackage", "A short domain summary", ["Author Name"], :standard, false)
generate_package(spec, "/path/to/output")
```
"""
module JuliaPackageSpitter

include("generator.jl")

using .Generator
export PackageSpec, generate_package

end # module JuliaPackageSpitter
