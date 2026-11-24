# 简体中文 .BF 构建说明

这套脚本把 `Scripts/` 下已汉化的 `.msg` 编译成游戏可直接加载的 `.bf`（简体中文，P5R Steam 版 `schinese`）。

## 前置

1. `ModMenuBuilder.sln` 已编译出 `bin/Debug/ModMenuBuilder.exe`（或 `bin/Release/`）。
2. 已跑过 `Apply-ZH-CN.ps1`（把 `Scripts/` 里的英文换成简体中文）。
3. 有一份 **2025 年之后的** `AtlusScriptCompiler.exe`（含 `P5R_CHS` 编码，例如 `x-v1.0-0a74cf05` 那版）。
   2024 年及更早的版本不认 `P5R_CHS`，会静默回退 EFIGS 把汉字全变成 `?`。

## 一条命令

```bat
Tools\Generate-BF.cmd "D:\path\to\AtlusScriptCompiler.exe" "D:\path\to\out-zh-cn"
```

脚本会先把 `Tools/charsets/P5R_CHS.tsv` 装到编译器目录的 `Charsets/`，再调用 builder。
输出 5 个文件：

```
FIELD/ETC/at_dng.bf
FIELD/ETC/dungeon.bf
FIELD/ETC/field.bf
FIELD/INIT/fini_000_003.bf
SCRIPT/FIELD/fscr0150_002_100.bf
```

## 为什么需要自己带一份 P5R_CHS.tsv

官方 `P5R_CHS.tsv` 的前 128 格是 `*` 占位，**没有半角 ASCII**。
2025 版编译器严格校验字符，遇到 `.`、`(`、字母就直接抛
`Encoding P5R_CHS does not support character: .`，产物 0 字节。
`Tools/charsets/P5R_CHS.tsv` 已把 `P5R_Japanese.tsv` 的低区（0x00–0x7F）并入，`Tools/Generate-BF.cmd` 每次编译前自动覆盖安装。

## 部署

覆盖到 Reloaded-II 的 Mod Menu 目录（先备份原文件）：

```
Reloaded-II/Mods/p5rpc.modmenu.beta/P5REssentials/CPK/MODMENU.CPK/<同上相对路径>
```

## 回滚

`Apply-ZH-CN.ps1 -Restore` 还原 `.msg`；
把 `Reloaded-II/Mods/p5rpc.modmenu.beta/P5REssentials/.backup-en-<时间戳>/` 里的 5 个 `.bf` 覆盖回 `CPK/MODMENU.CPK/` 即可回到英文版。

## 已知限制

- `Assets/Royal/field/*.pac` 里的原版 `.bf` 是**英文版**（作者提供）。
  `P5R Steam 版 CPK 内的文件是加密的`，无法直接取出 schinese 原版作基底，
  所以原版 bf 自带的 2 处日文残留（`警戒度が上がっちまったな(仮)` 之类）会以怪字符显示。
  这与本次汉化无关（英文版游戏里同样异常）。
- 官方表还缺 `（` `）` `？` `•` `鳳` 五个字符，builder 里的 `NormalizeCharset()`
  会在编译前自动换成 `(` `)` `?` `・` `凤`（不动 `Scripts/` 源文件）。