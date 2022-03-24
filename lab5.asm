TITLE USBView32 
;32-х разрядное приложение для вывода в консольное окно  
; дескрипторов всех подключенных USB устройств. 
 
.386  
; Плоская модель памяти и стандартная модель вызова подпрограмм. 
.MODEL FLAT, STDCALL  
 
; Директивы компоновщику для подключения библиотек. 
INCLUDELIB import32.lib ; Работа с библиотекой ОС Kernel32. 
 
;--- Внешние WinAPI-функций -------------------------------------------------- 
EXTRN FreeConsole:    PROC ; Освободить текущую консоль 
EXTRN AllocConsole:  PROC ; Создать свою консоль 
EXTRN GetStdHandle:  PROC ; Получить дескриптор текущей консоли 
EXTRN printf:       PROC ; Вывести по шаблону 
EXTRN CreateFileA:      PROC ; Получить дескриптор ресурса 
EXTRN DeviceIoControl: PROC ; Получить информацию об устройстве 
EXTRN RtlZeroMemory:  PROC ; Очистить память 
EXTRN ReadConsoleInputA: PROC ; Получить события консоли 
EXTRN GetLastError:   PROC ; Получить код ошибки 
EXTRN CloseHandle:    PROC ; Закрыть дескриптор

EXTRN ExitProcess:   PROC ; Завершить процесс 
 
;--- Константы ----------------------------------------------------------------------- 
GENERIC_WRITE  = 40000000h ; допускается запись 
FILE_SHARE_WRITE  = 2   ; допускается запись другими процессами 
OPEN_EXISTING  = 3   ; предписывает открывать устройство, 
;если оно существует 
STD_INPUT_HANDLE = -10 ; консольное окно для ввода данных 
USB_REQUEST_GET_DESCRIPTOR= 06  ; запрос дескриптора 
Key_Event   = 1      ; тип клавиатурного события 
 
; Типы дескрипторов  
USB_DEVICE_DESCRIPTOR_TYPE   = 01h 
USB_CONFIGURATION_DESCRIPTOR_TYPE = 02h 

; Additional descriptors
USB_INTERFACE_DESCRIPTOR_TYPE = 04h
USB_HID_DESCRIPTOR_TYPE = 21h
USB_ENDPOINT_DESCRIPTOR_TYPE = 05h
 
; Управляющие коды операций  
IOCTL_USB_GET_ROOT_HUB_NAME   = 00220408h; 
IOCTL_USB_GET_NODE_INFORMATION  = 00220408h; 
IOCTL_USB_GET_NODE_CONNECTION_INFORMATION_EX = 00220448h; 
IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION = 00220410h; 
 
;--- Структуры данных ------------------------------------------------------------- 
; Структура символьного имени устройства 
TDeviceName STRUC  
   Length dd ?        ; Размер структуры в байтах 
   Name   dw 136 dup (?) ; Символьное имя устройства в Юникоде 
TDeviceName ENDS  
 
; Структура дескриптора хаба 
THubDescriptor STRUC  
   bDescriptorLength  db ? ; Длина дескриптора 
   bDescriptorType  db ? ; Тип дескриптора 
   bNumberOfPorts  db ? ; Число портов хаба 
   wHubCharacteristics dw ? ; Атрибуты порта 
   bPowerOnToPowerGood  db ? ; Время стабилизации напряжения 
   bHubControlCurrent db ? ; Максимальное потребление (мА) 
   bRemoveAndPowerMask  db 64 dup (?)  ; не используется 
THubDescriptor ENDS  
 
; Структура с информацией о хабе 
THubInformation STRUC

HubDescriptor THubDescriptor <>   
   HubIsBusPowered db ?   ; Способ питания хаба: от шины (1) 
;или от внешнего источника (0) 
THubInformation ENDS  
 
; Структура запроса/ответа с информацией о хабе 
TNodeInformation STRUC  
   NodeType       dd ?   ;  Тип устройства: 0  ?  хаб 
;1 ? комбинир. устройство 
   HubInformation THubInformation <>  
TNodeInformation ENDS  
 
; Структура дескриптора USB устройства 
TDeviceDescriptor STRUC  
   bLength        db ? ; Длина дескриптора 
   bDescriptorType db ? ; Тип дескриптора 
   bcdUSB        dw ? ; Номер поддерживаемой специф. USB 
   bDeviceClass   db ? ; Код класса USB 
   bDeviceSubClass db ? ; Код подкласса USB устройства 
   bDeviceProtocol db ? ; Код протокола USB 
   bMaxPacketSize db ? ; Макс. размер пакета для нулевой 
;конечной точки 
   idVendor       dw ? ; Идентификатор производителя 
   idProduct      dw ? ; Идентификатор продукта 
   bcdDevice      dw ? ; Номер версии устройства 
   iManufacturer db ? ; Индекс дескриптора строки, 
;описывающего производителя 
   iProduct       db ? ; Индекс дескриптора строки, 
;описывающего продукт 
   iSerialNumber db ? ; Индекс дескриптора строки с серийным 
;номером устройства 
   bNumConfigurations  db ? ; Число конфигураций у устройства 
TDeviceDescriptor ENDS  
 
; Структура с информацией о порте 
TNodeConnectionInformation STRUC 
   ConnectionIndex  dd ?        ; Индекс порта 
   DeviceDescriptor TDeviceDescriptor <> ; Дескриптор устройства 
   CurrentConfigurationValue db ?     ; Номер конфигурации устройства 
   Speed        db ?        ; Скорость работы устройства 
;(0-LS, 1-FS, 2-HS, 3-SS)

DeviceIsHub     db ?        ; Индикатор подключенного хаба 
   DeviceAddress  dw ?        ; Адрес устройства на шине USB 
   NumberOfOpenPipes db ?        ; Число открытых канал, 
;связанных с портом 
   ConnectionStatus  db 4 dup (?) ; Статус порта (см. ниже) 
   PipeList       db 32 dup (?)  ; Массив структур с описание 
;каналов, связанных с портом 
TNodeConnectionInformation ENDS 
;ConnectionStatus =  
;  0 = NoDeviceConnected  - нет подключенных устройств 
;  1 = DeviceConnected   - устройство подключено 
;  2 = DeviceFailedEnumeration - ошибка нумерации 
;  3 = DeviceGeneralFailure  - фатальная ошибка 
;  4 = DeviceCausedOvercurrent - перегрузка по току 
;  5 = DeviceNotEnoughPower  - недостаточное питание 
;  6 = DeviceNotEnoughBandwidth - не хватает пропускной способности 
;  7 = DeviceHubNestedTooDeeply - превышен уровень каскадиров. хабов 
;  8 = DeviceInLegacyHub  - не поддерживаемый хаб 
;  9 = DeviceEnumerating  - устройство в состоянии ?нумерации? 
;  10= DeviceReset    - устройство в состоянии ?сброса? 
  
; Структура конфигурационного пакета запроса к устройству 
TSetupPacket STRUC  
   bmRequest   db ? ; Тип запроса 
   bRequest  db ? ; Номер запроса 
   wValue  dw ? ; Тип и индекс дескриптора 
   wIndex  dw ? ; Индекс дескриптора 
   wLength  dw ? ; Длина данных при вторичном запросе 
TSetupPacket ENDS  
  
; Структура запроса к устройству   
UsbDescriptorRequest STRUC  
   ConnectionIndex dd ?          ; Номер объекта (порт, конеч. точка) 
   SetupPacket      TSetupPacket <>  
   Data         db 2048 dup (?)  ; Буфер для возвращаемых данных 
UsbDescriptorRequest ENDS  
  
; Структура с информацией о событиях от клавиатуры 
KeyEvent STRUC  
   KeyDown       dd ? ; Признак нажатия/отпускания клавиши 
   RepeatCount   dw ? ; Кол-во повторов при удержании клавиши

VirtualKeyCode dw ? ; Виртуальный код клавиши 
   VirtualScanCode dw ? ; Скан-код клавиши 
   ASCIIChar   dw ? ; ASCII-код клавиши 
   ControlKeyState dd ? ; Состояние управляющих клавиш 
KeyEvent ENDS  
  
; Структура буфера событий консоли 
InputRecord STRUC  
     EventType   dw ? ; Тип события 
                 dw 0 ; для выравнивания поля 
     KeyEventRecord     KeyEvent <>  
     MouseEventRecord dd 4 dup (?)  
     WindowsBufferSizeRecord dd ?  
     MenuEventRecord dd ?  
     FocusEventRecord dd ?  
InputRecord ENDS  
  
;--- Данные --------------------------------------------------------------------------- 
.DATA  
; Выводимые сообщения  
  msgTitle     db 'Получение дескрипторов USB устройств', 13,10,13,10, 0 
  msgHostError  db 'Ни одного USB хост-контроллера не найдено', 13, 10, 0 
  msgError    db 13,10,'Ошибка: %u', 13, 10, 0 
  msgInitHost db 0B3h, 13, 10, 0C3h, 'Хост контроллер No%d', 13, 10, 0 
  msgHubInfo  db 0B3h, 0C0h, ' Число портов корневого хаба: %d', 13, 10, 0 
  msgNoCon  db 0B3h,'  ', 0C3h,' К порту %02d устройств не подключено',13,10,0 
  msgHubCon db 0B3h, '  ', 0C3h,' К порту %02d подключен хаб', 13, 10, 0 
  msgDevCon db 0B3h,'  ',0C3h,' К порту %02d подключено устройство', 13, 10, 0 
  msgStatus db 0B3h,'  ',0C3h,' Порт %02d находится в состоянии <%d>', 13,10,0 
  
  msgDevDescr db 0B3h,'  ',0B3h, 13, 10 
     db 0B3h,'  ',0B3h,'    <Дескриптор устройства>', 13, 10 
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
      db 0B3h,'  ',0B3h,'    <Дескриптор конфигурации>',13,10 
      db 0B3h,'  ',0B3h,'         wTotalLength = %u', 13, 10 
      db 0B3h,'  ',0B3h,'       bNumInterfaces = %u', 13, 10 
      db 0B3h,'  ',0B3h,'  bConfigurationValue = %u', 13, 10 
      db 0B3h,'  ',0B3h,'       iConfiguration = %u', 13, 10 
      db 0B3h,'  ',0B3h,'         bmAttributes = %02Xh', 13, 10 
      db 0B3h,'  ',0B3h,'             MaxPower = %u мА', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0

  msgInterfaceDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <Дескриптор интерфейса>',13,10 
      db 0B3h,'  ',0B3h,'     bInterfaceNumber = %u', 13, 10 
      db 0B3h,'  ',0B3h,'    bAlternateSetting = %u', 13, 10 
      db 0B3h,'  ',0B3h,'        bNumEndpoints = %u', 13, 10 
      db 0B3h,'  ',0B3h,'      bInterfaceClass = %u', 13, 10 
      db 0B3h,'  ',0B3h,'   bInterfaceSubClass = %u', 13, 10 
      db 0B3h,'  ',0B3h,'   bInterfaceProtocol = %u', 13, 10 
      db 0B3h,'  ',0B3h,'           iInterface = %u', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0 

  msgHidDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <Дескриптор HID>',13,10 
      db 0B3h,'  ',0B3h,'               bcdHID = %X.%X', 13, 10 
      db 0B3h,'  ',0B3h,'         bCountryCode = %u', 13, 10 
      db 0B3h,'  ',0B3h,'      bNumDescriptors = %u', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0 
   
  msgEndpointDescr db 0B3h,'  ',0B3h, 13, 10 
      db 0B3h,'  ',0B3h,'    <Дескриптор конечной точки>',13,10 
      db 0B3h,'  ',0B3h,'     bEndpointAddress = %02Xh', 13, 10 
      db 0B3h,'  ',0B3h,'         bmAttributes = %02Xh', 13, 10 
      db 0B3h,'  ',0B3h,'       wMaxPacketSize = %u', 13, 10 
      db 0B3h,'  ',0B3h,'            bInterval = %u', 13, 10 
      db 0B3h,'  ',0B3h, 13, 10, 0

  msgExit db 13,10,'Для выхода нажмите любую клавишу...', 0 
 
; Переменные 
  NameHost db '\\.\HCD' ; Имя хоста в Windows 
  NumHost dd ?    ; Номер хоста 
  iHost  dd ?    ; Индекс хоста 
  
  ; Pay attention here 
  NameRootHub db '\\.\'  ; Заготовка под имя корневого хаба 
  
  SRootHub db 136 dup (?) ; Строка с именем хаба 
  hHost   dd ?    ; Дескриптор хост-контроллера 
  hRootHub dd ?    ; Дескриптор корневого хаба 
  hPort  dd ?    ; Дескриптор порта 
  iPort   dd ?    ; Индекс текущего порта хаба 
  hIn  dd ?    ; Дескриптор окна ввода данных 
  NumEvent dd ?    ; Число событий 
  bReturned dd ?    ; Число байт, возвращённых функцией 
  
; Указатели на структуры  
  CBuffer     InputRecord <>        ; буфер консоли 
  DeviceName      TDeviceName <>        ; имя устройства 
  NodeInformation  TNodeInformation <>       ; информация о хабе 
  NodeConnInfo   TNodeConnectionInformation <>  ; информация о порте 
  DescriptorRequest  UsbDescriptorRequest <>    ; запрос дескриптора 
  
.CODE  
;--- Получение информации о порте хаба -------------------------------------- 
;hHub  ? дескриптор корневого хаба 
;Port ? индекс порта хаба 
;Возвращает EAX = 1 ? успешное завершение, 0 ? ошибка 
ShowHubPortDetail PROC  
 ARG   hHub: DWORD, Port: DWORD

; Получение состояния порта хаба 
 mov  eax, Port  
 mov  NodeConnInfo.ConnectionIndex, eax 
 call DeviceIoControl, hHub, IOCTL_USB_GET_NODE_CONNECTION_INFORMATION_EX, offset NodeConnInfo, size NodeConnInfo, offset NodeConnInfo, size NodeConnInfo, offset bReturned, 0 
 test  eax, eax ; Проверка успешного выполнения команды 
 jz   SHPDExit ; В случае ошибки выход из процедуры (eax=0) 
  
; Проверка статуса порта 
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

;--- Получение USB дескрипторов ----------------------------------------------

;hHub  ? дескриптор корневого хаба 
;Port ? индекс порта хаба 
;Возвращает EAX = 1 ? успешное завершение, 0 ? ошибка 
ShowDeviceDetail PROC  
 ARG   hHub: DWORD, Port: DWORD 
  
; Получение дескриптора устройства 
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
 
; Вывод дескриптора устройства 
 call DisplayDescriptorInfo, offset DescriptorRequest.Data 
 
; Очистка буфера 
 call RtlZeroMemory, offset DescriptorRequest.Data, dword ptr size DescriptorRequest.Data 
 
; Получение дескрипторов конфигураций 
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
 
; Вывод дескриптора 
 call DisplayDescriptorInfo, offset DescriptorRequest.Data 
 
; Очистка буфера 
 call RtlZeroMemory, offset DescriptorRequest.Data, dword ptr size DescriptorRequest.Data 
 mov  eax, 1 
 
SDDExit:  ret 
ShowDeviceDetail ENDP 
 
;--- Вывод дескрипторов в консоль ---------------------------------------------- 
;Buffer ? адрес массива дескрипторов 
;edi ? адрес текущего байта в буфере 
;esi ? длина дескриптора 
DisplayDescriptorInfo PROC 
 ARG   Buffer: DWORD 
 uses  eax, ebx, edi, esi 
 
; Проходим по массиву дескрипторов 
; Первый байт ? размер дескриптора в байтах 
; Второй байт ? тип дескриптора 
 mov  edi, Buffer  
Cycle:  
 movzx  esi, byte ptr [edi+0]    ; Длина дескриптора 
 cmp  esi, 0                 ; Нет больше дескрипторов? 
 je   DDIExit  
 cmp  byte ptr [edi+1], 0 ; Нет данных? 
 je   DDIExit  
 
 cmp  byte ptr [edi+1], 1 ; Дескриптор устройства? 
 jne   DesCon  
;  Занесение в  стек  значений в  обратном  порядке  для  передачи параметров printf

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
 cmp  byte ptr [edi+1], 2  ; Дескриптор конфигурации? 
 jne  DesInterface  
 xor  eax, eax

mov  al, [edi+8]  
 mov  bl, 2  
 mul  bl             ; Преобразование значения в мА 
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
 
;--- Основной код --------------------------------------------------------------------  
Start:  
 call FreeConsole  
 call AllocConsole  
 call GetStdHandle, STD_INPUT_HANDLE 
 mov    hIn, eax  
 call printf, offset msgTitle 
 add   esp, 4*1  ; Корректировка стека после printf 
 
; Цикл по всем хостам 
 mov  iHost, 0  
mNextHost:  
; Формирование имени хоста  
 mov  eax, iHost  
 add  eax, '0'  ; Перевод номера диска в символ '0', '1' и т.д. 
 mov  NumHost, eax ; Не более 9 хостов в системе

; Получение дескриптора текущего хоста 
 call CreateFileA, offset NameHost, GENERIC_WRITE, FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0 
 cmp  eax, -1   ; В случае ошибки вывод сообщения 
 je   mErrorHost  
 mov  hHost, eax  ; Сохранение дескриптора в hHost 
 
 call printf, offset msgInitHost, iHost 
 add  esp, 4*2  
 
; Получение PnP-имени корневого хаба 
 call DeviceIoControl, hHost, IOCTL_USB_GET_ROOT_HUB_NAME, 0, 0, offset DeviceName, size DeviceName, offset bReturned, 0 
 test  eax, eax  
 jz   mError  
 mov  ebx, DeviceName.Length 
 cmp  ebx, bReturned ; Проверка на полностью  
 jb   mError   ; полученную структуру с именем 
 
; Формирование полного имени корневого хаба из PnP-имени 
 mov  ecx, 136  ; Максимальная длина имени хаба 
 cld         ; Движение по строке вперёд 
 push  ds  
 pop  es  
 lea  esi, DeviceName.Name  ; Каждый символ занимает 2 байта 
 lea  edi, SRootHub         ; Каждый символ занимает 1 байт 
mLoop:  
 movsb  
 inc  esi  
 loop mLoop  
 
; Получение дескриптора текущего корневого хаба 
 call  CreateFileA, offset NameRootHub, GENERIC_WRITE, FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0 
 cmp  eax, -1  
 jne   mHostCont
 inc iHost
 jmp mNextHost
mHostCont:
 mov  hRootHub, eax ; Сохранение дескриптора в hRootHub 
 
; Получение информации о корневом хабе 
 mov  NodeInformation.NodeType, 0

call DeviceIoControl, hRootHub, IOCTL_USB_GET_NODE_INFORMATION, offset NodeInformation, size NodeInformation, offset NodeInformation, size NodeInformation, offset bReturned, 0 
 test  eax, eax  
 jz   mError  
 
 xor  ebx, ebx ; ebx ? число портов хаба 
 movzx ebx, NodeInformation.HubInformation.HubDescriptor.bNumberOfPorts 
 call printf, offset msgHubInfo, ebx 
 add  esp, 4*2  
 
; Перебор всех портов хаба  
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
 
mErrorHost:   ; Вывод последнего сообщения 
 call printf, offset msgExit 
 add  esp, 4*1  
 jmp  mWait  
 
mError:    ; Обработка ошибок 
 call GetLastError  
 call printf, offset msgError, eax 
 add  esp, 4*2  
 cmp  hRootHub, 0  
 je   mWait  
 call  CloseHandle, hRootHub

call  CloseHandle, hHost 
 
mWait:     ; Ожидание нажатия клавиши 
 call ReadConsoleInputA, hIn, offset CBuffer, 1, offset NumEvent 
 cmp  CBuffer.EventType, Key_Event 
 jne  mWait ; Событие от клавиатуры? 
 
mExit:     ; Выход из программы 
 call  CloseHandle, hIn 
 call FreeConsole  
 call ExitProcess, 0  
END Start
