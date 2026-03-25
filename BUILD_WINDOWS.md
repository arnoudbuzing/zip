# ZipLink Windows Build Instructions

This document provides instructions for building the `ZipLink` Rust library on Windows. Due to persistent linker issues with the WSTP static libraries, a specific workaround is required.

## Prerequisites

1.  **Rust/Cargo**: High-performance Rust toolchain installed.
2.  **Mathematica/Wolfram Engine (15.0)**: Required for WSTP SDK.
    *   WSTP path: `C:\Program Files\Wolfram Research\Wolfram\15.0\SystemFiles\Links\WSTP\DeveloperKit\Windows-x86-64\CompilerAdditions`

## Automated Build (Recommended)

Run the included PowerShell script from the root of the repository:

```powershell
.\scripts\build_windows.ps1
```

This script automates the setup of the `fake_wstp` directory, environment variables, and deployment to the paclet directory.

## Manual Build Steps

If you prefer to run the commands manually:

1.  Create a temporary directory for the workaround:
    ```powershell
    mkdir fake_wstp
    ```
2.  Copy the dynamic WSTP import library and rename it to trick the `wstp-sys` crate:
    ```powershell
    $WstpPath = "C:\Program Files\Wolfram Research\Wolfram\15.0\SystemFiles\Links\WSTP\DeveloperKit\Windows-x86-64\CompilerAdditions"
    copy "$WstpPath\wstp64i4.lib" "fake_wstp\wstp64i4s.lib"
    copy "$WstpPath\wstp.h" "fake_wstp\wstp.h"
    ```
3.  Set the environment variable for the build:
    ```powershell
    $env:WSTP_COMPILER_ADDITIONS_DIRECTORY = "$(Get-Location)\fake_wstp"
    ```
4.  Run the build command from the `zip_link` directory:
    ```powershell
    cd zip_link
    cargo build --release --target x86_64-pc-windows-msvc
    ```
5.  Deploy the built DLL to the paclet resources:
    ```powershell
    copy "target\x86_64-pc-windows-msvc\release\zip_link.dll" "..\ZipLink\LibraryResources\Windows-x86-64\libzip_link.dll"
    ```
6.  Cleanup the temporary directory:
    ```powershell
    cd ..
    Remove-Item -Recurse -Force fake_wstp
    ```

## Why this is necessary

The `wstp-sys` crate used in the project attempts to link statically to the WSTP libraries on Windows. However, these static libraries often contain C++ symbols that are incompatible with newer MSVC runtimes. By providing the dynamic import library (`wstp64i4.lib`) but naming it as the static one (`wstp64i4s.lib`), we trick the build script into linking dynamically, which avoids these runtime mismatches.
