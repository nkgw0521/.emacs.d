;;; init.el --- Emacs configuration for embedded C development  -*- lexical-binding: t -*-
;;; Environment: Windows + MSYS2 (msys64)
;;; Package manager: leaf.el
;;; Last updated: 2026-04-14 (corfu + eglot + wgrep edition)

;;; ============================================================
;; 0. 起動時パフォーマンス改善
;;    GCの閾値を起動中だけ引き上げ、起動後に戻す
;;; ============================================================
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)))) ; 32MB

;;; ============================================================
;; 1. パッケージアーカイブの設定
;;; ============================================================
(require 'package)
(setq package-archives
      '(("melpa"        . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("gnu"          . "https://elpa.gnu.org/packages/")
        ("nongnu"       . "https://elpa.nongnu.org/packages/")))
(package-initialize)

;;; ============================================================
;; 2. leaf.el のブートストラップ
;;    leaf.el 本体と leaf-keywords をインストール・初期化する
;;; ============================================================
(unless (package-installed-p 'leaf)
  (package-refresh-contents)
  (package-install 'leaf))

(leaf leaf-keywords
  :ensure t
  :init
  ;; leaf-keywords が依存する hydra / blackout を先にインストール
  (leaf hydra :ensure t)
  (leaf blackout :ensure t)
  :config
  (leaf-keywords-init))

;;; ============================================================
;; 3. 基本設定 (GUI / 表示)
;;; ============================================================
(leaf emacs
  :init
  ;; --- 文字コード ---
  ;; utf-8-dos : UTF-8 + CRLF改行 (Windows ファイルとの互換性優先)
  ;; LF のみのファイルを開いても正しく読めるが、保存時は CRLF になる
  ;; 特定バッファだけ LF にしたい場合: M-x set-buffer-file-coding-system utf-8-unix
  (set-language-environment "Japanese")
  (prefer-coding-system 'utf-8-dos)
  (set-default-coding-systems 'utf-8-dos)
  (set-terminal-coding-system 'utf-8-dos)
  (set-keyboard-coding-system 'utf-8-dos)

  ;; --- UI 簡素化 ---
  (setq inhibit-startup-screen t)       ; スプラッシュ非表示
  (setq initial-scratch-message nil)    ; *scratch* の初期メッセージ消去
  (menu-bar-mode -1)                    ; メニューバー非表示
  (tool-bar-mode -1)                    ; ツールバー非表示
  (scroll-bar-mode -1)                  ; スクロールバー非表示
  (column-number-mode t)                ; カラム番号表示
  (line-number-mode t)                  ; 行番号表示
  (global-display-line-numbers-mode t)  ; 全バッファで行番号

  ;; --- 動作 ---
  (setq make-backup-files nil)          ; バックアップファイルを作らない
  (setq auto-save-default nil)          ; 自動保存しない
  (setq create-lockfiles nil)           ; .#xxx ロックファイルを作らない
  (setq ring-bell-function 'ignore)     ; ビープ音を消す
  (setq use-short-answers t)            ; yes/no → y/n (Emacs 28+)
  (defalias 'yes-or-no-p 'y-or-n-p)    ; Emacs 27 以前の互換

  ;; --- スクロール ---
  (setq scroll-preserve-screen-position t) ; スクロール時にカーソル位置を維持
  (setq scroll-margin 0)
  (setq scroll-conservatively 10000)
  (setq scroll-step 0)
  (setq next-screen-context-lines 1)
  (setq recenter-positions '(middle top bottom))
  (setq hscroll-margin 1)
  (setq hscroll-step 1)

  ;; --- インデント (C言語向け) ---
  (setq-default indent-tabs-mode t)     ; スペースではなくタブ文字を使う
  (setq-default tab-width 4)            ; タブ幅 = 4
  (setq-default tab-always-indent nil)  ; TAB はタブ文字入力を優先
  (setq c-default-style "linux")        ; Linuxカーネルスタイル (組込みに多い)
  (setq c-basic-offset 4)
  (setq-default c-basic-offset 4)
  (setq-default tab-stop-list
                '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60
                  64 68 72 76 80 84 88 92 96 100 104 108 112 116 120)))

;;; ============================================================
;; 4. Windows / MSYS2 固有設定
;;; ============================================================

;; MSYS2 インストールパス ★環境に合わせて変更してください
;; leaf ブロックの外で定義することで他のセクションからも参照可能
(defvar msys2-root "C:/msys2-x86_64-20250830"
  "MSYS2 のインストールディレクトリ")

(leaf emacs
  :if (eq system-type 'windows-nt)
  :init
  ;; MSYS2 の各種ツールを PATH に追加
  ;; ucrt64/bin のみを追加（mingw64/bin・usr/bin は混在防止のため除外）
  (dolist (path (list
                 (concat msys2-root "/ucrt64/bin")))
    (when (file-directory-p path)
      (add-to-list 'exec-path path)
      (setenv "PATH" (concat (replace-regexp-in-string "/" "\\\\" path)
                             ";" (getenv "PATH")))))

  ;; find / grep を MSYS2 ucrt64 のものを使う
  (setq find-program  (concat msys2-root "/ucrt64/bin/find.exe"))
  (setq grep-program  (concat msys2-root "/ucrt64/bin/grep.exe"))

  ;; shell を bash に切り替え
  (setq shell-file-name (concat msys2-root "/usr/bin/bash.exe"))
  (setenv "SHELL" shell-file-name)
  (setq explicit-shell-file-name shell-file-name)
  (setq explicit-bash.exe-args '("--login" "-i"))

  ;; Windows でのフォント設定
  ;; タブ整列を崩さないため、英数字・日本語を Migu 1M に統一する。
  (when (display-graphic-p)
    (set-face-attribute 'default nil :family "Migu 1M" :height 110)
    (set-face-attribute 'fixed-pitch nil :family "Migu 1M" :height 110)
    (set-face-attribute 'variable-pitch nil :family "Migu 1M" :height 110)
    (set-fontset-font t 'ascii (font-spec :family "Migu 1M"))
    (set-fontset-font t 'japanese-jisx0208 (font-spec :family "Migu 1M"))
    (set-fontset-font t 'katakana-jisx0201 (font-spec :family "Migu 1M"))))

;;; ============================================================
;; 5. テーマ
;;    modus-themes は Emacs 28+ 組み込み。軽量で視認性が高い。
;;; ============================================================
(leaf modus-themes
  :init
  (load-theme 'modus-vivendi t))        ; ダークテーマ
  ;; ライトにしたい場合は 'modus-operandi

;;; ============================================================
;; 6. 補完フレームワーク
;;    vertico (候補一覧) + orderless (あいまい検索) + marginalia (説明付加)
;;; ============================================================
(leaf vertico
  :ensure t
  :init
  (vertico-mode t)
  :custom
  (vertico-count . 15))

(leaf orderless
  :ensure t
  :custom
  (completion-styles . '(orderless basic))
  (completion-category-overrides . '((file (styles basic partial-completion)))))

(leaf marginalia
  :ensure t
  :init
  (marginalia-mode t))

(leaf consult
  :ensure t
  :bind
  ("C-s"     . consult-line)            ; バッファ内インクリメンタル検索
  ("C-x b"   . consult-buffer)          ; バッファ切り替え
  ("M-g g"   . consult-goto-line)       ; 行番号ジャンプ
  ("C-c g"   . consult-grep)            ; grep
  ("C-c s"   . consult-ripgrep)         ; ripgrep (推奨)
  ("C-c f"   . consult-find))           ; ファイル検索

;;; ============================================================
;; 7. 補完 (corfu)
;;    corfu   : インラインポップアップ補完 UI
;;    cape    : 補完バックエンド集 (dabbrev, file, keyword 等)
;;    TAB は Emacs 標準のインデント/タブ入力を優先し、補完確定は RET/M-TAB に割り当てる
;;; ============================================================
(leaf corfu
  :ensure t
  :init
  (global-corfu-mode t)
  :custom
  (corfu-auto          . t)             ; 自動ポップアップ有効
  (corfu-auto-delay    . 0.2)           ; 表示遅延 [秒]
  (corfu-auto-prefix   . 2)             ; 何文字入力で補完を出すか
  (corfu-cycle         . t)             ; 候補の先頭/末尾をループ
  (corfu-quit-no-match . 'separator)    ; 候補なし時の動作
  :bind
  (:corfu-map
   ("C-n"     . corfu-next)
   ("C-p"     . corfu-previous)
   ("RET"     . corfu-insert)
   ("M-<tab>" . corfu-insert)
   ("C-g"     . corfu-quit)))

;; corfu-terminal: TUI (非GUI) 環境でもポップアップを表示
(leaf corfu-terminal
  :ensure t
  :unless (display-graphic-p)
  :init
  (corfu-terminal-mode t))

;; cape: 補完バックエンドの追加
;; eglot と組み合わせた場合、cape-wrap-buster で LSP 補完を優先させる
(leaf cape
  :ensure t
  :init
  ;; 補完候補ソースを優先順に登録
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)  ; バッファ内単語
  (add-to-list 'completion-at-point-functions #'cape-file)     ; ファイルパス
  (add-to-list 'completion-at-point-functions #'cape-keyword)  ; C キーワード
  :bind
  ("C-c p p" . completion-at-point)
  ("C-c p d" . cape-dabbrev)
  ("C-c p f" . cape-file)
  ("C-c p k" . cape-keyword))

;;; ============================================================
;; 8. C言語 / 組込み開発向け設定
;;; ============================================================
(leaf cc-mode
  :hook
  ;; c-mode と c-ts-mode 両対応
  ((c-mode-hook c-ts-mode-hook c++-mode-hook c++-ts-mode-hook) .
   (lambda ()
     ;; タブ・インデントをバッファローカルで強制する。
     (c-set-style "k&r")
     (setq-local tab-width 4)
     (setq-local indent-tabs-mode t)
     (setq-local c-basic-offset 4)
     (setq-local tab-always-indent nil)
     (setq-local c-tab-always-indent nil)
     (setq-local tab-stop-list
                 '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60
                   64 68 72 76 80 84 88 92 96 100 104 108 112 116 120))
     ;; TAB は C/C++ バッファではタブ文字を入力する。
     (local-set-key (kbd "TAB") #'self-insert-command)
     ;; 改行時の自動インデントで表形式テーブルが崩れるのを抑制。
     (electric-indent-local-mode -1)
     ;; switch の case をインデントしない。
     (c-set-offset 'case-label 0)
     ;; 構造体/配列初期化子の深い縦揃えを抑制。
     (c-set-offset 'arglist-cont '+)
     (c-set-offset 'arglist-cont-nonempty '+)
     (c-set-offset 'brace-list-intro '+)
     (c-set-offset 'brace-list-entry 0)
     ;; 保存時に自動フォーマット (clang-format 使用時はコメント解除)
     ;; (add-hook 'before-save-hook #'clang-format-buffer nil t)
     )))

;; --- whitespace: タブ・末尾空白・全角スペースを可視化 ---
(leaf whitespace
  :hook
  ((c-mode-hook c-ts-mode-hook prog-mode-hook) . whitespace-mode)
  :custom
  ;; 可視化する対象
  (whitespace-style . '(face
                         trailing        ; 行末の空白
                         tabs            ; タブ文字 (着色のみ。tab-mark は表示桁を崩すため使わない)
                         spaces          ; スペース系 (全角スペース対象)
                         space-mark))    ; スペース系 (記号表示)
  ;; 全角スペース (U+3000) を可視化対象に追加
  ;; whitespace-space-regexp のデフォルトは半角スペースのみなので上書きする
  (whitespace-space-regexp . "\\(　+\\)")  ; 全角スペースのみマッチ
  :config
  ;; タブは「記号表示しない」で着色のみ。
  ;; tab-mark は見かけの表示桁を変え、タブ整列済みの表がズレて見えるため使わない。
  (set-face-attribute 'whitespace-tab nil
                      :background "gray18"
                      :foreground "gray45")
  ;; 全角スペースは □ 表示 + 着色。
  (set-face-attribute 'whitespace-space nil
                      :background "gray20"
                      :foreground "gray60")
  (setq whitespace-display-mappings
        '((space-mark ?\u3000 [?\□] [?_]))))

;; --- electric-pair: 括弧の自動補完 ---
(leaf electric
  :hook
  (prog-mode-hook . electric-pair-mode))

;; --- rainbow-delimiters: 対応括弧をカラー表示 ---
(leaf rainbow-delimiters
  :ensure t
  :hook
  (prog-mode-hook . rainbow-delimiters-mode))

;;; ============================================================
;; 9. LSP : eglot (Emacs 29+ 組み込み) + clangd
;;
;;  【事前準備】clangd のインストール (MSYS2 UCRT64 シェルで実行)
;;    pacman -S mingw-w64-ucrt-x86_64-clang-tools-extra
;;
;;  【compile_commands.json の生成】
;;    cmake を使う場合  : cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ...
;;    make を使う場合   : bear -- make   (bear も pacman でインストール可)
;;    手動作成も可       : プロジェクトルートに置くだけで clangd が認識する
;;; ============================================================
(leaf eglot
  :hook
  ;; C/C++ ファイルを開いたとき自動で eglot を起動
  ((c-mode-hook c-ts-mode-hook c++-mode-hook c++-ts-mode-hook) . eglot-ensure)
  :custom
  (eglot-autoshutdown          . t)     ; バッファを閉じたら LSP も落とす
  (eglot-ignored-server-capabilities   ; 不要な機能を無効化して軽量化
   . '(:documentHighlightProvider
       :documentFormattingProvider
       :documentRangeFormattingProvider))
  :config
  ;; clangd の起動オプション
  ;; --background-index   : バックグラウンドでインデックス構築
  ;; --clang-tidy         : clang-tidy を有効化
  ;; --completion-style   : 補完スタイル (detailed = 型情報付き)
  ;; --header-insertion   : #include の自動挿入 (never にすると挿入しない)
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode)
                 . ("clangd"
                    "--background-index"
                    "--clang-tidy"
                    "--completion-style=detailed"
                    "--header-insertion=never")))
  ;; eglot の補完を corfu/cape と連携させる
  ;; cape-wrap-buster で LSP 補完キャッシュを無効化し常に最新を取得
  (defun my/eglot-capf-setup ()
    (setq-local completion-at-point-functions
                (list (cape-capf-super
                       (cape-wrap-buster #'eglot-completion-at-point)
                       #'cape-dabbrev
                       #'cape-keyword))))
  (add-hook 'eglot-managed-mode-hook #'my/eglot-capf-setup)
  :bind
  (:eglot-mode-map
   ("C-c e r" . eglot-rename)           ; シンボルのリネーム
   ("C-c e a" . eglot-code-actions)     ; コードアクション
   ;; ("C-c e f" . eglot-format-buffer) ; 表形式テーブルが崩れるため無効
   ("M-."     . xref-find-definitions)  ; 定義へジャンプ
   ("M-,"     . xref-go-back)           ; 戻る
   ("M-?"     . xref-find-references))) ; 参照を検索

;;; ============================================================
;; 10. flycheck: 構文チェック (オプション)
;;     clang-tidy / gcc を静的解析に使う
;;; ============================================================
(leaf flycheck
  :ensure t
  :hook
  (prog-mode-hook . flycheck-mode)
  :custom
  ;; C言語のチェッカーを明示 (clang / gcc / clang-tidy から選択)
  (flycheck-c/c++-clang-executable . "clang")
  ;; クロスコンパイル時はコンパイラを変える
  ;; (flycheck-c/c++-gcc-executable . "arm-none-eabi-gcc")
  )

;; --- wgrep: grep/ripgrep 結果バッファを直接編集して一括置換 ---
;; 使い方:
;;   1. M-x rgrep / M-x grep-find / M-x deadgrep などで検索
;;   2. 結果バッファで e を押して編集開始
;;   3. 編集後 C-c C-c で反映、C-c C-k でキャンセル
(leaf wgrep
  :ensure t
  :custom
  (wgrep-auto-save-buffer . t)
  (wgrep-change-readonly-file . t)
  :bind
  (:grep-mode-map
   ("e"     . wgrep-change-to-wgrep-mode)
   ("C-c C-c" . wgrep-finish-edit)
   ("C-c C-k" . wgrep-abort-changes)))

;;; ============================================================
;; 10.5 ggtags : GNU Global によるタグジャンプ
;;
;;  【役割分担】
;;    eglot (clangd) : 補完・エラー表示・開いているファイルのジャンプ
;;    ggtags (Global): プロジェクト全ファイルを対象とした確実なジャンプ
;;
;;  【事前準備】
;;    1. GNU Global のインストール (MSYS2 UCRT64 シェルで実行)
;;       pacman -S mingw-w64-ucrt-x86_64-global
;;
;;    2. プロジェクトルートでタグ生成
;;       cd f:/workspace/your-project
;;       gtags
;;       → GPATH / GRTAGS / GTAGS の3ファイルが生成される
;;
;;    3. ファイル変更後はタグを更新
;;       M-x ggtags-update-tags  または  C-c g u
;;
;;  【キーバインド早見表】
;;    C-o     : 定義へジャンプ (dwim: カーソル下のシンボルを自動判定)
;;    M-t     : 定義元へジャンプ
;;    M-r     : 参照先を検索
;;    M-s     : シンボル検索 (定義・参照の両方)
;;    M-o     : 前の位置に戻る
;;    C-c G g : grep 検索
;;    C-c G f : ファイル名で検索
;;    C-c G p : 正規表現でタグ検索
;;    C-c G u : タグ更新
;;; ============================================================
(leaf ggtags
  :ensure t
  :init
  ;; gtags コマンドのパスを明示 (MSYS2環境でのパス解決問題を回避)
  ;; usr/bin の gtags は MSYS2形式パスを使うため ucrt64/bin を使用
  ;; msys2-root は Section 4 で定義
  (setq ggtags-executable-directory
        (concat (if (boundp 'msys2-root) msys2-root "C:/msys64")
                "/ucrt64/bin"))
  :hook
  ((c-mode-hook c-ts-mode-hook c++-mode-hook c++-ts-mode-hook) .
   (lambda ()
     (when (derived-mode-p 'c-mode 'c-ts-mode 'c++-mode 'c++-ts-mode)
       (ggtags-mode 1))))
  :bind
  ;; グローバルキーバインド (ggtags-mode 有効時に使用)
  ;; ※ C-c g は consult-grep に使用中のため C-c G を使用
  ("C-o"     . ggtags-find-tag-dwim)    ; 定義へジャンプ (自動判定)
  ("M-t"     . ggtags-find-definition)  ; 定義元へ
  ("M-r"     . ggtags-find-reference)   ; 参照先へ
  ("M-s"     . ggtags-find-other-symbol); シンボル検索
  ("M-o"     . pop-tag-mark)            ; 前の位置に戻る
  ("C-c G g" . ggtags-grep)             ; grep 検索
  ("C-c G f" . ggtags-find-file)        ; ファイル名で検索
  ("C-c G p" . ggtags-find-tag-regexp)  ; 正規表現でタグ検索
  ("C-c G u" . ggtags-update-tags))     ; タグ更新

;;; ============================================================
;; 11. その他の便利パッケージ
;;; ============================================================

;; --- which-key: キーバインドのヒント表示 ---
(leaf which-key
  :ensure t
  :blackout t
  :init
  (which-key-mode t)
  :custom
  (which-key-idle-delay . 0.8))

;; --- undo-fu: より使いやすい Undo/Redo ---
(leaf undo-fu
  :ensure t
  :bind
  ("C-/" . undo-fu-only-undo)
  ("C-?" . undo-fu-only-redo))

;; --- avy: 画面内任意位置へのジャンプ ---
(leaf avy
  :ensure t
  :bind
  ("C-c j" . avy-goto-char-2)
  ("C-c l" . avy-goto-line))

;; --- recentf: 最近使ったファイル ---
(leaf recentf
  :init
  (recentf-mode t)
  :custom
  (recentf-max-saved-items . 100)
  :bind
  ("C-c r" . recentf-open-files))

;;; ============================================================
;; 12. ibuffer + Dired : バッファ管理とファイル操作
;;; ============================================================

;; --- ibuffer: バッファ一覧 (F2 で起動) ---
(leaf ibuffer
  :bind
  ("<f2>" . ibuffer)
  :custom
  ;; バッファをメジャーモードでグループ化して表示
  (ibuffer-saved-filter-groups
   . '(("default"
        ("C / C++"  (or (mode . c-mode)
                        (mode . c-ts-mode)
                        (mode . c++-mode)
                        (mode . c++-ts-mode)))
        ("Python"   (mode . python-mode))
        ("Dired"    (mode . dired-mode))
        ("Emacs"    (or (name . "^\\*scratch\\*$")
                        (name . "^\\*Messages\\*$")
                        (name . "^\\*Warnings\\*$")))
        ("Help"     (or (mode . help-mode)
                        (mode . Info-mode))))))
  (ibuffer-show-empty-filter-groups . nil)  ; 空グループは非表示
  (ibuffer-default-sorting-mode . 'filename/process)
  :hook
  (ibuffer-mode-hook .
   (lambda ()
     (ibuffer-switch-to-saved-filter-groups "default"))))

;; --- Dired: ファイラー ---
(leaf dired
  :custom
  ;; ls オプション: -l 詳細表示 / -h 人間可読サイズ / -v 自然順ソート
  ;; MSYS2 の ls (GNU coreutils) を使用するため --group-directories-first が使える
  (dired-listing-switches . "-lhv --group-directories-first")
  (dired-dwim-target . t)               ; 2ペイン時に移動先を自動推定
  (dired-recursive-copies  . 'always)   ; コピーは再帰的に (確認なし)
  (dired-recursive-deletes . 'always)   ; 削除は再帰的に (確認なし)
  (dired-kill-when-opening-new-dired-buffer . t) ; 新しい Dired を開いたら古いバッファを閉じる
  :bind
  (:dired-mode-map
   ;; 主要キー早見表 (変更なし、参考用コメント)
   ;; R : 移動(rename)  C : コピー      D : 削除    + : ディレクトリ作成
   ;; m : マーク        u : マーク解除  % m : 正規表現マーク
   ;; f / RET : 開く    ^ : 親ディレクトリへ
   ("<f2>" . ibuffer)))                  ; Dired からも F2 で ibuffer へ戻る

;; --- dired-x: Dired 拡張 (Emacs 組み込み) ---
;; C-x C-j : カレントファイルのあるディレクトリを Dired で開く
(leaf dired-x
  :after dired
  :bind
  ("C-x C-j" . dired-jump))

;;; ============================================================
;; 13. キーバインド追加
;;; ============================================================

;; TAB 入力メモ
;; - 通常の TAB       : インデント（indent-tabs-mode=t なので必要に応じて 	 を使う）
;; - 補完候補表示中    : RET または M-TAB で corfu 候補を確定
;; - 文字として 	 を直接挿入したい場合: C-q TAB

;; C-z : スクロールダウン (従来通り)
(global-set-key (kbd "C-z") 'scroll-down)

;; C-x p : 逆方向ウィンドウ移動 (C-x o の逆)
(global-set-key (kbd "C-x p")
                (lambda () (interactive) (other-window -1)))

;; F5 : バッファを確認なしで再読込
(defun revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer t t))
(global-set-key (kbd "<f5>") 'revert-buffer-no-confirm)

;; フォントサイズ変更
(global-set-key (kbd "C-<wheel-up>")
                (lambda () (interactive) (text-scale-increase 1)))
(global-set-key (kbd "C-=")
                (lambda () (interactive) (text-scale-increase 1)))
(global-set-key (kbd "C-<wheel-down>")
                (lambda () (interactive) (text-scale-decrease 1)))
(global-set-key (kbd "C--")
                (lambda () (interactive) (text-scale-decrease 1)))
(global-set-key (kbd "M-0")
                (lambda () (interactive) (text-scale-set 0)))

;; バッファ端でのスクロール制御
;; 先頭付近で scroll-down したとき point-min へ移動
(advice-add 'scroll-down :around
            (lambda (orig-fn &rest args)
              (let ((bgn-num (1+ (count-lines (point-min) (point)))))
                (if (< bgn-num (window-height))
                    (goto-char (point-min))
                  (apply orig-fn args)))))

;; 末尾付近で scroll-up したとき point-max へ移動
(advice-add 'scroll-up :around
            (lambda (orig-fn &rest args)
              (let* ((bgn-num (1+ (count-lines (point-min) (point))))
                     (end-num (save-excursion
                                (goto-char (point-max))
                                (1+ (count-lines (point-min) (point))))))
                (if (< (- (- end-num bgn-num) (window-height)) 0)
                    (goto-char (point-max))
                  (apply orig-fn args)))))

;;; ============================================================
;; 14. global-auto-revert : 外部変更を自動反映
;;; ============================================================
(leaf autorevert
  :init
  (global-auto-revert-mode 1)
  :custom
  (auto-revert-mode-text        . " ARev") ; モードライン表示
  (global-auto-revert-mode-text . "")
  ;; text-mode では自動リバートしない
  (global-auto-revert-ignore-modes . '(text-mode))
  :hook
  ;; c-mode では個別にも有効化（global が無効になっても確実に動く）
  (c-mode-hook . turn-on-auto-revert-mode))

;;; ============================================================
;; 15. hl-line + hiwin : カレント行・ウィンドウの視覚化
;;; ============================================================

;; hl-line: カレント行をハイライト
(leaf hl-line
  :init
  (defface my-hl-line-face
    '((((class color) (background dark))
       (:background "NavyBlue" t))
      (((class color) (background light))
       (:background "LightGoldenrodYellow" t))
      (t (:bold t)))
    "hl-line face for current line highlight")
  (setq hl-line-face 'my-hl-line-face)
  (global-hl-line-mode t))

;; hiwin: 非アクティブウィンドウを暗くして選択中を明確化
(leaf hiwin
  :ensure t
  :init
  (hiwin-activate))

;;; ============================================================
;; 16. auto-insert : 新規ファイルにテンプレートを自動挿入
;;
;;  テンプレートファイルの置き場所:
;;    ~/.emacs.d/site-lisp/auto-insert/template.c
;;    ~/.emacs.d/site-lisp/auto-insert/template.h
;;
;;  テンプレート内で使用できるプレースホルダ:
;;    %file%             → ファイル名 (例: main.c)
;;    %file-without-ext% → 拡張子なしファイル名 (例: main)
;;    %include-guard%    → インクルードガード用マクロ名 (例: __MAIN_H__)
;;; ============================================================
(leaf autoinsert
  :init
  (auto-insert-mode t)
  :custom
  (auto-insert-directory
   . "~/.emacs.d/site-lisp/auto-insert/") ; テンプレートディレクトリ
  (auto-insert-query . nil)               ; 挿入前の確認を省略
  :config
  ;; C/H ファイルにテンプレートを割り当て
  (setq auto-insert-alist
        (append '(("\\.c\\'" . ["template.c" my-auto-insert-template])
                  ("\\.h\\'" . ["template.h" my-auto-insert-template]))
                auto-insert-alist))

  ;; プレースホルダ置換関数
  (defvar my-template-replacements
    '(("%file%"
       . (lambda ()
           (file-name-nondirectory (buffer-file-name))))
      ("%file-without-ext%"
       . (lambda ()
           (file-name-sans-extension
            (file-name-nondirectory (buffer-file-name)))))
      ("%include-guard%"
       . (lambda ()
           (format "__%s__"
                   (upcase (replace-regexp-in-string
                            "\\." "_"
                            (file-name-nondirectory
                             (buffer-file-name))))))))
    "auto-insert テンプレートのプレースホルダと置換関数の対応リスト")

  (defun my-auto-insert-template ()
    "テンプレート内のプレースホルダを実際の値に置換する"
    (dolist (replacement my-template-replacements)
      (goto-char (point-min))
      (while (search-forward (car replacement) nil t)
        (replace-match (funcall (cdr replacement)) t t)))
    (goto-char (point-max)))

  ;; 新規ファイルを開いたとき auto-insert を発動
  (add-hook 'find-file-not-found-hooks #'auto-insert))

;;; ============================================================
;; 17. カスタム変数の保存先を分離
;;    M-x customize で変更した設定を init.el に書き込まないようにする
;;; ============================================================
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
