; ============================================================================
; SECURE VAULT OS - File I/O & Input Procedures
; Person 3: File I/O & Input Developer
; File: fileio_procs.asm
; ============================================================================
; Procedures to build:
;   - read_input            (Day 1)
;   - write_file_proc       (Day 1)
;   - read_file_proc        (Day 2)
;   - check_timeout_proc    (Day 2)
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
    msg_file_err        BYTE "[ERR] Cannot create vault.txt", 0
    msg_no_vault        BYTE "[ERR] No vault found. Store first.", 0
    msg_success         BYTE "[ OK ] Operation Complete", 0
    msg_error           BYTE "[ERR] Access Denied", 0
    prompt_input        BYTE "Enter secret message: ", 0

.code

; ============================================================================
; PROCEDURE: read_input
; Description: Uses Irvine's ReadString to read a line of text from the user.
;              Stores it in input_buffer. Enforces 100-character limit
;              automatically via ReadString's max-length parameter.
; Registers:   Uses PUSHAD/POPAD (no register corruption)
; Day:         Day 1
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
; Day:         Day 1
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
; Day:         Day 2
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
; Day:         Day 2
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
; Temporary main for standalone testing (REMOVE when merging into master.asm)
; ============================================================================
main PROC
    ; --- Test your procedures here ---
    ;
    ; Test 1: read_input
    ;   mov edx, OFFSET prompt_input
    ;   call WriteString
    ;   call read_input
    ;   ; Then print input_buffer to verify
    ;   mov edx, OFFSET input_buffer
    ;   call WriteString
    ;   call Crlf
    ;
    ; Test 2: write_file_proc
    ;   ; Manually fill encrypted_buffer with 'TEST' and set checksum_val = 99
    ;   ; call write_file_proc
    ;   ; Open vault.txt in Notepad to verify
    ;
    ; Test 3: read_file_proc
    ;   ; Run write_file_proc first, then:
    ;   call read_file_proc
    ;   ; Print encrypted_buffer to verify it matches
    ;
    ; Test 4: check_timeout_proc
    ;   ; Set timer_start = 0 -> call check_timeout_proc -> EAX should = 1
    ;   ; Set timer_start = current time -> call immediately -> EAX should = 0

    invoke ExitProcess, 0
main ENDP

END main
