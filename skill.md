---
name: codex-search
description: Codex CLI を使った Web 検索 + 成果物自動保存。検索結果を .md/.json/.txt の3形式でタイムスタンプ付き保存。
argument-hint: <検索キーワード> [--out-dir DIR] [--dry-run]
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Codex Search Skill (Web検索 + 成果物保存)

Codex CLI (`codex exec`) を使った Web 検索スキル。検索結果を `.md` / `.json` / `.txt` の3形式でタイムスタンプ付きで自動保存する。

## 使い方

```
/codex-search <検索キーワード>
/codex-search <検索キーワード> --out-dir ~/my-research
/codex-search <検索キーワード> --dry-run
```

## 例

```
/codex-search Claude Code の最新アップデート情報
/codex-search TypeScript 5.8 新機能まとめ
/codex-search AIエージェント開発 ベストプラクティス 2026
/codex-search React Server Components パフォーマンス比較
/codex-search Large Language Machines Survey 2024
/codex-search Transformer architecture attention mechanisms 論文
```

## 期待される挙動

1. ユーザーから受け取ったキーワードを `--query` に渡す
2. オプション（`--out-dir`, `--dry-run`）があればそれも渡す
3. **必ず以下のラッパースクリプトを実行する**（`codex exec` を直接実行してはならない）:

```bash
bash ~/.claude/skills/codex-search/scripts/codex_search.sh --query "<クエリ>" [オプション]
```

4. **重要: Bash 実行時は `timeout: 200000` を必ず指定する**
5. 実行結果の検索結果をユーザーに表示する
6. 成果物が保存されたことを確認する:

```bash
ls -la ~/.claude/data/codex-search/ | tail -5
```

7. 保存されたファイルのパスをユーザーに報告する

## オプション

| オプション | デフォルト | 説明 |
|-----------|----------|------|
| `--query` | (必須) | 検索クエリ |
| `--out-dir` | `~/.claude/data/codex-search` | 成果物の保存先ディレクトリ |
| `--dry-run` | - | 実行コマンドを表示して終了 |

## 出力

`~/.claude/data/codex-search/` に以下が保存される:
- `YYYYMMDD_HHMMSSZ_search.md` (検索結果 Markdown)
- `YYYYMMDD_HHMMSSZ_search.json` (クエリ・レスポンス・メタデータ)
- `YYYYMMDD_HHMMSSZ_search.txt` (プレーンテキスト抽出)

## 特徴

- **安定版**: `codex exec` を使用（MCP経由より安定）
- **ログ可視**: 実行プロセスが見えるため、途中で止まらない
- **日本語OK**: 自然な日本語で検索可能
- **成果物自動保存**: 検索結果を3形式で自動保存、後から参照可能
- **DOI抽出対応**: 文献検索時に論文の DOI (Digital Object Identifier) を自動抽出

## 注意

- **codex exec を直接実行しないこと**。必ずラッパースクリプト経由で実行する（ログ保存のため）
- Bash実行時は `timeout: 200000` を指定すること
- Codex CLI がインストール済みであること（`codex exec` が使えること）
- 検索結果の品質は Codex のモデルとWeb検索能力に依存する
