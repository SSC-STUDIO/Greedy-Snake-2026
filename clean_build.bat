@echo off
setlocal
set "ROOT=%~dp0"
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
msbuild "%ROOT%Greed-Snake-2025.sln" /t:Clean /p:Configuration=Release /p:Platform=x64
msbuild "%ROOT%Greed-Snake-2025.sln" /t:Rebuild /p:Configuration=Release /p:Platform=x64 /m /v:m
