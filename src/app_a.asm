[org 0x8000]

start:
    mov si, msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0x00
    je .done
    int 0x10
    jmp .loop
.done:
    ret

msg: db "Hello from App A!", 0x0D, 0x0A, 0

times 512-($-$$) db 0