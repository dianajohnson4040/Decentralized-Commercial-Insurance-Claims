;; Policy Verification Contract
;; Validates coverage terms and conditions

(define-data-var admin principal tx-sender)

;; Policy data structure
(define-map policies
  { policy-id: (string-ascii 32) }
  {
    owner: principal,
    coverage-amount: uint,
    premium-paid: uint,
    start-date: uint,
    end-date: uint,
    active: bool,
    policy-type: (string-ascii 32)
  }
)

;; Create a new policy
(define-public (create-policy (policy-id (string-ascii 32))
                             (coverage-amount uint)
                             (premium-paid uint)
                             (start-date uint)
                             (end-date uint)
                             (policy-type (string-ascii 32)))
  (let ((caller tx-sender))
    (if (map-insert policies
                   { policy-id: policy-id }
                   {
                     owner: caller,
                     coverage-amount: coverage-amount,
                     premium-paid: premium-paid,
                     start-date: start-date,
                     end-date: end-date,
                     active: true,
                     policy-type: policy-type
                   })
        (ok true)
        (err u1))))

;; Check if a policy is valid
(define-read-only (is-policy-valid (policy-id (string-ascii 32)))
  (let ((policy (unwrap-panic (map-get? policies { policy-id: policy-id }))))
    (and (get active policy)
         (>= (get end-date policy) block-height))))

;; Get policy details
(define-read-only (get-policy (policy-id (string-ascii 32)))
  (map-get? policies { policy-id: policy-id }))

;; Deactivate a policy (admin only)
(define-public (deactivate-policy (policy-id (string-ascii 32)))
  (let ((caller tx-sender)
        (policy (unwrap-panic (map-get? policies { policy-id: policy-id }))))
    (if (or (is-eq caller (var-get admin))
            (is-eq caller (get owner policy)))
        (begin
          (map-set policies
                  { policy-id: policy-id }
                  (merge policy { active: false }))
          (ok true))
        (err u2))))

;; Update admin
(define-public (set-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set admin new-admin)
          (ok true))
        (err u3))))
