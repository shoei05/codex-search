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

set -uo pipefail
# Note: -e を外す。保存フェーズのエラーでスクリプト全体を中断させないため

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
  - Details (詳細な調査結果)

【重要】文献検索（論文・学術記事）の場合:
- 見つかった論文・記事ごとに必ず DOI (Digital Object Identifier) を抽出して記載してください
- DOI は通常「10.xxxx/...」の形式です
- DOI が見つからない場合は「DOI: なし」と明記してください
- 出力形式例:
  ## 論文1
  - タイトル: xxx
  - 著者: xxx
  - DOI: 10.xxxx/xxx
  - URL: https://doi.org/10.xxxx/xxx"

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
# macOS には timeout コマンドがないため、利用可能な方法を選択
RESULT=""
EXEC_OK=false
if command -v timeout &>/dev/null; then
  RESULT=$(timeout "${TIMEOUT}" "${CODEX_CMD[@]}" 2>&1) && EXEC_OK=true || {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
      echo "Warning: codex exec timed out after ${TIMEOUT}s" >&2
    else
      echo "Warning: codex exec exited with code ${EXIT_CODE}" >&2
    fi
    # 部分的な出力でも保存を試みる
  }
elif command -v gtimeout &>/dev/null; then
  RESULT=$(gtimeout "${TIMEOUT}" "${CODEX_CMD[@]}" 2>&1) && EXEC_OK=true || {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
      echo "Warning: codex exec timed out after ${TIMEOUT}s" >&2
    else
      echo "Warning: codex exec exited with code ${EXIT_CODE}" >&2
    fi
  }
else
  RESULT=$("${CODEX_CMD[@]}" 2>&1) && EXEC_OK=true || {
    EXIT_CODE=$?
    echo "Warning: codex exec exited with code ${EXIT_CODE}" >&2
  }
fi

# 結果が空の場合でも保存フェーズに進む（メタデータだけでも記録する）
if [[ -z "$RESULT" ]]; then
  echo "Warning: codex exec returned empty result" >&2
  RESULT="(empty result)"
fi

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
# stdin 経由で RESULT を渡す（ARG_MAX 超え回避）
echo "${RESULT}" | python3 -c "
import json, sys
result_text = sys.stdin.read()
data = {
    'query': sys.argv[1],
    'timestamp': sys.argv[2],
    'params': {
        'out_dir': sys.argv[3],
        'timeout': int(sys.argv[4]),
    },
    'result': result_text.rstrip('\n'),
}
print(json.dumps(data, ensure_ascii=False, indent=2))
" "${QUERY}" "${TIMESTAMP_ISO}" "${OUT_DIR}" "${TIMEOUT}" > "${JSON_FILE}" 2>/dev/null || {
  echo "Warning: JSON save failed, falling back to plain text" >&2
  # フォールバック: python3 が失敗した場合は簡易 JSON
  printf '{"query":"%s","timestamp":"%s","result":"(see .txt file)"}\n' \
    "${QUERY}" "${TIMESTAMP_ISO}" > "${JSON_FILE}"
}

# --- save .txt ---
TXT_FILE="${OUT_DIR}/${TIMESTAMP_SLUG}_search.txt"
echo "${RESULT}" > "${TXT_FILE}"

# --- verify & report saved paths ---
SAVE_COUNT=0
for f in "${MD_FILE}" "${JSON_FILE}" "${TXT_FILE}"; do
  if [[ -f "$f" && -s "$f" ]]; then
    echo "Saved: ${f}" >&2
    SAVE_COUNT=$((SAVE_COUNT + 1))
  else
    echo "Warning: Failed to save ${f}" >&2
  fi
done

echo "" >&2
echo "=== Save Summary ===" >&2
echo "Files saved: ${SAVE_COUNT}/3" >&2
echo "Directory: ${OUT_DIR}" >&2
echo "Timestamp: ${TIMESTAMP_SLUG}" >&2

# --- output result to stdout ---
echo "${RESULT}"
