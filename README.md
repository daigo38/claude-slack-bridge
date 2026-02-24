# Claude Code ⇔ Slack Bridge

Mac上で動くClaude Codeを、Slackから監視・操作するブリッジ。
複数タスクの同時実行に対応。

- **DMモード**: 管理者がスマホからDMで操作（メンション不要）
- **チャンネルモード**: チームメンバーがチャンネルで `@bot` メンションして操作

## こんなとき便利

- トイレや休憩で席を離れるとき → スマホで進捗確認＆新しい指示
- 長時間タスクの完了通知をスマホで受け取りたい
- 移動中にふと思いついたタスクをすぐ投入したい
- チームメンバーと1台のMac上のClaude Codeを共有して使いたい

## セキュリティに関する注意

このツールはSlack経由で **ローカルMac上のClaude Code（=シェル実行が可能なCLI）をリモート操作** します。以下の点を理解した上でご利用ください。

- **管理者**: `.env` の `ADMIN_SLACK_USER_ID` に設定したユーザーのみがDMモードを使用できます
- **チャンネルモード**: `SLACK_ALLOWED_USERS` / `SLACK_ALLOWED_CHANNELS` で許可されたユーザー・チャンネルのみ応答します。`*`（全許可）を設定する場合は、botが意図しないチャンネルに招待されるリスクに注意してください
- **トークン管理**: `SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN` が漏洩すると、第三者がBotを通じてClaude Codeを操作できる可能性があります。`.env` ファイルの権限を適切に設定し、Gitにコミットしないでください
- **許可ツールの設定**: `DEFAULT_ALLOWED_TOOLS` はClaude Codeが自動承認するツールを制御します。`Bash(*)` を設定すると任意のシェルコマンドが自動実行されます。必要最小限のツールのみ許可することを推奨します
- **自分のMac専用**: 共有サーバーやCI環境での利用は想定していません
- **共有設定**: `cd` や `tools` コマンドの設定はプロセス全体で共有されます。チャンネルモードでは他のユーザーの設定変更が自分のタスクに影響する場合があります

## 仕組み

```
┌──────────┐   Socket Mode    ┌───────────────┐    subprocess ×N   ┌────────────┐
│  あなた   │ ─────────────► │               │ ──────────────► │ Claude Code│
│ (スマホ)  │   DM / Channel  │    Bridge     │                  │   (CLI)    │
└──────────┘                  │  (Mac上で動作)  │ ──────────────► ├────────────┤
                              │               │                  │ Claude Code│
                              └───────────────┘                  │   (CLI)    │
                                      │                          └────────────┘
```

**ポイント:** Socket Modeを使うので、公開URL・ポートフォワード一切不要。

## セットアップ

### 1. Slack App を作成

1. [Slack API](https://api.slack.com/apps) にアクセス → **Create New App** → **From scratch**
2. アプリ名（例: `Claude Code Bridge`）とワークスペースを選択

#### Socket Mode を有効化
1. 左メニュー **Socket Mode** → **Enable Socket Mode**
2. Token Name に `claude-bridge` と入力 → **Generate**
3. 表示される `xapp-...` トークンをコピー → `.env` の `SLACK_APP_TOKEN` に設定

#### Bot Token Scopes を追加
1. 左メニュー **OAuth & Permissions** → **Scopes** → **Bot Token Scopes** に以下を追加:
   - `chat:write` — メッセージ送信
   - `im:history` — DM履歴読み取り
   - `im:write` — DM送信
   - `files:write` — ファイル送信（結果が大きい場合用）

チャンネルモードを使う場合は追加で:
   - `channels:history` — パブリックチャンネルのメッセージ読み取り
   - `groups:history` — プライベートチャンネルのメッセージ読み取り

#### Event Subscriptions を設定
1. 左メニュー **Event Subscriptions** → **Enable Events**
2. **Subscribe to bot events** に以下を追加:
   - `message.im`

チャンネルモードを使う場合は追加で:
   - `message.channels` — パブリックチャンネルのメッセージ
   - `message.groups` — プライベートチャンネルのメッセージ

#### Install App
1. 左メニュー **Install App** → **Install to Workspace** → 許可
2. **Bot User OAuth Token** (`xoxb-...`) をコピー → `.env` の `SLACK_BOT_TOKEN` に設定

### 2. プロジェクトのセットアップ

```bash
cd /path/to/claude-slack-bridge

# 仮想環境を作成（推奨）
python3 -m venv venv
source venv/bin/activate

# 依存パッケージをインストール
pip install -r requirements.txt

# 設定ファイルを準備
cp .env.example .env
```

### 3. `.env` を編集

```bash
# 必須
SLACK_BOT_TOKEN=xoxb-xxxxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx
SLACK_APP_TOKEN=xapp-1-xxxxxxxxxxxx-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 管理者のSlackユーザーID（必須）
# 自分のプロフィール → … → Copy member ID
ADMIN_SLACK_USER_ID=U0123456789

# Claude Code の作業ディレクトリ
WORKING_DIR=/Users/yourname/projects/my-project

# 自動承認ツール（プロジェクトに合わせて調整）
DEFAULT_ALLOWED_TOOLS=Read,Write,Edit,MultiEdit,Bash(git *),TodoWrite
```

**ユーザーIDの確認方法:** Slackで自分のプロフィールを開く → 「…」→ 「メンバーIDをコピー」

### 4. 起動

```bash
python bridge.py
```

起動するとDMに通知が届きます:
> :rocket: **Claude Code Bridge が起動しました**
> デフォルト作業ディレクトリ: `/Users/yourname/projects/my-project`

## 使い方（DMモード）

BotにDMを送信するだけ。`@bot` のメンションは不要です。管理者のみ利用可能。

## 使い方（チャンネルモード）

`.env` で `SLACK_ALLOWED_USERS` と `SLACK_ALLOWED_CHANNELS` を設定した上で、botをチャンネルに招待します。チャンネルでは `@bot` メンション付きでコマンドを送信します。

```bash
# .env の設定例
SLACK_ALLOWED_USERS=U1111111111,U2222222222   # 特定ユーザーのみ
SLACK_ALLOWED_CHANNELS=C3333333333             # 特定チャンネルのみ

# または全許可
SLACK_ALLOWED_USERS=*
SLACK_ALLOWED_CHANNELS=*
```

タスクのSlackスレッドへの返信はメンション不要でCLIに転送されます。

### コマンド一覧

| コマンド | 説明 |
|---------|------|
| `<タスク内容>` | 新しいタスクを実行 |
| `in ~/other-project テスト書いて` | 指定ディレクトリで実行 |
| `continue テストも追加して` | 直前セッションを続行 |
| `continue #2 エラーを修正して` | 指定タスクのセッションを続行 |
| `resume <session_id> エラーを修正して` | 指定セッションを再開 |
| `status` | 全タスクの状態一覧 |
| `cancel #2` | タスクをキャンセル |
| `cancel all` | 全タスクをキャンセル |
| `cd /path/to/project` | 作業ディレクトリを変更 |
| `tools Read,Write,Bash(*)` | 次タスクの許可ツールを設定 |
| `sessions` | セッション履歴 |
| `detect` | 実行中のclaude CLIインスタンスを検出・接続 |
| `help` | ヘルプ表示 |

チャンネルモードでは各コマンドの前に `@bot` が必要です（例: `@bot status`）。

### 典型的なワークフロー

各タスクは1つのSlackスレッドに対応します。
`continue` するとスレッド内に続行メッセージが追加され、会話の流れが一目でわかります。

```
あなた: エラーハンドリングを改善して

━━ DM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔵 #1  タスク開始
  📂 api
  └─ スレッド (3件)
     ├─ 🔵 #1  ⏳ 実行中... ツール: Read → Edit
     ├─ 🔵 #1  ✅ タスク完了 (45秒)
     │     `continue #1 <指示>` で続行
     │
     │  ← ここから continue #1 の続き ─────────
     │
     ├─ 🔵 #3  ▶️ セッション続行
     │     テストも書いて。jest を使って
     ├─ 🔵 #3  ⏳ 実行中... ツール: Read → Write
     └─ 🔵 #3  ✅ タスク完了 (30秒)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### detect: 実行中のClaude CLIに接続

`detect` コマンドを使うと、Mac上で既に動いているClaude CLIプロセスを検出し、Slackスレッドから操作できるようになります。

```
あなた: detect
Bot:    🔍 2件の新しいclaude CLIインスタンスを検出・登録しました
```

検出されたインスタンスごとにスレッドが作成され、スレッドに返信することでそのCLIに入力を送れます。Bridge起動時にも自動検出が行われます。

## 許可ツールの設定

`DEFAULT_ALLOWED_TOOLS` の設定例:

```bash
# 保守的（読み取り中心）
DEFAULT_ALLOWED_TOOLS=Read,TodoWrite

# 標準的（ファイル編集 + git操作）
DEFAULT_ALLOWED_TOOLS=Read,Write,Edit,MultiEdit,Bash(git *),TodoWrite

# 積極的（ほぼ全操作を自動承認）
DEFAULT_ALLOWED_TOOLS=Read,Write,Edit,MultiEdit,Bash(*),TodoWrite,WebSearch,WebFetch
```

`tools` コマンドで一時的に変更も可能（次の1タスクのみ有効）:
```
tools Read,Write,Edit,Bash(*)
npm run build の結果を見てエラーを修正して
```

> **注意（チャンネルモード）:** `tools` コマンドの設定はプロセス全体で共有されます。ユーザーAが `tools` を設定した直後にユーザーBがタスクを投入すると、Bのタスクがその設定を消費する可能性があります。

## トラブルシューティング

### Bridge が起動しない
- `SLACK_BOT_TOKEN` と `SLACK_APP_TOKEN` が正しいか確認
- Socket Mode が有効になっているか確認
- `pip install -r requirements.txt` でパッケージがインストール済みか確認

### Bot が反応しない
- **DMモード**: BotにDMを送っているか確認。`.env` の `ADMIN_SLACK_USER_ID` が自分のIDか確認
- **チャンネルモード**: `SLACK_ALLOWED_USERS` と `SLACK_ALLOWED_CHANNELS` が設定されているか確認。`message.channels` イベントが購読されているか確認。botがチャンネルに招待されているか確認
- ターミナルにエラーが出ていないか確認

### Claude Code がエラーになる
- `which claude` でclaude コマンドのパスを確認
- `WORKING_DIR` が存在するか確認
- ターミナルで `claude -p "hello" --output-format json` が動くか確認
- Claude Code の認証が有効か確認（`claude` を直接起動して確認）

### 日本語が文字化けする
- `.env` に `LANG=en_US.UTF-8` を追加してみる
- Python 3.9 以上を使用しているか確認

## 自動起動 (macOS)

Mac起動時に自動で立ち上げたい場合、LaunchAgent を使えます:

```bash
cat << 'EOF' > ~/Library/LaunchAgents/com.claude-slack-bridge.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude-slack-bridge</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/venv/bin/python</string>
        <string>/path/to/claude-slack-bridge/bridge.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/path/to/claude-slack-bridge</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/claude-slack-bridge.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-slack-bridge.err</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.claude-slack-bridge.plist
```

## ライセンス

MIT
