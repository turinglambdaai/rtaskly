#lang racket/base

;; Runs every backend test module. Use `racket run-tests.rkt`
;; (or `raco test tests/`).

(require "tests/test-date.rkt"
         "tests/test-database.rkt"
         "tests/test-rpc-serde.rkt")

;; The required modules above each call (run-tests ...) at load, so simply
;; requiring them runs the suites. This file exists as a single entry point.
(void)
