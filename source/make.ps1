Param([string]$Configuration, [switch]$EnableActivator, [switch]$EnableSplashScreen, [switch]$EnableUpdateScript)

$Configurations = @("Release", "Distribution")
if ($Configuration.Length -eq 0) {
    $Configuration = "Release"
} 

if (!$Configurations.Contains($Configuration)) {
    Write-Output "[ERROR] 指定されたコンフィギュレーション $Configuration は存在しません"
    EndMake
}

# 現在のディレクトリを取得する
$startdir = Get-Location
$cd = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $cd

Start-Transcript make.log | Out-Null

function EndMake() {
    Stop-Transcript | Out-Null
    ''
    Read-Host "終了するには何かキーを押してください..."
    exit
}

$msbuild = $null
$msbuild_exe = @(
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe", 
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe", 
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe")
foreach ($m in $msbuild_exe) {
    if (Test-Path $m) {
        $msbuild = $m
        break
    }
}
if ($null -eq $msbuild) {
    Write-Output ("MSBuild.exe が見つかりませんでした。Visual Studio または Build Tools をインストールしてください。")
    EndMake
}

$7zPath = ".\tools\7za.exe"
if (Test-Path $7zPath) {
    if ((Get-Item -Path $7zPath).Length -lt 10000) {
        Write-Output ($7zPath + " が壊れている可能性があります。")
        Write-Output ("GitHubからソースコードをzipファイルでダウンロードした場合、正しくビルドできません。")
        Write-Output ("git コマンドを使用してレポジトリ全体をダウンロードして下さい。")
        EndMake
    }
    $7z = Get-Item -Path $7zPath
}
else {
    Write-Output ($7zPath + " が見つかりませんでした。")
    EndMake
}

$sln = Get-Item *.sln
$archives = Get-Item .\archives\
$archiveTarget = Join-Path $archives $Configuration
if(!(Test-Path $archiveTarget)) {
    New-Item -Path $archiveTarget -ItemType Directory | Out-Null
}

# Version
$versionContent = $(Get-Content "@MasterVersion.txt").Trim("\r").Trim("\n")

# AssemblyInfo.cs 向けのバージョン文字列を生成する
[Collections.Generic.List[String]]$versionParts = $versionContent.Replace("v", "").Split(".")
$versionParts.Insert(2, "0")
$version = [string]::Join(".", $versionParts)
$masterVersionCS = "MasterVersion.cs"
$masterVersionTemp = $masterVersionCS + ".tmp"

# バージョン表記
$versionShort = $versionContent

Write-Output "***"
Write-Output ("*** ACT.Hojoring " + $versionShort + " のビルドを開始します")
Write-Output "***"
Write-Output ""

# Param から DefineConstants を作成
$DefineConstants = ""
$DefineConstantsArray = @("TRACE")
if ($EnableActivator) {
    $DefineConstantsArray += "ENABLE_ACTIVATOR"
    Write-Output "[Warning] ACT.Hojoring.Activator を有効にするよう選択されています"
}
if ($EnableSplashScreen) {
    $DefineConstantsArray += "ENABLE_SPLASH_SCREEN"
    Write-Output "[Warning] Splash Screen を有効にするよう選択されています"
}
if ($EnableSplashScreen) {
    $DefineConstantsArray += "ENABLE_UPDATE_SCRIPT"
    Write-Output "[Warning] Update Script を有効にするよう選択されています"
}
if ($DefineConstantsArray.Count -gt 0) {
    $DefineConstants = $DefineConstantsArray -join ","
}

# MasterVersion.cs のバージョンを置換する
[System.IO.File]::WriteAllLines($masterVersionTemp, ((Get-Content $masterVersionCS) | ForEach-Object { $_ -replace "#MASTER_VERSION#", $version }), (New-Object System.Text.UTF8Encoding $False))

# MasterVersion.cs.tmp をコピーする
Move-Item -Force $masterVersionTemp ".\ACT.Hojoring.Common\Version.cs"

if (Test-Path .\ACT.Hojoring\bin\Release) {
    Remove-Item -Path .\ACT.Hojoring\bin\Release\* -Force -Recurse
    Remove-Item -Path .\ACT.Hojoring\bin\Release -Force -Recurse
}

Write-Output('ACT.Hojoringを ' + $Configuration + ' でビルドしています...')
Start-Sleep -m 500
& $msbuild $sln /nologo /v:minimal /p:Configuration=$Configuration /t:Clean | Write-Output
& $msbuild $sln /nologo /v:minimal /p:Configuration=$Configuration /t:Restore | Write-Output
& $msbuild $sln /nologo /v:minimal /p:Configuration=$Configuration /t:Build /p:DefineConstants=`"$DefineConstants`" | Write-Output
Start-Sleep -m 500

if (Test-Path .\ACT.Hojoring\bin\Release) {
    Set-Location .\ACT.Hojoring\bin\Release

    '不要なロケールを削除しています...'
    $locales = @(
        "de",
        "en",
        "es",
        "fr",
        "it",
        "ja",
        "ko",
        "ja",
        "ru",
        "zh-Hans",
        "zh-Hant",
        "hu",
        "pt-BR",
        "ro",
        "sv"
    )

    foreach ($locale in $locales) {
        if (Test-Path $locale) {
            Remove-Item -Force -Recurse $locale
            Write-Output("  " + $locale)
        }
    }

    '不要なファイルを削除しています...'
    Remove-Item -Force *.pdb
    Remove-Item -Force *.xml
    Remove-Item -Force *.exe.config
    if (!$EnableUpdateScript) {
        Remove-Item -Force "update_hojoring.ps1"
    }

    '外部参照用DLLを移動しています...'
    New-Item -ItemType Directory "bin" | Out-Null

    Rename-Item Yukkuri _yukkuri
    Rename-Item OpenJTalk _openJTalk
    Rename-Item _yukkuri yukkuri
    Rename-Item _openJTalk openJTalk
    Move-Item yukkuri .\bin\
    Move-Item openJTalk .\bin\
    Move-Item lib .\bin\
    Move-Item tools .\bin\

    if ($Configuration -eq "Distribution") {
        'ATDExtractorをコピーしています...'
        New-Item -ItemType Directory -Path "bin\tools\ATDExtractor" | Out-Null
        Copy-Item -Path "..\..\..\ACT.Hojoring.ATDExtractor\bin\Release\ATDExtractor.exe" -Destination "bin\tools\ATDExtractor\" -Force
     }
  
    '配布ファイルをアーカイブしています...'
    $archive = "ACT.Hojoring-" + $versionShort
    $archiveZip = $archive + ".zip"
    $archive7z = $archive + ".7z"

    if (Test-Path $archiveZip) {
        Remove-Item $archiveZip -Force
    }
  
    if (Test-Path $archive7z) {
        Remove-Item $archive7z -Force
    }

    & $7z a -r "-xr!*.zip" "-xr!*.7z" "-xr!*.pdb" "-xr!archives\" $archive7z *
    Move-Item $archive7z $archiveTarget -Force

    <#
    & $7z a -r "-xr!*.zip" "-xr!*.7z" "-xr!*.pdb" "-xr!archives\" $archiveZip *
    Move-Item $archiveZip $archiveTarget -Force
    #>

    Set-Location $startdir
}

Write-Output ""
Write-Output "***"
Write-Output ("*** ACT.Hojoring " + $versionShort + " のビルドが完了しました")
Write-Output "***"

EndMake
