;; Automated Market Maker Liquidity Pool
;; Enables token swapping and liquidity provision

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-insufficient-liquidity (err u401))
(define-constant err-slippage-exceeded (err u402))
(define-constant err-insufficient-balance (err u403))
(define-constant err-zero-amount (err u404))

(define-data-var token-a-reserve uint u0)
(define-data-var token-b-reserve uint u0)
(define-data-var total-lp-tokens uint u0)
(define-data-var trading-fee uint u30) ;; 0.3% trading fee

(define-map lp-balances principal uint)
(define-map user-token-a-balance principal uint)
(define-map user-token-b-balance principal uint)

(define-read-only (get-reserves)
  {
    token-a: (var-get token-a-reserve),
    token-b: (var-get token-b-reserve)
  }
)

(define-read-only (get-lp-balance (user principal))
  (default-to u0 (map-get? lp-balances user))
)

(define-read-only (get-token-balance (user principal) (token (string-ascii 10)))
  (if (is-eq token "token-a")
    (default-to u0 (map-get? user-token-a-balance user))
    (default-to u0 (map-get? user-token-b-balance user))
  )
)

(define-read-only (calculate-swap-output (input-amount uint) (input-reserve uint) (output-reserve uint))
  (let ((input-with-fee (- input-amount (/ (* input-amount (var-get trading-fee)) u10000)))
        (numerator (* input-with-fee output-reserve))
        (denominator (+ input-reserve input-with-fee)))
    (/ numerator denominator)
  )
)

(define-public (set-token-balance (user principal) (token (string-ascii 10)) (amount uint))
  (asserts! (is-eq tx-sender contract-owner) err-owner-only)
  (if (is-eq token "token-a")
    (map-set user-token-a-balance user amount)
    (map-set user-token-b-balance user amount)
  )
  (ok true)
)

(define-public (add-liquidity (amount-a uint) (amount-b uint))
  (let ((reserve-a (var-get token-a-reserve))
        (reserve-b (var-get token-b-reserve))
        (total-supply (var-get total-lp-tokens))
        (user-balance-a (get-token-balance tx-sender "token-a"))
        (user-balance-b (get-token-balance tx-sender "token-b")))
    
    (asserts! (> amount-a u0) err-zero-amount)
    (asserts! (> amount-b u0) err-zero-amount)
    (asserts! (>= user-balance-a amount-a) err-insufficient-balance)
    (asserts! (>= user-balance-b amount-b) err-insufficient-balance)
    
    (let ((lp-tokens (if (is-eq total-supply u0)
                       (sqrti (* amount-a amount-b))
                       (min (/ (* amount-a total-supply) reserve-a)
                            (/ (* amount-b total-supply) reserve-b)))))
      
      ;; Update user balances
      (map-set user-token-a-balance tx-sender (- user-balance-a amount-a))
      (map-set user-token-b-balance tx-sender (- user-balance-b amount-b))
      
      ;; Update reserves
      (var-set token-a-reserve (+ reserve-a amount-a))
      (var-set token-b-reserve (+ reserve-b amount-b))
      
      ;; Mint LP tokens
      (map-set lp-balances tx-sender (+ (get-lp-balance tx-sender) lp-tokens))
      (var-set total-lp-tokens (+ total-supply lp-tokens))
      
      (ok lp-tokens)
    )
  )
)

(define-public (remove-liquidity (lp-amount uint))
  (let ((user-lp-balance (get-lp-balance tx-sender))
        (total-supply (var-get total-lp-tokens))
        (reserve-a (var-get token-a-reserve))
        (reserve-b (var-get token-b-reserve)))
    
    (asserts! (> lp-amount u0) err-zero-amount)
    (asserts! (>= user-lp-balance lp-amount) err-insufficient-balance)
    
    (let ((amount-a (/ (* lp-amount reserve-a) total-supply))
          (amount-b (/ (* lp-amount reserve-b) total-supply)))
      
      ;; Update LP balance
      (map-set lp-balances tx-sender (- user-lp-balance lp-amount))
      (var-set total-lp-tokens (- total-supply lp-amount))
      
      ;; Update reserves
      (var-set token-a-reserve (- reserve-a amount-a))
      (var-set token-b-reserve (- reserve-b amount-b))
      
      ;; Return tokens to user
      (map-set user-token-a-balance tx-sender (+ (get-token-balance tx-sender "token-a") amount-a))
      (map-set user-token-b-balance tx-sender (+ (get-token-balance tx-sender "token-b") amount-b))
      
      (ok {amount-a: amount-a, amount-b: amount-b})
    )
  )
)

(define-public (swap-a-for-b (input-amount uint) (min-output uint))
  (let ((reserve-a (var-get token-a-reserve))
        (reserve-b (var-get token-b-reserve))
        (user-balance-a (get-token-balance tx-sender "token-a"))
        (output-amount (calculate-swap-output input-amount reserve-a reserve-b)))
    
    (asserts! (> input-amount u0) err-zero-amount)
    (asserts! (>= user-balance-a input-amount) err-insufficient-balance)
    (asserts! (>= output-amount min-output) err-slippage-exceeded)
    
    ;; Update user balances
    (map-set user-token-a-balance tx-sender (- user-balance-a input-amount))
    (map-set user-token-b-balance tx-sender (+ (get-token-balance tx-sender "token-b") output-amount))
    
    ;; Update reserves
    (var-set token-a-reserve (+ reserve-a input-amount))
    (var-set token-b-reserve (- reserve-b output-amount))
    
    (ok output-amount)
  )
)

(define-public (swap-b-for-a (input-amount uint) (min-output uint))
  (let ((reserve-a (var-get token-a-reserve))
        (reserve-b (var-get token-b-reserve))
        (user-balance-b (get-token-balance tx-sender "token-b"))
        (output-amount (calculate-swap-output input-amount reserve-b reserve-a)))
    
    (asserts! (> input-amount u0) err-zero-amount)
    (asserts! (>= user-balance-b input-amount) err-insufficient-balance)
    (asserts! (>= output-amount min-output) err-slippage-exceeded)
    
    ;; Update user balances
    (map-set user-token-b-balance tx-sender (- user-balance-b input-amount))
    (map-set user-token-a-balance tx-sender (+ (get-token-balance tx-sender "token-a") output-amount))
    
    ;; Update reserves
    (var-set token-b-reserve (+ reserve-b input-amount))
    (var-set token-a-reserve (- reserve-a output-amount))
    
    (ok output-amount)
  )
)
