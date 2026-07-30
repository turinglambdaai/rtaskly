#lang racket/base

;; Taskly backend entry point.
;;
;; Boots the Noise RPC server: (serve in-fd out-fd) reads framed requests
;; from the Swift client, dispatches each to the matching define-rpc in
;; rpc.rkt, and writes back the serialized result. Runs forever (until the
;; app tears the pipes down). An exit-handler trap prevents any stray
;; (exit) from killing the whole app process.
;;
;; Requiring "rpc.rkt" for effect is what registers every RPC with the
;; Noise sequencer; the codegen tool reads *this* module to generate
;; Backend.swift, so the RPC surface must be transitively required here.

(require noise/backend
         noise/serde
         "rpc.rkt")

(provide main)

(define (main in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (let/cc trap
    (parameterize ([exit-handler
                    (lambda (err-or-code)
                      (when (exn:fail? err-or-code)
                        ((error-display-handler)
                         (format "trap: ~a" (exn-message err-or-code))
                         err-or-code))
                      (trap))])
      (define stop (serve in-fd out-fd))
      (with-handlers ([exn:break? void])
        (sync never-evt))
      (stop))))
