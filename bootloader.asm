[org 0x7c00]            ; V téhle adrese se nám spustí kód, protože BIOS vždy bootuje z této adresy

start:                  ; Aby se nestal bad addresing
    xor ax, ax          ;  - Vynulujeme AX
    mov ds, ax          ;  - Nastaví DS na 0
    mov es, ax          ;  - Nastaví ES na 0

    mov [boot_drive], dl; BIOS tady ukládá drive

    mov di, input_buffer; Nastavení DI na začátek paměti

    mov si, welcome_msg
    call print_string
    call print_menu
    mov si, prompt
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
load_sector:
    mov ah, 0x02        ; BIOS funkce na čtení sektoru
    mov al, 1           ; Kolik sektorů má přečíst (1 sektor = 512 bytů)
    mov ch, 0
    mov dh, 0
    int 0x13
    jc disk_error       ; Pokud nastala chyba, skoč na disk_error
    ret

disk_error:
    mov si, disk_err_msg
    call print_string
    jmp $               ; Nekonečná loop

launch_app_a:
    mov si, app_a_message
    call print_string

    xor ax, ax
    mov es, ax          ; ES:BX = 0x0000:0x8000
    mov bx, 0x8000      ; Načte aplikaci do adresy 0x8000
    mov cl, 2           ; Sektor 2 na disku
    mov dl, [boot_drive]
    call load_sector
    jmp 0x8000

launch_app_b:
    mov si, app_b_message
    call print_string

    xor ax, ax
    mov es, ax
    mov bx, 0x8000      ; Načte aplikaci do adresy 0x8000
    mov cl, 3           ; Sektor 2 na disku
    mov dl, [boot_drive]
    call load_sector
    jmp 0x8000


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

print_menu:
    mov si, menu_top
    call print_string

    mov si, menu_line1
    call print_string

    mov si, menu_line2
    call print_string

    mov si, menu_line3
    call print_string

    mov si, menu_bottom
    call print_string
    ret

get_input:
    mov ah, 0x00        ; BIOS funkce pro čtení klávesy
    int 0x16
    ret

handle_enter:
    mov byte [di], 0
    call print_newline

    call check_buffer

    mov di, input_buffer
    mov si, prompt
    call print_string
    jmp main

print_newline:
    mov ah, 0x0e        ; BIOS funkce pro vykreslení grafiky
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    ret

check_buffer:           ; Jednoduchý If's
    mov al, [input_buffer]

    cmp al, 'a'
    je launch_app_a
    cmp al, 'A'
    je launch_app_a

    cmp al, 'b'
    je launch_app_b
    cmp al, 'B'
    je launch_app_b

    cmp al, 'c'
    je print_menu
    cmp al, 'C'
    je print_menu

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
boot_drive: db 0x00
disk_err_msg: db "Disk read failed!", 0x0D, 0x0A, 0x00
input_buffer: times 8 db 0x00
welcome_msg: db "Hello and welcome to my bootloader!", 0x0D, 0X0A, 0x00

app_a_message: db "Loading [Guess the number]...", 0x0D, 0X0A, 0x00
app_b_message: db "Loading [Show the time]...", 0x0D, 0X0A, 0x00

menu_top:    db 0xDA, 0xC4, 0xC4, 0xC4, " SELECT APP ", 0xC4, 0xC4, 0xC4, 0xBF, 0x0D, 0x0A, 0x00
menu_line1:  db 0xB3, " [A] Guess number ", 0xB3, 0x0D, 0x0A, 0x00
menu_line2:  db 0xB3, " [B] Show time    ", 0xB3, 0x0D, 0x0A, 0x00
menu_line3:  db 0xB3, " [C] This menu    ", 0xB3, 0x0D, 0x0A, 0x00
menu_bottom: db 0xC0, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4
            db 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4
            db 0xD9, 0x0D, 0x0A, 0x00
prompt:      db " > ", 0x00

; ----- "Nastavení" pro BIOS -----
times 510-($-$$) db 0x00  ; Byte sektor musí být dlouhý přesně 512 bytes, pro BIOS
dw 0xaa55               ; BIOS bootuje jen pokud ten sektor končí na 0x55AA (malý endian)