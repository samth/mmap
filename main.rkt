#lang racket

(require ffi/unsafe)
(provide mmap)

(define PROT_READ 1)
(define PROT_WRITE 2)

(define MAP_SHARED 1)

(define get_port_fd (get-ffi-obj 'scheme_get_port_fd #f (_fun _racket -> _int)))

(define _mmap
  (get-ffi-obj 'mmap #f
               (_fun #:save-errno 'posix _pointer _ssize _int _int _int _int -> _pointer)))

(define (mmap f len)
  (define-values (in out) (open-input-output-file f #:exists 'can-update))
  (define m (_mmap #f len (bitwise-ior PROT_READ PROT_WRITE) MAP_SHARED (get_port_fd in) 0))
  (define result (cast m _pointer _long))
  (unless (< 0 result)
    (error 'mmap "errno: ~s ~s" (saved-errno) result))
  (cast m _pointer (_bytes o len)))

(module+ test
  (require rackunit racket/runtime-path)
  (define-runtime-path here "main.rkt")
  (define m (mmap here 5))
  (check-equal? m #"#lang"))
