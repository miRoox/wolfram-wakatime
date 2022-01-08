BeginTestSection["WakaTime"]

Needs["WakaTime`"]

VerificationTest[
  TaskWait@SetupWakatimeAsync[];
  Pause[1]; (* ensure downloading task already started *)
  TaskWait[Select[Tasks[], #["TaskType"] === "Asynchronous"&]]; (* wait for async downloading task*)
  $WakaTimeStatus
  ,
  "Ready"
  ,
  TestID->"Setup"
  ,
  TimeConstraint -> 600
]

VerificationTest[
  ReadString@SendHeartbeat["entity" -> $TestFileName, "category" -> "running tests"]
  ,
  EndOfFile
  ,
  TestID->"SendHeartbeat"
  ,
  TimeConstraint -> 60
]

EndTestSection[]
