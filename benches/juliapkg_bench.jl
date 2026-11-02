# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
#
# JuliaPackageSpitter benchmarks — PackageSpec construction, draft name
# parsing, and directory scaffold planning.
#
# Measures the core operations called during batch package generation:
# - `PackageSpec` construction (called once per package to generate)
# - `generate_package` scaffold planning (directory list construction)
# - UUID generation throughput (one UUID per package)
# - Mustache template rendering for Project.toml and module body
#
# Run:
#   julia --project=. benches/juliapkg_bench.jl

using BenchmarkTools
using UUIDs

# ============================================================================
# Load the module under test
# ============================================================================

# Add the package source dir to the load path so we can load Generator
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
include(joinpath(@__DIR__, "..", "src", "generator.jl"))
using .Generator: PackageSpec, generate_package

# ============================================================================
# Helper constructors
# ============================================================================

"""Build a minimal PackageSpec for benchmarking."""
function make_spec_minimal()
    PackageSpec(
        "BenchmarkPkg",
        "A minimal benchmark test package",
        ["Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>"],
        :minimal,
        false,
    )
end

"""Build a PackageSpec with FFI enabled (adds two extra directories)."""
function make_spec_ffi()
    PackageSpec(
        "BenchmarkPkgFFI",
        "Benchmark package with Zig FFI scaffold",
        ["Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>"],
        :standard,
        true,
    )
end

"""Build the directory list that generate_package would create, without touching the filesystem."""
function plan_directories(spec::PackageSpec)::Vector{String}
    dirs = [
        "src",
        "test",
        "docs",
        "scripts",
        "contractiles",
        ".github/workflows",
        ".machine_readable",
    ]
    if spec.ffi_enabled
        push!(dirs, "ffi/zig")
        push!(dirs, "src/abi")
    end
    dirs
end

# ============================================================================
# Benchmarks
# ============================================================================

println("Running JuliaPackageSpitter benchmarks...")
println("=" ^ 60)

# --- PackageSpec construction ---
println("\n[1] PackageSpec construction (no FFI)")
b_spec = @benchmark make_spec_minimal() samples = 1000 evals = 10
display(b_spec)

println("\n[2] PackageSpec construction (with FFI)")
b_spec_ffi = @benchmark make_spec_ffi() samples = 1000 evals = 10
display(b_spec_ffi)

# --- Directory planning (in-memory, no I/O) ---
spec_min = make_spec_minimal()
spec_ffi = make_spec_ffi()

println("\n[3] Directory list planning (minimal spec, no FFI)")
b_dirs = @benchmark plan_directories($spec_min) samples = 1000 evals = 10
display(b_dirs)

println("\n[4] Directory list planning (with FFI)")
b_dirs_ffi = @benchmark plan_directories($spec_ffi) samples = 1000 evals = 10
display(b_dirs_ffi)

# --- UUID generation (one per package) ---
println("\n[5] UUID generation throughput")
b_uuid = @benchmark uuid4() samples = 2000 evals = 10
display(b_uuid)

println("\n[6] UUID string conversion")
b_uuid_str = @benchmark string(uuid4()) samples = 2000 evals = 10
display(b_uuid_str)

# --- Vector push performance (mimics directory scaffold growth) ---
println("\n[7] Directory scaffold append (8 dirs baseline)")
b_push = @benchmark begin
    dirs = Vector{String}(undef, 0)
    sizehint!(dirs, 9)
    push!(
        dirs,
        "src",
        "test",
        "docs",
        "scripts",
        "contractiles",
        ".github/workflows",
        ".machine_readable",
    )
end samples = 2000 evals = 10
display(b_push)

println("\n[8] Directory scaffold append (with FFI paths)")
b_push_ffi = @benchmark begin
    dirs = Vector{String}(undef, 0)
    sizehint!(dirs, 9)
    push!(
        dirs,
        "src",
        "test",
        "docs",
        "scripts",
        "contractiles",
        ".github/workflows",
        ".machine_readable",
        "ffi/zig",
        "src/abi",
    )
end samples = 2000 evals = 10
display(b_push_ffi)

println("\n" * "=" ^ 60)
println("Benchmark run complete.")
println("To run individual benchmarks interactively:")
println("  julia --project=. -e 'include(\"benches/juliapkg_bench.jl\")'")
