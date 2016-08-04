;;; ciel.el --- A command that is clone of "ci" in vim.

;; Copyright (C) 2016 Takuma Matsushita

;; Author: Takuma Matsushita <cs14095@gmail.com>
;; Created: 2 Jul 2016
;; Version: 0.0.1
;; Keywords: convinience
;; Homepage: https://github.com/cs14095/ciel.el
;; Package-Requires: ((emacs "24"))


;; This file is not part of GNU Emacs

;; The MIT License (MIT)

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;;; Commentary:

;; You can use ci", ci', ci(, ci{ and ciw entering `Ctrl-c, i`.
;; Also you can copy them with `Ctrl-c, o` instead of `Ctrl-c, i`.
;; This is standalone package and you can probably use any mode.

;; **Now at work! I highly recommend updating every week!**
;; I decided to remove cit on master branch, because it's too heavy.
;; Other command is still available, but some code is broken.
;; I will fix in summer vacation...

;; ## Usage

;; Press `Ctrl-c, i` or `Ctrl-c, o` and enter available character.
;; Watch example or vim usage.

;; ## Example

;; 	Ctrl-c, i, w => kill a word
;; 	Ctrl-c, i, [<>] => kill inside <>
;; 	Ctrl-c, i, ' => kill inside ''
;; 	Ctrl-c, i, " => kill inside ""
;; 	Ctrl-c, i, [()] => kill inside ()
;; 	Ctrl-c, i, [{}] => kill inside {}
;;
;; 	Ctrl-c, o, w => copy a word
;; 	Ctrl-c, o, [<>] => copy inside <>
;; 	Ctrl-c, o, ' => copy inside ''
;; 	Ctrl-c, o, " => copy inside ""
;; 	Ctrl-c, o, [()] => copy inside ()
;; 	Ctrl-c, o, [{}] => copy inside {}

;; you can also kill nested parentheses as you can see.
;; https://raw.githubusercontent.com/cs14095/cs14095.github.io/master/ci-el.gif


;;; Code:

(defvar ciel-mode-map nil
  "Keymap used in ciel-mode.")
(unless ciel-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c i") 'ciel-ci)
    (define-key map (kbd "C-c o") 'ciel-co)
    (setq ciel-mode-map map)))

(defvar ciel-mode-lighter " ci")

;;;###autoload
(defun ciel-ci (arg)
  ""
  (interactive "sci: ")
  (let ((%region))
    (cond ((or (string= arg "(") (string= arg ")")) (setq %region (region-paren "(")))
	  ((or (string= arg "[") (string= arg "]")) (setq %region (region-paren "[")))
	  ((or (string= arg "{") (string= arg "}")) (setq %region (region-paren "{")))
	  ((or (string= arg "\"")
	       (string= arg "\'")
	       (string= arg "\`"))
	   (setq %region (region-quote arg)))
	  ((string= arg "w") (setq %region (region-word)))
	  )
    (unless (null %region)
      (kill-region (car %region) (cadr %region)))
    )
  )

;;;###autoload
(defun ciel-co (arg)
  "COpy inside."
  (interactive "sco: ")
  (let ((%region))
    (cond ((or (string= arg "(") (string= arg ")")) (setq %region (region-paren "(")))
	  ((or (string= arg "[") (string= arg "]")) (setq %region (region-paren "[")))
	  ((or (string= arg "{") (string= arg "}")) (setq %region (region-paren "{")))
	  ((or (string= arg "\"")
	       (string= arg "\'")
	       (string= arg "\`"))
	   (setq %region (region-quote arg)))
	  ((string= arg "w") (setq %region (region-word)))
	  )
    (unless (null %region)
      (copy-region-as-kill (car %region) (cadr %region)))
    )
  )

;;;###autoload
(define-minor-mode ciel-mode
  "Minor mode for ciel."
  :lighter ciel-mode-lighter
  :global t
  ciel-mode-map
  :group 'ciel)

(defun region-paren (arg)
  (interactive "s") 
  (let ((%beginning) (%end) (%target))
    (move-to-parent-parenthesis arg)
    (setq %beginning (1+ (point)))
    (forward-list)
    (setq %end (1- (point)))
    (goto-char (1- (point)))
    (list %beginning %end)
    )
  )

(defun move-to-parent-parenthesis (arg)
  "

( %point% ) => left paren is parent.
( %point% ( => left paren is parent.
) %point% ) => right paren is parent.
) %point% ( => find parent.  the t of the second cond form is it."
  (let ((%target arg) (%init (point)) (%regexp) (%pair))
    (catch 'process 
    (cond ((string= %target "(") (setq %regexp "[()]"))
	  ((string= %target "{") (setq %regexp "[{}]"))
	  ((string= %target "[") (setq %regexp "[][]")))
    (cond ((string= %target "(") (setq %pair ")"))
	  ((string= %target "{") (setq %pair "}"))
	  ((string= %target "[") (setq %pair "]")))

    (when (string= %target (char-to-string (following-char)))
      (throw 'process nil)) ;; end here
    (when (string= %pair (char-to-string (preceding-char)))
      (backward-list)
      (throw 'process nil)) ;; end here
    
    (re-search-backward %regexp)
    (while (nth 3 (syntax-ppss)) ;; ignore commented
      (re-search-backward %regexp))
    (cond ((string= %target (char-to-string (following-char))) ;; backward is (, { or [
	   ;; do nothing cuz here is parent
	   )
	  (t
	   (goto-char %init)
	   (re-search-forward %regexp)
	   (while (nth 3 (syntax-ppss))
	     (re-search-forward %regexp)) 
	   (cond ((string= %target (char-to-string (following-char))) ;; forward is (
		  ;; do nothing
		  )
		 (t (let ((%count 0)) ;; here is in the case of ) %point (
		      (goto-char %init) 
		      (while (not (= %count 1))
			(re-search-backward %regexp)
			(while (nth 3 (syntax-ppss)) ;; ignore commented
			  (re-search-backward %regexp))
			(cond ((string= %target (char-to-string (following-char)))
			       (setq %count(1+ %count)))
			      (t (setq %count (1- %count))))
			))))
	   ))
    )))


(defun region-quote (arg)
  (let ((%init (point)) (%beg nil) (%end nil) (%fw 0) (%cur (point)))
    (search-backward arg nil t 1)
    (goto-char %init)
    (cond ((string= arg (char-to-string (following-char)))
	  (search-forward arg nil t 1)
	  (goto-char %init)
	  (while (> (line-end-position) (match-beginning 0))
	    (setq %cur (match-end 0))
	    (setq %fw (1+ %fw))
	    (goto-char %cur)
	    (search-forward arg nil t 1)
	    (goto-char %init)
	    )
	  
	  (goto-char %init)
	  (cond ((= 0 (mod %fw 2))
		 (catch 'no-match-in-line-error ;; break when run into next line
		   (forward-char) ;; to avoid matching head
		   (search-forward arg)
		   (goto-char %init)
		   (cond ((< (line-end-position) (match-beginning 0)) (throw 'no-match-in-line-error nil)))
		   (setq %end (match-beginning 0))

		   (forward-char)
		   (search-backward arg)
		   (goto-char %init)
		   (cond ((> (line-beginning-position) (match-beginning 0)) (throw 'no-match-in-line-error nil)))
		   (setq %beginning (match-end 0))
		   
		   (goto-char %beginning)
		   (list %beginning %end)
		   ))
		(t
		 (catch 'no-match-in-line-error ;; break when run into next line
		   (search-backward arg)
		   (goto-char %init)
		   (cond ((> (line-beginning-position) (match-beginning 0)) (throw 'no-match-in-line-error nil)))
		   (setq %beginning (match-end 0))

		   (search-forward arg)
		   (goto-char %init)
		   (cond ((< (line-end-position) (match-beginning 0)) (throw 'no-match-in-line-error nil)))
		   (setq %end (match-beginning 0))
		   
		   (goto-char %beginning)
		   (list %beginning %end)
		   )))
	  )
	  (t
	   (goto-char %init)
	   (catch 'no-match-in-line-error ;; break when run into next line
	     (search-backward arg)
	     (goto-char %init)
	     (cond ((> (line-beginning-position) (match-beginning 0)) (throw 'no-match-in-line-error nil)))
	     (setq %beginning (match-end 0))

	     (search-forward arg)
	     (goto-char %init)
	     (cond ((< (line-end-position) (match-beginning 0)) (throw 'no-match-in-line-error nil)))
	     (setq %end (match-beginning 0))
	     
	     (goto-char %beginning)
	     (list %beginning %end)
	     )))
    )
  )

;; just select word
(defun region-word ()
  (let ((%beginning) (%end) (%init (point)))
    (forward-word 1)
    (setq %beginning (point))
    (backward-word 1)
    (setq %end (point))
    (goto-char %init)
    (list %beginning %end)
    )
  )

(provide 'ciel)
;;; ciel.el ends here
