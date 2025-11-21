---
created: 2025-06-06T10:30
updated: 2025-06-12T18:40
---
# トラブルシューティング

> Claude Codeのインストールと使用に関する一般的な問題の解決策。

## 一般的なインストールの問題

### Linuxの権限の問題

npmでClaude Codeをインストールする際、npmのグローバルプレフィックスがユーザーによって書き込み可能でない場合（例：`/usr`や`/usr/local`）、権限エラーが発生することがあります。

#### 推奨される解決策：ユーザーが書き込み可能なnpmプレフィックスを作成する

最も安全なアプローチは、ホームフォルダ内のディレクトリを使用するようにnpmを設定することです：

```bash
# まず、既存のグローバルパッケージのリストを後で移行するために保存します
npm list -g --depth=0 > ~/npm-global-packages.txt

# グローバルパッケージ用のディレクトリを作成します
mkdir -p ~/.npm-global

# 新しいディレクトリパスを使用するようにnpmを設定します
npm config set prefix ~/.npm-global

# 注意：~/.bashrcを、お使いのシェルに応じて~/.zshrc、~/.profile、または他の適切なファイルに置き換えてください
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc

# 新しいPATH設定を適用します
source ~/.bashrc

# これで新しい場所にClaude Codeを再インストールします
npm install -g @anthropic-ai/claude-code

# オプション：以前のグローバルパッケージを新しい場所に再インストールします
# ~/npm-global-packages.txtを確認し、保持したいパッケージをインストールします
```

この解決策が推奨される理由：

* システムディレクトリの権限を変更する必要がない
* グローバルnpmパッケージ用の専用の場所を作成する
* セキュリティのベストプラクティスに従っている

#### システム復旧：システムファイルの所有権と権限を変更するコマンドを実行した場合

システムディレクトリの権限を変更するコマンド（例：`sudo chown -R $USER:$(id -gn) /usr && sudo chmod -R u+w /usr`）を既に実行してシステムが破損している場合（例えば、`sudo: /usr/bin/sudo must be owned by uid 0 and have the setuid bit set`というエラーが表示される場合）、復旧手順を実行する必要があります。

##### Ubuntu/Debian復旧方法：

1. 再起動中にSHIFTキーを押し続けてGRUBメニューにアクセスします

2. 「Advanced options for Ubuntu/Debian」を選択します

3. リカバリーモードのオプションを選択します

4. 「Drop to root shell prompt」を選択します

5. ファイルシステムを書き込み可能として再マウントします：
   ```bash
   mount -o remount,rw /
   ```

6. 権限を修正します：

   ```bash
   # rootの所有権を復元します
   chown -R root:root /usr
   chmod -R 755 /usr

   # npmパッケージ用に/usr/localがあなたのユーザーによって所有されていることを確認します
   chown -R YOUR_USERNAME:YOUR_USERNAME /usr/local

   # 重要なバイナリにsetuidビットを設定します
   chmod u+s /usr/bin/sudo
   chmod 4755 /usr/bin/sudo
   chmod u+s /usr/bin/su
   chmod u+s /usr/bin/passwd
   chmod u+s /usr/bin/newgrp
   chmod u+s /usr/bin/gpasswd
   chmod u+s /usr/bin/chsh
   chmod u+s /usr/bin/chfn

   # sudo設定を修正します
   chown root:root /usr/libexec/sudo/sudoers.so
   chmod 4755 /usr/libexec/sudo/sudoers.so
   chown root:root /etc/sudo.conf
   chmod 644 /etc/sudo.conf
   ```

7. 影響を受けたパッケージを再インストールします（オプションですが推奨）：

   ```bash
   # インストールされているパッケージのリストを保存します
   dpkg --get-selections > /tmp/installed_packages.txt

   # それらを再インストールします
   awk '{print $1}' /tmp/installed_packages.txt | xargs -r apt-get install --reinstall -y
   ```

8. 再起動します：
   ```bash
   reboot
   ```

##### 代替のライブUSB復旧方法：

リカバリーモードが機能しない場合は、ライブUSBを使用できます：

1. ライブUSB（Ubuntu、Debian、または任意のLinuxディストリビューション）から起動します

2. システムパーティションを見つけます：
   ```bash
   lsblk
   ```

3. システムパーティションをマウントします：
   ```bash
   sudo mount /dev/sdXY /mnt  # sdXYを実際のシステムパーティションに置き換えてください
   ```

4. 別のブートパーティションがある場合は、それもマウントします：
   ```bash
   sudo mount /dev/sdXZ /mnt/boot  # 必要な場合
   ```

5. システムにchrootします：

   ```bash
   # Ubuntu/Debian向け：
   sudo chroot /mnt

   # Archベースのシステム向け：
   sudo arch-chroot /mnt
   ```

6. 上記のUbuntu/Debian復旧方法のステップ6〜8に従います

システムを復元した後、上記の推奨される解決策に従って、ユーザーが書き込み可能なnpmプレフィックスを設定してください。

## 自動更新の問題

Claude Codeが自動的に更新できない場合、npmのグローバルプレフィックスディレクトリの権限の問題が原因である可能性があります。この問題を解決するには、上記の[推奨される解決策](#推奨される解決策ユーザーが書き込み可能なnpmプレフィックスを作成する)に従ってください。

代わりに自動更新を無効にしたい場合は、
`DISABLE_AUTOUPDATER` [環境変数](settings#environment-variables)を`1`に設定することができます

## 権限と認証

### 繰り返される権限プロンプト

同じコマンドを繰り返し承認する必要がある場合は、`/permissions`コマンドを使用して特定のツールが承認なしで実行できるようにすることができます。[権限のドキュメント](settings#permissions)を参照してください。

### 認証の問題

認証の問題が発生している場合：

1. `/logout`を実行して完全にサインアウトします
2. Claude Codeを閉じます
3. `claude`で再起動し、認証プロセスを再度完了します

問題が解決しない場合は、次を試してください：

```bash
rm -rf ~/.config/claude-code/auth.json
claude
```

これにより保存された認証情報が削除され、クリーンなログインが強制されます。

## パフォーマンスと安定性

### 高いCPUまたはメモリ使用量

Claude Codeはほとんどの開発環境で動作するように設計されていますが、大規模なコードベースを処理する際に大量のリソースを消費する可能性があります。パフォーマンスの問題が発生している場合：

1. コンテキストサイズを減らすために定期的に`/compact`を使用します
2. 主要なタスク間でClaude Codeを閉じて再起動します
3. 大きなビルドディレクトリを`.gitignore`ファイルに追加することを検討してください

### コマンドがハングまたはフリーズする

Claude Codeが応答しない場合：

1. Ctrl+Cを押して現在の操作をキャンセルしてみてください
2. 応答しない場合は、ターミナルを閉じて再起動する必要があるかもしれません

### JetBrains（IntelliJ、PyCharmなど）のターミナルでESCキーが機能しない

JetBrainsのターミナルでClaude Codeを使用していて、ESCキーが期待通りにエージェントを中断しない場合、これはJetBrainsのデフォルトのショートカットとのキーバインディングの衝突が原因である可能性があります。

この問題を解決するには：

1. 設定 → ツール → ターミナルに移動します
2. 「Override IDE Shortcuts」の横にある「Configure terminal keybindings」ハイパーリンクをクリックします
3. ターミナルのキーバインディング内で、「Switch focus to Editor」までスクロールし、そのショートカットを削除します

これにより、ESCキーがPyCharmの「Switch focus to Editor」アクションによってキャプチャされるのではなく、Claude Codeの操作をキャンセルするために適切に機能するようになります。

## さらなるヘルプを得る

ここで説明されていない問題が発生している場合：

1. Claude Code内で`/bug`コマンドを使用して、問題を直接Anthropicに報告します
2. 既知の問題については[GitHubリポジトリ](https://github.com/anthropics/claude-code)を確認してください
3. Claude Codeのインストールの健全性を確認するために`/doctor`を実行します
