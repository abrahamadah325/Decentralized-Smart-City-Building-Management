;; building-verification.clar
;; A contract that validates and registers urban structures

(define-data-var last-building-id uint u0)

;; Define building structure
(define-map buildings
  { building-id: uint }
  {
    owner: principal,
    status: (string-ascii 20),
    verification-date: uint,
    building-type: (string-ascii 30),
    location: (string-ascii 50)
  }
)

;; Define verification status tracking
(define-map verification-history
  { building-id: uint, timestamp: uint }
  {
    verifier: principal,
    status: (string-ascii 20),
    notes: (string-ascii 100)
  }
)

;; Register a new building
(define-public (register-building
                (building-type (string-ascii 30))
                (location (string-ascii 50)))
  (let ((new-id (+ (var-get last-building-id) u1)))
    (begin
      (var-set last-building-id new-id)
      (map-set buildings
        { building-id: new-id }
        {
          owner: tx-sender,
          status: "pending",
          verification-date: u0,
          building-type: building-type,
          location: location
        }
      )
      (ok new-id)
    )
  )
)

;; Verify a building (only authorized verifiers)
(define-public (verify-building
                (building-id uint)
                (status (string-ascii 20))
                (notes (string-ascii 100)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (begin
      (asserts! (is-authorized-verifier tx-sender) (err u403))
      (asserts! (is-building-registered building-id) (err u404))

      ;; Update building status
      (map-set buildings
        { building-id: building-id }
        (merge (unwrap-panic (map-get? buildings { building-id: building-id }))
               {
                 status: status,
                 verification-date: current-time
               }
        )
      )

      ;; Record verification history
      (map-set verification-history
        { building-id: building-id, timestamp: current-time }
        {
          verifier: tx-sender,
          status: status,
          notes: notes
        }
      )

      (ok true)
    )
  )
)

;; Check if a building is registered
(define-private (is-building-registered (building-id uint))
  (is-some (map-get? buildings { building-id: building-id }))
)

;; Check if principal is an authorized verifier
;; In a real implementation, this would check against a list of authorized verifiers
(define-private (is-authorized-verifier (principal principal))
  ;; Simplified for demo - would be replaced with proper authorization logic
  (is-eq principal tx-sender)
)

;; Get building details
(define-read-only (get-building-details (building-id uint))
  (map-get? buildings { building-id: building-id })
)

;; Get verification history for a building
(define-read-only (get-verification-history (building-id uint) (timestamp uint))
  (map-get? verification-history { building-id: building-id, timestamp: timestamp })
)
