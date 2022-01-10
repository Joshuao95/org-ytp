;;; org-ytp.el --- Converts youtube playlists to org headlines -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Copyright (C) 2021 Joshua O'Connor

;; Author: Joshua O'Connor <joshua@joshuao.com>


;;; Commentary:

;; This package access the Youtube Data API in order to create headlines in org
;; representing a Youtube playlist or channel
;; The main function to use is org-ytp-insert-headlines.
;; You'll have to get a Youtube Data API key see here for details: https://developers.google.com/youtube/v3/getting-started
;;; Code:

(require 'org)

(defgroup org-ytp nil
  "org-ytp group"
  :group 'applications)


(defcustom org-ytp-api-key ""
  "Your youtube Data v3 API key."
  :type '(string))

(defcustom org-ytp-headline-prefix nil
  "An optional prefix before video headline, useful for TODO."
  :type '(string))

					;TODO: Add option of adding description or not


					; If you have to change this, like as not the parsing of the JSON is also wrong
(defconst base-url "https://youtube.googleapis.com/youtube/v3/playlistItems")

(defun org-youtube-api-get (url key args)
  "Send ARGS to URL as a GET request authorizing with KEY."
  (let (
        (args-string
         (mapconcat (lambda (arg)
                      (concat (url-hexify-string (car arg))
                              "="
                              (url-hexify-string (cdr arg))))
                    args
                    "&")))
    
    (url-retrieve-synchronously (concat url "?key=" key "&" args-string))))


(defun org-ytp-get-uploads-playlist-id (channel-name)
  "Return 'Uploads' playlist for CHANNEL-NAME."
					;TODO:
  )


(defun org-ytp-get-playlist-page (playlist-id page-token)
  "Return nextPageToken and array of items of PLAYLIST-ID as identified by PAGE-TOKEN."
  
  
  (let* ((buf (org-youtube-api-get base-url org-ytp-api-key `(("part" . "snippet")
							      ("playlistId" . ,playlist-id)
							      ("maxResults" . "10")
							      ("pageToken" . ,page-token))))
	 (json (save-window-excursion (switch-to-buffer buf)
				      (json-parse-buffer))))
    
    (cons (gethash "nextPageToken" json)
	  (gethash "items" json))))



(defun org-ytp-get-playlist-items (playlist-id)
  "Return playlist items array for PLAYLIST-ID."
					; The Youtube API is paginated, so we use the nextPageToken to collect all playlist items into a big array
  (let ((items nil)
	(page-token "")
	(result nil))

  (while page-token
    (setq result (org-ytp-get-playlist-page playlist-id page-token))
    ;; Append the items from the page
    (setq items (vconcat items (cdr result)))
    
    (setq page-token (car result))) ; Will be nil if that was the last page

  items))


(defun org-ytp-link-from-id (video-id)
  "Create Youtube watch link from VIDEO-ID."
  (concat "https://youtube.com/watch?v=" video-id))


(defun org-ytp-headline-from-playlist-item (pl-item)
  "Create headline from PL-ITEM as returned by YouTube Data APIv3."
  (let* ((snippet (gethash "snippet" pl-item))
	 (title (gethash "title" snippet))
	 (description (gethash "description" snippet))
	 (id (gethash "videoId"
		      (gethash "resourceId" snippet) ))
	 )
    (org-insert-heading)

    (if org-ytp-headline-prefix
	(insert org-ytp-headline-prefix))
					;TODO: Optional TODO element here
    (org-insert-link nil (org-ytp-link-from-id id) title)))


(defun org-ytp-insert-headlines (playlist-id)
  "Create 1 org headline per video in playlist described by PLAYLIST-ID."
  (interactive "MPlaylist ID: ")
  (mapc 'org-ytp-headline-from-playlist-item (org-ytp-get-playlist-items playlist-id)))

(provide 'org-ytp)
;;; org-ytp.el ends here
