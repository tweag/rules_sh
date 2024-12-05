# Exit immediately if a command fails, if a variable is used without being defined, or if a pipeline fails
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

# Get the Bazel version
$bazel_version = & $Env:BAZEL_REAL --version | ForEach-Object { ($_ -split ' ')[1] }

# Construct the config flag based on the major version
$config = "--config=bazel7" # BISECT

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
if ($args.Count -gt 0) {
    $command = $args[0]
    if ($args.Count -gt 1) {
        $args = $args[1..($args.Count - 1)]
    } else {
        $args = @()
    }
} else {
    $args = @()
}

# Execute Bazel with the collected options and arguments
& $Env:BAZEL_REAL @startup_options $command $config @args
