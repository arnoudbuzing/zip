# ZipLink

`ZipLink` is a state-of-the-art Wolfram Language paclet that bridges the Wolfram ecosystem with the high-performance Rust `zip` ecosystem through `LibraryLink`. Engineered for speed and reliability, it provides an intuitive interface for managing archives with support for industry-standard compression methods like Deflate, Bzip2, and the ultra-fast ZStandard. Whether you are bundling large datasets for distribution or performing surgical extractions from complex directory structures, `ZipLink` delivers a seamless, native-level experience for archive management in Mathematica and Wolfram Desktop.

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

`ZipLevel`: Integer or `Automatic`.

**"Deflate"**: `0` (least) to `9` (most). Default: `6`.

**"Bzip2"**: `0` (least) to `9` (most). Default: `6`.

**"ZStandard"**: `-7` (least) to `22` (most). Default: `3`.

**None**: Only `Automatic` is supported.

> [!TIP]
> **Performance**: `"ZStandard"` is generally the fastest compression method while providing excellent compression ratios. Use `"None"` if you only need to bundle files without reducing their size. `"Bzip2"` is usually the slowest but can be very effective for large text-based data.

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
Zip["my_data", "data.zip", ZipMethod -> "ZStandard"]

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
