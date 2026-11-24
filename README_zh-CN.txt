Persona 5 Royal PC - Mod Menu 简体中文源码补丁 v0.2
===================================================

目标
----
游戏版本：Persona 5 Royal PC（P5R_PC）
语言：简体中文
中文编码：P5R_CHINESE
补丁类型：源码 .msg 汉化 + ModMenuBuilder 源码构建辅助脚本
本包不包含已经编译好的 .BF/.BMD 文件，也不包含游戏字体或游戏资源。

重要：不要只下载 ModMenuBuilder.sln
-------------------------------------
.sln 只是 Visual Studio 解决方案入口，不包含完整源码或依赖。
请先下载完整 Persona-5-Mod-Menu 仓库（ZIP 或 git clone），目录中应包含：
- ModMenuBuilder.sln
- ModMenuBuilder.csproj
- Builder\
- Scripts\
- Assets\
- packages.config

构建器依赖
----------
上游 .csproj 引用了三个相邻目录的项目：
- ../AtlusFileSystemLibrary/Source/AtlusFileSystemLibrary/AtlusFileSystemLibrary.csproj
- ../SimpleCommandLine/Source/SimpleCommandLine/SimpleCommandLine.csproj
- ../ShrineFox.IO/ShrineFox.IO.csproj

推荐目录结构：
work\
  Persona-5-Mod-Menu\
  AtlusFileSystemLibrary\
  SimpleCommandLine\
  ShrineFox.IO\

操作步骤
--------
1. 安装 Git for Windows。
2. 下载完整仓库并解压为 work\Persona-5-Mod-Menu。
3. 将本补丁包的文件复制到 Persona-5-Mod-Menu 根目录（与 .sln 同级）。
4. 双击 Clone-Builder-Dependencies.cmd，自动克隆三个依赖仓库。
5. 构建环境（三选一；本仓库实测走第 3 条，无需 Visual Studio）：
   - Visual Studio 2022 + “.NET 桌面开发” + .NET Framework 4.8 Developer Pack；
   - 仅 Visual Studio Build Tools 的 MSBuild + .NET Framework Reference Assemblies；
   - 无 VS：装 dotnet-sdk，取 NuGet 包 microsoft.netframework.referenceassemblies.net48 的 build/.NETFramework/v4.8
     树放到自建根（例如 C:\Users\<you>\.netfx-refs\.NETFramework\v4.8）。
6. 还原并生成（仓库根目录执行）：
   dotnet msbuild ModMenuBuilder.sln -t:Restore -p:RestorePackagesConfig=true -p:RuntimeIdentifiers=win -p:TargetFrameworkRootPath=C:/Users/<you>/.netfx-refs/ -v:m
   "<MSBuild.exe 完整路径>" ModMenuBuilder.sln -t:Build -p:Configuration=Debug "-p:Platform=Any CPU" -p:RuntimeIdentifiers=win -p:TargetFrameworkRootPath=C:/Users/<you>/.netfx-refs/ -m -v:m
   必须带 -p:RuntimeIdentifiers=win，否则 ShrineFox.IO 报 "doesn't list 'win' as a RuntimeIdentifier"。
   Git Bash / MSYS 下参数要写 -p: 与 -t:，写 /p: 与 /t: 会被 MSYS 改写成路径。
7. 在仓库根目录打开 PowerShell，执行：
   Set-ExecutionPolicy -Scope Process Bypass
   .\Apply-ZH-CN.ps1
   脚本会联网获取 P5R 简中面具/技能名称对照表，修改 Scripts\ModMenu 下的 .msg 文件。
8. 用 Tools\Generate-BF.cmd 编译（不要用 2024 版编译器）：
   Tools\Generate-BF.cmd "D:\path\to\AtlusScriptCompiler.exe" "D:\path\to\out-zh-cn"
   编译器必须是 2025 年之后、含 P5R_CHS 编码的版本（如 v1.0-0a74cf05）；
   2024 及更早版本不认 P5R_CHS，会静默回退 EFIGS 把汉字全变成 "?"。
   脚本会自动把 Tools\charsets\P5R_CHS.tsv 装进编译器的 Charsets 目录。
9. 把输出的 5 个 .bf 覆盖到 Reloaded-II\Mods\p5rpc.modmenu.beta\P5REssentials\CPK\MODMENU.CPK\：
   FIELD/ETC/at_dng.bf、FIELD/ETC/dungeon.bf、FIELD/ETC/field.bf、FIELD/INIT/fini_000_003.bf、SCRIPT/FIELD/fscr0150_002_100.bf
   然后在 Reloaded-II 启用 Mod Menu（游戏语言需为简体中文 schinese）。

为什么面具/技能名不会错位？
--------------------------
PersonaSelect.flow 和 SkillSelect.flow 的索引函数用“菜单块编号 + 所选行号”返回内部 Persona/Skill ID，而不是根据英文显示名称查询。
补丁仅将相同行的显示名称替换为简体中文，保留：
- 每个 [sel] 菜单块的顺序和数量
- 每个项目的原始行位置
- 名称后的数字后缀（例如 (201)）
- [e]、[ref]、[var]、[n]、[clr] 等控制标记
- Next / Previous / Exit 分页/退出条目
- 所有 .flow 文件（不修改）
脚本会逐文件核对行数与全部方括号控制标记序列；任何不一致都会中止写入。
因此不会因名称本身而改变 .flow 选择索引。不要手动重排或增删面具/技能列表。

汉化范围与限制
--------------
- 静态人格面具选择列表：253 个不同名称。
- 静态技能选择列表：730 个不同名称（不同列表行可能重复）。
- 主菜单及常见子菜单标签：按完整字段逐行匹配翻译。
- Persona / Skill 选择列表按原顺序、原 ID 后缀逐条替换。
- 预备列表（Reserve Personas / Reserve Skills）使用 [var] 从游戏本体文本/数据动态读取名称；这些名称不在本补丁 .msg 静态表内。英文游戏资源中的动态名称可能仍显示英文，需要另行汉化本体语言资源。
- 少数内部调试/未使用条目或原始数据不存在可靠译名时，保持原文。
- [A-Z] 首字母分类仍保留英文字母，因为 .flow 用这些字母序号映射到对应菜单块；如果改成拼音首字母，必须同时重写并验证 .flow 的 switch 映射。

编码说明
--------
实测结论（P5R Steam 版，Steam 语言 schinese）：
  - 命令行必须用 -e P5R_CHS，不是 P5R_CHINESE：
      -g P5R_PC -e P5R_CHS -r true
  - P5R_CHINESE 是繁体表（13828 字），不含“历设环当选择无风报…”等 335 个简体字，编译器会把汉字静默写成 "?"。
  - P5R_CHS 是简体表（7473 字），覆盖本补丁 1088 个非 ASCII 字符中的 1086 个，仅缺 "•" 与 "鳳"。
  - 官方 P5R_CHS.tsv 前 128 格是 * 占位、没有半角 ASCII，2025 版编译器直接报 "does not support character: ."；
    Tools\charsets\P5R_CHS.tsv 已并入 P5R_Japanese 的低区（0x00-0x7F）。
  - 仍有 5 个字符不在表内（（ ） ？ • 鳳），builder 的 NormalizeCharset() 在编译前自动替换为 ( ) ? ・ 凤，不改 Scripts 源文件。
  - 不要用 P5R_EFIGS 编译中文文本。

备份与恢复
----------
首次执行 Apply-ZH-CN.ps1 时，会把原始 .msg 文件逐字节备份到：
  .persona5-zhcn-backup\
如已存在 v0.1 补丁备份，v0.2 会先从该备份恢复原文件，再使用更严格的逐行方法重新汉化。
恢复英文：
  .\Apply-ZH-CN.ps1 -Restore

已知实测结果
------------
- 已实测：无 Visual Studio 环境下，用 dotnet msbuild + MSBuild.exe + 自建 reference assemblies 可编译 ModMenuBuilder.sln（0 error / 85 warning）。
- 已实测：-e P5R_CHS + 补丁字符表可产出 5 个 .bf；反编译回读 1427 行中文，菜单条目（手机 / 自动恢复、玩家、传送…）逐条正确；两次独立构建 md5 完全相同。
- 已实测：产物已覆盖到 Reloaded-II\Mods\p5rpc.modmenu.beta\P5REssentials\CPK\MODMENU.CPK\，覆盖后游戏内效果尚待实机确认。
- 已知限制：Assets 里的原版 PAC 是英文版 .bf，而 P5R Steam 版 CPK 内文件是加密的（FLW0 之后为随机字节），无法取出 schinese 原版作基底；
  因此原版 .bf 自带的日文残留条目（如“警戒度が上がっちまったな(仮)”）会以怪字符显示。
- 上游 README 当前将 PC 版本说明为预览/未完成状态；请在备份原 Mod 后测试。

上游与对照数据来源
------------------
Mod Menu:
https://github.com/ShrineFox/Persona-5-Mod-Menu

AtlusMSGEditor (P5R_CHINESE 编码说明):
https://github.com/ShrineFox/AtlusMSGEditor

P5R 简中面具数据:
https://github.com/YUANYINGLONG-91/Persona-5-Roral-persona-fusion-planner-encyclopedia-/blob/main/data/p5r_data.json
https://github.com/lraty-li/Persona-Modding/blob/main/zh_hans_for_megaten-fusion-tool/name_pair_readable-game-p5r.json

P5R 技能 ID 中英对照:
https://github.com/Ruimusume/P5R/blob/main/Skill%20ID.txt
