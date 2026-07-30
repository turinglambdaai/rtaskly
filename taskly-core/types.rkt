#lang racket/base

;; Noise serde types shared between the Racket backend and the generated
;; Swift Backend.swift client.
;;
;; These mirror the Racket structs in task.rkt / list.rkt but are declared
;; with `define-record` so noise-serde-codegen emits matching Swift types
;; (Readable + Writable + Sendable) and the values can be marshaled across
;; the backend pipe.

(require noise/serde)

(provide (record-out TaskItem)
         (record-out TodoList))

;; A single task. Fields map 1:1 onto the original (struct task ...) plus
;; its resolved list-name. due-date is #f when the task has no due date;
;; on the Swift side this becomes `String?`.
;;
;; Named TaskItem (not Task) to avoid clashing with Swift's concurrency
;; `Task` type on the generated-client side.
;; Declares the Swift `Identifiable` protocol so SwiftUI `.sheet(item:)`
;; can take a TaskItem directly (its `id` field satisfies the requirement).
(define-record (TaskItem : Identifiable)
  [id         : UVarint]            ; task_id
  [list-id    : UVarint]            ; list_id
  [text       : String]             ; task_text
  [due-date   : (Optional String)]  ; "YYYY-MM-DD HH:MM" or #f
  [completed  : Bool]               ; is_completed == 1
  [created-at : Varint]             ; epoch seconds
  [list-name  : String])            ; resolved list name ("Unknown List" on miss)

;; A todo list.
(define-record TodoList
  [id   : UVarint]                  ; list_id
  [name : String])                  ; list_name
