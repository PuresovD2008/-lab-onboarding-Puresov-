@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM ============================================================================
REM Тема: Практическая работа 8 (Часть 2) - Аудит и рекомендации по ПО
REM Автор: Пуресов Даниил
REM ============================================================================

set "REPORT=%~dp0pc_report.txt"
set "TEMP_RAW=%TEMP%\apps_raw_%RANDOM%.txt"
set "TEMP_APPS=%TEMP%\apps_list_%RANDOM%.txt"

set /a CHECKED_CATS=0
set /a RECS_COUNT=0

REM Получение текущей даты и времени для временной метки отчёта
set "REPORT_TIME="
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format 'dd.MM.yyyy HH:mm:ss'" 2^>nul') do set "REPORT_TIME=%%T"
if not defined REPORT_TIME set "REPORT_TIME=%DATE% %TIME%"

REM Очистка и создание нового файла отчёта
type nul > "%REPORT%"

call :log "=========================================================="
call :log "ОТЧЁТ АУДИТА КЛИЕНТСКОГО КОМПЬЮТЕРА"
call :log "Дата и время формирования: %REPORT_TIME%"
call :log "=========================================================="
call :log ""

REM ============================================================================
REM БЛОК 1. СБОР АППАРАТНЫХ И СИСТЕМНЫХ ДАННЫХ (С ЗАЩИТОЙ ОТ ПУСТЫХ ЗНАЧЕНИЙ)
REM ============================================================================
echo [1/4] Сбор сведений об операционной системе и оборудовании...

call :log "[1. Операционная система]"
set "OS_CAPTION="
set "OS_VERSION="
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul') do set "OS_CAPTION=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Version" 2^>nul') do set "OS_VERSION=%%A"

if defined OS_CAPTION (
    call :log "Система: %OS_CAPTION%"
) else (
    call :log "Система: Не удалось получить название ОС"
)
if defined OS_VERSION (
    call :log "Версия: %OS_VERSION%"
) else (
    call :log "Версия: Не удалось получить версию ОС"
)
call :log "----------------------------------------------------------"
call :log ""

call :log "[2. Процессор]"
set "CPU_NAME="
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1).Name" 2^>nul') do set "CPU_NAME=%%A"
if defined CPU_NAME (
    call :log "Модель: %CPU_NAME%"
) else (
    call :log "Модель: Не удалось получить данные о процессоре"
)
call :log "----------------------------------------------------------"
call :log ""

call :log "[3. Оперативная память]"
set "MEM_TOTAL="
set "MEM_FREE="
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB, 1)" 2^>nul') do set "MEM_TOTAL=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)" 2^>nul') do set "MEM_FREE=%%A"

if defined MEM_TOTAL (
    call :log "Всего памяти: %MEM_TOTAL% ГБ"
) else (
    call :log "Всего памяти: Не удалось получить данные"
)
if defined MEM_FREE (
    call :log "Свободно памяти: %MEM_FREE% ГБ"
) else (
    call :log "Свободно памяти: Не удалось получить данные"
)
call :log "----------------------------------------------------------"
call :log ""

call :log "[4. Диск C]"
set "DISK_TOTAL="
set "DISK_FREE="
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").Size / 1GB, 1)" 2^>nul') do set "DISK_TOTAL=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace / 1GB, 1)" 2^>nul') do set "DISK_FREE=%%A"

if defined DISK_TOTAL (
    call :log "Общий размер диска C: %DISK_TOTAL% ГБ"
) else (
    call :log "Общий размер диска C: Не удалось получить данные"
)
if defined DISK_FREE (
    call :log "Свободно на диске C: %DISK_FREE% ГБ"
) else (
    call :log "Свободно на диске C: Не удалось получить данные"
)
call :log "----------------------------------------------------------"
call :log ""

REM ============================================================================
REM БЛОК 2. ОПРОС РЕЕСТРА И ФОРМИРОВАНИЕ ОЧИЩЕННОГО СПИСКА ПРОГРАММ
REM ============================================================================
echo [2/4] Опрос реестра установленных программ (подождите)...

type nul > "%TEMP_RAW%"

REM Извлечение 64-битных программ (берется 3-й токен - само название DisplayName)
for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%B>> "%TEMP_RAW%"
)

REM Извлечение 32-битных программ
for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\WOW6432Node\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%B>> "%TEMP_RAW%"
)

REM Сортировка и удаление дубликатов через PowerShell во временный файл
powershell -NoProfile -Command "Get-Content '%TEMP_RAW%' -Encoding Default | Where-Object { $_.Trim() -ne '' } | Sort-Object -Unique | Set-Content '%TEMP_APPS%' -Encoding UTF8" 2>nul

REM Если PowerShell не создал файл, используем простой sort
if not exist "%TEMP_APPS%" (
    sort "%TEMP_RAW%" > "%TEMP_APPS%"
)

call :log "[5. Установленное программное обеспечение]"
set "APPS_FOUND=0"
for /f "usebackq delims=" %%P in ("%TEMP_APPS%") do (
    set "APPS_FOUND=1"
    call :log " - %%P"
)
if "%APPS_FOUND%"=="0" (
    call :log "Список установленных программ пуст или недоступен."
)
call :log "=========================================================="
call :log ""

REM ============================================================================
REM БЛОК 3. РЕКОМЕНДАЦИИ ПО БАЗОВОМУ ОФИСНОМУ ПО
REM ============================================================================
echo [3/4] Анализ базового офисного ПО...

call :log "[6. АУДИТ БАЗОВОГО ОФИСНОГО ПО]"

REM 3.1. Офисный пакет
set /a CHECKED_CATS+=1
set "MATCH="
for /f "delims=" %%M in ('findstr /i "Office LibreOffice OpenOffice МойОфис" "%TEMP_APPS%"') do if not defined MATCH set "MATCH=%%M"
if defined MATCH (
    call :log "[OK] Офисный пакет: требование выполнено (найдено: !MATCH!)"
) else (
    set /a RECS_COUNT+=1
    call :log "[РЕКОМЕНДАЦИЯ] Не обнаружен офисный пакет. Для работы с документами и таблицами рекомендуется установить LibreOffice или МойОфис."
)

REM 3.2. Браузер (с проверкой наличия стороннего браузера помимо системного Edge)
set /a CHECKED_CATS+=1
set "MATCH_ALT="
set "MATCH_EDGE="
for /f "delims=" %%M in ('findstr /i "Chrome Firefox Яндекс Yandex Opera" "%TEMP_APPS%"') do if not defined MATCH_ALT set "MATCH_ALT=%%M"
for /f "delims=" %%M in ('findstr /i "Edge" "%TEMP_APPS%"') do if not defined MATCH_EDGE set "MATCH_EDGE=%%M"

if defined MATCH_ALT (
    call :log "[OK] Веб-браузер: требование выполнено (найдено: !MATCH_ALT!)"
) else if defined MATCH_EDGE (
    set /a RECS_COUNT+=1
    call :log "[ВНИМАНИЕ] Веб-браузер: обнаружен только системный компонент (!MATCH_EDGE!). Рекомендуется установить корпоративный браузер (Яндекс Браузер или Google Chrome)."
) else (
    set /a RECS_COUNT+=1
    call :log "[РЕКОМЕНДАЦИЯ] Не обнаружен веб-браузер. Рекомендуется установить Яндекс Браузер или Google Chrome."
)

REM 3.3. Программа для чтения PDF
set /a CHECKED_CATS+=1
set "MATCH="
for /f "delims=" %%M in ('findstr /i "Acrobat Foxit SumatraPDF PDF" "%TEMP_APPS%"') do if not defined MATCH set "MATCH=%%M"
if defined MATCH (
    call :log "[OK] Просмотр PDF: требование выполнено (найдено: !MATCH!)"
) else (
    set /a RECS_COUNT+=1
    call :log "[РЕКОМЕНДАЦИЯ] Не обнаружена программа для чтения PDF. Для работы с документами рекомендуется установить SumatraPDF или Foxit PDF Reader."
)

REM 3.4. Архиватор
set /a CHECKED_CATS+=1
set "MATCH="
for /f "delims=" %%M in ('findstr /i "7-Zip WinRAR WinZip PeaZip" "%TEMP_APPS%"') do if not defined MATCH set "MATCH=%%M"
if defined MATCH (
    call :log "[OK] Архиватор: требование выполнено (найдено: !MATCH!)"
) else (
    set /a RECS_COUNT+=1
    call :log "[РЕКОМЕНДАЦИЯ] Не обнаружен архиватор. Для работы с вложениями в почте рекомендуется установить 7-Zip или WinRAR."
)

REM 3.5. Антивирусная защита
set /a CHECKED_CATS+=1
set "MATCH="
for /f "delims=" %%M in ('findstr /i "Kaspersky ESET Dr.Web Defender Avast AVG" "%TEMP_APPS%"') do if not defined MATCH set "MATCH=%%M"
if defined MATCH (
    call :log "[OK] Антивирус: требование выполнено (найдено: !MATCH!)"
) else (
    call :log "[OK] Антивирус: сторонний клиент не найден, используется встроенный защитник Windows Defender (компонент ОС)."
)

call :log "----------------------------------------------------------"
call :log ""

REM ============================================================================
REM БЛОК 4. ПРОВЕРКА ИЗЛИШНЕГО И НЕПРОФИЛЬНОГО ПО
REM ============================================================================
echo [4/4] Поиск непрофильного и излишнего ПО...

call :log "[7. АУДИТ ИЗЛИШНЕГО ПО (РЕКОМЕНДАЦИИ К ПРОВЕРКЕ)]"
call :log "Примечание: вывод ниже не является указанием к удалению. Программа может использоваться по согласованию; решение принимает администратор."
call :log ""

REM Группа 1: Игровое ПО
call :log "--- Группа 1: Игровое ПО и игровые платформы ---"
set "GRP_FOUND=0"
for /f "delims=" %%M in ('findstr /i "Steam Epic GOG Origin Ubisoft Battle.net Riot Game Gaming" "%TEMP_APPS%"') do (
    set "GRP_FOUND=1"
    set /a RECS_COUNT+=1
    call :log " [ПРОВЕРИТЬ] %%M — не относится к базовым офисным задачам и подлежит проверке."
)
if "!GRP_FOUND!"=="0" call :log " Нарушений не выявлено: игровое ПО не обнаружено."
call :log ""

REM Группа 2: Торрент-клиенты
call :log "--- Группа 2: Торрент-клиенты и P2P-сети ---"
set "GRP_FOUND=0"
for /f "delims=" %%M in ('findstr /i "torrent uTorrent BitTorrent qBittorrent Vuze MediaGet" "%TEMP_APPS%"') do (
    set "GRP_FOUND=1"
    set /a RECS_COUNT+=1
call :log " [ПРОВЕРИТЬ] %%M — не относится к базовым офисным задачам, создает нагрузку на сеть и подлежит проверке."
)
if "!GRP_FOUND!"=="0" call :log " Нарушений не выявлено: торрент-клиенты не обнаружены."
call :log ""
REM Группа 3: Мессенджеры
call :log "--- Группа 3: Мессенджеры и личное общение ---"
set "GRP_FOUND=0"
for /f "delims=" %%M in ('findstr /i "Discord Telegram WhatsApp Viber Skype" "%TEMP_APPS%"') do (
set "GRP_FOUND=1"
set /a RECS_COUNT+=1
call :log " [ПРОВЕРИТЬ] %%M — не относится к базовым офисным задачам и подлежит проверке (уточнить наличие согласования как рабочего канала)."
)
if "!GRP_FOUND!"=="0" call :log " Нарушений не выявлено: сторонние мессенджеры не обнаружены."
call :log ""
REM Группа 4: Развлечения и мультимедиа
call :log "--- Группа 4: Инструменты развлечений и мультимедиа ---"
set "GRP_FOUND=0"
for /f "delims=" %%M in ('findstr /i "Wallpaper OBS Soundpad Spotify Winamp AIMP" "%TEMP_APPS%"') do (
set "GRP_FOUND=1"
set /a RECS_COUNT+=1
call :log " [ПРОВЕРИТЬ] %%M — не относится к базовым офисным задачам и подлежит проверке."
)
if "!GRP_FOUND!"=="0" call :log " Нарушений не выявлено: развлекательное ПО не обнаружено."
call :log ""
REM ============================================================================
REM ИТОГОВАЯ СВОДКА И УДАЛЕНИЕ ВРЕМЕННЫХ ФАЙЛОВ
REM ============================================================================
call :log "=========================================================="
call :log "ИТОГИ ПРОВЕРКИ:"
call :log "Проверено категорий базового ПО: %CHECKED_CATS%"
call :log "Выдано рекомендаций и пунктов для проверки: %RECS_COUNT%"
call :log "Полный путь к файлу отчёта: %REPORT%"
call :log "=========================================================="
REM Очистка временных файлов анализа
if exist "%TEMP_RAW%" del /f /q "%TEMP_RAW%" > nul 2>&1
if exist "%TEMP_APPS%" del /f /q "%TEMP_APPS%" > nul 2>&1
echo.
echo Работа скрипта успешно завершена.
pause
exit /b 0
REM ============================================================================
REM ПОДПРОГРАММА ВЫВОДА В КОНСОЛЬ И ЗАПИСИ В ФАЙЛ ОТЧЁТА
REM ============================================================================
:log
set "MSG=%~1"
if "%MSG%"=="" (
echo(
echo(>> "%REPORT%"
exit /b
)
set "MSG=!MSG:^=^^!"
set "MSG=!MSG:&=^&!"
set "MSG=!MSG:|=^|!"
set "MSG=!MSG:<=^<!"
set "MSG=!MSG:>=^>!"
echo(!MSG!
echo(!MSG!>> "%REPORT%"
exit /b
