"""The C runtime that toolchains should target on Windows platforms."""

load(":crt.bzl", "PreferredWindowsCrtInfo")

visibility(["//os/windows/crt", "//tests"])

CRT_FLAVORS = [
    "ucrt",
    "msvcrt",
]

_STATIC_PREFIX = "static-"

NO_CRT = "none"

# msvcrt.dll has no static counterpart.
CRT_PREFERENCES = CRT_FLAVORS + [_STATIC_PREFIX + "ucrt", NO_CRT]

_CrtPreferenceInfo = provider(
    doc = "The ranking of CRT options set via //os/windows/crt:preference.",
    fields = ["preferences"],
)

def _crt_preference_flag_impl(ctx):
    for preference in ctx.build_setting_value:
        if preference not in CRT_PREFERENCES:
            fail("Unsupported CRT preference {preference} in --{flag}, expected one of: {supported}".format(
                preference = repr(preference),
                flag = ctx.label,
                supported = ", ".join([repr(supported) for supported in CRT_PREFERENCES]),
            ))
    return [_CrtPreferenceInfo(preferences = ctx.build_setting_value)]

crt_preference_flag = rule(
    implementation = _crt_preference_flag_impl,
    build_setting = config.string_list(flag = True),
    attrs = {
        # Read by Bazel 9 and later to decide whether the value propagates to exec configurations.
        "scope": attr.string(),
    },
)

def _resolve(ctx):
    if not ctx.target_platform_has_constraint(ctx.attr._windows[platform_common.ConstraintValueInfo]):
        return PreferredWindowsCrtInfo(status = "not_applicable", flavor = None, requires_static = None)

    preferences = ctx.attr._preference[_CrtPreferenceInfo].preferences
    if not preferences:
        return PreferredWindowsCrtInfo(status = "unset", flavor = None, requires_static = None)

    # Every Windows version with vendor support ships both DLLs and static linking doesn't depend
    # on the platform, so all options are viable as long as there are no availability constraints.
    preference = preferences[0]
    if preference == NO_CRT:
        return PreferredWindowsCrtInfo(status = "resolved", flavor = NO_CRT, requires_static = None)
    return PreferredWindowsCrtInfo(
        status = "resolved",
        flavor = preference.removeprefix(_STATIC_PREFIX),
        requires_static = preference.startswith(_STATIC_PREFIX),
    )

def _preferred_windows_crt_impl(ctx):
    preferred_crt = _resolve(ctx)
    if preferred_crt.status != "resolved":
        flag_value = preferred_crt.status
    elif ctx.attr.requires_static:
        flag_value = str(preferred_crt.requires_static).lower()
    else:
        flag_value = preferred_crt.flavor
    return [
        preferred_crt,
        config_common.FeatureFlagInfo(value = flag_value),
        platform_common.TemplateVariableInfo({
            "PREFERRED_WINDOWS_CRT": preferred_crt.flavor or "",
            "PREFERRED_WINDOWS_CRT_REQUIRES_STATIC": "1" if preferred_crt.requires_static else "",
            "PREFERRED_WINDOWS_CRT_STATUS": preferred_crt.status,
        }),
    ]

preferred_windows_crt = rule(
    implementation = _preferred_windows_crt_impl,
    attrs = {
        "requires_static": attr.bool(
            doc = "Whether to provide whether the CRT has to be linked statically instead of the " +
                  "flavor for `config_setting.flag_values`.",
        ),
        "_preference": attr.label(default = ":preference"),
        "_windows": attr.label(default = "@platforms//os:windows"),
    },
)
