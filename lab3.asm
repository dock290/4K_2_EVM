TITLE SMART
;32-х разрядное приложение получения значений S.M.A.R.T. атрибута
;жесткого диска.
;Программа выводит в текущую консоль номер атрибута и его описание,
;текущее нормированное, худшее, пороговое и необработанное значения для
;каждого диска.
.386 ;Расширенная система команд.
;Плоская модель памяти и стандартная модель вызова подпрограмм.
.MODEL FLAT, STDCALL
;Директивы компоновщику для подключения библиотек.
INCLUDELIB import32.lib ;Работа с библиотекой ОС Kernel32.
;--- Внешние WinAPI-функции -------------------------------------------------------------
EXTRN CreateFileA: PROC ;Получить дескриптор устройства.
EXTRN DeviceIoControl: PROC ;Получить информацию об устройстве.
EXTRN CloseHandle: PROC ;Закрыть дескриптор устройства.
EXTRN printf: PROC ;Вывести текст по шаблону.
EXTRN RtlZeroMemory: PROC ;Очистить память.
EXTRN ExitProcess: PROC ;Завершить процесс.
;--- Константы и структуры -----------------------------------------------------------------
;стандартные значения WinApi
GENERIC_READ = 80000000h ;допускается чтение
GENERIC_WRITE = 40000000h ;допускается запись
FILE_SHARE_READ = 1 ;допускается чтение другими процессами
FILE_SHARE_WRITE = 2 ;допускается запись другими процессами
OPEN_EXISTING = 3 ;предписывает открывать устройство,
;если оно существует
READ_ATTRIBUTE_BUFFER_SIZE = 512 ;размер буфера атрибутов
READ_THRESHOLD_BUFFER_SIZE = 512 ;размер буфера пороговых значений
DFP_SEND_DRIVE_COMMAND = 0007C084h ;управляющие коды для
DFP_RECEIVE_DRIVE_DATA = 0007C088h ;функции DeviceIOControl
IDE_SMART_ENABLE = 0D8h ;запрос на активацию S.M.A.R.T.
IDE_SMART_READ_ATTRIBUTES = 0D0h ;запрос на чтение атрибутов
IDE_SMART_READ_THRESHOLDS = 0D1h ;запрос на чтение порогового значения
IDE_COMMAND_SMART = 0B0h ;команда IDE для работы со S.M.A.R.T.
SMART_CYL_LOW = 4Fh ;младший байт цилиндра для S.M.A.R.T.
SMART_CYL_HI = 0C2h ;старший байт цилиндра для S.M.A.R.T.
ATTR_NAME equ <'Raw Read Error Rate'> ;название атрибута
; Структура записи регистров IDE
IDERegs STRUC
bFeaturesReg db ? ;регистр подкоманды SMART
bSectorCountReg db ? ;регистр количества секторов IDE
bSectorNumberReg db ? ;регистр номера сектора IDE
bCylLowReg db ? ;младший разряд номера цилиндра IDE
bCylHighReg db ? ;старший разряд номера цилиндра IDE
bDriveHeadReg db ? ;регистр номера диска/головки IDE
bCommandReg db ? ;фактическая команда IDE
db ? ;зарезервировано. Должен быть 0
IDERegs ENDS
; Структура записи входных параметров для функции DeviceIOControl
SendCmdInParams STRUC
    cBufferSize dd ? ;размер буфера в байтах
    irDriveRegs IDERegs <> ;структура со значениями регистров диска
    bDriveNumber db ? ;физ. номер диска для посылки команд SMART
    db 3 dup (?) ;зарезервировано
    dd 4 dup (?) ;зарезервировано
    bInBuffer label byte ;входной буфер
SendCmdInParams ENDS
; Структура состояния диска
DriverStatus STRUC
    bDriverError db ? ;код ошибки драйвера
    bIDEStatus db ? ;содержит значение регистра ошибки IDE
    ;контроллера, только когда bDriverError = 1
    db 2 dup (?) ;зарезервировано
    dd 2 dup (?) ;зарезервировано
DriverStatus ENDS
; Структура записи параметров, возвращаемых функцией DeviceIOControl
SendCmdOutParams STRUC
    cBufferSize dd ? ;размер буфера в байтах
    DrvStatus DriverStatus <> ;структура состояния диска
    bOutBuffer label byte ;буфер произвольной длины для хранения
    ;данных, полученных от диска
SendCmdOutParams ENDS
; Структура записи значений атрибутов
DriveAttribute STRUC
bAttrID db ? ;идентификатор атрибута
wStatusFlags dw ? ;флаг состояния
bAttrValue db ? ;текущее нормализованное значение
bWorstValue db ? ;худшее значение
bRawValue db 6 dup (?) ;текущее ненормализованное значение
db ? ;зарезервирован
DriveAttribute ENDS
; Структура записи порогового значения атрибута
AttrThreshold STRUC
bAttrID db ? ; идентификатор атрибута
bWarrantyThreshold db ? ; пороговое значение
db 10 dup (?) ; зарезервировано
AttrThreshold ENDS
;--- Данные -------------------------------------------------------------------------------------
.DATA
    sDrive DB '\\.\PhysicalDrive' ; имя устройства,
    cDrive DB '0', 0 ; включая его номер
    msgSMART DB 'Чтение значений S.M.A.R.T. атрибута '
    DB 'всех подключенных дисков...', 13, 10, 0
    msgNoSMART DB 'HDD%u не поддерживает '
    DB 'технологию S.M.A.R.T.!', 13, 10, 0
    msgNoAttr DB 13, 10, 'Атрибут ',ATTR_NAME,' для HDD%u '
    DB 'не найден!',13,10,0
    msgNoDrives DB 13, 10, 'Не удалось открыть ни одного устройства '
    DB '(видимо, у Вас нет прав администратора)', 13, 10, 0
    msgSMARTInfo DB 13, 10, 'Значения атрибута для HDD%u', 13, 10
    DB 'Attribute number = %u (', ATTR_NAME, ')', 13, 10
    DB ' Attribute value = %u', 13, 10
    DB ' Worst value = %u', 13, 10
    DB ' Threshold value = %u', 13, 10
    DB ' RAW value = %02X %02X %02X %02X %02X %02X (hex)', 13, 10, 0
    drvHandle DD ? ;дескриптор устройства
    SCIP SendCmdInParams <> ;указатель на структуру входных параметров
    SCOP SendCmdOutParams <> ;указатель на структуру выходных параметров
    DB 512 dup (?) ;зарезервированное место для буфера
    bReturned DD ? ;число байт, возвращённых функцией
    drvAttr DriveAttribute <> ;указатель на структуру значений атрибута
    drvThres AttrThreshold <> ;указатель на структуру с пороговым значением
;--- Основной код -----------------------------------------------------------------------------
.CODE
Start:
    call printf, offset msgSMART ;Выводим приветствие.
    add esp, 4*2 ;Корректируем стек.
    xor esi, esi ;esi - счетчик успешно открытых устройств
    mov ebx, 0 ;ebx - номер текущего диска
mNextDrive:
    call InitSMART, ebx ;Активация S.M.A.R.T.
    test eax, eax ;Проверяем результат.
    js mNoDrive ;Переходим, если диск открыть не удалось (eax = -1).
    jz mNoSMART ;Переходим, если ошибка (eax = 0).
    ; Чтение S.M.A.R.T. атрибутов
    call ReadSMARTAttr, ebx, offset drvAttr, offset drvThres, 1
    test eax, eax ;Проверяем результат
    jz mNoSMART ;Переходим, если ошибка (eax = 0)
    js mNoAttr ;Переходим, если атрибут не найден (eax = -1)
    inc esi ;Увеличиваем значение счетчика открытых устройств.
    ; Заносим в стек значения в обратном порядке для передачи параметров printf
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
    call printf, offset msgSMARTInfo ;Выводим значения атрибута.
    add esp, 4*12
    ; Чтение S.M.A.R.T. атрибутов
    call ReadSMARTAttr, ebx, offset drvAttr, offset drvThres, 194
    test eax, eax ;Проверяем результат
    jz mNoSMART ;Переходим, если ошибка (eax = 0)
    js mNoAttr ;Переходим, если атрибут не найден (eax = -1)
    inc esi ;Увеличиваем значение счетчика открытых устройств.
    ; Заносим в стек значения в обратном порядке для передачи параметров printf
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
    call printf, offset msgSMARTInfo ;Выводим значения атрибута.
    add esp, 4*12
mClose:
    call CloseHandle, drvHandle ;Закрываем устройство.
mNoDrive:
    inc ebx ;Увеличиваем номер диска.
    cmp ebx, 10 ;Сравниваем его с максимальным.
    jbe mNextDrive ;Повторяем цикл, если он не превышает 10
    test esi, esi ;Проверяем кол-во успешно открытых устройств.
    jnz mExit ;Переходим, если их больше 0,
    call printf, offset msgNoDrives ;иначе выводим сообщение об ошибке.
    add esp, 4*1
mExit:
    call ExitProcess, 0 ;Выходим из программы.
mNoAttr: ;В случае ошибки чтения атрибута
    call printf, offset msgNoAttr, ebx ;выводим сообщение об ошибке.
    add esp, 4*2
    jmp mClose
mNoSMART: ;В случае ошибки активации S.M.A.R.T.
    call printf, offset msgNoSMART, ebx ;выводим сообщение об ошибке.
    add esp, 4*2
    jmp mClose
;=== Активация S.M.A.R.T. для диска номер Drive =====================
; Возвращает EAX = 1 - успешное завершение, 0 - ошибка (нет прав),
; -1 - диск не найден
InitSMART PROC
    ARG Drive: DWORD
    mov al, byte ptr Drive
    add al, '0' ;Превращаем номер диска в символ '0', '1' и т.д.
    mov cDrive, al ;Сохраняем его в cDrive (корректируем строку sDrive)
    ; Получаем дескриптор диска
    call CreateFileA, offset sDrive, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0
    cmp eax, -1 ;В случае ошибки
    je mISExit ;выходим, возвращая -1
    mov drvHandle, eax ;Сохраняем дескриптор в drvHandle
    ; Подготавливаем буфер SCIP для активации S.M.A.R.T
    call InitSMARTInBuf, Drive, IDE_SMART_ENABLE, offset SCIP, 0
    ; Активируем S.M.A.R.T. для текущего диска
    call DeviceIoControl, drvHandle, DFP_SEND_DRIVE_COMMAND, offset SCIP, size SCIP, offset SCOP, size SCOP, offset bReturned, 0
    test eax, eax ;Проверяем успешное выполнение команды
    jz mISExit ;В случае ошибки возвращаем 0,
    mov eax, 1 ;иначе 1.
mISExit: ret
InitSMART ENDP
;=== Чтение значений S.M.A.R.T. атрибута =========================
; DriveAttr и AttrThres ? буферы для значений атрибута,
; Drive ? номер диска.
; Возвращает EAX <> 1 - успешное завершение, 0 - ошибка (нет прав),
; -1 - атрибут не найден.
ReadSMARTAttr PROC
    ARG Drive: DWORD, DriveAttr: DWORD, AttrThres: DWORD, Attrib: BYTE
    uses esi, edi ;Сохраняем значения регистров в стеке
    ; Определяем размер буферов под значения атрибутов
    ATTR_SIZE=size SendCmdOutParams+READ_ATTRIBUTE_BUFFER_SIZE
    THRES_SIZE=size SendCmdOutParams+READ_THRESHOLD_BUFFER_SIZE
    ; Очищаем буферы для значений атрибута.
    call RtlZeroMemory, DriveAttr, size DriveAttribute
    call RtlZeroMemory, AttrThres, size AttrThreshold
    ; Подготавливаем буфер SCIP для чтения атрибутов S.M.A.R.T.
    call InitSMARTInBuf, Drive, IDE_SMART_READ_ATTRIBUTES, offset SCIP, READ_ATTRIBUTE_BUFFER_SIZE
    ; Читаем значения атрибутов
    call DeviceIoControl, drvHandle, DFP_RECEIVE_DRIVE_DATA, offset SCIP, size SCIP, offset SCOP, ATTR_SIZE, offset bReturned, 0
    test eax, eax ;Проверяем успешное выполнение команды
    jz mRSExit ;В случае ошибки возвращаем 0.
    ; Буфер SCOP.bOutBuffer содержит идущие друг за другом значения в
    ; формате структуры DriveAttribute, начиная со 2-го байта
    mov esi, offset SCOP.bOutBuffer[2]
    mov ecx, 30
mNextAttr:
    lodsb ;Загружаем элемент строки [DS:SI] в AL
    ;cmp al, 194
    ;je mFoundAttr
    ;cmp al, 231
    ;je mFoundAttr
    cmp al, Attrib
    je mFoundAttr
    add esi, size DriveAttribute-1
    loop mNextAttr
    mov eax, -1 ;Если атрибут не найден, возвращаем -1.
    jmp mRSExit
mFoundAttr:
    dec esi ;Корректируем адрес найденной
    ;структуры, после команды lodsb
    mov edi, DriveAttr ;edi = буфер для копирования данных
    mov ecx, size DriveAttribute ;ecx = размер данных
    rep movsb ;Копируем данные в буфер.
    ; Подготавливаем буфер SCIP для чтения пороговых значений S.M.A.R.T.
    call InitSMARTInBuf, Drive, IDE_SMART_READ_THRESHOLDS, offset SCIP, READ_THRESHOLD_BUFFER_SIZE
    ; Читаем пороговые значения
    call DeviceIoControl, drvHandle, DFP_RECEIVE_DRIVE_DATA, offset SCIP, size SCIP, offset SCOP, THRES_SIZE, offset bReturned, 0
    test eax, eax ;Проверяем успешное выполнение команды
    jz mRSExit ;В случае ошибки возвращаем 0.
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
    mov eax, 1 ;Возвращаем 1 (успех).
mRSExit: ret
ReadSMARTAttr ENDP
;=== Инициализация структуры SendCmdInParams ====================
; Drive ? номер диска, Feature ? номер функции,
; Buffer ? указатель на структуры данных, AddSize ? размер буфера.
InitSMARTInBuf PROC
    ARG Drive:DWORD, Feature:DWORD, Buffer:DWORD, AddSize:DWORD
    mov eax, AddSize
    push eax
    ; Вычисляем размер буфера для чтения параметров
    add eax, size SendCmdInParams
    call RtlZeroMemory, Buffer, eax ;Очищаем буфер.
    pop eax ;eax = AddSize
    mov SCIP.cBufferSize, eax ;Записываем размер буфера.
    mov eax, Feature ;Записываем номер функции.
    mov SCIP.irDriveRegs.bFeaturesReg, al
    mov SCIP.irDriveRegs.bSectorCountReg, 1
    mov SCIP.irDriveRegs.bSectorNumberReg, 1
    mov SCIP.irDriveRegs.bCylLowReg, SMART_CYL_LOW
    mov SCIP.irDriveRegs.bCylHighReg, SMART_CYL_HI
    mov al, byte ptr Drive
    mov SCIP.bDriveNumber, al
    ;Вычисляем номер диска/головки
    and al, 1
    shl al, 4
    or al, 0A0h
    mov SCIP.irDriveRegs.bDriveHeadReg, al
    mov SCIP.irDriveRegs.bCommandReg, IDE_COMMAND_SMART
    ret
InitSMARTInBuf ENDP
END Start
