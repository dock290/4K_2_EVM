TITLE COM-PORT32 
;32-х разрядное приложение для отправки данных в COM-порт. 
;Программа передаёт код символа, введённого с клавиатуры, в первый 
;COM-порт, работающий в синхронном режиме. 

.386
;Плоская модель памяти и стандартная модель вызова подпрограмм. 
.MODEL FLAT, STDCALL

;Директивы компоновщику для подключения библиотек. 
INCLUDELIB import32.lib ; Работа с библиотекой ОС Kernel32. 
  
;--- Внешние WinAPI-функций -------------------------------------------------- 
EXTRN FreeConsole:    PROC  ; Освободить текущую консоль 
EXTRN AllocConsole:  PROC  ; Создать свою консоль 
EXTRN GetStdHandle:  PROC  ; Получить дескриптор текущей консоли 
EXTRN printf:       PROC  ; Вывести по шаблону 
EXTRN CreateFileA:      PROC  ; Получить дескриптор ресурса 
EXTRN ReadConsoleInputA: PROC  ; Получить события консоли 
EXTRN WriteFile:  PROC  ; Передать данные в порт 
EXTRN ReadFile:  PROC  ; Получить данные из порта 
EXTRN GetLastError:   PROC  ; Получить код ошибки 
EXTRN PurgeComm:     PROC  ; Очистить очередь приёма и передачи 
EXTRN CloseHandle:    PROC  ; Закрыть дескриптор 
EXTRN ExitProcess:   PROC  ; Завершить процесс 
EXTRN GetCommState:  PROC  ; Получить DCB структуру порта 
EXTRN SetCommState:  PROC  ; Задать параметры порта 
EXTRN GetCommTimeouts:  PROC ; Получить временные параметры 
EXTRN SetCommTimeouts: PROC ; Установить временные параметры 
  
;--- Константы ----------------------------------------------------------------------- 
GENERIC_READ         = 80000000h ; допускается чтение 
GENERIC_WRITE        = 40000000h ; допускается запись 
OPEN_EXISTING      = 3   ; предписывает открывать устройство, если оно существует 
STD_INPUT_HANDLE   = -10 ; консольное окно для ввода данных 
STD_OUTPUT_HANDLE  = -11 ; консольное окно для вывода данных 
PURGE_TXCLEAR      = 4   ; очистка очереди передачи 
CBR_300            = 300 ; значение скорости передачи данных 
Key_Event          = 1 ; тип клавиатурного события

;--- Структуры данных ------------------------------------------------------------- 
;Структура основных параметров последовательного порта 
DeviceControlBlock STRUC  
 DCBlength dd ? ; Размер структуры в байтах 
 BaudRate dd ? ; Скорость передачи данных 
 fBitFields dd ? ; Битовые поля 
 wReserved dw ? ; Зарезервировано 
 XonLim   dw ? ; Мин. кол-во символов для посылки XON 
 XoffLim   dw ? ; Макс. кол-во символов для посылки XOFF 
 ByteSize db ? ; Число информационных бит 
 Parity   db ? ; Выбор схемы контроля четности 0-4 
 StopBits db ? ; Кол-во стоповых битов 0, 1, 2 = 1, 1.5, 2 
 XonChar   db ? ; Код XON при передаче и приёме 
 XoffChar db ? ; Код XOFF при передаче и приёме 
 ErrorChar db ? ; Код символа при обнаружении ошибки 
 EofChar    db ? ; Код символа конца данных 
 EvtChar    db ? ; Код символа для вызова событий 
 wReserved1 dw ? ; Зарезервировано 
DeviceControlBlock ENDS  
  
;Структура временных параметров порта 
CommTimeOuts STRUC  
   ReadIntervalTimeout        dd ?  ; Интервал между символами 
   ReadTotalTimeoutMultiplier  dd ?  ; Множ. для периода простоя чтения 
   ReadTotalTimeoutConstant    dd ?  ; Постоян. для периода простоя чтения 
   WriteTotalTimeoutMultiplier dd ?  ; Множ. для периода простоя записи 
   WriteTotalTimeoutConstant   dd ?  ; Постоян. для периода простоя записи 
CommTimeOuts ENDS    
  
; Структура с информацией о событиях от клавиатуры 
KeyEvent  STRUC  
 KeyDown       dd ? ; Признак нажатия/отпускания клавиши 
 RepeatCount   dw ? ; Кол-во повторов при удержании клавиши 
 VirtualKeyCode dw ? ; Виртуальный код клавиши 
 VirtualScanCode dw ? ; Скан-код клавиши 
 ASCIIChar  dw ? ; ASCII-код клавиши 
 ControlKeyState dd ? ; Состояние управляющих клавиш 
KeyEvent  ENDS  
  
; Структура буфера событий консоли 
InputRecord  STRUC  
     EventType        dw ?  ; Тип события 
                       dw 0  ; для выравнивания поля 
     KeyEventRecord    KeyEvent <>   
     MouseEventRecord  dd 4 dup (?)   
     WindowsBufferSizeRecord dd ?  
     MenuEventRecord      dd ?  
     FocusEventRecord      dd ?  
InputRecord  ENDS  

;--- Данные --------------------------------------------------------------------------- 
.DATA  
  msgTitle db 'Тестирование последовательного порта', 13,10,13,10, 0 
  msgInit db 'Com-порт инициализирован', 13, 10, 13, 10, 0 
  msgError db 13, 10, 'Ошибка: %u', 13, 10, 0 
  msgInKey db '%c=', 0 
  msgInKeyBin db '        ', 0 
  msgOutKey   db 1Ah, 'Данные отправлены в порт', 13, 10, 0 
  msgNotOutKey db 7Eh, 'Данные в порт не отправлены', 13, 10, 0
  nl db 13,10,0
  msgIntVal db '%d',13,10,0
 
  NamePort  db '\\.\COM4', 0  ; Имя порта в Windows 
  HPort   dd ? ; Дескриптор порта 
  HIn  dd ? ; Дескриптор окна ввода данных 
  Buffer dw ? ; Буфер для передачи данных 
  NumEvent dd ? ; Число событий 
  LenBuf dd 1 ; Количество читаемых байт из порта
  RdLen   dd ? ; Количество прочитанных байт из порта

  DCB DeviceControlBlock <> ; Указатель на структуру с параметрами порта 
  CTO CommTimeOuts       <>  ; Указатель на структуру с времен. параметрами 
  CBuffer InputRecord    <> ; Указатель на структуру буфера консоли 
  
.CODE  
;--- Инициализация COM-порта ------------------------------------------------- 
; Возвращает EAX <> 0 - успешное завершение, 0 - ошибка 
InitCom PROC  
 ARG   Port: DWORD  ; Дескриптор порта 
  
; Получение текущих значений DCB структуры 
 call GetCommState, Port, offset DCB
 test eax, eax ; Проверка на ошибки
 jz   mICExit
  
; Заполнение структуры DCB 
 mov  DCB.BaudRate, CBR_300 
 mov  DCB.ByteSize, 5
 mov  DCB.Parity, 0 
 mov  DCB.StopBits, 1
  
; Установка параметров порта 
 call SetCommState, Port, offset DCB
 test eax, eax
 jz   mICExit
  
; Получение текущих значений временных параметров 
 call GetCommTimeouts, Port, offset CTO
 test eax, eax
 jz   mICExit

; Заполнение структуры CTO 
 mov  CTO.WriteTotalTimeoutMultiplier, 100
 mov  CTO.WriteTotalTimeoutConstant,   10

; Установка временных параметров порта 
 call SetCommTimeouts, Port, offset CTO
 test eax, eax
 jz   mICExit
  
; Очистка буфера передачи перед работой с портом 
 call PurgeComm, Port, PURGE_TXCLEAR
mICExit:
 ret
InitCom ENDP  
  
;--- Преобразование числа к двоичному виду --------------------------------- 
;Number - исходное число 
;String - адрес строки, куда записывается результат преобразования 
Preobr PROC
 ARG  Number:DWORD, String:DWORD
 uses esi, ebx, ecx
 mov esi, String
 mov ecx, 8 ; Преобразование только младшего байта 
 add esi, ecx ; Обратный порядок вывода: от младшего разряда к старшему 
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
  
;--- Основной код -------------------------------------------------------------------- 
Start:  
 call FreeConsole  
 call AllocConsole  
 call GetStdHandle, STD_INPUT_HANDLE 
 mov    HIn, eax  
 call printf, offset msgTitle 
 add   esp, 4*1 ; Корректировка стека после printf 
  
; Открытие порта для синхронного режима работы 
 call CreateFileA, offset NamePort, GENERIC_READ or GENERIC_WRITE, 0, 0, OPEN_EXISTING, 0, 0 
 mov  HPort, eax  
 cmp  HPort, -1 ; В случае ошибки вывод сообщения 
 je   mError  
  
; Инициализация COM-порта 
 call InitCom, HPort 
 test eax, eax  
 jz   mError  
  
 call printf, offset msgInit 
 add  esp, 4*1  

 ; Вывод символа и его двоичного кода в консоль
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
  
mError:  ; Обработка ошибок 
 call GetLastError  
 call printf, offset msgError, eax 
 add  esp, 4*2  
 cmp  HPort, -1  
 je   mWait  
 call CloseHandle, HPort 
  
mWait: ; Ожидание нажатия клавиши 
 call ReadConsoleInputA, HIn, offset CBuffer, 1, offset NumEvent 
 cmp  CBuffer.EventType, Key_Event 
 jne  mWait ; Событие от клавиатуры? 
 jmp  mExit  
  
; Очистка буфера передачи и закрытие порта 
mClose:  
 call PurgeComm, HPort, PURGE_TXCLEAR 
 test eax, eax  
 jz   mError  
 call CloseHandle, HPort  
  
mExit:   ; Выход из программы 
 call  CloseHandle, HIn 
 call FreeConsole  
 call ExitProcess, 0  
END Start
