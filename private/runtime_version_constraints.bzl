load(":compat_constraint_setting.bzl", "compat_constraint_setting")

visibility(["//os/..."])

def runtime_version_constraints(*, versions, os_constraint):
    """Declares `:available` and an `:at_least_<version>_available` value per version.

    Args:
      versions: The supported versions in increasing order.
      os_constraint: The OS the runtime can be available on.
    """
    native.alias(
        name = "available",
        actual = ":at_least_{}_available".format(versions[0]),
        visibility = ["//visibility:public"],
    )
    for i in range(len(versions)):
        compat_constraint_setting(
            name = "at_least_{}".format(versions[i]),
            refines_constraint_value = os_constraint if i == 0 else ":at_least_{}_available".format(versions[i - 1]),
        )
        native.constraint_value(
            name = "at_least_{}_available".format(versions[i]),
            constraint_setting = ":at_least_{}".format(versions[i]),
            visibility = ["//visibility:public"],
        )
