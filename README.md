# 🧾 Tokenized Invoices

> Transform your invoicing process with blockchain-powered tokenized invoices! 🚀

## 📝 Overview

Tokenized Invoices is a revolutionary smart contract system built on Stacks that allows sellers to issue invoice tokens and enables secure payment processing when goods are delivered. Each invoice becomes an NFT, providing transparency, traceability, and trustless transactions.

## ✨ Key Features

- 🎫 **NFT Invoice Tokens**: Each invoice is minted as a unique NFT
- 💰 **Secure Payments**: STX payments held until goods are delivered
- 📦 **Delivery Confirmation**: Sellers mark goods as delivered
- 🔄 **Transfer Ownership**: Invoice tokens can be transferred to other sellers
- 📊 **Analytics Dashboard**: Track pending and paid invoice statistics
- ❌ **Cancellation Support**: Cancel unpaid invoices before delivery

## 🛠️ Core Functions

### For Sellers 👨‍💼

#### Create Invoice
```clarity
(contract-call? .tokenized-invoices create-invoice 'ST1BUYER123 u1000000)
```
Creates a new invoice for 1 STX to buyer address.

#### Mark as Delivered
```clarity
(contract-call? .tokenized-invoices mark-delivered u1)
```
Confirms goods have been delivered for invoice #1.

#### Transfer Invoice
```clarity
(contract-call? .tokenized-invoices transfer-invoice u1 'ST1NEWSELLER456)
```
Transfers invoice ownership to another seller.

#### Cancel Invoice
```clarity
(contract-call? .tokenized-invoices cancel-invoice u1)
```
Cancels an undelivered invoice.

### For Buyers 💳

#### Pay Invoice
```clarity
(contract-call? .tokenized-invoices pay-invoice u1)
```
Pays for delivered goods in invoice #1.

### Read-Only Functions 📖

#### Get Invoice Details
```clarity
(contract-call? .tokenized-invoices get-invoice u1)
```

#### Check Invoice Status
```clarity
(contract-call? .tokenized-invoices get-invoice-status u1)
```
Returns: `"pending"`, `"delivered"`, `"paid"`, or `"not-found"`

#### Get Seller Statistics
```clarity
(contract-call? .tokenized-invoices get-seller-stats 'ST1SELLER123)
```

#### Get Buyer Statistics  
```clarity
(contract-call? .tokenized-invoices get-buyer-stats 'ST1BUYER456)
```

## 🔄 Invoice Lifecycle

```
📝 Created → 📦 Delivered → 💰 Paid
     ↓           ↓
    ❌ Cancel   🔄 Transfer
```

1. **Creation** 📝: Seller creates invoice with buyer address and amount
2. **Delivery** 📦: Seller marks goods as delivered
3. **Payment** 💰: Buyer pays after receiving goods
4. **Complete** ✅: Transaction finalized

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks Wallet](https://www.hiro.so/wallet) for testing

### Setup
```bash
clarinet new tokenized-invoices
cd tokenized-invoices
# Copy the contract file to contracts/tokenized-invoices.clar
```

### Test
```bash
clarinet test
```

### Deploy
```bash
clarinet deploy --testnet
```

## 📊 Data Structure

### Invoice Object
```clarity
{
  seller: principal,
  buyer: principal, 
  amount: uint,
  delivered: bool,
  paid: bool,
  created-at: uint,
  delivered-at: (optional uint),
  paid-at: (optional uint)
}
```

## ⚠️ Error Codes

- `u100`: Not authorized
- `u101`: Invoice not found  
- `u102`: Invoice already paid
- `u103`: Invoice not delivered
- `u104`: Insufficient funds
- `u105`: Invalid amount
- `u106`: Already delivered
- `u107`: Self payment not allowed

## 🔒 Security Features

- ✅ Authorization checks for all operations
- ✅ Prevents self-payment
- ✅ Validates invoice states
- ✅ Secure STX transfer mechanism
- ✅ NFT ownership verification

## 💡 Use Cases

- 🛒 **E-commerce**: Online store payments with delivery confirmation
- 🏗️ **Construction**: Progress-based payments for contractors
- 🚚 **Logistics**: Freight payment upon delivery
- 🎨 **Freelancing**: Creative work payments with milestone delivery
- 📦 **Supply Chain**: B2B invoice management



## 📄 License

MIT License - Build amazing things! 🌟

---

*Built with ❤️ on Stacks blockchain*
