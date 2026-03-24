(* DownloadAndDeployLibraries.wl *)

$ProjectDir = ParentDirectory[DirectoryName[$InputFileName]];
$PacletDir = FileNameJoin[{$ProjectDir, "ZipLink"}];
$TempDir = FileNameJoin[{$ProjectDir, "temp_artifacts"}];

$ArtifactSystemMapping = <|
    "aarch64-apple-darwin-library" -> "MacOSX-ARM64",
    "x86_64-pc-windows-msvc-library" -> "Windows-x86-64",
    "x86_64-unknown-linux-gnu-library" -> "Linux-x86-64"
|>;

$FileMapping = <|
    "MacOSX-ARM64" -> "libzip_link.dylib",
    "Windows-x86-64" -> "zip_link.dll",
    "Linux-x86-64" -> "libzip_link.so"
|>;

(* Find gh CLI *)
$GH = "gh";
If[$GH === $Failed,
    Print["Error: GitHub CLI (gh) not found in PATH. Please install it from https://cli.github.com/"];
    Exit[1]
];

Print["--- Downloading GitHub Actions Artifacts ---"];
(* Download all artifacts for the most recent run *)
res = RunProcess[{$GH, "run", "download", "--dir", $TempDir}];

If[res["ExitCode"] =!= 0,
    Print["Error downloading artifacts:"];
    Print[res["StandardError"]];
    Exit[1]
];

Print["--- Deploying Libraries to ZipLink/LibraryResources ---"];

KeyValueMap[
    Function[{artifact, systemID},
        sourceFile = $FileMapping[systemID];
        sourcePath = FileNameJoin[{$TempDir, artifact, sourceFile}];
        
        destDir = FileNameJoin[{$PacletDir, "LibraryResources", systemID}];
        (* Ensure consistent naming: FindLibrary["libzip_link"] expects libzip_link.dll on Windows *)
        destFile = If[systemID === "Windows-x86-64", "libzip_link.dll", sourceFile];
        destPath = FileNameJoin[{destDir, destFile}];
        
        If[FileExistsQ[sourcePath],
            If[!DirectoryQ[destDir], CreateDirectory[destDir, CreateIntermediateDirectories -> True]];
            Print["Deploying: ", sourceFile, " -> ", destPath];
            CopyFile[sourcePath, destPath, OverwriteTarget -> True],
            Print["Warning: Expected artifact file not found: ", sourcePath]
        ]
    ],
    $ArtifactSystemMapping
];

(* Clean up *)
If[DirectoryQ[$TempDir],
    DeleteDirectory[$TempDir, DeleteContents -> True]
];

Print["--- Deployment Complete ---"];
Exit[0];
