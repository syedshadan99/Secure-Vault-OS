; ============================================================================
; SECURE VAULT OS - Master Assembly File
; Secure Text Storage System with Attack Prevention
; ============================================================================
; COAL Semester Project | Spring 2026 | 8086 Assembly Language (MASM + Irvine32)
; ============================================================================
; This is the FINAL integration file. On Day 3, Person 1 will paste all
; procedures from ui_procs.asm, crypto_procs.asm, and fileio_procs.asm here.
; ============================================================================

INCLUDE Irvine32.inc

; ============================================================================
; SHARED .data SECTION
; All global variables are defined ONCE here. Every member must use these
; exact variable names in their own procedures. DO NOT redefine them.
; ============================================================================
.data

    ; --- Authentication ---
    master_pass         BYTE "coal123", 0           ; hardcoded password
    strike_count        BYTE 0                      ; wrong password counter

    ; --- Buffers ---
    input_buffer        BYTE 101 DUP(0)             ; 100 chars + null terminator
    encrypted_buffer    BYTE 101 DUP(0)             ; holds XOR-encrypted text

    ; --- Encryption ---
    xor_key             BYTE 42                     ; the encryption key
    checksum_val        BYTE 0                      ; holds the calculated checksum

    ; --- File I/O ---
    filename            BYTE "vault.txt", 0         ; file name for vault storage
    fileHandle          DWORD 0                     ; stores the open file handle
    bytes_written       DWORD 0                     ; bytes written to file
    bytes_read          DWORD 0                     ; bytes read from file

    ; --- Timer ---
    timer_start         DWORD 0                     ; holds the timestamp for auto-logout

    ; --- UI Strings (Person 1) ---
    border_top          BYTE 201, 30 DUP(205), 187, 0   ; top border
    border_side         BYTE 186, 0                      ; side border
    border_bot          BYTE 200, 30 DUP(205), 188, 0   ; bottom border
    title_str           BYTE "     SECURE VAULT OS     ", 0
    menu_opt1           BYTE "  [1] Store Secret", 0
    menu_opt2           BYTE "  [2] View Secret", 0
    menu_opt3           BYTE "  [3] Logout", 0
    prompt_choice       BYTE "Enter choice: ", 0
    prompt_password     BYTE "Enter Password: ", 0
    prompt_input        BYTE "Enter secret message: ", 0

    ; --- Status Messages ---
    msg_store           BYTE "Store selected (not connected yet)", 0
    msg_view            BYTE "View selected (not connected yet)", 0
    msg_success         BYTE "[ OK ] Operation Complete", 0
    msg_error           BYTE "[ERR] Access Denied", 0
    msg_lockout         BYTE "[!!!] VAULT LOCKED. Exiting.", 0
    msg_file_err        BYTE "[ERR] Cannot create vault.txt", 0
    msg_no_vault        BYTE "[ERR] No vault found. Store first.", 0
    msg_welcome         BYTE "Welcome to Secure Vault OS", 0
    msg_login_fail      BYTE "[ERR] Wrong password!", 0
    msg_timeout         BYTE "[!!!] Session timed out. Auto-logout.", 0
    msg_checksum_ok     BYTE "[ OK ] Checksum verified.", 0
    msg_checksum_fail   BYTE "[ERR] Checksum mismatch! Data may be corrupted.", 0
    msg_stored_ok       BYTE "[ OK ] Secret stored successfully.", 0
    msg_decrypted       BYTE "Decrypted message: ", 0

; ============================================================================
; BUFFER OWNERSHIP RULES (DO NOT VIOLATE):
;   input_buffer     -> ONLY Person 3 (read_input) writes here
;   encrypted_buffer -> ONLY Person 2 (encrypt_decrypt_proc) writes here
;   checksum_val     -> ONLY Person 2 (calculate_checksum) writes here
;   timer_start      -> ONLY Person 3 (check_timeout_proc) writes here
; ============================================================================

.code

; ============================================================================
; MAIN ENTRY POINT
; ============================================================================
main PROC

    ; --- Initialize timer ---
    call GetMseconds
    mov timer_start, eax

    ; --- Login Screen ---
    login_screen:
        call ClrScr
        call draw_border

        ; Display welcome message
        mov eax, lightCyan + (black * 16)
        call SetTextColor
        mov edx, OFFSET msg_welcome
        call WriteString
        call Crlf
        call Crlf

        ; Prompt for password
        mov eax, white + (black * 16)
        call SetTextColor
        mov edx, OFFSET prompt_password
        call WriteString

        ; Read password with hidden input
        call hidden_input

        ; Check password
        call check_password
        cmp eax, 1
        je login_success

        ; Wrong password
        call print_error
        mov edx, OFFSET msg_login_fail
        call WriteString
        call Crlf

        ; Small delay so user can read the error
        mov eax, 1500
        call Delay

        jmp login_screen

    login_success:
        ; Reset timer after successful login
        call GetMseconds
        mov timer_start, eax

        ; Enter main menu loop
        call main_loop

        ; main_loop returns when user logs out or times out
        jmp login_screen

    invoke ExitProcess, 0

main ENDP

; ============================================================================
; PERSON 1 PROCEDURES (from ui_procs.asm)
; Paste draw_border, draw_menu, hidden_input, main_loop,
; print_success, print_error here on Day 3.
; ============================================================================

; >>> PERSON 1: PASTE YOUR PROCEDURES BELOW THIS LINE <<<



; >>> PERSON 1: END OF YOUR PROCEDURES <<<

; ============================================================================
; PERSON 2 PROCEDURES (from crypto_procs.asm)
; Paste encrypt_decrypt_proc, calculate_checksum, check_password here on Day 3.
; ============================================================================

; >>> PERSON 2: PASTE YOUR PROCEDURES BELOW THIS LINE <<<



; >>> PERSON 2: END OF YOUR PROCEDURES <<<

; ============================================================================
; PERSON 3 PROCEDURES (from fileio_procs.asm)
; Paste read_input, write_file_proc, read_file_proc,
; check_timeout_proc here on Day 3.
; ============================================================================

; >>> PERSON 3: PASTE YOUR PROCEDURES BELOW THIS LINE <<<



; >>> PERSON 3: END OF YOUR PROCEDURES <<<

; ============================================================================
END main
