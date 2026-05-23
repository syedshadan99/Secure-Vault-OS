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
    mov esi, OFFSET input_buffer       ; source: where text is
    mov edi, OFFSET encrypted_buffer   ; destination: where to put result
    mov ecx, 100                       ; max 100 characters
    xor_loop:
        mov al, [esi]                  ; load one byte
        cmp al, 0                      ; stop at null terminator
        je xor_done
        xor al, xor_key                ; XOR with the key
        mov [edi], al                  ; store in destination
        inc esi                        ; move source pointer forward
        inc edi                        ; move destination pointer forward
        loop xor_loop                  ; ECX-- and repeat
    xor_done:
        mov BYTE PTR [edi], 0          ; null terminate the output
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
    mov esi, OFFSET input_buffer       ; start of text
    mov eax, 0                         ; accumulator (running total)
    mov ecx, 100                       ; max iterations
    checksum_loop:
        movzx ebx, BYTE PTR [esi]      ; load byte (zero-extended to 32-bit)
        cmp ebx, 0                     ; stop at null terminator
        je checksum_done
        add eax, ebx                   ; add to total
        inc esi
        loop checksum_loop
    checksum_done:
        mov checksum_val, al           ; store lowest byte as checksum
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
    mov esi, OFFSET input_buffer       ; user typed this
    mov edi, OFFSET master_pass        ; correct password
    compare_loop:
        mov al, [esi]
        mov bl, [edi]
        cmp al, bl                     ; compare characters
        jne wrong_password
        cmp al, 0                      ; both reached null at same time = match
        je correct_password
        inc esi
        inc edi
        jmp compare_loop
    wrong_password:
        inc strike_count
        cmp strike_count, 3
        jl password_fail_return         ; less than 3 strikes: just return failure
        ; 3 strikes: exit program
        mov edx, OFFSET msg_lockout    ; "[!!!] VAULT LOCKED. Exiting."
        call WriteString
        call Crlf
        invoke ExitProcess, 0           ; terminate immediately
    password_fail_return:
        ; signal failure: set EAX = 0 (caller checks this)
        POPAD
        mov eax, 0
        RET
    correct_password:
        mov strike_count, 0             ; reset strikes on success
        POPAD
        mov eax, 1                      ; signal success
        RET
check_password ENDP

; ============================================================================
; Temporary main for standalone testing (REMOVE when merging into master.asm)
; ============================================================================
main PROC

    ; ==================================================================
    ; TEST 1: Encrypt 'HELLO', then decrypt and verify
    ; ==================================================================
    mov edx, OFFSET msg_test_encrypt
    call WriteString
    call Crlf

    ; Manually place 'HELLO' in input_buffer
    mov input_buffer, 'H'
    mov input_buffer+1, 'E'
    mov input_buffer+2, 'L'
    mov input_buffer+3, 'L'
    mov input_buffer+4, 'O'
    mov input_buffer+5, 0

    ; Encrypt: input_buffer -> encrypted_buffer
    call encrypt_decrypt_proc

    ; Print encrypted text (should be garbled)
    mov edx, OFFSET encrypted_buffer
    call WriteString
    call Crlf

    ; To decrypt: copy encrypted_buffer into input_buffer, then call again
    mov esi, OFFSET encrypted_buffer
    mov edi, OFFSET input_buffer
    mov ecx, 101
    rep movsb

    ; Decrypt: input_buffer -> encrypted_buffer
    call encrypt_decrypt_proc

    ; Print decrypted text (should show 'HELLO')
    mov edx, OFFSET encrypted_buffer
    call WriteString
    call Crlf
    call Crlf

    ; ==================================================================
    ; TEST 2: Checksum of 'HELLO'
    ; ==================================================================
    mov edx, OFFSET msg_test_checksum
    call WriteString
    call Crlf

    ; Put 'HELLO' back in input_buffer for checksum
    mov input_buffer, 'H'
    mov input_buffer+1, 'E'
    mov input_buffer+2, 'L'
    mov input_buffer+3, 'L'
    mov input_buffer+4, 'O'
    mov input_buffer+5, 0

    call calculate_checksum

    ; Print checksum value
    movzx eax, checksum_val
    call WriteDec
    call Crlf
    call Crlf

    ; ==================================================================
    ; TEST 3: Correct password check (coal123)
    ; ==================================================================
    mov edx, OFFSET msg_test_password
    call WriteString
    call Crlf

    ; Place 'coal123' in input_buffer
    mov input_buffer, 'c'
    mov input_buffer+1, 'o'
    mov input_buffer+2, 'a'
    mov input_buffer+3, 'l'
    mov input_buffer+4, '1'
    mov input_buffer+5, '2'
    mov input_buffer+6, '3'
    mov input_buffer+7, 0

    call check_password
    ; EAX should be 1 (correct password)
    call WriteDec
    call Crlf

    invoke ExitProcess, 0
main ENDP

END main
