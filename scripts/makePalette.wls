#!/usr/bin/env wolframscript

BeginPackage["WakaTime`FrontEnd`", {"WakaTime`"}]

ResourceFunction["SaveReadableNotebook"]
ResourceFunction["GitHubInstall"]

If[PacletFind["MirooxUtils"]==={},
  ResourceFunction["GitHubInstall"]["miRoox", "MirooxUtils"]
]

Needs["MirooxUtils`"]

$path=FileNameJoin@{DirectoryName[$InputFileName,2],"WakaTime","FrontEnd","Palettes","WakaTime.nb"}

palette=MakePalette[
  DynamicModule[{init=False, gotTime=False},
    PaneSelector[{
      False -> "Initializing...",
      True -> Grid[{{
        PaneSelector[{
          True -> Tooltip[
            Dynamic[$LatestDashboardTime],
            Row@{"Today you've spent ", Dynamic[$LatestDashboardTime], "."}
          ],
          False -> "Cannot get dashboard time!"
        }, Dynamic[gotTime]]
      }}]
    }, Dynamic[init]],
    SynchronousInitialization -> False,
    Initialization :> (
      Needs["WakaTime`"];
      SetupWakatimeAsync[];
      init=True;
      gotTime = StringQ[$LatestDashboardTime];
    )
  ],
  "WakaTime",
  "NotebookOptions" -> {
    TaggingRules -> {}
  }
];
Block[{$ContextPath=DeleteCases[$ContextPath, "WakaTime`"]},
  ResourceFunction["SaveReadableNotebook"][palette,ResourceFunction["EnsureFilePath"][$path],"ExcludedNotebookOptions"->{}]
]

EndPackage[]
