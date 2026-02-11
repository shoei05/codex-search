#!/bin/bash
# codex_search.sh - Codex CLI Web検索 + 成果物保存ラッパー
#
# Usage: bash codex_search.sh --query "検索キーワード" [--out-dir DIR] [--dry-run]
#
# Options:
#   --query TEXT    検索キーワード (必須)
#   --out-dir DIR   保存先ディレクトリ (デフォルト: ~/.claude/data/codex-search)
#   --dry-run       コマンドを表示して終了
#
# 出力:
#   stdout: 検索結果テキスト
#   stderr: 保存先ファイルパス
#   保存ファイル (3形式):
#     YYYYMMDD_HHMMSSZ_search.md   - Metaヘッダ + 検索結果本文
#     YYYYMMDD_HHMMSSZ_search.json - query, timestamp, params, result (JSON)
#     YYYYMMDD_HHMMSSZ_search.txt  - プレーンテキスト結果

set -euo pipefail

# --- defaults ---
QUERY=""
OUT_DIR="${HOME}/.claude/data/codex-search"
DRY_RUN=false
TIMEOUT=120

# --- parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      QUERY="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      sed -n '2,/^$/s/^# \?//p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- validate ---
if [[ -z "$QUERY" ]]; then
  echo "Error: --query is required." >&2
  echo "Usage: bash $0 --query \"検索キーワード\" [--out-dir DIR] [--dry-run]" >&2
  exit 2
fi

# --- timestamp (UTC) ---
TIMESTAMP_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TIMESTAMP_SLUG=$(date -u +"%Y%m%d_%H%M%SZ")

# --- build codex prompt ---
CODEX_PROMPT="Web検索を行い、以下のクエリについて詳細な情報を収集してください。

検索クエリ: ${QUERY}

要件:
- 公式ドキュメント、公式ブログ、仕様、GitHub等の一次情報を優先
- 数字・仕様・制限は捏造しない。不明は unknown と書く
- 情報の参照日を明記する
- 検索結果をMarkdown形式で構造化して出力
- 出力に含める見出し:
  - Summary (1-3文の要約)
  - Key Findings (箇条書き)
  - Sources (URL list)
  - Details (詳細な調査結果)"

# --- codex command ---
CODEX_CMD=(codex exec --skip-git-repo-check "$CODEX_PROMPT")

# --- dry-run ---
if [[ "$DRY_RUN" == true ]]; then
  echo "=== Dry Run ===" >&2
  echo "Query:     ${QUERY}" >&2
  echo "Out Dir:   ${OUT_DIR}" >&2
  echo "Timestamp: ${TIMESTAMP_SLUG}" >&2
  echo "Timeout:   ${TIMEOUT}s" >&2
  echo "" >&2
  echo "Command:" >&2
  printf '  %q' "${CODEX_CMD[@]}" >&2
  echo "" >&2
  exit 0
fi

# --- execute codex ---
RESULT=$(timeout "${TIMEOUT}" "${CODEX_CMD[@]}" 2>/dev/null) || {
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 ]]; then
    echo "Error: codex exec timed out after ${TIMEOUT}s" >&2
  else
    echo "Error: codex exec failed with exit code ${EXIT_CODE}" >&2
  fi
  exit $EXIT_CODE
}

# --- ensure output directory ---
mkdir -p "${OUT_DIR}"

# --- save .md ---
MD_FILE="${OUT_DIR}/${TIMESTAMP_SLUG}_search.md"
{
  echo "# Codex Search Result"
  echo ""
  echo "## Meta"
  echo "- Timestamp (UTC): ${TIMESTAMP_ISO}"
  echo "- Query: ${QUERY}"
  echo ""
  echo "---"
  echo ""
  echo "${RESULT}"
} > "${MD_FILE}"

# --- save .json ---
JSON_FILE="${OUT_DIR}/${TIMESTAMP_SLUG}_search.json"
# Use python3 for reliable JSON encoding (handles special chars, newlines)
python3 -c "
import json, sys
data = {
    'query': sys.argv[1],
    'timestamp': sys.argv[2],
    'params': {
        'out_dir': sys.argv[3],
        'timeout': int(sys.argv[4]),
    },
    'result': sys.argv[5],
}
print(json.dumps(data, ensure_ascii=False, indent=2))
" "${QUERY}" "${TIMESTAMP_ISO}" "${OUT_DIR}" "${TIMEOUT}" "${RESULT}" > "${JSON_FILE}"

# --- save .txt ---
TXT_FILE="${OUT_DIR}/${TIMESTAMP_SLUG}_search.txt"
echo "${RESULT}" > "${TXT_FILE}"

# --- report saved paths to stderr ---
echo "Saved: ${MD_FILE}" >&2
echo "Saved: ${JSON_FILE}" >&2
echo "Saved: ${TXT_FILE}" >&2

# --- output result to stdout ---
echo "${RESULT}"
