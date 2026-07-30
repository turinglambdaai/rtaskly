#lang racket/base

;; Database layer tests, ported from rtaskly's tests/core/test-database.rkt.
;;
;; Covers: connect + schema creation, default Work/Personal seeding, list CRUD,
;; task CRUD, the smart-view queries (today/planned/all/completed/search), FK
;; cascade on list delete, and the safe-fallback behavior with no connection.
;;
;; Each case uses a fresh temp .db and closes the connection in teardown so the
;; global current-db-connection is reset between cases.

(require rackunit
         rackunit/text-ui
         racket/file
         racket/list
         (only-in db sql-null sql-null?)
         "../taskly-core/database.rkt"
         "../taskly-core/date.rkt")

;; Create a temp .db, connect+init, run body, then close + delete.
(define (with-temp-db name body-thunk)
  (define tmp (make-temporary-file (string-append "~a-" name ".db.tmp")))
  ;; make-temporary-file creates an empty file; connect opens/creates the db
  ;; at that path (sqlite3-connect #:mode 'create).
  (connect-to-database tmp)
  (dynamic-wind
    void
    body-thunk
    (lambda ()
      (close-database)
      (with-handlers ([exn:fail? void]) (delete-file tmp)))))

(define database-tests
  (test-suite
   "database layer"

   (test-case "connect initializes tables and seeds defaults"
     (with-temp-db
      "init"
      (lambda ()
        (check-not-false (current-db-connection) "connection is set")
        (check-equal? (length (get-all-lists)) 2 "Work + Personal seeded"))))

   (test-case "operations are safe (return '()/#f) with no connection"
     (close-database)
     (check-equal? (get-all-lists) '())
     (check-equal? (get-all-tasks) '())
     (check-false (add-list "x"))
     (check-false (add-task 1 "t" #f)))

   (test-case "list CRUD"
     (with-temp-db
      "list"
      (lambda ()
        (add-list "学习")
        (add-list "娱乐")
        (check-equal? (length (get-all-lists)) 4) ; 2 defaults + 2

        (define lists (get-all-lists))
        (define first-id (vector-ref (first lists) 0))
        (update-list first-id "工作列表")
        (check-equal? (vector-ref (first (get-all-lists)) 1) "工作列表")

        (delete-list first-id)
        (check-equal? (length (get-all-lists)) 3)

        (delete-list 9999)))) ; deleting a non-existent list must not crash

   (test-case "task CRUD + completion toggle"
     (with-temp-db
      "task"
      (lambda ()
        (define list-id (vector-ref (first (get-all-lists)) 0))

        (check-true (add-task list-id "买牛奶" #f))
        (check-true (add-task list-id "开会" "2099-01-01 09:00"))
        (check-equal? (length (get-tasks-by-list list-id)) 2)

        ;; toggle the first task to completed; it leaves the incomplete view
        (define first-id (vector-ref (first (get-tasks-by-list list-id)) 0))
        (toggle-task-completed first-id)
        (check-equal? (length (get-tasks-by-list list-id)) 1)
        (check-equal? (length (get-completed-tasks)) 1)

        ;; edit + delete the remaining task
        (define rest-id (vector-ref (first (get-tasks-by-list list-id)) 0))
        (check-true (update-task rest-id list-id "开会(改)" #f))
        (delete-task rest-id)
        (check-equal? (length (get-tasks-by-list list-id)) 0))))

   (test-case "FK cascade: deleting a list removes its tasks"
     (with-temp-db
      "cascade"
      (lambda ()
        (define list-id (vector-ref (first (get-all-lists)) 0))
        (add-task list-id "t1" #f)
        (add-task list-id "t2" #f)
        (check-equal? (length (get-all-tasks)) 2)
        (delete-list list-id)
        (check-equal? (length (get-all-tasks)) 0))))

   (test-case "smart views: today / planned / all / completed / search"
     (with-temp-db
      "views"
      (lambda ()
        (define list-id (vector-ref (first (get-all-lists)) 0))
        (define today (get-current-date-string))

        (add-task list-id "今天的事" (string-append today " 10:00"))
        (add-task list-id "将来的事" "2099-01-01 09:00")
        (add-task list-id "无日期的事" #f)

        (check-equal? (length (get-today-tasks today)) 1)
        (check-equal? (length (get-planned-tasks)) 2)
        (check-equal? (length (get-incomplete-tasks)) 3)
        (check-equal? (length (get-completed-tasks)) 0)
        (check-equal? (length (search-tasks "将来")) 1)
        (check-equal? (length (search-tasks "xyz-not-found")) 0))))))

(run-tests database-tests)
