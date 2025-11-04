# 📋 Open Source License Verifier

🔒 A comprehensive Clarity smart contract for verifying and managing open-source license compliance on the Stacks blockchain.

## 🌟 Features

- ✅ **License Registration**: Add and manage various open-source licenses with detailed permissions
- 🏗️ **Project Registration**: Register projects with their associated licenses
- 👨‍💼 **Authorized Verifiers**: Manage a network of trusted license compliance verifiers
- 🔍 **Compliance Verification**: Verify project compliance with their declared licenses
- 🔗 **Dependency Tracking**: Track project dependencies and their license compatibility
- ⚖️ **License Compatibility**: Check compatibility between different licenses
- 📊 **Reputation System**: Track verifier performance and reliability

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `clarinet check` to verify the contract

## 📖 Usage

### 🏷️ Adding a License

Only the contract owner can add new licenses:

```clarity
(contract-call? .open-source-license-verifier add-license
  "MIT"
  "MIT License"
  "A permissive license with minimal restrictions"
  false  ;; copyleft
  true   ;; commercial-use
  true   ;; modification
  true   ;; distribution
  false  ;; patent-use
  true   ;; private-use
  false  ;; disclose-source
  false  ;; same-license
)
```

### 📁 Registering a Project

Any user can register a project:

```clarity
(contract-call? .open-source-license-verifier register-project
  "my-awesome-project"
  "Awesome Web Framework"
  "A modern web framework built with TypeScript"
  "MIT"
  "https://github.com/user/awesome-project"
)
```

### 👨‍⚖️ Adding Verifiers

Contract owner can authorize verifiers:

```clarity
(contract-call? .open-source-license-verifier add-verifier
  'SP1234567890ABCDEF
  "Expert License Auditor"
)
```

### ✅ Verifying Project Compliance

Authorized verifiers can verify projects:

```clarity
(contract-call? .open-source-license-verifier verify-project
  "my-awesome-project"
  true  ;; compliant
)
```

### 🔗 Adding Dependencies

Project owners can add dependencies:

```clarity
(contract-call? .open-source-license-verifier add-dependency
  "my-awesome-project"
  "dependency-project"
)
```

### ⚖️ Setting License Compatibility

Contract owner can define license compatibility rules:

```clarity
(contract-call? .open-source-license-verifier set-license-compatibility
  "MIT"
  "Apache-2.0"
  true
  "MIT is compatible with Apache 2.0"
)
```

## 🔍 Read-Only Functions

### Get License Information
```clarity
(contract-call? .open-source-license-verifier get-license "MIT")
```

### Get Project Information
```clarity
(contract-call? .open-source-license-verifier get-project "my-awesome-project")
```

### Check Project Compliance
```clarity
(contract-call? .open-source-license-verifier is-project-compliant "my-awesome-project")
```

### Get License Compatibility
```clarity
(contract-call? .open-source-license-verifier get-license-compatibility "MIT" "GPL-3.0")
```

### Get Contract Statistics
```clarity
(contract-call? .open-source-license-verifier get-contract-stats)
```

## 🏗️ Contract Architecture

### 🗂️ Data Maps

- **licenses**: Store license definitions and permissions
- **projects**: Track registered projects and their compliance status
- **project-dependencies**: Map project dependencies and compatibility
- **license-compatibility**: Define compatibility rules between licenses
- **verifiers**: Manage authorized compliance verifiers

### 🔐 Access Control

- **Contract Owner**: Can add licenses, verifiers, and set compatibility rules
- **Project Owners**: Can register projects and add dependencies
- **Authorized Verifiers**: Can verify project compliance
- **Public**: Can read all information

## 🎯 Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only action |
| u101 | Resource not found |
| u102 | Resource already exists |
| u103 | Invalid license |
| u104 | Incompatible license |
| u105 | Unauthorized action |

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - promoting open-source compliance! 🎉

## 🌐 Community

- 💬 Join our discussions
- 🐛 Report issues
- 💡 Suggest features
- ⭐ Star the repository if you find it useful!

---

Built with ❤️ for the open-source community on Stacks blockchain! 🔗
