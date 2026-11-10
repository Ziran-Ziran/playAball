param([string]$GodotExe = $env:GODOT_EXE)
$ErrorActionPreference = 'Stop'
if (-not $GodotExe) {
    $godotCommand = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($godotCommand) { $GodotExe = $godotCommand.Source }
}
if (-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw '请使用 -GodotExe 指定本机 Godot 4.7.1 可执行文件的实际绝对路径。'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $projectRoot '.local'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
foreach ($step in @(
    @{ Name = 'version'; Arguments = '--version' },
    @{ Name = 'import'; Arguments = '--headless --path "' + $projectRoot + '" --editor --import' },
    @{ Name = 'map'; Arguments = '--headless --path "' + $projectRoot + '" --script tools/project_map.gd -- --check' },
    @{ Name = 'roguelite'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_smoke.gd' },
    @{ Name = 'input_feedback'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_input_feedback.gd' },
    @{ Name = 'enemies'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_enemies.gd' },
    @{ Name = 'build'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_build.gd' },
    @{ Name = 'boss'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_boss.gd' },
    @{ Name = 'run'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_run.gd' },
    @{ Name = 'rice'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_rice.gd' },
    @{ Name = 'theme'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_theme.gd' },
    @{ Name = 'kill_rewards'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_kill_rewards.gd' },
    @{ Name = 'kill_run'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_kill_run.gd' },
    @{ Name = 'launch_rewards'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_launch_rewards.gd' },
    @{ Name = 'reward_effects'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_reward_effects.gd' },
    @{ Name = 'audio'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_audio.gd' },
    @{ Name = 'hud'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_hud.gd' },
    @{ Name = 'card_art'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_card_art.gd' },
    @{ Name = 'feedback_integration'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_feedback_integration.gd' },
    @{ Name = 'stage_flow'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_stage_flow.gd' },
    @{ Name = 'shop_events'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_shop_events.gd' },
    @{ Name = 'crowd'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_crowd.gd' },
    @{ Name = 'difficulty'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_difficulty.gd' },
    @{ Name = 'damage_contacts'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_damage_contacts.gd' },
    @{ Name = 'enemy_readability'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_enemy_readability.gd' },
    @{ Name = 'splitting'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_splitting.gd' },
    @{ Name = 'presentation_interface'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_presentation_interface.gd' },
    @{ Name = 'gameplay_lab'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_gameplay_lab.gd' },
    @{ Name = 'live_tuning'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_live_tuning.gd' },
    @{ Name = 'full_tuning'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_full_tuning.gd' },
    @{ Name = 'ui_integration'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/ui_integration.gd' },
    @{ Name = 'ocean_ui'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/ocean_ui.gd' },
    @{ Name = 'map_mechanisms'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_map_mechanisms.gd' },
    @{ Name = 'portals'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_portals.gd' },
    @{ Name = 'maps'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_maps.gd' },
    @{ Name = 'map_flow'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_map_flow.gd' },
    @{ Name = 'map_navigation'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_map_navigation.gd' },
    @{ Name = 'map_blueprints'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_map_blueprints.gd' },
    @{ Name = 'ball_art'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_ball_art.gd' },
    @{ Name = 'tactical_aim'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_tactical_aim.gd' },
    @{ Name = 'card_typography'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_card_typography.gd' },
    @{ Name = 'sea_ui'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_sea_ui.gd' },
    @{ Name = 'sea_ui_integration'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_sea_ui_integration.gd' },
    @{ Name = 'sea_ui_formal_game'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_sea_ui_formal_game.gd' },
    @{ Name = 'sea_ui_mouse'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_sea_ui_mouse.gd' },
    @{ Name = 'ball_animation'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_ball_animation.gd' },
    @{ Name = 'hero_smooth'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_hero_smooth.gd' },
    @{ Name = 'card_content_flow'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_card_content_flow.gd' },
    @{ Name = 'music'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/music_manager.gd' },
    @{ Name = 'menu_character'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/menu_character_integration.gd' },
    @{ Name = 'balance_metrics'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_balance_metrics.gd' },
    @{ Name = 'fish_view'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_fish_view.gd' },
    @{ Name = 'actor_views'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_actor_views.gd' },
    @{ Name = 'paddle_response'; Arguments = '--headless --fixed-fps 120 --path "' + $projectRoot + '" --script tests/roguelite_paddle_response.gd' },
    @{ Name = 'feature_acceptance'; Arguments = '--headless --fixed-fps 120 --path "' + $projectRoot + '" --script tests/roguelite_feature_acceptance.gd' },
    @{ Name = 'smoke'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/smoke.gd' }
)) {
    $outFile = Join-Path $logDirectory ($step.Name + '.out')
    $errFile = Join-Path $logDirectory ($step.Name + '.err')
    $godotProcess = Start-Process -FilePath $GodotExe -ArgumentList $step.Arguments -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $logText = (Get-Content -LiteralPath $outFile,$errFile -Raw) -join "`n"
    Write-Output $logText
    if ($godotProcess.ExitCode -ne 0 -or $logText -match '(?m)^(SCRIPT ERROR|ERROR):') {
        throw ($step.Name + ' 检查失败，请检查 .local 中的日志。')
    }
    if ($step.Name -eq 'version' -and $logText.Trim() -notmatch '^4\.7\.1\.stable') {
        throw '团队统一使用 Godot 4.7.1 stable。'
    }
    if ($step.Name -eq 'smoke' -and $logText -notmatch 'ALL CHECKS PASSED') {
        throw '未获得测试完成标志。'
    }
    if ($step.Name -eq 'roguelite' -and $logText -notmatch 'ROGUELITE CHECKS PASSED') {
        throw '未获得肉鸽测试完成标志。'
    }
    if ($step.Name -eq 'input_feedback' -and $logText -notmatch 'INPUT FEEDBACK CHECKS PASSED') {
        throw '未获得输入与反馈回归测试完成标志。'
    }
    $completionMarkers = @{ enemies = 'ENEMY CHECKS PASSED'; build = 'BUILD CHECKS PASSED'; boss = 'ROGUELITE BOSS: \d+ checks, 0 failures'; run = 'RUN CHECKS PASSED'; rice = 'RICE CHECKS PASSED'; theme = 'ROGUELITE THEME: \d+ checks, 0 failures' }
    $completionMarkers.kill_rewards = 'KILL REWARD CHECKS PASSED'
    $completionMarkers.card_art = 'CARD ART CHECKS: \d+ checks, 0 failures'
    $completionMarkers.kill_run = 'KILL RUN CHECKS PASSED'
    $completionMarkers.launch_rewards = 'ROGUELITE LAUNCH REWARDS: \d+ checks, 0 failures'
    $completionMarkers.reward_effects = 'REWARD EFFECTS CHECKS PASSED'
    $completionMarkers.audio = 'Audio checks: \d+, failures: 0'
    $completionMarkers.hud = 'HUD CHECKS PASSED'
    $completionMarkers.ocean_ui = 'OCEAN UI CHECKS: \d+ checks, 0 failures'
    $completionMarkers.feedback_integration = 'FEEDBACK INTEGRATION CHECKS PASSED'
    $completionMarkers.stage_flow = 'STAGE FLOW CHECKS PASSED'
    $completionMarkers.shop_events = 'SHOP EVENT CHECKS PASSED'
    $completionMarkers.crowd = 'CROWD CHECKS PASSED'
    $completionMarkers.difficulty = 'DIFFICULTY CHECKS PASSED'
    $completionMarkers.damage_contacts = 'DAMAGE CONTACT CHECKS PASSED'
    $completionMarkers.enemy_readability = 'ENEMY READABILITY CHECKS PASSED'
    $completionMarkers.splitting = 'SPLITTING CHECKS PASSED'
    $completionMarkers.presentation_interface = 'PRESENTATION INTERFACE CHECKS PASSED'
    $completionMarkers.gameplay_lab = 'GAMEPLAY LAB CHECKS PASSED'
    $completionMarkers.live_tuning = 'LIVE TUNING CHECKS PASSED'
    $completionMarkers.ui_integration = 'UI INTEGRATION CHECKS PASSED'
    $completionMarkers.full_tuning = 'FULL TUNING CHECKS PASSED'
    $completionMarkers.map_mechanisms = 'MAP MECHANISM CHECKS PASSED'
    $completionMarkers.portals = 'PORTAL CHECKS PASSED'
    $completionMarkers.maps = 'MAP CHECKS PASSED'
    $completionMarkers.map_flow = 'MAP FLOW CHECKS PASSED'
    $completionMarkers.map_navigation = 'MAP NAVIGATION CHECKS PASSED'
    $completionMarkers.map_blueprints = 'BLUEPRINT CHECKS: \d+ failures: 0'
    $completionMarkers.ball_art = 'BALL ART CHECKS: \d+ failures: 0'
    $completionMarkers.tactical_aim = 'tactical aim failures: 0'
    $completionMarkers.card_typography = 'TYPOGRAPHY: \d+ checks, 0 failures'
    $completionMarkers.sea_ui = 'SEA UI: \d+ checks, 0 failures'
    $completionMarkers.sea_ui_integration = 'ACTUAL UI: \d+ checks, 0 failures'
    $completionMarkers.sea_ui_formal_game = 'FORMAL GAME REGRESSION FAILURES 0'
    $completionMarkers.sea_ui_mouse = 'SEA MOUSE FAILURES 0'
    $completionMarkers.ball_animation = 'BALL ANIMATION INDEPENDENT \d+ checks failures 0'
    $completionMarkers.hero_smooth = 'SMOOTH HERO failures 0'
    $completionMarkers.card_content_flow = 'CONTENT FLOW 16 cards failures 0'
    $completionMarkers.music = 'MUSIC CHECKS \d+ failures 0'
    $completionMarkers.menu_character = 'MENU CHARACTER CHECKS: \d+ failures: 0'
    $completionMarkers.balance_metrics = 'BALANCE METRIC CHECKS PASSED'
    $completionMarkers.fish_view = 'FISH VIEW CHECKS PASSED'
    $completionMarkers.actor_views = 'ACTOR VIEW CHECKS PASSED'
    $completionMarkers.paddle_response = 'PADDLE RESPONSE CHECKS PASSED: \d+ failures: 0'
    $completionMarkers.feature_acceptance = 'FEATURE ACCEPTANCE CHECKS PASSED: \d+ failures: 0'
    if ($completionMarkers.ContainsKey($step.Name) -and $logText -notmatch $completionMarkers[$step.Name]) {
        throw ($step.Name + ' 未获得测试完成标志。')
    }
    if ($step.Name -eq 'map' -and $logText -notmatch 'PROJECT MAP CHECK PASSED') {
        throw '未获得目录检查完成标志。'
    }
}
Write-Output 'VERIFIED: import + map + all 53 behavior suites including generated ocean UI and reduced motion'
