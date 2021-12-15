(* ::Package:: *)

Paclet[
  Name -> "WakaTime",
  Version -> "0.1.0",
  MathematicaVersion -> "12.2+",
  Description -> "WakaTime plugin for Wolfram systems",
  Loading -> Manual,
  "Keywords" -> {"WakaTime", "Time Tracking"},
  Creator -> "Yongan Lu <miroox@outlook.com>",
  URL -> "https://github.com/miRoox/wolfram-wakatime",
  Thumbnail -> "Logo.png",
  "Icon" -> "Logo.png",
  Extensions -> {
    {"Kernel", 
      Context -> "WakaTime`",
      Root -> "Kernel"
    },
    {"FrontEnd", Prepend->True}
  }
]
