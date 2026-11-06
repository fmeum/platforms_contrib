load("@rules_testing//lib:analysis_test.bzl", "analysis_test")
load("@rules_testing//lib:truth.bzl", "matching")
load("//os/windows/crt:crt.bzl", "PreferredWindowsCrtInfo")

visibility("private")

_PREFERENCE = str(Label("//os/windows/crt:preference"))

_SubjectInfo = provider(
    doc = "The values of the ways to read the preferred CRT.",
    fields = ["provider", "selected"],
)

def _subject_impl(ctx):
    return [_SubjectInfo(
        provider = ctx.attr.preferred[PreferredWindowsCrtInfo],
        selected = [ctx.attr.selected_flavor, ctx.attr.selected_linkage],
    )]

_subject = rule(
    implementation = _subject_impl,
    attrs = {
        "preferred": attr.label(),
        "selected_flavor": attr.string(),
        "selected_linkage": attr.string(),
    },
)

def _expect(status, flavor, requires_static, selected):
    def impl(env, target):
        info = target[_SubjectInfo]
        env.expect.that_str(info.provider.status).equals(status)
        env.expect.that_bool(info.provider.flavor == flavor).equals(True)
        env.expect.that_bool(info.provider.requires_static == requires_static).equals(True)
        env.expect.that_collection(info.selected).contains_exactly(selected).in_order()

    return impl

def _expect_failure(message):
    def impl(env, target):
        env.expect.that_target(target).failures().contains_predicate(matching.contains(message))

    return impl

def windows_crt_preference_test_suite(name):
    _subject(
        name = name + "_subject",
        preferred = "//os/windows/crt:preferred",
        selected_flavor = select({
            "//os/windows/crt:ucrt_preferred": "ucrt",
            "//os/windows/crt:msvcrt_preferred": "msvcrt",
            "//conditions:default": "",
        }),
        selected_linkage = select({
            "//os/windows/crt:requires_static": "static",
            "//os/windows/crt:requires_dynamic": "dynamic",
            "//os/windows/crt:unset": "unset",
            "//conditions:default": "",
        }),
    )
    native.platform(
        name = name + "_windows",
        constraint_values = ["@platforms//cpu:x86_64", "@platforms//os:windows"],
    )
    native.platform(
        name = name + "_linux",
        constraint_values = ["@platforms//cpu:x86_64", "@platforms//os:linux"],
    )

    for test, platform, preference, impl in [
        ("default", "windows", None, _expect("unset", None, None, ["", "unset"])),
        ("ucrt", "windows", ["ucrt"], _expect("resolved", "ucrt", False, ["ucrt", "dynamic"])),
        ("msvcrt", "windows", ["msvcrt", "ucrt"], _expect("resolved", "msvcrt", False, ["msvcrt", "dynamic"])),
        ("static_ucrt", "windows", ["static-ucrt", "ucrt"], _expect("resolved", "ucrt", True, ["ucrt", "static"])),
        ("not_windows", "linux", ["static-ucrt"], _expect("not_applicable", None, None, ["", ""])),
    ]:
        analysis_test(
            name = "{}_{}_test".format(name, test),
            target = ":{}_subject".format(name),
            impl = impl,
            config_settings = {
                "//command_line_option:platforms": str(Label(":{}_{}".format(name, platform))),
            } | ({_PREFERENCE: preference} if preference != None else {}),
        )

    analysis_test(
        name = name + "_unsupported_test",
        target = "//os/windows/crt:preferred",
        impl = _expect_failure('Unsupported CRT preference "static-msvcrt" in --{}, expected one of: "ucrt", "msvcrt", "static-ucrt"'.format(_PREFERENCE)),
        expect_failure = True,
        config_settings = {_PREFERENCE: ["static-msvcrt"]},
    )
