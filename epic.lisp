(defpackage :cl-epic
  (:use :cl :drakma :html5-parser))

(in-package :cl-epic)

(defparameter *epic-site* "https://epic.gsfc.nasa.gov/" "URL of the EPIC image website")
(defparameter *picdir* "pics/" "Directory to store downloaded EPIC images")

(defvar *html* nil "HTML of EPIC website")
(defvar *xmls* nil "EPIC website converted to XMLS tree")
(defvar *picurls* nil "List of URLs to individual EPIC images for the current EPIC web site")

(defun date-to-datestring (yyyy mm dd &optional (sepchar #\-))
  "Convert numeric YYYY MM DD to a datestring with optional separation character ('-' by default"
  (format nil "~4,'0D~c~2,'0D~c~2,'0D" yyyy sepchar mm sepchar dd))

(defun download-site (&optional date &key (site *epic-site*))
  "Retrieve EPIC web page for specified date as a list of (YYYY MM DD)"
  (setq *html* (if date
		   (http-request (concatenate 'string site "?date=" (apply #'date-to-datestring date)))
		   (http-request site)))
  (setq *xmls* (parse-html5 *html* :dom :xmls)))

(defun find-pic-urls (&optional (xmls *xmls*))
  "Generate list of URLs to individual EPIC images in the downloaded site XMLS"
  (let (urls)
    (tree-equal xmls xmls :test (lambda (el-1 el-2)
				  (declare (ignore el-2))
				  (when (and (search "archive/natural" el-1) (search "png" el-1))
				    (push el-1 urls))
				  t))
    (setq *picurls* (remove-duplicates urls :test #'string=))))

(defun get-file-name (pic-url)
  "Generate a list of individual filenames from an image URL list"
  (let ((pos0 (1+ (position #\/ pic-url :from-end t)))
	(pos1 (length pic-url)))
    (subseq pic-url pos0 pos1)))

(defun download-pics (date &optional (pic-urls *picurls*))
  "Download picture URLs to files, stored in subdirectory pics/YYYY/MM/DD"
  (destructuring-bind (yyyy mm dd) date
    (let ((pic-dir (concatenate 'string *picdir* (date-to-datestring yyyy mm dd #\/) "/")))
      (ensure-directories-exist pic-dir)
      (loop for pic-url in pic-urls
	 for fname = (get-file-name pic-url)
	 for pic-path = (concatenate 'string pic-dir fname)
	 do (with-open-file (pic-stream pic-path
					:direction :output
					:element-type '(unsigned-byte 8)
					:if-exists :supersede)
	      (let ((pic-bin (http-request pic-url)))
		(format t "Downloading ~a~&" pic-url)
		(write-sequence pic-bin pic-stream)))))))

(defun make-anim (yyyy mm dd &key (px 512) (delay 100))
  "Generate animated gif from PNG images stored in pics/YYYY/MM/DD subdirectory"
  (let* ((pic-dir (concatenate 'string *picdir* (date-to-datestring yyyy mm dd #\/) "/"))
	 (anim-path (concatenate 'string pic-dir "epic-" (date-to-datestring yyyy mm dd #\-) ".gif")))
    (if (uiop:directory-exists-p pic-dir)
	(uiop:run-program (format nil "convert -delay ~a -loop 0 -resize ~ax~a ~a*.png ~a" delay px px pic-dir anim-path))
	(warn "No data downloaded for date ~a ~a ~a." yyyy mm dd))))

#|
TODO: function to perform all steps, with error checking
TODO: delete image files when done
TODO: check if animation already created, and skip if so
TODO: Make a website out of it
TODO: Specify start and end dates & times
- Download multiple days
- Scan HTML for images
- Assign *picurls* based on time
- Download
- (?) If animation already exists for part of the time, splice it into the existing animation instead of downloading & using images
|#
