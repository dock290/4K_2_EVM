@echo off
SET file=%1
SET filename=%~n1
SET extension=%~x1
@REM /zi - include debug symbols (full)
@REM /ml - case sensitive (all)
tasm32\tasm32.exe /zi /ml %filename%.asm
@REM /Tpe - 32-bit EXE
@REM /ap - 32-bit console app
@REM /v - include debug symbols
tasm32\tlink32.exe /Tpe /ap /v %filename%.obj
