@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM Тема: Диагностика клиентского компьютера
REM Автор: Пуресов Даниил
REM Дата: 19.11.2026

set "REPORT=%~dp0pc_report.txt"

REM Инициализация отчёта и вывод заголовка
echo ================================================== > "%REPORT%"
echo ДИАГНОСТИКА КЛИЕНТСКОГО КОМПЬЮТЕРА >> "%REPORT%"
echo ================================================== >> "%REPORT%"

echo ==================================================
echo ДИАГНОСТИКА КЛИЕНТСКОГО КОМПЬЮТЕРА
echo ==================================================
echo.

REM Блок 1: Сведения об операционной системе
echo [Операционная система]
echo [Операционная система] >> "%REPORT%"
for /f "tokens=1,* delims==" %%A in ('wmic os get Caption^,Version /format:list ^| findstr "="') do (
    echo %%A: %%B
    echo %%A: %%B >> "%REPORT%"
)
echo --------------------------------------------------
echo -------------------------------------------------- >> "%REPORT%"
echo.

REM Блок 2: Сведения о процессоре
echo [Процессор]
echo [Процессор] >> "%REPORT%"
for /f "tokens=2 delims==" %%A in ('wmic cpu get Name /format:list ^| findstr "="') do (
    echo %%A
    echo %%A >> "%REPORT%"
)
echo --------------------------------------------------
echo -------------------------------------------------- >> "%REPORT%"
echo.

REM Блок 3: Сведения об оперативной памяти (перевод из КБ в ГБ делением на 1048576)
echo [Оперативная память]
echo [Оперативная память] >> "%REPORT%"
for /f "tokens=2 delims==" %%A in ('wmic OS get TotalVisibleMemorySize /format:list ^| findstr "="') do set "TOTAL_KB=%%A"
for /f "tokens=2 delims==" %%A in ('wmic OS get FreePhysicalMemory /format:list ^| findstr "="') do set "FREE_KB=%%A"
set /a TOTAL_GB=%TOTAL_KB% / 1048576
set /a FREE_GB=%FREE_KB% / 1048576
echo Всего памяти: %TOTAL_GB% ГБ
echo Свободно памяти: %FREE_GB% ГБ
echo Всего памяти: %TOTAL_GB% ГБ >> "%REPORT%"
echo Свободно памяти: %FREE_GB% ГБ >> "%REPORT%"
echo --------------------------------------------------
echo -------------------------------------------------- >> "%REPORT%"
echo.

REM Блок 4: Свободное место на диске C (перевод из байт в ГБ делением на 1073741824)
echo [Диск C]
echo [Диск C] >> "%REPORT%"
for /f "tokens=2 delims==" %%A in ('wmic logicaldisk where "DeviceID='C:'" get Size /format:list ^| findstr "="') do set "DISK_SIZE_B=%%A"
for /f "tokens=2 delims==" %%A in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /format:list ^| findstr "="') do set "DISK_FREE_B=%%A"
set "DISK_SIZE_GB=%DISK_SIZE_B:~0,-9%"
set "DISK_FREE_GB=%DISK_FREE_B:~0,-9%"
set /a DISK_SIZE_GB=(%DISK_SIZE_GB% * 1000) / 1074
set /a DISK_FREE_GB=(%DISK_FREE_GB% * 1000) / 1074
echo Общий размер диска C: %DISK_SIZE_GB% ГБ
echo Свободно на диске C: %DISK_FREE_GB% ГБ
echo Общий размер диска C: %DISK_SIZE_GB% ГБ >> "%REPORT%"
echo Свободно на диске C: %DISK_FREE_GB% ГБ >> "%REPORT%"
echo --------------------------------------------------
echo -------------------------------------------------- >> "%REPORT%"
echo.

REM Блок 5: Список установленных программ из реестра (64-бит и 32-бит)
echo [Установленные программы]
echo [Установленные программы] >> "%REPORT%"
for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo - %%B
    echo - %%B >> "%REPORT%"
)
for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\WOW6432Node\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo - %%B
    echo - %%B >> "%REPORT%"
)
echo ==================================================
echo ================================================== >> "%REPORT%"
echo.

REM Завершение работы и сохранение отчёта
echo Отчёт сохранён в файл: %REPORT%
pause
