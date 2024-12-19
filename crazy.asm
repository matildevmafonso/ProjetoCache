; fcXXXXX_Cache.asm
section .data
    msg_erro: db "Erro: Número de argumentos inválido.", 0
    len_msg_erro: equ $-msg_erro
    cacheSize equ 16             
    blocoSize equ 4              
    offsetBits equ 2             
    indiceBits equ 4             
    tagBits equ 10               

section .bss
    cache resb cacheSize * (1 + tagBits / 8 + blocoSize)

section .text
    extern set_validation_bit, set_tag, get_data, display_table, get_validation_bit, get_tag
    global _start

_start:
    mov rdi, [rsp]                  
    cmp rdi, 2                      
    jb erro                        
    mov rsi, [rsp + 8]              
    test rsi, rsi                   
    je fim                         

    mov rcx, rdi                    
    sub rcx, 1                      
    mov rbx, rsp                    
    add rbx, 16                     

processar_argumentos:
    cmp rdx, cacheSize              
    jae fim                         
    movzx rdx, byte [rbx]           
    movzx rax, byte [rbx + 1]       
    shl rax, 8                      
    or rax, rdx                    

    mov rcx, rax                    
    and rcx, 0x3                   
    shr rax, offsetBits
    mov rdx, rax
    and rdx, 0xF                   
    shr rax, indiceBits             

    mov rdi, rdx                    
    call get_validation_bit
    cmp rax, 1                      
    jne atualizar_cache             

    mov rdi, rdx                    
    call get_tag
    cmp rax, rcx                    
    jne atualizar_cache             

    mov rdi, rdx                    
    mov rsi, rcx                    
    call get_data
    jmp continuar

atualizar_cache:
    mov rdi, rdx                    
    call set_validation_bit

    mov rsi, rax                    
    call set_tag

    mov rdi, rdx                    
    mov rsi, rcx                    
    call get_data

continuar:
    add rbx, 2                      
    dec rcx                         
    cmp rcx, 0                      
    jne processar_argumentos        

    call display_table              

erro:
    mov rax, 1                      
    mov rdi, 1                      
    mov rsi, msg_erro               
    mov rdx, len_msg_erro           
    syscall
    ret

fim:
    mov rax, 60                     
    xor rdi, rdi                    
    syscall
