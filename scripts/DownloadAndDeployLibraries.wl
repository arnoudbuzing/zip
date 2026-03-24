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

Print["--- Fetching Latest Successful Build ID ---"];
runIDRes = RunProcess[{$GH, "run", "list", "--workflow", "build-libraries.yml", "--status", "success", "--limit", "1", "--json", "databaseId", "--jq", ".[0].databaseId"}];

If[runIDRes["ExitCode"] =!= 0 || runIDRes["StandardOutput"] === "",
    Print["Error: Could not find a successful build. Please wait for the GitHub Action to complete."];
    Exit[1]
];

$RunID = StringTrim[runIDRes["StandardOutput"]];
Print["Targeting Run ID: ", $RunID];

Print["--- Downloading GitHub Actions Artifacts ---"];
(* Download all artifacts for the specified run ID non-interactively *)
res = RunProcess[{$GH, "run", "download", $RunID, "--dir", $TempDir}];

If[res["ExitCode"] =!= 0,
    Print["Error downloading artifacts:"];
    Print[res["StandardError"]];
    Exit[1]
];

Print["--- Deploying Libraries to ZipLink/LibraryResources ---"];

KeyValueMap[
    Function[{artifact, systemID},
        sourceFile = $FileMapping[systemID];
        artifactDir = FileNameJoin[{$TempDir, artifact}];
        
        (* Recursive search for the library file within the artifact directory *)
        foundFiles = FileNames[sourceFile, artifactDir, Infinity];
        
        destDir = FileNameJoin[{$PacletDir, "LibraryResources", systemID}];
        (* Ensure consistent naming: FindLibrary["libzip_link"] expects libzip_link.dll on Windows *)
        destFile = If[systemID === "Windows-x86-64", "libzip_link.dll", sourceFile];
        destPath = FileNameJoin[{destDir, destFile}];
        
        If[Length[foundFiles] > 0,
            sourcePath = foundFiles[[1]];
            If[!DirectoryQ[destDir], CreateDirectory[destDir, CreateIntermediateDirectories -> True]];
            Print["Deploying: ", sourcePath, " -> ", destPath];
            CopyFile[sourcePath, destPath, OverwriteTarget -> True],
            Print["Warning: Expected artifact file '", sourceFile, "' not found in ", artifactDir]
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
