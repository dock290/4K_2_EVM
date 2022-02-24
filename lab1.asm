;32-х разрядное приложение получения информации о процессоре,
;используя команду CPUID.
;Программа выводит в текущую консоль количество поддерживаемых
;процессором стандартных функций команды CPUID.
.586                         ;Расширенная система команд.
;Плоская модель памяти и стандартная модель вызова подпрограмм.
.MODEL FLAT, STDCALL
;Директивы компоновщику для подключения библиотек.
INCLUDELIB import32.lib      ;Работа с библиотекой ОС Kernel32.

;Внешние процедуры
EXTRN GetStdHandle:     PROC ;Получить дескриптор окна.
EXTRN WriteConsoleA:    PROC ;Вывести в консоль.
EXTRN ExitProcess:      PROC ;Завершить процесс.

;Константы
Std_Output_Handle EQU -11    ;Консольное окно для вывода данных.

.DATA                               ;Открыть сегмент данных.
    Handl_Out DD ?                  ;Дескриптор окна вывода данных.
    Lens DW ?                       ;Количество выведенных символов.
    Not_Supp DB 'CPUID not supported', 13, 10, '$'
    Not_Supp_L = $ - Not_Supp - 1   ;Длина строки Not_Supp без знака $.
    Supp DB 'CPUID supported', 13, 10, '$'
    Supp_L = $ - Supp - 1
    Str1 DB 'Number function: ','$'
    Str1_L = $ - Str1 - 1
    Number DD ?
    Number_Str DB 8 dup (0)
    Number_Str_L = 8
;-------------------------------------------------------------------------------------------
.CODE ;Открыть сегмент кодов.
Preobr PROC
    mov EAX, Number
    mov EBX, 10
    mov word ptr Number_Str, 0 ;Очистить переменную.
    mov word ptr Number_Str[2], 0h
    mov word ptr Number_Str[4], 0h
    mov word ptr Number_Str[6], 0h
    xor ECX, ECX
m1: xor EDX, EDX
    div EBX
    push EDX
    inc ECX
    cmp EAX, 0
    jne m1
    xor ESI, ESI
m2: pop EAX
    add EAX, 30h
    mov Number_Str[ESI], AL
    inc ESI
    loop m2
    ret
Preobr ENDP
Start:
    ;Получить дескриптор окна вывода.
    call GetStdHandle, Std_Output_Handle
    mov Handl_Out, EAX
    ;--------Проверка поддержки команды CPUID процессором----------
    pushfd              ;Получение регистра флагов через стек.
    pop EAX
    mov EBX, EAX
    xor EAX, 200000h    ;Изменение 21-ого бита в регистре флагов.
    push EAX            ;Сохранение и снова получение
    popfd               ;регистра флагов.
    pushfd
    pop EAX
    cmp EAX, EBX    ;Сравнение регистров до и после изменения.
    jne CPUIDSupp   ;Если не изменился, то CPUID не поддерживается.
    ;Вывести строку Not_supp.
    call WriteConsoleA, Handl_Out, offset Not_Supp, Not_Supp_L, offset Lens, 0
    jmp @exit
CPUIDSupp:
    ;Вывести строку Supp.
    call WriteConsoleA, Handl_Out, offset Supp, Supp_L, offset Lens, 0

    ;Получение информации о количестве поддерживаемых функций CPUID
    mov EAX, 0
    cpuid
    mov Number, EAX ;Количество поддерживаемых функций.
    call Preobr
    ;Добавление в конец строки служебных кодов 13 и 10.
    mov word ptr Number_Str[6], 0D0Ah
    ;Вывести строку Str1.
    call WriteConsoleA, Handl_Out, offset Str1, Str1_L, offset Lens, 0
    ;Вывести строку Number_Str.
    call WriteConsoleA, Handl_Out, offset Number_Str, Number_Str_L, offset Lens, 0
@exit: call ExitProcess ;Завершить программу.
END Start ;Конец исходного модуля.
