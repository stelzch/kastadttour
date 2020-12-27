adb shell run-as com.example.kacityguide "cp databases/lastVisit.db /sdcard/lastVisit.db && exit";
adb pull "/sdcard/lastVisit.db";
sqlite3 lastVisit.db
