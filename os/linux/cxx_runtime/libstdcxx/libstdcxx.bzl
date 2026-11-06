load(":libstdcxx_private.bzl", "LIBSTDCXX_VERSIONS")

def libstdcxx_version_constraints(version):
    """Returns the constraints describing the given libstdc++ version available on a platform."""
    if version not in LIBSTDCXX_VERSIONS:
        fail("Unsupported libstdc++ version {version}, expected one of: {supported}".format(
            version = repr(version),
            supported = ", ".join([repr(supported) for supported in LIBSTDCXX_VERSIONS]),
        ))
    return [
        Label(":at_least_{version}_available".format(version = lower_version))
        for lower_version in LIBSTDCXX_VERSIONS[:LIBSTDCXX_VERSIONS.index(version) + 1]
    ]
