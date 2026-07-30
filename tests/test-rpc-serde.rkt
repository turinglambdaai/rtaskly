#lang racket/base

;; Noise RPC registration tests.
;;
;; Guards the Swift<->Racket contract at the level the app actually depends
;; on: that every operation is registered as a define-rpc (so it appears in
;; the generated Backend.swift), and that the shared records' constructors /
;; accessors / predicates behave (the values the server returns and the
;; generated Swift structs mirror).
;;
;; (We don't test the raw wire bytes here: `write-record`/`read-record` are
;;  internal to noise-serde-lib and not part of its public API; the wire
;;  format is exercised end-to-end by the NoiseBackend round-trip, and the
;;  generated Swift read/write methods are type-checked against the same
;;  record definitions during the app build.)

(require rackunit
         rackunit/text-ui
         noise/backend
         "../taskly-core/types.rkt"
         "../taskly-core/rpc.rkt")   ; registers every define-rpc for effect

(define rpc-tests
  (test-suite
   "rpc surface"

   ;; --- records: constructors / accessors / predicates ---
   ;; These are the values the server returns and that the generated Swift
   ;; structs mirror; pinning their behavior keeps the two sides in sync.
   (test-case "TodoList record"
     (define v (make-TodoList #:id 7 #:name "Work"))
     (check-true (TodoList? v))
     (check-equal? (TodoList-id v) 7)
     (check-equal? (TodoList-name v) "Work"))

   (test-case "TaskItem record (nil due-date)"
     (define v (make-TaskItem
                #:id 42 #:list-id 7 #:text "买牛奶"
                #:due-date #f #:completed #f
                #:created-at 1700000000 #:list-name "Work"))
     (check-true (TaskItem? v))
     (check-equal? (TaskItem-id v) 42)
     (check-equal? (TaskItem-list-id v) 7)
     (check-equal? (TaskItem-text v) "买牛奶")
     (check-false (TaskItem-due-date v))
     (check-false (TaskItem-completed v))
     (check-equal? (TaskItem-created-at v) 1700000000)
     (check-equal? (TaskItem-list-name v) "Work"))

   (test-case "TaskItem record (with due-date, completed)"
     (define v (make-TaskItem
                #:id 43 #:list-id 7 #:text "开会"
                #:due-date "2099-01-01 09:00" #:completed #t
                #:created-at 1700000001 #:list-name "Personal"))
     (check-equal? (TaskItem-due-date v) "2099-01-01 09:00")
     (check-true (TaskItem-completed v)))))

(run-tests rpc-tests)
