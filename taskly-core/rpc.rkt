#lang racket/base

;; Noise RPC surface.
;;
;; Every operation the SwiftUI frontend can invoke is declared here with
;; `define-rpc`. `define-rpc` has fixed arity (no optional args), so views
;; that conceptually take an optional list-id / keyword instead take a
;; non-optional `(Optional ...)` that the Swift side passes as nil.
;;
;; The bodies delegate to the business layers in task.rkt / list.rkt and
;; the low-level database.rkt. Each RPC is registered with the Noise
;; sequencer and dispatched automatically by (serve in-fd out-fd).

(require noise/backend
         noise/serde
         (prefix-in db:  "database.rkt")
         (prefix-in tsk: "task.rkt")
         (prefix-in lst: "list.rkt")
         "date.rkt"
         "path.rkt"
         "types.rkt")

;; `provide` isn't needed for RPCs to be served (define-rpc registers them
;; in the sequencer), but re-exporting the entry points keeps the module's
;; intent self-documenting.

;; --- database ----------------------------------------------------------

(define-rpc (connect-to-database [at-path path : String] : Bool)
  (and (db:connect-to-database path) #t))

;; No return-type annotation => a Void RPC (the server writes nothing back).
(define-rpc (close-database)
  (db:close-database))

(define-rpc (is-db-connected : Bool)
  (and (db:current-db-connection) #t))

(define-rpc (get-current-db-path : (Optional String))
  (db:current-db-path))

;; --- lists -------------------------------------------------------------

(define-rpc (get-all-lists : (Listof TodoList))
  (lst:get-all-lists))

;; Returns the new list's id (0 on failure, since UVarint can't be #f).
(define-rpc (add-list [named name : String] : UVarint)
  (or (lst:add-list name) 0))

(define-rpc (update-list [for-id id : UVarint] [to-name name : String] : Bool)
  (and (lst:update-list id name) #t))

(define-rpc (delete-list [for-id id : UVarint] : Bool)
  (and (lst:delete-list id) #t))

(define-rpc (get-default-list : (Optional TodoList))
  (lst:get-default-list))

;; --- tasks -------------------------------------------------------------

;; view ∈ {"today","planned","all","completed","list","search"}.
;; list-id is consulted only for "list"; keyword only for "search".
(define-rpc (get-tasks-by-view
             [for-view view : String]
             [in-list list-id : (Optional UVarint)]
             [matching keyword : (Optional String)]
             : (Listof TaskItem))
  (tsk:get-tasks-by-view view list-id keyword))

(define-rpc (add-task
             [in-list list-id : UVarint]
             [with-text text : String]
             [due-on due-date : (Optional String)]
             : Bool)
  (and (tsk:add-task list-id text due-date) #t))

(define-rpc (edit-task
             [for-id id : UVarint]
             [in-list list-id : UVarint]
             [with-text text : String]
             [due-on due-date : (Optional String)]
             : Bool)
  (and (tsk:edit-task id list-id text due-date) #t))

(define-rpc (toggle-task-completed [for-id id : UVarint] : Bool)
  (and (tsk:toggle-task-completed id) #t))

(define-rpc (delete-task [for-id id : UVarint] : Bool)
  (and (tsk:delete-task id) #t))

(define-rpc (search-tasks [for keyword : String] : (Listof TaskItem))
  (tsk:search-tasks keyword))

;; --- date helpers (UI uses these to parse/format) ----------------------

;; Parse a user-entered date string into "YYYY-MM-DD HH:MM", or nil.
(define-rpc (parse-date-string [for s : String] : (Optional String))
  (parse-date-string s))

;; Format a stored date for display ("YYYY-MM-DD[ HH:MM]" -> "YYYY/MM/DD[ HH:MM]").
(define-rpc (format-date-for-display [for s : String] : String)
  (format-date-for-display s))

(define-rpc (is-today [date s : String] : Bool)
  (is-today? s))

;; --- paths -------------------------------------------------------------

(define-rpc (get-default-db-path : String)
  (get-default-db-path))
