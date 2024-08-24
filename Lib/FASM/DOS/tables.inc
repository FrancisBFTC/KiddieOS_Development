
; SISTEMA INICIAL DO PRÉ-PROCESSADOR DE DIRETIVAS E CONSTANTES

; Passos pra identificar a diretiva:
; 	1. Pegar a primeira letra da diretiva, Exemplo: 'i' = 69h
;	2. Subtrair número hexa por 61h (equivale a vogal 'a'), Exemplo: 69h - 61h = 8
;	3. Armazenar em CX o valor de [..._vec] no deslocamento +8, Exemplo: cx = [_vec + 8] = 4
;	4. Executar loop 8 vezes somando cada valor de _vec, Exemplo: bx=0+0+0+1+0+0+0+0=1
;	5. Multiplicar o resultado por 2 (WORD), Exemplo: 1 * 2 = 1 << 1 = 2
;	6. Usar este número para deslocar na tabela ..._addr, Exemplo: si = [_addr + 2] = include_addr
;	7. Usar o valor de CX = 4 salvo antes como Loop pra ler a partir de [include_addr], Exemplo: 4 vezes
;	8. Comparar cada uma das diretivas: include, irp, irps e irpv
;	9. Se não encontrar, procurar em outras tabelas iguais a preprocessor_directives_addr, voltar ao passo 3
;	10. Se na última tabela de diretivas não encontrar, então, a diretiva é desconhecida

; Passos alternativos ou de falhas dos passos anteriores:
;	1.0 - Se no passo 2. a subtração der 0, não é necessário executar o passo 4. e 5.
;		1.1 - Sendo este número 0, o deslocamento da tabela _addr será o 1ª endereço ([_addr + 0])
;	2.0 - Se no passo 3. o valor de [_vec + N] for 0, realizar os mesmos passos na próxima tabela
;		2.1 - Se nas próximas tabelas houver o mesmo resultado 0, a diretiva é desconhecida

preprocessor_directives_addr:
	dw	define_addr,	include_addr, 	irp_addr, 		irps_addr, 		irpv_addr
	dw 	macro_addr, 	match_addr, 	postpone_addr, 	purge_addr, 	rept_addr
	dw	restore_addr,	restruc_addr,	struc_addr

preprocessor_directives_vec db 0,0,0,1,0,0,0,0,4,0,0,0,2,0,0,2,0,3,1,0,0,0,0,0,0,0

preprocessor_directives:
 define_addr  	db 'define',0
 include_addr 	db 'include',0
 irp_addr		db 'irp',0
 irps_addr		db 'irps',0
 irpv_addr		db 'irpv',0
 macro_addr		db 'macro',0
 match_addr		db 'match',0
 postpone_addr	db 'postpone',0
 purge_addr		db 'purge',0
 rept_addr		db 'rept',0
 restore_addr	db 'restore',0
 restruc_addr	db 'restruc',0
 struc_addr		db 'struc',0
 db 0
 
; SISTEMA SECUNDÁRIO DO PRÉ-PROCESSADOR DE DIRETIVAS E CONSTANTES

; Passos para armazenar diretivas após o 1ª sistema:
;	1. Se não encontrar a diretiva, abortar este sistema, Se encontrar, Executar o próximo passo	 	
;	2. Armazenar numa tabela da XMS o endereço da diretiva do código-fonte
;	3. Após armazenar todas as diretivas, executar sistemas de substituição nos próximos passos
;	4. Executar código específico pra cada diretiva, Exemplo: 'includes' serão substituídos por código-fonte
;	5. Em caso de 'Defines/Macros', todo o código será lido procurando ocorrências, copiando pra outro buffer
;	6. Na 1ªs palavras desconhecidas, procurar na tabela da XMS e copiar o conteúdo no restante do buffer
;	7. Após o outro buffer ser preenchido, todo o código-fonte foi substituído, executar próximos passos
;	8. Recopiar novamente pro buffer original e zerar os dados do outro buffer e da tabela na XMS
;	9. Tanto includes, defines e macros, as cópias serão feitas entre os buffers durante as substituições
;	10. Fim do sistema de diretivas, e executar sistema terciário de substituição de labels

; OBSERVAÇÕES: Estas tabelas acima serão usadas também para instruções e registradores, usando a mesma
;			   Lógica. No entanto, ao invés de terminar em 0 cada String, ela terminará no OPCODE, onde
;			   Este opcode será lido e efetuado a 'mescla' nos dados da instrução. Na próxima linha, esse
;			   Processo se reinicia.