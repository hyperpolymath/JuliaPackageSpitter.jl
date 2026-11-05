K9!
# SPDX-License-Identifier: MPL-2.0
# Yard-level K9 contract: CI and verification configuration for JuliaPackageSpitter.jl
# Security Level: Yard (Nickel evaluation with validation contracts)

{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "ci-validation",
    security = {
      leash = 'Yard,
      trust_level = "validated-config",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
    },
    metadata = {
      name = "juliapackagespitter-ci-validation",
      version = "0.1.0",
      description = "CI matrix, formal identity proof, and governance gate contracts for JuliaPackageSpitter.jl",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
  },

  config = {
    package_name
      | String
      | std.string.NonEmpty
      = "JuliaPackageSpitter",

    repository_slug
      | String
      | std.string.NonEmpty
      = "hyperpolymath/JuliaPackageSpitter.jl",

    julia_versions
      | Array String
      | std.array.NonEmpty
      = ["1.10", "1.11"],

    formatter_style
      | [| 'DefaultStyle, 'BlueStyle, 'SciMLStyle |]
      = 'DefaultStyle,

    strict_dogfood_validation | Bool = true,
    require_pinned_container_digests | Bool = true,
    require_agda_identity_gate | Bool = true,

    gates = {
      identity_gate = "tests/check-identity.sh",
      identity_fixtures = "tests/check-identity-fixtures.sh",
      julia_tests = "test/runtests.jl",
      contractile_file = "contractile.just",
      standards_reusable_owner = "metadatastician/standards",
    },
  },

  validation = {
    has_lts_and_stable_julia = std.array.length config.julia_versions >= 2,
    strict_gates_enabled =
      config.strict_dogfood_validation
      && config.require_pinned_container_digests
      && config.require_agda_identity_gate,
  },
}
