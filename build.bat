@echo off
setlocal
set "ROOT=%~dp0"
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" "%ROOT%Greed-Snake-2025.sln" /p:Configuration=Release /p:Platform=x64 /t:Rebuild
