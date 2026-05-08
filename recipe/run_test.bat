@echo off

podman --help
if %errorlevel% neq 0 exit /b 1

podman --version
if %errorlevel% neq 0 exit /b 1

:: Podman on Windows is a remote client only; functional tests require a
:: running Podman service (WSL2/Hyper-V), so we skip them here.
echo Skipping local daemon tests on Windows (podman-remote only)
