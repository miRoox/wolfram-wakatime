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
  Grid[{{
    Tooltip[
      Dynamic[$LatestDashboardTime],
      Row@{"Today you've spent ", Dynamic[$LatestDashboardTime], "."}
    ]
  }}],
  "WakaTime",
  "NotebookOptions" -> {
    TaggingRules -> {},
    NotebookDynamicExpression :> Refresh[Needs["WakaTime`"], None]
  }
];
Block[{$ContextPath=DeleteCases[$ContextPath, "WakaTime`"]},
  ResourceFunction["SaveReadableNotebook"][palette,ResourceFunction["EnsureFilePath"][$path],"ExcludedNotebookOptions"->{}]
]

EndPackage[]
