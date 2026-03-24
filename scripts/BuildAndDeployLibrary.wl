(* BuildAndDeployLibrary.wl *)

$ProjectDir = ParentDirectory[DirectoryName[$InputFileName]];
$PacletDir = FileNameJoin[{$ProjectDir, "ZipLink"}];
$LinkDir = FileNameJoin[{$ProjectDir, "zip_link"}];

mySystemID = $SystemID; 
$LibraryOutputDir = FileNameJoin[{$PacletDir, "LibraryResources", mySystemID}];

Print["Starting build process for system: ", mySystemID];

(* 1. Compile Rust code *)
Print["Checking Cargo.toml in: ", $LinkDir];
If[!FileExistsQ[FileNameJoin[{$LinkDir, "Cargo.toml"}]],
  Print["Error: Cargo.toml not found in ", $LinkDir];
  Exit[1]
];

Print["Running cargo build..."];
res = RunProcess[{"cargo", "build", "--release"}, ProcessDirectory -> $LinkDir];

If[Not[AssociationQ[res]] || res["ExitCode"] =!= 0,
  Print["Cargo build failed."];
  If[AssociationQ[res], Print[res["StandardError"]]];
  Exit[1]
];

(* 2. Ensure LibraryResources directory exists *)
If[!DirectoryQ[$LibraryOutputDir],
  CreateDirectory[$LibraryOutputDir, CreateIntermediateDirectories -> True]
];

(* 3. Copy compiled library *)
$LibExtension = Internal`DynamicLibraryExtension[];
$LibName = "libzip_link." <> $LibExtension;
$SourcePath = FileNameJoin[{$LinkDir, "target", "release", $LibName}];
$DestPath = FileNameJoin[{$LibraryOutputDir, $LibName}];

Print["Deploying library to: ", $DestPath];
If[FileExistsQ[$SourcePath],
  CopyFile[$SourcePath, $DestPath, OverwriteTarget -> True],
  Print["Error: Compiled library not found at ", $SourcePath];
  Exit[1]
];

Print["Build and deployment successful: ", $DestPath];
Exit[0];
