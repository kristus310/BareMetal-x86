[org 0x7c00]            ; V téhle adrese se nám spustí kód, protože BIOS vždy bootuje z této adresy

start:                  ; Aby se nestal bad addresing
    xor ax, ax          ;  - Vynulujeme AX
    mov ds, ax          ;  - Nastaví DS na 0
    mov es, ax          ;  - Nastaví ES na 0

    mov di, input_buffer; Nastavení DI na začátek paměti

    mov si, welcome_msg
    call print_string

main:
    call get_input      ; Čeká na input od uživatele

    cmp al, 0x0D        ; Zmáčkl uživatel Enter?
    je handle_enter

    cmp al, 0x08        ; Zmáčkl uživatel Backspace?
    je handle_backspace

    stosb               ; Uložení znaku AL do DI
    call print_char

    jmp main

; ----- FUNKCE -----
print_string:
    mov ah, 0x0e        ; BIOS funkce pro vykreslení grafiky
.loop:
    lodsb               ; Načte SI do AL a inkrementne SI
    cmp al, 0x00        ; Jestli AL = 0 tak to skočí do .done
    je .done
    int 0x10
    jmp .loop
.done:
    ret                 ; Tady končí loop, vracíme se po call print

print_char:
    mov ah, 0x0e        ; BIOS funkce pro vykreslení grafiky
    int 0x10
    ret

get_input:
    mov ah, 0x00        ; BIOS funkce pro čtení klávesy
    int 0x16
    ret

handle_enter:
    call print_newline
    call check_buffer

    mov di, input_buffer
    jmp main

print_newline:
    mov ah, 0x0e        ; BIOS funkce pro vykreslení grafiky
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    ret

check_buffer:
    cmp byte [input_buffer], 'p'
    jne .done

    mov si, welcome_msg
    call print_string
.done:
    ret

handle_backspace:
    dec di              ; V paměti se vráti o znak zpět, pro stosb
    mov ah, 0x0e        ; BIOS funkce pro vykreslení grafiky
    mov al, 0x08        ; Kurzor vlevo
    int 0x10
    mov al, 0x20        ; Mezera
    int 0x10
    mov al, 0x08        ; Kurzor znovu vlevo
    int 0x10
    jmp main

; ----- VARIABLES -----
input_buffer: times 64 db 0     ; Vyhrazený místo pro 64 znaků
welcome_msg: db "Hello and welcome to my bootloader!", 0x0D, 0X0A, 0x00

; --- "Nastavení" pro BIOS ---
times 510-($-$$) db 0   ; Byte sektor musí být dlouhý přesně 512 bytes, pro BIOS
dw 0xaa55               ; BIOS bootuje jen pokud ten sektor končí na 0x55AA (malý endian)