VerificationTest[
    Needs["ZipLink`"];
    MemberQ[$Packages, "ZipLink`"]
    ,
    True
    ,
    TestID -> "LoadPackage"
]

VerificationTest[
    Module[{source = "test_file.txt", zip = "test_file.zip", unzipDir = "unzip_test", res},
        If[FileExistsQ[source], DeleteFile[source]];
        If[FileExistsQ[zip], DeleteFile[zip]];
        If[DirectoryQ[unzipDir], DeleteDirectory[unzipDir, DeleteContents -> True]];
        
        Export[source, "Hello Zip", "String"];
        res = Zip[source, zip];
        If[FailureQ[res], Return[res, Module]];
        
        CreateDirectory[unzipDir];
        res = Unzip[zip, unzipDir];
        If[FailureQ[res], Return[res, Module]];
        
        FileExistsQ[FileNameJoin[{unzipDir, source}]] && Import[FileNameJoin[{unzipDir, source}], "String"] === "Hello Zip"
    ]
    ,
    True
    ,
    TestID -> "ZipUnzipFile"
]

VerificationTest[
    Module[{sourceDir = "test_dir", zip = "test_dir.zip", unzipDir = "unzip_dir_test", res},
        If[DirectoryQ[sourceDir], DeleteDirectory[sourceDir, DeleteContents -> True]];
        If[FileExistsQ[zip], DeleteFile[zip]];
        If[DirectoryQ[unzipDir], DeleteDirectory[unzipDir, DeleteContents -> True]];

        CreateDirectory[sourceDir];
        Export[FileNameJoin[{sourceDir, "file1.txt"}], "Content 1", "String"];
        Export[FileNameJoin[{sourceDir, "file2.txt"}], "Content 2", "String"];
        
        res = Zip[sourceDir, zip];
        If[FailureQ[res], Return[res, Module]];
        
        CreateDirectory[unzipDir];
        res = Unzip[zip, unzipDir];
        If[FailureQ[res], Return[res, Module]];
        
        FileExistsQ[FileNameJoin[{unzipDir, "file1.txt"}]] && 
        FileExistsQ[FileNameJoin[{unzipDir, "file2.txt"}]] &&
        Import[FileNameJoin[{unzipDir, "file1.txt"}], "String"] === "Content 1" &&
        Import[FileNameJoin[{unzipDir, "file2.txt"}], "String"] === "Content 2"
    ]
    ,
    True
    ,
    TestID -> "ZipUnzipDirectory"
]
