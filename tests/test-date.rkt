#lang racket/base

;; Date-engine tests, ported from rtaskly's tests/utils/test-date.rkt.
;;
;; These pin the behavior of the parser so the SwiftUI quick-add /
;; edit-dialog date handling stays identical to the original: +Nunit,
;; @time[am|pm][ tomorrow|tmw], ISO dates, normalization, and display
;; formatting (note: display uses un-padded "2023/1/1", matching the
;; original's number-based formatting).

(require rackunit
         rackunit/text-ui
         racket/format
         racket/string
         (only-in db sql-null)
         "../taskly-core/date.rkt")

(define date-tests
  (test-suite
   "date engine"

   ;; --- normalize-date-string ---
   (test-case "normalize: padding & whitespace"
     (check-equal? (normalize-date-string "2023-01-01") "2023-01-01")
     (check-equal? (normalize-date-string "2023-1-1") "2023-01-01")
     (check-equal? (normalize-date-string " 2023-01-01 ") "2023-01-01"))

   (test-case "normalize: year boundaries"
     (check-equal? (normalize-date-string "1900-01-01") "1900-01-01")
     (check-equal? (normalize-date-string "9999-12-31") "9999-12-31")
     (check-false (normalize-date-string "1899-01-01"))
     (check-false (normalize-date-string "10000-01-01")))

   (test-case "normalize: month boundaries"
     (check-false (normalize-date-string "2023-00-01"))
     (check-false (normalize-date-string "2023-13-01")))

   (test-case "normalize: day boundaries incl. month-length"
     (check-false (normalize-date-string "2023-01-00"))
     (check-false (normalize-date-string "2023-01-32"))
     (check-false (normalize-date-string "2023-02-30"))   ; Feb has no 30th
     (check-false (normalize-date-string "2023-04-31")))  ; Apr has 30 days

   (test-case "normalize: invalid shapes"
     (check-false (normalize-date-string "2023/01/01"))
     (check-false (normalize-date-string "20230101"))
     (check-false (normalize-date-string "2023-01"))
     (check-false (normalize-date-string ""))
     (check-false (normalize-date-string "invalid-date")))

   ;; --- get-current-date-string ---
   (test-case "current date is YYYY-MM-DD"
     (define s (get-current-date-string))
     (check-pred string? s)
     (check-regexp-match #px"^\\d{4}-\\d{2}-\\d{2}$" s))

   ;; --- format-date-for-display (un-padded, like the original) ---
   (test-case "format for display"
     (check-equal? (format-date-for-display "2023-01-01") "2023/1/1")
     (check-equal? (format-date-for-display "2023-12-31") "2023/12/31")
     (check-equal? (format-date-for-display "2023-06-15 09:30") "2023/6/15 09:30")
     (check-equal? (format-date-for-display "") "")
     (check-equal? (format-date-for-display #f) "")
     (check-equal? (format-date-for-display sql-null) ""))

   ;; --- is-today? ---
   (test-case "is-today?"
     (define today (get-current-date-string))
     (check-true (is-today? today))
     (check-false (is-today? ""))
     (check-false (is-today? #f))
     (check-false (is-today? sql-null)))

   ;; --- valid-date? ---
   (test-case "valid-date?"
     (check-true (valid-date? "2023-01-01"))
     (check-true (valid-date? ""))     ; empty counts as "no date" => valid
     (check-true (valid-date? #f))
     (check-false (valid-date? "2023-02-30"))
     (check-false (valid-date? "invalid-date")))

   ;; --- parse-date-string: relative (+Nunit) ---
   (test-case "parse relative time lands on the right day"
     (define today (get-current-date-string))
     ;; +30m / +2h stay on today
     (check-true (string-prefix? (parse-date-string "+30m") today))
     (check-true (string-prefix? (parse-date-string "+2h") today))
     ;; +1d / +1w / +6M all produce a concrete datetime
     (check-not-false (parse-date-string "+1d"))
     (check-not-false (parse-date-string "+1w"))
     (check-not-false (parse-date-string "+6M")))

   ;; --- parse-date-string: exact (@time) ---
   (test-case "parse exact time"
     (define today (get-current-date-string))
     ;; @time without a day-spec is today; @time tomorrow|tmw is tomorrow.
     (check-true (string-prefix? (parse-date-string "@10am") today))
     (check-true (string-prefix? (parse-date-string "@10:30pm") today))
     (check-true (string-prefix? (parse-date-string "@22:30") today))
     (define tomorrow (parse-date-string "+1d"))
     (when tomorrow
       (define tdate (substring tomorrow 0 10))
       (check-true (string-prefix? (parse-date-string "@10am tomorrow") tdate))
       (check-true (string-prefix? (parse-date-string "@10am tmw") tdate))))

   ;; --- parse-date-string: ISO passthrough adds 00:00 ---
   (test-case "ISO date gets default 00:00"
     (check-equal? (parse-date-string "2025-08-07") "2025-08-07 00:00")
     (check-equal? (parse-date-string "2025-1-1") "2025-01-01 00:00"))

   ;; --- date-diff ---
   (test-case "date-diff"
     (check-equal? (date-diff "2023-01-01" "2023-01-01") 0)
     (check-equal? (date-diff "2023-01-01" "2023-01-02") 1)
     (check-equal? (date-diff "2023-01-02" "2023-01-01") 1)
     (check-equal? (date-diff sql-null "2023-01-01") 0)
     (check-equal? (date-diff "2023-01-01" #f) 0))))

(run-tests date-tests)
