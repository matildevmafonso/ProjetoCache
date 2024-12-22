; fc63692
; nasm -f elf64 -g -F dwarf djskl.asm
; gcc djskl.o biblioteca.o -o memoria_cache -nostartfiles -fPIE -no-pie -lncurses

section .data
    msg_erro: db "Erro: Número insuficiente de argumentos.", 0
    len_msg_erro: equ $-msg_erro

section .bss
    offset: resb 4
    index: resb 4
    tag: resb 4

section .text
    extern set_validation_bit
    extern set_tag
    extern get_data
    extern display_table
    extern get_validation_bit
    extern get_tag

    global _start
_start:
    call start_program
    jmp end_program

start_program:
    call convert_map
    jmp end_program

convert_map:
    mov r14, [rsp + 16]         ; r14 = a[i]
    mov r8, [rsp + 8]           ; r8 = b[i]

process_address:
    ; Descompacta endereço em tag, índice e deslocamento
    movzx r14, byte offset [r8]   ; Extrair deslocamento
    shr r14, 10
    and r14, 0x3
    mov [offset], r14           ; Salvar deslocamento

    movzx r14, byte index [r8]   ; Extrair índice
    shr r14, 14
    and r14, 0xF
    mov [index], r14            ; Salvar índice

    movzx r14, byte tag [r8]   ; Extrair tag
    shr r14, 24
    mov [tag], r14              ; Salvar tag

cache_hit:
    movzx rax, byte [index]     ; Carregar índice
    call get_validation_bit          ; Verificar bit de validade
    cmp al, 1
    jne cache_miss              ; Se inválido, vá para cache_miss

    call get_tag                ; Obter tag armazenada
    cmp eax, [tag]              ; Comparar com a tag calculada
    jne cache_miss              ; Se diferente, vá para cache_miss

    call get_data           ; Exibir dados em caso de hit
    jmp convert_map             ; Voltar para processar próximo endereço

cache_miss:
    movzx rax, byte [index]     ; Carregar índice
    call set_validation_bit          ; Configurar bit de validade
    call set_tag                ; Atualizar tag na cache
    call get_data           ; Exibir dados
    movzx r9, byte [index]      ; Movimentar índice (ajuste do registrador não especificado)
    jmp convert_map             ; Voltar para processar próximo endereço

end_program:
    mov rax, 60                 ; syscall: exit
    xor rdi, rdi                ; status: 0
    syscall