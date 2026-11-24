@echo off
setlocal
set "BUILDER=%~dp0bin\Debug\ModMenuBuilder.exe"
if not exist "%BUILDER%" set "BUILDER=%~dp0bin\Release\ModMenuBuilder.exe"
if not exist "%BUILDER%" (
  echo ERROR: ModMenuBuilder.exe was not found.
  echo First run Clone-Builder-Dependencies.cmd and build ModMenuBuilder.sln.
  pause
  exit /b 1
)

set /p "COMPILER=Full path to AtlusScriptCompiler.exe: "
if not exist "%COMPILER%" (
  echo ERROR: AtlusScriptCompiler.exe not found.
  pause
  exit /b 1
)

set /p "OUTPUT=Full path to P5R PC Mod Menu output folder: "
if "%OUTPUT%"=="" (
  echo ERROR: Output path is empty.
  pause
  exit /b 1
)
if not exist "%OUTPUT%" mkdir "%OUTPUT%"

echo.
echo Build target: P5R_PC
echo Encoding: P5R_CHINESE
echo Reindex messages: enabled
echo Output: %OUTPUT%
echo.
"%BUILDER%" -g P5R_PC -e P5R_CHINESE -c "%COMPILER%" -o "%OUTPUT%" -r true
set "RESULT=%ERRORLEVEL%"

echo.
if not "%RESULT%"=="0" (
  echo Builder returned exit code %RESULT%.
  echo Check the ModMenuBuilder log and AtlusScriptCompiler output.
) else (
  echo The builder process finished. Verify .BF files in the output folder and test in-game.
)
pause
exit /b %RESULT%
