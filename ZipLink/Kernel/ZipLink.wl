BeginPackage["ZipLink`"];

Zip::usage = "Zip[source, dest] zips the source file or directory and saves it to dest.";
Unzip::usage = "Unzip[source, dest] unzips the source file and saves it to dest.";

Begin["`Private`"];

zipLibrary = FindLibrary["libzip_link"];

If[zipLibrary === $Failed,
    (* Fallback to direct path inside the paclet if FindLibrary fails *)
    zipLibrary = FileNameJoin[{
        DirectoryName[$InputFileName], 
        "..", 
        "LibraryResources", 
        $SystemID, 
        "libzip_link." <> Internal`DynamicLibraryExtension[]
    }];
];

If[!FileExistsQ[zipLibrary],
    Print["Error: ZipLink LibraryLink library (libzip_link) not found at ", zipLibrary]
];

iZipFile = LibraryFunctionLoad[zipLibrary, "zip_file", LinkObject, LinkObject];
iUnzipFile = LibraryFunctionLoad[zipLibrary, "unzip_file", LinkObject, LinkObject];

Zip[source_String, dest_String] := 
    Module[{res = iZipFile[ExpandFileName[source], ExpandFileName[dest]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]
Zip[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Zip expects two String arguments (source and dest)."|>]

Unzip[source_String, dest_String] := 
    Module[{res = iUnzipFile[ExpandFileName[source], ExpandFileName[dest]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["UnzipError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]
Unzip[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Unzip expects two String arguments (source and dest)."|>]

End[];
EndPackage[];
