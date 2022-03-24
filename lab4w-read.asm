TITLE COM-PORT32 
;32-� ࠧ�來�� �ਫ������ ��� ��ࠢ�� ������ � COM-����. 
;�ணࠬ�� ��।��� ��� ᨬ����, ����񭭮�� � ����������, � ���� 
;COM-����, ࠡ���騩 � ᨭ�஭��� ०���. 

.386
;���᪠� ������ ����� � �⠭���⭠� ������ �맮�� ����ணࠬ�. 
.MODEL FLAT, STDCALL

;��४⨢� ��������騪� ��� ������祭�� ������⥪. 
INCLUDELIB import32.lib ; ����� � ������⥪�� �� Kernel32. 
  
;--- ���譨� WinAPI-�㭪権 -------------------------------------------------- 
EXTRN FreeConsole:    PROC  ; �᢮������ ⥪���� ���᮫� 
EXTRN AllocConsole:  PROC  ; ������� ᢮� ���᮫� 
EXTRN GetStdHandle:  PROC  ; ������� ���ਯ�� ⥪�饩 ���᮫� 
EXTRN printf:       PROC  ; �뢥�� �� 蠡���� 
EXTRN CreateFileA:      PROC  ; ������� ���ਯ�� ����� 
EXTRN ReadConsoleInputA: PROC  ; ������� ᮡ��� ���᮫� 
EXTRN WriteFile:  PROC  ; ��।��� ����� � ���� 
EXTRN ReadFile:  PROC  ; ������� ����� �� ���� 
EXTRN GetLastError:   PROC  ; ������� ��� �訡�� 
EXTRN PurgeComm:     PROC  ; ������ ��।� ��� � ��।�� 
EXTRN CloseHandle:    PROC  ; ������� ���ਯ�� 
EXTRN ExitProcess:   PROC  ; �������� ����� 
EXTRN GetCommState:  PROC  ; ������� DCB �������� ���� 
EXTRN SetCommState:  PROC  ; ������ ��ࠬ���� ���� 
EXTRN GetCommTimeouts:  PROC ; ������� �६���� ��ࠬ���� 
EXTRN SetCommTimeouts: PROC ; ��⠭����� �६���� ��ࠬ���� 
  
;--- ����⠭�� ----------------------------------------------------------------------- 
GENERIC_READ         = 80000000h ; ����᪠���� �⥭�� 
GENERIC_WRITE        = 40000000h ; ����᪠���� ������ 
OPEN_EXISTING      = 3   ; �।���뢠�� ���뢠�� ���ன�⢮, �᫨ ��� ������� 
STD_INPUT_HANDLE   = -10 ; ���᮫쭮� ���� ��� ����� ������ 
STD_OUTPUT_HANDLE  = -11 ; ���᮫쭮� ���� ��� �뢮�� ������ 
PURGE_TXCLEAR      = 4   ; ���⪠ ��।� ��।�� 
CBR_300            = 300 ; ���祭�� ᪮��� ��।�� ������ 
Key_Event          = 1 ; ⨯ ��������୮�� ᮡ���

;--- �������� ������ ------------------------------------------------------------- 
;������� �᭮���� ��ࠬ��஢ ��᫥����⥫쭮�� ���� 
DeviceControlBlock STRUC  
 DCBlength dd ? ; ������ �������� � ����� 
 BaudRate dd ? ; ������� ��।�� ������ 
 fBitFields dd ? ; ��⮢� ���� 
 wReserved dw ? ; ��१�ࢨ஢��� 
 XonLim   dw ? ; ���. ���-�� ᨬ����� ��� ���뫪� XON 
 XoffLim   dw ? ; ����. ���-�� ᨬ����� ��� ���뫪� XOFF 
 ByteSize db ? ; ��᫮ ���ଠ樮���� ��� 
 Parity   db ? ; �롮� �奬� ����஫� �⭮�� 0-4 
 StopBits db ? ; ���-�� �⮯���� ��⮢ 0, 1, 2 = 1, 1.5, 2 
 XonChar   db ? ; ��� XON �� ��।�� � ��� 
 XoffChar db ? ; ��� XOFF �� ��।�� � ��� 
 ErrorChar db ? ; ��� ᨬ���� �� �����㦥��� �訡�� 
 EofChar    db ? ; ��� ᨬ���� ���� ������ 
 EvtChar    db ? ; ��� ᨬ���� ��� �맮�� ᮡ�⨩ 
 wReserved1 dw ? ; ��१�ࢨ஢��� 
DeviceControlBlock ENDS  
  
;������� �६����� ��ࠬ��஢ ���� 
CommTimeOuts STRUC  
   ReadIntervalTimeout        dd ?  ; ���ࢠ� ����� ᨬ������ 
   ReadTotalTimeoutMultiplier  dd ?  ; ����. ��� ��ਮ�� ����� �⥭�� 
   ReadTotalTimeoutConstant    dd ?  ; �����. ��� ��ਮ�� ����� �⥭�� 
   WriteTotalTimeoutMultiplier dd ?  ; ����. ��� ��ਮ�� ����� ����� 
   WriteTotalTimeoutConstant   dd ?  ; �����. ��� ��ਮ�� ����� ����� 
CommTimeOuts ENDS    
  
; ������� � ���ଠ樥� � ᮡ���� �� ���������� 
KeyEvent  STRUC  
 KeyDown       dd ? ; �ਧ��� ������/���᪠��� ������ 
 RepeatCount   dw ? ; ���-�� ����஢ �� 㤥ঠ��� ������ 
 VirtualKeyCode dw ? ; ����㠫�� ��� ������ 
 VirtualScanCode dw ? ; ����-��� ������ 
 ASCIIChar  dw ? ; ASCII-��� ������ 
 ControlKeyState dd ? ; ����ﭨ� �ࠢ����� ������ 
KeyEvent  ENDS  
  
; ������� ���� ᮡ�⨩ ���᮫� 
InputRecord  STRUC  
     EventType        dw ?  ; ��� ᮡ��� 
                       dw 0  ; ��� ��ࠢ������� ���� 
     KeyEventRecord    KeyEvent <>   
     MouseEventRecord  dd 4 dup (?)   
     WindowsBufferSizeRecord dd ?  
     MenuEventRecord      dd ?  
     FocusEventRecord      dd ?  
InputRecord  ENDS  

;--- ����� --------------------------------------------------------------------------- 
.DATA  
  msgTitle db '����஢���� ��᫥����⥫쭮�� ����', 13,10,13,10, 0 
  msgInit db 'Com-���� ���樠����஢��', 13, 10, 13, 10, 0 
  msgError db 13, 10, '�訡��: %u', 13, 10, 0 
  msgInKey db '%c=', 0 
  msgInKeyBin db '        ', 0 
  msgOutKey   db 1Ah, '����� ��ࠢ���� � ����', 13, 10, 0 
  msgNotOutKey db 7Eh, '����� � ���� �� ��ࠢ����', 13, 10, 0
  nl db 13,10,0
  msgIntVal db '%d',13,10,0
 
  NamePort  db '\\.\COM4', 0  ; ��� ���� � Windows 
  HPort   dd ? ; ���ਯ�� ���� 
  HIn  dd ? ; ���ਯ�� ���� ����� ������ 
  Buffer dw ? ; ���� ��� ��।�� ������ 
  NumEvent dd ? ; ��᫮ ᮡ�⨩ 
  LenBuf dd 1 ; ������⢮ �⠥��� ���� �� ����
  RdLen   dd ? ; ������⢮ ���⠭��� ���� �� ����

  DCB DeviceControlBlock <> ; �����⥫� �� �������� � ��ࠬ��ࠬ� ���� 
  CTO CommTimeOuts       <>  ; �����⥫� �� �������� � �६��. ��ࠬ��ࠬ� 
  CBuffer InputRecord    <> ; �����⥫� �� �������� ���� ���᮫� 
  
.CODE  
;--- ���樠������ COM-���� ------------------------------------------------- 
; �����頥� EAX <> 0 - �ᯥ譮� �����襭��, 0 - �訡�� 
InitCom PROC  
 ARG   Port: DWORD  ; ���ਯ�� ���� 
  
; ����祭�� ⥪��� ���祭�� DCB �������� 
 call GetCommState, Port, offset DCB
 test eax, eax ; �஢�ઠ �� �訡��
 jz   mICExit
  
; ���������� �������� DCB 
 mov  DCB.BaudRate, CBR_300 
 mov  DCB.ByteSize, 5
 mov  DCB.Parity, 0 
 mov  DCB.StopBits, 1
  
; ��⠭���� ��ࠬ��஢ ���� 
 call SetCommState, Port, offset DCB
 test eax, eax
 jz   mICExit
  
; ����祭�� ⥪��� ���祭�� �६����� ��ࠬ��஢ 
 call GetCommTimeouts, Port, offset CTO
 test eax, eax
 jz   mICExit

; ���������� �������� CTO 
 mov  CTO.WriteTotalTimeoutMultiplier, 100
 mov  CTO.WriteTotalTimeoutConstant,   10

; ��⠭���� �६����� ��ࠬ��஢ ���� 
 call SetCommTimeouts, Port, offset CTO
 test eax, eax
 jz   mICExit
  
; ���⪠ ���� ��।�� ��। ࠡ�⮩ � ���⮬ 
 call PurgeComm, Port, PURGE_TXCLEAR
mICExit:
 ret
InitCom ENDP  
  
;--- �८�ࠧ������ �᫠ � ����筮�� ���� --------------------------------- 
;Number - ��室��� �᫮ 
;String - ���� ��ப�, �㤠 �����뢠���� १���� �८�ࠧ������ 
Preobr PROC
 ARG  Number:DWORD, String:DWORD
 uses esi, ebx, ecx
 mov esi, String
 mov ecx, 8 ; �८�ࠧ������ ⮫쪮 ����襣� ���� 
 add esi, ecx ; ����� ���冷� �뢮��: �� ����襣� ࠧ�鸞 � ���襬� 
 sub esi, 1  
@1: shr Number, 1  
 jc @2  
 mov bl, 30h  
 jmp @3  
@2: mov bl, 31h  
@3: mov [esi], bl  
 dec esi  
 loop @1
 ret  
Preobr ENDP   
  
;--- �᭮���� ��� -------------------------------------------------------------------- 
Start:  
 call FreeConsole  
 call AllocConsole  
 call GetStdHandle, STD_INPUT_HANDLE 
 mov    HIn, eax  
 call printf, offset msgTitle 
 add   esp, 4*1 ; ���४�஢�� �⥪� ��᫥ printf 
  
; ����⨥ ���� ��� ᨭ�஭���� ०��� ࠡ��� 
 call CreateFileA, offset NamePort, GENERIC_READ or GENERIC_WRITE, 0, 0, OPEN_EXISTING, 0, 0 
 mov  HPort, eax  
 cmp  HPort, -1 ; � ��砥 �訡�� �뢮� ᮮ�饭�� 
 je   mError  
  
; ���樠������ COM-���� 
 call InitCom, HPort 
 test eax, eax  
 jz   mError  
  
 call printf, offset msgInit 
 add  esp, 4*1  

 ; �뢮� ᨬ���� � ��� ����筮�� ���� � ���᮫�
pr:
 call ReadFile, HPort, offset Buffer, LenBuf, offset RdLen, 0
 xor eax, eax
 mov ax, [Buffer]
 call Preobr, eax, offset msgInKeyBin
 call printf, offset msgInKey, Buffer
 add esp, 4*2
 call printf, offset msgInKeyBin
 add esp, 4
 call printf, offset nl
 add esp, 4
 mov eax, RdLen
 jmp pr
  
mError:  ; ��ࠡ�⪠ �訡�� 
 call GetLastError  
 call printf, offset msgError, eax 
 add  esp, 4*2  
 cmp  HPort, -1  
 je   mWait  
 call CloseHandle, HPort 
  
mWait: ; �������� ������ ������ 
 call ReadConsoleInputA, HIn, offset CBuffer, 1, offset NumEvent 
 cmp  CBuffer.EventType, Key_Event 
 jne  mWait ; ����⨥ �� ����������? 
 jmp  mExit  
  
; ���⪠ ���� ��।�� � �����⨥ ���� 
mClose:  
 call PurgeComm, HPort, PURGE_TXCLEAR 
 test eax, eax  
 jz   mError  
 call CloseHandle, HPort  
  
mExit:   ; ��室 �� �ணࠬ�� 
 call  CloseHandle, HIn 
 call FreeConsole  
 call ExitProcess, 0  
END Start
