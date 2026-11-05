# SPDX-License-Identifier: MPL-2.0
module Generator

using UUIDs
using Mustache
using JSON3

export PackageSpec, generate_package

struct PackageSpec
    name::String
    domain_summary::String
    authors::Vector{String}
    ci_profile::Symbol # :minimal, :standard, :strict
    ffi_enabled::Bool
end

"""
    generate_package(spec, target_dir)

Scaffold a Julia package in `target_dir` using the RSR standard. Create the
directory structure and write `Project.toml` and the main source file. Write
`README.adoc` and `SONNET-TASKS.md` when their templates are present. Existing
generated files are overwritten. If `spec.ffi_enabled` is true, also create
the `ffi/zig` and `src/abi` directories; `spec.ci_profile` does not affect
the output.

Print a progress message and return a completion message. Errors from reading or
rendering templates, creating directories or writing files propagate to the
caller; a failure may leave a partial scaffold.
"""
function generate_package(spec::PackageSpec, target_dir::String)
    println("🛠️ Spitting out new package: $(spec.name)...")

    # Base template path (internal to the spitter package)
    tpl_dir = joinpath(@__DIR__, "..", "templates", "base")

    # 1. Create directory structure
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

    for d in dirs
        mkpath(joinpath(target_dir, d))
    end

    # 2. Generate Project.toml
    uuid = string(uuid4())
    project_tpl = read(joinpath(tpl_dir, "Project.toml.in"), String)

    open(joinpath(target_dir, "Project.toml"), "w") do io
        print(
            io,
            render(project_tpl, name = spec.name, uuid = uuid, authors = spec.authors),
        )
    end

    # 3. Generate main entry point
    src_tpl = """
    # SPDX-License-Identifier: MPL-2.0
    module {{name}}

    # Domain: {{summary}}

    end # module
    """

    open(joinpath(target_dir, "src", "$(spec.name).jl"), "w") do io
        print(io, render(src_tpl, name = spec.name, summary = spec.domain_summary))
    end

    # 4. Use external templates for README and TASKS if they exist
    readme_tpl_path = joinpath(tpl_dir, "README.adoc.tpl")
    if isfile(readme_tpl_path)
        tpl_content = read(readme_tpl_path, String)
        open(joinpath(target_dir, "README.adoc"), "w") do io
            print(io, render(tpl_content, name = spec.name, summary = spec.domain_summary))
        end
    end

    tasks_tpl_path = joinpath(tpl_dir, "SONNET-TASKS.md.tpl")
    if isfile(tasks_tpl_path)
        tpl_content = read(tasks_tpl_path, String)
        open(joinpath(target_dir, "SONNET-TASKS.md"), "w") do io
            print(
                io,
                render(
                    tpl_content,
                    name = spec.name,
                    summary = spec.domain_summary,
                    uuid = uuid,
                ),
            )
        end
    end

    return "Package $(spec.name) scaffolded successfully! 🚀"
end

end # module
