"""Unittest to verify properties of rustdoc rules"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("//cargo:defs.bzl", "cargo_build_script")
load("//rust:defs.bzl", "rust_binary", "rust_doc", "rust_doc_test", "rust_library", "rust_proc_macro", "rust_test")
load(
    "//test/unit:common.bzl",
    "assert_action_mnemonic",
    "assert_argv_contains_prefix_not",
)

def _common_rustdoc_checks(env, tut):
    actions = tut.actions
    action = actions[0]
    assert_action_mnemonic(env, action, "Rustdoc")

    # These flags, while required for `Rustc` actions, should be omitted for
    # `Rustdoc` actions
    assert_argv_contains_prefix_not(env, action, "--remap-path-prefix")
    assert_argv_contains_prefix_not(env, action, "--emit")

def _rustdoc_for_lib_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    _common_rustdoc_checks(env, tut)

    return analysistest.end(env)

def _rustdoc_for_bin_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    _common_rustdoc_checks(env, tut)

    return analysistest.end(env)

def _rustdoc_for_proc_macro_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    _common_rustdoc_checks(env, tut)

    return analysistest.end(env)

def _rustdoc_for_lib_with_proc_macro_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    _common_rustdoc_checks(env, tut)

    return analysistest.end(env)

def _rustdoc_for_bin_with_transitive_proc_macro_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    _common_rustdoc_checks(env, tut)

    return analysistest.end(env)

def _rustdoc_for_lib_with_cc_lib_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)

    _common_rustdoc_checks(env, tut)

    return analysistest.end(env)

rustdoc_for_lib_test = analysistest.make(_rustdoc_for_lib_test_impl)
rustdoc_for_bin_test = analysistest.make(_rustdoc_for_bin_test_impl)
rustdoc_for_proc_macro_test = analysistest.make(_rustdoc_for_proc_macro_test_impl)
rustdoc_for_lib_with_proc_macro_test = analysistest.make(_rustdoc_for_lib_with_proc_macro_test_impl)
rustdoc_for_bin_with_transitive_proc_macro_test = analysistest.make(_rustdoc_for_bin_with_transitive_proc_macro_test_impl)
rustdoc_for_lib_with_cc_lib_test = analysistest.make(_rustdoc_for_lib_with_cc_lib_test_impl)

def _target_maker(rule_fn, name, rustdoc_deps = [], **kwargs):
    rule_fn(
        name = name,
        edition = "2018",
        **kwargs
    )

    rust_test(
        name = "{}_test".format(name),
        crate = ":{}".format(name),
        edition = "2018",
    )

    rust_doc(
        name = "{}_doc".format(name),
        crate = ":{}".format(name),
    )

    rust_doc_test(
        name = "{}_doctest".format(name),
        crate = ":{}".format(name),
        deps = rustdoc_deps,
    )

def _define_targets():
    rust_library(
        name = "adder",
        srcs = ["adder.rs"],
        edition = "2018",
    )

    _target_maker(
        rust_binary,
        name = "bin",
        srcs = ["rustdoc_bin.rs"],
    )

    _target_maker(
        rust_library,
        name = "lib",
        srcs = ["rustdoc_lib.rs"],
        rustdoc_deps = [":adder"],
    )

    _target_maker(
        rust_library,
        name = "nodep_lib",
        srcs = ["rustdoc_nodep_lib.rs"],
    )

    _target_maker(
        rust_proc_macro,
        name = "rustdoc_proc_macro",
        srcs = ["rustdoc_proc_macro.rs"],
    )

    _target_maker(
        rust_library,
        name = "lib_with_proc_macro",
        srcs = ["rustdoc_lib.rs"],
        rustdoc_deps = [":adder"],
        proc_macro_deps = [":rustdoc_proc_macro"],
        crate_features = ["with_proc_macro"],
    )

    _target_maker(
        rust_library,
        name = "lib_nodep_with_proc_macro",
        srcs = ["rustdoc_nodep_lib.rs"],
        proc_macro_deps = [":rustdoc_proc_macro"],
        crate_features = ["with_proc_macro"],
    )

    _target_maker(
        rust_binary,
        name = "bin_with_transitive_proc_macro",
        srcs = ["rustdoc_bin.rs"],
        deps = [":lib_with_proc_macro"],
        proc_macro_deps = [":rustdoc_proc_macro"],
        crate_features = ["with_proc_macro"],
    )

    cc_library(
        name = "cc_lib",
        hdrs = ["rustdoc.h"],
        srcs = ["rustdoc.cc"],
    )

    _target_maker(
        rust_library,
        name = "lib_with_cc",
        srcs = ["rustdoc_lib.rs"],
        rustdoc_deps = [":adder"],
        crate_features = ["with_cc"],
        deps = [":cc_lib"],
    )

    _target_maker(
        rust_library,
        name = "lib_nodep_with_cc",
        srcs = ["rustdoc_nodep_lib.rs"],
        crate_features = ["with_cc"],
        deps = [":cc_lib"],
    )

    cargo_build_script(
        name = "lib_build_script",
        srcs = ["rustdoc_build.rs"],
        edition = "2018",
    )

    _target_maker(
        rust_library,
        name = "lib_with_build_script",
        srcs = ["rustdoc_lib.rs"],
        rustdoc_deps = [":adder"],
        crate_features = ["with_build_script"],
        deps = [":lib_build_script"],
    )

    _target_maker(
        rust_library,
        name = "lib_nodep_with_build_script",
        srcs = ["rustdoc_nodep_lib.rs"],
        crate_features = ["with_build_script"],
        deps = [":lib_build_script"],
    )

def rustdoc_test_suite(name):
    """Entry-point macro called from the BUILD file.

    Args:
        name (str): Name of the macro.
    """

    _define_targets()

    rustdoc_for_lib_test(
        name = "rustdoc_for_lib_test",
        target_under_test = ":lib_doc",
    )

    rustdoc_for_bin_test(
        name = "rustdoc_for_bin_test",
        target_under_test = ":bin_doc",
    )

    rustdoc_for_proc_macro_test(
        name = "rustdoc_for_proc_macro_test",
        target_under_test = ":rustdoc_proc_macro_doc",
    )

    rustdoc_for_lib_with_proc_macro_test(
        name = "rustdoc_for_lib_with_proc_macro_test",
        target_under_test = ":lib_with_proc_macro_doc",
    )

    rustdoc_for_bin_with_transitive_proc_macro_test(
        name = "rustdoc_for_bin_with_transitive_proc_macro_test",
        target_under_test = ":bin_with_transitive_proc_macro_doc",
    )

    rustdoc_for_lib_with_cc_lib_test(
        name = "rustdoc_for_lib_with_cc_lib_test",
        target_under_test = ":lib_with_cc_doc",
    )

    native.test_suite(
        name = name,
        tests = [
            ":rustdoc_for_lib_test",
            ":rustdoc_for_bin_test",
            ":rustdoc_for_proc_macro_test",
            ":rustdoc_for_lib_with_proc_macro_test",
            ":rustdoc_for_lib_with_cc_lib_test",
        ],
    )
