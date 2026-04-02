; ----- App for showing time -----
; BCD = Binary Coded Decimal :)
[org 0x8000]

start:
; Read CMOS Real Time Clock
    mov ah, 0x02
    int 0x1a            ; Get the time (CH=hours, CL=minutes, DH=seconds in BCD)

    mov al, ch
    add al, 0x02        ; Add 2 hours for Czech timezone- not optimal its hardcoded
    daa                 ; Corrects the math for BCD
    mov ch, al          ; Store the corrected hour back in CH
    mov si, time_message
    call print_string

    ; Print Hours
    mov al, ch
    call print_bcd
    mov al, ':'
    call print_char

    ; Print Minutes
    mov al, cl
    call print_bcd
    mov al, ':'
    call print_char

    ; Print Seconds
    mov al, dh
    call print_bcd

    ; Double newline
    mov si, new_line
    call print_string
    mov si, new_line
    call print_string

    jmp 0x0000:0x7C00   ; Jump back to bootloader menu

print_bcd:
    push ax
    shr al, 4          ; Get high nibble (tens digit)
    add al, '0'
    call print_char
    pop ax
    and al, 0x0F       ; Get low nibble (ones digit)
    add al, '0'
    call print_char
    ret

print_string:
    mov ah, 0x0e        ; BIOS function for renderinga
.loop:
    lodsb               ; Load SI into AL and increment SI
    cmp al, 0x00        ; If AL = 0, jump to .done
    je .done
    int 0x10
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0x0e
    int 0x10
    ret

time_message: db "Current time: ", 0x00
new_line: db 0x0D, 0X0A, 0x00

times 512-($-$$) db 0