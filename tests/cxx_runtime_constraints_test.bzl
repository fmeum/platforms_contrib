load("@rules_testing//lib:test_suite.bzl", "test_suite")
load("//os/linux/cxx_runtime/libcxx:libcxx.bzl", "libcxx_version_constraints")
load("//os/linux/cxx_runtime/libstdcxx:libstdcxx.bzl", "libstdcxx_version_constraints")
load("//os/windows/cxx_runtime/msvcp:msvcp.bzl", "msvcp_version_constraints")

visibility("private")

def _names(labels):
    return [label.name for label in labels]

def _versions_are_cumulative_test(env):
    env.expect.that_collection(_names(libstdcxx_version_constraints("7"))).contains_exactly([
        "at_least_5_available",
        "at_least_6_available",
        "at_least_7_available",
    ]).in_order()
    env.expect.that_collection(_names(libcxx_version_constraints("15"))).contains_exactly([
        "at_least_14_available",
        "at_least_15_available",
    ]).in_order()
    env.expect.that_collection(_names(msvcp_version_constraints("14.10"))).contains_exactly([
        "at_least_14.0_available",
        "at_least_14.10_available",
    ]).in_order()

def cxx_runtime_constraints_test_suite(name):
    test_suite(
        name = name,
        basic_tests = [_versions_are_cumulative_test],
    )
