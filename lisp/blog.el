(defun bryan/blog ()
  (setq bryan/blog-blogdir "~/org/new-site/")
  (setq bryan/blog-indexfile (concat bryan/blog-blogdir "index.org"))
  (setq bryan/blog-rssfile (concat bryan/blog-blogdir "rss.org"))

  (setq org-publish-project-alist
        '(("blog"
           :base-directory "~/org/new-site/"
           :publishing-directory "~/org/new-site/"
           :recursive t

           :base-extension "org"
           :html-extension "html"

           :publishing-function (org-html-publish-to-html)
           :exclude "rss.org"

           :html-preamble "<h1 class=\"title\"><a href=\"http://bryangarza.github.io\">val bryan : sushi -> emacs -> code </a></h1>"
           :html-postamble
           (lambda (info)
             "Do not show archive link in Archive, show link to index instead"
             (cond ((string= (car (plist-get info :title)) "Archive")
                    "<a href=\"./\">Back to index</a>")
                   (t "<a href=\"archive.html\">Archive</a>")))

           :html-doctype "html5"
           :with-author: nil
           :with-toc nil
           :with-timestamps t
           :with-tables t
           :section-numbers nil
           :with-smart-quotes t
           ;; :html-head-include-default-style nil
           ;; :html-head-include-scripts nil

           :html-head "
<link href=\"https://fonts.googleapis.com/css?family=Source+Code+Pro\" rel=\"stylesheet\" type=\"text/css\">
<link href=\"./css/styles2.css\" rel=\"stylesheet\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"./css/styles.css\"/>"

           :auto-sitemap t
           :sitemap-filename "archive.org"
           :sitemap-title "Archive"
           :sitemap-sort-files anti-chronologically
           :sitemap-style list)

          ("blog-rss"
           :base-directory "~/org/new-site/"
           :base-extension "org"
           :publishing-directory "~/org/new-site/"
           :publishing-function (org-rss-publish-to-rss)
           :html-link-home "http://bryangarza.github.io/"
           :html-link-use-abs-url t
           :exclude ".*"
           :include ("rss.org")
           :with-toc nil
           :section-numbers nil
           :title "Camels, Aliens, &amp; Other Strange Creatures")))

  (defadvice org-rss-headline
      (around my-rss-headline (headline contents info) activate)
    "only use org-rss-headline for top level headlines"
    (if (< (org-export-get-relative-level headline info) 2)
        ad-do-it
      (setq ad-return-value (org-html-headline headline contents info))))

  ;; use <header>, <aside>, and other fancy tags
  (setq org-html-validation-link nil)
  (setq org-html-doctype "html5")
  (setq org-html-html5-fancy t)
  (setq org-html-htmlize-output-type 'css) ; default: 'inline-css
  (setq org-html-htmlize-font-prefix "org-")) ; default "org-"

(defun bryan/org-escape-html (str)
  (mapconcat #'identity `("" "#+BEGIN_HTML" ,str "#+END_HTML" "") "\n"))

(defun bryan/blog-new-post (title keywords description)
  "Create a new post"
  (interactive "sTitle: \nsKeywords: \nsDescription: ")
  ;; (message "Keywords are: %s" keywords)
  (let* ((filename-prepared (string-trim
                             (replace-regexp-in-string " " "-" (downcase title))))
         (relfile (concat filename-prepared ".org"))
         (relfile-html (concat "./" filename-prepared ".html"))
         (absfile (concat bryan/blog-blogdir relfile))
         (date (format-time-string "[%Y-%m-%d %a]"))
         (date-day-not-padded (string-trim (format-time-string "%e")))
         (mon (format-time-string "%B"))
         (yr (format-time-string "%Y"))
         (date-human-readable
          (concat "(" mon (format " %s, " date-day-not-padded) yr ")"))
         (my-html-link-and-span
          `(,(html-a
              :href relfile-html title)
            ,(html-span " ")
            ,(html-span
              :class "timestamp-wrapper"
              (html-span
               :class "timestamp"
               date-human-readable)))))

    (with-current-buffer (find-file-noselect bryan/blog-indexfile)
      (goto-char (point-min))
      (search-forward ">@@")
      (insert "\n#+BEGIN_HTML\n")
      (html-lite-write-tree-single-line
       (butlast
        (html-div
         :class "outline-3"
         (html-h3
          my-html-link-and-span))))
      (insert "\n#+END_HTML\n")
      (insert (format "#+INCLUDE: \"%s\" :lines \"11-\"" relfile))
      (insert (bryan/org-escape-html "</div>"))
      (with-temp-message (format "Writing to %s" bryan/blog-indexfile)
        (save-buffer))
      (message "Writing file...done"))

    ;; (with-current-buffer (find-file-noselect bryan/blog-rssfile)
    ;;   (goto-char (point-min))
    ;;   (-each `(,(format "* [[./%s][%s]]\n" relfile title) ; heading level 1
    ;;            ":PROPERTIES:\n"
    ;;            ,(format ":RSS_PERMALINK: %s\n" (concat filename-prepared ".html"))
    ;;            ,(format ":PUBDATE: %s\n" (format-time-string "<%Y-%m-%d %a>"))
    ;;            ":END:\n"
    ;;            ,(format "#+INCLUDE: \"%s\" :lines \"8-\"\n" relfile))
    ;;     'insert)
    ;;   (with-temp-message (format "Writing to %s" bryan/blog-rssfile)
    ;;     (save-buffer))
    ;;   (message "Writing file...done"))

    (with-temp-buffer
      (-each `(,(format "#+TITLE: %s\n" title)
               ,(format "#+DATE: %s\n" date)
               ,(format "#+KEYWORDS: %s\n" keywords)
               ,(format "#+DESCRIPTION: %s\n" description)
               "#+OPTIONS: title:nil\n\n"
               "#+BEGIN_HTML\n")
        #'insert)
      (html-lite-write-tree-single-line
       (html-header
        (html-h1 :class "title" my-html-link-and-span)))
      (insert "\n#+END_HTML\n\n")
      (when (file-writable-p absfile)
        (write-region (point-min)
                      (point-max)
                      absfile)))
    (find-file absfile))
  (goto-char (point-max))
  (message "Generated template"))

(provide 'bryan-blog)
