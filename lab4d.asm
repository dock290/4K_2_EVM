TITLE COM-PORT
;Comport.asm
;16-� ࠧ�來�� �ਫ������ �஢�ન ࠡ��� COM-����.
;�ணࠬ�� ��।��� ��� ᨬ����, ����񭭮�� � ����������, � ����
;COM-���� � ����砥� �� ᨣ���, ����� �뢮��� �� �࠭.

.MODEL SMALL
.STACK 100h

;--- ����� ---------------------------------------------------------------------------
.DATA
  msgTitle db 'Testirovanie posledovatelnogo porta', 13, 10, 13, 10, '$'
  msgInfo db 'Nazhmite lyubuyu klavishu dlya otpravki yeyo koda v port.'
       db 13, 10, 'Dlya vykhoda nazhmite ESC.', 13, 10, 13, 10, '$'
  msgInit db 'Com-port inizializirovan', 13, 10, 13, 10, '$'
  msgError db 'Port ne obnaruzhen', 13, 10, '$'

.CODE
;--- ���⪠ �࠭� � ��⠭���� ����� � ���孨� ���� 㣮�-----------
ClearScreen PROC
mov ah, 06h   ;�㭪�� �ப��⪨ ��⨢��� ��࠭��� �����
 mov al, 00h  ;���⪠ �ᥣ� �࠭�
 mov bh, 07h   ;��ਡ�� �஡��� = �/�, ���. �મ��
 mov cx, 00h   ;������ ����� ������
 mov dx, 184Fh ;������ �ࠢ�� ������ (Y=24, X=79)
 int 10h
 mov ah, 02h   ;��⠭���� �����
 mov bh, 00h
 mov dx, 00h
 int 10h
 ret
ClearScreen ENDP

;--- �뢮� ⥪�� �� �࠭ --------------------------------------------------------
Print PROC
 push ax
 mov ah, 9
 int 21h
 pop ax
 ret
Print ENDP

;--- ���樠������ C0M-����--------------------------------------------------
;DX ? ������ ���� ���� COM-����
InitCom PROC
 push dx
 add dx, 03h      ;ॣ���� �ࠢ����� ����� (03FBh)
 mov al, 10000000b  ;��⠭�������� 7 ���
 out dx, al
 sub dx, 2    ;���訩 ���� ॣ���� ����⥫� ����� (3F9h)
 mov al, 00h    ;��� ��� 600 ���
 out dx, al
 dec dx         ;����訩 ���� ॣ���� ����⥫� ����� (3F8h)
 mov al, 0C0h   ;��� ��� 600 ���
 out dx, al
 add dx, 03h      ;ॣ���� �ࠢ����� ������ (3FBh)
 mov al, 00h    ;��頥� al
 or  al, 00000011b  ;����� ᨬ���� (11b) ? 8 ��� ������
 or  al, 00000000b  ;����� �⮯-��� (0b) ? 1 �⮯-���
 or  al, 00000000b  ;����稥 ��� ��⭮�� (000b) ?
                    ;�� �����஢��� ��� �⭮��
 out dx, al
 inc dx         ;ॣ���� �ࠢ����� ������� (3FCh)
 mov al, 00010000b  ;���������᪨� ०�� (0001����b)
 out dx, al
 sub dx, 3    ;ॣ���� ࠧ�襭�� ���뢠��� (3F9h)
 mov al, 0    ;���뢠��� ����饭�
 out dx, al
 pop dx
 ret
InitCom ENDP

;--- �८�ࠧ������ ���� ᨬ���� ��� �뢮�� � ����୮� ���� ---------
;AX ? ASCII ��� ᨬ����
Preobr PROC
 mov bl, al
 mov ah, 0Eh 
 mov cx, 8
m6: rol bl, 1
 jc m7
 mov al, 30h  ;�뢮� ᨬ���� "0"
 jmp m8
m7: mov al, 31h  ;�뢮� ᨬ���� "1"
m8: int 10h
 loop m6
 ret
Preobr ENDP

;--- ����� � ���⮬ ----------------------------------------------------------------
;DX ? ������ ���� COM-����
Work PROC
m1: mov ah, 00h ;���� ᨬ����
 int 16h ;AL=ASCII ���, AH=᪠����
 mov ah, 00h ;᪠���� 㤠�塞
 cmp al, 1Bh ;�஢�ઠ ������ ESC
 je m5
 push ax
 push ax
 mov ah, 0Eh ;�뢮� �⮣� ᨬ���� �� �࠭
 int 10h
 mov al, 3Dh ;�뢮� ᨬ���� "="
 int 10h
 pop ax
 call Preobr
 mov al, 1Ah ;�뢮� ᨬ���� "��५�窠"
 int 10h
 add dx, 05h ;ॣ���� ���ﭨ� ����� (3FDh)
 mov cx, 0Ah ;����稪 横�� ࠢ�� 10
m2: in al, dx ;����ࠥ� �� ���� 03FDh ����� � AL
 test al, 20h ;��⮢ � �ਥ�� ������? (00100000b)
 jz m3
 loop m2
m3: sub dx, 05h ;ॣ���� ��।��稪� (03F8h)
 pop ax  ;����㧨�� ��।������ ���� �� �⥪�
 out dx, al ;��।�� � COM-���� ��� ᨬ���� �� AL
 add dx, 05h ;ॣ���� ���ﭨ� ����� (03FDh)
m4: in al, dx ;����� �ਭ��� ?
 test al, 01h
 jz m4
 sub dx, 05h ;ॣ���� ��񬭨�� (03F8h)
 in al, dx ;������ �ਭ��� �����
 mov ah, 0
 push ax
 mov ah, 0Eh ;�뢥�� ᨬ��� �� �࠭
 int 10h
 mov al, 3Dh ;�뢮� ᨬ���� "="
 int 10h
 pop ax
 call Preobr
 mov al, 13 ;��ॢ�� � ��砫� ��ப�
 int 10h
 mov al, 10 ;���室 �� ����� �����
 int 10h
 jmp m1
m5: ret
Work ENDP

;--- �᭮���� ��� --------------------------------------------------------------------
Start:  mov ax, @Data
 mov ds, ax
 call ClearScreen ;���⪠ �࠭�
 lea dx, msgTitle
 call Print  ;�뢮� ��ப� msgTitle
 mov ax, 40h      ;ES 㪠�뢠�� �� ������� ������ BIOS
 mov es, ax
 ;mov dx, es:[0]    ;����砥� ������ ���� COM1 (03F8h)
 mov dx, es:[2]    ;����砥� ������ ���� COM2 (02F8h)
 test dx, 0FFFFh ;���� ���� ����?
 jnz m0
 lea dx, msgError
 call Print
 jmp mExit
m0: call InitCom   ;���樠������ COM-����
 push  dx
 lea dx, msgInit
 call Print
 lea dx, msgInfo
 call Print
 pop dx
 call Work   ;ࠡ�� � ���⮬
mExit: mov ax, 4C00h
 int 21h
END Start
