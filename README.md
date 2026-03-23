# ZipLink

`ZipLink` is a Wolfram Language paclet that provides bindings to the Rust `zip` crate via LibraryLink. It allows for high-performance zipping and unzipping of files and directories with support for modern compression formats.

## Features

- **Multi-Format Support**: Deflate, Bzip2, and ZStandard (zstd) compression.
- **Archive Inspection**: List contents and metadata without extracting.
- **Single File Extraction**: Extract specific files from an archive.
- **Recursive**: Supports zipping entire directory structures.
- **LibraryLink**: High-performance Rust-to-WL integration.

## Building the Paclet

To build the project, you need to have `cargo` (Rust) and `wolframscript` installed.

1.  Clone the repository (or enter the project directory).
2.  Run the build script:
    ```bash
    wolframscript -file scripts/BuildPaclet.wl
    ```

## Installation

```wolfram
PacletInstall["build/ZipLink-MacOSX-ARM64-1.0.0.paclet"]
```

## Functions

### `Zip[source, dest, options]`
Creates a zip archive at `dest` containing the file or directory at `source`.

- **Options**:
    - `"CompressionMethod"`: `"Deflate"` (default), `"Bzip2"`, `"ZStandard"`, or `"None"`.
    - `"CompressionLevel"`: Integer (higher for better compression, lower for speed).

### `Unzip[source, dest]`
Extracts the entire contents of the zip archive at `source` into the directory at `dest`.

### `ZipInformation[zip]`
Returns a list of associations containing metadata for each file in the archive.
- Fields: `"FileName"`, `"Size"`, `"CompressedSize"`, `"CompressionMethod"`, `"CRC32"`.

### `ZipExtract[zip, file, dest]`
Extracts a specific `file` (relative path in the archive) from the `zip` into the `dest` directory.

## Quick Start

```wolfram
Needs["ZipLink`"]

(* Zip using ZStandard compression *)
Zip["my_data", "data.zip", "CompressionMethod" -> "ZStandard"]

(* Inspect the archive *)
ZipInformation["data.zip"]

(* Extract just one file *)
ZipExtract["data.zip", "my_data/report.txt", "extracts"]
```

## Testing

Run the included unit tests using:
```bash
wolframscript -file scripts/RunTests.wl
```
All testing artifacts and temporary files are managed within the `tests/` directory.
