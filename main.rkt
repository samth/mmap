#lang racket/base

(require ffi/unsafe ffi/unsafe/port (except-in racket/contract ->))
(provide (contract-out [mmap (->* (path-string?) (#:hint (or/c #f exact-nonnegative-integer?)
                                                  #:length exact-nonnegative-integer?
                                                  #:offset exact-nonnegative-integer?
                                                  #:prot (or/c symbol? (listof symbol?))
                                                  #:flags (or/c symbol? (listof symbol?)))
                                  bytes?)]))

(define flags
  (apply hash
         (append
          '(PROT_NONE 0)
          '(PROT_READ 1)
          '(PROT_WRITE 2)
          '(PROT_EXEC 4)

          '(MAP_NONBLOCK 65536)
          '(MAP_SHARED 1)
          '(MAP_HUGETLB 262144)
          '(MAP_GROWSDOWN 256)
          '(MAP_LOCKED 8192)
          '(MAP_FIXED 16)
          '(MAP_NORESERVE 16384)
          '(MAP_STACK 131072)
          '(MAP_PRIVATE 2)
          '(MAP_ANONYMOUS 32)
          '(MAP_POPULATE 32768))))

(define (->bits flag+)
  (if (symbol? flag+)
      (hash-ref flags flag+)
      (apply bitwise-ior (map ->bits flag+))))

(define get_port_fd unsafe-port->file-descriptor)

(define _mmap
  (get-ffi-obj 'mmap #f
               (_fun #:save-errno 'posix _pointer _ssize _int _int _int _int -> _pointer)))

(define (mmap f
              #:hint [hint #f]
              #:length [len 0] #:offset [off 0] #:prot [prot 'PROT_READ]
              #:flags [flags 'MAP_PRIVATE])
  (define sz (file-size f))
  (unless (>= sz (+ off len))
    (raise-argument-error 'mmap (format "file with size at least ~s" (+ off len))
                          f))
  (define-values (in out) (open-input-output-file f #:exists 'can-update))
  (define m (_mmap hint len (->bits prot) (->bits flags) (get_port_fd in) off))
  (define result (cast m _pointer _long))
  (unless (< 0 result)
    (error 'mmap "errno: ~s ~s" (saved-errno) result))
  (make-sized-byte-string m len))

(module* test racket/base
  (require rackunit racket/runtime-path (submod ".."))
  (define-runtime-path here "main.rkt")
  (when (eq? 'racket (system-type 'vm))
    (define m (mmap here #:length 5 #:prot 'PROT_READ #:flags 'MAP_SHARED))
    (check-equal? m #"#lang")))
