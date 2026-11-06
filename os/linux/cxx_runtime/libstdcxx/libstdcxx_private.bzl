visibility(["//os/linux/cxx_runtime/libstdcxx", "//tests"])

# GCC major versions, each of which ships a libstdc++.so.6 with new GLIBCXX symbol versions.
LIBSTDCXX_VERSIONS = [str(major) for major in range(5, 17)]
