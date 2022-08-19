load("@bazel_skylib//lib:dicts.bzl", "dicts")

ConstantInfo = provider(fields = ["value"])

def _constant_impl(ctx):
    return [ConstantInfo(value = ctx.attr.value)]

bool_constant = rule(
    _constant_impl,
    attrs = {
        "value": attr.bool(),
    },
)

def to_var_name(label_name):
    """Turn a label name into a template variable info.

    Uses all upper case variable names with `_` as separator.
    """
    return label_name.upper().replace("-", "_")

def mk_template_variable_info(name, sh_binaries_info):
    var_prefix = to_var_name(name)
    return platform_common.TemplateVariableInfo(dicts.add(
        {
            "{}_{}".format(var_prefix, to_var_name(name)): file.path
            for name, file in sh_binaries_info.executables.items()
        },
        {
            "_{}_PATH".format(var_prefix): ":".join(sh_binaries_info.paths.to_list()),
        },
    ))
