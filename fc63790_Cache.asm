section .bss
    offset: resb 1
    Index: resb 1
    Tag: resw 1

section .data
    error_msg: db "Erro: Argumentos insuficientes fornecidos.", 0xA, 0
    errormsg_TAM: equ $-error_msg

section .text
extern set_validation_bit
extern set_tag
extern get_data
extern display_table
extern get_validation_bit
extern get_tag

global _start

_start:
    ; Carrega o número de argumentos passados
    mov rsi, [rsp]          ; Número de argumentos para rsi
    cmp rsi, 2              ; Precisa de pelo menos 1 argumento além do nome do programa
    jb _erro                ; Vai para erro se não houver argumentos suficientes

    ; Inicialização
    xor r13, r13            ; Contador para argumentos processados
    mov r15, rsi
    sub r15, 1              ; Total de argumentos a processar (ignorar o nome do programa)

_for:
    ; Carregar o argumento atual
    mov r11, [rsp + 16 + r13 * 8] ; Endereço do argumento para r11
    mov r12, [r11]                ; Valor do argumento em r12

    ; Extrair offset
    and r12, 3             ; Máscara para obter os últimos 2 bits
    mov [offset], r12w     ; Armazena em offset

    ; Extrair Index
    mov r12, [r11]         ; Reinicia r12 com o valor original
    shr r12, 2             ; Desloca à direita para apagar os 2 bits de offset
    and r12, 15            ; Máscara para obter os próximos 4 bits
    mov [Index], r12w       ; Armazena em Index

    ; Extrair Tag
    mov r12, [r11]         ; Reinicia r12 com o valor original
    shr r12, 6             ; Desloca à direita para apagar offset e Index
    and r12, 0x3FF         ; Máscara para obter os 10 bits seguintes
    mov [Tag], r12w         ; Armazena em Tag

    ; Verificar bit de validade
    movzx edi, byte [Index]
    call get_validation_bit
    cmp rax, 1
    jne _miss              ; Se não for válido, vai para miss

_hit:
    ; Cache hit: verificar Tag
    movzx edi, byte [Index]
    call get_tag
    cmp rax, [Tag]         ; Compara a Tag recuperada com a atual
    jne _notSameTag        ; Se não coincidir, vai para atualizar Tag
    jmp _sameTag           ; Caso coincida, vai buscar dados

_sameTag:
    movzx edi, byte [Index]
    movzx edi, byte [offset]
    call get_data
    jmp _continue

_notSameTag:
    movzx edi, byte [Index]
    movzx edi, word [Tag]
    call set_tag
    movzx edi, byte [Index]
    movzx edi, byte [offset]
    call get_data
    jmp _continue

_miss:
    ; Cache miss: atualizar dados da cache
    movzx edi, byte [Index]
    call set_validation_bit
    movzx edi, byte [Index]
    movzx edi, word [Tag]
    call set_tag
    movzx edi, byte [Index]
    movzx edi, byte [offset]
    call get_data
    jmp _continue

_continue:
    ; Incrementar contador e verificar fim do loop
    inc r13
    sub r15, 1
    cmp r15, 0
    jne _for

    ; Exibir tabela final da cache
    call display_table

    ; Sair do programa
    mov rax, 60            ; Código de saída para syscall
    xor rdi, rdi           ; Código de status 0
    syscall

_erro:
    ; Exibir mensagem de erro e sair
    mov rax, 1             ; SYS_WRITE
    mov rdi, 1             ; File descriptor (stdout)
    mov rsi, error_msg     ; Mensagem de erro
    mov rdx, errormsg_TAM  ; Tamanho da mensagem
    syscall

    ; Encerrar o programa
    mov rax, 60            ; SYS_EXIT
    xor rdi, rdi           ; Código de status 0
    syscall