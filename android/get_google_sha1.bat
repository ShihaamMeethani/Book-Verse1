@echo off
setlocal

echo ==============================================
echo BookVerse - Android Google Sign-In SHA-1
 echo ==============================================

set "KEYSTORE=%USERPROFILE%\.android\debug.keystore"
set "KEYTOOL=keytool"

where %KEYTOOL% >nul 2>nul
if errorlevel 1 (
  echo.
  echo ERROR: Java keytool was not found in PATH.
  echo Make sure Android Studio's bundled JDK is installed.
  echo.
  pause
  exit /b 1
)

if not exist "%KEYSTORE%" (
  echo Debug keystore was not found. Creating it now...
  if not exist "%USERPROFILE%\.android" mkdir "%USERPROFILE%\.android"
  "%KEYTOOL%" -genkeypair -v -keystore "%KEYSTORE%" -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
  if errorlevel 1 (
    echo.
    echo Could not create the debug keystore.
    pause
    exit /b 1
  )
)

echo.
echo Your Android debug SHA-1 is:
echo.
"%KEYTOOL%" -list -v -keystore "%KEYSTORE%" -storepass android -alias androiddebugkey | findstr /C:"SHA1:" /C:"SHA-1:"
echo.
echo Add that SHA-1 in Firebase Console:
echo Project settings -^> General -^> Your Android app -^> SHA certificate fingerprints
 echo.
echo Then download the NEW google-services.json and replace:
echo android\app\google-services.json
 echo.
pause
