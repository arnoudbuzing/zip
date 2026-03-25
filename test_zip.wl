PacletDirectoryLoad["c:\\Users\\arnou\\github\\zip\\ZipLink"];
Needs["ZipLink`"];
res = Zip["test_output.zip", {"c:\\Users\\arnou\\github\\zip\\README.md"}];
Print["Result of Zip: ", res];
If[FileExistsQ["test_output.zip"], Print["Success! ZIP created."]];
Exit[];
