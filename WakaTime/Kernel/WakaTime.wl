(* ::Package:: *)

(* ::Title:: *)
(*WakaTime Plugin*)


BeginPackage["WakaTime`", {"GeneralUtilities`"}]


WakaTime::usage="Common message placeholder.";
$WakaTimeEnabled::usage="$WakaTimeEnabled indicate if WakaTime is enabled.";
$WakaTimeApiKey::usage="$WakaTimeApiKey is your WakaTime API key.";
$WakaTimeDebug::usage="$WakaTimeDebug indicate whether WakaTime is on debug mode."
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
SetAttributes[$LatestDashboardTime, {ReadProtected}]
SetAttributes[SetupWakatimeAsync, {ReadProtected}]
SetAttributes[SendHeartbeat, {ReadProtected}]


(* ::Section:: *)
(*Implement*)


Begin["`Private`"]


PersistentValue["WakaTime/Enabled", "Installation"]=True
$WakaTimeEnabledOverriding=False
$WakaTimeEnabled:=$WakaTimeEnabled=PersistentValue["WakaTime/Enabled"]
$WakaTimeEnabled/:Set[$WakaTimeEnabled,val_]/;!TrueQ@$WakaTimeEnabledOverriding:=Enclose@Block[{$WakaTimeEnabledOverriding=True},
  $WakaTimeEnabled=ConfirmBy[val, BooleanQ];
  PersistentValue["WakaTime/Enabled"]=$WakaTimeEnabled
]


(* TODO: config read/write *)
PersistentValue["WakaTime/APIKey", "Installation"]=None
$WakaTimeApiKeyOverriding=False
$WakaTimeApiKey:=$WakaTimeApiKey=PersistentValue["WakaTime/APIKey"]
$WakaTimeApiKey/:Set[$WakaTimeApiKey,val_]/;!TrueQ@$WakaTimeApiKeyOverriding:=Enclose@Block[{$WakaTimeApiKeyOverriding=True},
  $WakaTimeApiKey=ConfirmBy[val, StringMatchQ[RegularExpression["^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"], IgnoreCase -> True]];
  PersistentValue["WakaTime/APIKey"]=$WakaTimeApiKey
]


PersistentValue["WakaTime/DebugMode", "Installation"]=False
$WakaTimeDebugOverriding=False
$WakaTimeDebug:=$WakaTimeDebug=PersistentValue["WakaTime/DebugMode"]
$WakaTimeDebug/:Set[$WakaTimeDebug,val_]/;!TrueQ@$WakaTimeDebugOverriding:=Enclose@Block[{$WakaTimeDebugOverriding=True},
  $WakaTimeDebug=ConfirmBy[val, BooleanQ];
  PersistentValue["WakaTime/DebugMode"]=$WakaTimeDebug
]


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
$cfgPath:=$cfgPath=FileNameJoin@{$wakatimeHome, ".wakatime.cfg"}


$intervalInSecond=120;
$lastSentTime=UnixTime[]-$intervalInSecond;
$lastSentFile="";
$lastProcess=None


SendHeartbeat[opts:OptionsPattern[]]:=If[FileExistsQ@$cliPath,
  iSendHeartbeat@Merge[{Options[SendHeartbeat], opts}, Last],
  Once[Message[WakaTime::nocli]]
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
]
resolveArguments[assoc_Association]:=Splice@Table[
  Replace[assoc[k],{
    None|False|"" -> Nothing,
    True -> "--"<>k,
    v_ :> Splice@{"--"<>k, ToString[v]}
  }],
  {k, Keys[assoc]}
]


setupDashboardTimeUpdater[]:=With[
  {$cliPath=$cliPath, $pluginName=$pluginName, $intervalInSecond=$intervalInSecond},
  {getter:=StringTrim@RunProcess[{
      $cliPath,
      "--plugin", $pluginName,
      "--today"
    }, "StandardOutput"]
  },
  LocalSubmit[
    ScheduledTask[
      WithCleanup[
        getter,
        Pause[0.1] (* workaround to resume the task on the standalone kernel after RunProcess. *)
      ],
      Quantity[$intervalInSecond, "Seconds"]
    ],
    HandlerFunctions -> <|
      "ResultReceived" -> (If[
        StringQ[#EvaluationResult],
        $LatestDashboardTime=#EvaluationResult
      ]&)
    |>,
    HandlerFunctionsKeys -> "EvaluationResult"
  ];
  $LatestDashboardTime:=$LatestDashboardTime=getter
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
setupFrontEnd[]:=(
  CurrentValue[$FrontEndSession, FrontEndEventActions]={
    PassEventsDown -> True,
    "KeyDown" :> eventHandler[False],
    {"MenuCommand", "Save"} :> eventHandler[True]
  };
  (* TODO: AutoloadPath *)
)


SetupWakatimeAsync[]:=(
(* TODO: install wakatime-cli automatically and prompt to enter API key *)
  setupDashboardTimeUpdater[];
  setupPreRead[];
  setupFrontEnd[];
)


(* ::Section:: *)
(*End*)


End[] (*`Private`*)


EndPackage[]


Once@If[$EvaluationEnvironment === "Session",
  SetupWakatimeAsync[]
]
