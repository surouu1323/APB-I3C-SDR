@echo off
set cov=0

call make clean

if "%1"=="cov" (
    set cov=1
)

for /f "tokens=*" %%a in (pat.list) do (
    echo %%a
    echo %%a | findstr "//" >nul
    if errorlevel 1 (
        @REM if %cov%==1 (
            call make all_cov TESTNAME=%%a
        @REM ) else (
        @REM     call make all TESTNAME=%%a
        @REM )
    )
)

if %cov%==1 (
    call make gen_cov
)
