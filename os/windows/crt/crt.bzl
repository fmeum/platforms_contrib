"""The C runtime that toolchains should target on Windows platforms."""

PreferredWindowsCrtInfo = provider(
    doc = """The result of resolving //os/windows/crt:preference against the target platform.

Provided by //os/windows/crt:preferred.""",
    fields = {
        "flavor": "The preferred flavor, currently \"ucrt\" or \"msvcrt\", if `status` is " +
                  "\"resolved\", otherwise None. More flavors may be added in the future.",
        "requires_static": "Whether the CRT has to be linked statically into every binary and " +
                           "DLL if `status` is \"resolved\", otherwise None.",
        "status": "\"resolved\" for Windows platforms with a non-empty ranking, \"unset\" for " +
                  "Windows platforms with an empty ranking, which leaves the choice to the " +
                  "toolchain, and \"not_applicable\" for other platforms.",
    },
)
