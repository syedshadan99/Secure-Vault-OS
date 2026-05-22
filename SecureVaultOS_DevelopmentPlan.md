**COAL SEMESTER PROJECT**

Computer Organization and Assembly Language

**Secure Vault OS**

*Secure Text Storage System with Attack Prevention*

**Step-by-Step Development Plan**

**Team Members**

|              |                                 |
|:------------:|:-------------------------------:|
|   **Role**   |           **Member**            |
| **Person 1** |    UI & Main Loop Developer     |
| **Person 2** | Security & Encryption Developer |
| **Person 3** |   File I/O & Input Developer    |

Spring 2026 \| 8086 Assembly Language (MASM + Irvine32)

**1. Project Overview**

This document is the complete step-by-step development plan for the Secure Vault OS project. Every member has their own clearly defined timeline, steps, and tests. The plan is designed so all three members can work independently without getting blocked by each other.

**1.1 What the Project Does**

- Shows a colored, bordered terminal UI using Irvine32.

- Requires a password to log in (max 3 wrong attempts, then exits).

- Lets the user type a secret message (max 100 characters).

- Encrypts the message using XOR and saves it to vault.txt.

- Reads vault.txt, decrypts the message, and verifies its checksum.

- Auto-logs out after 15 seconds of inactivity on the menu.

**1.2 Tools & Environment**

|  |  |
|:--:|:--:|
| **Tool** | **Purpose** |
| Visual Studio + MASM | Main development environment |
| EMU8086 | Quick testing of small code snippets |
| Irvine32 Library | ReadString, WriteString, SetTextColor, GetMseconds, file procedures |
| vault.txt | The output file where encrypted data is stored |

**1.3 Final File Structure**

master.asm \<\-- FINAL file (all code goes here at the end)\
ui_procs.asm \<\-- Person 1 works here\
crypto_procs.asm \<\-- Person 2 works here\
fileio_procs.asm \<\-- Person 3 works here\
vault.txt \<\-- Created automatically when program runs

Each person develops in their own .asm file. On Day 3, all code is copied into master.asm by Person 1.

**2. Shared Rules (All 3 Members Must Follow)**

These rules prevent the most common integration bugs. Read them once carefully and follow them in every procedure you write.

**Rule 1 --- Save and Restore Registers in Every Procedure**

Every single procedure MUST start with PUSHAD and end with POPAD before RET. This protects the main program\'s register values from being destroyed.

my_proc PROC\
PUSHAD ; save all registers (do this first, always)\
; \... your code goes here \...\
POPAD ; restore all registers (do this last, always)\
RET\
my_proc ENDP

**Rule 2 --- Shared .data Section**

All global variables are defined ONCE in master.asm. Each member must use these exact variable names in their own procedures --- do not redefine them in your separate file.

.data\
master_pass BYTE \"coal123\", 0 ; hardcoded password\
filename BYTE \"vault.txt\", 0 ; file name\
input_buffer BYTE 101 DUP(0) ; 100 chars + null terminator\
encrypted_buffer BYTE 101 DUP(0) ; holds XOR-encrypted text\
xor_key BYTE 42 ; the encryption key (change if you want)\
checksum_val BYTE 0 ; holds the calculated checksum\
strike_count BYTE 0 ; wrong password counter\
timer_start DWORD 0 ; holds the timestamp for auto-logout

**Rule 3 --- Buffer Ownership**

To avoid confusion, only one person writes to each buffer:

- input_buffer → ONLY Person 3 (read_input) writes here.

- encrypted_buffer → ONLY Person 2 (encrypt_decrypt_proc) writes here.

- checksum_val → ONLY Person 2 (calculate_checksum) writes here.

- timer_start → ONLY Person 3 (check_timeout_proc) writes here.

**Rule 4 --- Test Every Step Before Moving Forward**

Do NOT move to the next step until the current step works. A small bug found early takes 5 minutes to fix. The same bug found during integration can take hours.

**PERSON 1 --- UI & Main Loop Developer**

**File to work in: ui_procs.asm**

Procedures to build: draw_border, draw_menu, hidden_input, main_loop

**DAY 1 --- Build the Border and Menu Display**

**Step 1.1 --- Set Up Your File**

Create ui_procs.asm. Copy the shared .data section at the top (just for reference --- do not redefine variables in master.asm later). Add the INCLUDE and library lines:

INCLUDE Irvine32.inc\
\
.data\
; (paste the shared variables here for now --- remove when merging)\
\
.code

✅ Test: File compiles without errors (even if it is empty).

**Step 1.2 --- Write draw_border**

This procedure draws a box around the screen using box-drawing characters. Use SetTextColor (Irvine) to set yellow before drawing.

draw_border PROC\
PUSHAD\
mov eax, yellow + (black \* 16) ; yellow text, black background\
call SetTextColor\
mov edx, OFFSET border_top ; border_top BYTE \"╔══════════════╗\", 0\
call WriteString\
call Crlf\
; repeat for side borders and bottom border\
POPAD\
RET\
draw_border ENDP

Add these strings to your .data section:

border_top BYTE \"╔══════════════════════════════╗\", 0\
border_side BYTE \"║\", 0\
border_bot BYTE \"╚══════════════════════════════╝\", 0\
title_str BYTE \" SECURE VAULT OS \", 0

✅ Test: Run the program. You should see a yellow box on a black background.

**Step 1.3 --- Write draw_menu**

This procedure prints the 3 menu options in light blue text inside the border.

draw_menu PROC\
PUSHAD\
call draw_border ; call your own border first\
mov eax, lightBlue + (black\*16)\
call SetTextColor\
mov edx, OFFSET menu_opt1 ; \" \[1\] Store Secret\"\
call WriteString\
call Crlf\
mov edx, OFFSET menu_opt2 ; \" \[2\] View Secret\"\
call WriteString\
call Crlf\
mov edx, OFFSET menu_opt3 ; \" \[3\] Logout\"\
call WriteString\
call Crlf\
POPAD\
RET\
draw_menu ENDP

✅ Test: Call draw_menu from main. Confirm all 3 options appear in correct color.

**DAY 2 --- Hidden Password Input and Main Loop**

**Step 2.1 --- Write hidden_input**

This procedure reads characters one at a time using ReadChar (Irvine). It prints \* for each character and stores the actual typed character in input_buffer.

hidden_input PROC\
PUSHAD\
mov edi, OFFSET input_buffer\
mov ecx, 0 ; character counter\
read_loop:\
call ReadChar ; reads one char into AL, no echo\
cmp al, 13 ; 13 = Enter key\
je done_input\
cmp ecx, 100 ; enforce 100 char limit\
jge read_loop\
mov \[edi\], al ; store real character\
inc edi\
inc ecx\
mov al, \'\*\'\
call WriteChar ; print \* on screen\
jmp read_loop\
done_input:\
mov BYTE PTR \[edi\], 0 ; null terminator\
call Crlf\
POPAD\
RET\
hidden_input ENDP

✅ Test: Call hidden_input, then WriteString input_buffer. You should see the actual text you typed (not stars).

**Step 2.2 --- Write main_loop**

This is the main menu loop. It shows the menu, reads a choice (1, 2, or 3), and uses CALL placeholders for now (Person 2 and 3 modules will replace them on Day 3).

main_loop PROC\
PUSHAD\
menu_start:\
call ClrScr\
call draw_menu\
mov edx, OFFSET prompt_choice ; \"Enter choice: \"\
call WriteString\
call ReadChar\
cmp al, \'1\'\
je do_store\
cmp al, \'2\'\
je do_view\
cmp al, \'3\'\
je do_logout\
jmp menu_start ; invalid input, loop again\
do_store:\
; PLACEHOLDER: call write_file_proc and encrypt_decrypt_proc\
mov edx, OFFSET msg_store ; \"Store selected (not connected yet)\"\
call WriteString\
call Crlf\
jmp menu_start\
do_view:\
; PLACEHOLDER: call read_file_proc and decrypt\
mov edx, OFFSET msg_view\
call WriteString\
call Crlf\
jmp menu_start\
do_logout:\
POPAD\
RET ; return to login screen\
main_loop ENDP\
\
print_success PROC\
PUSHAD\
mov eax, lightGreen + (black\*16)\
call SetTextColor\
mov edx, OFFSET msg_success ; \"\[ OK \] Operation Complete\"\
call WriteString\
call Crlf\
POPAD\
RET\
print_success ENDP\
\
print_error PROC\
PUSHAD\
mov eax, lightRed + (black\*16)\
call SetTextColor\
mov edx, OFFSET msg_error ; \"\[ERR\] Access Denied\"\
call WriteString\
call Crlf\
POPAD\
RET\
print_error ENDP

✅ Test: Run main_loop. Pressing 1, 2, or 3 should print a placeholder message. Pressing 3 exits. Any other key loops back.

**DAY 3 --- Integration (Person 1 Leads)**

1.  Create master.asm with INCLUDE Irvine32.inc and all shared .data variables.

2.  Paste your own procedures (draw_border, draw_menu, hidden_input, main_loop, print_success, print_error) into master.asm.

3.  Ask Person 2 to send crypto_procs.asm. Paste those procedures below yours.

4.  Ask Person 3 to send fileio_procs.asm. Paste those procedures below Person 2\'s.

5.  In main_loop, replace the do_store PLACEHOLDER with real calls: CALL read_input, CALL calculate_checksum, CALL encrypt_decrypt_proc, CALL write_file_proc.

6.  In main_loop, replace the do_view PLACEHOLDER with real calls: CALL read_file_proc, CALL encrypt_decrypt_proc (XOR is symmetric), CALL verify_checksum.

7.  At program start (before main_loop), connect the login: CALL draw_login, CALL check_password.

8.  Test after EACH step. Do NOT connect everything at once.

**Integration Test Checklist**

|                                   |                       |            |
|:---------------------------------:|:---------------------:|:----------:|
|             **Test**              |  **Expected Result**  | **Status** |
|    Login with correct password    |     Menu appears      | \[ \] Pass |
|   Login with wrong password x3    |     Program exits     | \[ \] Pass |
| Press 1 → type text → press Enter |   vault.txt created   | \[ \] Pass |
|  Press 2 → decrypted text shown   | Original text visible | \[ \] Pass |
|   Press 3 → goes back to login    |  Login prompt shown   | \[ \] Pass |
|      Wait 15 seconds on menu      | Auto-logout to login  | \[ \] Pass |

**PERSON 2 --- Security & Encryption Developer**

**File to work in: crypto_procs.asm**

Procedures to build: encrypt_decrypt_proc, calculate_checksum, check_password

**DAY 1 --- XOR Encryption Procedure**

**Step 1.1 --- Set Up Your File**

Create crypto_procs.asm with INCLUDE Irvine32.inc at the top. Copy the shared .data section for reference.

INCLUDE Irvine32.inc\
.data\
; (reference copy of shared variables)\
input_buffer BYTE 101 DUP(0)\
encrypted_buffer BYTE 101 DUP(0)\
xor_key BYTE 42\
checksum_val BYTE 0\
.code

✅ Test: File compiles without errors.

**Step 1.2 --- Understand XOR Encryption**

XOR encryption is simple: encrypt and decrypt use the exact same code. If you XOR a value with the key, you get ciphertext. XOR the ciphertext with the same key again and you get the original text back.

; \'H\' XOR 42 = some encrypted byte\
; (encrypted byte) XOR 42 = \'H\' \<\-- same operation, same key\
; So one procedure does BOTH encrypt AND decrypt.

**Step 1.3 --- Write encrypt_decrypt_proc**

This procedure reads from input_buffer, XORs each byte with xor_key, and stores the result in encrypted_buffer (when encrypting) OR input_buffer (when decrypting). Use ESI to point to the source, EDI to point to the destination, and ECX as the loop counter.

encrypt_decrypt_proc PROC\
PUSHAD\
mov esi, OFFSET input_buffer ; source: where text is\
mov edi, OFFSET encrypted_buffer ; destination: where to put result\
mov ecx, 100 ; max 100 characters\
xor_loop:\
mov al, \[esi\] ; load one byte\
cmp al, 0 ; stop at null terminator\
je xor_done\
xor al, xor_key ; XOR with the key\
mov \[edi\], al ; store in destination\
inc esi ; move source pointer forward\
inc edi ; move destination pointer forward\
loop xor_loop ; ECX\-- and repeat\
xor_done:\
mov BYTE PTR \[edi\], 0 ; null terminate the output\
POPAD\
RET\
encrypt_decrypt_proc ENDP

✅ Test: Manually place \'HELLO\' in input_buffer before calling the proc. After the call, print encrypted_buffer. You should see garbled text. Call the proc again with source=encrypted_buffer → destination=input_buffer. Print input_buffer. You should see \'HELLO\' again.

**DAY 2 --- Checksum and Password Check**

**Step 2.1 --- Write calculate_checksum**

The checksum is a simple integrity check. Add all the ASCII values of the characters in input_buffer together. Store the lowest byte of the result in checksum_val. When verifying, recalculate and compare.

calculate_checksum PROC\
PUSHAD\
mov esi, OFFSET input_buffer ; start of text\
mov eax, 0 ; accumulator (running total)\
mov ecx, 100 ; max iterations\
checksum_loop:\
movzx ebx, BYTE PTR \[esi\] ; load byte (zero-extended to 32-bit)\
cmp ebx, 0 ; stop at null terminator\
je checksum_done\
add eax, ebx ; add to total\
inc esi\
loop checksum_loop\
checksum_done:\
mov checksum_val, al ; store lowest byte as checksum\
POPAD\
RET\
calculate_checksum ENDP

✅ Test: Put \'HELLO\' in input_buffer. Call calculate_checksum. Print the value in checksum_val. Call again with the same input. Confirm the value is identical both times (it should be 329 mod 256 = 73).

**Step 2.2 --- Write check_password**

This procedure compares the user\'s input (in input_buffer) with master_pass byte by byte. On failure, it increments strike_count. At 3 failures, it exits the program. On success, it returns normally so the main program continues.

check_password PROC\
PUSHAD\
mov esi, OFFSET input_buffer ; user typed this\
mov edi, OFFSET master_pass ; correct password\
compare_loop:\
mov al, \[esi\]\
mov bl, \[edi\]\
cmp al, bl ; compare characters\
jne wrong_password\
cmp al, 0 ; both reached null at same time = match\
je correct_password\
inc esi\
inc edi\
jmp compare_loop\
wrong_password:\
inc strike_count\
cmp strike_count, 3\
jl password_fail_return ; less than 3 strikes: just return failure\
; 3 strikes: exit program\
mov edx, OFFSET msg_lockout ; \"\[!!!\] VAULT LOCKED. Exiting.\"\
call WriteString\
call Crlf\
invoke ExitProcess, 0 ; terminate immediately\
password_fail_return:\
; signal failure: set EAX = 0 (caller checks this)\
POPAD\
mov eax, 0\
RET\
correct_password:\
mov strike_count, 0 ; reset strikes on success\
POPAD\
mov eax, 1 ; signal success\
RET\
check_password ENDP

⚠️ Important: POPAD before RET restores EAX. To return a value in EAX, move it AFTER POPAD.

✅ Test 1: Type \'coal123\' in input_buffer. Call check_password. Confirm EAX = 1.

✅ Test 2: Type \'wrong\' in input_buffer. Call check_password three times. Confirm the program exits on the 3rd call.

**DAY 3 --- Hand Off and Support Integration**

9.  Send crypto_procs.asm to Person 1 (or share via USB / cloud).

10. Make sure all your procedures compile cleanly as a standalone file.

11. Be available to help Person 1 if a procedure does not connect correctly.

12. If Person 1 reports that the decrypt result is wrong, check: are they passing encrypted_buffer as source when decrypting? The proc reads from input_buffer by default --- Person 1 may need to copy encrypted_buffer into input_buffer before calling.

13. Final check: verify checksum before and after decryption produces the same value.

**Person 2 --- Self-Test Checklist**

|                                    |                         |           |
|:----------------------------------:|:-----------------------:|:---------:|
|              **Test**              |      **Expected**       | **Done?** |
| Encrypt \'HELLO\', decrypt result  |   Get \'HELLO\' back    |   \[ \]   |
| Checksum of \'HELLO\' called twice | Same number both times  |   \[ \]   |
|       Correct password → EAX       |         EAX = 1         |   \[ \]   |
|    Wrong password x3 → program     | Exits / lockout message |   \[ \]   |
|     PUSHAD/POPAD in every proc     | No register corruption  |   \[ \]   |

**PERSON 3 --- File I/O & Input Developer**

**File to work in: fileio_procs.asm**

Procedures to build: read_input, write_file_proc, read_file_proc, check_timeout_proc

**DAY 1 --- Input Reading and File Writing**

**Step 1.1 --- Set Up Your File**

Create fileio_procs.asm with INCLUDE Irvine32.inc at the top. Add the shared variables for reference.

INCLUDE Irvine32.inc\
.data\
filename BYTE \"vault.txt\", 0\
input_buffer BYTE 101 DUP(0)\
encrypted_buffer BYTE 101 DUP(0)\
checksum_val BYTE 0\
timer_start DWORD 0\
fileHandle DWORD 0 ; stores the open file handle\
bytes_written DWORD 0\
bytes_read DWORD 0\
.code

✅ Test: File compiles without errors.

**Step 1.2 --- Write read_input**

This procedure uses Irvine\'s ReadString to read a line of text from the user and stores it in input_buffer. It enforces a 100-character limit automatically because ReadString takes a max-length parameter.

read_input PROC\
PUSHAD\
mov edx, OFFSET input_buffer ; where to store the text\
mov ecx, 100 ; maximum number of characters to read\
call ReadString ; Irvine proc: reads line, stores in \[EDX\]\
; After ReadString, EAX = number of characters read\
; input_buffer now contains the user\'s text, null-terminated\
POPAD\
RET\
read_input ENDP

✅ Test: Call read_input, then call WriteString with OFFSET input_buffer. You should see exactly what you typed printed back on the screen.

✅ Test 2: Type exactly 100+ characters. Confirm only 100 are stored (no crash).

**Step 1.3 --- Write write_file_proc**

This procedure creates (or overwrites) vault.txt and writes two things: the checksum byte first, then the encrypted text from encrypted_buffer.

write_file_proc PROC\
PUSHAD\
; Step A: Create the file (overwrites if it already exists)\
mov edx, OFFSET filename\
call CreateOutputFile ; EAX = file handle\
cmp eax, INVALID_HANDLE_VALUE ; did it fail?\
je write_failed\
mov fileHandle, eax ; save handle\
\
; Step B: Write the checksum byte first\
mov eax, fileHandle\
mov edx, OFFSET checksum_val ; address of the byte\
mov ecx, 1 ; write 1 byte\
call WriteToFile\
\
; Step C: Write the encrypted text\
mov eax, fileHandle\
mov edx, OFFSET encrypted_buffer\
mov ecx, 100 ; write up to 100 bytes\
call WriteToFile\
\
; Step D: Close the file\
mov eax, fileHandle\
call CloseFile\
jmp write_done\
write_failed:\
mov edx, OFFSET msg_file_err ; \"\[ERR\] Cannot create vault.txt\"\
call WriteString\
call Crlf\
write_done:\
POPAD\
RET\
write_file_proc ENDP

✅ Test: Manually fill encrypted_buffer with \'TEST\' and set checksum_val = 99. Call write_file_proc. Open vault.txt in Notepad. The first byte should be a garbled character (value 99), followed by \'TEST\'.

**DAY 2 --- File Reading and Auto-Logout Timer**

**Step 2.1 --- Write read_file_proc**

This procedure opens vault.txt, reads the first byte into checksum_val, and reads the remaining bytes into encrypted_buffer.

read_file_proc PROC\
PUSHAD\
; Step A: Open the file\
mov edx, OFFSET filename\
call OpenInputFile ; EAX = file handle, or -1 if not found\
cmp eax, INVALID_HANDLE_VALUE\
je read_failed\
mov fileHandle, eax\
\
; Step B: Read the checksum byte\
mov eax, fileHandle\
mov edx, OFFSET checksum_val\
mov ecx, 1\
call ReadFromFile\
\
; Step C: Read the encrypted text\
mov eax, fileHandle\
mov edx, OFFSET encrypted_buffer\
mov ecx, 100\
call ReadFromFile\
mov bytes_read, eax ; save how many bytes were actually read\
\
; Step D: Close the file\
mov eax, fileHandle\
call CloseFile\
jmp read_done\
read_failed:\
mov edx, OFFSET msg_no_vault ; \"\[ERR\] No vault found. Store first.\"\
call WriteString\
call Crlf\
read_done:\
POPAD\
RET\
read_file_proc ENDP

✅ Test: Run write_file_proc first to create the file. Then run read_file_proc. Print encrypted_buffer --- it should match what you wrote.

**Step 2.2 --- Write check_timeout_proc**

This procedure uses Irvine\'s GetMseconds to check if 15 seconds (15000 milliseconds) have passed since the timer was last reset. If yes, it returns EAX = 1 (timeout). Otherwise EAX = 0.

; Call this ONCE at login to start the timer:\
; call GetMseconds\
; mov timer_start, eax\
\
check_timeout_proc PROC\
PUSHAD\
call GetMseconds ; EAX = current time in milliseconds\
sub eax, timer_start ; elapsed = now - start\
cmp eax, 15000 ; 15 seconds = 15000 ms\
jl no_timeout ; less than 15s? no timeout\
; Timeout occurred\
POPAD\
mov eax, 1 ; return 1 = TIMED OUT\
RET\
no_timeout:\
POPAD\
mov eax, 0 ; return 0 = still active\
RET\
check_timeout_proc ENDP\
\
; In main_loop (Person 1 adds this call at the top of menu_start):\
; call check_timeout_proc\
; cmp eax, 1\
; je do_logout

✅ Test: Set timer_start = 0 (a very old timestamp). Call check_timeout_proc. Confirm EAX = 1 (timed out). Then set timer_start to current time (call GetMseconds first). Call check_timeout_proc immediately. Confirm EAX = 0.

**DAY 3 --- Hand Off and Support Integration**

14. Send fileio_procs.asm to Person 1.

15. Make sure your file compiles cleanly as a standalone file first.

16. Tell Person 1 that timer_start must be set (call GetMseconds + store result) right after a successful login, and reset after every menu interaction.

17. Tell Person 1 to call check_timeout_proc at the TOP of the main menu loop, before showing the menu.

18. If Person 1 reports that read_file_proc returns wrong data, check: the checksum byte must be read FIRST (1 byte), then the encrypted text. Order matters.

**Person 3 --- Self-Test Checklist**

|                                           |                       |           |
|:-----------------------------------------:|:---------------------:|:---------:|
|                 **Test**                  |     **Expected**      | **Done?** |
| read_input → type \'HELLO\' → WriteString |   \'HELLO\' printed   |   \[ \]   |
|       read_input → type 100+ chars        |  No crash, truncated  |   \[ \]   |
|     write_file_proc → open vault.txt      | File exists with data |   \[ \]   |
|         write then read_file_proc         |     Data matches      |   \[ \]   |
|     read_file_proc with no vault.txt      |  Error message shown  |   \[ \]   |
|      check_timeout_proc after 15 sec      |        EAX = 1        |   \[ \]   |

**5. Common Pitfalls and How to Avoid Them**

These are the most frequent bugs in Assembly projects. Read this section before you start coding.

<table style="width:93%;">
<colgroup>
<col style="width: 3%" />
<col style="width: 89%" />
</colgroup>
<tbody>
<tr>
<td style="text-align: center;"><strong>BUG 1</strong></td>
<td><p><strong>Stack Corruption (Program crashes with random jump)</strong></p>
<p>Cause: You PUSH registers at the start of a procedure but forget to POP them before RET. The CPU then reads a garbage value as the return address and jumps to a random location.</p>
<p>Fix: Use PUSHAD at the start and POPAD before every RET. If you need to return a value in EAX, move it AFTER the POPAD.</p></td>
</tr>
</tbody>
</table>

<table style="width:93%;">
<colgroup>
<col style="width: 3%" />
<col style="width: 89%" />
</colgroup>
<tbody>
<tr>
<td style="text-align: center;"><strong>BUG 2</strong></td>
<td><p><strong>ECX Overwritten Inside a LOOP (Infinite loop or loop skipped)</strong></p>
<p>Cause: You use LOOP (which uses ECX as a counter) but inside the loop you call a procedure that also modifies ECX. After the call, ECX has a garbage value.</p>
<p>Fix: Every procedure uses PUSHAD/POPAD, so internal ECX changes are restored. But double-check: never set ECX inside a loop body directly unless intentional.</p></td>
</tr>
</tbody>
</table>

<table style="width:93%;">
<colgroup>
<col style="width: 3%" />
<col style="width: 89%" />
</colgroup>
<tbody>
<tr>
<td style="text-align: center;"><strong>BUG 3</strong></td>
<td><p><strong>XOR Decryption Gives Wrong Result</strong></p>
<p>Cause: During decryption, Person 1 calls encrypt_decrypt_proc but the source is still input_buffer (which is now empty), not encrypted_buffer.</p>
<p>Fix: Before calling encrypt_decrypt_proc for decryption, copy encrypted_buffer into input_buffer first, OR modify the procedure to accept source/destination via registers.</p></td>
</tr>
</tbody>
</table>

<table style="width:93%;">
<colgroup>
<col style="width: 3%" />
<col style="width: 89%" />
</colgroup>
<tbody>
<tr>
<td style="text-align: center;"><strong>BUG 4</strong></td>
<td><p><strong>File Handle Not Closed (Data not saved / file corruption)</strong></p>
<p>Cause: Person 3 opens vault.txt with CreateOutputFile but the program exits or crashes before CloseFile is called. Windows may not flush the buffer.</p>
<p>Fix: Always call CloseFile before RET in both write_file_proc and read_file_proc. Keep it as the last step before the label that jumps to RET.</p></td>
</tr>
</tbody>
</table>

<table style="width:93%;">
<colgroup>
<col style="width: 3%" />
<col style="width: 89%" />
</colgroup>
<tbody>
<tr>
<td style="text-align: center;"><strong>BUG 5</strong></td>
<td><p><strong>Null Terminator Missing (WriteString prints garbage)</strong></p>
<p>Cause: After XOR encryption, the loop stops at ECX = 0 but does not write a null byte (0) at the end of encrypted_buffer. WriteString then reads beyond the string.</p>
<p>Fix: After every string-building loop, add: mov BYTE PTR [edi], 0 to place the null terminator.</p></td>
</tr>
</tbody>
</table>

**6. Quick Reference Card**

Keep this page open while coding.

**Irvine32 Procedures Used in This Project**

|  |  |  |
|:--:|:--:|:--:|
| **Procedure** | **What It Does** | **Key Registers** |
| WriteString | Prints a null-terminated string | EDX = address of string |
| ReadString | Reads a line of input | EDX = buffer, ECX = max length, EAX = chars read |
| ReadChar | Reads one character (no echo) | AL = character read |
| WriteChar | Prints one character | AL = character to print |
| SetTextColor | Sets foreground + background color | EAX = color value |
| ClrScr | Clears the console screen | (no parameters) |
| Crlf | Prints a newline | (no parameters) |
| GetMseconds | Returns milliseconds since boot | EAX = time in ms |
| CreateOutputFile | Creates or overwrites a file | EDX = filename, EAX = handle |
| OpenInputFile | Opens existing file for reading | EDX = filename, EAX = handle or -1 |
| WriteToFile | Writes bytes to open file | EAX = handle, EDX = buffer, ECX = count |
| ReadFromFile | Reads bytes from open file | EAX = handle, EDX = buffer, ECX = count |
| CloseFile | Closes an open file handle | EAX = handle |

**Color Constants (Irvine32)**

; Text color values for SetTextColor\
; Usage: mov eax, FOREGROUND + (BACKGROUND \* 16)\
; Example: Yellow text on Black background = yellow + (black \* 16)\
\
black = 0\
blue = 1\
green = 2\
cyan = 3\
red = 4\
magenta = 5\
brown = 6\
lightGray = 7\
darkGray = 8\
lightBlue = 9\
lightGreen = 10\
lightCyan = 11\
lightRed = 12\
lightMagenta = 13\
yellow = 14\
white = 15

**3-Day Timeline Summary**

|  |  |  |  |
|:--:|:--:|:--:|:--:|
| **Day** | **Person 1** | **Person 2** | **Person 3** |
| **Day 1** | draw_border + draw_menu | encrypt_decrypt_proc | read_input + write_file_proc |
| **Day 2** | hidden_input + main_loop | calculate_checksum + check_password | read_file_proc + check_timeout_proc |
| **Day 3** | Integration (leads), master.asm | Hand off, support integration | Hand off, support integration |
