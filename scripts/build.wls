#!/usr/bin/env wolframscript

$pacletDir=FileNameJoin@{DirectoryName[$InputFileName, 2], "WakaTime"}

PacletDirectoryLoad[$pacletDir]

return[exitcode_:0]:=If[
  exitcode=!=0,
  Throw[exitcode, return]
]

Catch[
  Block[{Exit=return},
    Get@FileNameJoin@{DirectoryName[$InputFileName], "makePalette.wls"}
  ],
  return,
  {value, tag}|->Quit[value]
]

paclet=CreatePacletArchive[$pacletDir]

If[FailureQ@paclet,
  Exit[1],
  Print["::set-output name=name::", FileNameTake@paclet];
]
