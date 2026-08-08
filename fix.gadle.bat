@echo off
set GRADLE_PROPS="android\gradle.properties"

echo Adding Network fixes to %GRADLE_PROPS%...

:: اضافه کردن تنظیمات بهبود سرعت و رفع مشکل SSL
echo org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m >> %GRADLE_PROPS%
echo android.useAndroidX=true >> %GRADLE_PROPS%
echo android.enableJetifier=true >> %GRADLE_PROPS%

:: اگر از پروکسی استفاده می‌کنید، خط‌های زیر را از حالت کامنت خارج کنید
:: echo systemProp.http.proxyHost=127.0.0.1 >> %GRADLE_PROPS%
:: echo systemProp.http.proxyPort=1080 >> %GRADLE_PROPS%
:: echo systemProp.https.proxyHost=127.0.0.1 >> %GRADLE_PROPS%
:: echo systemProp.https.proxyPort=1080 >> %GRADLE_PROPS%

echo Done! Now open Android Studio and Sync.
pause