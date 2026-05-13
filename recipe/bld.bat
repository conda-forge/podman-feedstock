@echo off
setlocal

set "BUILD_ROOT=%CD%"
set "GOPATH=%BUILD_ROOT%"
set "MODULE_PATH=src\github.com\containers\podman"
set "LICENSE_DIR=%BUILD_ROOT%\license-files"

cd "%BUILD_ROOT%\%MODULE_PATH%"
if %errorlevel% neq 0 exit /b 1

:: Build podman remote for Windows (remote-only, like the macOS build)
go build ^
    -tags "remote,exclude_graphdriver_btrfs,containers_image_openpgp" ^
    -o podman.exe ^
    .\cmd\podman
if %errorlevel% neq 0 exit /b 1

:: Install the binary
if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"
copy podman.exe "%PREFIX%\bin\podman.exe"
if %errorlevel% neq 0 exit /b 1

:: Collect license files
set "GOFLAGS=-tags=remote,exclude_graphdriver_btrfs,containers_image_openpgp"
go-licenses save ./cmd/podman/ --save_path="%LICENSE_DIR%"
if %errorlevel% neq 0 exit /b 1
