;;; init.el --- my Emacs 30 config  -*- lexical-binding: t; -*-

;;; ------------------------------------------------------------
;;; 基本設定
;;; ------------------------------------------------------------

(setq inhibit-startup-message t
      inhibit-startup-screen t)

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;;; ------------------------------------------------------------
;;; パッケージ管理
;;; ------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

;;; ------------------------------------------------------------
;;; 必要パッケージの自動インストール
;;; ------------------------------------------------------------

(defvar my-required-packages '(ggtags color-moccur))

(defun my-install-missing-packages ()
  (dolist (pkg my-required-packages)
    (unless (package-installed-p pkg)
      (package-refresh-contents)
      (package-install pkg))))
(my-install-missing-packages)

(require 'ggtags)

(require 'color-moccur)
(setq moccur-split-word t)

;;; ------------------------------------------------------------
;;; PATH（MSYS2 UCRT64 の LSP サーバーを Emacs に認識させる）
;;; ------------------------------------------------------------

(add-to-list 'exec-path "C:/msys64/ucrt64/bin")
(setenv "PATH" (concat "C:/msys64/ucrt64/bin;" (getenv "PATH")))

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
  (set-face-attribute 'default nil :family "Cica" :height 110)
  (set-face-attribute 'fixed-pitch nil :family "Cica" :height 110)
  (set-face-attribute 'variable-pitch nil :family "Cica" :height 110))

(global-hl-line-mode 1)
(load-theme 'wombat t)

;;; ------------------------------------------------------------
;;; whitespace
;;; ------------------------------------------------------------

(require 'whitespace)
(setq whitespace-style '(face trailing tabs))
(global-whitespace-mode 1)

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
(require 'project)
(add-to-list 'xref-backend-functions #'xref-gtags-backend)

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
     (ignore-errors (call-interactively #'ggtags-find-tag-dwim))
     (ignore-errors (call-interactively #'xref-find-definitions))
     (ignore-errors (call-interactively #'eglot-find-declaration))
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
     (format "rg -n --no-heading --color never --glob \"*\" -- %s \"%s\""
             (shell-quote-argument pattern)
             root)
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
             (executable-find "global"))
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

(require 'eglot)

(dolist (hook '(c-mode-hook
                c++-mode-hook
                python-mode-hook
                rust-mode-hook
                js-mode-hook
                typescript-mode-hook
                perl-mode-hook))
  (add-hook hook #'eglot-ensure))

(add-to-list 'eglot-server-programs '(c-mode . ("clangd")))
(add-to-list 'eglot-server-programs '(c++-mode . ("clangd")))
(add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
(add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
(add-to-list 'eglot-server-programs
             '((js-mode js-ts-mode typescript-mode typescript-ts-mode)
               . ("typescript-language-server" "--stdio")))
(add-to-list 'eglot-server-programs
             '((perl-mode cperl-mode)
               . ("perl-language-server")))

(add-hook 'before-save-hook #'eglot-format-buffer)

;;; ------------------------------------------------------------
;;; minibuffer で IME を切る（Windows）
;;; ------------------------------------------------------------

(when (eq system-type 'windows-nt)
  (add-hook 'minibuffer-setup-hook
            (lambda ()
              (deactivate-input-method)
              (set-input-method nil))))

(provide 'init)
;;; init.el ends here
