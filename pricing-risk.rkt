#lang racket/base

(require math/distributions)

(provide black-scholes
         black-scholes-delta
         black-scholes-gamma
         black-scholes-theta
         black-scholes-vega
         black-scholes-rho)

(define (black-scholes price years-left strike call-put rate vol divs)
  (let* ([discounted-price
          (- price (foldl (λ (div res)
                            (if (>= years-left (vector-ref div 0))
                                (+ res (* (vector-ref div 1)
                                          (exp (* -1 rate (vector-ref div 0)))))
                                res))
                          0
                          divs))]
         [d-1 (* (/ 1 (* vol (sqrt years-left)))
                 (+ (log (/ discounted-price strike))
                    (* (+ rate (/ (* vol vol) 2))
                       years-left)))]
         [d-2 (- d-1 (* vol (sqrt years-left)))]
         [pv (* strike (exp (* -1 rate years-left)))])
    (cond [(or (equal? call-put 'Call) (equal? call-put 'call))
           (- (* (cdf (normal-dist) d-1) discounted-price)
              (* (cdf (normal-dist) d-2) pv))]
          [(or (equal? call-put 'Put) (equal? call-put 'put))
           (- (* (cdf (normal-dist) (* d-2 -1)) pv)
              (* (cdf (normal-dist) (* d-1 -1)) discounted-price))])))

(define (black-scholes-delta price years-left strike call-put rate vol divs)
  (* (- (black-scholes (+ price 1/100) years-left strike call-put rate vol divs)
        (black-scholes price years-left strike call-put rate vol divs))
     100))

(define (black-scholes-gamma price years-left strike call-put rate vol divs)
  (* (- (black-scholes-delta (+ price 1/100) years-left strike call-put rate vol divs)
        (black-scholes-delta price years-left strike call-put rate vol divs))
     100))

(define (black-scholes-theta price years-left strike call-put rate vol divs)
  (- (black-scholes price (max (- years-left 1/365) 1/1000000) strike call-put rate vol divs)
     (black-scholes price years-left strike call-put rate vol divs)))

(define (black-scholes-vega price years-left strike call-put rate vol divs)
  (- (black-scholes price years-left strike call-put rate (+ vol 1/100) divs)
     (black-scholes price years-left strike call-put rate vol divs)))

(define (black-scholes-rho price years-left strike call-put rate vol divs)
  (- (black-scholes price years-left strike call-put (+ rate 1/100) vol divs)
     (black-scholes price years-left strike call-put rate vol divs)))
