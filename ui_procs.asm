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

    ; TODO: Implement draw_border
    ;
    ; Steps:
    ;   1. Set text color to yellow on black:
    ;      mov eax, yellow + (black * 16)
    ;      call SetTextColor
    ;
    ;   2. Print border_top string
    ;      mov edx, OFFSET border_top
    ;      call WriteString
    ;      call Crlf
    ;
    ;   3. Print side borders with title
    ;      (print border_side, then title_str, then border_side)
    ;
    ;   4. Print border_bot string
    ;      mov edx, OFFSET border_bot
    ;      call WriteString
    ;      call Crlf

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

    ; TODO: Implement draw_menu
    ;
    ; Steps:
    ;   1. Call draw_border first
    ;      call draw_border
    ;
    ;   2. Set color to light blue on black:
    ;      mov eax, lightBlue + (black * 16)
    ;      call SetTextColor
    ;
    ;   3. Print menu_opt1, menu_opt2, menu_opt3 each followed by Crlf

    POPAD
    RET
draw_menu ENDP

; ============================================================================
; PROCEDURE: hidden_input
; Description: Reads characters one at a time using ReadChar (no echo).
;              Prints '*' for each character typed. Stores actual characters
;              in input_buffer. Enter key (ASCII 13) ends input.
;              Enforces 100 character limit.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; Day:         Day 2
; ============================================================================
hidden_input PROC
    PUSHAD

    ; TODO: Implement hidden_input
    ;
    ; Steps:
    ;   1. Set EDI to OFFSET input_buffer
    ;   2. Set ECX = 0 (character counter)
    ;   3. read_loop:
    ;      a. call ReadChar (result in AL)
    ;      b. cmp al, 13 -> je done_input (Enter pressed)
    ;      c. cmp ecx, 100 -> jge read_loop (limit reached)
    ;      d. mov [edi], al (store real character)
    ;      e. inc edi, inc ecx
    ;      f. mov al, '*' -> call WriteChar (print asterisk)
    ;      g. jmp read_loop
    ;   4. done_input:
    ;      mov BYTE PTR [edi], 0 (null terminate)
    ;      call Crlf

    POPAD
    RET
hidden_input ENDP

; ============================================================================
; PROCEDURE: main_loop
; Description: Main menu loop. Shows menu, reads choice (1, 2, or 3).
;              Currently uses PLACEHOLDER calls for Person 2 and 3 modules.
;              On Day 3, replace placeholders with real procedure calls.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; Day:         Day 2
; ============================================================================
main_loop PROC
    PUSHAD

    menu_start:
        ; TODO: Add timeout check here on Day 3
        ; call check_timeout_proc
        ; cmp eax, 1
        ; je do_logout

        call ClrScr
        call draw_menu

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
        ; PLACEHOLDER: On Day 3, replace with:
        ;   call read_input
        ;   call calculate_checksum
        ;   call encrypt_decrypt_proc
        ;   call write_file_proc
        mov edx, OFFSET msg_store
        call WriteString
        call Crlf

        ; Reset timer after interaction
        call GetMseconds
        mov timer_start, eax

        ; Pause so user can read the message
        mov eax, 1500
        call Delay
        jmp menu_start

    do_view:
        ; PLACEHOLDER: On Day 3, replace with:
        ;   call read_file_proc
        ;   call encrypt_decrypt_proc  (XOR is symmetric - decrypts too)
        ;   call verify_checksum
        mov edx, OFFSET msg_view
        call WriteString
        call Crlf

        ; Reset timer after interaction
        call GetMseconds
        mov timer_start, eax

        ; Pause so user can read the message
        mov eax, 1500
        call Delay
        jmp menu_start

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

    ; TODO: Implement print_success
    ;
    ; Steps:
    ;   1. Set color to lightGreen on black
    ;      mov eax, lightGreen + (black * 16)
    ;      call SetTextColor
    ;   2. Print msg_success
    ;      mov edx, OFFSET msg_success
    ;      call WriteString
    ;      call Crlf

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

    ; TODO: Implement print_error
    ;
    ; Steps:
    ;   1. Set color to lightRed on black
    ;      mov eax, lightRed + (black * 16)
    ;      call SetTextColor
    ;   2. Print msg_error
    ;      mov edx, OFFSET msg_error
    ;      call WriteString
    ;      call Crlf

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
