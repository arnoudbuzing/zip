# ZipLink

`ZipLink` is a Wolfram Language paclet that provides bindings to the Rust `zip` crate via LibraryLink. It allows for high-performance zipping and unzipping of files and directories.

## Features

- **Efficient**: Uses the Rust `zip` crate for compressed archive operations.
- **Recursive**: Supports zipping entire directory structures.
- **LibraryLink**: Seamlessly integrated into the Wolfram Language.

## Building the Paclet

To build the project, you need to have `cargo` (Rust) and `wolframscript` installed.

1.  Clone the repository (or enter the project directory).
2.  Run the build script:
    ```bash
    wolframscript -file scripts/BuildPaclet.wl
    ```
    This script will:
    - Compile the Rust code in `zip_link/`.
    - Copy the dynamic library to the paclet's `LibraryResources` directory.
    - Build the final `.paclet` file in the `build/` directory.

## Installation

After building, you can install the paclet using:
```wolfram
PacletInstall["build/ZipLink-MacOSX-ARM64-1.0.0.paclet"]
```
*(Adjust the filename based on your system ID and version)*

## Quick Start

```wolfram
Needs["ZipLink`"]

(* Zip a file or directory *)
Zip["path/to/source", "archive.zip"]

(* Unzip an archive *)
Unzip["archive.zip", "path/to/destination"]
```

## Testing

Run the included unit tests using:
```bash
wolframscript -file scripts/RunTests.wl
```
All testing artifacts and temporary files are managed within the `tests/` directory.
