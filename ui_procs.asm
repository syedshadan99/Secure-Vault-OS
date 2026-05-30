; ============================================================================
; SECURE VAULT OS - UI & Main Loop Procedures
; Person 1: UI & Main Loop Developer
; File: ui_procs.asm
; ============================================================================
; Procedures to build:
;   - draw_border       (Day 1)
;   - draw_menu         (Day 1)
;   - hidden_input      (Day 2)
;   - main_loop         (Day 2)
;   - print_success     (Day 2)
;   - print_error       (Day 2)
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

    ; --- UI Strings ---
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

.code

; ============================================================================
; PROCEDURE: draw_border
; Description: Draws a yellow box border around the screen using box-drawing
;              characters. Uses SetTextColor (Irvine) for yellow text.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; Day:         Day 1
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
; Day:         Day 1
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
; Day:         Day 2
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
; Day:         Day 2 (Integration on Day 3)
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
; Day:         Day 2
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
; Day:         Day 2
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
; Temporary main for standalone testing (REMOVE when merging into master.asm)
; ============================================================================
main PROC
    ; --- Test your procedures here ---
    ; Example:
    ;   call draw_border
    ;   call draw_menu

    invoke ExitProcess, 0
main ENDP

END main
