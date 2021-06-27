;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ package manager                                               ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

(require 'package)
;(add-to-list 'package-archives
;             '("melpa" . "https://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/"))
(package-initialize)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ key binding - keyboard                                        ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; Altキーを使用せずにMetaキーを使用（有効：t、無効：nil）
(setq w32-alt-is-meta t)

;; F2(ibuffer)
(global-set-key (kbd "<f2>") 'ibuffer)

;; C-x oの逆動作をC-x pに割り当てる
(global-set-key "\C-xp" (lambda () (interactive) (other-window -1)))

;; Backspace
(keyboard-translate ?\C-h ?\C-?)

;; スクロールダウン
(global-set-key (kbd "C-z") 'scroll-down)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;; @ Refresh                                                        ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
( defun revert-buffer-no-confirm ()
     "Revert buffer without confirmation."
     (interactive) (revert-buffer t t))
(global-set-key (kbd "<f5>") 'revert-buffer-no-confirm)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ file - lockfile                                               ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; ロックファイルを生成（有効：t、無効：nil）
(setq create-lockfiles nil)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ file - backup                                                 ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; ファイルオープン時のバックアップ（~）（有効：t、無効：nil）
(setq make-backup-files   t)  ;; 自動バックアップの実行有無
(setq version-control     t)  ;; バックアップファイルへの番号付与
(setq kept-new-versions   3)  ;; 最新バックアップファイルの保持数
(setq kept-old-versions   0)  ;; 最古バックアップファイルの保持数
(setq delete-old-versions t)  ;; バックアップファイル削除の実行有無

;; ファイルオープン時のバックアップ（~）の格納ディレクトリ
(setq backup-directory-alist
      (cons (cons "\\.*$" (expand-file-name "/tmp/emacsbk"))
            backup-directory-alist))

;; 編集中ファイルの自動バックアップ（有効：t、無効：nil）
(setq backup-inhibited nil)

;; 終了時に自動バックアップファイルを削除（有効：t、無効：nil）
(setq delete-auto-save-files nil)

;; 編集中ファイルのバックアップ（有効：t、無効：nil）
(setq auto-save-list-file-name nil)
(setq auto-save-list-file-prefix nil)

;; 編集中ファイルのバックアップ間隔（秒）
(setq auto-save-timeout 3)

;; 編集中ファイルのバックアップ間隔（打鍵）
(setq auto-save-interval 100)

;; 編集中ファイル（##）の格納ディレクトリ
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "/tmp/emacsbk") t)))


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ Auto Revert-buffer                                            ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;; 起動時から global-auto-revert-mode を有効にする
(global-auto-revert-mode 1)
;; 特定のモードでのみ有効にする
(add-hook 'c-mode-hook 'turn-on-auto-revert-mode)

;; global-auto-revert でも特定のモードでは無効にする
(add-hook 'text-mode-hook
          (lambda ()
            (setq global-auto-revert-ignore-buffer t)))

;; global-auto-revert でも特定のモードでは無効にする
(setq global-auto-revert-ignore-modes
      '(text-mode))

;; auto-revert-mode のモードライン表示を変更
(setq auto-revert-mode-text " ARev")

;; global-auto-revert でのモードライン表示を変更
(setq global-auto-revert-mode-text "")


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ language - coding system                                      ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; デフォルトの文字コード
(set-default-coding-systems 'utf-8)

;; テキストファイル／新規バッファの文字コード
(prefer-coding-system 'utf-8)

;; ファイル名の文字コード
(set-file-name-coding-system 'utf-8)

;; キーボード入力の文字コード
(set-keyboard-coding-system 'utf-8)

;; サブプロセスのデフォルト文字コード
(setq default-process-coding-system '(undecided-dos . utf-8))

;; 環境依存文字 文字化け対応
(set-charset-priority 'ascii 'japanese-jisx0208 'latin-jisx0201
                      'katakana-jisx0201 'iso-8859-1 'cp1252 'unicode)
(set-coding-system-priority 'utf-8 'euc-jp 'iso-2022-jp 'cp932)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;; Tab indent
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
(setq tab-always-indent nil)
(setq c-tab-always-indent nil)
(setq tab-width 4)
;; Tab indent
(setq c-basic-offset 4)
(setq-default tab-width 4)
(setq default-tab-width 4)
(setq tab-stop-lit '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60
               64 68 72 76 80 84 88 92 96 100 104 108 112 116 120))

;; Style
;; c mode
(add-hook 'c-mode-common-hook
      '(lambda ()
         (c-set-style "k&r")
         (setq c-basic-offset 4)
         (setq indent-tabs-mode 4)
         (setq tab-width 4)))


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ Tab space可視化
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

(require 'whitespace)
(setq whitespace-style '(face           ; faceで可視化
                         trailing       ; 行末
                         tabs           ; タブ
                         ;;empty          ; 先頭/末尾の空行
                         space-mark     ; 表示のマッピング
                         tab-mark
                         ))

(setq whitespace-display-mappings
      '((space-mark ?\x3000 [?\□])
;;      (tab-mark ?\t [?\u00BB ?\t] [?\\ ?\t])
        ))

(global-whitespace-mode 1)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ language - fontset                                            ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; デフォルト フォント
;; (set-face-attribute 'default nil :family "Migu 1M" :height 110)
(set-face-font 'default "Migu 1M-11:antialias=standard")

;; プロポーショナル フォント
;; (set-face-attribute 'variable-pitch nil :family "Migu 1M" :height 110)
(set-face-font 'variable-pitch "Migu 1M-11:antialias=standard")

;; 等幅フォント
;; (set-face-attribute 'fixed-pitch nil :family "Migu 1M" :height 110)
(set-face-font 'fixed-pitch "Migu 1M-11:antialias=standard")

;; ツールチップ表示フォント
;; (set-face-attribute 'tooltip nil :family "Migu 1M" :height 90)
(set-face-font 'tooltip "Migu 1M-9:antialias=standard")

;;; fontset

;; フォントサイズ調整
(global-set-key (kbd "C-<wheel-up>")   '(lambda() (interactive) (text-scale-increase 1)))
(global-set-key (kbd "C-=")            '(lambda() (interactive) (text-scale-increase 1)))
(global-set-key (kbd "C-<wheel-down>") '(lambda() (interactive) (text-scale-decrease 1)))
(global-set-key (kbd "C--")            '(lambda() (interactive) (text-scale-decrease 1)))

;; フォントサイズ リセット
(global-set-key (kbd "M-0") '(lambda() (interactive) (text-scale-set 0)))


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - frame                                                ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;;(setq default-frame-alist
;;      (append '((width                . 85)  ; フレーム幅
;;                (height               . 38 ) ; フレーム高
;;                (left                 . 70 ) ; 配置左位置
;;                (top                  . 28 ) ; 配置上位置
;;                (line-spacing         . 0  ) ; 文字間隔
;;                (left-fringe          . 10 ) ; 左フリンジ幅
;;                (right-fringe         . 11 ) ; 右フリンジ幅
;;                (menu-bar-lines       . 1  ) ; メニューバー
;;                (tool-bar-lines       . 1  ) ; ツールバー
;;                (vertical-scroll-bars . 1  ) ; スクロールバー
;;                (scroll-bar-width     . 17 ) ; スクロールバー幅
;;                (cursor-type          . box) ; カーソル種別
;;                (alpha                . 100) ; 透明度
;;                ) default-frame-alist) )
;;(setq initial-frame-alist default-frame-alist)
;;
;;;; フレーム タイトル
;;(setq frame-title-format
;;      '("emacs " emacs-version (buffer-file-name " - %f")))
;;
;; 初期画面の非表示（有効：t、無効：nil）
(setq inhibit-startup-message nil)
(setq inhibit-startup-screen nil)

;; フルスクリーン化
(global-set-key (kbd "<M-return>") 'toggle-frame-fullscreen)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ scroll                                                        ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; スクロール時のカーソル位置を維持（有効：t、無効：nil）
(setq scroll-preserve-screen-position t)

;; スクロール開始の残り行数
(setq scroll-margin 0)

;; スクロール時の行数
(setq scroll-conservatively 10000)

;; スクロール時の行数（scroll-marginに影響せず）
(setq scroll-step 0)

;; 画面スクロール時の重複表示する行数
(setq next-screen-context-lines 1)

;; キー入力中の画面更新を抑止（有効：t、無効：nil）
(setq redisplay-dont-pause t)

;; recenter-top-bottomのポジション
(setq recenter-positions '(middle top bottom))

;; 横スクロール開始の残り列数
(setq hscroll-margin 1)

;; 横スクロール時の列数
(setq hscroll-step 1)

;; バッファの最後までスクロールダウン
(defadvice scroll-down (around scroll-down activate compile)
  (interactive)
  (let (
        (bgn-num (+ 1 (count-lines (point-min) (point))))
        )
    (if (< bgn-num (window-height))
        (goto-char (point-min))
      ad-do-it) ))

;; バッファの先頭までスクロールアップ
(defadvice scroll-up (around scroll-up activate compile)
  (interactive)
  (let (
        (bgn-num (+ 1 (count-lines (point-min) (point))))
        (end-num nil)
        )
    (save-excursion
      (goto-char (point-max))
      (setq end-num (+ 1 (count-lines (point-min) (point))))
      )
    (if (< (- (- end-num bgn-num) (window-height)) 0)
        (goto-char (point-max))
      ad-do-it) ))


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - mode line                                            ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; 行番号の表示（有効：t、無効：nil）
(line-number-mode t)

;; 列番号の表示（有効：t、無効：nil）
(column-number-mode t)

;; モードライン カスタマイズ
(setq-default
 mode-line-format
 `(
   ""
   w32-ime-mode-line-state-indicator
   " "
   mode-line-mule-info
   mode-line-modified
   mode-line-frame-identification
   mode-line-buffer-identification
   " "
   global-mode-string
   " %[("
   mode-name
   mode-line-process
   "%n"
   ")%] "
   (which-func-mode ("" which-func-format " "))
   (line-number-mode
    (:eval
     (format "L%%l/L%d " (count-lines (point-max) 1) )))
   (column-number-mode " C%c ")
   (-3 . "%p")
   )
 )
(setq mode-line-frame-identification " ")

;; cp932エンコードの表記変更
(coding-system-put 'cp932 :mnemonic ?P)
(coding-system-put 'cp932-dos :mnemonic ?P)
(coding-system-put 'cp932-unix :mnemonic ?P)
(coding-system-put 'cp932-mac :mnemonic ?P)

;; UTF-8エンコードの表記変更
(coding-system-put 'utf-8 :mnemonic ?U)
(coding-system-put 'utf-8-with-signature :mnemonic ?u)

;; 改行コードの表記追加
(setq eol-mnemonic-dos       ":Dos ")
(setq eol-mnemonic-mac       ":Mac ")
(setq eol-mnemonic-unix      ":Unx ")
(setq eol-mnemonic-undecided ":??? ")


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - linum                                                ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

(require 'linum)

;; 行移動を契機に描画
(defvar linum-line-number 0)
(declare-function linum-update-current "linum" ())
(defadvice linum-update-current
    (around linum-update-current-around activate compile)
  (unless (= linum-line-number (line-number-at-pos))
    (setq linum-line-number (line-number-at-pos))
    ad-do-it
    ))

;; バッファ中の行番号表示の遅延設定
(defvar linum-delay nil)
(setq linum-delay t)
(defadvice linum-schedule (around linum-schedule-around () activate)
  (run-with-idle-timer 1.0 nil #'linum-update-current))

;; 行番号の書式
(defvar linum-format nil)
(setq linum-format "%5d ")

;; バッファ中の行番号表示（有効：t、無効：nil）
(global-linum-mode t)

;; 文字サイズ
(set-face-attribute 'linum nil :height 0.75)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ search - isearch                                              ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; 大文字・小文字を区別しないでサーチ（有効：t、無効：nil）
(setq-default case-fold-search nil)

;; インクリメント検索時に縦スクロールを有効化（有効：t、無効：nil）
(setq isearch-allow-scroll nil)

;; C-dで検索文字列を一文字削除
(define-key isearch-mode-map (kbd "C-d") 'isearch-delete-char)

;; C-yで検索文字列にヤンク貼り付け
(define-key isearch-mode-map (kbd "C-y") 'isearch-yank-kill)

;; C-eで検索文字列を編集
(define-key isearch-mode-map (kbd "C-e") 'isearch-edit-string)

;; Tabで検索文字列を補完
(define-key isearch-mode-map (kbd "TAB") 'isearch-yank-word)

;; C-gで検索を終了
(define-key isearch-mode-map (kbd "C-g")
  '(lambda() (interactive) (isearch-done)))

;; 日本語の検索文字列をミニバッファに表示
(define-key isearch-mode-map (kbd "<compend>")
  '(lambda() (interactive) (isearch-update)))
(define-key isearch-mode-map (kbd "<kanji>")
  'isearch-toggle-input-method)
(add-hook
 'isearch-mode-hook
 '(lambda() (setq w32-ime-composition-window (minibuffer-window)))
 )
(add-hook
 'isearch-mode-end-hook
 '(lambda() (setq w32-ime-composition-window nil))
 )


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - cursor                                               ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; カーソルの点滅（有効：1、無効：0）
(blink-cursor-mode 0)

;; 非アクティブウィンドウのカーソル表示（有効：t、無効：nil）
(setq-default cursor-in-non-selected-windows t)

;; IME無効／有効時のカーソルカラー定義
(unless (facep 'cursor-ime-off)
  (make-face 'cursor-ime-off)
  (set-face-attribute 'cursor-ime-off nil
                      :background "DarkRed" :foreground "White")
  )
(unless (facep 'cursor-ime-on)
  (make-face 'cursor-ime-on)
  (set-face-attribute 'cursor-ime-on nil
                      :background "DarkGreen" :foreground "White")
  )

;; IME無効／有効時のカーソルカラー設定
(advice-add 'ime-force-on
            :before (lambda (&rest args)
                      (if (facep 'cursor-ime-on)
                          (let ( (fg (face-attribute 'cursor-ime-on :foreground))
                                 (bg (face-attribute 'cursor-ime-on :background)) )
                            (set-face-attribute 'cursor nil :foreground fg :background bg) )
                        )
                      ))
(advice-add 'ime-force-off
            :before (lambda (&rest args)
                      (if (facep 'cursor-ime-off)
                          (let ( (fg (face-attribute 'cursor-ime-off :foreground))
                                 (bg (face-attribute 'cursor-ime-off :background)) )
                            (set-face-attribute 'cursor nil :foreground fg :background bg) )
                        )
                      ))

;; バッファ切り替え時の状態引継ぎ設定（有効：t、無効：nil）
(setq w32-ime-buffer-switch-p t)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - buffer                                               ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; バッファ画面外文字の切り詰め表示（有効：t、無効：nil）
(setq truncate-lines nil)

;; ウィンドウ縦分割時のバッファ画面外文字の切り詰め表示（有効：t、無効：nil）
(setq truncate-partial-width-windows t)

;; 同一バッファ名にディレクトリ付与
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-ignore-buffers-re "*[^*]+*")


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - minibuffer                                           ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

;; minibufferのアクティブ時、IMEを無効化
(add-hook 'minibuffer-setup-hook
          (lambda ()
            (deactivate-input-method)))
;;(wrap-function-to-control-ime 'y-or-n-p nil nil)
;;(wrap-function-to-control-ime 'map-y-or-n-p nil nil)
;;(wrap-function-to-control-ime 'read-char nil nil)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ hl-line-mode
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
(defface my-hl-line-face
  ;;背景がdarkなら背景色を紺に
  '((((class color) (background dark))
     (:background "NavyBlue" t))
    ;;背景がlightなら背景色を緑に
    (((class color) (background light))
     (:background "LightGoldenrodYellow" t))
    (t (:bold t)))
  "hl-line's my face")
(setq hl-line-face 'my-hl-line-face)
(global-hl-line-mode t)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ theme                                                         ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;(load-theme 'manoj-dark t)
;(load-theme 'tango-dark t)
;(load-theme 'tsdh-dark t)
;(load-theme 'deeper-blue t) ;; like
;(load-theme 'leuven t)
;(load-theme 'tango t)
;(load-theme 'whiteboard t)
(load-theme 'wombat t)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ screen - hiwin                                                ;;;
;;; 選択されていないウィンドウすべてに色をつけることによって、      ;;;
;;; 選択中のウィンドウをよりわかりやすくします。                    ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

(require 'hiwin)

;; hiwin-modeを有効化
(hiwin-activate)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ search - migemo                                               ;;;
;;;   https://github.com/emacs-jp/migemo                            ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

(setq search-default-mode nil)
(setq search-default-regexp-mode nil)

(require 'migemo)

(defvar migemo-command nil)
(setq migemo-command "cmigemo")

(defvar migemo-options nil)
(setq migemo-options '("-q" "--emacs"))

(defvar migemo-dictionary nil)
(setq migemo-dictionary "/usr/local/share/migemo/utf-8/migemo-dict")

(defvar migemo-user-dictionary nil)

(defvar migemo-regex-dictionary nil)

(defvar migemo-coding-system nil)
(setq migemo-coding-system 'utf-8)

(load-library "migemo")
(migemo-init)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
; GGTAGS
;--- GNU GLOBAL(ggtags) ggtags.el ---
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
(global-set-key "\C-o" 'ggtags-find-tag-dwim)
(global-set-key "\M-t" 'ggtags-find-definition)  ;関数の定義元へ
(global-set-key "\M-r" 'ggtags-find-reference)  ;関数の参照先へ
(global-set-key "\M-s" 'ggtags-find-other-symbol)  ;変数の定義元/参照先へ
(global-set-key "\C-cp" 'ggtags-find-tag-regexp)
(global-set-key "\C-cf" 'ggtags-find-file)  ;ファイルにジャンプ
(global-set-key "\M-o" 'pop-tag-mark)   ;前のバッファに戻る

(require 'ggtags)
(add-hook 'c-mode-common-hook
          (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode)
              (ggtags-mode 1))))


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ color-moccur                                                  ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
(when (require 'color-moccur nil t)
;  (define-key global-map (kbd "C-o") 'moccur-grep-find)
  (setq moccur-split-word t)
  (add-to-list 'dmoccur-exclusion-mask "\\.DS_Store")
  (add-to-list 'dmoccur-exclusion-mask "^#.+#$")
;  (when (and (executable-find "cmigemo")
;          (require 'migemo nitl t))
;    (setq moccur-use-migemo t))
)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ moccur-edit                                                   ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
(require 'moccur-edit nil t)


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;
;;; @ auto-insert                              ;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;

(require 'autoinsert)

;; テンプレートのディレクトリ
(setq auto-insert-directory "~/.emacs.d/site-lisp/auto-insert/")

;; 各ファイルによってテンプレートを切り替える
(setq auto-insert-alist
      (nconc '(
               ("\\.c$" . ["template.c" my-template])
               ("\\.h$" . ["template.h" my-template])
               ) auto-insert-alist))
(require 'cl)

;; ここが腕の見せ所
(defvar template-replacements-alists
  '(("%file%"            . (lambda () (file-name-nondirectory (buffer-file-name))))
    ("%file-without-ext%" . (lambda () (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))
    ("%include-guard%"  . (lambda () (format "__%s__" (upcase (replace-regexp-in-string "\\." "_" (file-name-nondirectory (buffer-file-name)))))))))

(defun my-template ()
  (time-stamp)
  (mapc #'(lambda(c)
            (progn
              (goto-char (point-min))
              (replace-string (car c) (funcall (cdr c)) nil)))
        template-replacements-alists)
  (goto-char (point-max))
  (message "done."))
(add-hook 'find-file-not-found-hooks 'auto-insert)



;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (color-theme color-theme-wombat migemo package-utils hiwin color-moccur moccur-edit ggtags))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
