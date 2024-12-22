section .data
    msg_erro: db "Erro: Número insuficiente de argumentos.", 0
    len_msg_erro: equ $-msg_erro
    offsetBits equ 2             ; Bits para deslocamento
    indiceBits equ 4             ; Bits para índice
    tagBits equ 10               ; Bits para tag

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
    cmp rdi, 2                      ; Pelo menos um argumento adicional
    jb erro
    mov rsi, [rsp + 8]              ; Primeiro argumento (endereços em pares ASCII)

    ; Inicializar contador e ponteiro para os argumentos
    mov rcx, rdi                    ; Número de argumentos
    sub rcx, 1                      ; Descontar o programa em si
    lea rbx, [rsp + 16]             ; Apontar para o primeiro argumento

processar_argumentos:
    ; Converter dois caracteres ASCII em endereço
    movzx rax, byte [rbx]           ; Primeiro caractere (LSB)
    movzx rdx, byte [rbx + 1]       ; Segundo caractere (MSB)
    shl rdx, 8                      ; Deslocar MSB para a esquerda
    or rax, rdx                     ; Combinar em um único valor de 16 bits
    mov rsi, rax                    ; RAX contém o endereço completo

    ; Extrair deslocamento (offset)
    mov r14, r12                  ; Copiar o endereço completo para R14
    and r14, 0x3                  ; Máscara para obter os 2 bits menos significativos (deslocamento)
    mov [offset], r14             ; Salvar deslocamento em uma variável ou registrador

    ; Extrair índice
    mov r14, r12                  ; Copiar novamente o endereço completo
    shr r14, 2                    ; Deslocar 2 bits à direita para ignorar deslocamento
    and r14, 0xF                  ; Máscara para obter os 4 bits de índice
    mov [index], r14              ; Salvar índice em uma variável ou registrador

    ; Extrair tag
    mov r14, r12                  ; Copiar o endereço completo novamente
    shr r14, 6                    ; Deslocar 6 bits à direita para ignorar deslocamento e índice
    mov [tag], r14                ; Salvar tag em uma variável ou registrador

    ; 3. Consultar cache
    mov rdi, rcx                    ; Índice
    call get_validation_bit
    cmp rax, 1                      ; Verificar bit de validade
    jne reset_cache

    mov rdi, rcx                    ; Índice
    call get_tag
    cmp rax, rsi                    ; Comparar tag
    jne reset_cache

    ; Cache hit: buscar dado
    mov rdi, rcx                    ; Índice
    mov rsi, rdx                    ; Offset
    call get_data
    jmp continuar

reset_cache:
    ; Atualizar bit de validade
    mov rdi, rcx                    ; Índice
    call set_validation_bit

    ; Atualizar tag
    mov rdi, rcx                    ; Índice
    mov rsi, rsi                    ; Tag
    call set_tag

    ; Buscar dado
    mov rdi, rcx                    ; Índice
    mov rsi, rdx                    ; Offset
    call get_data                   ; Buscar dado da cache

continuar:
    add rbx, 2                      ; Avançar para o próximo par de caracteres
    dec rcx                         ; Decrementar contador
    jnz processar_argumentos        ; Repetir enquanto houver argumentos

    ; Exibir estado final da cache
    call display_table
    jmp fim

erro:
    ; Exibir mensagem de erro
    mov rax, 1                      ; syscall: write
    mov rdi, 1                      ; stdout
    mov rsi, msg_erro               ; Mensagem de erro
    mov rdx, len_msg_erro           ; Comprimento da mensagem
    syscall

fim:
    mov rax, 60                     ; syscall: exit
    xor rdi, rdi                    ; status: 0
    syscall