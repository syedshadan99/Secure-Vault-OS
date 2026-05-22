; ============================================================================
; SECURE VAULT OS - Security & Encryption Procedures
; Person 2: Security & Encryption Developer
; File: crypto_procs.asm
; ============================================================================
; Procedures to build:
;   - encrypt_decrypt_proc   (Day 1)
;   - calculate_checksum     (Day 2)
;   - check_password         (Day 2)
; ============================================================================
; IMPORTANT: Remove the .data section below when merging into master.asm.
;            These are REFERENCE COPIES only for standalone testing.
; ============================================================================

INCLUDE Irvine32.inc

; --- Reference copy of shared variables (REMOVE when merging into master.asm) ---
.data
    master_pass         BYTE "coal123", 0
    strike_count        BYTE 0
    input_buffer        BYTE 101 DUP(0)
    encrypted_buffer    BYTE 101 DUP(0)
    xor_key             BYTE 42
    checksum_val        BYTE 0
    filename            BYTE "vault.txt", 0
    fileHandle          DWORD 0
    bytes_written       DWORD 0
    bytes_read          DWORD 0
    timer_start         DWORD 0

    ; --- Messages needed for testing ---
    msg_lockout         BYTE "[!!!] VAULT LOCKED. Exiting.", 0
    msg_error           BYTE "[ERR] Access Denied", 0
    msg_success         BYTE "[ OK ] Operation Complete", 0
    msg_test_encrypt    BYTE "Testing encryption...", 0
    msg_test_checksum   BYTE "Testing checksum...", 0
    msg_test_password   BYTE "Testing password...", 0

.code

; ============================================================================
; PROCEDURE: encrypt_decrypt_proc
; Description: Reads from input_buffer, XORs each byte with xor_key, and
;              stores the result in encrypted_buffer.
;              XOR is symmetric: same procedure encrypts AND decrypts.
;              When decrypting, copy encrypted_buffer into input_buffer first,
;              then call this procedure.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; Day:         Day 1
; ============================================================================
encrypt_decrypt_proc PROC
    PUSHAD

    ; TODO: Implement encrypt_decrypt_proc
    ;
    ; Steps:
    ;   1. Set up pointers:
    ;      mov esi, OFFSET input_buffer       ; source
    ;      mov edi, OFFSET encrypted_buffer   ; destination
    ;      mov ecx, 100                       ; max 100 characters
    ;
    ;   2. xor_loop:
    ;      a. mov al, [esi]                   ; load one byte
    ;      b. cmp al, 0                       ; stop at null terminator
    ;         je xor_done
    ;      c. xor al, xor_key                 ; XOR with the key
    ;      d. mov [edi], al                   ; store in destination
    ;      e. inc esi                         ; move source pointer forward
    ;      f. inc edi                         ; move destination pointer forward
    ;      g. loop xor_loop                   ; ECX-- and repeat
    ;
    ;   3. xor_done:
    ;      mov BYTE PTR [edi], 0             ; null terminate the output

    POPAD
    RET
encrypt_decrypt_proc ENDP

; ============================================================================
; PROCEDURE: calculate_checksum
; Description: Adds all ASCII values of characters in input_buffer together.
;              Stores the lowest byte of the result in checksum_val.
;              Used for data integrity verification.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; Day:         Day 2
; ============================================================================
calculate_checksum PROC
    PUSHAD

    ; TODO: Implement calculate_checksum
    ;
    ; Steps:
    ;   1. Set up:
    ;      mov esi, OFFSET input_buffer   ; start of text
    ;      mov eax, 0                     ; accumulator (running total)
    ;      mov ecx, 100                   ; max iterations
    ;
    ;   2. checksum_loop:
    ;      a. movzx ebx, BYTE PTR [esi]   ; load byte (zero-extended)
    ;      b. cmp ebx, 0                  ; stop at null terminator
    ;         je checksum_done
    ;      c. add eax, ebx                ; add to total
    ;      d. inc esi
    ;      e. loop checksum_loop
    ;
    ;   3. checksum_done:
    ;      mov checksum_val, al           ; store lowest byte as checksum
    ;
    ; Expected: 'HELLO' checksum = (72+69+76+76+79) mod 256 = 372 mod 256 = 116

    POPAD
    RET
calculate_checksum ENDP

; ============================================================================
; PROCEDURE: check_password
; Description: Compares user input (in input_buffer) with master_pass byte by
;              byte. On failure, increments strike_count. At 3 failures, exits
;              the program with lockout message. On success, returns EAX = 1.
; Returns:     EAX = 1 (correct password) or EAX = 0 (wrong password)
; IMPORTANT:   POPAD before RET restores EAX. To return a value in EAX,
;              move it AFTER POPAD.
; Registers:   Uses PUSHAD/POPAD (EAX set after POPAD for return value)
; Day:         Day 2
; ============================================================================
check_password PROC
    PUSHAD

    ; TODO: Implement check_password
    ;
    ; Steps:
    ;   1. Set up pointers:
    ;      mov esi, OFFSET input_buffer   ; user typed this
    ;      mov edi, OFFSET master_pass    ; correct password
    ;
    ;   2. compare_loop:
    ;      a. mov al, [esi]
    ;      b. mov bl, [edi]
    ;      c. cmp al, bl                  ; compare characters
    ;         jne wrong_password
    ;      d. cmp al, 0                   ; both reached null = match
    ;         je correct_password
    ;      e. inc esi
    ;      f. inc edi
    ;      g. jmp compare_loop
    ;
    ;   3. wrong_password:
    ;      a. inc strike_count
    ;      b. cmp strike_count, 3
    ;         jl password_fail_return     ; less than 3 strikes
    ;      c. ; 3 strikes: exit program
    ;         mov edx, OFFSET msg_lockout
    ;         call WriteString
    ;         call Crlf
    ;         invoke ExitProcess, 0       ; terminate immediately
    ;
    ;   4. password_fail_return:
    ;      POPAD
    ;      mov eax, 0                     ; signal failure
    ;      RET
    ;
    ;   5. correct_password:
    ;      mov strike_count, 0            ; reset strikes on success
    ;      POPAD
    ;      mov eax, 1                     ; signal success
    ;      RET

    POPAD
    mov eax, 0      ; default: failure (replace with full implementation)
    RET
check_password ENDP

; ============================================================================
; Temporary main for standalone testing (REMOVE when merging into master.asm)
; ============================================================================
main PROC
    ; --- Test your procedures here ---
    ;
    ; Test 1: Encrypt/Decrypt
    ;   Manually place 'HELLO' in input_buffer:
    ;     mov input_buffer, 'H'
    ;     mov input_buffer+1, 'E'
    ;     mov input_buffer+2, 'L'
    ;     mov input_buffer+3, 'L'
    ;     mov input_buffer+4, 'O'
    ;     mov input_buffer+5, 0
    ;   call encrypt_decrypt_proc
    ;   ; Print encrypted_buffer (should be garbled)
    ;   ; Then swap buffers and call again to decrypt
    ;
    ; Test 2: Checksum
    ;   call calculate_checksum
    ;   ; Print checksum_val (should be 116 for 'HELLO')
    ;
    ; Test 3: Password
    ;   ; Type 'coal123' into input_buffer
    ;   call check_password
    ;   ; EAX should be 1

    invoke ExitProcess, 0
main ENDP

END main
