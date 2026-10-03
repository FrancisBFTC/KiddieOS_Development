; Variável de Controle de 32-bit para 
; guardamos a Fila Prioritária 
; (a que está sendo processada)
ctrl_channel: dd 1; Cada programa
; tem o seu Canal para falar com o Kernel 
; Uma lista pro Escalonador do Kernel 
; decidir qual Canal do IPC priorizar 
ipc_priority: dd 256 
; O Escalonador usará o Segmento 0x000000:0x1FF0 
; para alocar um Novo Canal 
seg_alloc: dd 0x000000:0x1FF0
; Todo Programa tem seu Canal 
channel:
    message: dd 2 ; Bit 0 = Dado da Mensagem, Bit 1 = Instrução da Mensagem, 
                  ; o Bit 0 contém o Dado e o Bit 1 a Instrução!
    id_remetent: dd 8 ; O ID do Remetente
    reserved: db 0 ; Pode ficar zerado
    datas: dd 16 ; O que o Kernel terá que carregar,
             ; fica zerado se a Syscall não for de 
             ; Memória (como Alocação)
; Para caso de erros, 
; retornamos uma Variável
QUEUE_FALL: dd 1
; A Estrutura que o queue.asm
; terá o Estado 
queue_ctrl:
  head: dd 0 ; Ponteiro de Escrita
  tail: dd 0 ; Ponteiro de Leitura
  capacity: dd 32 ; O Tamanho Total do Canal
  Count: dd 4 ; Array de 4 Bytes para as
              ; Mensagens guardadas atualmente
; Extern da Função "ISR-IPC" em queue.asm 
extern find_data
extern find_instr 
; Exemplo:
; 0x20 para o Dado, 0x04 para a Instrução -> 
; a minha Set_Bit!

; Externs das funções/serviços localizados em syscmng.asm
extern Set_Bit
extern Get_Interface
extern Get_Class
extern Get_SubClass
extern Get_Device
extern Get_Vendor
extern Get_Classes
extern Print_String32
extern Print_Zero_Terminated
extern Get_String

GLOBAL queue_push
GLOBAL parser
GLOBAL table_services

SECTION .data
align 4
; Tabela de Serviços mapeada a partir das rotinas do syscmng.asm
table_services:
    dd 0                   ; Index 0x00: Reservado
    dd Set_Bit             ; Index 0x04: Set_Bit (Aguardando aprovação do PR do Franzis)
    dd Get_Class           ; Index 0x08: Get_Class (0x16)
    dd Get_SubClass        ; Index 0x0C: Get_SubClass (0x17)
    dd Get_Interface       ; Index 0x10: Get_Interface (0x18)
    dd Get_Device          ; Index 0x14: Get_Device (0x19)
    dd Get_Vendor          ; Index 0x18: Get_Vendor (0x1A)
    dd Get_Classes         ; Index 0x1C: Get_Classes (0x1B)
    dd Print_String32      ; Index 0x20: Print_String32
    dd Print_Zero_Terminated ; Index 0x24: Print_Zero_Terminated
    dd Get_String          ; Index 0x28: Get_String

SECTION .text

; A Função de Envio (push)
queue_push:
  ; Compara Count com capacity,
  ; se Count igual: Retorna QUEUE_FALL
  cmp dword [queue_ctrl.Count], dword [queue_ctrl.capacity] 
  je .error
  jne .continue
.error:
  mov eax, dword [QUEUE_FALL] 
  ret ; Para a CPU não executar mais
.continue:
    ; Copia a message para um
    ; Registrador 
    mov ecx, dword [channel.message] 
    ; Checa qual instrução e dado foi 
    ; enviado 
    bt ecx, 0 ; O Dado 
    jc .is_a_data
    bt ecx, 1 ; A Instrução 
    jnc .is_a_instr
    ; Copia o Valor Modificado 
    ; para a posição de memória 
    ; calculated pelo head
    mov eax, dword [queue_ctrl.head]
    ; Lógica de gravação do buffer...
.is_a_data:
  ; Chamar find_data 
  call find_data 
  mov ecx, eax ; Salva o Dado (Ex: 0x20)
.is_a_instr:
  ; Chamar find_instr 
  call find_instr
  mov ebx, eax ; Salva a Instrução (Ex: 0x04)
; Rotina Parser: Soma ECX e EBX para encontrar o Serviço correspondente
parser:
    push eax
    push edx
    ; Soma ECX (Dado, ex: 0x20) + EBX (Instrução, ex: 0x04)
    mov edx, ecx
    add edx, ebx                   ; EDX = Offset total dentro do canal/serviço
    ; Chama o serviço apontado pela tabela de serviços
    mov eax, dword [table_services + edx]
    test eax, eax                  ; Verifica se o ponteiro é válido (não nulo)
    jz .invalid_service
    call eax                       ; Executa o Serviço do syscmng.asm!
.invalid_service:
    pop edx
    pop eax
    ret

; ==================================================================
; queue_pop - Remove e retorna o elemento/mensagem do início da fila (FIFO)
;
; ENTRADA:
;   Nenhuma (ou ponteiro de contexto dependendo do buffer)
;
; SAÍDA:
;   EAX / AX = Dados/Mensagem removida da fila
;   CF (Carry Flag) = 0 se sucesso, 1 se a fila estiver vazia
; ==================================================================
queue_pop:
    push    ebx
    push    ecx
    push    edx
    ; Verifica se a fila está vazia (Count == 0)
    cmp     dword [queue_ctrl.Count], 0
    je      .queue_empty
    ; Obtém o índice do elemento do topo (head)
    mov     ebx, dword [queue_ctrl.head]
    ; Obtém o dado armazenado no ponteiro/buffer da fila
    ; Exemplo assumindo um array de dwords/mensagens em 'queue_buffer':
    mov     eax, dword [queue_buffer + ebx * 4]
    ; Atualiza a posição do head (Avança o ponteiro circular)
    inc     ebx
    cmp     ebx, QUEUE_MAX_SIZE    ; Limite máximo do buffer da fila
    jb      .no_head_wrap
    xor     ebx, ebx               ; Reseta head para 0 caso atinja o limite
.no_head_wrap:
    mov     dword [queue_ctrl.head], ebx
    ; Decrementa o contador total de itens da fila
    dec     dword [queue_ctrl.Count]
    clc     ; Limpa o Carry Flag (Sucesso)
    jmp     .exit
.queue_empty:
    stc     ; Define o Carry Flag (Erro: Fila Vazia)
.exit:
    pop     edx
    pop     ecx
    pop     ebx
    ret