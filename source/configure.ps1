Param()

$startdir = Get-Location
$cd = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $cd

Start-Transcript configure.log | Out-Null

function EndConfigure() {
    Stop-Transcript | Out-Null
    ''
    Read-Host "終了するには何かキーを押してください..."
    exit
}


$7zPath = ".\tools\7za.exe"
$msSdkDir = "C:\Program Files (x86)\Microsoft SDKs"
$actURL = "https://advancedcombattracker.com/includes/page-download.php?id=57"
$cevioURL = "http://storage.cevio.jp/product/CeVIO_Creative_Studio_Setup_(6.1.53.0).msi"

Write-Output ("*** Configure start.")
Write-Output ""
Write-Output ""

Write-Output ("環境を確認しています...")
Write-Output ""


# Test 7zip
if (!(Test-Path $7zPath)) {
    Write-Output ("エラー: " + $7zPath + " が見つかりませんでした。")
    EndConfigure
}
$7z = Get-Item -Path $7zPath
if ($7z.Length -lt 10000) {
    Write-Output ("エラー: " + $7zPath + " が壊れている可能性があります。")
    Write-Output ("GitHubからソースコードをzipファイルでダウンロードした場合、正しくビルドできません。")
    Write-Output ("git コマンドを使用してレポジトリ全体をダウンロードして下さい。")
    EndConfigure
}
Write-Output("7zip: " + $7z.FullName)


# Test ildasm
if (!(Test-Path $msSdkDir)) {
    Write-Output ("エラー: " + $msSdkDir + " が見つかりませんでした。")
    Write-Output ("Microsoft Windows 10 SDK をインストールして下さい。")
    EndConfigure
}
$ildasm_exes = Get-ChildItem "C:\Program Files (x86)\Microsoft SDKs" -Recurse -Filter "ildasm.exe" | Sort-Object -Property FullName -Descending
if($ildasm_exes.Length -eq 0) {
    Write-Output ("エラー: ildasm.exe が見つかりませんでした。")
    Write-Output ("Microsoft Windows 10 SDK をインストールして下さい。")
    EndConfigure
}
$ildasm = Get-Item $ildasm_exes[0].FullName
Write-Output("ildasm: " + $ildasm.FullName)


Write-Output ("必要なファイルを集めています...")
Write-Output ""

$TempFolder = New-TemporaryFile | ForEach-Object { Remove-Item -Path $_; New-Item -Path $_ -ItemType Directory }

# Advanced Combat Tracker
if (!(Test-Path ".\ThirdParty\Advanced Combat Tracker.exe")) {
    Write-Output ""
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "Advanced Combat Tracker をダウンロードしています..."
    Write-Output ($actURL)
    $actFile = Join-Path $TempFolder "ACT.zip"
    Invoke-WebRequest -Uri $actURL -OutFile $actFile
    & $7z e -y -o".\ThirdParty\" -ir!"Advanced Combat Tracker.exe" $actFile
    Write-Output "完了."
}

# FFXIV_ACT_Plugin SDK
if ((!(Test-Path ".\ThirdParty\SDK\FFXIV_ACT_Plugin.Common.dll")) -or
    (!(Test-Path ".\ThirdParty\SDK\FFXIV_ACT_Plugin.LogFile.dll")) -or
    (!(Test-Path ".\ThirdParty\SDK\FFXIV_ACT_Plugin.Resource.dll"))) {
    Write-Output ""
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "FFXIV_ACT_Plugin SDK をダウンロードしています..."

    $ffxivActPluginRepo = "ravahn/FFXIV_ACT_Plugin"
    $ffxivActPluginDllFileName = "FFXIV_ACT_Plugin.dll"
    $ffxivActPluginLiFileName = "FFXIV_ACT_Plugin.li"
    $ffxivActPluginLatest = "https://api.github.com/repos/$ffxivActPluginRepo/releases/latest"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ffxivActPlugin_download_url = (Invoke-WebRequest -Uri $ffxivActPluginLatest -UseBasicParsing | ConvertFrom-Json)[0].assets[0].browser_download_url
    if ($ffxivActPlugin_download_url.Length -gt 1) {
        $ffxivActPluginArchiveFileName = [System.IO.Path]::GetFileName($ffxivActPlugin_download_url)
        $ffxivActPluginArchiveFile = Join-Path $TempFolder $ffxivActPluginArchiveFileName
        Invoke-WebRequest -Uri $ffxivActPlugin_download_url -OutFile $ffxivActPluginArchiveFile
        $ffxivActPluginExtractDir = Join-Path $TempFolder "FFXIVActPluginExtract"
        & $7z e -y -o"$ffxivActPluginExtractDir" -ir!"$ffxivActPluginDllFileName" $ffxivActPluginArchiveFile
        $ffxivActPluginDllFile = Join-Path $ffxivActPluginExtractDir $ffxivActPluginDllFileName
        $ffxivActPluginLiFile = Join-Path $ffxivActPluginExtractDir $ffxivActPluginLiFileName
        if(!(Test-Path $ffxivActPluginDllFile)) {
            Write-Output ("エラー: 最新リリースの取得に失敗しました")
            EndConfigure
        }
        & $ildasm $ffxivActPluginDllFile /out="$ffxivActPluginLiFile"

        $fileCosturaDecompress = "./ACT.Hojoring.ATDExtractor/CosturaDecompress.cs"
        $srcCosturaDecompress = Get-Content $fileCosturaDecompress | Out-String
        Add-Type -TypeDefinition $srcCosturaDecompress -Language CSharp

        [ACT.Hojoring.ATDExtractor.CosturaDecompress]::DecompressFile((Join-Path $ffxivActPluginExtractDir "costura.ffxiv_act_plugin.common.dll.compressed"), (Join-Path $cd ".\Thirdparty\SDK\FFXIV_ACT_Plugin.Common.dll"))
        [ACT.Hojoring.ATDExtractor.CosturaDecompress]::DecompressFile((Join-Path $ffxivActPluginExtractDir "costura.ffxiv_act_plugin.logfile.dll.compressed"), (Join-Path $cd ".\Thirdparty\SDK\FFXIV_ACT_Plugin.LogFile.dll"))
        [ACT.Hojoring.ATDExtractor.CosturaDecompress]::DecompressFile((Join-Path $ffxivActPluginExtractDir "costura.ffxiv_act_plugin.resource.dll.compressed"), (Join-Path $cd ".\Thirdparty\SDK\FFXIV_ACT_Plugin.Resource.dll"))
    }
    else {
        Write-Output ("エラー: 最新リリースの取得に失敗しました")
        EndConfigure
    }
    Write-Output "完了."
}

# Sharlayan
if (!(Test-Path ".\ThirdParty\Sharlayan.dll")){
    Write-Output ""
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "qitana/sharlayan をダウンロードしています..."

    $repo = "qitana/sharlayan"
    $latest = "https://api.github.com/repos/$repo/releases/latest"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $download_url = (Invoke-WebRequest -Uri $latest -UseBasicParsing | ConvertFrom-Json)[0].assets[0].browser_download_url
    if ($download_url.Length -gt 1) {
        $sharlayanArchiveFileName = [System.IO.Path]::GetFileName($download_url)
        $sharlayanArchiveFile = Join-Path $TempFolder $sharlayanArchiveFileName
        Invoke-WebRequest -Uri $download_url -OutFile $sharlayanArchiveFile
        & $7z e -y -o".\ThirdParty\" -ir!"Sharlayan.dll" $sharlayanArchiveFile
        Write-Output "完了."
    }
    else {
        Write-Output ("エラー: 最新リリースの取得に失敗しました")
        EndConfigure
    }
}

# CeVIO Creative Studio 6
if (!(Test-Path ".\ThirdParty\CeVIO.Talk.RemoteService.DLL")) {
    Write-Output ""
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "CeVIO Creative Studio 6 をダウンロードしています..."
    Write-Output ($cevioURL)
    $cevioMsiFileName = [System.IO.Path]::GetFileName($cevioURL)
    $cevioMsiFile = Join-Path $TempFolder $cevioMsiFileName
    $cevioExtractDir = Join-Path $TempFolder "CeVIO_Creative_Studio_Extract"
    Invoke-WebRequest -Uri $cevioURL -OutFile $cevioMsiFile
    New-Item -Path $cevioExtractDir -ItemType Directory | Out-Null
    Write-Output ""
    Write-Output ($cevioMsiFileName + "を展開しています...")
    $msiExecArgs = '/a', ('"' + $cevioMsiFile + '"'), ('targetdir="' + $cevioExtractDir + '"'), '/qn'
    $msiexec = Start-Process -PassThru -Wait msiexec -ArgumentList $msiExecArgs

    if ($msiexec.ExitCode -eq 0) {
        $cevioDLL = Join-Path $cevioExtractDir "CeVIO.Talk.RemoteService.DLL"
        Write-Output ("必要なファイルをコピーしています...")
        Copy-Item $cevioDLL ".\ThirdParty\" -Force
        Write-Output "完了."
    }
    else {
        Write-Output ("エラー: " + $cevioMsiFileName + " の展開に失敗しました")
        EndConfigure
    }
}

# anoyetta/ACT.Hojoring AquesTalk
if (!(Test-Path ".\ACT.TTSYukkuri\ACT.TTSYukkuri\Costura32\AquesTalkDriver.dll") -or 
    !(Test-Path ".\ACT.TTSYukkuri\ACT.TTSYukkuri\Costura64\AquesTalkDriver.dll")) {
    Write-Output ""
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "anoyetta/ACT.Hojoring をダウンロードしています..."

    $hojoringRepo = "anoyetta/ACT.Hojoring"
    $ttsYukkuriDllFileName = "ACT.TTSYukkuri.dll"
    $ttsYukkuriLiFileName = "ACT.TTSYukkuri.li"
    $hojoringLatest = "https://api.github.com/repos/$hojoringRepo/releases"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $hojoring_download_url = (Invoke-WebRequest -Uri $hojoringLatest -UseBasicParsing | ConvertFrom-Json)[0].assets[0].browser_download_url
    if ($hojoring_download_url.Length -gt 1) {
        $hojoringArchiveFileName = [System.IO.Path]::GetFileName($hojoring_download_url)
        $hojoringArchiveFile = Join-Path $TempFolder $hojoringArchiveFileName
        Invoke-WebRequest -Uri $hojoring_download_url -OutFile $hojoringArchiveFile
        $hojoringExtractDir = Join-Path $TempFolder "HojoringExtract"
        & $7z e -y -o"$hojoringExtractDir" -ir!"$ttsYukkuriDllFileName" $hojoringArchiveFile
        $ttsYukkuriDllFile = Join-Path $hojoringExtractDir $ttsYukkuriDllFileName
        $ttsYukkuriLiFile = Join-Path $hojoringExtractDir $ttsYukkuriLiFileName
        if(!(Test-Path $ttsYukkuriDllFile)) {
            Write-Output ("エラー: 最新リリースの取得に失敗しました")
            EndConfigure
        }
        & $ildasm $ttsYukkuriDllFile /out="$ttsYukkuriLiFile"
        Copy-Item -Force -Path (Join-Path $hojoringExtractDir "costura32.aquestalkdriver.dll") -Destination ".\ACT.TTSYukkuri\ACT.TTSYukkuri\Costura32\AquesTalkDriver.dll"
        Copy-Item -Force -Path (Join-Path $hojoringExtractDir "costura64.aquestalkdriver.dll") -Destination ".\ACT.TTSYukkuri\ACT.TTSYukkuri\Costura64\AquesTalkDriver.dll"

    }
    else {
        Write-Output ("エラー: 最新リリースの取得に失敗しました")
        EndConfigure
    }
    Write-Output "完了."
}

Remove-Item -Path $TempFolder -Recurse -Force;

Write-Output ""
Write-Output ("*** Configure complete.")
Write-Output ""

Set-Location $startdir
EndConfigure
