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
  {
    BoxData@TemplateBox[
      {
        DynamicBox@FEPrivate`ImportImage@FrontEnd`FileName[{"WakaTime"}, "LogoTextHorizontal.png"],
        "https://wakatime.com/"
      },
      "HyperlinkURL"
    ],
    DynamicModule[{gotTime=None},
      PaneSelector[
        {
          "Ready" -> Grid[{
            {PaneSelector[
              {
                True -> Tooltip[
                  Dynamic[$LatestDashboardTime],
                  Row@{"Today you've spent ", Dynamic[$LatestDashboardTime], "."}
                ],
                False -> "Cannot get dashboard time!"
              },
              Dynamic[gotTime],
              Row@{"Waiting", ProgressIndicator[Appearance -> "Ellipsis"]}
            ]},
            {OpenerView[{
              "WakaTime Config",
              Grid[{
                {
                  Button[
                    "Edit API Key",
                    PromptApiKey[True],
                    Method -> "Queued"
                  ],
                  SpanFromLeft
                },
                {
                  Checkbox[Dynamic[$WakaTimeDebug]],
                  "Debug Mode"
                },
                {
                  Checkbox[Dynamic[$WakaTimeEnabled]],
                  "WakaTime Enabled"
                }
              }, Alignment->{{Center, Left}, Baseline}]
            },
            Dynamic@CurrentValue[EvaluationNotebook[], {TaggingRules, "ConfigOpened"}]
            ]}
          }, Alignment->{Left, Baseline}],
          "Missing CLI" -> "Missing WakaTime CLI!"
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
    ]
  },
  "WakaTime",
  "NotebookOptions" -> {
    TaggingRules -> {
      "ConfigOpened" -> False
    }
  }
];
Block[{$ContextPath=DeleteCases[$ContextPath, "WakaTime`"]},
  ResourceFunction["SaveReadableNotebook"][palette,ResourceFunction["EnsureFilePath"][$path],"ExcludedNotebookOptions"->{}]
]

EndPackage[]
