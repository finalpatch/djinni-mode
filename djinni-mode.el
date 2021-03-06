;;; djinni-mode.el --- An Emacs mode for editing Djinni IDL files

;; Author:  Li Feng <fengli@gmail.com>
;; Maintainer: Li Feng <fengli@gmail.com>
;; Created: October 2020
;; Version: 0.2
;; Keywords: djinni emacs

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'smie)

(defvar djinni-mode-indent-level 4)

(defvar djinni-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)
    (modify-syntax-entry ?\< "(>" st)
    (modify-syntax-entry ?\> ")<" st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?# "<" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?@ "_" st)
    st))

(defconst djinni-mode-keywords '("interface" "record" "enum" "const" "flags" "static" "deriving")
  "List of Djinni keywords.")

(defconst djinni-mode-constants '("none" "all" "eq" "ord")
  "List of Djinni constants.")

(defvar djinni-mode-font-lock-keywords
  `((,(concat "\\<" (regexp-opt djinni-mode-keywords) "\\>")
     (0 font-lock-keyword-face))
    (,(concat "\\<" (regexp-opt djinni-mode-constants) "\\>")
     (0 font-lock-constant-face))
    ("@[a-z]+" . 'font-lock-preprocessor-face)
    ("\\+[cjo]" . 'font-lock-preprocessor-face)
    ("\\([a-zA-Z0-9_]+\\)[ \t\n]*:[ \t\n]*\\([a-zA-Z0-9_]+\\)"
     (1 'font-lock-variable-name-face) (2 'font-lock-type-face))
    (")[ \t\n]*:[ \t\n]*\\([a-zA-Z0-9_]+\\)" . (1 'font-lock-type-face))
    ("^[ \t\n]*\\(\\sw+\\)[ \t\n]*=[ \t\n]*\\(enum\\|flags\\|record\\|interface\\)"
     . (1 'font-lock-type-face))
    ("\\(\\sw+\\)[ \t\n]*<\\(\\sw+\\)>" (1 'font-lock-type-face) (2 'font-lock-type-face))
    ("\\(\\sw+\\)[ \t\n]*<\\(\\sw+\\)[ \t\n]*,[ \t\n]*\\(\\sw+\\)>"
     (1 'font-lock-type-face) (2 'font-lock-type-face) (3 'font-lock-type-face))
    ("^[ \t\n]*\\(static[ \t\n]*\\)?\\(\\sw+\\)[ \t\n]*(" . (2 'font-lock-function-name-face))))

(defun djinni-font-lock-extend-region-func (beg end old-len)
  (save-excursion
    (cons
     (progn (goto-char beg) (backward-word) (point))
     (progn (goto-char end) (forward-word) (point)))))

(defconst djinni-mode-smie-grammar
  (smie-prec2->grammar
   (smie-precs->prec2
    '((right "@import")
      (right "@extern")
      (right "@protobuf")
      (assoc ";")
      (assoc ",")
      (left ":")))))

(defun djinni-mode-smie-rules (method arg)
  "Provide indentation rules for METHOD given ARG.
See the documentation of `smie-rules-function' for further
information."
  (pcase (cons method arg)
    (`(:before . "{")
     (save-excursion
       (smie-backward-sexp) (back-to-indentation)
       `(column . ,(smie-indent-virtual))))
    (`(:before . "(")
     (save-excursion
       (smie-backward-sexp) (back-to-indentation)
       `(column . ,(smie-indent-virtual))))
    (`(:after . "}")
     (save-excursion
       (smie-backward-sexp) (back-to-indentation)
       `(column . ,(smie-indent-virtual))))
    (`(:after . ":") djinni-mode-indent-level)
    (`(:before . "=") djinni-mode-indent-level)
    (`(:elem . basic)
     (save-excursion
       (let ((c (current-column)))
         (smie-backward-sexp) (back-to-indentation)
         (if (looking-at "@")
             (- (current-column) c)
           djinni-mode-indent-level))))))

(defconst djinni-imenu-generic-expression
  '(("*Interfaces*" "^\\(\\sw+\\)\\s-*=\\s-*interface" 1)
    ("*Records*" "^\\(\\sw+\\)\\s-*=\\s-*record" 1)
    ("*Flags*" "^\\(\\sw+\\)\\s-*=\\s-*flags" 1)
    ("*Enums*" "^\\(\\sw+\\)\\s-*=\\s-*enum" 1)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.djinni\\'" . djinni-mode))

;;;###autoload
(define-derived-mode djinni-mode prog-mode "Djinni"
  "A mode for editing Djinni IDL files."
  (setq-local font-lock-defaults '(djinni-mode-font-lock-keywords nil nil nil nil))
  (setq-local font-lock-extend-after-change-region-function #'djinni-font-lock-extend-region-func)
  (setq-local comment-start "# ")
  (setq-local comment-end "")
  (smie-setup djinni-mode-smie-grammar #'djinni-mode-smie-rules)
  (setq-local imenu-generic-expression djinni-imenu-generic-expression))

(provide 'djinni-mode)

;;; djinni-mode.el ends here
