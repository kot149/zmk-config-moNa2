# コマンドライン引数を取得
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('L', 'R')]
    [string]$Side = 'R'
)

# ビルドディレクトリのパスを設定
$buildDir = Join-Path $PSScriptRoot ".." "build"
$uf2File = Join-Path $buildDir "moNa2_$Side-seeeduino_xiao_ble-zmk.uf2"

# ファイルの存在確認
if (-not (Test-Path $uf2File)) {
    Write-Error "File '$uf2File' not found."
    exit 1
}

Write-Host "Firmware file: $uf2File"
Write-Host "Waiting for new drive... (Press Ctrl+C to cancel)"

try {
    # 初期のドライブ一覧を取得
    $initialDrives = Get-PSDrive -PSProvider FileSystem

    while ($true) {
        Start-Sleep -Milliseconds 500
        $currentDrives = Get-PSDrive -PSProvider FileSystem

        # 新しく追加されたドライブを検出
        $newDrives = $currentDrives | Where-Object {
            $drive = $_
            -not ($initialDrives | Where-Object { $_.Name -eq $drive.Name })
        }

        if ($newDrives) {
            $targetDrive = $newDrives[0]
            $targetPath = Join-Path ($targetDrive.Name + ":\") (Split-Path $uf2File -Leaf)

            Write-Host "New drive detected: $($targetDrive.Name)"
            Write-Host "Copying firmware..."

            # ファイルサイズを取得
            $fileSize = (Get-Item $uf2File).Length
            $buffer = New-Object byte[] 1MB
            $totalBytesRead = 0

            # ファイルストリームを開く
            $source = [System.IO.File]::OpenRead($uf2File)
            $destination = [System.IO.File]::Create($targetPath)

            try {
                do {
                    $bytesRead = $source.Read($buffer, 0, $buffer.Length)
                    if ($bytesRead -gt 0) {
                        $destination.Write($buffer, 0, $bytesRead)
                        $totalBytesRead += $bytesRead
                        $percentComplete = [math]::Min(100, ($totalBytesRead * 100) / $fileSize)
                        Write-Progress -Activity "Copying firmware" -Status "$([math]::Round($percentComplete))% complete" -PercentComplete $percentComplete
                    }
                } while ($bytesRead -gt 0)
            }
            finally {
                $source.Close()
                $destination.Close()
            }

            Write-Progress -Activity "Copying firmware" -Completed
            Write-Host "Flash completed!"
            break
        }
    }
}
catch [System.Management.Automation.Host.HostException] {
    Write-Host "`nCancelled."
    exit 0
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}