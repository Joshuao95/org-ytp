;;; org-ytp.el --- Converts youtube playlists to org headlines -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Copyright (C) 2021 Joshua O'Connor

;; Author: Joshua O'Connor <joshua@joshuao.com>
;; URL: https://git.joshuao.com/joshuao/org-ytp


;;; Commentary:

;; This package access the Youtube Data API in order to create headlines in org
;; representing a Youtube playlist or channel
;; The main function to use is org-ytp-insert-headlines.
;TODO: Talk about not using set in defcustom
					;TODO: Talk about api key

;;; Code:

(require 'org)

(defgroup org-ytp nil
  "org-ytp group"
  :group 'applications)

(defcustom org-ytp-api-key ""
  "Your youtube Data v3 API key."
  :type '(string))

;TODO: Give the option of adding "TODO" or some other prefix?

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


(defun org-ytp-get-playlist-items (playlist-id)
  "Return playlist items array for PLAYLIST-ID."
  ; The Youtube API returns a big JSON blob, we have to dig out what we want.
  (let* ((buf (org-youtube-api-get base-url org-ytp-api-key `(("part" . "snippet")
							      ("playlistId" . ,playlist-id)
							      ("maxResults" . "50"))))
	 (json ((save-window-excursion (switch-to-buffer buf)
				       (json-parse-buffer))))
	 (playlist-items (gethash "items" json)))
	 (message (gethash "nextPageToken" json))

    playlist-items))


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
     (message 
     (org-insert-heading)

					;TODO: Optional TODO element here
     (org-insert-link nil (org-ytp-link-from-id id) title)))


(defun org-ytp-insert-headlines (playlist-id)
  "Create 1 org headline per video in playlist described by PLAYLIST-ID."
  (interactive "MPlaylist ID: ")
  ;TODO: Paginate
  (mapc 'org-ytp-headline-from-playlist-item (org-ytp-get-playlist-items playlist-id)))

(provide 'org-ytp)
;;; org-ytp.el ends here


