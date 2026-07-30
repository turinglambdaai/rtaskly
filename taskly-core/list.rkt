#lang racket/base

;; List business layer.
;;
;; Adapted from rtaskly's src/core/list.rkt: the same CRUD delegation to
;; database.rkt, but rows are converted into the Noise `TodoList` record
;; (declared in types.rkt) so they can be returned over RPC to Swift.

(require racket/list
         (prefix-in db: "database.rkt")
         "types.rkt")

(provide row->todo-list
         rows->todo-lists
         get-all-lists
         get-list-by-id
         add-list
         update-list
         delete-list
         get-default-list)

;; DB row -> TodoList record.
(define (row->todo-list row)
  (make-TodoList
   #:id   (vector-ref row 0)   ; list_id
   #:name (vector-ref row 1))) ; list_name

(define (rows->todo-lists rows)
  (map row->todo-list rows))

(define (get-all-lists)
  (rows->todo-lists (db:get-all-lists)))

;; Linear search by id (mirrors the original).
(define (get-list-by-id list-id)
  (findf (lambda (lst) (= (TodoList-id lst) list-id)) (get-all-lists)))

(define (add-list list-name)
  (db:add-list list-name))

(define (update-list list-id new-name)
  (db:update-list list-id new-name))

(define (delete-list list-id)
  (db:delete-list list-id))

;; First list, or #f if there are none.
(define (get-default-list)
  (define all (get-all-lists))
  (if (not (null? all)) (first all) #f))
