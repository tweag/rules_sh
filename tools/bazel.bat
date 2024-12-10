@echo off

:: Check if bash is available
where bash >nul 2>nul
if errorlevel 1 (
   echo Bash is not installed or not in PATH. Please install WSL or add bash to PATH.
   exit /b 1
)

# disable POSIX-to-Windows path conversion for MINGW / MSYS2
set MSYS_NO_PATHCONV=1

:: Call the Bash wrapper
bash --noprofile --norc -o errexit -o nounset -o pipefail "%~dp0bazel" %*

