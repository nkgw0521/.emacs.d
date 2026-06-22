;;; init.el --- my Emacs 30 config  -*- lexical-binding: t; -*-

;;; ------------------------------------------------------------
;;; 基本設定
;;; ------------------------------------------------------------

(setq inhibit-startup-message t
      inhibit-startup-screen t)

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

(require 'cl-lib)
(require 'subr-x)

;;; ------------------------------------------------------------
;;; Windows / MSYS2 / GnuPG
;;; ------------------------------------------------------------

(defun my-add-to-path (dir)
  "Add DIR to `exec-path' and PATH if it exists.
Append to PATH on Windows so MSYS2 tools do not override native tools such as GnuPG."
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir t)
    (let ((path (getenv "PATH")))
      (unless (and path (string-match-p (regexp-quote dir) path))
        (setenv "PATH"
                (if (eq system-type 'windows-nt)
                    (concat path ";" dir)
                  (concat path ":" dir)))))))

(when (eq system-type 'windows-nt)
  ;; Prefer Gpg4win's native gpg.exe for ELPA signature checks.
  ;; MSYS2 gpg can mis-handle Windows paths such as c:/Users/...
  (let ((gpg4win "C:/Program Files (x86)/GnuPG/bin/gpg.exe")
        (gpg4win64 "C:/Program Files/GnuPG/bin/gpg.exe"))
    (cond
     ((file-exists-p gpg4win)   (setq epg-gpg-program gpg4win))
     ((file-exists-p gpg4win64) (setq epg-gpg-program gpg4win64))))
  (setq package-gnupghome-dir
        (expand-file-name "elpa/gnupg" user-emacs-directory)))

;;; ------------------------------------------------------------
;;; パッケージ管理
;;; ------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(setq package-archive-priorities
      '(("gnu" . 100)
        ("nongnu" . 90)
        ("melpa" . 80)))
(package-initialize)

;; use-package が無ければインストール
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;; ------------------------------------------------------------
;;; color-moccur（インストール済み前提）
;;; ------------------------------------------------------------

(use-package color-moccur
  :ensure t
  :config
  (setq moccur-split-word t))

;;; ------------------------------------------------------------
;;; ggtags
;;; ------------------------------------------------------------

(use-package ggtags
  :ensure t)

;;; ------------------------------------------------------------
;;; PATH（MSYS2 UCRT64 の LSP サーバーを Emacs に認識させる）
;;; ------------------------------------------------------------

(dolist (dir '("C:/msys64/ucrt64/bin"
               "C:/msys2-x86_64-20250830/ucrt64/bin"))
  (my-add-to-path dir))

;;; ------------------------------------------------------------
;;; キーバインド
;;; ------------------------------------------------------------

(when (eq system-type 'windows-nt)
  (setq w32-alt-is-meta t))

(global-set-key (kbd "<f2>") 'ibuffer)
(global-set-key (kbd "C-x p") (lambda () (interactive) (other-window -1)))
(keyboard-translate ?\C-h ?\C-?)
(global-set-key (kbd "C-z") 'scroll-down)

(defun revert-buffer-no-confirm ()
  (interactive)
  (revert-buffer :ignore-auto :noconfirm))
(global-set-key (kbd "<f5>") #'revert-buffer-no-confirm)

(global-set-key (kbd "<M-return>") #'toggle-frame-fullscreen)

;;; ------------------------------------------------------------
;;; バックアップ・オートセーブ
;;; ------------------------------------------------------------

(let ((backup-dir (expand-file-name "~/.emacs.d/backups/"))
      (autosave-dir (expand-file-name "~/.emacs.d/auto-save/")))
  (dolist (dir (list backup-dir autosave-dir))
    (unless (file-directory-p dir)
      (make-directory dir t)))
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,autosave-dir t))
        make-backup-files t
        version-control t
        delete-old-versions t
        kept-new-versions 3
        kept-old-versions 0))

;;; ------------------------------------------------------------
;;; 表示（行番号・スクロール・フォント）
;;; ------------------------------------------------------------

(global-display-line-numbers-mode t)
(setq display-line-numbers-width 4)

(pixel-scroll-precision-mode -1)

(setq scroll-margin 0
      scroll-conservatively 101
      scroll-step 1
      next-screen-context-lines 1)

(when (display-graphic-p)
  (when (member "Cica" (font-family-list))
    (set-face-attribute 'default nil :family "Cica" :height 110)
    (set-face-attribute 'fixed-pitch nil :family "Cica" :height 110)
    (set-face-attribute 'variable-pitch nil :family "Cica" :height 110)))

(global-hl-line-mode 1)
(load-theme 'wombat t)

;;; ------------------------------------------------------------
;;; whitespace
;;; ------------------------------------------------------------

(use-package whitespace
  :ensure nil
  :custom
  (whitespace-style '(face trailing tabs))
  :config
  (global-whitespace-mode 1))

;;; ------------------------------------------------------------
;;; タブ設定
;;; ------------------------------------------------------------

(setq-default tab-width 4)
(setq-default indent-tabs-mode t)

(defun my-tab-setup ()
  (setq tab-width 4)
  (setq indent-tabs-mode t))
(add-hook 'prog-mode-hook #'my-tab-setup)
(add-hook 'text-mode-hook #'my-tab-setup)

(add-hook 'c-mode-common-hook
          (lambda ()
            (setq c-basic-offset 4)
            (setq tab-width 4)
            (setq indent-tabs-mode t)))

;;; ------------------------------------------------------------
;;; project.el の誤認防止
;;; ------------------------------------------------------------

(require 'project)

(defun my-project-try-root (dir)
  (let ((root (locate-dominating-file dir "Makefile")))
    (when root
      (cons 'my-project root))))
(cl-defmethod project-root ((project (head my-project)))
  (cdr project))
(add-hook 'project-find-functions #'my-project-try-root)

;;; ------------------------------------------------------------
;;; xref / project
;;; ------------------------------------------------------------

(require 'xref)
(with-eval-after-load 'ggtags
  (when (boundp 'xref-backend-functions)
    (add-to-list 'xref-backend-functions #'xref-gtags-backend)))

;;; ------------------------------------------------------------
;;; symbol を確実に取得
;;; ------------------------------------------------------------

(defun my-symbol-at-point ()
  (let ((sym (thing-at-point 'symbol t)))
    (when (and (not sym)
               (looking-back "[A-Za-z0-9_]" 1))
      (save-excursion
        (backward-char 1)
        (setq sym (thing-at-point 'symbol t))))
    sym))

;;; ------------------------------------------------------------
;;; override-map（C-o / M-t / M-r）
;;; ------------------------------------------------------------

(defvar my-override-map (make-sparse-keymap))

(define-key my-override-map (kbd "C-o")
  (lambda ()
    (interactive)
    (or
     (when (fboundp 'ggtags-find-tag-dwim)
       (ignore-errors (call-interactively #'ggtags-find-tag-dwim)))
     (ignore-errors (call-interactively #'xref-find-definitions))
     (when (fboundp 'eglot-find-declaration)
       (ignore-errors (call-interactively #'eglot-find-declaration)))
     (message "定義が見つかりませんでした"))))

(define-key my-override-map (kbd "M-t")
  (lambda () (interactive) (call-interactively #'xref-find-definitions)))

(define-key my-override-map (kbd "M-r")
  (lambda () (interactive) (call-interactively #'xref-find-references)))

;;; ------------------------------------------------------------
;;; ripgrep（M-s）
;;; ------------------------------------------------------------

(defun my-ripgrep-search ()
  (interactive)
  (let* ((proj (project-current))
         (root (if proj (project-root proj) default-directory))
         (sym (my-symbol-at-point))
         (pattern (read-string
                   (format "Search (rg) [%s]: " (or sym "")))))
    (when (string-empty-p pattern)
      (setq pattern sym))
    (unless pattern
      (user-error "検索語が空です"))
    (compilation-start
     (format "rg -n --no-heading --color never --glob \"*\" -- %s %s"
             (shell-quote-argument pattern)
             (shell-quote-argument root))
     'grep-mode
     (lambda (_) "*ripgrep*"))))

(define-key my-override-map (kbd "M-s") #'my-ripgrep-search)
(define-key my-override-map (kbd "C-c p") #'my-ripgrep-search)

(define-key my-override-map (kbd "C-c f")
  (lambda () (interactive) (call-interactively #'project-find-file)))

(add-to-list 'emulation-mode-map-alists
             `((my-override-mode . ,my-override-map)))

(define-minor-mode my-override-mode
  "Force override keymap."
  :global t
  :lighter " OVR")
(my-override-mode 1)

;;; ------------------------------------------------------------
;;; GTAGS 自動更新
;;; ------------------------------------------------------------

(defun my-update-gtags ()
  (when (and (project-current)
             (executable-find "global")
             (fboundp 'ggtags-create-tags))
    (let* ((root (project-root (project-current)))
           (gtags (expand-file-name "GTAGS" root)))
      (cond
       ((not (file-exists-p gtags))
        (call-interactively #'ggtags-create-tags))
       ((= (nth 7 (file-attributes gtags)) 0)
        (call-interactively #'ggtags-create-tags))
       (t
        (start-process "gtags-update" nil "global" "--incremental"))))))
(add-hook 'after-save-hook #'my-update-gtags)

;;; ------------------------------------------------------------
;;; Eglot（LSP）
;;; ------------------------------------------------------------

(use-package eglot
  :ensure nil
  :hook ((c-mode c++-mode python-mode rust-mode js-mode typescript-mode perl-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs '(c-mode . ("clangd")))
  (add-to-list 'eglot-server-programs '(c++-mode . ("clangd")))
  (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs
               '((js-mode js-ts-mode typescript-mode typescript-ts-mode)
                 . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((perl-mode cperl-mode)
                 . ("perl-language-server"))))

(defun my-eglot-format-buffer-if-managed ()
  "Format current buffer only when it is managed by Eglot."
  (when (and (fboundp 'eglot-managed-p)
             (eglot-managed-p))
    (eglot-format-buffer)))
(add-hook 'before-save-hook #'my-eglot-format-buffer-if-managed)

;;; ------------------------------------------------------------
;;; minibuffer で IME を切る（Windows）
;;; ------------------------------------------------------------

(when (eq system-type 'windows-nt)
  (add-hook 'minibuffer-setup-hook
            (lambda ()
              (deactivate-input-method)
              (set-input-method nil))))

;;; ------------------------------------------------------------
;;; 補完強化：Corfu + Cape + Eglot + Gtags
;;; ------------------------------------------------------------

;; Corfu（補完 UI）
(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 1)
  (corfu-cycle t)
  :init
  (global-corfu-mode 1))

;; Cape（補完ソース）
(use-package cape
  :ensure t
  :bind (("M-/" . cape-dabbrev)
         ("M-<tab>" . cape-file)))

;; Eglot と Corfu の統合
(setq completion-category-defaults nil)
(setq completion-cycle-threshold 3)

;; gtags 補完（ggtags が completion-at-point 関数を提供する環境のみ）
(defun my-enable-gtags-capf ()
  (when (fboundp 'ggtags-completion-at-point)
    (add-hook 'completion-at-point-functions
              #'ggtags-completion-at-point nil t)))
(add-hook 'prog-mode-hook #'my-enable-gtags-capf)

;;; ------------------------------------------------------------
;;; ミニバッファ補完：Vertico + Orderless + Marginalia
;;; ------------------------------------------------------------

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(provide 'init)
;;; init.el ends here
