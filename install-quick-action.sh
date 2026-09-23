#!/bin/bash
#
# install-quick-action.sh
#   Finder 우클릭 → "빠른 동작(Quick Actions)" → "EUC-KR → UTF-8 변환" 메뉴를 설치합니다.
#
#   구성:
#     1) 변환 엔진(euckr2utf8.sh)을 안정된 위치로 복사
#          ~/Library/Application Support/euckr2utf8/euckr2utf8.sh
#     2) macOS 서비스 번들 생성
#          ~/Library/Services/EUCKR-to-UTF8.workflow
#     3) 서비스 목록 새로고침(pbs)
#
#   설치 후: Finder 에서 파일 선택 → 우클릭 → 빠른 동작 → "EUC-KR → UTF-8 변환"
#
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
ENGINE_SRC="$HERE/euckr2utf8.sh"
WRAPPER_SRC="$HERE/quick-action.sh"

APP_SUPPORT="$HOME/Library/Application Support/euckr2utf8"
ENGINE_DST="$APP_SUPPORT/euckr2utf8.sh"
WRAPPER_DST="$APP_SUPPORT/quick-action.sh"

SERVICES="$HOME/Library/Services"
WF="$SERVICES/EUCKR-to-UTF8.workflow"
CONTENTS="$WF/Contents"

MENU_LABEL="EUC-KR → UTF-8 변환"

# --- 사전 점검 ---
for f in "$ENGINE_SRC" "$WRAPPER_SRC"; do
  if [ ! -f "$f" ]; then
    echo "오류: 필요한 파일을 찾을 수 없습니다: $f" >&2
    exit 1
  fi
done

echo "[1/3] 변환 엔진/래퍼 설치 → $APP_SUPPORT"
mkdir -p "$APP_SUPPORT"
cp "$ENGINE_SRC"  "$ENGINE_DST";  chmod +x "$ENGINE_DST"
cp "$WRAPPER_SRC" "$WRAPPER_DST"; chmod +x "$WRAPPER_DST"

echo "[2/3] Quick Action 번들 생성 → $WF"
rm -rf "$WF"
mkdir -p "$CONTENTS"

# Info.plist — Finder 서비스 메뉴 항목 정의
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>${MENU_LABEL}</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.item</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
PLIST

# document.wflow — 실제 동작(선택된 파일들을 인자로 받아 변환 엔진 실행 + 결과 알림)
# ※ 따옴표 heredoc('WFLOW') 이므로 아래 셸 변수($HOME 등)는 설치 시점이 아니라
#   Quick Action 실행 시점에 평가됩니다.
cat > "$CONTENTS/document.wflow" <<'WFLOW'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>528</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>"$HOME/Library/Application Support/euckr2utf8/quick-action.sh" "$@"</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.Automator.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>C4E3B8F2-1A2B-4C3D-9E4F-000000000001</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>C4E3B8F2-1A2B-4C3D-9E4F-000000000002</string>
				<key>UUID</key>
				<string>C4E3B8F2-1A2B-4C3D-9E4F-000000000003</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>309.000000:253.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleIDsByPath</key>
		<dict/>
		<key>applicationPaths</key>
		<array/>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>presentationMode</key>
		<integer>11</integer>
		<key>processesInput</key>
		<integer>0</integer>
		<key>serviceApplicationBundleID</key>
		<string></string>
		<key>serviceApplicationPath</key>
		<string></string>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<integer>0</integer>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
WFLOW

echo "[3/3] plist 검증 및 서비스 새로고침"
plutil -lint "$CONTENTS/Info.plist"      >/dev/null && echo "  Info.plist OK"
plutil -lint "$CONTENTS/document.wflow"  >/dev/null && echo "  document.wflow OK"

# 서비스 목록 새로고침
/System/Library/CoreServices/pbs -update 2>/dev/null || true
/System/Library/CoreServices/pbs -flush  2>/dev/null || true

cat <<DONE

────────────────────────────────────────────────────────
✅ 설치 완료

사용법:
  Finder 에서 변환할 .xls/.csv 파일(들) 선택
  → 우클릭 → "빠른 동작(Quick Actions)"
  → "${MENU_LABEL}" 클릭
  → 완료 알림창 확인

  ▪ 폴더를 선택하면 그 안의 xls/csv/tsv/txt/html/xml 을 한꺼번에 변환합니다.
  ▪ 이미 UTF-8 인 파일은 자동으로 건너뜁니다(여러 번 눌러도 안전).

메뉴가 바로 안 보이면:
  ▪ Finder 를 한 번 재실행:  killall Finder
  ▪ 또는 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램
    → 추가 기능(Finder 확장/빠른 동작)에서 활성화 확인

제거:  ./uninstall.sh
────────────────────────────────────────────────────────
DONE
