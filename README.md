# codex-search

Claude Code用スキル: Codex CLIを使ったWeb検索 + 成果物自動保存

検索結果を `.md` / `.json` / `.txt` の3形式でタイムスタンプ付きで自動保存します。

## 注釈

本スキルは [HayattiQ/x-research-skills](https://github.com/HayattiQ/x-research-skills) を参考に作成されました。

## インストール

```bash
# スキルディレクトリにコピー
mkdir -p ~/.claude/skills
cp -r ./ ~/.claude/skills/codex-search

# スクリプトに実行権限を付与
chmod +x ~/.claude/skills/codex-search/scripts/codex_search.sh
```

## 使い方

```
/codex-search <検索キーワード>
/codex-search <検索キーワード> --out-dir ~/my-research
/codex-search <検索キーワード> --dry-run
```

### 例

```
/codex-search Claude Code の最新アップデート情報
/codex-search TypeScript 5.8 新機能まとめ
/codex-search AIエージェント開発 ベストプラクティス 2026
/codex-search React Server Components パフォーマンス比較
```

## 機能

- **安定版**: `codex exec` を使用（MCP経由より安定）
- **ログ可視**: 実行プロセスが見えるため、途中で止まらない
- **日本語OK**: 自然な日本語で検索可能
- **成果物の自動保存**: 検索結果を3形式で自動保存、後から参照可能

## 出力

`~/.claude/data/codex-search/` に以下が保存されます:
- `YYYYMMDD_HHMMSSZ_search.md` - Metaヘッダ + 検索結果本文
- `YYYYMMDD_HHMMSSZ_search.json` - クエリ・レスポンス・メタデータ
- `YYYYMMDD_HHMMSSZ_search.txt` - プレーンテキスト結果

## 依存関係

- [Codex CLI](https://github.com/anthropics/codex) がインストール済みであること
- `codex exec` が使用できること

## ライセンス

MIT
