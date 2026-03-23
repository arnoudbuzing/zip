(* RunTests.wl *)

$ScriptDir = DirectoryName[$InputFileName];
$ProjectDir = ParentDirectory[$ScriptDir];

PacletDirectoryLoad[$ProjectDir];
Needs["ZipLink`"];

$TestFile = FileNameJoin[{$ProjectDir, "tests", "ZipLink.wlt"}];

If[!FileExistsQ[$TestFile],
    Print["Error: Test file not found at ", $TestFile];
    Quit[1]
];

Print["Running tests from ", $TestFile];
SetDirectory[DirectoryName[$TestFile]];
tr = TestReport[FileNameTake[$TestFile]];
ResetDirectory[];

Print["Tests Succeeded: ", tr["TestsSucceededCount"]];
Print["Tests Failed: ", tr["TestsFailedCount"]];

If[tr["TestsFailedCount"] > 0,
    Print["\nDetailed Failures:"];
    Scan[
        Function[res,
            If[res["Outcome"] =!= "Success",
                Print["-------------------------------------------------"];
                Print["TestID: ", res["TestID"]];
                Print["Outcome: ", res["Outcome"]];
                Print["Input: ", InputForm[res["Input"]]];
                Print["Expected Output: ", InputForm[res["ExpectedOutput"]]];
                Print["Actual Output: ", InputForm[res["ActualOutput"]]];
            ]
        ],
        Values[tr["TestResults"]]
    ]
];

If[tr["TestsFailedCount"] > 0, Quit[1], Quit[0]];
