# Art and Antique Transportation Services

A comprehensive blockchain-based system for managing specialized art and antique transportation services, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a complete solution for art and antique transportation, covering every aspect from initial packing requirements to final installation. The platform ensures transparency, security, and accountability throughout the entire transportation process.

## Key Features

### 🎨 Specialized Handling Management
- Custom packing requirements specification
- Handling protocol documentation
- Material and equipment tracking
- Professional certification verification

### 🌡️ Environmental Monitoring
- Real-time temperature and humidity tracking
- Climate control verification
- Environmental condition alerts
- Historical data logging

### 🛡️ Insurance & Valuation
- Transparent insurance coverage calculation
- Professional appraisal integration
- Risk assessment protocols
- Claims processing automation

### 📦 Custom Crating Services
- Bespoke crating specifications
- Material requirements tracking
- Quality assurance protocols
- Installation coordination

### 🌍 International Shipping
- Customs documentation automation
- Regulatory compliance tracking
- International shipping protocols
- Multi-jurisdiction support

## Smart Contract Architecture

The system consists of five interconnected smart contracts:

### 1. Art Transport Core (`art-transport-core.clar`)
- Main transportation order management
- Client and service provider registration
- Order lifecycle tracking
- Payment processing

### 2. Insurance Valuation (`insurance-valuation.clar`)
- Artwork valuation management
- Insurance policy creation
- Premium calculation
- Claims processing

### 3. Environmental Monitor (`environmental-monitor.clar`)
- Environmental condition tracking
- Alert system management
- Compliance verification
- Historical data storage

### 4. Customs Documentation (`customs-documentation.clar`)
- International shipping documentation
- Customs declaration management
- Regulatory compliance tracking
- Multi-country support

### 5. Installation Coordination (`installation-coordination.clar`)
- Installation scheduling
- Professional coordination
- Quality verification
- Completion certification

## Data Types

### Transportation Order
```clarity
{
  order-id: uint,
  client: principal,
  artwork-details: {
    title: (string-ascii 100),
    artist: (string-ascii 100),
    dimensions: {width: uint, height: uint, depth: uint},
    weight: uint,
    material: (string-ascii 50),
    estimated-value: uint
  },
  origin: {
    address: (string-ascii 200),
    contact: (string-ascii 100)
  },
  destination: {
    address: (string-ascii 200),
    contact: (string-ascii 100)
  },
  special-requirements: (string-ascii 500),
  status: (string-ascii 20),
  created-at: uint,
  estimated-delivery: uint
}
