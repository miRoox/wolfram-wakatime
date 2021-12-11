(* ::Package:: *)

Paclet[
  Name -> "WakaTime",
  Version -> "0.1.0",
  MathematicaVersion -> "12.2+",
  Description -> "WakaTime plugin for Wolfram systems",
  Loading -> Manual,
  Creator -> "miRoox",
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


