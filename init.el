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

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

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

(defvar my-core-packages
  '(use-package compat color-moccur ggtags corfu cape vertico orderless marginalia)
  "Packages installed automatically for this Emacs configuration.")

(defun my-install-package-if-missing (pkg)
  "Install PKG when it is not already available."
  (unless (package-installed-p pkg)
    (message "Installing package: %s" pkg)
    (package-install pkg)))

(defun my-ensure-core-packages ()
  "Install packages required by this init.el."
  (let ((missing (cl-remove-if #'package-installed-p my-core-packages)))
    (when missing
      (package-refresh-contents)
      (mapc #'my-install-package-if-missing missing))))

(my-ensure-core-packages)
(require 'use-package)
(setq use-package-always-ensure t)

;;; ------------------------------------------------------------
;;; color-moccur（インストール済み前提）
;;; ------------------------------------------------------------

(use-package color-moccur
  :ensure t
  :config
  (setq moccur-split-word t
        moccur-following-mode-toggle nil
        moccur-grep-following-mode-toggle nil
        moccur-view-other-window nil
        moccur-view-other-window-nobuf nil))

(defvar my-moccur-file-coding-system 'undecided-dos
  "Coding system used when color-moccur reads files for grep results.")

(defun my-moccur-search-files-with-coding (orig-fun &rest args)
  "Decode Japanese files and preserve windows in color-moccur results."
  (let ((coding-system-for-read my-moccur-file-coding-system))
    (cl-letf (((symbol-function 'delete-other-windows) #'ignore))
      (apply orig-fun args))))

(with-eval-after-load 'color-moccur
  (unless (advice-member-p #'my-moccur-search-files-with-coding
                           'moccur-search-files)
    (advice-add 'moccur-search-files
                :around #'my-moccur-search-files-with-coding)))

;;; ------------------------------------------------------------
;;; ggtags
;;; ------------------------------------------------------------

(use-package ggtags
  :ensure t
  :custom
  (ggtags-auto-jump-to-match nil))

(defun my-ggtags-global-build-command-no-verbose (orig-fun &rest args)
  "Remove Global's verbose flag to keep progress text out of results."
  (string-replace " -v " " " (apply orig-fun args)))

(with-eval-after-load 'ggtags
  (unless (advice-member-p #'my-ggtags-global-build-command-no-verbose
                           'ggtags-global-build-command)
    (advice-add 'ggtags-global-build-command
                :around #'my-ggtags-global-build-command-no-verbose)))

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
(global-set-key (kbd "<f6>") #'toggle-truncate-lines)

(global-set-key (kbd "<M-return>") #'toggle-frame-fullscreen)

;;; ------------------------------------------------------------
;;; ジャンプ先表示（検索結果からの自動分割を抑制）
;;; ------------------------------------------------------------

(defvar my-last-source-window nil
  "Last selected non-result window used as a jump target.")

(defun my-result-buffer-p (&optional buffer)
  "Return non-nil when BUFFER is a search/result buffer."
  (with-current-buffer (or buffer (current-buffer))
    (or (derived-mode-p 'compilation-mode 'grep-mode)
        (memq major-mode '(ggtags-global-mode xref--xref-buffer-mode))
        (string-match-p
         "\\`\\*\\(ripgrep\\|grep\\|ggtags\\|xref\\|compilation\\|Moccur\\|ee-outline\\|Search\\)"
         (buffer-name)))))

(defun my-source-window-p (window)
  "Return non-nil when WINDOW can be reused for source navigation."
  (and (window-live-p window)
       (not (window-minibuffer-p window))
       (not (window-dedicated-p window))
       (not (my-result-buffer-p (window-buffer window)))))

(defun my-record-source-window ()
  "Remember the last selected window that is suitable for source buffers."
  (when (my-source-window-p (selected-window))
    (setq my-last-source-window (selected-window))))

(add-hook 'post-command-hook #'my-record-source-window)

(defun my-navigation-target-window (buffer)
  "Return an existing window to display BUFFER without splitting."
  (or (get-buffer-window buffer 0)
      (and (my-source-window-p my-last-source-window)
           my-last-source-window)
      (cl-find-if #'my-source-window-p (window-list nil 'no-minibuf))
      (selected-window)))

(defun my-switch-to-buffer-no-split (buffer-or-name &optional norecord force-same-window)
  "Switch to BUFFER-OR-NAME in an existing reusable window."
  (let* ((buffer (if (bufferp buffer-or-name)
                     buffer-or-name
                   (get-buffer-create buffer-or-name)))
         (window (my-navigation-target-window buffer)))
    (select-window window norecord)
    (switch-to-buffer buffer norecord force-same-window)
    window))

(defun my-pop-to-buffer-no-split (buffer-or-name &optional _action norecord)
  "Pop to BUFFER-OR-NAME without creating a new window."
  (my-switch-to-buffer-no-split buffer-or-name norecord))

(defun my-find-file-no-split (filename &optional wildcards)
  "Visit FILENAME without creating a new window."
  (let ((buffer (find-file-noselect filename nil nil wildcards)))
    (my-switch-to-buffer-no-split buffer)))

(defun my-moccur-goto-no-split (orig-fun &rest args)
  "Display color-moccur jump targets without creating windows."
  (cl-letf (((symbol-function 'switch-to-buffer-other-window)
             #'my-switch-to-buffer-no-split)
            ((symbol-function 'find-file-other-window)
             #'my-find-file-no-split)
            ((symbol-function 'pop-to-buffer)
             #'my-pop-to-buffer-no-split)
            ((symbol-function 'delete-other-windows)
             #'ignore))
    (apply orig-fun args)))

(with-eval-after-load 'color-moccur
  (dolist (fn '(moccur-grep-goto moccur-mode-goto-occurrence))
    (unless (advice-member-p #'my-moccur-goto-no-split fn)
      (advice-add fn :around #'my-moccur-goto-no-split))))

(defun my-compilation-goto-locus-no-split (orig-fun msg mk end-mk)
  "Display compilation and ggtags jump targets without creating windows."
  (let ((original-pop-to-buffer (symbol-function 'pop-to-buffer)))
    (cl-letf (((symbol-function 'pop-to-buffer)
               (lambda (buffer-or-name &optional action norecord)
                 (if (eq action 'other-window)
                     (let* ((buffer (get-buffer-create buffer-or-name))
                            (window (my-navigation-target-window buffer)))
                       (select-window window norecord)
                       (switch-to-buffer buffer norecord)
                       window)
                   (funcall original-pop-to-buffer
                            buffer-or-name action norecord)))))
      (funcall orig-fun msg mk end-mk))))

(with-eval-after-load 'compile
  (setq compilation-auto-jump-to-first-error nil)
  (advice-add 'compilation-goto-locus
              :around #'my-compilation-goto-locus-no-split))

(add-to-list 'display-buffer-alist
             '("\\`\\*\\(ripgrep\\|grep\\|ggtags-global\\|Ggtags Search History\\|xref\\|Occur\\|Moccur\\|ee-outline\\|Search\\)"
               (display-buffer-same-window)))

;;; ------------------------------------------------------------
;;; isearch
;;; ------------------------------------------------------------

(setq search-upper-case t)

(with-eval-after-load 'isearch
  (define-key isearch-mode-map (kbd "TAB") #'isearch-yank-symbol-or-char)
  (define-key isearch-mode-map (kbd "<tab>") #'isearch-yank-symbol-or-char))

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
;;; 外部変更の自動反映
;;; ------------------------------------------------------------

(setq auto-revert-verbose nil
      auto-revert-stop-on-user-input nil)
(global-auto-revert-mode 1)

;;; ------------------------------------------------------------
;;; auto-insert（C/C++ テンプレート）
;;; ------------------------------------------------------------

(require 'autoinsert)

(setq auto-insert-directory
      (expand-file-name "site-lisp/auto-insert/" user-emacs-directory))
(setq auto-insert-query nil)

(defun my-auto-insert--include-guard ()
  "Return an include guard name for the current buffer file."
  (let* ((file (file-name-nondirectory (or buffer-file-name "header.h")))
         (guard (upcase (replace-regexp-in-string "[^[:alnum:]]+" "_" file))))
    (string-trim guard "_" "_")))

(defun my-auto-insert--replace-placeholder (placeholder replacement)
  "Replace PLACEHOLDER with REPLACEMENT in the current buffer."
  (save-excursion
    (goto-char (point-min))
    (while (search-forward placeholder nil t)
      (replace-match replacement t t))))

(defun my-auto-insert--template (template)
  "Insert TEMPLATE from `auto-insert-directory' and expand placeholders."
  (let ((template-file (expand-file-name template auto-insert-directory)))
    (unless (file-readable-p template-file)
      (user-error "Template file is not readable: %s" template-file))
    (insert-file-contents template-file)
    (my-auto-insert--replace-placeholder
     "%file%" (file-name-nondirectory (or buffer-file-name "")))
    (my-auto-insert--replace-placeholder
     "%include-guard%" (my-auto-insert--include-guard))))

(defun my-auto-insert-c-template ()
  "Insert the C source template."
  (my-auto-insert--template "template.c"))

(defun my-auto-insert-h-template ()
  "Insert the C header template."
  (my-auto-insert--template "template.h"))

(define-auto-insert '("\\.c\\'" . "C source template")
  #'my-auto-insert-c-template)
(define-auto-insert '("\\.h\\'" . "C header template")
  #'my-auto-insert-h-template)

(auto-insert-mode 1)

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
(set-face-attribute 'hl-line nil
                    :background "#303030"
                    :extend t)
(set-face-attribute 'region nil
                    :background "#4f5b93"
                    :foreground "#ffffff"
                    :extend t)

;;; ------------------------------------------------------------
;;; whitespace
;;; ------------------------------------------------------------

(use-package whitespace
  :ensure nil
  :custom
  (whitespace-style '(face trailing tabs))
  (whitespace-action nil)
  :config
  (global-whitespace-mode 1))

(defun my-disable-save-whitespace-cleanup ()
  "Keep trailing spaces and tabs intact when saving."
  (remove-hook 'before-save-hook #'delete-trailing-whitespace t)
  (remove-hook 'before-save-hook #'whitespace-cleanup t))

(add-hook 'prog-mode-hook #'my-disable-save-whitespace-cleanup)
(add-hook 'text-mode-hook #'my-disable-save-whitespace-cleanup)
(add-hook 'before-save-hook #'my-disable-save-whitespace-cleanup)

;;; ------------------------------------------------------------
;;; タブ設定
;;; ------------------------------------------------------------

(setq-default tab-width 4)
(setq-default indent-tabs-mode t)
(setq tab-always-indent nil)
(setq-default c-basic-offset 4)
(setq-default c-ts-mode-indent-offset 4)
(setq c-default-style
      '((java-mode . "java")
        (awk-mode . "awk")
        (other . "bsd")))

(defun my-tab-setup ()
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode t))
(add-hook 'prog-mode-hook #'my-tab-setup)
(add-hook 'text-mode-hook #'my-tab-setup)

(defun my-insert-literal-tab ()
  "Insert a literal tab character."
  (interactive)
  (insert "\t"))

(global-set-key (kbd "C-c TAB") #'my-insert-literal-tab)
(global-set-key (kbd "C-c <tab>") #'my-insert-literal-tab)

(defun my-c-mode-setup ()
  "Configure C/C++ indentation without electric brace reformatting."
  (c-set-style "bsd")
  (setq-local c-basic-offset 4)
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode t)
  (setq-local electric-indent-inhibit t)
  (setq-local c-auto-newline nil)
  (setq-local c-electric-flag nil)
  (local-set-key (kbd "RET") #'newline-and-indent))

(add-hook 'c-mode-common-hook #'my-c-mode-setup)

(defun my-c-ts-mode-setup ()
  "Configure tree-sitter C/C++ indentation to use 4-column tabs."
  (setq-local c-ts-mode-indent-offset 4)
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode t)
  (setq-local electric-indent-inhibit t)
  (local-set-key (kbd "RET") #'newline-and-indent))

(add-hook 'c-ts-base-mode-hook #'my-c-ts-mode-setup)
(add-hook 'c-ts-mode-hook #'my-c-ts-mode-setup)
(add-hook 'c++-ts-mode-hook #'my-c-ts-mode-setup)

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
  (setq eglot-ignored-server-capabilities
        '(:documentFormattingProvider
          :documentRangeFormattingProvider
          :documentOnTypeFormattingProvider))
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

(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)
;;; init.el ends here
