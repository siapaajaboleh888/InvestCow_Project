@echo off
set FFMPEG_PATH=C:\ffmpeg\bin\ffmpeg.exe
set STREAM_URL=rtmp://localhost/live/cow1

echo --- InvestCow CCTV Simulator Pushing Stream ---
echo Make sure Node.js server is running first!
echo.
echo Using FFMPEG path: %FFMPEG_PATH%
echo.

"%FFMPEG_PATH%" -re -f lavfi -i testsrc=size=1280x720:rate=30 -f lavfi -i aevalsrc=0 -vf "drawtext=text='LIVE INVESTCOW %%{localtime}':x=10:y=10:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.5" -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac -f flv %STREAM_URL%

pause
