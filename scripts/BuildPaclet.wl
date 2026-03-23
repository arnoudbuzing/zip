(* BuildPaclet.wl *)

$ProjectDir = ParentDirectory[DirectoryName[$InputFileName]];
$PacletDir = FileNameJoin[{$ProjectDir, "ZipLink"}];
$LinkDir = FileNameJoin[{$ProjectDir, "zip_link"}];
$BuildDir = FileNameJoin[{$ProjectDir, "build"}];

(* Use the current system's ID *)
mySystemID = $SystemID; 
$LibraryOutputDir = FileNameJoin[{$PacletDir, "LibraryResources", mySystemID}];

Print["Starting build process for system: ", mySystemID];

(* 1. Ensure directories exist *)
If[!DirectoryQ[$BuildDir],
  CreateDirectory[$BuildDir, CreateIntermediateDirectories -> True]
];

(* 2. Compile Rust code *)
Print["Checking Cargo.toml in: ", $LinkDir];
If[!FileExistsQ[FileNameJoin[{$LinkDir, "Cargo.toml"}]],
  Print["Error: Cargo.toml not found in ", $LinkDir];
  Quit[1]
];

Print["Running cargo build..."];
res = RunProcess[{"cargo", "build", "--release"}, ProcessDirectory -> $LinkDir];

If[Not[AssociationQ[res]] || res["ExitCode"] =!= 0,
  Print["Cargo build failed."];
  If[AssociationQ[res], Print[ToString[res["StandardError"]]]];
  Quit[1]
];

(* 3. Ensure LibraryResources directory exists *)
If[!DirectoryQ[$LibraryOutputDir],
  CreateDirectory[$LibraryOutputDir, CreateIntermediateDirectories -> True]
];

(* 4. Copy compiled library *)
$LibExtension = Internal`DynamicLibraryExtension[];
$LibName = "libzip_link." <> $LibExtension;
$SourcePath = FileNameJoin[{$LinkDir, "target", "release", $LibName}];
$DestPath = FileNameJoin[{$LibraryOutputDir, $LibName}];

Print["Copying library to: ", $DestPath];
If[FileExistsQ[$SourcePath],
  CopyFile[$SourcePath, $DestPath, OverwriteTarget -> True],
  Print["Error: Compiled library not found at ", $SourcePath];
  Quit[1]
];

(* 5. Build Paclet *)
Needs["PacletTools`"];
Print["Building paclet file to: ", $BuildDir];
$result = PacletBuild[$PacletDir, $BuildDir];

If[Head[$result] === Success,
  $DefaultPacletFile = $result["PacletArchive"];
  If[StringQ[$DefaultPacletFile] && FileExistsQ[$DefaultPacletFile],
    pObj = PacletObject["File" -> $PacletDir];
    pVersion = pObj["Version"];
    pName = pObj["Name"];
    
    If[MissingQ[pName], pName = "ZipLink"];
    If[MissingQ[pVersion], pVersion = "1.0.0"];
    
    newName = pName <> "-" <> mySystemID <> "-" <> pVersion <> ".paclet";
    newPath = FileNameJoin[{$BuildDir, newName}];
    
    Print["Renaming ", FileNameTake[$DefaultPacletFile], " to ", newName];
    RenameFile[$DefaultPacletFile, newPath, OverwriteTarget -> True];
    
    If[FileExistsQ[newPath],
      Print["Build successful: ", newPath],
      Print["Failed to rename paclet file."];
      Quit[1]
    ],
    Print["Build failed. Archive not found: ", $DefaultPacletFile];
    Quit[1]
  ],
  Print["Build failed. Result was:"];
  Print[InputForm[$result]];
  Quit[1]
];

Print["Build complete."];
Quit[0];
