(* ::Package:: *)

(* ::Title:: *)
(*WakaTime Plugin*)


BeginPackage["WakaTime`", {"GeneralUtilities`"}]


WakaTime::usage="Common message placeholder.";
$WakaTimeEnabled::usage="$WakaTimeEnabled indicate if WakaTime is enabled.";
$WakaTimeApiKey::usage="$WakaTimeApiKey is your WakaTime API key.";
$WakaTimeDebug::usage="$WakaTimeDebug indicate whether WakaTime is on debug mode."
$WakaTimeStatus::usage="$WakaTimeStatus represent status of WakaTime in current session."
$LatestDashboardTime::usage="$LatestDashboardTime get latest dashboard time today."
SetupWakatimeAsync::usage="SetupWakatimeAsync[] setup WakaTime environment asynchronously."


WakaTime::nocli="Cannot find WakaTime CLI.";


Options[SendHeartbeat]:={
  "entity" -> "",
  "write" -> False,
  "category" -> "coding",
  "language" -> "Wolfram",
  "lineno" -> None,
  "project" -> None
}


SetAttributes[$WakaTimeEnabled, {ReadProtected}]
SetAttributes[$WakaTimeApiKey, {ReadProtected}]
SetAttributes[$WakaTimeDebug, {ReadProtected}]
SetAttributes[$WakaTimeStatus, {ReadProtected}]
SetAttributes[$LatestDashboardTime, {ReadProtected}]
SetAttributes[SetupWakatimeAsync, {ReadProtected}]
SetAttributes[SendHeartbeat, {ReadProtected}]


(* ::Section:: *)
(*Implement*)


Begin["`Private`"]


With[{PersistentSymbol=If[TrueQ[$VersionNumber>=12.3], PersistentSymbol, PersistentValue]},
  PersistentSymbol["WakaTime/Enabled", "Installation"]=True;
  $WakaTimeEnabledOverriding=False;
  $WakaTimeEnabled:=$WakaTimeEnabled=PersistentSymbol["WakaTime/Enabled"];
  $WakaTimeEnabled/:Set[$WakaTimeEnabled,val_]/;!TrueQ@$WakaTimeEnabledOverriding:=Enclose@Block[{$WakaTimeEnabledOverriding=True},
    $WakaTimeEnabled=ConfirmBy[val, BooleanQ];
    PersistentSymbol["WakaTime/Enabled"]=$WakaTimeEnabled
  ];
  (* TODO: config read/write *)
  PersistentSymbol["WakaTime/APIKey", "Installation"]=None;
  $WakaTimeApiKeyOverriding=False;
  $WakaTimeApiKey:=$WakaTimeApiKey=PersistentSymbol["WakaTime/APIKey"];
  $WakaTimeApiKey/:Set[$WakaTimeApiKey,val_]/;!TrueQ@$WakaTimeApiKeyOverriding:=Enclose@Block[{$WakaTimeApiKeyOverriding=True},
    $WakaTimeApiKey=ConfirmBy[val, StringMatchQ[RegularExpression["^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"], IgnoreCase -> True]];
    PersistentSymbol["WakaTime/APIKey"]=$WakaTimeApiKey
  ];
  PersistentSymbol["WakaTime/DebugMode", "Installation"]=False;
  $WakaTimeDebugOverriding=False;
  $WakaTimeDebug:=$WakaTimeDebug=PersistentSymbol["WakaTime/DebugMode"];
  $WakaTimeDebug/:Set[$WakaTimeDebug,val_]/;!TrueQ@$WakaTimeDebugOverriding:=Enclose@Block[{$WakaTimeDebugOverriding=True},
    $WakaTimeDebug=ConfirmBy[val, BooleanQ];
    PersistentSymbol["WakaTime/DebugMode"]=$WakaTimeDebug
  ];
]


$WakaTimeStatus=None
$LatestDashboardTime=Missing["NotAvailable", WakaTime]


$paclets:=$paclets=System`PacletFind["WakaTime"]
$pluginVersion:=$pluginVersion=If[Length@$paclets>0,
  First[$paclets]@"Version",
  "0.0.0" (*fallback*)
]
$pluginName:=$pluginName=SystemInformation["Kernel","ProductIDName"]<>"/"<>$Version<>" WakaTime/"<>$pluginVersion


$wakatimeHome:=$wakatimeHome=Module[{$envWakatimeHome=Environment["WAKATIME_HOME"]},
  If[!FailureQ@$envWakatimeHome && DirectoryQ@$envWakatimeHome, $envWakatimeHome, $HomeDirectory]
];
$cliName:=$cliName=Module[{
    os=StringCases[$SystemID,{
      "MacOS"->"darwin",
      os:(LetterCharacter..)~~"-":>ToLowerCase[os]
    }],
    arch=StringCases[$SystemID,{
      "x86-64"->"amd64",
      "x86"->"386",
      arm:("ARM"~~___):>ToLowerCase[arm]
    }]
  },
  "wakatime-cli-"<>os<>"-"<>arch
];
$cliPath:=$cliPath=Module[{ext=If[$OperatingSystem==="Windows", ".exe", ""]},
  FileNameJoin@{$wakatimeHome, ".wakatime", $cliName<>ext}
]
(* TODO: install wakatime-cli automatically *)


tryInstallLatestWakatime[resolve_]:=URLSubmit[
  URL["https://api.github.com/repos/wakatime/wakatime-cli/releases/latest"],
  HandlerFunctions -> <|
   "TaskFinished" -> (handleLatestWakatimeApiResponse[#StatusCode, #ContentType, #Body, resolve] &),
   "ConnectionFailed" -> (handleConnectionFailure[resolve]&)
  |>,
  HandlerFunctionsKeys -> {"ContentType", "Body", "StatusCode"},
  TimeConstraint -> 10
]
handleLatestWakatimeApiResponse[status_, contentType_, body_, resolve_]:=If[TrueQ[status<400 && StringContainsQ[contentType, "application/json"]],
  With[
    {data=ImportString[First@body, "RawJSON"]},
    $WakaTimeStatus="CLI Metadata Ready";
    If[TrueQ[FileExistsQ@$cliPath], (*TODO: check version for update*)
      resolve[],
      tryInstallWakatime[
        SelectFirst[data["assets"], StringStartsQ[#name, $cliName]&],
        resolve
      ]
    ]
  ],
  handleConnectionFailure[resolve]
]
handleConnectionFailure[resolve_]:=If[TrueQ[FileExistsQ@$cliPath],
  resolve[],
  $WakaTimeStatus="Missing CLI"
]
tryInstallWakatime[assertData_, resolve_]:=With[
  {dir=CreateDirectory[]},
  {file=FileNameJoin@{dir, assertData["name"]}},
  URLDownloadSubmit[
    assertData["browser_download_url"],
    file,
    HandlerFunctions -> <|
      "TaskFinished" -> (WithCleanup[
        $WakaTimeStatus="CLI Downloaded";
        CopyFile[ExtractArchive[#File][[1]], $cliPath, OverwriteTarget->True];
        resolve[],
        DeleteDirectory[dir, DeleteContents->True]
      ]&),
      "ConnectionFailed" -> (handleConnectionFailure[resolve]&)
    |>,
    HandlerFunctionsKeys -> {"File"},
    TimeConstraint -> <|
      "Connecting" -> 10,
      "Reading" -> 600
    |>
  ]
]


$cfgPath:=$cfgPath=FileNameJoin@{$wakatimeHome, ".wakatime.cfg"}


$intervalInSecond=120;
$lastSentTime=UnixTime[]-$intervalInSecond;
$lastSentFile="";
$lastProcess=None


SendHeartbeat[opts:OptionsPattern[]]:=If[FileExistsQ@$cliPath,
  iSendHeartbeat@Merge[{Options[SendHeartbeat], opts}, Last],
  Once[Message[WakaTime::nocli]];
  $Failed
]
iSendHeartbeat[assoc_Association]:=If[assoc@"entity"=!=$lastSentFile || UnixTime[]-$lastSentTime>=$intervalInSecond || assoc@"write",
  $lastProcess=StartProcess@{
    $cliPath,
    "--plugin", $pluginName,
    If[TrueQ@$WakaTimeDebug, "--verbose", Nothing],
    resolveArguments@assoc
  };
  $lastSentTime=UnixTime[];
  $lastSentFile=assoc@"entity";
  $lastProcess
]
resolveArguments[assoc_Association]:=Splice@Table[
  Replace[assoc[k],{
    None|False|"" -> Nothing,
    True -> "--"<>k,
    v_ :> Splice@{"--"<>k, ToString[v]}
  }],
  {k, Keys[assoc]}
]


$updaterTask = None
setupDashboardTimeUpdater[]:=If[!MatchQ[$updaterTask, _TaskObject] || $updaterTask@"TaskStatus" =!= "Running",
  With[
    {$cliPath=$cliPath, $pluginName=$pluginName, $intervalInSecond=$intervalInSecond},
    {getter:=StringTrim@RunProcess[{
        $cliPath,
        "--plugin", $pluginName,
        "--today"
      }, "StandardOutput"]
    },
    $updaterTask = SessionSubmit[
      ScheduledTask[
        getter,
        Quantity[$intervalInSecond, "Seconds"]
      ],
      HandlerFunctions -> <|
        "ResultReceived" -> (If[
          StringQ[#EvaluationResult],
          $LatestDashboardTime=#EvaluationResult
        ]&)
      |>,
      HandlerFunctionsKeys -> "EvaluationResult",
      Method -> "Idle"
    ];
    $LatestDashboardTime:=$LatestDashboardTime=getter
  ]
]


PreReadHook[v_]:=If[TrueQ@$WakaTimeEnabled,
  SendHeartbeat[
    "entity" -> If[$Notebooks, AbsoluteCurrentValue[EvaluationNotebook[], "NotebookFullFileName"], $InputFileName],
    "category"->"debugging",
    "lineno"->$Line
  ];
  v,
  v
]
setupPreRead[]:=Once[
  If[ValueQ[$PreRead], $PreRead=PreReadHook@*$PreRead, $PreRead=PreReadHook];
  $PreReadOverriding=False;
  $PreRead/:Set[$PreRead, val_/;FreeQ[val, PreReadHook]]/;!TrueQ@$PreReadOverriding:=Block[{$PreReadOverriding=True}, $PreRead=PreReadHook@*val];
  $PreRead/:Unset[$PreRead]/;!TrueQ@$PreReadOverriding:=Block[{$PreReadOverriding=True}, $PreRead=PreReadHook];
]


eventHandler/:RuleDelayed[event_, eventHandler[isWrite_]]:=RuleDelayed[event, 
  If[TrueQ@WakaTime`$WakaTimeEnabled,
    WakaTime`SendHeartbeat[
      "entity" -> AbsoluteCurrentValue["NotebookFullFileName"],
      "write" -> isWrite
    ],
    Inherited
  ]
]
setupFrontEnd[]:=If[$Notebooks && CurrentValue[$FrontEndSession, FrontEndEventActions] === None,
  CurrentValue[$FrontEndSession, FrontEndEventActions]={
    PassEventsDown -> True,
    "KeyDown" :> eventHandler[False],
    {"MenuCommand", "Save"} :> eventHandler[True]
  };
  (* TODO: AutoloadPath *)
]


SetupWakatimeAsync[]:=tryInstallLatestWakatime[wakatimeCliReady]
wakatimeCliReady[]:=(
  (* TODO: prompt to enter API key *)
  setupDashboardTimeUpdater[];
  setupPreRead[];
  setupFrontEnd[];
  $WakaTimeStatus="Ready"
)


(* ::Section:: *)
(*End*)


End[] (*`Private`*)


EndPackage[]


Once@If[$EvaluationEnvironment === "Session",
  SetupWakatimeAsync[]
]
