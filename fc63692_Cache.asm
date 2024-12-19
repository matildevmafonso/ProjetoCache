section .data
    msg_erro: db "Erro", 0
    len_msg_erro: equ $-msg_erro

section .bss
    cache_data resb 64          ; 64 bytes for cache data
    cache_tags resb 16          ; 16 bytes for tags (1 byte per line)
    cache_validity resb 16       ; 16 bytes for validity bits (1 byte per line)


section .text
    extern set_validation_bit
    extern set_tag
    extern get_data
    extern display_table
    extern get_validation_bit
    extern get_tag

global _start

_start:
    ; Step 1: Handle command-line arguments
    mov rdi, [rsp]                   ; rdi = argc (number of arguments)
    cmp rdi, 2
    jb _erro
    mov rsi, [rsp + 8]               ; rsi = argv (pointer to arguments)
    ; Read the arguments and convert them from ASCII to integers
    ; Loop through each argument
    xor rcx, rcx                     ; rcx = index (0)
_ciclo:
    cmp rcx, rdi                     ; Compare index with argc
    jge _fim                         ; If index >= argc, exit loop

    ; Get the argument string
    mov rax, [rsi + rcx * 8]         ; rax = argv[index]

    ; Convert ASCII to integer directly
    xor rbx, rbx                     ; Clear rbx (this will hold the integer)

_conversao:
    mov rdx, byte [rax]              ; Load the next byte (character) from the string
    cmp rdx, 0                       ; Check for null terminator
    je _guardarint                   ; If null terminator, store the integer
    sub rdx, '0'                     ; Convert ASCII to integer (subtract ASCII value of '0')
    mul rbx, rbx, 10                 ; Multiply the current result by 10
    add rbx, rdx                     ; Add the new digit
    inc rax                          ; Move to the next character
    jmp _conversao                   ; Repeat the loop


_guardarint
    mov [int_args + rcx * 4], rbx    ; Store the integer in the array
    ; Print the argument and its integer value
    ; Prepare for syscall: write
    mov rax, 1                       ; syscall: write
    mov rdi, 1                       ; file descriptor: stdout
    lea rsi, [msg]                   ; pointer to the message format
    mov rdx, 256                     ; number of bytes to write (adjust as needed)
    syscall
    inc rcx                          ; Increment index
    jmp _ciclo

    ; Step 2: Decompose addresses into tag, index, and offset
    ; Loop through each address and perform the following:
    ; - Extract tag, index, and offset
    ; - Call cache simulation functions

    ; Step 3: Cache simulation logic
    ; Implement hit/miss logic and update cache accordingly

    ; Step 4: Display the cache state if needed
    ; Call display_table() to show the current state of the cache
    call display_table

_erro:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, msg_erro
    mov rdi, len_msg_erro
    syscall

; Exit the program
_fim:
    mov rax, 60         ; syscall: exit
    xor rdi, rdi        ; status: 0
    syscall

; Define your functions here
; Example function to decompose address
decompose_address:
    ; Assuming address is in rdi
    mov rsi, rdi        ; Copy address to rsi for tag extraction
    shr rsi, 6          ; Shift right by 6 bits to get the tag (10 bits)
    and rsi, 0x3FF      ; Mask to get the 10 bits for the tag

    mov rdx, rdi        ; Copy address to rdx for index extraction
    shr rdx, 2          ; Shift right by 2 bits to get the index (4 bits)
    and rdx, 0xF        ; Mask to get the 4 bits for the index

    mov rcx, rdi        ; Copy address to rcx for offset extraction
    and rcx, 0x3        ; Mask to get the 2 bits for the offset
    ret

; Example function to simulate cache access
cache_access:
    ; Check if the cache line is valid
    call get_validation_bit
    cmp rax, 1          ; Check if valid bit is set
    jne miss            ; If not valid, go to miss handling

    ; Check if the tag matches
    call get_tag
    cmp rax, rsi        ; Compare with the tag
    jne miss            ; If not equal, go to miss handling

    ; If we reach here, it's a hit
    ; Retrieve data from cache
    call get_data
    ret

miss:
    ; Handle cache miss
    ; Load data from main memory and update cache
    ret