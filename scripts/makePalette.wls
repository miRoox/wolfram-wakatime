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
  DynamicModule[{gotTime=None},
    PaneSelector[
      {
        "Ready" -> Grid[{{
          PaneSelector[
            {
              True -> Tooltip[
                Dynamic[$LatestDashboardTime],
                Row@{"Today you've spent ", Dynamic[$LatestDashboardTime], "."}
              ],
              False -> "Cannot get dashboard time!"
            },
            Dynamic[gotTime],
            "Initialized"
          ]
        }}],
        $Failed -> "Cannot setup WakaTime!"
      },
      Dynamic[$WakaTimeStatus],
      Row@{"Initializing", ProgressIndicator[Appearance -> "Ellipsis"]}
    ],
    SynchronousInitialization -> False,
    Initialization :> (
      Needs["WakaTime`"];
      If[$WakaTimeStatus =!= "Ready",
        SetupWakatimeAsync[];
      ];
      gotTime = StringQ[$LatestDashboardTime];
    ),
    UnsavedVariables :> {gotTime}
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
