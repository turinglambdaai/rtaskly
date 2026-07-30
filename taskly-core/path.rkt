#lang racket/base

;; Application paths + simple key=value config store.
;;
;; Ported from rtaskly's src/utils/path.rkt. The app directory is
;; ~/.taskly, the default DB is ~/.taskly/tasks.db, and config lives in
;; ~/.taskly/config.ini (one `key=value` per line, `;` comments).
;;
;; On macOS the same home-directory layout is used so a database created
;; by this app is interchangeable with the original rtaskly one.

(require racket/file
         racket/list
         racket/port
         racket/string)

(provide get-default-app-dir
         get-default-db-path
         get-config-file-path
         read-config
         save-config
         get-config
         set-config
         ensure-directory-exists
         safe-file-exists?
         path-add-extension)

;; ~/.taskly (created if missing).
(define (get-default-app-dir)
  (define home (find-system-path 'home-dir))
  (define dir (build-path home ".taskly"))
  (ensure-directory-exists dir)
  dir)

;; ~/.taskly/tasks.db
(define (get-default-db-path)
  (path->string (build-path (get-default-app-dir) "tasks.db")))

;; ~/.taskly/config.ini
(define (get-config-file-path)
  (path->string (build-path (get-default-app-dir) "config.ini")))

;; Read the whole config file into an alist of (key . value).
(define (read-config)
  (define path (get-config-file-path))
  (if (safe-file-exists? path)
      (with-handlers ([exn:fail? (lambda (_) '())])
        (for/fold ([acc '()])
                  ([line (in-list (string-split (file->string path) "\n"))])
          (define trimmed (string-trim line))
          (cond
            [(or (equal? trimmed "") (string-prefix? trimmed ";")) acc]
            [else
             (define idx (string-index-of trimmed "="))
             (if idx
                 (cons (cons (string-trim (substring trimmed 0 idx))
                             (string-trim (substring trimmed (+ idx 1))))
                       acc)
                 acc)])))
      '()))

;; Write an alist of (key . value) back to the config file.
(define (save-config config-alist)
  (define path (get-config-file-path))
  (define content
    (string-join
     (for/list ([pair (in-list config-alist)])
       (format "~a=~a" (car pair) (cdr pair)))
     "\n"))
  (with-handlers ([exn:fail? void])
    (display-to-file (string-append content "\n") path #:exists 'replace)))

;; Look up a key (with optional default).
(define (get-config key [default #f])
  (define config (read-config))
  (let ([pair (assoc key config)])
    (if pair (cdr pair) default)))

;; Set a key (read-modify-write, dedupes by key).
(define (set-config key value)
  (define config (read-config))
  (define filtered (filter (lambda (p) (not (equal? (car p) key))) config))
  (save-config (cons (cons key value) filtered)))

;; mkdir -p (racket/file provides make-directory*).
(define (ensure-directory-exists path)
  (make-directory* path)
  path)

;; File exists? (swallows errors -> #f).
(define (safe-file-exists? path)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (file-exists? path)))

;; Append `ext` (e.g. ".db") to a path string if it has no extension.
;; Mirrors rtaskly's path-add-extension used by the New Database dialog.
(define (path-add-extension path-str ext)
  (define filename (file-name-from-path path-str))
  (if (and filename (string? filename) (string-contains? filename "."))
      path-str
      (string-append path-str ext)))

;; --- helpers -----------------------------------------------------------

(define (string-index-of str ch)
  (for/first ([i (in-range (string-length str))]
              #:when (string=? (substring str i (+ i 1)) ch))
    i))

(define (file-name-from-path path-str)
  (define elems (string-split path-str "/"))
  (and (pair? elems) (last elems)))
