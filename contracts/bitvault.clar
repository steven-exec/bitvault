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