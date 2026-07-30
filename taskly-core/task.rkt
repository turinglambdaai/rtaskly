#lang racket/base

;; Task business layer.
;;
;; Adapted from rtaskly's src/core/task.rkt: same CRUD + the view
;; dispatcher (get-tasks-by-view), but rows are converted into the Noise
;; `Task` record (declared in types.rkt). The original `get-tasks-by-view`
;; took optional list-id/keyword args; here they are required (callers pass
;; #f to mean "none") since define-rpc has fixed arity.

(require racket/list
         (only-in db sql-null?)
         (prefix-in db: "database.rkt")
         (prefix-in lst: "list.rkt")
         "date.rkt"
         "types.rkt")

(provide row->task
         rows->tasks
         get-all-tasks
         get-tasks-by-list
         get-today-tasks
         get-planned-tasks
         get-all-incomplete-tasks
         get-all-completed-tasks
         search-tasks
         add-task
         edit-task
         toggle-task-completed
         delete-task
         get-tasks-by-view)

;; DB row -> TaskItem record. due-date becomes #f on sql-null; list-name is
;; resolved via the list layer ("Unknown List" if the lookup fails).
(define (row->task row)
  (define list-id (vector-ref row 1))
  (define list-name
    (with-handlers ([exn:fail? (lambda (_) "Unknown List")])
      (or (db:get-list-name list-id) "Unknown List")))
  (make-TaskItem
   #:id         (vector-ref row 0)                           ; task_id
   #:list-id    list-id                                      ; list_id
   #:text       (vector-ref row 2)                           ; task_text
   #:due-date   (if (sql-null? (vector-ref row 3))
                    #f
                    (vector-ref row 3))                      ; due_date
   #:completed  (= (vector-ref row 4) 1)                     ; is_completed
   #:created-at (string->number (vector-ref row 5))          ; created_at
   #:list-name  list-name))

(define (rows->tasks rows)
  (map row->task rows))

;; --- queries -----------------------------------------------------------

(define (get-all-tasks)
  (rows->tasks (db:get-all-tasks)))

(define (get-tasks-by-list list-id)
  (rows->tasks (db:get-tasks-by-list list-id)))

(define (get-today-tasks)
  (rows->tasks (db:get-today-tasks (get-current-date-string))))

(define (get-planned-tasks)
  (rows->tasks (db:get-planned-tasks)))

(define (get-all-incomplete-tasks)
  (rows->tasks (db:get-incomplete-tasks)))

(define (get-all-completed-tasks)
  (rows->tasks (db:get-completed-tasks)))

;; --- mutations ---------------------------------------------------------

(define (add-task list-id task-text due-date)
  (db:add-task list-id task-text due-date (current-seconds)))

(define (edit-task task-id list-id task-text due-date)
  (db:update-task task-id list-id task-text due-date))

(define (toggle-task-completed task-id)
  (db:toggle-task-completed task-id))

(define (delete-task task-id)
  (db:delete-task task-id))

(define (search-tasks keyword)
  (rows->tasks (db:search-tasks keyword)))

;; View dispatcher. view-type ∈ {"today","planned","all","completed",
;; "list","search"}; list-id/keyword are used only for "list"/"search"
;; and are otherwise ignored (pass #f).
(define (get-tasks-by-view view-type list-id keyword)
  (cond
    [(string=? view-type "today")     (get-today-tasks)]
    [(string=? view-type "planned")   (get-planned-tasks)]
    [(string=? view-type "all")       (get-all-incomplete-tasks)]
    [(string=? view-type "completed") (get-all-completed-tasks)]
    [(string=? view-type "list")      (if list-id (get-tasks-by-list list-id) '())]
    [(string=? view-type "search")    (if keyword (search-tasks keyword) '())]
    [else '()]))
