; Exportamos as funções para o ipc.asm ou kernel poderem chamar
global queue_push
global queue_pop
global find_data
global find_instr

; Importamos as estruturas e variáveis declaradas no ipc.asm
extern queue_ctrl
extern channel
extern QUEUE_FALL

SECTION .text

; ==================================================================
; Função: find_data
; Descrição: Extrai/Verifica se o Bit 0 (Dado) está ativo em ECX
; Entrada: ECX = Valor da mensagem
; Saída: EAX = Valor do Dado (Exemplo: 0x20 para Set_Bit) ou 0
; ==================================================================
find_data:
    bt ecx, 0                     ; Testa o Bit 0 (Dado)
    jnc .no_data
    ; Extrai os bits de Dado (mascarando a flag de sinalizador do bit 0)
    mov eax, ecx
    and eax, 0xFFFFFFFC           ; Limpa bits de controle (bit 0 e bit 1)
    ret
.no_data:
    xor eax, eax                  ; Retorna 0 se não houver dado
    ret


; ==================================================================
; Função: find_instr
; Descrição: Extrai/Verifica se o Bit 1 (Instrução) está ativo em ECX
; Entrada: ECX = Valor da mensagem
; Saída: EAX = Valor da Instrução (Exemplo: 0x04 para Set_Bit) ou 0
; ==================================================================
find_instr:
    bt ecx, 1                     ; Testa o Bit 1 (Instrução)
    jnc .no_instr
    ; Extrai o identificador da instrução/comando
    mov eax, ecx
    and eax, 0x0000000C           ; Isolando os bits correspondentes à Instrução
    ret
.no_instr:
    xor eax, eax                  ; Retorna 0 se não houver instrução
    ret