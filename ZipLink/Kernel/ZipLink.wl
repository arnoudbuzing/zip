BeginPackage["ArnoudBuzing`ZipLink`"];

Zip::usage = "Zip[source, dest] zips the source file or directory and saves it to dest.";
Unzip::usage = "Unzip[source, dest] unzips the source file and saves it to dest.";
ZipInformation::usage = "ZipInformation[zip] returns a list of associations containing metadata for each file in the zip archive.";
ZipExtract::usage = "ZipExtract[zip, file, dest] extracts a single file from the zip archive to the destination directory.";
Zip::nolib = "ZipLink LibraryLink library (libzip_link) not found at `1`.";

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
    Message[Zip::nolib, zipLibrary]
];

iZipFile = LibraryFunctionLoad[zipLibrary, "zip_file", LinkObject, LinkObject];
iUnzipFile = LibraryFunctionLoad[zipLibrary, "unzip_file", LinkObject, LinkObject];
iZipInfo = LibraryFunctionLoad[zipLibrary, "zip_info", LinkObject, LinkObject];
iZipExtract = LibraryFunctionLoad[zipLibrary, "zip_extract_file", LinkObject, LinkObject];

Options[Zip] = {
    "CompressionMethod" -> "Deflate",
    "CompressionLevel" -> Automatic
};

Zip[source_String, dest_String, opts : OptionsPattern[]] := 
    Module[{res, optionsJSON, optionsAssoc},
        optionsAssoc = DeleteCases[<|
            "CompressionMethod" -> OptionValue["CompressionMethod"],
            "CompressionLevel" -> OptionValue["CompressionLevel"]
        |>, Automatic];
        optionsJSON = ExportString[optionsAssoc, "JSON"];
        If[!StringQ[optionsJSON], optionsJSON = "{}"];
        res = iZipFile[ExpandFileName[source], ExpandFileName[dest], optionsJSON];
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]
Zip[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Zip expects two String arguments and optional Options."|>]

Unzip[source_String, dest_String] := 
    Module[{res = iUnzipFile[ExpandFileName[source], ExpandFileName[dest]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["UnzipError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]
Unzip[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Unzip expects two String arguments (source and dest)."|>]

ZipInformation[zip_String] := 
    Module[{res = iZipInfo[ExpandFileName[zip]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipInformationError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]

ZipExtract[zip_String, file_String, dest_String] := 
    Module[{res = iZipExtract[ExpandFileName[zip], file, ExpandFileName[dest]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipExtractError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]

End[];
EndPackage[];
