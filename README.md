# 🔐 Secure Vault OS

> **A Console-Based Digital Safe in x86 Assembly**
> *Department of Computer Science & Information Technology — Spring 2026*

---

## 📊 Project Overview

**Secure Vault OS** is a high-security text storage terminal application written in 32-bit x86 Assembly Language using **MASM** in Visual Studio. It bridges low-level hardware mechanics with practical security engineering by providing a colored menu interface, cryptographic text protection, data integrity verification, and automatic session timeouts.

---

## ⚡ Key Features & Low-Level Implementation

| Feature | How It Works Under the Hood | Technical Concept |
| --- | --- | --- |
| **🎨 Graphical Terminal** | Uses Irvine32 color attributes to draw a custom-styled, bordered interface. | `SetTextColor` & ASCII box-drawing |
| **🛡️ Brute-Force Prevention** | Tracks wrong password attempts and triggers a lockout after 3 failures. | Comparison flags (`CMP`, `JNE`) |
| **🔑 XOR Cryptography** | Scrambles user text into unreadable gibberish using symmetric bitwise math. | Bitwise manipulation (`XOR AL, key`) |
| **💾 Persistent Storage** | Streams protected string data into a local `vault.txt` file. | File buffer streaming (`WriteToFile`) |
| **🧬 Checksum Integrity** | Runs an arithmetic validation routine to verify data hasn't been altered. | Additive accumulation logic |
| **⏳ Auto-Logout Timer** | Monitors real-time clock cycles to lock the database after 15s of inactivity. | Delta-time math (`GetMseconds`) |

---

## 🏗️ System Architecture

The software follows **Modular Programming** principles, separating concerns into specialized assembly files while utilizing the CPU hardware Stack to protect system registers from corruption.

### Module Mapping

* **`master.asm`** ── The main orchestrator managing the primary initialization and logic loop.
* **`ui_procs.asm`** ── Houses visual borders, interface layouts, and colored alert triggers.
* **`crypto_procs.asm`** ── Houses verification conditions, password matches, and cryptographic loops.
* **`fileio_procs.asm`** ── Houses file read/write routines and time monitoring variables.

---

## 🛠️ Technical Stack & Setup

To run or modify this project, ensure your environment meets these specifications:

| Requirement | Specification |
| --- | --- |
| **Language** | x86 Assembly (32-bit MASM) |
| **IDE** | Visual Studio (C++ workload) |
| **Framework** | Irvine32 Runtime Library |
| **OS** | Windows |

### How to Execute

1. **Clone** the repository to your local workspace.
2. **Configure** your Project Properties to link the `Irvine32` library directory.
3. **Build** the solution using the Visual Studio compiler.
4. **Login** using the hardcoded credentials (e.g., `coal123`) at the initial boot screen.

### Team
1. **Syed Shadan Raza**
2. **Abdulah Abdullah**
3. **Sajjad Ijaz**

---

*Developed for Spring 2026 COAL Semester Project*
