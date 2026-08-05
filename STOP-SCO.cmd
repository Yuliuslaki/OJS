@echo off
chcp 65001 >nul
title ScientiCO Local
echo.
echo Membuka ScientiCO melalui WSL Ubuntu...
echo.
wsl.exe -d Ubuntu -- bash -lc "cd /home/acer/ojs-sco-local && bash ./scripts/stop-local.sh"
echo.
pause
