@echo off

set /p < speech.env

call download_voices_tts-1.bat
call download_voices_tts-1-hd.bat %PRELOAD_MODEL%

python speech.py %PRELOAD_MODEL:+--preload %PRELOAD_MODEL% %OPENEDAI_LOG_LEVEL:+--log-level %OPENEDAI_LOG_LEVEL%