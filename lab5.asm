TITLE USBView32 
;32-� ࠧ�來�� �ਫ������ ��� �뢮�� � ���᮫쭮� ����  
; ���ਯ�஢ ��� ������祭��� USB ���ன��. 
 
.386  
; ���᪠� ������ ����� � �⠭���⭠� ������ �맮�� ����ணࠬ�. 
.MODEL FLAT, STDCALL  
 
; ��४⨢� ��������騪� ��� ������祭�� ������⥪. 
INCLUDELIB import32.lib ; ����� � ������⥪�� �� Kernel32. 
 
;--- ���譨� WinAPI-�㭪権 -------------------------------------------------- 
EXTRN FreeConsole:    PROC ; �᢮������ ⥪���� ���᮫� 
EXTRN AllocConsole:  PROC ; ������� ᢮� ���᮫� 
EXTRN GetStdHandle:  PROC ; ������� ���ਯ�� ⥪�饩 ���᮫� 
EXTRN printf:       PROC ; �뢥�� �� 蠡���� 
EXTRN CreateFileA:      PROC ; ������� ���ਯ�� ����� 
EXTRN DeviceIoControl: PROC ; ������� ���ଠ�� �� ���ன�⢥ 
EXTRN RtlZeroMemory:  PROC ; ������ ������ 
EXTRN ReadConsoleInputA: PROC ; ������� ᮡ��� ���᮫� 
EXTRN GetLastError:   PROC ; ������� ��� �訡�� 
EXTRN CloseHandle:    PROC ; ������� ���ਯ��

EXTRN ExitProcess:   PROC ; �������� ����� 
 
;--- ����⠭�� ----------------------------------------------------------------------- 
GENERIC_WRITE  = 40000000h ; ����᪠���� ������ 
FILE_SHARE_WRITE  = 2   ; ����᪠���� ������ ��㣨�� ����ᠬ� 
OPEN_EXISTING  = 3   ; �।���뢠�� ���뢠�� ���ன�⢮, 
;�᫨ ��� ������� 
STD_INPUT_HANDLE = -10 ; ���᮫쭮� ���� ��� ����� ������ 
USB_REQUEST_GET_DESCRIPTOR= 06  ; ����� ���ਯ�� 
Key_Event   = 1      ; ⨯ ��������୮�� ᮡ��� 
 
; ���� ���ਯ�஢  
USB_DEVICE_DESCRIPTOR_TYPE   = 01h 
USB_CONFIGURATION_DESCRIPTOR_TYPE = 02h 

; Additional descriptors
USB_INTERFACE_DESCRIPTOR_TYPE = 04h
USB_HID_DESCRIPTOR_TYPE = 21h
USB_ENDPOINT_DESCRIPTOR_TYPE = 05h
 
; ��ࠢ���騥 ���� ����権  
IOCTL_USB_GET_ROOT_HUB_NAME   = 00220408h; 
IOCTL_USB_GET_NODE_INFORMATION  = 00220408h; 
IOCTL_USB_GET_NODE_CONNECTION_INFORMATION_EX = 00220448h; 
IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION = 00220410h; 
 
;--- �������� ������ ------------------------------------------------------------- 
; ������� ᨬ���쭮�� ����� ���ன�⢠ 
TDeviceName STRUC  
   Length dd ?        ; ������ �������� � ����� 
   Name   dw 136 dup (?) ; ������쭮� ��� ���ன�⢠ � ������� 
TDeviceName ENDS  
 
; ������� ���ਯ�� 堡� 
THubDescriptor STRUC  
   bDescriptorLength  db ? ; ����� ���ਯ�� 
   bDescriptorType  db ? ; ��� ���ਯ�� 
   bNumberOfPorts  db ? ; ��᫮ ���⮢ 堡� 
   wHubCharacteristics dw ? ; ��ਡ��� ���� 
   bPowerOnToPowerGood  db ? ; �६� �⠡�����樨 ����殮��� 
   bHubControlCurrent db ? ; ���ᨬ��쭮� ���ॡ����� (��) 
   bRemoveAndPowerMask  db 64 dup (?)  ; �� �ᯮ������ 
THubDescriptor ENDS  
 
; ������� � ���ଠ樥� � 堡� 
THubInformation STRUC

HubDescriptor THubDescriptor <>   
   HubIsBusPowered db ?   ; ���ᮡ ��⠭�� 堡�: �� 設� (1) 
;��� �� ���譥�� ���筨�� (0) 
THubInformation ENDS  
 
; ������� �����/�⢥� � ���ଠ樥� � 堡� 
TNodeInformation STRUC  
   NodeType       dd ?   ;  ��� ���ன�⢠: 0  ?  堡 
;1 ? ��������. ���ன�⢮ 
   HubInformation THubInformation <>  
TNodeInformation ENDS  
 
; ������� ���ਯ�� USB ���ன�⢠ 
TDeviceDescriptor STRUC  
   bLength        db ? ; ����� ���ਯ�� 
   bDescriptorType db ? ; ��� ���ਯ�� 
   bcdUSB        dw ? ; ����� �����ন������ ᯥ��. USB 
   bDeviceClass   db ? ; ��� ����� USB 
   bDeviceSubClass db ? ; ��� �������� USB ���ன�⢠ 
   bDeviceProtocol db ? ; ��� ��⮪��� USB 
   bMaxPacketSize db ? ; ����. ࠧ��� ����� ��� �㫥��� 
;����筮� �窨 
   idVendor       dw ? ; �����䨪��� �ந�����⥫� 
   idProduct      dw ? ; �����䨪��� �த�� 
   bcdDevice      dw ? ; ����� ���ᨨ ���ன�⢠ 
   iManufacturer db ? ; ������ ���ਯ�� ��ப�, 
;����뢠�饣� �ந�����⥫� 
   iProduct       db ? ; ������ ���ਯ�� ��ப�, 
;����뢠�饣� �த�� 
   iSerialNumber db ? ; ������ ���ਯ�� ��ப� � �਩�� 
;����஬ ���ன�⢠ 
   bNumConfigurations  db ? ; ��᫮ ���䨣��権 � ���ன�⢠ 
TDeviceDescriptor ENDS  
 
; ������� � ���ଠ樥� � ���� 
TNodeConnectionInformation STRUC 
   ConnectionIndex  dd ?        ; ������ ���� 
   DeviceDescriptor TDeviceDescriptor <> ; ���ਯ�� ���ன�⢠ 
   CurrentConfigurationValue db ?     ; ����� ���䨣��樨 ���ன�⢠ 
   Speed        db ?        ; ������� ࠡ��� ���ன�⢠ 
;(0-LS, 1-FS, 2-HS, 3-SS)

DeviceIsHub     db ?        ; �������� ������祭���� 堡� 
   DeviceAddress  dw ?        ; ���� ���ன�⢠ �� 設� USB 
   NumberOfOpenPipes db ?        ; ��᫮ ������� �����, 
;�易���� � ���⮬ 
   ConnectionStatus  db 4 dup (?) ; ����� ���� (�. ����) 
   PipeList       db 32 dup (?)  ; ���ᨢ ������� � ���ᠭ�� 
;�������, �易���� � ���⮬ 
TNodeConnectionInformation ENDS 
;ConnectionStatus =  
;  0 = NoDeviceConnected  - ��� ������祭��� ���ன�� 
;  1 = DeviceConnected   - ���ன�⢮ ������祭� 
;  2 = DeviceFailedEnumeration - �訡�� �㬥�樨 
;  3 = DeviceGeneralFailure  - �⠫쭠� �訡�� 
;  4 = DeviceCausedOvercurrent - ��ॣ�㧪� �� ⮪� 
;  5 = DeviceNotEnoughPower  - �������筮� ��⠭�� 
;  6 = DeviceNotEnoughBandwidth - �� 墠⠥� �ய�᪭�� ᯮᮡ���� 
;  7 = DeviceHubNestedTooDeeply - �ॢ�襭 �஢��� ��᪠��஢. 堡�� 
;  8 = DeviceInLegacyHub  - �� �����ন����� 堡 
;  9 = DeviceEnumerating  - ���ன�⢮ � ���ﭨ� ?�㬥�樨? 
;  10= DeviceReset    - ���ன�⢮ � ���ﭨ� ?���? 
  
; ������� ���䨣��樮����� ����� ����� � ���ன��� 
TSetupPacket STRUC  
   bmRequest   db ? ; ��� ����� 
   bRequest  db ? ; ����� ����� 
   wValue  dw ? ; ��� � ������ ���ਯ�� 
   wIndex  dw ? ; ������ ���ਯ�� 
   wLength  dw ? ; ����� ������ �� ���筮� ����� 
TSetupPacket ENDS  
  
; ������� ����� � ���ன���   
UsbDescriptorRequest STRUC  
   ConnectionIndex dd ?          ; ����� ��ꥪ� (����, �����. �窠) 
   SetupPacket      TSetupPacket <>  
   Data         db 2048 dup (?)  ; ���� ��� �����頥��� ������ 
UsbDescriptorRequest ENDS  
  
; ������� � ���ଠ樥� � ᮡ���� �� ���������� 
KeyEvent STRUC  
   KeyDown       dd ? ; �ਧ��� ������/���᪠��� ������ 
   RepeatCount   dw ? ; ���-�� ����஢ �� 㤥ঠ��� ������

VirtualKeyCode dw ? ; ����㠫�� ��� ������ 
   VirtualScanCode dw ? ; ����-��� ������ 
   ASCIIChar   dw ? ; ASCII-��� ������ 
   ControlKeyState dd ? ; ����ﭨ� �ࠢ����� ������ 
KeyEvent ENDS  
  
; ������� ���� ᮡ�⨩ ���᮫� 
InputRecord STRUC  
     EventType   dw ? ; ��� ᮡ��� 
                 dw 0 ; ��� ��ࠢ������� ���� 
     KeyEventRecord     KeyEvent <>  
     MouseEventRecord dd 4 dup (?)  
     WindowsBufferSizeRecord dd ?  
     MenuEventRecord dd ?  
     FocusEventRecord dd ?  
InputRecord ENDS  
  
;--- ����� --------------------------------------------------------------------------- 
.DATA  
; �뢮���� ᮮ�饭��  
  msgTitle     db '����祭�� ���ਯ�஢ USB ���ன��', 13,10,13,10, 0 
  msgHostError  db '�� ������ USB ���-����஫��� �� �������', 13, 10, 0 
  msgError    db 13,10,'�訡��: %u', 13, 10, 0 
  msgInitHost db 0B3h, 13, 10, 0C3h, '���� ����஫��� No%d', 13, 10, 0 
  msgHubInfo  db 0B3h, 0C0h, ' ��᫮ ���⮢ ��୥���� 堡�: %d', 13, 10, 0 
  msgNoCon  db 0B3h,'  ', 0C3h,' � ����� %02d ���ன�� �� ������祭�',13,10,0 
  msgHubCon db 0B3h, '  ', 0C3h,' � ����� %02d ������祭 堡', 13, 10, 0 
  msgDevCon db 0B3h,'  ',0C3h,' � ����� %02d ������祭� ���ன�⢮', 13, 10, 0 
  msgStatus db 0B3h,'  ',0C3h,' ���� %02d ��室���� � ���ﭨ� <%d>', 13,10,0 
  
  msgDevDescr db 0B3h,'  ',0B3h, 13, 10 
     db 0B3h,'  ',0B3h,'    <���ਯ�� ���ன�⢠>', 13, 10 
     db 0B3h,'  ',0B3h,'               bcdUSB = %X.%X', 13, 10 
     db 0B3h,'  ',0B3h,'         bDeviceClass = %u', 13, 10 
     db 0B3h,'  ',0B3h,'      bDeviceSubClass = %u', 13, 10 
     db 0B3h,'  ',0B3h,'      bDeviceProtocol = %u', 13, 10 
     db 0B3h,'  ',0B3h,'       bMaxPacketSize = %u', 13, 10 
     db 0B3h,'  ',0B3h,'             idVendor = %02X%02Xh', 13, 10 
     db 0B3h,'  ',0B3h,'            idProduct = %02X%02Xh', 13, 10 
     db 0B3h,'  ',0B3h,'            bcdDevice = %02X%02Xh', 13,10 
     db 0B3h,'  ',0B3h,'        iManufacturer = %u', 13, 10 
     db 0B3h,'  ',0B3h,'             iProduct = %u', 13, 10

     db 0B3h,'  ',0B3h,'        iSerialNumber = %u', 13, 10 
     db 0B3h,'  ',0B3h,'   bNumConfigurations = %u', 13, 10, 0 
  
  msgConfDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <���ਯ�� ���䨣��樨>',13,10 
      db 0B3h,'  ',0B3h,'         wTotalLength = %u', 13, 10 
      db 0B3h,'  ',0B3h,'       bNumInterfaces = %u', 13, 10 
      db 0B3h,'  ',0B3h,'  bConfigurationValue = %u', 13, 10 
      db 0B3h,'  ',0B3h,'       iConfiguration = %u', 13, 10 
      db 0B3h,'  ',0B3h,'         bmAttributes = %02Xh', 13, 10 
      db 0B3h,'  ',0B3h,'             MaxPower = %u ��', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0

  msgInterfaceDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <���ਯ�� ����䥩�>',13,10 
      db 0B3h,'  ',0B3h,'     bInterfaceNumber = %u', 13, 10 
      db 0B3h,'  ',0B3h,'    bAlternateSetting = %u', 13, 10 
      db 0B3h,'  ',0B3h,'        bNumEndpoints = %u', 13, 10 
      db 0B3h,'  ',0B3h,'      bInterfaceClass = %u', 13, 10 
      db 0B3h,'  ',0B3h,'   bInterfaceSubClass = %u', 13, 10 
      db 0B3h,'  ',0B3h,'   bInterfaceProtocol = %u', 13, 10 
      db 0B3h,'  ',0B3h,'           iInterface = %u', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0 

  msgHidDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <���ਯ�� HID>',13,10 
      db 0B3h,'  ',0B3h,'               bcdHID = %X.%X', 13, 10 
      db 0B3h,'  ',0B3h,'         bCountryCode = %u', 13, 10 
      db 0B3h,'  ',0B3h,'      bNumDescriptors = %u', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0 
   
  msgEndpointDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <���ਯ�� ����筮� �窨>',13,10 
      db 0B3h,'  ',0B3h,'     bEndpointAddress = %02Xh', 13, 10 
      db 0B3h,'  ',0B3h,'         bmAttributes = %02Xh', 13, 10 
      db 0B3h,'  ',0B3h,'       wMaxPacketSize = %u', 13, 10 
      db 0B3h,'  ',0B3h,'            bInterval = %u', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0

  msgExit db 13,10,'��� ��室� ������ ���� �������...', 0 
 
; ��६���� 
  NameHost db '\\.\HCD' ; ��� ��� � Windows 
  NumHost dd ?    ; ����� ��� 
  iHost  dd ?    ; ������ ��� 
  
  ; Pay attention here 
  NameRootHub db '\\.\'  ; ����⮢�� ��� ��� ��୥���� 堡� 
  
  SRootHub db 136 dup (?) ; ��ப� � ������ 堡� 
  hHost   dd ?    ; ���ਯ�� ���-����஫��� 
  hRootHub dd ?    ; ���ਯ�� ��୥���� 堡� 
  hPort  dd ?    ; ���ਯ�� ���� 
  iPort   dd ?    ; ������ ⥪�饣� ���� 堡� 
  hIn  dd ?    ; ���ਯ�� ���� ����� ������ 
  NumEvent dd ?    ; ��᫮ ᮡ�⨩ 
  bReturned dd ?    ; ��᫮ ����, ��������� �㭪樥� 
  
; �����⥫� �� ��������  
  CBuffer     InputRecord <>        ; ���� ���᮫� 
  DeviceName      TDeviceName <>        ; ��� ���ன�⢠ 
  NodeInformation  TNodeInformation <>       ; ���ଠ�� � 堡� 
  NodeConnInfo   TNodeConnectionInformation <>  ; ���ଠ�� � ���� 
  DescriptorRequest  UsbDescriptorRequest <>    ; ����� ���ਯ�� 
  
.CODE  
;--- ����祭�� ���ଠ樨 � ���� 堡� -------------------------------------- 
;hHub  ? ���ਯ�� ��୥���� 堡� 
;Port ? ������ ���� 堡� 
;�����頥� EAX = 1 ? �ᯥ譮� �����襭��, 0 ? �訡�� 
ShowHubPortDetail PROC  
 ARG   hHub: DWORD, Port: DWORD

; ����祭�� ���ﭨ� ���� 堡� 
 mov  eax, Port  
 mov  NodeConnInfo.ConnectionIndex, eax 
 call DeviceIoControl, hHub, IOCTL_USB_GET_NODE_CONNECTION_INFORMATION_EX, offset NodeConnInfo, size NodeConnInfo, offset NodeConnInfo, size NodeConnInfo, offset bReturned, 0 
 test  eax, eax ; �஢�ઠ �ᯥ譮�� �믮������ ������� 
 jz   SHPDExit ; � ��砥 �訡�� ��室 �� ��楤��� (eax=0) 
  
; �஢�ઠ ����� ���� 
 cmp  NodeConnInfo.ConnectionStatus[3], 0 
 jne  ConDev 
 call printf, offset msgNoCon, Port 
 add  esp, 4*2 
 jmp  NoError 
ConDev:  
 cmp  NodeConnInfo.ConnectionStatus[3], 1 
 jne  NextStatus 
 cmp  NodeConnInfo.DeviceIsHub, 0 
 jz   NoHub 
 call  printf, offset msgHubCon, Port 
 add  esp, 4*2 
 call  ShowDeviceDetail, hHub, Port 
 jmp  NoError 
NoHub: 
 call  printf, offset msgDevCon, Port 
 add  esp, 4*2 
 call  ShowDeviceDetail, hHub, Port 
 jmp  NoError 
NextStatus: 
    call  printf, offset msgStatus, Port, dword ptr NodeConnInfo.ConnectionStatus[3] 
 add  esp, 4*3 
  
NoError:  
 mov  eax, 1  
SHPDExit:  ret  
ShowHubPortDetail ENDP

;--- ����祭�� USB ���ਯ�஢ ----------------------------------------------

;hHub  ? ���ਯ�� ��୥���� 堡� 
;Port ? ������ ���� 堡� 
;�����頥� EAX = 1 ? �ᯥ譮� �����襭��, 0 ? �訡�� 
ShowDeviceDetail PROC  
 ARG   hHub: DWORD, Port: DWORD 
  
; ����祭�� ���ਯ�� ���ன�⢠ 
 mov  eax, Port  
 mov  DescriptorRequest.ConnectionIndex, eax 
 mov  DescriptorRequest.SetupPacket.bmRequest, 80h 
 mov  DescriptorRequest.SetupPacket.bRequest, USB_REQUEST_GET_DESCRIPTOR 
 mov  DescriptorRequest.SetupPacket.wValue, USB_DEVICE_DESCRIPTOR_TYPE 
 shl  DescriptorRequest.SetupPacket.wValue, 8 
 mov  DescriptorRequest.SetupPacket.wLength, 100h 
 
 call DeviceIoControl, hHub, IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION, offset DescriptorRequest, size DescriptorRequest, offset DescriptorRequest, size DescriptorRequest, offset bReturned, 0 
 test  eax, eax 
 jz   SDDExit 
 
; �뢮� ���ਯ�� ���ன�⢠ 
 call DisplayDescriptorInfo, offset DescriptorRequest.Data 
 
; ���⪠ ���� 
 call RtlZeroMemory, offset DescriptorRequest.Data, dword ptr size DescriptorRequest.Data 
 
; ����祭�� ���ਯ�஢ ���䨣��権 
 mov  eax, Port 
 mov  DescriptorRequest.ConnectionIndex, eax 
 mov  DescriptorRequest.SetupPacket.bmRequest, 80h 
 mov  DescriptorRequest.SetupPacket.bRequest, USB_REQUEST_GET_DESCRIPTOR 
 mov  DescriptorRequest.SetupPacket.wValue, USB_CONFIGURATION_DESCRIPTOR_TYPE 
 shl  DescriptorRequest.SetupPacket.wValue, 8 
 mov  DescriptorRequest.SetupPacket.wLength, 100h 
 
 call DeviceIoControl, hHub, IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION, offset DescriptorRequest, size DescriptorRequest, offset DescriptorRequest, size DescriptorRequest, offset bReturned, 0 
 test  eax, eax 
 jz   SDDExit 
 
; �뢮� ���ਯ�� 
 call DisplayDescriptorInfo, offset DescriptorRequest.Data 
 
; ���⪠ ���� 
 call RtlZeroMemory, offset DescriptorRequest.Data, dword ptr size DescriptorRequest.Data 
 mov  eax, 1 
 
SDDExit:  ret 
ShowDeviceDetail ENDP 
 
;--- �뢮� ���ਯ�஢ � ���᮫� ---------------------------------------------- 
;Buffer ? ���� ���ᨢ� ���ਯ�஢ 
;edi ? ���� ⥪�饣� ���� � ���� 
;esi ? ����� ���ਯ�� 
DisplayDescriptorInfo PROC 
 ARG   Buffer: DWORD 
 uses  eax, ebx, edi, esi 
 
; ��室�� �� ���ᨢ� ���ਯ�஢ 
; ���� ���� ? ࠧ��� ���ਯ�� � ����� 
; ��ன ���� ? ⨯ ���ਯ�� 
 mov  edi, Buffer  
Cycle:  
 movzx  esi, byte ptr [edi+0]    ; ����� ���ਯ�� 
 cmp  esi, 0                 ; ��� ����� ���ਯ�஢? 
 je   DDIExit  
 cmp  byte ptr [edi+1], 0 ; ��� ������? 
 je   DDIExit  
 
 cmp  byte ptr [edi+1], 1 ; ���ਯ�� ���ன�⢠? 
 jne   DesCon  
;  ����ᥭ�� �  �⥪  ���祭�� �  ���⭮�  ���浪�  ���  ��।�� ��ࠬ��஢ printf

xor  eax, eax  
 mov  al, [edi+17]  
 push  eax  
 mov  al, [edi+16]  
 push  eax  
 mov  al, [edi+15]  
 push  eax  
 mov  al, [edi+14]  
 push  eax  
 mov  al, [edi+12]  
 push  eax  
 mov  al, [edi+13]  
 push  eax  
 mov  al, [edi+10]  
 push  eax  
 mov  al, [edi+11]  
 push  eax  
 mov  al, [edi+8]  
 push  eax  
 mov  al, [edi+9]  
 push  eax  
 mov  al, [edi+7]  
 push  eax  
 mov  al, [edi+6]  
 push  eax  
 mov  al, [edi+5]  
 push  eax  
 mov  al, [edi+4]  
 push  eax  
 mov  al, [edi+2]  
 push  eax  
 mov  al, [edi+3]  
 push  eax  
 call printf, offset msgDevDescr 
 add  esp, 4*17  
 jmp  NextDescr
 
DesCon:  
 cmp  byte ptr [edi+1], 2  ; ���ਯ�� ���䨣��樨? 
 jne  DesInterface  
 xor  eax, eax

mov  al, [edi+8]  
 mov  bl, 2  
 mul  bl             ; �८�ࠧ������ ���祭�� � �� 
 push  eax  
 xor  eax, eax  
 mov  al, [edi+7]  
 push  eax  
 mov  al, [edi+6]  
 push  eax  
 mov  al, [edi+5]  
 push  eax  
 mov  al, [edi+4]  
 push  eax  
 mov  ax, [edi+2]  
 push  eax  
 call printf, offset msgConfDescr 
 add  esp, 4*7    
 jmp  NextDescr

DesInterface:
 cmp  byte ptr [edi+1], 4  ; Interface Descriptor?
 jne  DesHid  
 
xor  eax, eax
 mov  al, [edi+8]  
 push  eax  
 mov  al, [edi+7]  
 push  eax  
 mov  al, [edi+6]  
 push  eax  
 mov  al, [edi+5]  
 push  eax  
 mov  al, [edi+4]  
 push  eax  
 mov  al, [edi+2]  
 push  eax  
 mov  al, [edi+3]  
 push  eax  
 call printf, offset msgInterfaceDescr 
 add  esp, 4*8
 jmp  NextDescr
 
DesHid:
 cmp  byte ptr [edi+1], 21h  ; HID Descriptor?
 jne  DesEndpoint  
 
xor  eax, eax  
 mov  al, [edi+5]  
 push  eax  
 mov  al, [edi+4]  
 push  eax  
 mov  al, [edi+2]  
 push  eax  
 mov  al, [edi+3]  
 push  eax  
 call printf, offset msgHidDescr 
 add  esp, 4*5 
 jmp  NextDescr

DesEndpoint:
 cmp  byte ptr [edi+1], 5  ; Endpoint Descriptor?
 jne  NextDescr
 
xor  eax, eax  
 mov  al, [edi+6]  
 push  eax  
 mov  al, [edi+4]  
 push  eax  
 mov  al, [edi+3]  
 push  eax  
 mov  al, [edi+2]  
 push  eax  
 call printf, offset msgEndpointDescr 
 add  esp, 4*5
 jmp  NextDescr
 
NextDescr:  
 add  edi, esi 
 jmp  Cycle  
DDIExit:  ret  
DisplayDescriptorInfo ENDP 
 
;--- �᭮���� ��� --------------------------------------------------------------------  
Start:  
 call FreeConsole  
 call AllocConsole  
 call GetStdHandle, STD_INPUT_HANDLE 
 mov    hIn, eax  
 call printf, offset msgTitle 
 add   esp, 4*1  ; ���४�஢�� �⥪� ��᫥ printf 
 
; ���� �� �ᥬ ��⠬ 
 mov  iHost, 0  
mNextHost:  
; ��ନ஢���� ����� ���  
 mov  eax, iHost  
 add  eax, '0'  ; ��ॢ�� ����� ��᪠ � ᨬ��� '0', '1' � �.�. 
 mov  NumHost, eax ; �� ����� 9 ��⮢ � ��⥬�

; ����祭�� ���ਯ�� ⥪�饣� ��� 
 call CreateFileA, offset NameHost, GENERIC_WRITE, FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0 
 cmp  eax, -1   ; � ��砥 �訡�� �뢮� ᮮ�饭�� 
 je   mErrorHost  
 mov  hHost, eax  ; ���࠭���� ���ਯ�� � hHost 
 
 call printf, offset msgInitHost, iHost 
 add  esp, 4*2  
 
; ����祭�� PnP-����� ��୥���� 堡� 
 call DeviceIoControl, hHost, IOCTL_USB_GET_ROOT_HUB_NAME, 0, 0, offset DeviceName, size DeviceName, offset bReturned, 0 
 test  eax, eax  
 jz   mError  
 mov  ebx, DeviceName.Length 
 cmp  ebx, bReturned ; �஢�ઠ �� ���������  
 jb   mError   ; ����祭��� �������� � ������ 
 
; ��ନ஢���� ������� ����� ��୥���� 堡� �� PnP-����� 
 mov  ecx, 136  ; ���ᨬ��쭠� ����� ����� 堡� 
 cld         ; �������� �� ��ப� ����� 
 push  ds  
 pop  es  
 lea  esi, DeviceName.Name  ; ����� ᨬ��� �������� 2 ���� 
 lea  edi, SRootHub         ; ����� ᨬ��� �������� 1 ���� 
mLoop:  
 movsb  
 inc  esi  
 loop mLoop  
 
; ����祭�� ���ਯ�� ⥪�饣� ��୥���� 堡� 
 call  CreateFileA, offset NameRootHub, GENERIC_WRITE, FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0 
 cmp  eax, -1  
 jne   mHostCont
 inc iHost
 jmp mNextHost
mHostCont:
 mov  hRootHub, eax ; ���࠭���� ���ਯ�� � hRootHub 
 
; ����祭�� ���ଠ樨 � ��୥��� 堡� 
 mov  NodeInformation.NodeType, 0

call DeviceIoControl, hRootHub, IOCTL_USB_GET_NODE_INFORMATION, offset NodeInformation, size NodeInformation, offset NodeInformation, size NodeInformation, offset bReturned, 0 
 test  eax, eax  
 jz   mError  
 
 xor  ebx, ebx ; ebx ? �᫮ ���⮢ 堡� 
 movzx ebx, NodeInformation.HubInformation.HubDescriptor.bNumberOfPorts 
 call printf, offset msgHubInfo, ebx 
 add  esp, 4*2  
 
; ��ॡ�� ��� ���⮢ 堡�  
 mov  iPort, 1  
mNextPort:  
 call ShowHubPortDetail, hRootHub, iPort; 
 test  eax, eax  
 jz  mError  
 
 inc  iPort  
 cmp  ebx, iPort  
 jnb  mNextPort  
 
 call  CloseHandle, hRootHub 
 call  CloseHandle, hHost 
 inc  iHost  
 jmp  mNextHost  
 
mErrorHost:   ; �뢮� ��᫥����� ᮮ�饭�� 
 call printf, offset msgExit 
 add  esp, 4*1  
 jmp  mWait  
 
mError:    ; ��ࠡ�⪠ �訡�� 
 call GetLastError  
 call printf, offset msgError, eax 
 add  esp, 4*2  
 cmp  hRootHub, 0  
 je   mWait  
 call  CloseHandle, hRootHub

call  CloseHandle, hHost 
 
mWait:     ; �������� ������ ������ 
 call ReadConsoleInputA, hIn, offset CBuffer, 1, offset NumEvent 
 cmp  CBuffer.EventType, Key_Event 
 jne  mWait ; ����⨥ �� ����������? 
 
mExit:     ; ��室 �� �ணࠬ�� 
 call  CloseHandle, hIn 
 call FreeConsole  
 call ExitProcess, 0  
END Start
