;; Title: BitVault - Decentralized Bitcoin-Backed Lending Protocol
;;
;; Summary: A trustless lending platform enabling Bitcoin holders to unlock
;;          liquidity without selling their BTC through over-collateralized loans
;;
;; Description: BitVault revolutionizes Bitcoin utility by creating a bridge
;;              between hodling and liquidity. Users can deposit Bitcoin as
;;              collateral to secure USD-denominated loans while maintaining
;;              BTC exposure. The protocol ensures security through automated
;;              liquidation mechanisms and real-time price monitoring, making
;;              Bitcoin productive capital in the DeFi ecosystem.
;;
;; Features:
;;   - Over-collateralized lending with customizable ratios
;;   - Automated liquidation protection for lenders
;;   - Real-time Bitcoin price integration
;;   - Multi-asset support with governance controls
;;   - Transparent fee structure and platform statistics
;;

;; CONSTANTS & CONFIGURATION

(define-constant CONTRACT-OWNER tx-sender)

;; Error Codes - Comprehensive error handling for all operations
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-MINIMUM (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-ALREADY-INITIALIZED (err u104))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-INVALID-LIQUIDATION (err u106))
(define-constant ERR-LOAN-NOT-FOUND (err u107))
(define-constant ERR-LOAN-NOT-ACTIVE (err u108))
(define-constant ERR-INVALID-LOAN-ID (err u109))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-INVALID-ASSET (err u111))

;; Supported Collateral Assets
(define-constant VALID-ASSETS (list "BTC" "STX"))

;; PLATFORM STATE VARIABLES

(define-data-var platform-initialized bool false)
(define-data-var minimum-collateral-ratio uint u150) ;; 150% minimum collateral ratio
(define-data-var liquidation-threshold uint u120) ;; 120% liquidation trigger
(define-data-var platform-fee-rate uint u1) ;; 1% platform fee
(define-data-var total-btc-locked uint u0) ;; Total BTC locked as collateral
(define-data-var total-loans-issued uint u0) ;; Total number of loans created

;; DATA STRUCTURES

;; Loan Structure - Core loan information
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-rate: uint,
    start-height: uint,
    last-interest-calc: uint,
    status: (string-ascii 20),
  }
)

;; User Loan Tracking - Maps users to their active loans
(define-map user-loans
  { user: principal }
  { active-loans: (list 10 uint) }
)

;; Price Feed Management - Oracle price data for supported assets
(define-map collateral-prices
  { asset: (string-ascii 3) }
  { price: uint }
)

;; PRIVATE UTILITY FUNCTIONS

;; Calculate collateral ratio as percentage
(define-private (calculate-collateral-ratio
    (collateral uint)
    (loan uint)
    (btc-price uint)
  )
  (let (
      (collateral-value (* collateral btc-price))
      (ratio (* (/ collateral-value loan) u100))
    )
    ratio
  )
)

;; Calculate accrued interest based on blocks elapsed
(define-private (calculate-interest
    (principal uint)
    (rate uint)
    (blocks uint)
  )
  (let (
      (interest-per-block (/ (* principal rate) (* u100 u144))) ;; Daily interest / blocks per day
      (total-interest (* interest-per-block blocks))
    )
    total-interest
  )
)

;; Check if loan position requires liquidation
(define-private (check-liquidation (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (btc-price (unwrap! (get price (map-get? collateral-prices { asset: "BTC" }))
        ERR-NOT-INITIALIZED
      ))
      (current-ratio (calculate-collateral-ratio (get collateral-amount loan)
        (get loan-amount loan) btc-price
      ))
    )
    (if (<= current-ratio (var-get liquidation-threshold))
      (liquidate-position loan-id)
      (ok true)
    )
  )
)

;; Execute liquidation of undercollateralized position
(define-private (liquidate-position (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (borrower (get borrower loan))
    )
    (begin
      (map-set loans { loan-id: loan-id } (merge loan { status: "liquidated" }))
      (map-delete user-loans { user: borrower })
      (ok true)
    )
  )
)

;; Validate loan ID is within valid range
(define-private (validate-loan-id (loan-id uint))
  (and
    (> loan-id u0)
    (<= loan-id (var-get total-loans-issued))
  )
)

;; Verify asset is supported by platform
(define-private (is-valid-asset (asset (string-ascii 3)))
  (is-some (index-of VALID-ASSETS asset))
)

;; Validate price feed data integrity
(define-private (is-valid-price (price uint))
  (and
    (> price u0)
    (<= price u1000000000000) ;; Reasonable upper limit
  )
)

;; Helper function for loan ID filtering
(define-private (not-equal-loan-id (id uint))
  (not (is-eq id id))
)

;; PLATFORM MANAGEMENT FUNCTIONS

;; Initialize the BitVault platform
(define-public (initialize-platform)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get platform-initialized)) ERR-ALREADY-INITIALIZED)
    (var-set platform-initialized true)
    (ok true)
  )
)

;; CORE LENDING OPERATIONS

;; Deposit Bitcoin collateral to the platform
(define-public (deposit-collateral (amount uint))
  (begin
    (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (var-set total-btc-locked (+ (var-get total-btc-locked) amount))
    (ok true)
  )
)