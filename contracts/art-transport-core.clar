;; Art Transport Core Contract
;; Manages transportation orders, clients, and service providers

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ORDER-NOT-FOUND (err u101))
(define-constant ERR-INVALID-STATUS (err u102))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u103))
(define-constant ERR-INVALID-INPUT (err u104))
(define-constant ERR-ALREADY-EXISTS (err u105))
(define-constant ERR-EXPIRED (err u106))
(define-constant ERR-CONDITIONS-NOT-MET (err u107))

;; Data Variables
(define-data-var next-order-id uint u1)
(define-data-var next-provider-id uint u1)
(define-data-var contract-paused bool false)

;; Data Maps
(define-map orders uint {
  client: principal,
  provider: (optional principal),
  artwork-title: (string-ascii 100),
  artwork-artist: (string-ascii 100),
  artwork-width: uint,
  artwork-height: uint,
  artwork-depth: uint,
  artwork-weight: uint,
  artwork-material: (string-ascii 50),
  estimated-value: uint,
  origin-address: (string-ascii 200),
  origin-contact: (string-ascii 100),
  destination-address: (string-ascii 200),
  destination-contact: (string-ascii 100),
  special-requirements: (string-ascii 500),
  status: (string-ascii 20),
  total-cost: uint,
  payment-received: uint,
  created-at: uint,
  estimated-delivery: uint,
  actual-delivery: (optional uint)
})

(define-map clients principal {
  name: (string-ascii 100),
  contact-email: (string-ascii 100),
  phone: (string-ascii 20),
  address: (string-ascii 200),
  verified: bool,
  total-orders: uint,
  registration-date: uint
})

(define-map service-providers principal {
  provider-id: uint,
  company-name: (string-ascii 100),
  license-number: (string-ascii 50),
  specializations: (string-ascii 200),
  insurance-coverage: uint,
  rating: uint,
  total-completed: uint,
  verified: bool,
  active: bool,
  registration-date: uint
})

(define-map order-payments uint {
  order-id: uint,
  client: principal,
  amount: uint,
  payment-date: uint,
  payment-type: (string-ascii 20)
})

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER))

(define-private (is-order-client (order-id uint))
  (match (map-get? orders order-id)
    order (is-eq tx-sender (get client order))
    false))

(define-private (is-order-provider (order-id uint))
  (match (map-get? orders order-id)
    order (match (get provider order)
      provider-principal (is-eq tx-sender provider-principal)
      false)
    false))

(define-private (can-modify-order (order-id uint))
  (or (is-contract-owner)
      (is-order-client order-id)
      (is-order-provider order-id)))

;; Validation Functions
(define-private (is-valid-dimensions (width uint) (height uint) (depth uint))
  (and (> width u0)
       (> height u0)
       (> depth u0)
       (< width u10000)
       (< height u10000)
       (< depth u10000)))

(define-private (is-valid-weight (weight uint))
  (and (> weight u0)
       (< weight u100000)))

(define-private (is-valid-value (value uint))
  (and (> value u0)
       (< value u1000000000)))

(define-private (is-valid-status (status (string-ascii 20)))
  (or (is-eq status "pending")
      (is-eq status "confirmed")
      (is-eq status "in-transit")
      (is-eq status "delivered")
      (is-eq status "cancelled")))

;; Client Management Functions
(define-public (register-client (name (string-ascii 100))
                               (contact-email (string-ascii 100))
                               (phone (string-ascii 20))
                               (address (string-ascii 200)))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONDITIONS-NOT-MET)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len contact-email) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? clients tx-sender)) ERR-ALREADY-EXISTS)
    (ok (map-set clients tx-sender {
      name: name,
      contact-email: contact-email,
      phone: phone,
      address: address,
      verified: false,
      total-orders: u0,
      registration-date: block-height
    }))))

(define-public (verify-client (client principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? clients client)) ERR-ORDER-NOT-FOUND)
    (ok (map-set clients client
      (merge (unwrap-panic (map-get? clients client))
             {verified: true})))))

;; Service Provider Management Functions
(define-public (register-provider (company-name (string-ascii 100))
                                 (license-number (string-ascii 50))
                                 (specializations (string-ascii 200))
                                 (insurance-coverage uint))
  (let ((provider-id (var-get next-provider-id)))
    (begin
      (asserts! (not (var-get contract-paused)) ERR-CONDITIONS-NOT-MET)
      (asserts! (> (len company-name) u0) ERR-INVALID-INPUT)
      (asserts! (> (len license-number) u0) ERR-INVALID-INPUT)
      (asserts! (> insurance-coverage u0) ERR-INVALID-INPUT)
      (asserts! (is-none (map-get? service-providers tx-sender)) ERR-ALREADY-EXISTS)
      (var-set next-provider-id (+ provider-id u1))
      (ok (map-set service-providers tx-sender {
        provider-id: provider-id,
        company-name: company-name,
        license-number: license-number,
        specializations: specializations,
        insurance-coverage: insurance-coverage,
        rating: u0,
        total-completed: u0,
        verified: false,
        active: true,
        registration-date: block-height
      })))))

(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? service-providers provider)) ERR-ORDER-NOT-FOUND)
    (ok (map-set service-providers provider
      (merge (unwrap-panic (map-get? service-providers provider))
             {verified: true})))))

;; Order Management Functions
(define-public (create-order (artwork-title (string-ascii 100))
                            (artwork-artist (string-ascii 100))
                            (artwork-width uint)
                            (artwork-height uint)
                            (artwork-depth uint)
                            (artwork-weight uint)
                            (artwork-material (string-ascii 50))
                            (estimated-value uint)
                            (origin-address (string-ascii 200))
                            (origin-contact (string-ascii 100))
                            (destination-address (string-ascii 200))
                            (destination-contact (string-ascii 100))
                            (special-requirements (string-ascii 500))
                            (estimated-delivery uint))
  (let ((order-id (var-get next-order-id))
        (client-data (map-get? clients tx-sender)))
    (begin
      (asserts! (not (var-get contract-paused)) ERR-CONDITIONS-NOT-MET)
      (asserts! (is-some client-data) ERR-NOT-AUTHORIZED)
      (asserts! (get verified (unwrap-panic client-data)) ERR-NOT-AUTHORIZED)
      (asserts! (> (len artwork-title) u0) ERR-INVALID-INPUT)
      (asserts! (> (len artwork-artist) u0) ERR-INVALID-INPUT)
      (asserts! (is-valid-dimensions artwork-width artwork-height artwork-depth) ERR-INVALID-INPUT)
      (asserts! (is-valid-weight artwork-weight) ERR-INVALID-INPUT)
      (asserts! (is-valid-value estimated-value) ERR-INVALID-INPUT)
      (asserts! (> estimated-delivery block-height) ERR-INVALID-INPUT)
      (var-set next-order-id (+ order-id u1))
      (map-set clients tx-sender
        (merge (unwrap-panic client-data)
               {total-orders: (+ (get total-orders (unwrap-panic client-data)) u1)}))
      (ok (map-set orders order-id {
        client: tx-sender,
        provider: none,
        artwork-title: artwork-title,
        artwork-artist: artwork-artist,
        artwork-width: artwork-width,
        artwork-height: artwork-height,
        artwork-depth: artwork-depth,
        artwork-weight: artwork-weight,
        artwork-material: artwork-material,
        estimated-value: estimated-value,
        origin-address: origin-address,
        origin-contact: origin-contact,
        destination-address: destination-address,
        destination-contact: destination-contact,
        special-requirements: special-requirements,
        status: "pending",
        total-cost: u0,
        payment-received: u0,
        created-at: block-height,
        estimated-delivery: estimated-delivery,
        actual-delivery: none
      })))))

(define-public (assign-provider (order-id uint) (provider principal) (total-cost uint))
  (let ((order-data (map-get? orders order-id))
        (provider-data (map-get? service-providers provider)))
    (begin
      (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
      (asserts! (is-some order-data) ERR-ORDER-NOT-FOUND)
      (asserts! (is-some provider-data) ERR-ORDER-NOT-FOUND)
      (asserts! (get verified (unwrap-panic provider-data)) ERR-NOT-AUTHORIZED)
      (asserts! (get active (unwrap-panic provider-data)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status (unwrap-panic order-data)) "pending") ERR-INVALID-STATUS)
      (asserts! (> total-cost u0) ERR-INVALID-INPUT)
      (ok (map-set orders order-id
        (merge (unwrap-panic order-data)
               {provider: (some provider),
                total-cost: total-cost,
                status: "confirmed"}))))))

(define-public (update-order-status (order-id uint) (new-status (string-ascii 20)))
  (let ((order-data (map-get? orders order-id)))
    (begin
      (asserts! (is-some order-data) ERR-ORDER-NOT-FOUND)
      (asserts! (can-modify-order order-id) ERR-NOT-AUTHORIZED)
      (asserts! (is-valid-status new-status) ERR-INVALID-INPUT)
      (if (is-eq new-status "delivered")
        (ok (map-set orders order-id
          (merge (unwrap-panic order-data)
                 {status: new-status,
                  actual-delivery: (some block-height)})))
        (ok (map-set orders order-id
          (merge (unwrap-panic order-data)
                 {status: new-status})))))))

;; Payment Functions
(define-public (make-payment (order-id uint))
  (let ((order-data (map-get? orders order-id))
        (payment-amount (stx-get-balance tx-sender)))
    (begin
      (asserts! (is-some order-data) ERR-ORDER-NOT-FOUND)
      (asserts! (is-order-client order-id) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status (unwrap-panic order-data)) "confirmed") ERR-INVALID-STATUS)
      (asserts! (>= payment-amount (get total-cost (unwrap-panic order-data))) ERR-INSUFFICIENT-PAYMENT)
      (try! (stx-transfer? (get total-cost (unwrap-panic order-data)) tx-sender CONTRACT-OWNER))
      (map-set orders order-id
        (merge (unwrap-panic order-data)
               {payment-received: (get total-cost (unwrap-panic order-data))}))
      (ok (map-set order-payments order-id {
        order-id: order-id,
        client: tx-sender,
        amount: (get total-cost (unwrap-panic order-data)),
        payment-date: block-height,
        payment-type: "full-payment"
      })))))

;; Read-only Functions
(define-read-only (get-order (order-id uint))
  (map-get? orders order-id))

(define-read-only (get-client (client principal))
  (map-get? clients client))

(define-read-only (get-provider (provider principal))
  (map-get? service-providers provider))

(define-read-only (get-order-payment (order-id uint))
  (map-get? order-payments order-id))

(define-read-only (get-next-order-id)
  (var-get next-order-id))

(define-read-only (get-next-provider-id)
  (var-get next-provider-id))

(define-read-only (is-contract-paused)
  (var-get contract-paused))

;; Admin Functions
(define-public (pause-contract)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-paused true))))

(define-public (unpause-contract)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-paused false))))

(define-public (update-provider-rating (provider principal) (new-rating uint))
  (let ((provider-data (map-get? service-providers provider)))
    (begin
      (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
      (asserts! (is-some provider-data) ERR-ORDER-NOT-FOUND)
      (asserts! (<= new-rating u5) ERR-INVALID-INPUT)
      (ok (map-set service-providers provider
        (merge (unwrap-panic provider-data)
               {rating: new-rating}))))))
