# EUC-KR → UTF-8 변환기 (한글 안 깨짐)

국내 카드사·금융 사이트 등에서 내려받는 `.xls`(실제로는 EUC-KR 인코딩된 XML/HTML) 파일의 **내용을**
한글이 깨지지 않게 **UTF-8 로 변환**합니다. **파일명은 그대로 두고 내용만** 바꿉니다.

맥 **Finder 우클릭 → 빠른 동작** 메뉴로 클릭 한 번에 처리할 수 있습니다.

---

## 왜 단순 변환으로는 안 되나 (핵심)

이 파일들은 첫 줄에 인코딩이 **선언**되어 있습니다:

```xml
<?xml version='1.0' encoding='EUC-KR'?>       ← XML 형식
<meta ... charset=euc-kr>                     ← HTML 형식
```

바이트만 UTF-8 로 바꾸고 이 **선언을 그대로 두면**, 엑셀·브라우저가
UTF-8 바이트를 다시 EUC-KR 로 해석해서 **오히려 더 깨집니다.**
그래서 이 도구는 **① 바이트 변환 + ② 인코딩 선언까지 UTF-8 로 교체**를 함께 합니다.

---

## 설치 (우클릭 메뉴)

```bash
git clone https://github.com/mebaser/euckr-utf8-trans.git
cd euckr-utf8-trans
./install-quick-action.sh
```

설치되면:

1. Finder 에서 변환할 파일(들) 선택
2. **우클릭 → 빠른 동작(Quick Actions) → "EUC-KR → UTF-8 변환"**
3. 완료 대화상자에서 결과 확인 (`완료: 변환 N · 건너뜀 M · 실패 K`)

> 메뉴가 바로 안 보이면 `killall Finder` 로 Finder 를 한 번 재실행하세요.
> (또는 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램 → 빠른 동작에서 활성화 확인)

**제거:** `./uninstall.sh`

---

## 터미널로도 사용 가능

```bash
# 파일 하나 또는 여러 개
./euckr2utf8.sh 거래내역.xls

# 폴더 통째로 (안의 xls/csv/tsv/txt/html/xml 재귀 변환)
./euckr2utf8.sh ~/Downloads/내역/

# 옵션
./euckr2utf8.sh --dry-run 폴더/     # 실제로 안 바꾸고 대상만 미리보기
./euckr2utf8.sh --backup  파일.xls  # 원본을 파일.xls.bak 으로 백업 후 변환
```

---

## 특징 / 안전장치

- **지원 형식**: Excel 2003 XML(.xls), HTML 표(.xls/.html), CSV/TSV, 일반 텍스트
- **원본 인코딩**: CP949(EUC-KR 상위호환) 우선, 실패 시 EUC-KR 로 자동 폴백
- **멱등성**: 이미 UTF-8 인 파일은 **자동으로 건너뜀** → 여러 번 눌러도 안전
- **실패 안전**: 변환·검증에 실패하면 **원본을 절대 덮어쓰지 않음**
- **권한 보존**: 원본 파일의 권한(모드)을 유지한 채 내용만 교체
- **의존성 없음**: macOS 기본 내장 `iconv` / `perl` 만 사용 (Python 등 설치 불필요)

---

## 구성 파일

| 파일 | 설명 |
|------|------|
| `euckr2utf8.sh` | 변환 엔진 (터미널 단독 사용 가능) |
| `quick-action.sh` | 우클릭 실행 래퍼 (변환 후 결과 대화상자 표시, 한글 깨짐 방지) |
| `install-quick-action.sh` | Finder 우클릭 "빠른 동작" 메뉴 설치 |
| `uninstall.sh` | 우클릭 메뉴 및 설치본 제거 |

설치 시 엔진은 `~/Library/Application Support/euckr2utf8/` 로,
우클릭 서비스는 `~/Library/Services/EUCKR-to-UTF8.workflow` 로 복사됩니다.
