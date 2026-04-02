; ----- App/game about guessing a random generated number -----
[org 0x8000]

start:
    ; Setup segments
    xor ax, ax
    mov es, ax
    mov ds, ax

    ; Seed from BIOS timer at 0040:006C
    mov ax, 0x0040
    mov es, ax
    mov ax, [es:0x006C]
    mov [seed], ax

    ; Restore ES to 0 for later work with it
    xor ax, ax
    mov es, ax

    ; Generate number 1-9
    call rand_lcg
    xor dx, dx
    mov bx, 9
    div bx                  ; DX = AX mod 9
    inc dx                  ; range 1-9
    mov [secret], dx

    mov si, msg_welcome
    call print_string

game_loop:
    mov si, msg_prompt
    call print_string

    ; Read a single digit key
    mov ah, 0x00
    int 0x16                ; AL = key pressed

    ; Echo the character
    mov ah, 0x0e
    int 0x10

    push ax                 ; saving AL before overwriting it

    mov si, newline
    call print_string

    pop ax                  ; now taking AL back

    ; Ignore input that isnt a number
    cmp al, '1'
    jl game_loop
    cmp al, '9'
    jg game_loop

    ; Convert ASCII to number and compare
    sub al, '0'
    xor ah, ah
    cmp ax, [secret]
    je correct
    jl too_low

too_high:
    mov si, msg_too_high
    call print_string
    jmp game_loop

too_low:
    mov si, msg_too_low
    call print_string
    jmp game_loop

correct:
    mov si, msg_correct
    call print_string
    jmp 0x0000:0x7C00

; ----- LCG RNG -----
; Returns: AX = pseudo-random 16-bit number
rand_lcg:
    mov ax, [seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [seed], ax
    ret

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


seed:    dw 0
secret:  dw 0

newline:      db 0x0D, 0x0A, 0
msg_welcome:  db "Guess a number between 1 and 9!", 0x0D, 0x0A, 0
msg_prompt:   db "Your guess: ", 0
msg_too_low:  db "Too low!", 0x0D, 0x0A, 0
msg_too_high: db "Too high!", 0x0D, 0x0A, 0
msg_correct:  db "Correct! You win!", 0x0D, 0x0A, 0x0D, 0x0A, 0

times 512-($-$$) db 0