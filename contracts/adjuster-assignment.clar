;; Adjuster Assignment Contract
;; Manages claim investigation process

(define-data-var admin principal tx-sender)

;; Adjuster data structure
(define-map adjusters
  { adjuster-id: principal }
  {
    name: (string-ascii 64),
    active: bool,
    specialty: (string-ascii 32),
    rating: uint
  }
)

;; Assignment data structure
(define-map assignments
  { incident-id: (string-ascii 32) }
  {
    adjuster-id: principal,
    assigned-at: uint,
    status: (string-ascii 16),
    notes: (string-ascii 256)
  }
)

;; Register a new adjuster (admin only)
(define-public (register-adjuster (adjuster-id principal)
                                 (name (string-ascii 64))
                                 (specialty (string-ascii 32)))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (if (map-insert adjusters
                       { adjuster-id: adjuster-id }
                       {
                         name: name,
                         active: true,
                         specialty: specialty,
                         rating: u0
                       })
            (ok true)
            (err u1))
        (err u2))))

;; Assign an adjuster to an incident (admin only)
(define-public (assign-adjuster (incident-id (string-ascii 32))
                               (adjuster-id principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (if (map-insert assignments
                       { incident-id: incident-id }
                       {
                         adjuster-id: adjuster-id,
                         assigned-at: block-height,
                         status: "assigned",
                         notes: ""
                       })
            (ok true)
            (err u3))
        (err u4))))

;; Update assignment status (adjuster only)
(define-public (update-assignment (incident-id (string-ascii 32))
                                 (new-status (string-ascii 16))
                                 (notes (string-ascii 256)))
  (let ((caller tx-sender)
        (assignment (unwrap-panic (map-get? assignments { incident-id: incident-id }))))
    (if (is-eq caller (get adjuster-id assignment))
        (begin
          (map-set assignments
                  { incident-id: incident-id }
                  (merge assignment {
                    status: new-status,
                    notes: notes
                  }))
          (ok true))
        (err u5))))

;; Get adjuster details
(define-read-only (get-adjuster (adjuster-id principal))
  (map-get? adjusters { adjuster-id: adjuster-id }))

;; Get assignment details
(define-read-only (get-assignment (incident-id (string-ascii 32)))
  (map-get? assignments { incident-id: incident-id }))

;; Update admin
(define-public (set-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set admin new-admin)
          (ok true))
        (err u6))))
