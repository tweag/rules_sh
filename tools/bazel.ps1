# Exit immediately if a command fails, if a variable is used without being defined, or if a pipeline fails
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get the Bazel version
$bazel_version = & $Env:BAZEL_REAL --version | ForEach-Object { ($_ -split ' ')[1] }

# Construct the config flag based on the major version
$config = "--config=bazel$($bazel_version -split '\.' | Select-Object -First 1)"

# Initialize an array for startup options
$startup_options = @()

# Parse command-line arguments for options
while ($args.Count -gt 0) {
    $option = $args[0]
    if ($option -match '^-') {
        $startup_options += $option
        $args = $args[1..$($args.Count - 1)]
    } else {
        break
    }
}

# Get the command and remaining arguments
$command = $args[0]
$args = $args[1..$($args.Count - 1)]

# Execute Bazel with the collected options and arguments
& $Env:BAZEL_REAL @startup_options $command $config @args
