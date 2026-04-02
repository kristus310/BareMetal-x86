; ----- The bootloader -----
[org 0x7c00]            ; BIOS always boots from this address

start:                  ; To prevent bad addressing
    xor ax, ax          ;  - Zero out AX
    mov ds, ax          ;  - Set DS to 0
    mov es, ax          ;  - Set ES to 0

    cmp byte [boot_drive], 0 ; If the bootloader is rerun from any other app, it will skip setting the bootdrive
    jne skip_save
    mov [boot_drive], dl; BIOS stores the drive here
skip_save:
    mov di, input_buffer; Set DI to the start of the buffer

    mov si, welcome_msg
    call print_string
    call print_menu
    mov si, prompt
    call print_string

main:
    call get_input      ; Wait for user input

    cmp al, 0x0D        ; Did the user press Enter?
    je handle_enter

    cmp al, 0x08        ; Did the user press Backspace?
    je handle_backspace

    stosb               ; Store AL into DI
    call print_char

    jmp main

; ----- FUNCTIONS -----
load_sector:
    mov ah, 0x02        ; BIOS function to read a sector
    mov al, 1           ; How many sectors to read (1 sector = 512 bytes)
    mov ch, 0
    mov dh, 0
    int 0x13
    jc disk_error       ; If an error occurred, jump to disk_error
    ret

disk_error:
    mov si, disk_err_msg
    call print_string
    jmp $               ; Infinite loop

launch_app_a:
    mov si, app_a_message
    call print_string

    xor ax, ax
    mov es, ax          ; ES:BX = 0x0000:0x8000
    mov bx, 0x8000      ; Load app to address 0x8000
    mov cl, 2           ; Sector 2 on disk
    mov dl, [boot_drive]
    call load_sector
    jmp 0x8000

launch_app_b:
    mov si, app_b_message
    call print_string

    xor ax, ax
    mov es, ax
    mov bx, 0x8000      ; Load app to address 0x8000
    mov cl, 3           ; Sector 3 on disk
    mov dl, [boot_drive]
    call load_sector
    jmp 0x8000


print_string:
    mov ah, 0x0e        ; BIOS function for rendering
.loop:
    lodsb               ; Load SI into AL and increment SI
    cmp al, 0x00        ; If AL = 0, jump to .done
    je .done
    int 0x10
    jmp .loop
.done:
    ret                 ; End of loop, return from call print

print_char:
    mov ah, 0x0e        ; BIOS function for rendering
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
    mov ah, 0x00        ; BIOS function for reading a key
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
    mov ah, 0x0e        ; BIOS function for rendering
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    ret

check_buffer:           ; Simple if statements
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
    dec di              ; Move back one character in memory, for stosb
    mov ah, 0x0e        ; BIOS function for rendering
    mov al, 0x08        ; Cursor left
    int 0x10
    mov al, 0x20        ; Space
    int 0x10
    mov al, 0x08        ; Cursor left again
    int 0x10
    jmp main

; ----- VARIABLES -----
boot_drive: db 0x00
disk_err_msg: db "Disk read failed!", 0x0D, 0x0A, 0x00
input_buffer: times 8 db 0x00
welcome_msg: db "Hello and welcome to my bootloader!", 0x0D, 0X0A, 0x00

app_a_message: db "Loading [Guess number]...", 0x0D, 0X0A, 0x00
app_b_message: db "Loading [Show time]...", 0x0D, 0X0A, 0x00

menu_top:    db 0xDA, 0xC4, 0xC4, 0xC4, " SELECT APP ", 0xC4, 0xC4, 0xC4, 0xBF, 0x0D, 0x0A, 0x00
menu_line1:  db 0xB3, " [A] Guess number ", 0xB3, 0x0D, 0x0A, 0x00
menu_line2:  db 0xB3, " [B] Show time    ", 0xB3, 0x0D, 0x0A, 0x00
menu_line3:  db 0xB3, " [C] This menu    ", 0xB3, 0x0D, 0x0A, 0x00
menu_bottom: db 0xC0, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4
            db 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4, 0xC4
            db 0xD9, 0x0D, 0x0A, 0x00
prompt:      db " > ", 0x00

; ----- BIOS "Configuration" -----
times 510-($-$$) db 0x00  ; Boot sector must be exactly 512 bytes, required by BIOS
dw 0xaa55               ; BIOS only boots if the sector ends with 0x55AA (little endian)