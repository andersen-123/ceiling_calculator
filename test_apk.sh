#!/bin/bash

echo "=== APK Testing Script ==="
echo "1. Installing APK..."
adb install build/app/outputs/flutter-apk/app-release.apk

echo "2. Starting app..."
adb shell am start -n com.ceilingcalc.ceiling_calculator/.MainActivity

echo "3. Collecting logs for 30 seconds..."
timeout 30s adb logcat | grep -E "(ceiling_calculator|flutter|===|FATAL|AndroidRuntime)" > app_logs.txt &

echo "4. Waiting for app startup..."
sleep 5

echo "5. Checking if app is running..."
adb shell ps | grep ceiling_calculator || echo "App process not found"

echo "6. Getting crash logs..."
adb logcat -d | grep -A 20 -B 5 "FATAL EXCEPTION" > crash_logs.txt

echo "7. Full logs saved to app_logs.txt"
echo "8. Crash logs saved to crash_logs.txt"

echo "=== Analysis ==="
if grep -q "FATAL EXCEPTION" app_logs.txt; then
    echo "❌ APP CRASHED!"
    echo "=== Crash Details ==="
    cat crash_logs.txt
else
    echo "✅ App seems to be running"
fi

echo "=== Last 20 lines of logs ==="
tail -20 app_logs.txt
