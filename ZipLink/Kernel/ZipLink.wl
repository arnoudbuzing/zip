BeginPackage["ArnoudBuzing`ZipLink`"];

Zip::usage = "Zip[source, dest] zips the source file or directory and saves it to dest.";
Unzip::usage = "Unzip[source, dest] unzips the source file and saves it to dest.";
ZipInformation::usage = "ZipInformation[zip] returns a list of associations containing metadata for each file in the zip archive.";
ZipExtract::usage = "ZipExtract[zip, file, dest] extracts a single file from the zip archive to the destination directory.";
ZipMethod::usage = "ZipMethod is an option for Zip that specifies the compression algorithm to use (e.g., \"Deflate\", \"Bzip2\", or \"ZStandard\").";
ZipLevel::usage = "ZipLevel is an option for Zip that specifies the intensity of compression (0-9 for most methods).";
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

toPath[path_] := Replace[ExpandFileName[path], File[p_] :> p]

Options[Zip] = {
    ZipMethod -> "ZStandard",
    ZipLevel -> Automatic
};

Zip[source : _String|_File, dest : _String|_File, opts : OptionsPattern[]] := 
    Module[{res, optionsJSON, optionsAssoc},
        optionsAssoc = DeleteCases[<|
            "ZipMethod" -> OptionValue[ZipMethod],
            "ZipLevel" -> OptionValue[ZipLevel]
        |>, Automatic];
        optionsJSON = ExportString[optionsAssoc, "JSON"];
        If[!StringQ[optionsJSON], optionsJSON = "{}"];
        res = iZipFile[toPath[source], toPath[dest], optionsJSON];
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]
Zip[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Zip expects two string or File arguments and optional Options."|>]

Unzip[source : _String|_File, dest : _String|_File] := 
    Module[{res = iUnzipFile[toPath[source], toPath[dest]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["UnzipError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]
Unzip[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Unzip expects two string or File arguments (source and dest)."|>]

ZipInformation[zip : _String|_File] := 
    Module[{res = iZipInfo[toPath[zip]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipInformationError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]

ZipExtract[zip : _String|_File, file_String, dest : _String|_File] := 
    Module[{res = iZipExtract[toPath[zip], file, toPath[dest]]},
        If[StringQ[res] && StringStartsQ[res, "Error:"],
            Failure["ZipExtractError", <|"MessageTemplate" -> res|>],
            res
        ]
    ]

End[];
EndPackage[];
