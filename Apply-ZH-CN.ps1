[CmdletBinding()]
param(
    [switch]$Restore,
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$menuRoot = Join-Path $rootPath "Scripts\ModMenu"
$backupRoot = Join-Path $rootPath ".persona5-zhcn-backup"
$manifestPath = Join-Path $backupRoot "manifest.json"

if (-not (Test-Path -LiteralPath $menuRoot -PathType Container)) {
    throw "找不到 Scripts\ModMenu。请把补丁解压到 Persona-5-Mod-Menu 仓库根目录（与 ModMenuBuilder.sln 同级）。"
}

$files = @(Get-ChildItem -LiteralPath $menuRoot -Filter "*.msg" -File -Recurse)
if ($files.Count -eq 0) { throw "Scripts\ModMenu 下没有 .msg 文件。" }

function Restore-OriginalFiles {
    if (-not (Test-Path -LiteralPath $backupRoot -PathType Container)) {
        throw "没有找到原始备份目录：$backupRoot"
    }

    $count = 0
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($rootPath.Length).TrimStart('\')
        $backup = Join-Path $backupRoot $relative
        if (Test-Path -LiteralPath $backup -PathType Leaf) {
            Copy-Item -LiteralPath $backup -Destination $file.FullName -Force
            $count++
        }
    }
    Write-Host "已恢复 $count 个原始 .msg 文件。" -ForegroundColor Green
}

if ($Restore) {
    Restore-OriginalFiles
    exit 0
}

# 支持从旧版 v0.1 补丁安全迁移：只要发现旧备份中的 .msg 文件，就先恢复原版。
# v0.1 没有写 manifest.json，因此这里不能只依赖 manifest 判断。
$existingBackups = @()
if (Test-Path -LiteralPath $backupRoot -PathType Container) {
    $existingBackups = @(Get-ChildItem -LiteralPath $backupRoot -Filter "*.msg" -File -Recurse -ErrorAction SilentlyContinue)
}
if ($existingBackups.Count -gt 0) {
    Restore-OriginalFiles
}

# 备份所有源文件（逐字节复制）。
foreach ($file in $files) {
    $relative = $file.FullName.Substring($rootPath.Length).TrimStart('\')
    $backup = Join-Path $backupRoot $relative
    if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        $dir = Split-Path -Parent $backup
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $backup
    }
}

# 下载并组装面具名称映射。两份数据只用于英文显示名称 -> 简中显示名称，不参与游戏 ID 映射。
$personaMap = @{}
$personaSources = @(
    "https://raw.githubusercontent.com/lraty-li/Persona-Modding/main/zh_hans_for_megaten-fusion-tool/name_pair_readable-game-p5r.json",
    "https://raw.githubusercontent.com/YUANYINGLONG-91/Persona-5-Roral-persona-fusion-planner-encyclopedia-/main/data/p5r_data.json"
)
foreach ($url in $personaSources) {
    $json = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    $data = $json | ConvertFrom-Json
    if ($url -like "*p5r_data.json") {
        foreach ($prop in $data.demons.PSObject.Properties) {
            if ($prop.Value.cn) { $personaMap[$prop.Name] = [string]$prop.Value.cn }
        }
    } else {
        foreach ($prop in $data.PSObject.Properties) {
            if ($prop.Value) { $personaMap[$prop.Name] = [string]$prop.Value }
        }
    }
}
# 对两个在数据源中没有统一键名的皇家版名称补齐。
$personaMap["Celestine"] = "塞莱斯汀"
$personaMap["M. Izanagi Picaro"] = "祸津伊邪那岐•贼神"

# 技能名称来自带 EN_NAME 的 P5R 技能 ID 表。重复英文键存在不同历史/废弃标签，
# 这些歧义项在下方明确指定为本菜单实际使用的简中名。
$skillUrl = "https://raw.githubusercontent.com/Ruimusume/P5R/main/Skill%20ID.txt"
$skillText = (Invoke-WebRequest -Uri $skillUrl -UseBasicParsing).Content
$skillMap = @{}
$skillConflicts = @{}
foreach ($line in ($skillText -split "`r?`n" | Select-Object -Skip 1)) {
    $parts = $line -split "`t", 5
    if ($parts.Count -lt 4) { continue }
    $cn = ($parts[1] -replace '^\|', '').Trim()
    $en = $parts[3].Trim()
    if ([string]::IsNullOrWhiteSpace($en) -or $en -eq "----------" -or
        [string]::IsNullOrWhiteSpace($cn) -or $cn -eq "空栏" -or $en -match '^NOT USED$') {
        continue
    }

    if ($skillMap.ContainsKey($en) -and $skillMap[$en] -cne $cn) {
        $skillConflicts[$en] = $true
        $skillMap.Remove($en)
    } elseif (-not $skillConflicts.ContainsKey($en)) {
        $skillMap[$en] = $cn
    }
}
$skillMap["Laevateinn"] = "胜利之剑"
$skillMap["Will of the People"] = "民意"
$skillMap["Soul Touch"] = "灵魂接触"
$skillMap["Coffee 1"] = "咖啡 1"
$skillMap["Coffee 2"] = "咖啡 2"
$skillMap["Curry 1"] = "咖喱 1"
$skillMap["Curry 2"] = "咖喱 2"

# 菜单常用项目名称。只匹配某一行第一个控制标记之前的完整显示字段，
# 绝不执行跨行或子字符串全局替换。
$labelMap = @{
    "Phone/Auto-Recover"="手机 / 自动恢复"; "Player"="玩家"; "Teleport"="传送"; "Call..."="调用……"
    "Calendar"="日历"; "Camera"="摄像机"; "Flags"="标志位"; "Spawn"="生成"; "About"="关于"; "Royal"="皇家版"
    "Set Joker Appearance"="设置主角外观"; "Set Joker Name"="设置主角姓名"; "Set Team Name"="设置队伍名称"
    "Add Money"="增加金钱"; "Personas"="人格面具"; "Skills"="技能"; "Items"="道具"; "Social Stats"="社交属性"
    "Confidants"="协助者"; "Set Security Level"="设置警戒等级"
    "Set Joker Model"="设置主角模型"; "Set Joker GAP"="设置主角 GAP"; "Toggle Bag"="切换手提包显示"
    "Toggle Morgana"="切换摩尔加纳显示"; "Toggle Umbrella"="切换雨伞显示"
    "Set Joker Field Model"="设置主角场景模型"; "Set Joker Model Scale"="设置主角模型大小"
    "Attach Item Model to Joker"="将道具模型附加到主角"; "Set Joker Field .GAP"="设置主角场景动画 .GAP"
    "Set Animation Test GAP"="设置动画测试 GAP"; "Set Test Animation Index"="设置测试动画序号"
    "Toggle Animation Loop"="切换动画循环"; "Set Animation Speed"="设置动画速度"; "Set Animation Time"="设置动画时长"
    "Playback Test Animation"="播放测试动画"; "Player Animation"="玩家动画"; "Player Model"="玩家模型"
    "Consumables"="消耗品"; "Accessories"="饰品"; "Key Items"="重要道具"; "Ranged Weapons"="远程武器"
    "Melee Weapons"="近战武器"; "Outfits"="服装"; "Armor"="防具"; "Materials"="素材"; "Skill Cards"="技能卡"
    "Knowledge"="知识"; "Charm"="魅力"; "Proficiency"="灵巧"; "Guts"="胆量"; "Kindness"="体贴"
    "Set Rank"="设置等级"; "Toggle Romance Route"="切换恋爱路线"; "Set Friendzone Id"="设置友情路线 ID"
    "Call Field"="调用场景"; "Call Event"="调用事件"; "Battle"="战斗"; "Field"="场景"; "Event"="事件"
    "Cut-in"="对话特写"; "Font Test"="字体测试"; "Sound Test"="音效测试"; "Chat"="聊天"; "Shop"="商店"
    "Timer"="计时器"; "Tutorial"="教程"; "Load Field"="加载场景"; "Load Field (Manual Input)"="加载场景（手动输入）"
    "Reload Current Field"="重新加载当前场景"; "Load Mementos Floor"="加载印象空间楼层"
    "Load Mementos Floor (Manual Input)"="加载印象空间楼层（手动输入）"
    "Select Item Type..."="选择道具类型……"; "Select Stat Type..."="选择属性类型……"
    "Regular Encounter"="普通战斗"; "Boss Encounter"="首领战"; "Event Battle"="剧情战斗"
    "Battle Type Select"="战斗类型选择"; "Palace Select"="宫殿选择"; "Castle"="城堡"; "Art Museum"="美术馆"
    "First World Bank"="银行"; "Pyramid"="金字塔"; "Space Station"="宇宙基地"; "Casino"="赌场"
    "Cruise Ship"="邮轮"; "Mementos Depths"="印象空间深层"; "Misc"="其他"
    "Reposition Camera"="调整摄像机位置"; "Adjust FOV/Zoom"="调整视野角度 / 缩放"; "Unlock Camera"="解除摄像机锁定"
    "Lock Camera"="锁定摄像机"; "Disable Camera Shake"="关闭摄像机震动"
    "HUD Flags"="HUD 标志位"; "Party Flags"="队伍标志位"; "Persona Flags"="人格面具标志位"
    "Room Flags"="房间标志位"; "Map Flags"="地图标志位"; "Toggle HUD"="切换 HUD 显示"
    "Invert HUD"="反转 HUD 颜色"; "Set Hideout"="设置集合地点"; "Enable Fast Travel"="启用快速旅行"
    "Enable Hangout Spots"="启用约会地点"; "Enable Going Out At Night"="启用夜间外出"
    "Enable Thieves Den"="启用怪盗团基地"; "Toggle Party Member Unlocked"="切换队友解锁状态"
    "Toggle Party Editing"="切换队伍编辑"; "Set Navigator"="设置导航角色"; "Toggle Party Follower"="切换队友跟随"
    "Toggle Baton Pass"="切换接力"; "Toggle Black Mask Akechi"="切换黑面具明智"
    "Toggle Yoshizawa's Name"="切换芳泽的姓名"; "Toggle Showtime"="切换 Show Time"
    "Toggle by ID"="按 ID 切换"; "Toggle by Category"="按类别切换"; "Randomize Flags"="随机化标志位"
    "Print Enabled Flags"="输出已启用标志位"; "Print Disabled Flags"="输出已禁用标志位"
    "Print Count Values"="输出计数值"; "Set Individual Flag"="设置单个标志位"
    "Set Start Range"="设置起始范围"; "Set End Range"="设置结束范围"
    "Enable All Flags in Range"="启用范围内全部标志位"; "Disable All Flags in Range"="禁用范围内全部标志位"
    "Flip All Flags in Range"="反转范围内全部标志位"; "Set Count Value"="设置计数值"
    "Add Persona"="添加人格面具"; "Delete Personas"="删除人格面具"; "Unlock Full Compendium"="解锁完整人格面具全书"
    "Evolve Persona"="人格面具进化"; "Add Skill (Alphabetical)"="添加技能（按字母排序）"
    "Add Skill (Manual Input)"="添加技能（手动输入）"; "Add Skill (Reserves)"="添加技能（预备列表）"
    "Add Persona (Alphabetical)"="添加人格面具（按字母排序）"
    "Add Persona (Reserves)"="添加人格面具（预备列表）"; "Add Persona (Manual Input)"="添加人格面具（手动输入）"
    "Add Skill"="添加技能"; "Set Next Day"="设置下一天"; "Go to Next Day"="前往下一天"; "Set Weather"="设置天气"
    "Loop Current Day"="循环当前日期"; "Weather Select"="天气选择"; "Sunny"="晴天"; "Rainy"="雨天"
    "Cloudy"="多云"; "Snow"="下雪"; "Rainy Season"="梅雨季"; "Typhoon Warning"="台风警报"
    "Sunny Pollen Warning"="晴天花粉预警"; "Cloudy Pollen Warning"="多云花粉预警"
    "Torrential Rain"="暴雨"; "January"="一月"; "February"="二月"; "March"="三月"; "April"="四月"
    "May"="五月"; "June"="六月"; "July"="七月"; "August"="八月"; "September"="九月"
    "October"="十月"; "November"="十一月"; "December"="十二月"; "Next"="下一页"; "Previous"="上一页"; "Exit"="退出"
    "Select a Month"="选择月份"; "Seconds"="秒数"; "Sample Text"="示例文本"; "Uppercase"="大写字母"
    "Lowercase"="小写字母"; "Symbols"="符号"; "All-in-One"="全部字符"
    "Automatic Particle Selection"="自动选择粒子效果"; "Manual Particle Selection"="手动选择粒子效果"
    "Set Params to Default"="恢复默认参数"; "Set Effect Size"="设置效果大小"; "Set Effect Speed"="设置效果速度"
    "Set Effect Position"="设置效果位置"; "Set Effect Translucency"="设置效果透明度"
    "NPC Model"="NPC 模型"; "Field Model"="场景模型"; "Particle Effect"="粒子效果"
    "Spawn NPCs"="生成 NPC"; "Spawn Field Models"="生成场景模型"; "Spawn Item Model"="生成道具模型"
    "Spawn Object Model"="生成物件模型"; "Animate Model"="播放模型动画"; "Set Model Scale"="设置模型大小"
    "Attach Item Model"="附加道具模型"
    "Royal Menu"="皇家版菜单"; "Go to Thieves Den"="前往怪盗团基地"
    "Change Character"="更换角色"; "View Videos"="查看影片"; "View Music"="查看音乐"; "View Gallery"="查看画廊"
    "Play Tycoon"="游玩大富豪"; "Select BGM"="选择背景音乐"; "Stop BGM"="停止背景音乐"; "Start BGM"="播放背景音乐"
    "Select Reserve Persona"="选择预备人格面具"; "Select Reserve Skill"="选择预备技能"
}

# 可安全整行替换的帮助文案。只匹配完整原始行，绝不做子字符串替换。
$wholeLineMap = @{
    "Add how many points?"="要增加多少点数？"
    "Invalid day selected."="所选日期无效。"
    "Please try again."="请重试。"
    "All Personas have been deleted."="已删除全部人格面具。"
    "Persona ID (3 Digits)"="人格面具 ID（3 位）"
    "Skill ID (4 Digits)"="技能 ID（4 位）"
    "Chat ID (4 Digits)"="聊天记录 ID（4 位）"
    "Shop ID (2 Digits)"="商店 ID（2 位）"
    "BGM ID (3 Digits)"="背景音乐 ID（3 位）"
    "Tutorial ID (3 Digits)"="教程 ID（3 位）"
    "Item ID (4 Digits)"="道具 ID（4 位）"
    "Item Amount (2 Digits)"="道具数量（2 位）"
    "Add Yen (7 Digits)"="增加日元（7 位）"
    "Security Level (3 Digits)"="警戒等级（3 位）"
    "Range Start (5 Digits)"="范围起点（5 位）"
    "Range End (5 Digits)"="范围终点（5 位）"
    "Flag ID (5 Digits)"="标志位 ID（5 位）"
    "Percentage (3 Digits)"="百分比（3 位）"
    "Count ID (3 Digits)"="计数 ID（3 位）"
    "Count Value (6 Digits)"="计数值（6 位）"
    "Particle ID (3 Digits)"="粒子 ID（3 位）"
    "Day (2 Digits)"="日期（2 位）"
    "Seconds"="秒数"
    "Tutorial Test"="教程测试"
    "Spawn Menu"="生成菜单"
    "Select Item Type..."="选择道具类型……"
    "Select Stat Type..."="选择属性类型……"
    "Title_FontTest"="Title_FontTest"
}

function Get-TagSignature([string[]]$lines) {
    $all = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        foreach ($m in [regex]::Matches($line, '\[[^\]\r\n]+\]')) { $all.Add($m.Value) }
    }
    return ,$all.ToArray()
}

$changedFiles = 0
$personaTranslated = 0
$skillTranslated = 0
$labelTranslated = 0
$unmappedPersona = New-Object System.Collections.Generic.HashSet[string]
$unmappedSkill = New-Object System.Collections.Generic.HashSet[string]

foreach ($file in $files) {
    $originalLines = [System.IO.File]::ReadAllLines($file.FullName)
    $newLines = New-Object System.Collections.Generic.List[string]
    $section = ""

    foreach ($line in $originalLines) {
        if ($line -match '^\[(msg|dlg)\s+') { $section = "" }
        if ($line -match '^\[sel\s+([^\]]+)\]') {
            $section = $Matches[1]
            $newLines.Add($line)
            continue
        }

        $newLine = $line
        if ($section -like "SelPersonaNameSet*") {
            if ($line -match '^(?<name>.*?)(?<suffix>\s+\(\d+\))?(?<tail>\[e\].*)$') {
                $name = $Matches["name"]
                if ($personaMap.ContainsKey($name)) {
                    # Only replace the visible name; preserve any numeric suffix and [e]/comment tail verbatim.
                    $newLine = $personaMap[$name] + $Matches["suffix"] + $Matches["tail"]
                    $personaTranslated++
                } elseif ($name -in @("Next","Previous","Exit") -and $labelMap.ContainsKey($name)) {
                    $newLine = $labelMap[$name] + $Matches["suffix"] + $Matches["tail"]
                } elseif ($name -and $name -notin @("Next","Previous","Exit")) {
                    [void]$unmappedPersona.Add($name)
                }
            }
        } elseif ($section -like "SelSkillNameSet*") {
            if ($line -match '^(?<name>.*?)(?<suffix>\s+\(\d+\))?(?<tail>\[e\].*)$') {
                $name = $Matches["name"]
                if ($skillMap.ContainsKey($name)) {
                    $newLine = $skillMap[$name] + $Matches["suffix"] + $Matches["tail"]
                    $skillTranslated++
                } elseif ($name -in @("Next","Previous","Exit") -and $labelMap.ContainsKey($name)) {
                    $newLine = $labelMap[$name] + $Matches["suffix"] + $Matches["tail"]
                } elseif ($name -and $name -notin @("Next","Previous","Exit")) {
                    [void]$unmappedSkill.Add($name)
                }
            }
        } else {
            if ($line -match '^(?<indent>\s*)(?<display>[^\[]*?)(?<tail>\[[^\]]+\].*)?$') {
                $display = $Matches["display"]
                if ($display -and $labelMap.ContainsKey($display.Trim())) {
                    $newLine = $Matches["indent"] + $labelMap[$display.Trim()] + $Matches["tail"]
                    $labelTranslated++
                } elseif ($wholeLineMap.ContainsKey($line.Trim())) {
                    $newLine = $line.Replace($line.Trim(), $wholeLineMap[$line.Trim()])
                    $labelTranslated++
                }
            } elseif ($wholeLineMap.ContainsKey($line.Trim())) {
                $newLine = $line.Replace($line.Trim(), $wholeLineMap[$line.Trim()])
                $labelTranslated++
            }
        }

        $newLines.Add($newLine)
    }

    $before = @($originalLines)
    $after = @($newLines.ToArray())
    if ($before.Count -ne $after.Count) { throw "行数发生变化，已停止：$($file.FullName)" }

    $beforeTags = Get-TagSignature $before
    $afterTags = Get-TagSignature $after
    if (($beforeTags -join "`n") -cne ($afterTags -join "`n")) {
        throw "脚本控制标记发生变化，已停止：$($file.FullName)"
    }

    if (($before -join "`n") -cne ($after -join "`n")) {
        $utf8Bom = New-Object System.Text.UTF8Encoding($true); [System.IO.File]::WriteAllText($file.FullName, ($after -join [char]10), $utf8Bom)
        $changedFiles++
    }
}

$manifest = [ordered]@{
    patchVersion = "0.2"
    game = "P5R_PC"
    language = "zh-CN"
    changedFiles = $changedFiles
    personaNameRowsTranslated = $personaTranslated
    skillNameRowsTranslated = $skillTranslated
    otherLabelsTranslated = $labelTranslated
    unmappedPersonaNames = @($unmappedPersona)
    unmappedSkillNames = @($unmappedSkill)
}
$manifestDir = Split-Path -Parent $manifestPath
New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "P5R PC 简体中文补丁 v0.2 已应用。" -ForegroundColor Green
Write-Host "扫描消息文件：$($files.Count)"
Write-Host "修改文件：$changedFiles"
Write-Host "面具名称映射行：$personaTranslated"
Write-Host "技能名称映射行：$skillTranslated"
Write-Host "其他菜单标签：$labelTranslated"
Write-Host "未映射面具名称：$($unmappedPersona.Count)"
Write-Host "未映射技能名称：$($unmappedSkill.Count)"
Write-Host "原始备份：$backupRoot"
Write-Host ""
Write-Host "注意：使用 [var] 动态读取游戏本体名称的预备列表，不在此 .msg 静态名称补丁的范围内。" -ForegroundColor Yellow
