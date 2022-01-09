#!/usr/bin/env wolframscript
(* ::Package:: *)

$baseDir=DirectoryName[$InputFileName, 2];

$pacletDir=FileNameJoin@{$baseDir, "WakaTime"};

PacletDirectoryLoad@$pacletDir

Needs["MUnit`"]
Get["https://raw.githubusercontent.com/miRoox/CILogger-MUnit/master/CILogger/CILogger.wl"]

Needs["WakaTime`"]

$testDir=FileNameJoin@{$baseDir, "tests"};

If[
  AllTrue[
    FileNames["*.mt"|"*.wlt", $testDir],
    MUnit`TestRun[#, "Loggers" :> {CILogger`CILogger[]}]&
  ],
  Exit[],
  Exit[1]
]
