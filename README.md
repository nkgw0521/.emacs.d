# Emacs 30 Configuration  
Windows + MSYS2 + GNU GLOBAL + Eglot + GTAGS IDE

このリポジトリは、Windows 環境で C 開発を行うために最適化された  
**Emacs 30 の完全カスタム IDE 設定**です。

特徴:

- **C-o：GTAGS → xref → LSP の最強ジャンプ**
- **M-t / M-r / M-s：override-map により絶対に奪われないジャンプキー**
- **GTAGS が無いときは昔の ggtags のように “ルートを聞く” 対話式生成**
- **GTAGS があるときは自動 incremental 更新**
- **project.el の誤認を防ぐ（Makefile でルート判定）**
- **Windows + MSYS2 + NAS でも安定動作**
- **auto-insert による C/C++ テンプレート自動挿入**

---

# 1. 必要インストール

この設定を動かすには、以下のツールが必要です。

## ■ Emacs 30
公式ビルドまたは MSYS2 版を使用。

## ■ MSYS2（UCRT64）
https://www.msys2.org/

インストール後、以下を実行:

```sh
pacman -Syu
pacman -S mingw-w64-ucrt-x86_64-clang
pacman -S mingw-w64-ucrt-x86_64-ripgrep
pacman -S mingw-w64-ucrt-x86_64-global
pacman -S mingw-w64-ucrt-x86_64-universal-ctags
pacman -S mingw-w64-ucrt-x86_64-python-pyright
pacman -S mingw-w64-ucrt-x86_64-rust-analyzer
```
