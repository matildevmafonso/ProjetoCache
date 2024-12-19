; -----------------------------------------------------------------------------
; Este ficheiro (demo.asm) serve como uma demonstração das chamadas às funções 
; da biblioteca. Para ilustrar o funcionamento, foram criadas variáveis que 
; simulam dois endereços distintos, Bb e @b. Apesar de possuírem a mesma etiqueta 
; e o mesmo índice, os endereços distinguem-se pelo deslocamento. É de notar 
; que as variáveis abaixo (indice, etiqueta, deslocamento1 e deslocamento2) 
; são apenas para fins de demonstração deste cenário e não fariam sentido
; existir desta forma numa solução prática para o projeto.
;
; Após a execução deste ficheiro, é produzido um ficheiro de logs 
; que documenta a ordem e parametros dos comandos utilizados durante a execução.
; --------------------------------------------------------------------------------


section .data ;endereço de exemplo
    arg1 db "Bb", 0   		;3 bytes
    etiqueta dw 0110001001b     ; 10 bits	
    indice db 0000b             ; 4 bits
    deslocamento1 db 10b        ; 2 bits
    arg2 db "@b", 0 		;3 bytes
    deslocamento2 db 00b	; 2 bits

    


SECTION .text
; secção para identificar que funções da biblioteca a usar
extern set_validation_bit
extern set_tag
extern get_data
extern display_table
extern get_validation_bit
extern get_tag

global _start
_start:
	;Para simular um argumento recebido na linha de comando utilizamos a variável arg1
	;esta variável pode ser convertida de "B b 0x0" => 0x42 0x62 0x0
	;no entanto o conteúdo que se encontra no registo é 0x0 0x62 0x42 devido à escrita da direita para a esquerda
	
	mov rsi, arg1			;colocar o endereço de arg1 num registo (ex: rsi)			
	mov ax, [rsi]			;colocar o conteudo de arg1 num registo (ex: rax)
	
		
	; A representação em ascii encontra-se no registo rax
	
	
	;Inicialmente a cache encontra-se vazia
	call display_table
	
	;atualizar o bit de validade para 1 -> update_validation_bit(indice)
	movzx edi, byte[indice]			;colocar indice em rdi (argumento para a função)
	call set_validation_bit		;chamar a função
	
	;bit de validade no indice 0 é agora 1
	
	call display_table			;função para ver a estrutura da tabela
	
	;obter o bit de validade de um dado indice -> get_validation_bit(indice)
	movzx edi, byte[indice]			;colocar indice em rdi (argumento para a função)
	call get_validation_bit			;chamar a função
	
	;O bit de validade do indice 0 será colocado em rax e deverá ser 1
	
	
	;atualizar o conteúdo de uma linha -> update_line(indice, etiqueta, deslocamento)
	movzx edi, byte[indice]			;colocar indice em rdi (1º argumento para a função)
	movzx esi, word[etiqueta]			;colocar etiqueta em rsi (2º argumento para a função)
	call set_tag			;chamar a função
	
	;a linha com indice 0 deverá ter como etiqueta o valor 01 1000 1001 
	
	call display_table
	
	;Após isto vamos ler o byte dado pelo deslocamento1
	;acedendo ao 3 byte da memória que deverá ser F9
	movzx edi, byte[indice]			;colocar indice em rdi (1º argumento para a função)
	movzx esi, byte[deslocamento1]		;colocar deslocamento em rdx (2º argumento para a função)
	call get_data				;chamar a função
	
	
	
	call display_table
	
	
	;obter a etiqueta de uma linha -> get_tag(indice)
	movzx edi, byte[indice]			;colocar indice em rdi (argumento para a função)
	call get_tag				;chamar a função
	
	;A etiqueta do indice 0 será colocado em rax e deverá ser 01 1000 1001 

	;Agora vamos assumir que o segundo argumento passado é o arg2
	;esta variável pode ser convertida de "@ b 0x0" => 0x40 0x62 0x0
	;no entanto o conteúdo que se encontra no registo é 0x0 0x62 0x40 devido à escrita da direita para a esquerda
	
	;Este novo endereço aprensenta o mesmo indice e a mesma etiqueta que o endereço anterior,
	;portanto representa uma cache hit
	
	mov rsi, arg2		;colocar o endereço de arg2 num registo (ex: rsi)			
	mov ax, [rsi]		;colocar o conteudo de arg2 num registo (ex: rax)
	
	;Como é um cache hit, irá marcar o novo deslocamento que será 00 e aceder ao byte 0 da memória que deverá ser B6

	;Aceder um byte de uma linha especificada -> read_data(indice, etiqueta, deslocamento)
	movzx edi, byte[indice]			;colocar indice em rdi (1º argumento para a função)
	movzx esi, byte[deslocamento2]		;colocar deslocamento em rdx (2º argumento para a função)
	call get_data				;chamar a função
	
	
	
	call display_table 
		
	mov rax, 60                 ; Syscall: exit
	xor rdi, rdi                ; Exit code: 0
	syscall

