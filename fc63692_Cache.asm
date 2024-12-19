; fc63692

section .data
    msg_erro: db "Erro", 0
    len_msg_erro: equ $-msg_erro
    cacheSize equ 16             ; Número de linhas da cache
    blocoSize equ 4              ; Número de bytes por bloco
    offsetBits equ 2             ; Bits para deslocamento
    indiceBits equ 4             ; Bits para índice
    tagBits equ 10               ; Bits para tag

section .bss
    cache resb cacheSize * (1 + tagBits / 8 + blocoSize) ; Cada linha: bit de validade + tag + bloco

section .text
    extern set_validation_bit
    extern set_tag
    extern get_data
    extern display_table
    extern get_validation_bit
    extern get_tag

global _start
_start:
    ; 1. Validar argumentos
    mov rdi, [rsp]                  ; Número de argumentos
    cmp rdi, 2                      ; Pelo menos um argumento (o programa conta como argumento)
    jb erro
    mov rsi, [rsp + 8]              ; Primeiro argumento (endereços em ASCII)

    ; Loop para processar os argumentos
    mov rcx, rdi                    ; Número de argumentos
    sub rcx, 1                      ; Descontar o programa
    mov rbx, rsp                    ; Endereço inicial dos argumentos
    add rbx, 16                     ; Pular endereço do programa

processar_argumentos:
    ; 2. Converter ASCII para endereço
    cmp rdx, cacheSize
    jae fim
    movzx rdx, byte [rbx]           ; Primeiro caractere
    movzx rax, byte [rbx + 1]       ; Segundo caractere
    shl rax, 8                      ; Little-endian: caractere mais alto à direita
    or rax, rdx
    
    ; 3. Decompor endereço
    mov rcx, rax
    and rcx, 0x3                   ; Bits de deslocamento
    shr rax, offsetBits
    mov rdx, rax
    and rdx, 0xF                   ; Bits de índice
    shr rax, indiceBits
    ; Agora rax contém a tag

    ; 4. Consultar cache
    mov rdi, rdx                    ; Índice
    call get_validation_bit
    cmp rax, 1                      ; Validar bit de validade
    jne atualizar_cache             ; Se inválido, ir para atualizar_cache

    ; Verificar tag
    mov rdi, rdx                    ; Índice
    call get_tag
    cmp rax, rcx                    ; Comparar tag
    jne atualizar_cache

    ; Cache hit, buscar dado
    mov rdi, rdx                    ; Índice
    mov rsi, rcx                    ; Deslocamento
    call get_data
    jmp continuar


atualizar_cache:
    ; Atualizar bit de validade
    mov rdi, rdx                    ; Índice
    call set_validation_bit

    ; Atualizar tag
    mov rsi, rax                    ; Tag
    call set_tag

    ; Buscar dado
    mov rdi, rdx                    ; Índice
    mov rsi, rcx                    ; Deslocamento
    call get_data

continuar:
    add rbx, 2                      ; Próximo par de caracteres
    dec rcx                         ; Decrementa o contador
    jnz processar_argumentos        ; Salta se o contador não for zero

    ; Exibir estado final da cache
    call display_table
    jmp fim

erro:
    mov rax, 1                      ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    mov rsi, msg_erro               ; Mensagem
    mov rdx, len_msg_erro           ; Tamanho da mensagem
    syscall
    ret

fim:
    mov rax, 60                     ; syscall: exit
    xor rdi, rdi                    ; status: 0
    syscall