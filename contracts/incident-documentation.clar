;; Incident Documentation Contract
;; Records details of insured events

(define-data-var admin principal tx-sender)

;; Incident data structure
(define-map incidents
  { incident-id: (string-ascii 32) }
  {
    policy-id: (string-ascii 32),
    reporter: principal,
    timestamp: uint,
    description: (string-ascii 256),
    location: (string-ascii 64),
    status: (string-ascii 16),
    evidence-hash: (buff 32)
  }
)

;; Create a new incident report
(define-public (report-incident (incident-id (string-ascii 32))
                               (policy-id (string-ascii 32))
                               (description (string-ascii 256))
                               (location (string-ascii 64))
                               (evidence-hash (buff 32)))
  (let ((caller tx-sender))
    (if (map-insert incidents
                   { incident-id: incident-id }
                   {
                     policy-id: policy-id,
                     reporter: caller,
                     timestamp: block-height,
                     description: description,
                     location: location,
                     status: "reported",
                     evidence-hash: evidence-hash
                   })
        (ok true)
        (err u1))))

;; Get incident details
(define-read-only (get-incident (incident-id (string-ascii 32)))
  (map-get? incidents { incident-id: incident-id }))

;; Update incident status (admin only)
(define-public (update-incident-status (incident-id (string-ascii 32))
                                      (new-status (string-ascii 16)))
  (let ((caller tx-sender)
        (incident (unwrap-panic (map-get? incidents { incident-id: incident-id }))))
    (if (is-eq caller (var-get admin))
        (begin
          (map-set incidents
                  { incident-id: incident-id }
                  (merge incident { status: new-status }))
          (ok true))
        (err u2))))

;; Add additional evidence to an incident
(define-public (add-evidence (incident-id (string-ascii 32))
                            (new-evidence-hash (buff 32)))
  (let ((caller tx-sender)
        (incident (unwrap-panic (map-get? incidents { incident-id: incident-id }))))
    (if (is-eq caller (get reporter incident))
        (begin
          (map-set incidents
                  { incident-id: incident-id }
                  (merge incident { evidence-hash: new-evidence-hash }))
          (ok true))
        (err u3))))

;; Update admin
(define-public (set-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set admin new-admin)
          (ok true))
        (err u4))))
