;; Entity Verification Contract
;; Validates participating organizations in the knowledge management system

(define-data-var admin principal tx-sender)

;; Map to store verified entities
(define-map verified-entities principal
  {
    name: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-FOUND u102)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new entity
(define-public (register-entity (entity-name (string-utf8 100)))
  (begin
    (asserts! (not (default-to false (get verified (map-get? verified-entities tx-sender)))) (err ERR-ALREADY-VERIFIED))
    (ok (map-set verified-entities tx-sender
      {
        name: entity-name,
        verified: false,
        verification-date: u0
      }
    ))
  )
)

;; Verify an entity (admin only)
(define-public (verify-entity (entity principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (match (map-get? verified-entities entity)
      entity-data (ok (map-set verified-entities entity
        (merge entity-data {
          verified: true,
          verification-date: block-height
        })
      ))
      (err ERR-NOT-FOUND)
    )
  )
)

;; Check if an entity is verified
(define-read-only (is-verified (entity principal))
  (default-to false (get verified (map-get? verified-entities entity)))
)

;; Get entity details
(define-read-only (get-entity-details (entity principal))
  (map-get? verified-entities entity)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))
  )
)
