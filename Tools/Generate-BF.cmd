@echo off
setlocal
chcp 65001 >nul
rem ============================================================
rem  一键产出 P5R Mod Menu 简体中文 .BF
rem  用法: Generate-BF.cmd "<AtlusScriptCompiler.exe 完整路径>" [输出目录]
rem  前置: ModMenuBuilder.sln 已编译; Apply-ZH-CN.ps1 已跑过
rem ============================================================
set "TOOLS=%~dp0"
set "ROOT=%~dp0.."
set "BUILDER=%ROOT%\bin\Debug\ModMenuBuilder.exe"
if not exist "%BUILDER%" set "BUILDER=%ROOT%\bin\Release\ModMenuBuilder.exe"
if not exist "%BUILDER%" (
  echo [ERROR] 找不到 ModMenuBuilder.exe，先编译 ModMenuBuilder.sln
  exit /b 1
)

if "%~1"=="" (
  echo 用法: Generate-BF.cmd "<AtlusScriptCompiler.exe 完整路径>" [输出目录]
  exit /b 1
)
rem call 嵌套时残留的引号要去掉，否则路径非法
set COMPILER=%~1
set OUT=%~2
set COMPILER=%COMPILER:"=%
set OUT=%OUT:"=%
if not exist "%COMPILER%" (
  echo [ERROR] 找不到编译器: %COMPILER%
  exit /b 1
)
if "%OUT%"=="" set "OUT=%ROOT%\out-zh-cn"

rem 官方 P5R_CHS.tsv 缺半角 ASCII，2025 版编译器会直接报错；必须换成本仓库的补丁表
set "CHARSETS=%~dp1Charsets"
if not exist "%CHARSETS%" (
  echo [ERROR] 编译器目录下没有 Charsets 子目录: %CHARSETS%
  exit /b 1
)
copy /Y "%TOOLS%charsets\P5R_CHS.tsv" "%CHARSETS%\P5R_CHS.tsv" >nul
if errorlevel 1 (
  echo [ERROR] 安装补丁字符表失败
  exit /b 1
)
echo [OK] 补丁字符表已安装: %CHARSETS%\P5R_CHS.tsv

if not exist "%OUT%" mkdir "%OUT%"
echo [..] 编译中 -> %OUT%
"%BUILDER%" -g P5R_PC -e P5R_CHS -c "%COMPILER%" -o "%OUT%" -r true
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [FAIL] builder 退出码 %RC%
  exit /b %RC%
)
echo [OK] 完成。部署: 把 %OUT% 下 5 个 .bf 覆盖到
echo      Reloaded-II\Mods\p5rpc.modmenu.beta\P5REssentials\CPK\MODMENU.CPK\ 的对应子目录
exit /b 0