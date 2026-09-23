# EUC-KR → UTF-8 Converter (Korean text stays intact)

[한국어](README.md) | **English**

Converts the **contents** of Korean legacy-encoded files — such as the `.xls` exports from
Korean card companies and banking sites (which are actually EUC-KR encoded XML/HTML) —
to **UTF-8** without garbling Korean text. **The filename stays the same; only the contents change.**

On macOS you can run it with one click from the **Finder right-click → Quick Actions** menu.

---

## Why a plain conversion isn't enough

These files declare their encoding on the first line:

```xml
<?xml version='1.0' encoding='EUC-KR'?>       ← XML (Excel 2003 SpreadsheetML)
<meta ... charset=euc-kr>                     ← HTML
```

If you convert only the bytes to UTF-8 and **leave that declaration as is**, Excel and browsers
read the UTF-8 bytes as EUC-KR again and the text **gets even more garbled**.
This tool therefore does both: **① convert the bytes and ② rewrite the encoding declaration to UTF-8**.

---

## Install (right-click menu)

```bash
git clone https://github.com/mebaser/euckr-utf8-trans.git
cd euckr-utf8-trans
./install-quick-action.sh
```

After installing:

1. Select the file(s) to convert in Finder
2. **Right-click → Quick Actions → "EUC-KR → UTF-8 변환"**
3. Check the result in the completion dialog (`완료: 변환 N · 건너뜀 M · 실패 K` = done: converted N · skipped M · failed K)

> If the menu doesn't show up right away, restart Finder with `killall Finder`.
> (Or check that it's enabled under System Settings → General → Login Items & Extensions → Quick Actions.)

**Uninstall:** `./uninstall.sh`

---

## Command-line usage

```bash
# One or more files
./euckr2utf8.sh statement.xls

# A whole folder (recursively converts xls/csv/tsv/txt/html/xml inside)
./euckr2utf8.sh ~/Downloads/statements/

# Options
./euckr2utf8.sh --dry-run folder/    # preview targets without changing anything
./euckr2utf8.sh --backup  file.xls   # keep the original as file.xls.bak, then convert
```

---

## Features and safeguards

- **Supported formats**: Excel 2003 XML (.xls), HTML tables (.xls/.html), CSV/TSV, plain text
- **Source encoding**: CP949 (a superset of EUC-KR) first, falling back to EUC-KR automatically
- **Idempotent**: files already in UTF-8 are **skipped automatically**, so running it twice is safe
- **Fail-safe**: if conversion or verification fails, the **original is never overwritten**
- **Keeps permissions**: only the contents are replaced; the original file mode is kept
- **No dependencies**: uses only the `iconv` and `perl` that ship with macOS (no Python needed)

---

## Files

| File | Description |
|------|-------------|
| `euckr2utf8.sh` | Conversion engine (works on its own from the terminal) |
| `quick-action.sh` | Right-click wrapper (runs the conversion and shows the result dialog without garbled Korean) |
| `install-quick-action.sh` | Installs the Finder right-click Quick Action |
| `uninstall.sh` | Removes the Quick Action and installed files |

On install, the engine is copied to `~/Library/Application Support/euckr2utf8/`
and the Quick Action to `~/Library/Services/EUCKR-to-UTF8.workflow`.

---

## License

MIT
