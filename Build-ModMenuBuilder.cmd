@echo off
setlocal
set "SLN=%~dp0ModMenuBuilder.sln"
if not exist "%SLN%" (
  echo ERROR: ModMenuBuilder.sln not found. Run this script in the repository root.
  pause
  exit /b 1
)

where msbuild >nul 2>&1
if errorlevel 1 (
  echo MSBuild was not found.
  echo Open "Developer Command Prompt for Visual Studio" or use Visual Studio's Build menu.
  pause
  exit /b 1
)

msbuild "%SLN%" /t:Build /p:Configuration=Debug /p:Platform="Any CPU" /m
if errorlevel 1 (
  echo.
  echo Build failed. Check the error messages above.
  echo Ensure .NET Framework 4.8 Developer Pack and NuGet package restore are installed.
  pause
  exit /b 1
)

echo.
echo Build completed. Expected output:
echo   %~dp0bin\Debug\ModMenuBuilder.exe
pause
