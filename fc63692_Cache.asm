;fc63692

section .bss
    offset: resb 2
    index: resb 4
    tag: resb 10

section .data
    msg_erro: db "Erro: Número insuficiente de argumentos.", 0
    len_msg_erro: equ $-msg_erro

section .text
    extern set_validation_bit
    extern set_tag
    extern get_data
    extern display_table
    extern get_validation_bit
    extern get_tag

global _start
_start:
    mov rdi, [rsp]            
    cmp rdi, 2                      
    jb erro                        
    dec rdi
    xor r11, r11                

processar_argumentos:
    cmp r11, rdi                    
    jge fim                        
    mov r10, [rsp + 16 + r11 * 8]  
    mov r12, [r10]                 
    mov r14, r12                   

    ;Offset
    and r14, 0x3                   
    mov [offset], r14w              

    ; Index
    mov r14, r12                   
    shr r14, 2                     
    and r14, 0xF                   
    mov [index], r14w              

    ; Tag
    mov r14, r12                   
    shr r14, 6                     
    mov [tag], r14w                

    ; Comparar bit de validade
    movzx rdi, byte [index]                
    call get_validation_bit        
    cmp rax, 1                      
    jne miss                       

    ; Comparar tag
    movzx rdi, byte [index]                
    call get_tag                   
    cmp rax, [tag]                  
    jne miss                       

    ; Hit
    movzx rdi, byte [index]                
    movzx rsi, byte [offset]               
    call get_data                  
    jmp continuar

miss:
    ; Atualizar bit de validade
    movzx rdi, byte [index]                
    call set_validation_bit        

    ; Atualizar tag
    movzx rdi, byte [index]                
    movzx rsi, word [tag]                  
    call set_tag                   

    movzx rdi, byte [index]               
    movzx rsi, byte [offset]               
    call get_data                  

continuar:
    inc r11                         
    jmp processar_argumentos       

fim:
    call display_table
    mov rax, 60                     
    xor rdi, rdi                   
    syscall

erro:
    mov rdi, 1                      
    mov rsi, 1                      
    mov r10, msg_erro              
    mov r11, len_msg_erro         
    syscall