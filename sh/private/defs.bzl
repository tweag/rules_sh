ConstantInfo = provider(fields = ["value"])

def _constant_impl(ctx):
    return [ConstantInfo(value = ctx.attr.value)]

bool_constant = rule(
    _constant_impl,
    attrs = {
        "value": attr.bool(),
    },
)
