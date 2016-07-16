#lang racket

(require net/rfc6455
         racket/async-channel)

(struct client-handle (in out p serial [score #:mutable]) #:transparent)

(define waiting-sema (make-semaphore 1))
(define waiting& (box #f))
(define qtime& (box 0))

(define MATCH-WAIT 1)
(define MATCH-TIMEOUT 1)
(define ROUND-LENGTH 10000)
(define TIME-DIVISOR 500)

(define (make-ai)
  (let ([in   (make-async-channel)]
        [out  (make-async-channel)])
    (define handler
      (thread
        (thunk
          (async-channel-get in) ;; go
          (sync (alarm-evt (+ (current-inexact-milliseconds) (random 10000)))
                in)
          (async-channel-put out 'flip)
          (async-channel-put out 'hup))))
    (define (p action)
      (match action
        ['wait (thread-wait handler)]
        ['status (not (thread-dead? handler))]
        ['cleanup (kill-thread handler)]
        [x (error 'ai "bad action: ~a" x)]))
    (client-handle in out p 0 0)))

(define (match-timeout-poll)
  (call-with-semaphore waiting-sema
    (thunk
      (let ([w (unbox waiting&)])
        (when
          (and w
               (> (- (current-inexact-milliseconds) (unbox qtime&))
                  (* MATCH-TIMEOUT 1000)))
          (set-box! waiting& #f)
          (pair w (make-ai)))))))

(define match-timeout-poll-thread
  (thread
    (thunk
      (let loop ()
        (with-handlers
          ([exn?
             (lambda (e)
               (fprintf (current-error-port) "match-timeout-poll: ~a~n" (exn-message e)))])
          (sleep 1)
          (match-timeout-poll))
        (loop)))))

(define (score-scale end start)
  (round (inexact->exact (expt 2 (/ (- end start) TIME-DIVISOR)))))

(define (play a b)
  (cond
    [(not ((client-handle-p a) 'status))
     (enqueue b)]
    [(not ((client-handle-p b) 'status))
     (enqueue a)]
    [else
     (printf "new game: ~a vs ~a~n"
             (client-handle-serial a)
             (client-handle-serial b))
     (for ([client (list a b)])
       (async-channel-put (client-handle-in client) (list 'go (client-handle-score client))))
     (define start-time (current-inexact-milliseconds))
     (match
       (apply sync
              (wrap-evt (alarm-evt (+ start-time ROUND-LENGTH)) (curry cons 'timeout))
              (for/list ([client (list a b)])
                (wrap-evt (client-handle-out client) (curry cons client))))
       [(cons 'timeout _)
        (for ([client (list a b)])
          (async-channel-put (client-handle-in client) (list 'over (client-handle-score client))))
        (sleep MATCH-WAIT)
        (enqueue a)
        (enqueue b)]
       [(cons winner 'flip)
        (define loser (if (equal? winner a) b a))
        (define delta (score-scale (current-inexact-milliseconds) start-time))
        (set-client-handle-score! winner (+ (client-handle-score winner) delta))
        (set-client-handle-score! loser  (- (client-handle-score loser) delta))
        (for ([client (list a b)])
          (async-channel-put (client-handle-in client) (list 'over (client-handle-score client))))
        (sleep MATCH-WAIT)
        (enqueue a)
        (enqueue b)]
       [(cons loser 'hup)
        (define winner (if (equal? loser a) b a))
        (async-channel-put (client-handle-in winner) (list 'over (client-handle-score winner)))
        (enqueue winner)])]))

(define (pair a b)
  (thread
    (thunk (play a b))))

(define (enqueue handle)
  (call-with-semaphore waiting-sema
    (thunk
      (let ([w (unbox waiting&)])
        (if w
            (begin
              (set-box! waiting& #f)
              (pair handle w))
            (begin
              (set-box! qtime& (current-inexact-milliseconds))
              (set-box! waiting& handle)))))))

(define client-serial-sema (make-semaphore 1))
(define client-serial& (box 0))

(define (make-client-handle c)
  (define serial
    (call-with-semaphore client-serial-sema
      (thunk
        (set-box! client-serial& (add1 (unbox client-serial&)))
        (unbox client-serial&))))
  (let ([in   (make-async-channel)]
        [out  (make-async-channel)]
        [recv (make-async-channel)])
    (define courier
      (thread
        (thunk
          (dynamic-wind
            void
            (thunk
              (let loop ()
                (match (ws-recv c)
                  [(? eof-object?) (void)]
                  [x (async-channel-put recv x)
                     (loop)])))
            (thunk (async-channel-put recv 'hup))))))
    (define handler
      (thread
        (thunk
          (let loop ()
            (match (sync (wrap-evt in (curry cons 'in))
                         (wrap-evt recv (curry cons 'c)))
              [(cons 'c "flip")
               (printf "client ~a: flip~n" serial)
               (async-channel-put out 'flip)
               (loop)]
              [(cons 'c 'hup)
               (printf "client ~a disconnected~n" serial)
               (async-channel-put out 'hup)]
              [(cons 'in (list cmd score))
               (printf "notify client ~a: ~a score=~a~n" serial cmd score)
               (ws-send! c (~a (symbol->string cmd) " " score))
               (loop)]
              [x (printf "ded: ~a~n" x)])))))
    (define (p action)
      (match action
        ['wait
         (thread-wait handler)]
        ['status
         (not (thread-dead? handler))]
        ['cleanup
         (with-handlers ([exn? void]) (ws-close! c))
         (kill-thread courier)
         (kill-thread handler)]
        [x (error 'client-handle "bad action: ~a" x)]))
    (client-handle in out p serial 0)))

(fprintf (current-error-port) "starting...~n")

(define stop-thunk
  (ws-serve
    #:port 8080
    (lambda (c s)
      (pretty-print c)
      (define handle (make-client-handle c))
      (dynamic-wind
        void
        (thunk
          (enqueue handle)
          ((client-handle-p handle) 'wait))
        (lambda ()
          (with-handlers
            ([exn?
               (lambda (e)
                 (fprintf (current-error-port) "cleanup exn: ~a~n" (exn-message e)))])
            ((client-handle-p handle) 'cleanup)))))))

(parameterize-break
  #t
  (with-handlers
    ([exn:break? (lambda (e) (fprintf (current-error-port) "~ninterrupt...~n"))])
    (thread-wait (current-thread))))

(stop-thunk)

