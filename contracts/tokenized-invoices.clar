(define-non-fungible-token invoice-token uint)

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVOICE_NOT_FOUND (err u101))
(define-constant ERR_INVOICE_ALREADY_PAID (err u102))
(define-constant ERR_INVOICE_NOT_DELIVERED (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_ALREADY_DELIVERED (err u106))
(define-constant ERR_SELF_PAYMENT (err u107))

(define-data-var next-invoice-id uint u1)

(define-map invoices uint {
  seller: principal,
  buyer: principal,
  amount: uint,
  delivered: bool,
  paid: bool,
  created-at: uint,
  delivered-at: (optional uint),
  paid-at: (optional uint)
})

(define-map seller-invoices principal (list 100 uint))
(define-map buyer-invoices principal (list 100 uint))

(define-public (create-invoice (buyer principal) (amount uint))
  (let ((invoice-id (var-get next-invoice-id)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (not (is-eq tx-sender buyer)) ERR_SELF_PAYMENT)
    
    (try! (nft-mint? invoice-token invoice-id tx-sender))
    
    (map-set invoices invoice-id {
      seller: tx-sender,
      buyer: buyer,
      amount: amount,
      delivered: false,
      paid: false,
      created-at: burn-block-height,
      delivered-at: none,
      paid-at: none
    })
    
    (map-set seller-invoices tx-sender 
      (unwrap! 
        (as-max-len? 
          (append 
            (default-to (list) (map-get? seller-invoices tx-sender)) 
            invoice-id) 
          u100) 
        ERR_INVALID_AMOUNT))
    
    (map-set buyer-invoices buyer 
      (unwrap! 
        (as-max-len? 
          (append 
            (default-to (list) (map-get? buyer-invoices buyer)) 
            invoice-id) 
          u100) 
        ERR_INVALID_AMOUNT))
    
    (var-set next-invoice-id (+ invoice-id u1))
    (ok invoice-id)
  )
)

(define-public (mark-delivered (invoice-id uint))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get seller invoice)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get delivered invoice)) ERR_ALREADY_DELIVERED)
    (asserts! (not (get paid invoice)) ERR_INVOICE_ALREADY_PAID)
    
    (map-set invoices invoice-id (merge invoice {
      delivered: true,
      delivered-at: (some burn-block-height)
    }))
    
    (ok true)
  )
)

(define-public (pay-invoice (invoice-id uint))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get buyer invoice)) ERR_NOT_AUTHORIZED)
    (asserts! (get delivered invoice) ERR_INVOICE_NOT_DELIVERED)
    (asserts! (not (get paid invoice)) ERR_INVOICE_ALREADY_PAID)
    (asserts! (>= (stx-get-balance tx-sender) (get amount invoice)) ERR_INSUFFICIENT_FUNDS)
    
    (try! (stx-transfer? (get amount invoice) tx-sender (get seller invoice)))
    
    (map-set invoices invoice-id (merge invoice {
      paid: true,
      paid-at: (some burn-block-height)
    }))
    
    (ok true)
  )
)

(define-public (cancel-invoice (invoice-id uint))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get seller invoice)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get delivered invoice)) ERR_ALREADY_DELIVERED)
    (asserts! (not (get paid invoice)) ERR_INVOICE_ALREADY_PAID)
    
    (try! (nft-burn? invoice-token invoice-id tx-sender))
    (map-delete invoices invoice-id)
    
    (ok true)
  )
)

(define-public (transfer-invoice (invoice-id uint) (new-seller principal))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get seller invoice)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get delivered invoice)) ERR_ALREADY_DELIVERED)
    (asserts! (not (get paid invoice)) ERR_INVOICE_ALREADY_PAID)
    
    (try! (nft-transfer? invoice-token invoice-id tx-sender new-seller))
    
    (map-set invoices invoice-id (merge invoice {
      seller: new-seller
    }))
    
    (ok true)
  )
)

(define-read-only (get-invoice (invoice-id uint))
  (map-get? invoices invoice-id)
)

(define-read-only (get-invoice-owner (invoice-id uint))
  (nft-get-owner? invoice-token invoice-id)
)

(define-read-only (get-seller-invoices (seller principal))
  (default-to (list) (map-get? seller-invoices seller))
)

(define-read-only (get-buyer-invoices (buyer principal))
  (default-to (list) (map-get? buyer-invoices buyer))
)

(define-read-only (get-next-invoice-id)
  (var-get next-invoice-id)
)

(define-read-only (get-invoice-status (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice
      (if (get paid invoice)
        "paid"
        (if (get delivered invoice)
          "delivered"
          "pending"))
    "not-found"
  )
)

(define-read-only (calculate-total-pending (invoices-list (list 100 uint)))
  (fold calculate-pending-amount invoices-list u0)
)

(define-read-only (calculate-total-paid (invoices-list (list 100 uint)))
  (fold calculate-paid-amount invoices-list u0)
)

(define-private (calculate-pending-amount (invoice-id uint) (total uint))
  (match (map-get? invoices invoice-id)
    invoice
      (if (and (not (get paid invoice)) (not (get delivered invoice)))
        (+ total (get amount invoice))
        total)
    total
  )
)

(define-private (calculate-paid-amount (invoice-id uint) (total uint))
  (match (map-get? invoices invoice-id)
    invoice
      (if (get paid invoice)
        (+ total (get amount invoice))
        total)
    total
  )
)

(define-read-only (get-seller-stats (seller principal))
  (let ((seller-invoice-list (get-seller-invoices seller)))
    {
      total-invoices: (len seller-invoice-list),
      total-pending: (calculate-total-pending seller-invoice-list),
      total-paid: (calculate-total-paid seller-invoice-list)
    }
  )
)

(define-read-only (get-buyer-stats (buyer principal))
  (let ((buyer-invoice-list (get-buyer-invoices buyer)))
    {
      total-invoices: (len buyer-invoice-list),
      total-pending: (calculate-total-pending buyer-invoice-list),
      total-paid: (calculate-total-paid buyer-invoice-list)
    }
  )
)
