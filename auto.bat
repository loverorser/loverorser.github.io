@echo off
setlocal enabledelayedexpansion

set README=README.md
set TMP=__readme_utf8.tmp

> %TMP% (
    echo ## 文档列表
    echo.
    for %%f in (*.md) do (
        if /I not "%%f"=="%README%" (
            set name=%%~nf
            echo - [!name!](%%f^)
        )
    )
)

powershell -NoProfile -Command ^
    "Get-Content '%TMP%' | Set-Content '%README%' -Encoding utf8"

del %TMP%
echo README.md 已生成（UTF-8）
pause
