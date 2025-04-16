;; Settlement Contract
;; Handles payment and resolution of claims

(define-data-var admin principal tx-sender)
(define-data-var treasury principal tx-sender)

;; Settlement data structure
(define-map settlements
  { incident-id: (string-ascii 32) }
  {
    policy-id: (string-ascii 32),
    amount: uint,
    recipient: principal,
    status: (string-ascii 16),
    settled-at: uint,
    approved-by: principal
  }
)

;; Create a settlement proposal (adjuster only)
(define-public (propose-settlement (incident-id (string-ascii 32))
                                  (policy-id (string-ascii 32))
                                  (amount uint)
                                  (recipient principal))
  (let ((caller tx-sender))
    (if (map-insert settlements
                   { incident-id: incident-id }
                   {
                     policy-id: policy-id,
                     amount: amount,
                     recipient: recipient,
                     status: "proposed",
                     settled-at: u0,
                     approved-by: caller
                   })
        (ok true)
        (err u1))))

;; Approve a settlement (admin only)
(define-public (approve-settlement (incident-id (string-ascii 32)))
  (let ((caller tx-sender)
        (settlement (unwrap-panic (map-get? settlements { incident-id: incident-id }))))
    (if (is-eq caller (var-get admin))
        (begin
          (map-set settlements
                  { incident-id: incident-id }
                  (merge settlement {
                    status: "approved",
                    approved-by: caller
                  }))
          (ok true))
        (err u2))))

;; Execute settlement payment (admin only)
(define-public (execute-settlement (incident-id (string-ascii 32)))
  (let ((caller tx-sender)
        (settlement (unwrap-panic (map-get? settlements { incident-id: incident-id }))))
    (if (and (is-eq caller (var-get admin))
             (is-eq (get status settlement) "approved"))
        (begin
          (map-set settlements
                  { incident-id: incident-id }
                  (merge settlement {
                    status: "paid",
                    settled-at: block-height
                  }))
          (ok true))
        (err u3))))

;; Get settlement details
(define-read-only (get-settlement (incident-id (string-ascii 32)))
  (map-get? settlements { incident-id: incident-id }))

;; Update admin
(define-public (set-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set admin new-admin)
          (ok true))
        (err u4))))

;; Update treasury
(define-public (set-treasury (new-treasury principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set treasury new-treasury)
          (ok true))
        (err u5))))
