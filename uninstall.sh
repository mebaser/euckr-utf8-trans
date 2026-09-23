#!/bin/bash
# uninstall.sh — Quick Action 및 변환 엔진 제거
set -u

WF="$HOME/Library/Services/EUCKR-to-UTF8.workflow"
APP_SUPPORT="$HOME/Library/Application Support/euckr2utf8"

removed=0
if [ -d "$WF" ]; then rm -rf "$WF" && echo "제거: $WF" && removed=1; fi
if [ -d "$APP_SUPPORT" ]; then rm -rf "$APP_SUPPORT" && echo "제거: $APP_SUPPORT" && removed=1; fi

/System/Library/CoreServices/pbs -update 2>/dev/null || true
/System/Library/CoreServices/pbs -flush  2>/dev/null || true

[ "$removed" -eq 1 ] && echo "완료. (Finder 재실행: killall Finder)" || echo "설치된 항목이 없습니다."
