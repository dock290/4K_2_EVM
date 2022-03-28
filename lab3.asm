TITLE SMART
;32-� ࠧ�來�� �ਫ������ ����祭�� ���祭�� S.M.A.R.T. ��ਡ��
;���⪮�� ��᪠.
;�ணࠬ�� �뢮��� � ⥪���� ���᮫� ����� ��ਡ�� � ��� ���ᠭ��,
;⥪�饥 ��ନ஢�����, ��襥, ��ண���� � ����ࠡ�⠭��� ���祭�� ���
;������� ��᪠.
.386 ;����७��� ��⥬� ������.
;���᪠� ������ ����� � �⠭���⭠� ������ �맮�� ����ணࠬ�.
.MODEL FLAT, STDCALL
;��४⨢� ��������騪� ��� ������祭�� ������⥪.
INCLUDELIB import32.lib ;����� � ������⥪�� �� Kernel32.
;--- ���譨� WinAPI-�㭪樨 -------------------------------------------------------------
EXTRN CreateFileA: PROC ;������� ���ਯ�� ���ன�⢠.
EXTRN DeviceIoControl: PROC ;������� ���ଠ�� �� ���ன�⢥.
EXTRN CloseHandle: PROC ;������� ���ਯ�� ���ன�⢠.
EXTRN printf: PROC ;�뢥�� ⥪�� �� 蠡����.
EXTRN RtlZeroMemory: PROC ;������ ������.
EXTRN ExitProcess: PROC ;�������� �����.
;--- ����⠭�� � �������� -----------------------------------------------------------------
;�⠭����� ���祭�� WinApi
GENERIC_READ = 80000000h ;����᪠���� �⥭��
GENERIC_WRITE = 40000000h ;����᪠���� ������
FILE_SHARE_READ = 1 ;����᪠���� �⥭�� ��㣨�� ����ᠬ�
FILE_SHARE_WRITE = 2 ;����᪠���� ������ ��㣨�� ����ᠬ�
OPEN_EXISTING = 3 ;�।���뢠�� ���뢠�� ���ன�⢮,
;�᫨ ��� �������
READ_ATTRIBUTE_BUFFER_SIZE = 512 ;ࠧ��� ���� ��ਡ�⮢
READ_THRESHOLD_BUFFER_SIZE = 512 ;ࠧ��� ���� ��ண���� ���祭��
DFP_SEND_DRIVE_COMMAND = 0007C084h ;�ࠢ���騥 ���� ���
DFP_RECEIVE_DRIVE_DATA = 0007C088h ;�㭪樨 DeviceIOControl
IDE_SMART_ENABLE = 0D8h ;����� �� ��⨢��� S.M.A.R.T.
IDE_SMART_READ_ATTRIBUTES = 0D0h ;����� �� �⥭�� ��ਡ�⮢
IDE_SMART_READ_THRESHOLDS = 0D1h ;����� �� �⥭�� ��ண����� ���祭��
IDE_COMMAND_SMART = 0B0h ;������� IDE ��� ࠡ��� � S.M.A.R.T.
SMART_CYL_LOW = 4Fh ;����訩 ���� 樫���� ��� S.M.A.R.T.
SMART_CYL_HI = 0C2h ;���訩 ���� 樫���� ��� S.M.A.R.T.
ATTR_NAME equ <'Raw Read Error Rate'> ;�������� ��ਡ��
; ������� ����� ॣ���஢ IDE
IDERegs STRUC
bFeaturesReg db ? ;ॣ���� ���������� SMART
bSectorCountReg db ? ;ॣ���� ������⢠ ᥪ�஢ IDE
bSectorNumberReg db ? ;ॣ���� ����� ᥪ�� IDE
bCylLowReg db ? ;����訩 ࠧ�� ����� 樫���� IDE
bCylHighReg db ? ;���訩 ࠧ�� ����� 樫���� IDE
bDriveHeadReg db ? ;ॣ���� ����� ��᪠/������� IDE
bCommandReg db ? ;䠪��᪠� ������� IDE
db ? ;��१�ࢨ஢���. ������ ���� 0
IDERegs ENDS
; ������� ����� �室��� ��ࠬ��஢ ��� �㭪樨 DeviceIOControl
SendCmdInParams STRUC
    cBufferSize dd ? ;ࠧ��� ���� � �����
    irDriveRegs IDERegs <> ;������� � ���祭�ﬨ ॣ���஢ ��᪠
    bDriveNumber db ? ;䨧. ����� ��᪠ ��� ���뫪� ������ SMART
    db 3 dup (?) ;��१�ࢨ஢���
    dd 4 dup (?) ;��१�ࢨ஢���
    bInBuffer label byte ;�室��� ����
SendCmdInParams ENDS
; ������� ���ﭨ� ��᪠
DriverStatus STRUC
    bDriverError db ? ;��� �訡�� �ࠩ���
    bIDEStatus db ? ;ᮤ�ন� ���祭�� ॣ���� �訡�� IDE
    ;����஫���, ⮫쪮 ����� bDriverError = 1
    db 2 dup (?) ;��१�ࢨ஢���
    dd 2 dup (?) ;��१�ࢨ஢���
DriverStatus ENDS
; ������� ����� ��ࠬ��஢, �����頥��� �㭪樥� DeviceIOControl
SendCmdOutParams STRUC
    cBufferSize dd ? ;ࠧ��� ���� � �����
    DrvStatus DriverStatus <> ;������� ���ﭨ� ��᪠
    bOutBuffer label byte ;���� �ந����쭮� ����� ��� �࠭����
    ;������, ����祭��� �� ��᪠
SendCmdOutParams ENDS
; ������� ����� ���祭�� ��ਡ�⮢
DriveAttribute STRUC
bAttrID db ? ;�����䨪��� ��ਡ��
wStatusFlags dw ? ;䫠� ���ﭨ�
bAttrValue db ? ;⥪�饥 ��ଠ���������� ���祭��
bWorstValue db ? ;��襥 ���祭��
bRawValue db 6 dup (?) ;⥪�饥 ����ଠ���������� ���祭��
db ? ;��१�ࢨ஢��
DriveAttribute ENDS
; ������� ����� ��ண����� ���祭�� ��ਡ��
AttrThreshold STRUC
bAttrID db ? ; �����䨪��� ��ਡ��
bWarrantyThreshold db ? ; ��ண���� ���祭��
db 10 dup (?) ; ��१�ࢨ஢���
AttrThreshold ENDS
;--- ����� -------------------------------------------------------------------------------------
.DATA
    sDrive DB '\\.\PhysicalDrive' ; ��� ���ன�⢠,
    cDrive DB '0', 0 ; ������ ��� �����
    msgSMART DB '�⥭�� ���祭�� S.M.A.R.T. ��ਡ�� '
    DB '��� ������祭��� ��᪮�...', 13, 10, 0
    msgNoSMART DB 'HDD%u �� �����ন���� '
    DB '�孮����� S.M.A.R.T.!', 13, 10, 0
    msgNoAttr DB 13, 10, '��ਡ�� ',ATTR_NAME,' ��� HDD%u '
    DB '�� ������!',13,10,0
    msgNoDrives DB 13, 10, '�� 㤠���� ������ �� ������ ���ன�⢠ '
    DB '(������, � ��� ��� �ࠢ �����������)', 13, 10, 0
    msgSMARTInfo DB 13, 10, '���祭�� ��ਡ�� ��� HDD%u', 13, 10
    DB 'Attribute number = %u (', ATTR_NAME, ')', 13, 10
    DB ' Attribute value = %u', 13, 10
    DB ' Worst value = %u', 13, 10
    DB ' Threshold value = %u', 13, 10
    DB ' RAW value = %02X %02X %02X %02X %02X %02X (hex)', 13, 10, 0
    drvHandle DD ? ;���ਯ�� ���ன�⢠
    SCIP SendCmdInParams <> ;㪠��⥫� �� �������� �室��� ��ࠬ��஢
    SCOP SendCmdOutParams <> ;㪠��⥫� �� �������� ��室��� ��ࠬ��஢
    DB 512 dup (?) ;��१�ࢨ஢����� ���� ��� ����
    bReturned DD ? ;�᫮ ����, ��������� �㭪樥�
    drvAttr DriveAttribute <> ;㪠��⥫� �� �������� ���祭�� ��ਡ��
    drvThres AttrThreshold <> ;㪠��⥫� �� �������� � ��ண��� ���祭���
;--- �᭮���� ��� -----------------------------------------------------------------------------
.CODE
Start:
    call printf, offset msgSMART ;�뢮��� �ਢ���⢨�.
    add esp, 4*2 ;���४��㥬 �⥪.
    xor esi, esi ;esi - ���稪 �ᯥ譮 ������� ���ன��
    mov ebx, 0 ;ebx - ����� ⥪�饣� ��᪠
mNextDrive:
    call InitSMART, ebx ;��⨢��� S.M.A.R.T.
    test eax, eax ;�஢��塞 १����.
    js mNoDrive ;���室��, �᫨ ��� ������ �� 㤠���� (eax = -1).
    jz mNoSMART ;���室��, �᫨ �訡�� (eax = 0).
    ; �⥭�� S.M.A.R.T. ��ਡ�⮢
    call ReadSMARTAttr, ebx, offset drvAttr, offset drvThres, 1
    test eax, eax ;�஢��塞 १����
    jz mNoSMART ;���室��, �᫨ �訡�� (eax = 0)
    js mNoAttr ;���室��, �᫨ ��ਡ�� �� ������ (eax = -1)
    inc esi ;�����稢��� ���祭�� ���稪� ������� ���ன��.
    ; ����ᨬ � �⥪ ���祭�� � ���⭮� ���浪� ��� ��।�� ��ࠬ��஢ printf
    movzx eax, drvAttr.bRawValue[0]
    push eax
    movzx eax, drvAttr.bRawValue[1]
    push eax
    movzx eax, drvAttr.bRawValue[2]
    push eax
    movzx eax, drvAttr.bRawValue[3]
    push eax
    movzx eax, drvAttr.bRawValue[4]
    push eax
    movzx eax, drvAttr.bRawValue[5]
    push eax
    movzx eax, drvThres.bWarrantyThreshold
    push eax
    movzx eax, drvAttr.bWorstValue
    push eax
    movzx eax,drvAttr.bAttrValue
    push eax
    movzx eax,drvAttr.bAttrID
    push eax
    push ebx
    call printf, offset msgSMARTInfo ;�뢮��� ���祭�� ��ਡ��.
    add esp, 4*12
    ; �⥭�� S.M.A.R.T. ��ਡ�⮢
    call ReadSMARTAttr, ebx, offset drvAttr, offset drvThres, 194
    test eax, eax ;�஢��塞 १����
    jz mNoSMART ;���室��, �᫨ �訡�� (eax = 0)
    js mNoAttr ;���室��, �᫨ ��ਡ�� �� ������ (eax = -1)
    inc esi ;�����稢��� ���祭�� ���稪� ������� ���ன��.
    ; ����ᨬ � �⥪ ���祭�� � ���⭮� ���浪� ��� ��।�� ��ࠬ��஢ printf
    movzx eax, drvAttr.bRawValue[0]
    push eax
    movzx eax, drvAttr.bRawValue[1]
    push eax
    movzx eax, drvAttr.bRawValue[2]
    push eax
    movzx eax, drvAttr.bRawValue[3]
    push eax
    movzx eax, drvAttr.bRawValue[4]
    push eax
    movzx eax, drvAttr.bRawValue[5]
    push eax
    movzx eax, drvThres.bWarrantyThreshold
    push eax
    movzx eax, drvAttr.bWorstValue
    push eax
    movzx eax,drvAttr.bAttrValue
    push eax
    movzx eax,drvAttr.bAttrID
    push eax
    push ebx
    call printf, offset msgSMARTInfo ;�뢮��� ���祭�� ��ਡ��.
    add esp, 4*12
mClose:
    call CloseHandle, drvHandle ;����뢠�� ���ன�⢮.
mNoDrive:
    inc ebx ;�����稢��� ����� ��᪠.
    cmp ebx, 10 ;�ࠢ������ ��� � ���ᨬ����.
    jbe mNextDrive ;�����塞 横�, �᫨ �� �� �ॢ�蠥� 10
    test esi, esi ;�஢��塞 ���-�� �ᯥ譮 ������� ���ன��.
    jnz mExit ;���室��, �᫨ �� ����� 0,
    call printf, offset msgNoDrives ;���� �뢮��� ᮮ�饭�� �� �訡��.
    add esp, 4*1
mExit:
    call ExitProcess, 0 ;��室�� �� �ணࠬ��.
mNoAttr: ;� ��砥 �訡�� �⥭�� ��ਡ��
    call printf, offset msgNoAttr, ebx ;�뢮��� ᮮ�饭�� �� �訡��.
    add esp, 4*2
    jmp mClose
mNoSMART: ;� ��砥 �訡�� ��⨢�樨 S.M.A.R.T.
    call printf, offset msgNoSMART, ebx ;�뢮��� ᮮ�饭�� �� �訡��.
    add esp, 4*2
    jmp mClose
;=== ��⨢��� S.M.A.R.T. ��� ��᪠ ����� Drive =====================
; �����頥� EAX = 1 - �ᯥ譮� �����襭��, 0 - �訡�� (��� �ࠢ),
; -1 - ��� �� ������
InitSMART PROC
    ARG Drive: DWORD
    mov al, byte ptr Drive
    add al, '0' ;�ॢ�頥� ����� ��᪠ � ᨬ��� '0', '1' � �.�.
    mov cDrive, al ;���࠭塞 ��� � cDrive (���४��㥬 ��ப� sDrive)
    ; ����砥� ���ਯ�� ��᪠
    call CreateFileA, offset sDrive, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0
    cmp eax, -1 ;� ��砥 �訡��
    je mISExit ;��室��, ������� -1
    mov drvHandle, eax ;���࠭塞 ���ਯ�� � drvHandle
    ; �����⠢������ ���� SCIP ��� ��⨢�樨 S.M.A.R.T
    call InitSMARTInBuf, Drive, IDE_SMART_ENABLE, offset SCIP, 0
    ; ��⨢��㥬 S.M.A.R.T. ��� ⥪�饣� ��᪠
    call DeviceIoControl, drvHandle, DFP_SEND_DRIVE_COMMAND, offset SCIP, size SCIP, offset SCOP, size SCOP, offset bReturned, 0
    test eax, eax ;�஢��塞 �ᯥ譮� �믮������ �������
    jz mISExit ;� ��砥 �訡�� �����頥� 0,
    mov eax, 1 ;���� 1.
mISExit: ret
InitSMART ENDP
;=== �⥭�� ���祭�� S.M.A.R.T. ��ਡ�� =========================
; DriveAttr � AttrThres ? ����� ��� ���祭�� ��ਡ��,
; Drive ? ����� ��᪠.
; �����頥� EAX <> 1 - �ᯥ譮� �����襭��, 0 - �訡�� (��� �ࠢ),
; -1 - ��ਡ�� �� ������.
ReadSMARTAttr PROC
    ARG Drive: DWORD, DriveAttr: DWORD, AttrThres: DWORD, Attrib: BYTE
    uses esi, edi ;���࠭塞 ���祭�� ॣ���஢ � �⥪�
    ; ��।��塞 ࠧ��� ���஢ ��� ���祭�� ��ਡ�⮢
    ATTR_SIZE=size SendCmdOutParams+READ_ATTRIBUTE_BUFFER_SIZE
    THRES_SIZE=size SendCmdOutParams+READ_THRESHOLD_BUFFER_SIZE
    ; ��頥� ����� ��� ���祭�� ��ਡ��.
    call RtlZeroMemory, DriveAttr, size DriveAttribute
    call RtlZeroMemory, AttrThres, size AttrThreshold
    ; �����⠢������ ���� SCIP ��� �⥭�� ��ਡ�⮢ S.M.A.R.T.
    call InitSMARTInBuf, Drive, IDE_SMART_READ_ATTRIBUTES, offset SCIP, READ_ATTRIBUTE_BUFFER_SIZE
    ; ��⠥� ���祭�� ��ਡ�⮢
    call DeviceIoControl, drvHandle, DFP_RECEIVE_DRIVE_DATA, offset SCIP, size SCIP, offset SCOP, ATTR_SIZE, offset bReturned, 0
    test eax, eax ;�஢��塞 �ᯥ譮� �믮������ �������
    jz mRSExit ;� ��砥 �訡�� �����頥� 0.
    ; ���� SCOP.bOutBuffer ᮤ�ন� ���騥 ��� �� ��㣮� ���祭�� �
    ; �ଠ� �������� DriveAttribute, ��稭�� � 2-�� ����
    mov esi, offset SCOP.bOutBuffer[2]
    mov ecx, 30
mNextAttr:
    lodsb ;����㦠�� ����� ��ப� [DS:SI] � AL
    ;cmp al, 194
    ;je mFoundAttr
    ;cmp al, 231
    ;je mFoundAttr
    cmp al, Attrib
    je mFoundAttr
    add esi, size DriveAttribute-1
    loop mNextAttr
    mov eax, -1 ;�᫨ ��ਡ�� �� ������, �����頥� -1.
    jmp mRSExit
mFoundAttr:
    dec esi ;���४��㥬 ���� ���������
    ;��������, ��᫥ ������� lodsb
    mov edi, DriveAttr ;edi = ���� ��� ����஢���� ������
    mov ecx, size DriveAttribute ;ecx = ࠧ��� ������
    rep movsb ;�����㥬 ����� � ����.
    ; �����⠢������ ���� SCIP ��� �⥭�� ��ண���� ���祭�� S.M.A.R.T.
    call InitSMARTInBuf, Drive, IDE_SMART_READ_THRESHOLDS, offset SCIP, READ_THRESHOLD_BUFFER_SIZE
    ; ��⠥� ��ண��� ���祭��
    call DeviceIoControl, drvHandle, DFP_RECEIVE_DRIVE_DATA, offset SCIP, size SCIP, offset SCOP, THRES_SIZE, offset bReturned, 0
    test eax, eax ;�஢��塞 �ᯥ譮� �믮������ �������
    jz mRSExit ;� ��砥 �訡�� �����頥� 0.
    mov esi, offset SCOP.bOutBuffer[2]
    mov ecx, 30
mNextThres:
    lodsb
    cmp al, 194
    je mFoundThres
    cmp al, 231
    je mFoundThres
    add esi, size AttrThreshold-1
    loop mNextThres
    mov eax, -1
    jmp mRSExit
mFoundThres:
    dec esi
    mov edi, AttrThres
    mov ecx, size AttrThreshold
    rep movsb
    mov eax, 1 ;�����頥� 1 (�ᯥ�).
mRSExit: ret
ReadSMARTAttr ENDP
;=== ���樠������ �������� SendCmdInParams ====================
; Drive ? ����� ��᪠, Feature ? ����� �㭪樨,
; Buffer ? 㪠��⥫� �� �������� ������, AddSize ? ࠧ��� ����.
InitSMARTInBuf PROC
    ARG Drive:DWORD, Feature:DWORD, Buffer:DWORD, AddSize:DWORD
    mov eax, AddSize
    push eax
    ; ����塞 ࠧ��� ���� ��� �⥭�� ��ࠬ��஢
    add eax, size SendCmdInParams
    call RtlZeroMemory, Buffer, eax ;��頥� ����.
    pop eax ;eax = AddSize
    mov SCIP.cBufferSize, eax ;�����뢠�� ࠧ��� ����.
    mov eax, Feature ;�����뢠�� ����� �㭪樨.
    mov SCIP.irDriveRegs.bFeaturesReg, al
    mov SCIP.irDriveRegs.bSectorCountReg, 1
    mov SCIP.irDriveRegs.bSectorNumberReg, 1
    mov SCIP.irDriveRegs.bCylLowReg, SMART_CYL_LOW
    mov SCIP.irDriveRegs.bCylHighReg, SMART_CYL_HI
    mov al, byte ptr Drive
    mov SCIP.bDriveNumber, al
    ;����塞 ����� ��᪠/�������
    and al, 1
    shl al, 4
    or al, 0A0h
    mov SCIP.irDriveRegs.bDriveHeadReg, al
    mov SCIP.irDriveRegs.bCommandReg, IDE_COMMAND_SMART
    ret
InitSMARTInBuf ENDP
END Start
