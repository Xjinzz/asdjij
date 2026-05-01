$ErrorActionPreference = "Stop"

Write-Host "===== BidKing 打包环境一键安装 =====" -ForegroundColor Cyan

# 1. 检查 Python 是否已安装
$pythonInstalled = $false
try {
    $ver = python --version 2>&1
    if ($ver -match "Python 3\.(11|12|13)") {
        Write-Host "[OK] 已检测到 $ver" -ForegroundColor Green
        $pythonInstalled = $true
    }
} catch {}

if (-not $pythonInstalled) {
    Write-Host "[INFO] 正在下载 Python 3.12.8..." -ForegroundColor Yellow
    $installerUrl = "https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "[INFO] 正在安装 Python（静默模式）..." -ForegroundColor Yellow
    Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_pip=1" -Wait
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

    # 刷新 PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    $ver = python --version 2>&1
    Write-Host "[OK] Python 安装完成: $ver" -ForegroundColor Green
}

# 2. 升级 pip
Write-Host "[INFO] 升级 pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# 3. 安装项目依赖
Write-Host "[INFO] 安装项目依赖..." -ForegroundColor Yellow
$reqPath = Join-Path $PSScriptRoot "requirements.txt"
python -m pip install -r $reqPath

# 4. 验证关键包
Write-Host ""
Write-Host "===== 环境验证 =====" -ForegroundColor Cyan
$packages = @("pyinstaller", "pyautogui", "rapidocr_onnxruntime", "onnxruntime", "PIL", "numpy", "cv2")
foreach ($pkg in $packages) {
    try {
        python -c "import $pkg" 2>&1 | Out-Null
        Write-Host "[OK] $pkg" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $pkg" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "===== 环境就绪！=====" -ForegroundColor Cyan
Write-Host "现在可以执行打包了：" -ForegroundColor White
Write-Host "  cd bidking_fresh_bot" -ForegroundColor White
Write-Host "  powershell -ExecutionPolicy Bypass -File .\build_exe.ps1" -ForegroundColor White
Write-Host ""
