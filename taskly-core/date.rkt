#lang racket/base

;; Date parsing/normalization/formatting engine.
;;
;; Faithfully ported from rtaskly's src/utils/date.rkt. Behavior is
;; unchanged: the stored datetime format is "YYYY-MM-DD HH:MM".
;;
;; Supported input forms (see parse-date-string):
;;   * existing "YYYY-MM-DD HH:MM"           -> passed through
;;   * relative:  +30m  +2h  +1d  +1w  +3M   -> from now
;;   * exact:     @10am  @3:30pm  @14:45
;;                @10am tomorrow  @10am tmw  -> at a time, today/tomorrow
;;   * "YYYY-MM-DD" or "Y-M-D"               -> date at 00:00
;; (There is intentionally NO "tomorrow"/"next week" word parsing; that
;;  was a README claim the original code never implemented.)

(require racket/date
         racket/format
         racket/list
         racket/string)

(provide normalize-date-string
         parse-date-string
         get-current-date-string
         format-date-for-display
         is-today?
         valid-date?
         date-diff
         date-string->seconds)

;; Is (year, month, day) a real calendar date (leap-year aware)?
(define (valid-day? year month day)
  (cond
    [(member month '(1 3 5 7 8 10 12)) (<= 1 day 31)]
    [(member month '(4 6 9 11))        (<= 1 day 30)]
    [(= month 2)
     (define leap-year?
       (and (zero? (remainder year 4))
            (or (not (zero? (remainder year 100)))
                (zero? (remainder year 400)))))
     (<= 1 day (if leap-year? 29 28))]
    [else #f]))

;; Normalize "Y-M-D" -> "YYYY-MM-DD", or #f if invalid.
(define (normalize-date-string date-str)
  (define trimmed-str (string-trim date-str))
  (if (equal? trimmed-str "")
      #f
      (let ([parts (string-split trimmed-str "-")])
        (and (= (length parts) 3)
             (let ([year-num   (string->number (list-ref parts 0))]
                   [month-num  (string->number (list-ref parts 1))]
                   [day-num    (string->number (list-ref parts 2))])
               (and year-num month-num day-num
                    (<= 1 month-num 12)
                    (<= 1900 year-num 9999)
                    (valid-day? year-num month-num day-num)
                    (format "~a-~a-~a"
                            (~r year-num  #:min-width 4 #:pad-string "0")
                            (~r month-num #:min-width 2 #:pad-string "0")
                            (~r day-num   #:min-width 2 #:pad-string "0"))))))))

;; Today as "YYYY-MM-DD".
(define (get-current-date-string)
  (define today (current-date))
  (format "~a-~a-~a"
          (date-year today)
          (~r (date-month today) #:min-width 2 #:pad-string "0")
          (~r (date-day today)   #:min-width 2 #:pad-string "0")))

;; "YYYY-MM-DD[ HH:MM]" -> "YYYY/MM/DD[ HH:MM]"; "" when falsy/empty.
(define (format-date-for-display date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([date-part (if (string-contains? date-str " ")
                           (first (string-split date-str " "))
                           date-str)]
            [time-part (if (string-contains? date-str " ")
                           (second (string-split date-str " "))
                           #f)])
        (define parts (string-split date-part "-"))
        (if (= (length parts) 3)
            (let ([year  (string->number (list-ref parts 0))]
                  [month (string->number (list-ref parts 1))]
                  [day   (string->number (list-ref parts 2))])
              (if (and year month day)
                  (if time-part
                      (format "~a/~a/~a ~a" year month day time-part)
                      (format "~a/~a/~a" year month day))
                  date-str))
            date-str))
      ""))

;; Does date-str's date part equal today? Any non-string (incl. sql-null)
;; counts as "no date" => #f, so this module need not depend on `db`.
(define (is-today? date-str)
  (if (not (and date-str (string? date-str)))
      #f
      (let ([date-part (if (string-contains? date-str " ")
                           (first (string-split date-str " "))
                           date-str)])
        (equal? date-part (get-current-date-string)))))

;; "YYYY-MM-DD[ HH:MM]" -> epoch seconds (local).
(define (date-string->seconds date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([date-part (if (string-contains? date-str " ")
                           (first (string-split date-str " "))
                           date-str)]
            [time-part (if (string-contains? date-str " ")
                           (second (string-split date-str " "))
                           "00:00")])
        (define date-parts (string-split date-part "-"))
        (define time-parts (string-split time-part ":"))
        (if (and (= (length date-parts) 3) (= (length time-parts) 2))
            (let* ([year   (string->number (list-ref date-parts 0))]
                   [month  (string->number (list-ref date-parts 1))]
                   [day    (string->number (list-ref date-parts 2))]
                   [hour   (string->number (list-ref time-parts 0))]
                   [minute (string->number (list-ref time-parts 1))]
                   [base   (seconds->date 0 #f)])
              (if (and year month day hour minute)
                  (date->seconds (struct-copy date base
                                              (year year) (month month) (day day)
                                              (hour hour) (minute minute) (second 0)))
                  0))
            0))
      0))

;; Whole-day difference between two date strings. Non-strings (incl.
;; sql-null) / empty strings yield 0.
(define (date-diff date-str1 date-str2)
  (if (or (not (and date-str1 (string? date-str1)))
          (not (and date-str2 (string? date-str2)))
          (equal? date-str1 "") (equal? date-str2 ""))
      0
      (let ([seconds1 (date-string->seconds date-str1)]
            [seconds2 (date-string->seconds date-str2)])
        (quotient (abs (- seconds1 seconds2)) (* 60 60 24)))))

;; Max days in a month.
(define (get-month-max-day year month)
  (cond
    [(member month '(1 3 5 7 8 10 12)) 31]
    [(member month '(4 6 9 11))        30]
    [(and (zero? (remainder year 4))
          (or (not (zero? (remainder year 100)))
              (zero? (remainder year 400)))) 29]
    [else 28]))

;; Parse "+<num><unit>" (m/h/d/w/M) -> a date offset from now.
(define (parse-relative-time num unit)
  (define now (current-date))
  (define n (string->number num))
  (cond
    [(string=? unit "m") (seconds->date (+ (date->seconds now) (* n 60)) #t)]
    [(string=? unit "h") (seconds->date (+ (date->seconds now) (* n 3600)) #t)]
    [(string=? unit "d") (seconds->date (+ (date->seconds now) (* n 86400)) #t)]
    [(string=? unit "w") (seconds->date (+ (date->seconds now) (* n 604800)) #t)]
    [(string=? unit "M")
     (let* ([new-month   (+ (date-month now) n)]
            [year-offset (quotient (- new-month 1) 12)]
            [final-year  (+ (date-year now) year-offset)]
            [final-month (+ 1 (remainder (- new-month 1) 12))]
            [max-day     (get-month-max-day final-year final-month)]
            [final-day   (min (date-day now) max-day)])
       (struct-copy date now
                    (year final-year) (month final-month) (day final-day)))]
    [else now]))

;; Parse an exact "@<time>[am|pm][ tomorrow|tmw]" -> a date today/tomorrow.
(define (parse-exact-time hour minute am-pm day-spec)
  (define now (current-date))
  (define h (string->number hour))
  (define m (if minute (string->number (substring minute 1)) 0))
  (define final-hour
    (cond
      [(and am-pm (string=? am-pm "am")) (if (= h 12) 0 h)]
      [(and am-pm (string=? am-pm "pm")) (if (= h 12) 12 (+ h 12))]
      [else h]))
  (define target-date
    (cond
      [(or (equal? day-spec "tomorrow") (equal? day-spec "tmw"))
       (seconds->date (+ (date->seconds now) 86400) #f)]
      [else now]))
  (struct-copy date target-date (hour final-hour) (minute m) (second 0)))

;; date -> "YYYY-MM-DD HH:MM".
(define (format-datetime datetime)
  (format "~a-~a-~a ~a:~a"
          (date-year datetime)
          (~r (date-month datetime) #:min-width 2 #:pad-string "0")
          (~r (date-day datetime)   #:min-width 2 #:pad-string "0")
          (~r (date-hour datetime)  #:min-width 2 #:pad-string "0")
          (~r (date-minute datetime) #:min-width 2 #:pad-string "0")))

;; The main entry: parse a user-entered date string into "YYYY-MM-DD HH:MM",
;; or #f if it cannot be parsed.
(define (parse-date-string date-str)
  (define trimmed-str (string-trim date-str))
  (if (equal? trimmed-str "")
      #f
      (cond
        ;; already "YYYY-MM-DD HH:MM"
        [(and (string-contains? trimmed-str " ")
              (string-contains? trimmed-str ":"))
         trimmed-str]
        ;; relative: +Nm +Nh +Nd +Nw +NM
        [(regexp-match #rx"^\\+([0-9]+)([dmhwM])$" trimmed-str)
         => (lambda (match)
              (format-datetime (parse-relative-time (second match) (third match))))]
        ;; exact: @time [am|pm] [tomorrow|tmw]
        [(regexp-match #rx"^@([0-9]+)(:[0-9]+)?([ap]m)?\\s*(.*)$" trimmed-str)
         => (lambda (match)
              (format-datetime (parse-exact-time (second match) (third match)
                                                 (fourth match)
                                                 (string-trim (fifth match)))))]
        ;; "YYYY-MM-DD" -> at 00:00
        [(regexp-match #rx"^[0-9]{4}-[0-9]{2}-[0-9]{2}$" trimmed-str)
         (string-append trimmed-str " 00:00")]
        ;; else try to normalize "Y-M-D"
        [else
         (let ([normalized (normalize-date-string trimmed-str)])
           (and normalized (string-append normalized " 00:00")))])))

;; Is date-str parseable? (empty/#f counts as valid = no date)
(define (valid-date? date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([normalized (parse-date-string date-str)])
        (not (boolean? normalized)))
      #t))
