@echo off
echo BookVerse: deploying Firestore rules and indexes...
firebase deploy --only firestore:rules,firestore:indexes
pause
