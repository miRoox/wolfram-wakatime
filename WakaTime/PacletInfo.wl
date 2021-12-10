(* ::Package:: *)

Paclet[
  Name -> "WakaTime",
  Version -> "0.1.0",
  MathematicaVersion -> "12.2+",
  Description -> "WakaTime plugin for Wolfram systems",
  Loading -> Automatic,
  Creator -> "miRoox",
  URL -> "https://github.com/miRoox/wolfram-wakatime",
  Thumbnail -> "Logo.png",
  "Icon" -> "Logo.png",
  Extensions -> {
    {"Kernel", 
      Context -> "WakaTime`",
      Root -> "Kernel",
      Symbols -> {
        "WakaTime`WakaTime",
        "WakaTime`SetupWakatimeAsync",
        "WakaTime`SendHeartbeat"
      }
    },
    {"FrontEnd", Prepend->True}
  }
]


