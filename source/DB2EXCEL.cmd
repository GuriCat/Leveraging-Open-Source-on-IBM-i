@echo off
echo Remote dir = %1
echo Remote file = %2
echo Remote host = %3

set rparmf=%1%2.TXT
set lparmf=%TEMP%\DB2EXCEL_PARAM.TXT
set rmtf1=%1%2.CSV
set lclf1=%TEMP%\%2.CSV
set rmtf2=%1%2_FFD.CSV
set lclf2=%TEMP%\%2_FFD.CSV
set script=%TEMP%\script.TXT

if exist %lparmf% del %lparmf%
if exist %script% del %script%
if exist %TEMP%\db2excelftp.log del %TEMP%\db2excelftp.log

echo open %3 > %script%
echo %4 >> %script%
echo %5 >> %script%
echo bi >> %script%
echo get %rparmf% %lparmf% >> %script%
echo get %rmtf1% %lclf1% >> %script%
echo get %rmtf2% %lclf2% >> %script%
echo quit >> %script%

echo データの転送中...

ftp -s:%script% > %TEMP%\db2excelftp.log
del %script%

if not exist %lparmf% goto error
if not exist %TEMP%\%2.CSV goto error
if not exist %TEMP%\%2_FFD.CSV goto error

echo Excelの起動とデータの読み込み中...

start %USERPROFILE%\Desktop\DB2EXCEL.XLSM
goto exit

:error
echo ファイル転送が失敗。
pause

:exit
exit
