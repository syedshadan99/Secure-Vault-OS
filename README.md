# Secure-Vault-OS
A console-based secure text storage application built in 32-bit x86 Assembly Language. This project simulates a high-security digital safe with a custom colored interface, cryptographic text scrambling, and persistent file handling. Developed as a semester project for the Computer Organization and Assembly Language (COAL) course.

Features
Graphical Console UI: Custom menus and screen borders utilizing Irvine32 color libraries for a clean, retro OS aesthetic.

Secure Authentication: Master password protection featuring a strict 3-attempt lockout system to prevent brute-force attacks.

XOR Cryptography: Fast, symmetric bitwise encryption and decryption of user data using low-level register manipulation.

Persistent Storage: Safely writes and reads encrypted strings to a local vault.txt file.

Data Integrity: Calculates and verifies an additive checksum to ensure the saved data has not been corrupted or tampered with.

Memory Protection: Enforces a strict 100-character input limit to prevent buffer overflow vulnerabilities.

Auto-Logout Timer: Tracks software milliseconds and automatically locks the vault after 15 seconds of user inactivity.

Tech Stack
Language: x86 Assembly Language (32-bit)

Assembler: Microsoft Macro Assembler (MASM)

Library: Irvine32 Library

Environment: Visual Studio

Prerequisites
To run, compile, or modify this project, your system must have:

Windows Operating System

Visual Studio installed with the Desktop development with C++ workload.

The Irvine32 Assembly Library properly configured and linked in your Visual Studio environment.

How to Run
Clone this repository to your local machine.

Open the project solution (.sln) in Visual Studio.

Ensure your project properties are correctly linked to your local Irvine32 library paths.

Build and run the project (Local Windows Debugger).

Default Login: Use the hardcoded master password (e.g., coal123) to access the vault.

Project Architecture & Modules
The system is built using modular programming, with data safely passed between procedures using stack frames to prevent register corruption.

master.asm: The main executable file containing the UI loop and integrated logic.

ui_procs.asm: Procedures for drawing menus, handling colors, and masking password input.

crypto_procs.asm: Procedures handling XOR bitwise encryption, decryption, and checksum generation.

fileio_procs.asm: Procedures for creating, writing to, and reading from vault.txt, alongside the timeout logic.

vault.txt: Generated automatically upon storing the first secret message.

Team Members
Syed Shadan Raza – UI Design, Menu Navigation, & System Integration

Abdulah Abdullah – Security Logic, XOR Cryptography, & Stack Management

Sajjad Ijaz – File I/O, Buffer Overflow Protection, & Auto-Logout Timer

Developed for Spring 2026 COAL Semester Project.
