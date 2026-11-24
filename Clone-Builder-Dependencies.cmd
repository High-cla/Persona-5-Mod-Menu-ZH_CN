@echo off
setlocal
where git >nul 2>&1
if errorlevel 1 (
  echo ERROR: Git was not found. Install Git for Windows first.
  pause
  exit /b 1
)

set "REPO=%~dp0"
for %%I in ("%REPO%..") do set "WORK=%%~fI"

if not exist "%WORK%\AtlusFileSystemLibrary\.git" (
  git clone https://github.com/tge-was-taken/AtlusFileSystemLibrary.git "%WORK%\AtlusFileSystemLibrary" || goto :fail
)
if not exist "%WORK%\SimpleCommandLine\.git" (
  git clone https://github.com/tge-was-taken/SimpleCommandLine.git "%WORK%\SimpleCommandLine" || goto :fail
)
if not exist "%WORK%\ShrineFox.IO\.git" (
  git clone https://github.com/ShrineFox/ShrineFox.IO.git "%WORK%\ShrineFox.IO" || goto :fail
)

echo.
echo Dependencies ready:
echo   %WORK%\AtlusFileSystemLibrary
echo   %WORK%\SimpleCommandLine
echo   %WORK%\ShrineFox.IO
echo.
echo Open ModMenuBuilder.sln in Visual Studio and restore NuGet packages.
pause
exit /b 0

:fail
echo Failed to clone one or more dependency repositories.
pause
exit /b 1
