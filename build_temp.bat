@echo off
setlocal
set "ROOT=%~dp0"
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
msbuild "%ROOT%Greed-Snake-2025.sln" /p:Configuration=Release /p:Platform=x64 /t:Rebuild /m /v:m
