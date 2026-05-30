; ============================================================================
; SECURE VAULT OS - Master Assembly File
; Secure Text Storage System with Attack Prevention
; ============================================================================
; COAL Semester Project | Spring 2026 | 8086 Assembly Language (MASM + Irvine32)
; ============================================================================
; This is the FINAL integration file (Day 3). All procedures from
; ui_procs.asm, crypto_procs.asm, and fileio_procs.asm are merged here.
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
; draw_border, draw_menu, hidden_input, main_loop, print_success, print_error
; ============================================================================

; ============================================================================
; PROCEDURE: draw_border
; Description: Draws a yellow box border around the screen using box-drawing
;              characters. Uses SetTextColor (Irvine) for yellow text.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
draw_border PROC
    PUSHAD

    ; Set text color to yellow on black
    mov eax, yellow + (black * 16)
    call SetTextColor

    ; Print top border
    mov edx, OFFSET border_top
    call WriteString
    call Crlf

    ; Print side border with title
    mov edx, OFFSET border_side
    call WriteString
    mov edx, OFFSET title_str
    call WriteString
    mov eax, yellow + (black * 16)
    call SetTextColor
    mov edx, OFFSET border_side
    call WriteString
    call Crlf

    ; Print bottom border
    mov edx, OFFSET border_bot
    call WriteString
    call Crlf

    POPAD
    RET
draw_border ENDP

; ============================================================================
; PROCEDURE: draw_menu
; Description: Prints the 3 menu options in light blue text inside the border.
;              Calls draw_border first, then displays menu options.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
draw_menu PROC
    PUSHAD

    ; Call draw_border first
    call draw_border

    ; Set color to light blue on black
    mov eax, lightBlue + (black * 16)
    call SetTextColor

    ; Print menu option 1
    mov edx, OFFSET menu_opt1
    call WriteString
    call Crlf

    ; Print menu option 2
    mov edx, OFFSET menu_opt2
    call WriteString
    call Crlf

    ; Print menu option 3
    mov edx, OFFSET menu_opt3
    call WriteString
    call Crlf
    call Crlf

    POPAD
    RET
draw_menu ENDP

; ============================================================================
; PROCEDURE: hidden_input
; Description: Reads characters one at a time using ReadChar (no echo).
;              Prints '*' for each character typed. Stores actual characters
;              in input_buffer. Enter key (ASCII 13) ends input.
;              Backspace key (ASCII 8) deletes last character.
;              Enforces 100 character limit.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
hidden_input PROC
    PUSHAD

    mov edi, OFFSET input_buffer
    mov ecx, 0                     ; character counter

    read_loop:
        call ReadChar              ; reads one char into AL, no echo
        cmp al, 13                 ; 13 = Enter key
        je done_input
        cmp al, 8                  ; 8 = Backspace key
        je do_backspace
        cmp ecx, 100              ; enforce 100 char limit
        jge read_loop
        mov [edi], al             ; store real character
        inc edi
        inc ecx
        mov al, '*'
        call WriteChar            ; print * on screen
        jmp read_loop

    do_backspace:
        cmp ecx, 0               ; nothing to delete?
        je read_loop
        dec edi
        dec ecx
        mov BYTE PTR [edi], 0    ; clear the character
        ; Erase the * on screen: print backspace, space, backspace
        mov al, 8
        call WriteChar
        mov al, ' '
        call WriteChar
        mov al, 8
        call WriteChar
        jmp read_loop

    done_input:
        mov BYTE PTR [edi], 0    ; null terminator
        call Crlf

    POPAD
    RET
hidden_input ENDP

; ============================================================================
; PROCEDURE: main_loop
; Description: Main menu loop. Shows menu, reads choice (1, 2, or 3).
;              Integrates Person 2 (crypto) and Person 3 (file I/O) procedures.
;              Includes auto-logout timeout check at top of loop.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
main_loop PROC
    PUSHAD

    menu_start:
        ; --- Timeout check ---
        call check_timeout_proc
        cmp eax, 1
        je do_timeout

        call ClrScr
        call draw_menu

        ; Set color to white for prompt
        mov eax, white + (black * 16)
        call SetTextColor

        mov edx, OFFSET prompt_choice
        call WriteString
        call ReadChar

        cmp al, '1'
        je do_store
        cmp al, '2'
        je do_view
        cmp al, '3'
        je do_logout
        jmp menu_start              ; invalid input, loop again

    do_store:
        call ClrScr
        call draw_border

        ; Prompt user for secret message
        mov eax, lightCyan + (black * 16)
        call SetTextColor
        mov edx, OFFSET prompt_input
        call WriteString

        ; Read user's secret message
        mov eax, white + (black * 16)
        call SetTextColor
        call read_input

        ; Calculate checksum BEFORE encryption (on plaintext)
        call calculate_checksum

        ; Encrypt: input_buffer -> encrypted_buffer
        call encrypt_decrypt_proc

        ; Write checksum + encrypted data to vault.txt
        call write_file_proc

        ; Show success message
        call Crlf
        call print_success
        mov eax, lightGreen + (black * 16)
        call SetTextColor
        mov edx, OFFSET msg_stored_ok
        call WriteString
        call Crlf

        ; Reset timer after interaction
        call GetMseconds
        mov timer_start, eax

        ; Pause so user can read the message
        mov eax, 2000
        call Delay
        jmp menu_start

    do_view:
        call ClrScr
        call draw_border

        ; Read encrypted data + checksum from vault.txt
        call read_file_proc

        ; Save the stored checksum before decryption
        movzx eax, checksum_val
        push eax

        ; To decrypt: copy encrypted_buffer into input_buffer first
        ; (XOR is symmetric: encrypt_decrypt_proc reads from input_buffer)
        mov esi, OFFSET encrypted_buffer
        mov edi, OFFSET input_buffer
        mov ecx, 101
        rep movsb

        ; Decrypt: input_buffer -> encrypted_buffer
        call encrypt_decrypt_proc

        ; The decrypted text is now in encrypted_buffer
        ; Display decrypted message
        mov eax, lightCyan + (black * 16)
        call SetTextColor
        mov edx, OFFSET msg_decrypted
        call WriteString
        mov eax, white + (black * 16)
        call SetTextColor
        mov edx, OFFSET encrypted_buffer
        call WriteString
        call Crlf

        ; Verify checksum: copy decrypted text back to input_buffer for checksum
        mov esi, OFFSET encrypted_buffer
        mov edi, OFFSET input_buffer
        mov ecx, 101
        rep movsb

        ; Recalculate checksum on decrypted text
        pop eax                        ; restore stored checksum
        push eax                       ; keep it on stack
        call calculate_checksum

        ; Compare stored checksum with recalculated checksum
        pop eax                        ; EAX = stored checksum (low byte)
        movzx ebx, checksum_val        ; EBX = recalculated checksum
        cmp al, bl
        jne checksum_mismatch

        ; Checksum matches
        mov eax, lightGreen + (black * 16)
        call SetTextColor
        mov edx, OFFSET msg_checksum_ok
        call WriteString
        call Crlf
        jmp view_done

    checksum_mismatch:
        ; Checksum does not match
        mov eax, lightRed + (black * 16)
        call SetTextColor
        mov edx, OFFSET msg_checksum_fail
        call WriteString
        call Crlf

    view_done:
        ; Reset timer after interaction
        call GetMseconds
        mov timer_start, eax

        ; Pause so user can read
        mov eax, 3000
        call Delay
        jmp menu_start

    do_timeout:
        ; Display timeout message
        call ClrScr
        mov eax, lightRed + (black * 16)
        call SetTextColor
        mov edx, OFFSET msg_timeout
        call WriteString
        call Crlf
        mov eax, 2000
        call Delay
        ; Fall through to logout

    do_logout:
        POPAD
        RET                         ; return to login screen

main_loop ENDP

; ============================================================================
; PROCEDURE: print_success
; Description: Prints a success message in light green text.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
print_success PROC
    PUSHAD

    ; Set color to lightGreen on black
    mov eax, lightGreen + (black * 16)
    call SetTextColor

    ; Print msg_success
    mov edx, OFFSET msg_success
    call WriteString
    call Crlf

    POPAD
    RET
print_success ENDP

; ============================================================================
; PROCEDURE: print_error
; Description: Prints an error message in light red text.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
print_error PROC
    PUSHAD

    ; Set color to lightRed on black
    mov eax, lightRed + (black * 16)
    call SetTextColor

    ; Print msg_error
    mov edx, OFFSET msg_error
    call WriteString
    call Crlf

    POPAD
    RET
print_error ENDP

; ============================================================================
; PERSON 2 PROCEDURES (from crypto_procs.asm)
; encrypt_decrypt_proc, calculate_checksum, check_password
; ============================================================================

; ============================================================================
; PROCEDURE: encrypt_decrypt_proc
; Description: Reads from input_buffer, XORs each byte with xor_key, and
;              stores the result in encrypted_buffer.
;              XOR is symmetric: same procedure encrypts AND decrypts.
;              When decrypting, copy encrypted_buffer into input_buffer first,
;              then call this procedure.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
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
; PERSON 3 PROCEDURES (from fileio_procs.asm)
; read_input, write_file_proc, read_file_proc, check_timeout_proc
; ============================================================================

; ============================================================================
; PROCEDURE: read_input
; Description: Uses Irvine's ReadString to read a line of text from the user.
;              Stores it in input_buffer. Enforces 100-character limit
;              automatically via ReadString's max-length parameter.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
read_input PROC
    PUSHAD

    mov edx, OFFSET input_buffer   ; where to store the text
    mov ecx, 100                   ; maximum number of characters to read
    call ReadString                ; Irvine proc: reads line, stores in [EDX]
    ; After ReadString:
    ; EAX = number of characters actually read
    ; input_buffer now contains the user's text, null-terminated

    POPAD
    RET
read_input ENDP

; ============================================================================
; PROCEDURE: write_file_proc
; Description: Creates (or overwrites) vault.txt and writes two things:
;              1. The checksum byte (1 byte) FIRST
;              2. The encrypted text from encrypted_buffer
;              Uses Irvine's CreateOutputFile, WriteToFile, CloseFile.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
write_file_proc PROC
    PUSHAD

    ; Step A: Create the file (overwrites if it already exists)
    mov edx, OFFSET filename
    call CreateOutputFile           ; EAX = file handle
    cmp eax, INVALID_HANDLE_VALUE   ; did it fail?
    je write_failed
    mov fileHandle, eax             ; save handle

    ; Step B: Write the checksum byte first
    mov eax, fileHandle
    mov edx, OFFSET checksum_val    ; address of the byte
    mov ecx, 1                      ; write 1 byte
    call WriteToFile

    ; Step C: Write the encrypted text
    mov eax, fileHandle
    mov edx, OFFSET encrypted_buffer
    mov ecx, 100                    ; write up to 100 bytes
    call WriteToFile

    ; Step D: Close the file
    mov eax, fileHandle
    call CloseFile
    jmp write_done

    write_failed:
        mov edx, OFFSET msg_file_err   ; "[ERR] Cannot create vault.txt"
        call WriteString
        call Crlf

    write_done:
    POPAD
    RET
write_file_proc ENDP

; ============================================================================
; PROCEDURE: read_file_proc
; Description: Opens vault.txt, reads the first byte into checksum_val,
;              and reads the remaining bytes into encrypted_buffer.
;              Uses Irvine's OpenInputFile, ReadFromFile, CloseFile.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; ============================================================================
read_file_proc PROC
    PUSHAD

    ; Step A: Open the file
    mov edx, OFFSET filename
    call OpenInputFile              ; EAX = file handle, or -1 if not found
    cmp eax, INVALID_HANDLE_VALUE
    je read_failed
    mov fileHandle, eax

    ; Step B: Read the checksum byte FIRST
    mov eax, fileHandle
    mov edx, OFFSET checksum_val
    mov ecx, 1
    call ReadFromFile

    ; Step C: Read the encrypted text
    mov eax, fileHandle
    mov edx, OFFSET encrypted_buffer
    mov ecx, 100
    call ReadFromFile
    mov bytes_read, eax             ; save how many bytes were actually read

    ; Step D: Null-terminate encrypted_buffer based on bytes actually read
    mov edi, OFFSET encrypted_buffer
    add edi, eax                    ; move to position after last byte read
    mov BYTE PTR [edi], 0           ; null terminate

    ; Step E: Close the file
    mov eax, fileHandle
    call CloseFile
    jmp read_done

    read_failed:
        mov edx, OFFSET msg_no_vault   ; "[ERR] No vault found. Store first."
        call WriteString
        call Crlf

    read_done:
    POPAD
    RET
read_file_proc ENDP

; ============================================================================
; PROCEDURE: check_timeout_proc
; Description: Uses Irvine's GetMseconds to check if 15 seconds (15000 ms)
;              have passed since timer_start was last set. Returns EAX = 1
;              if timed out, EAX = 0 if still active.
; Returns:     EAX = 1 (timed out) or EAX = 0 (still active)
; IMPORTANT:   POPAD before RET restores EAX. To return a value in EAX,
;              move it AFTER POPAD.
; Registers:   Uses PUSHAD/POPAD (EAX set after POPAD for return value)
; ============================================================================
check_timeout_proc PROC
    PUSHAD

    call GetMseconds               ; EAX = current time in milliseconds
    sub eax, timer_start           ; elapsed = now - start
    cmp eax, 15000                 ; 15 seconds = 15000 ms
    jl no_timeout                  ; less than 15s? no timeout

    ; Timeout occurred
    POPAD
    mov eax, 1                     ; return 1 = TIMED OUT
    RET

    no_timeout:
    POPAD
    mov eax, 0                     ; return 0 = still active
    RET
check_timeout_proc ENDP

; ============================================================================
END main
