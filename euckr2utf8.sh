#!/bin/bash
#
# euckr2utf8.sh — 한글 EUC-KR/CP949 파일 내용을 UTF-8로 안전하게 변환 (in-place)
#
# 지원 형식
#   - Excel 2003 SpreadsheetML(XML) .xls   : <?xml ... encoding='EUC-KR'?> 선언까지 교체
#   - HTML 표를 .xls/.html 로 저장한 파일  : <meta charset=...> 선언까지 교체
#   - CSV / TSV / 일반 텍스트              : 바이트만 변환
#
# 핵심 원칙
#   1) 바이트를 CP949(EUC-KR 상위호환) -> UTF-8 로 변환
#   2) 파일에 박힌 인코딩 선언(XML encoding / HTML charset)도 UTF-8 로 교체
#      (선언을 안 고치면 UTF-8 바이트를 다시 EUC-KR 로 오독해서 더 깨짐)
#   3) 이미 UTF-8 인 파일은 건드리지 않음 (idempotent — 여러 번 돌려도 안전)
#   4) 변환 실패 시 원본을 절대 덮어쓰지 않음
#
# macOS 기본 내장 도구(iconv, perl)만 사용 — 별도 설치 불필요
#
# 사용법
#   ./euckr2utf8.sh 파일1.xls [파일2.xls ...]
#   ./euckr2utf8.sh 폴더/            # 폴더 안의 xls/csv/tsv/txt/html 재귀 변환
#   옵션:
#     --backup      변환 전 원본을 "<파일>.bak" 으로 보관
#     --dry-run     실제로 바꾸지 않고 무엇을 할지만 출력
#     --quiet       요약만 출력
#     -h, --help    도움말

set -u

SRC_ENC_PRIMARY="CP949"   # EUC-KR 상위호환(확장 한글 포함). 미지원 시 EUC-KR 로 폴백
SRC_ENC_FALLBACK="EUC-KR"

# 한국어 레거시 charset 토큰 (대소문자 무시)
KO_CHARSETS='euc-kr|euckr|ks_c_5601-1987|ks_c_5601-1989|ksc5601|ksc_5601|ks_c_5601|cp949|x-windows-949|windows-949|ms949|uhc|korean'

BACKUP=0
DRYRUN=0
QUIET=0

n_converted=0
n_skipped=0
n_failed=0

log()     { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }  # 파일별 상세 (--quiet 시 숨김)
err()     { printf '%s\n' "$*" >&2; }                    # 오류 (항상 출력)
summary() { printf '%s\n' "$*"; }                        # 최종 요약 (항상 출력)

usage() {
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# 파일이 "엄격한 UTF-8"로 유효한지 검사 (순수 ASCII 도 UTF-8 로 취급됨)
is_valid_utf8() {
  iconv -f UTF-8 -t UTF-8 "$1" >/dev/null 2>&1
}

# 파일 앞부분에 한국어 레거시 인코딩이 선언돼 있는지 검사
declares_korean_charset() {
  # 앞 4096바이트만 검사 (선언은 항상 head 에 있음)
  head -c 4096 "$1" 2>/dev/null | LC_ALL=C perl -0777 -ne '
    exit(( /encoding\s*=\s*["'\'']?\s*(?:euc-kr|euckr|ks_c_5601-1987|ks_c_5601-1989|ksc5601|ksc_5601|ks_c_5601|cp949|x-windows-949|windows-949|ms949|uhc|korean)/i
         || /charset\s*=\s*["'\'']?\s*(?:euc-kr|euckr|ks_c_5601-1987|ks_c_5601-1989|ksc5601|ksc_5601|ks_c_5601|cp949|x-windows-949|windows-949|ms949|uhc|korean)/i
         ) ? 0 : 1 )'
}

# UTF-8 텍스트 안의 인코딩 선언을 UTF-8 로 교체 (stdin -> stdout)
rewrite_declaration() {
  KO="$KO_CHARSETS" perl -0777 -pe '
    my $ko = $ENV{KO};
    # 1) XML 선언:  <?xml ... encoding="euc-kr" ... ?>  (파일 맨 앞의 prolog 만 매칭)
    s{(\A\s*<\?xml\b[^>]*?\bencoding\s*=\s*)(["'\''])\s*(?:$ko)\s*(\2)}{${1}${2}UTF-8${3}}i;
    # 2) HTML5 meta:  <meta charset="euc-kr">
    # 3) HTML4 meta:  <meta http-equiv=... content="text/html; charset=euc-kr">
    s{(charset\s*=\s*)(["'\'']?)\s*(?:$ko)\s*(\2)}{${1}${2}UTF-8${3}}ig;
  '
}

convert_one() {
  local f="$1"

  [ -f "$f" ] || { err "건너뜀(파일 아님): $f"; n_skipped=$((n_skipped+1)); return; }
  [ -s "$f" ] || { log  "건너뜀(빈 파일): $f";   n_skipped=$((n_skipped+1)); return; }

  # 이미 UTF-8 로 유효한가?
  if is_valid_utf8 "$f"; then
    if declares_korean_charset "$f"; then
      # 바이트는 UTF-8 인데 선언만 잘못됨 -> 선언만 교체
      if [ "$DRYRUN" -eq 1 ]; then
        log "[dry-run] 선언만 교체(내용은 이미 UTF-8): $f"; n_converted=$((n_converted+1)); return
      fi
      local tmp="$f.utf8tmp.$$"
      if rewrite_declaration < "$f" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        [ "$BACKUP" -eq 1 ] && cp -p "$f" "$f.bak"
        _replace "$f" "$tmp"
        log "선언 교체(이미 UTF-8): $f"; n_converted=$((n_converted+1))
      else
        rm -f "$tmp"; err "실패(선언 교체): $f"; n_failed=$((n_failed+1))
      fi
    else
      log "건너뜀(이미 UTF-8): $f"; n_skipped=$((n_skipped+1))
    fi
    return
  fi

  # 여기부터: UTF-8 이 아님 -> 레거시(EUC-KR/CP949) 로 간주하고 변환
  if [ "$DRYRUN" -eq 1 ]; then
    log "[dry-run] 변환 예정 (EUC-KR/CP949 -> UTF-8): $f"; n_converted=$((n_converted+1)); return
  fi

  local tmp="$f.utf8tmp.$$"
  local enc="$SRC_ENC_PRIMARY"

  if ! iconv -f "$enc" -t UTF-8 "$f" > "$tmp" 2>/dev/null; then
    enc="$SRC_ENC_FALLBACK"
    if ! iconv -f "$enc" -t UTF-8 "$f" > "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      err "실패(디코딩 불가: $f) — EUC-KR/CP949 가 아닐 수 있음"
      n_failed=$((n_failed+1)); return
    fi
  fi

  # 변환 결과가 정상 UTF-8 인지 재확인
  if ! is_valid_utf8 "$tmp"; then
    rm -f "$tmp"; err "실패(변환 결과 검증 실패): $f"; n_failed=$((n_failed+1)); return
  fi

  # 인코딩 선언 교체
  local tmp2="$f.utf8tmp2.$$"
  if rewrite_declaration < "$tmp" > "$tmp2" 2>/dev/null && [ -s "$tmp2" ]; then
    mv -f "$tmp2" "$tmp"
  fi
  rm -f "$tmp2" 2>/dev/null

  [ "$BACKUP" -eq 1 ] && cp -p "$f" "$f.bak"
  _replace "$f" "$tmp"
  log "변환 완료 ($enc -> UTF-8): $f"
  n_converted=$((n_converted+1))
}

# 원본 권한/소유를 최대한 보존하며 내용 교체
_replace() {
  local orig="$1" newf="$2"
  # 원본의 퍼미션을 새 파일에 복사 후 atomic mv
  chmod "$(stat -f '%Lp' "$orig" 2>/dev/null || echo 644)" "$newf" 2>/dev/null
  mv -f "$newf" "$orig"
}

# 인자가 폴더면 안쪽 대상 파일을 재귀 수집
expand_targets() {
  local t="$1"
  if [ -d "$t" ]; then
    find "$t" -type f \( \
      -iname '*.xls' -o -iname '*.csv' -o -iname '*.tsv' \
      -o -iname '*.txt' -o -iname '*.html' -o -iname '*.htm' -o -iname '*.xml' \
      \) -print
  else
    printf '%s\n' "$t"
  fi
}

# ---- 인자 파싱 ----
files=()
while [ $# -gt 0 ]; do
  case "$1" in
    --backup) BACKUP=1 ;;
    --dry-run) DRYRUN=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) usage ;;
    --) shift; while [ $# -gt 0 ]; do files+=("$1"); shift; done; break ;;
    -*) err "알 수 없는 옵션: $1"; exit 2 ;;
    *) files+=("$1") ;;
  esac
  shift
done

if [ "${#files[@]}" -eq 0 ]; then
  err "대상 파일이 없습니다. 사용법은 -h 참고."
  exit 2
fi

for t in "${files[@]}"; do
  while IFS= read -r f; do
    [ -n "$f" ] && convert_one "$f"
  done < <(expand_targets "$t")
done

summary "완료: 변환 ${n_converted} · 건너뜀 ${n_skipped} · 실패 ${n_failed}"

# 실패가 있으면 종료코드 1
[ "$n_failed" -eq 0 ]
