;;; init-editing.el --- editing ergonomics -*- lexical-binding: t; -*-

;; Buffer-level commands that are not tied to one language. They are
;; defined here and bound in init-keybindings.el, so a binding always
;; points at a named command instead of a lambda.

(require 'cl-lib)

(defun my/recentf-open ()
  "Find a recent file using built-in completion."
  (interactive)
  (find-file (completing-read "Recent file: " recentf-list nil t)))

(defun my/indent-buffer ()
  "Indent the whole buffer, keeping point where it was."
  (interactive)
  (save-excursion
    (indent-region (point-min) (point-max))))

(defun my/duplicate-line (&optional arg)
  "Duplicate the current line ARG times, then restore the column."
  (interactive "p")
  (let ((arg (or arg 1))
        (column (current-column)))
    (dotimes (_ arg)
      (let ((line (buffer-substring (line-beginning-position)
                                    (line-end-position))))
        (end-of-line)
        (newline)
        (insert line)))
    (move-to-column column)))

(defun my/cleanup-whitespace ()
  "Delete trailing whitespace and collapse runs of blank lines."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "[ \t]+$" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "\n\\{3,\\}" nil t)
      (replace-match "\n\n"))))

(provide 'init-editing)
;;; init-editing.el ends here
