load(":msvcp_private.bzl", "MSVCP_VERSIONS")

def msvcp_version_constraints(version):
    """Returns the constraints describing the given the Visual C++ Redistributable (msvcp140.dll and vcruntime140.dll) version available on a platform."""
    if version not in MSVCP_VERSIONS:
        fail("Unsupported the Visual C++ Redistributable (msvcp140.dll and vcruntime140.dll) version {version}, expected one of: {supported}".format(
            version = repr(version),
            supported = ", ".join([repr(supported) for supported in MSVCP_VERSIONS]),
        ))
    return [
        Label(":at_least_{version}_available".format(version = lower_version))
        for lower_version in MSVCP_VERSIONS[:MSVCP_VERSIONS.index(version) + 1]
    ]
