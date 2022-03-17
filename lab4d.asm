TITLE COM-PORT
;Comport.asm
;16-ти разрядное приложение проверки работы COM-порта.
;Программа передаёт код символа, введённого с клавиатуры, в первый
;COM-порт и получает эхо сигнал, который выводит на экран.

.MODEL SMALL
.STACK 100h

;--- Данные ---------------------------------------------------------------------------
.DATA
  msgTitle db 'Testirovanie posledovatelnogo porta', 13, 10, 13, 10, '$'
  msgInfo db 'Nazhmite lyubuyu klavishu dlya otpravki yeyo koda v port.'
       db 13, 10, 'Dlya vykhoda nazhmite ESC.', 13, 10, 13, 10, '$'
  msgInit db 'Com-port inizializirovan', 13, 10, 13, 10, '$'
  msgError db 'Port ne obnaruzhen', 13, 10, '$'

.CODE
;--- Очистка экрана и установка курсора в верхний левый угол-----------
ClearScreen PROC
mov ah, 06h   ;функция прокрутки активной страницы вверх
 mov al, 00h  ;очистка всего экрана
 mov bh, 07h   ;атрибут пробела = Ч/Б, норм. яркости
 mov cx, 00h   ;верхняя левая позиция
 mov dx, 184Fh ;нижняя правая позиция (Y=24, X=79)
 int 10h
 mov ah, 02h   ;установка курсора
 mov bh, 00h
 mov dx, 00h
 int 10h
 ret
ClearScreen ENDP

;--- Вывод текста на экран --------------------------------------------------------
Print PROC
 push ax
 mov ah, 9
 int 21h
 pop ax
 ret
Print ENDP

;--- Инициализация C0M-порта--------------------------------------------------
;DX ? базовый адрес порта COM-порта
InitCom PROC
 push dx
 add dx, 03h      ;регистр управления линии (03FBh)
 mov al, 10000000b  ;устанавливаем 7 бит
 out dx, al
 sub dx, 2    ;старший байт регистра делителя частоты (3F9h)
 mov al, 00h    ;код для 600 бод
 out dx, al
 dec dx         ;младший байт регистра делителя частоты (3F8h)
 mov al, 0C0h   ;код для 600 бод
 out dx, al
 add dx, 03h      ;регистр управления линией (3FBh)
 mov al, 00h    ;очищаем al
 or  al, 00000011b  ;длина символа (11b) ? 8 бит данных
 or  al, 00000000b  ;длина стоп-бита (0b) ? 1 стоп-бит
 or  al, 00000000b  ;наличие бита чётности (000b) ?
                    ;не генерировать бит четности
 out dx, al
 inc dx         ;регистр управления модемом (3FCh)
 mov al, 00010000b  ;диагностический режим (0001ХХХХb)
 out dx, al
 sub dx, 3    ;регистр разрешения прерываний (3F9h)
 mov al, 0    ;прерывания запрещены
 out dx, al
 pop dx
 ret
InitCom ENDP

;--- Преобразование кода символа для вывода в бинарном виде ---------
;AX ? ASCII код символа
Preobr PROC
 mov bl, al
 mov ah, 0Eh 
 mov cx, 8
m6: rol bl, 1
 jc m7
 mov al, 30h  ;вывод символа "0"
 jmp m8
m7: mov al, 31h  ;вывод символа "1"
m8: int 10h
 loop m6
 ret
Preobr ENDP

;--- Работа с портом ----------------------------------------------------------------
;DX ? базовый адрес COM-порта
Work PROC
m1: mov ah, 00h ;ввод символа
 int 16h ;AL=ASCII код, AH=сканкод
 mov ah, 00h ;сканкод удаляем
 cmp al, 1Bh ;проверка нажатия ESC
 je m5
 push ax
 push ax
 mov ah, 0Eh ;вывод этого символа на экран
 int 10h
 mov al, 3Dh ;вывод символа "="
 int 10h
 pop ax
 call Preobr
 mov al, 1Ah ;вывод символа "стрелочка"
 int 10h
 add dx, 05h ;регистр состояния линии (3FDh)
 mov cx, 0Ah ;счётчик цикла равен 10
m2: in al, dx ;забираем из порта 03FDh данные в AL
 test al, 20h ;готов к приему данных? (00100000b)
 jz m3
 loop m2
m3: sub dx, 05h ;регистр передатчика (03F8h)
 pop ax  ;загрузить передаваемый байт из стека
 out dx, al ;передаём в COM-порт код символа из AL
 add dx, 05h ;регистр состояния линии (03FDh)
m4: in al, dx ;данные приняты ?
 test al, 01h
 jz m4
 sub dx, 05h ;регистр приёмника (03F8h)
 in al, dx ;прочитать принятые данные
 mov ah, 0
 push ax
 mov ah, 0Eh ;вывести символ на экран
 int 10h
 mov al, 3Dh ;вывод символа "="
 int 10h
 pop ax
 call Preobr
 mov al, 13 ;перевод в начало строки
 int 10h
 mov al, 10 ;переход на другую строчку
 int 10h
 jmp m1
m5: ret
Work ENDP

;--- Основной код --------------------------------------------------------------------
Start:  mov ax, @Data
 mov ds, ax
 call ClearScreen ;очистка экрана
 lea dx, msgTitle
 call Print  ;вывод строки msgTitle
 mov ax, 40h      ;ES указывает на область данных BIOS
 mov es, ax
 ;mov dx, es:[0]    ;получаем базовый адрес COM1 (03F8h)
 mov dx, es:[2]    ;получаем базовый адрес COM2 (02F8h)
 test dx, 0FFFFh ;адрес порта есть?
 jnz m0
 lea dx, msgError
 call Print
 jmp mExit
m0: call InitCom   ;инициализация COM-порта
 push  dx
 lea dx, msgInit
 call Print
 lea dx, msgInfo
 call Print
 pop dx
 call Work   ;работа с портом
mExit: mov ax, 4C00h
 int 21h
END Start
