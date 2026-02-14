;;; tangle.el --- Tangle config.org with #+INCLUDE expansion -*- lexical-binding: t; -*-

;; Usage:
;;   emacs --batch -l tangle.el
;;   emacs --batch -l tangle.el --eval '(org-tangle-config "path/to/config.org")'

;;; Commentary:

;; `org-babel-tangle-file' does NOT expand #+INCLUDE directives, as those
;; are part of the export framework (ox.el).  This script works around that
;; by expanding all #+INCLUDE keywords in the buffer before tangling.

;;; Code:

(require 'org)
(require 'ob-tangle)
(require 'ox)

(defun org-tangle-escape-latex-for-elisp ()
  "Double backslashes and escape quotes in LaTeX source blocks that will be
embedded in Emacs Lisp strings via noweb references.

When org-babel expands a noweb reference like <<name>> inside an emacs-lisp
string, the raw LaTeX text is inserted verbatim.  Backslash sequences such as
\\usepackage are then misread by the Emacs Lisp reader (\\u as Unicode escape,
\\n as newline, \\t as tab, etc.).  This function escapes LaTeX block content
so the tangled output contains valid Emacs Lisp string literals."
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search t))
      (while (re-search-forward "^[ \t]*#\\+begin_src[ \t]+la?tex\\b" nil t)
        (let ((block-header-beg (line-beginning-position))
              (should-escape nil))
          ;; Check 1: #+name: on preceding affiliated-keyword lines
          (save-excursion
            (goto-char block-header-beg)
            (forward-line -1)
            (while (and (not (bobp))
                        (looking-at-p "^[ \t]*#\\+"))
              (when (looking-at-p "^[ \t]*#\\+name:")
                (setq should-escape t))
              (forward-line -1)))
          ;; Check 2: :noweb-ref in the #+begin_src header line
          (unless should-escape
            (save-excursion
              (goto-char block-header-beg)
              (when (re-search-forward ":noweb-ref" (line-end-position) t)
                (setq should-escape t))))
          ;; Check 3: :noweb-ref inherited from ancestor heading properties
          (unless should-escape
            (ignore-errors
              (save-excursion
                (goto-char block-header-beg)
                (while (and (not should-escape)
                            (org-up-heading-safe))
                  (dolist (prop '("header-args:LaTeX" "header-args:latex"))
                    (let ((val (org-entry-get nil prop)))
                      (when (and val (string-match-p ":noweb-ref" val))
                        (setq should-escape t))))))))
          ;; Perform escaping
          (when should-escape
            (let ((content-start (line-beginning-position 2))
                  (end-marker
                   (save-excursion
                     (when (re-search-forward "^[ \t]*#\\+end_src" nil t)
                       (copy-marker (line-beginning-position))))))
              (when end-marker
                ;; Step 1: Double all backslashes  (\foo -> \\foo)
                (goto-char content-start)
                (while (search-forward "\\" end-marker t)
                  (replace-match "\\\\" t t))
                ;; Step 2: Escape double quotes  (" -> \")
                (goto-char content-start)
                (while (search-forward "\"" end-marker t)
                  (replace-match "\\\"" t t))
                (set-marker end-marker nil)))))))))

(defun org-tangle-config (&optional file)
  "Tangle FILE (or config.org in the same directory as this script) with
#+INCLUDE directives expanded first."
  (let* ((file (or file
                   (expand-file-name "config.org"
                                     (if load-file-name
                                         (file-name-directory load-file-name)
                                       default-directory))))
         (org-confirm-babel-evaluate nil)
         (temp-file (make-temp-file "org-tangle-" nil ".org")))
    (message "Tangling %s ..." file)
    (unwind-protect
        (progn
          ;; Create a temporary file with expanded content
          (with-temp-buffer
            (insert-file-contents file)
            (org-mode)
            (setq default-directory (file-name-directory file))
            ;; Expand includes
            (org-export-expand-include-keyword)
            ;; Escape LaTeX blocks for Emacs Lisp string embedding via noweb
            (org-tangle-escape-latex-for-elisp)
            ;; Write to temp file
            (write-region (point-min) (point-max) temp-file nil 'silent))
          ;; Tangle from the temp file
          (with-current-buffer (find-file-noselect temp-file)
            (setq default-directory (file-name-directory file)
                  buffer-file-name file)  ; Set buffer-file-name to original file
            (org-mode-restart)
            (org-babel-tangle))
          (message "Tangling complete, %s" file))
      ;; Always clean up the temp file
      (when (file-exists-p temp-file)
        (delete-file temp-file)))))

;; Auto-run when loaded in batch mode.
(when noninteractive
  (org-tangle-config))

;;; tangle.el ends here
