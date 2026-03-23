(* RunTests.wl *)

PacletDirectoryLoad[ParentDirectory[DirectoryName[$InputFileName]]];
Needs["ZipLink`"];

$TestFile = FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "tests", "ZipLink.wlt"}];

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
    Print["Some tests failed:"];
    Scan[
        res = #;
        Print[res["TestID"], ": ", res["Outcome"]];
    ] &,
    tr["TestResults"]
];

If[tr["TestsFailedCount"] > 0, Quit[1], Quit[0]];
