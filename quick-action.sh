#!/bin/bash
#
# quick-action.sh — Finder "빠른 동작"용 래퍼
#   선택된 파일(들)을 변환 엔진에 넘기고, 결과를 대화상자로 보여줍니다.
#
#   ※ 한글 깨짐 방지:
#     AppleScript 의 `system attribute`(환경변수)나 인자 전달은 UTF-8 을 제대로
#     디코딩하지 못해 한글이 깨집니다. 그래서 메시지를 임시파일에 UTF-8 로 기록한 뒤
#     AppleScript 에서 `read ... as «class utf8»` 로 읽어 표시합니다.
#
set -u

ENGINE="$HOME/Library/Application Support/euckr2utf8/euckr2utf8.sh"

show_dialog() {   # $1 = icon(note|stop|caution)   $2 = message
  local icon="$1" msg="$2" tmp
  tmp="$(mktemp -t euckr2utf8)" || tmp="/tmp/euckr2utf8.$$.txt"
  printf '%s' "$msg" > "$tmp"
  osascript <<OSA >/dev/null 2>&1
set theText to (read (POSIX file "$tmp") as «class utf8»)
display dialog theText with title "EUC-KR → UTF-8 변환" buttons {"확인"} default button "확인" with icon $icon
OSA
  rm -f "$tmp"
}

if [ ! -x "$ENGINE" ]; then
  show_dialog stop "변환 엔진을 찾을 수 없습니다. 설치를 다시 실행하세요:
$ENGINE"
  exit 1
fi

OUT="$("$ENGINE" --quiet "$@" 2>&1)"
[ -z "$OUT" ] && OUT="처리할 파일이 없습니다."
show_dialog note "$OUT"
exit 0
