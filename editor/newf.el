;;; newf.el --- newf integration -*- lexical-binding: t; -*-
;;; Commentary:

;;; Code:
(defun newf/insert-template ()
  "Insert newf template output into an empty buffer for a missing file."
  (when (and (buffer-file-name)
             (not (file-exists-p (buffer-file-name)))
             (zerop (buffer-size))
             (not (file-remote-p (buffer-file-name)))
             (executable-find "newf"))
    (let ((file (buffer-file-name)))
      (let ((exit (call-process "newf" nil (list (current-buffer) nil) nil
                                "-o" file)))
        (when (and (integerp exit) (zerop exit))
          (goto-char (point-min)))))
    t))

(add-hook 'find-file-not-found-functions #'newf/insert-template)

(provide 'newf)

;;; newf.el ends here
