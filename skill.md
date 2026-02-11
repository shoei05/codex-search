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
```

## 期待される挙動

1. ユーザーからクエリを受け取る
2. ラッパースクリプトを実行:

```bash
bash ~/.claude/skills/codex-search/scripts/codex_search.sh --query "<クエリ>" [オプション]
```

3. 検索結果を表示する
4. 成果物は `~/.claude/data/codex-search/` に自動保存される

## オプション

| オプション | デフォルト | 説明 |
|-----------|----------|------|
| `--query` | (必須) | 検索クエリ |
| `--out-dir` | `~/.claude/data/codex-search` | 成果物の保存先ディレクトリ |
| `--dry-run` | - | 実行コマンドを表示して終了 |

## 出力

`~/.claude/data/codex-search/` に以下が保存される:
- `YYYYMMDD_HHMMSS_search.md` (検索結果 Markdown)
- `YYYYMMDD_HHMMSS_search.json` (クエリ・レスポンス・メタデータ)
- `YYYYMMDD_HHMMSS_search.txt` (プレーンテキスト抽出)

## 特徴

- **安定版**: `codex exec` を使用（MCP経由より安定）
- **ログ可視**: 実行プロセスが見えるため、途中で止まらない
- **日本語OK**: 自然な日本語で検索可能
- **成果物自動保存**: 検索結果を3形式で自動保存、後から参照可能

## 注意

- Bash実行時は `timeout: 200000` を指定すること
- Codex CLI がインストール済みであること（`codex exec` が使えること）
- 検索結果の品質は Codex のモデルとWeb検索能力に依存する
