#lang info

;; taskly-core: the Noise RPC backend for Taskly.
;;
;; This is the Racket package that runs inside the embedded Racket
;; runtime (a background thread of the macOS app). It owns the SQLite
;; database and exposes all task/list operations as Noise RPCs that the
;; SwiftUI frontend calls through the generated Backend.swift client.

(define collection "taskly")
(define version "0.0.31")
(define license 'MIT)
(define author "jrtxio")
(define homepage "https://github.com/turinglambdaai/rtaskly")
(define description "Taskly backend (Noise RPC + SQLite)")

;; base           - racket/base, racket/list, racket/string, ...
;; db             - SQLite via sqlite3-connect
;; threading-lib  - required by noise-serde-lib
(define deps
  '("base"
    "db"
    "threading-lib"
    ["noise-serde-lib" #:version "0.10"]))

(define build-deps
  '("rackunit-lib"))

(define pkg-desc "Taskly Noise RPC backend")

;; no raco-commands of our own; we only provide an entry module (`main`)
;; that calls (serve in-fd out-fd) from noise/backend.
