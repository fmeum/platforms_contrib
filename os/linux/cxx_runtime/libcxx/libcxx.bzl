load(":libcxx_private.bzl", "LIBCXX_VERSIONS")

def libcxx_version_constraints(version):
    """Returns the constraints describing the given libc++ version available on a platform."""
    if version not in LIBCXX_VERSIONS:
        fail("Unsupported libc++ version {version}, expected one of: {supported}".format(
            version = repr(version),
            supported = ", ".join([repr(supported) for supported in LIBCXX_VERSIONS]),
        ))
    return [
        Label(":at_least_{version}_available".format(version = lower_version))
        for lower_version in LIBCXX_VERSIONS[:LIBCXX_VERSIONS.index(version) + 1]
    ]
