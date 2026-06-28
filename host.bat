@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "PUBLIC_DIR=%ROOT_DIR%public"
set "AVATAR_SRC=%ROOT_DIR%avatars\priya"
set "AVATAR_DEST=%PUBLIC_DIR%\avatars\priya"

if "%PORT%"=="" set "PORT=8080"
if "%HOST%"=="" set "HOST=127.0.0.1"

where python >nul 2>nul
if %errorlevel%==0 (
  set "PYTHON_BIN=python"
) else (
  where py >nul 2>nul
  if %errorlevel%==0 (
    set "PYTHON_BIN=py -3"
  ) else (
    echo Error: Python is required. Install Python 3 and try again.
    exit /b 1
  )
)

if not exist "%PUBLIC_DIR%" (
  echo Error: public folder not found at %PUBLIC_DIR%
  exit /b 1
)

if exist "%AVATAR_SRC%" (
  if not exist "%AVATAR_DEST%" mkdir "%AVATAR_DEST%"
  xcopy "%AVATAR_SRC%\*" "%AVATAR_DEST%\" /E /Y /I >nul
  echo Synced avatar files to public\avatars\priya\
)

set "URL=http://%HOST%:%PORT%"

echo.
echo Priya Avatar - local host
echo -------------------------
echo URL:      %URL%
echo Folder:   %PUBLIC_DIR%
echo Python:   %PYTHON_BIN%
echo.
echo Press Ctrl+C to stop the server.
echo.

if not "%OPEN_BROWSER%"=="0" (
  start "" "%URL%"
)

cd /d "%PUBLIC_DIR%"
%PYTHON_BIN% -m http.server %PORT% --bind %HOST%
