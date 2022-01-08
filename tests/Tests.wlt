BeginTestSection["WakaTime"]

Needs["WakaTime`"]

VerificationTest[
  TaskWait@SetupWakatimeAsync[];
  $WakaTimeStatus
  ,
  "Ready"
  ,
  TestID->"Setup"
  ,
  TimeConstraint -> 600
]

EndTestSection[]
