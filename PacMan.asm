INCLUDE Irvine32.inc
INCLUDE macros.inc
INCLUDELIB kernel32.lib
INCLUDELIB user32.lib
INCLUDELIB Winmm.lib


NULL                                 equ 0
SND_ASYNC                            equ 1h
SND_FILENAME                         equ 20000h

PlaySound PROTO STDCALL :DWORD,:DWORD,:DWORD
ExitProcess PROTO STDCALL :DWORD


;---------------------------------------------------------------------------

BUFFER_SIZE = (640*480)
boardWidth = 30

upKey = 18432
rightKey = 19712
downKey = 20480
leftKey = 19200

maxScore = 500

.data
	;sound
		introfile db "pacman_beginning",0
		SoundFile db "pacman_death",0 
		chompFile db "pacman_chomp",0 

	;gameboard 1
		boardgame BYTE BUFFER_SIZE DUP(?)
		buffer BYTE BUFFER_SIZE DUP(?)
		filename  BYTE "map.txt",0
		filename2 BYTE "map2.txt",0
		filename3 BYTE "map3.txt",0
		fileHandle HANDLE ?

	
	;game strings
		scoreString  BYTE "Score: ",0
		levelString  BYTE "Level: ",0
		wincaption  BYTE "WINNER!",0
		livesString  BYTE "Lives: ",0
		lives dd 3
		winnermsg  BYTE "Congrats! You have beaten all 3 levels. You are the Champion.",0

		MessBoxTitle db "Level Complete",0
		MessBox db "Level Complete: Do you wish to continute?",0 

		MessBoxTitle1 db "Fail",0
		MessBox1 db "You have been eaten by a ghost. Do you wish to restart?", 0 

	; Player Name
		playerName db 50 dup(?), 0
		playerFile db "player.txt", 0
		bytesWritten DWORD ?
	
	;game variables
		nextTick dd 0
		lengthOfFrame dd 250
		lastKeyPressed dw 19712
		score dd 0
		level dd 1

	;charachter variable
		x byte 1
		y byte 1
		intendedX byte 2
		intendedY byte 1

	;monster variable
		mX byte 14
		mY byte 11
		mIntendedX byte 14
		mIntendedY byte 10
		mDirection dw 0

		m1X byte 13
		m1Y byte 11
		m1IntendedX byte 13
		m1IntendedY byte 10
		m1Direction dw 0

		m2X byte 14
		m2Y byte 9
		m2IntendedX byte 14
		m2IntendedY byte 8
		m2Direction dw 0

	;splashScreen Variables
		buffer1 BYTE BUFFER_SIZE DUP(?)
		directionfile BYTE "DirectionFile.txt", 0
		splashfile BYTE "art.txt",0
		splashfile2 BYTE "art2.txt",0

		Welcome db "Welcome To the Best Pac Man Game Ever!", 0
		CreatedBy db "Created By: Shaheer-E-Haq, 21i-1657, CS-D",0
		NextStep db "Begin Playing (1) or Need Directions (2)? ", 0
		directionContinue db "Now that you read the directions would you like to play? Yes (1) or No (2)?: ",0
		invalidnumber db "Invalid Number, Please enter either 1 or 2", 0

		yvalue db 20
		xvalue db 25
		inputnumber dd 0
		directionumber dd 0

;---------------------------------------------------------------------------
;Main Game Logic & Loop

.code

main PROC
	call randomize
	call splashscreen

	exit
main ENDP

gameLoop proc
	frameStart:
		call getMSeconds
		add eax, lengthOfFrame	;add length of frame to current time
		mov nextTick, eax
		call handleKey
		call moveCharacter
		call ghostUpdate
		call ghost1Update
		call ghost2Update
		call checkScore

		keyboardLoop:
			call getKeyStroke

			call getMSeconds	
			cmp eax, nextTick	;if length of frame has passed jump to frame start

			jle keyboardLoop	;start loop again if framelength hasnt passed

			jmp frameStart		;if length of frame has passed jump to frame start
		;end of keyboardLoop

	;ret
gameLoop endp

;---------------------------------------------------------------------------
;User Input

getKeyStroke proc
	call readKey
	jz noKeyPress	;dont store anything if no key was pressed (readkey returns 0 if no key pressed)
		mov lastKeyPressed, ax	;key pressed, store value in variable
	noKeyPress:
	ret
getKeyStroke endp

handleKey proc
	mov eax, 0
	mov ax, lastKeyPressed	;takes last keypress

	mov cl, x
	mov ch, y

	;determine what keys was pressed
	mov bx, upkey
	cmp bx, ax
	jz up

	mov bx, rightkey
	cmp bx, ax
	jz right
	
	mov bx, downKey
	cmp bx, ax
	jz down

	mov bx, leftKey
	cmp bx, ax
	jz left

	up:
		dec ch
		jmp endOf

	right:
		inc cl
		jmp endOf

	down:
		inc ch
		jmp endOf

	left:
		dec cl
		jmp endOf

	endOf:

	mov intendedX, cl
	mov intendedY, ch

	ret
handleKey endp

;---------------------------------------------------------------------------
;Move Pacman Around

moveCharacter PROC
    ; Takes intended next position in intendedX, intendedY
    mov eax, 0

    mov al, intendedX
    mov ah, intendedY
    call readArray

    mov bx, 0b00h     ; Left tunnel pos in hex
    cmp ax, bx
    jz leftTunnel

    mov bx, 0b1ah     ; Right tunnel pos in hex
    cmp ax, bx
    jz rightTunnel

    call readArray    ; Reads array to determine material of next intended position. Returns char in al

    mov bl, '#'       ; Wall
    cmp al, bl
    je wall

    mov bl, '.'       ; Food
    cmp al, bl
    je dot

    mov bl, '|'       ; Vertical Wall
    cmp al, bl
    je wall

    mov bl, '-'       ; Horizontal Wall
    cmp al, bl
    je wall

    mov bl, 'O'       ; Ghost
    cmp al, bl
    je wall

    free:
        mov al, x
        mov ah, y
        mov bl, ' '
        call writeToArray
        call movePacMan
        ret

    dot:
		mov al, x
		mov ah, y
		mov bl, ' '
		call writeToArray

		mov eax, score
		add eax, 100
		mov score, eax
		call updateScore  ; Update the score
		invoke PlaySound, ADDR chompFile, NULL, SND_FILENAME or SND_ASYNC
		call movePacMan
		ret


    wall:
        mov al, intendedX
		mov ah, intendedY
		mov al, x  ; keep Pac-Man's position unchanged
		mov ah, y
		ret
		jmp ghostUpdate

    leftTunnel:
        mov al, x
        mov ah, y
        mov bl, ' '
        call writeToArray
        mov intendedX, 26
        mov intendedY, 11
        call movePacMan
        ret

    rightTunnel:
        mov al, x
        mov ah, y
        mov bl, ' '
        call writeToArray
        mov intendedX, 1
        mov intendedY, 11
        call movePacMan
        ret

    ret
moveCharacter ENDP

movePacMan proc
    ; move pacmans x and y to intended x and y
    mov dl, intendedX
    mov dh, intendedY

    ; Set text color to yellow (assuming yellow variable is declared)
    mov eax, yellow
    call SetTextColor

    mov al, "C"
    call writeToScreen ; draw pacman

    mov dl, x
    mov dh, y
    mov al, " "
    call writeToScreen ; clear last position pacman

    mov al, intendedX
    mov ah, intendedY
    mov x, al
    mov y, ah

    ; update array with his char
    mov al, x
    mov ah, y
    mov bl, 'C'
    call writeToArray

    ret
movePacMan endp


writeToScreen proc
	;dl x, dh y
	; al char
	call gotoxy
	call writeChar
	ret
writeToScreen endp

;---------------------------------------------------------------------------
;Game States***

checkScore proc
	cmp score, maxScore
	je levelComplete
	ret

	levelComplete:
		;print message asking user if they want to move to next level
		INVOKE MessageBox, NULL, ADDR Messbox,
		ADDR MessBoxTitle, MB_YESNO + MB_ICONQUESTION
		cmp eax, IDYES
		je increaselevel	;increase level if they say yes
		;otherwise exit
		call resetBoard
		call reinitGhosts
		call splashScreen
		mov lengthOfFrame, 250
	ret

	increaselevel:
		call newLevel
	ret

checkScore endp

newLevel PROC
	;check if last level
	;mov eax, level
	cmp level, 4
	je levelscomplete
	jmp nextLevel


	levelscomplete:	;if youv complete all levels
		mov ebx,OFFSET wincaption
		mov edx,OFFSET winnermsg
		call MsgBox
		
	ret

	nextLevel:
		mov score,0 ;puts score back at zero for the next level
		inc level
		mov eax, 50
		sub lengthOfFrame, eax
		call resetBoard
	ret

newLevel ENDP

endGame PROC
	invoke PlaySound, ADDR SoundFile, NULL, SND_FILENAME or SND_ASYNC
	dec lives
	INVOKE MessageBox, NULL, ADDR Messbox1, ADDR MessBoxTitle1, MB_YESNO + MB_ICONQUESTION
	cmp eax, IDYES
	jnz startScreen
	restartGamee:
		call restartGame
		jmp endOf

	cmp lives, 0
	je splashScreen
	startScreen:
		call resetBoard
		call reinitGhosts
		call splashScreen
		mov lengthOfFrame, 250
	endOf:
	ret
endGame ENDP

restartGame PROC
	mov score, 0 ;puts score back at zero for the beginning level
	mov level, 1
	call resetBoard
	call reinitGhosts
	ret
restartGame endp

resetBoard PROC
	mov score, 0
	mov x, 1
	mov y, 1
	mov intendedX, 2
	mov intendedY, 1
	mov lastKeyPressed, 19712

	call clrscr
	call LoadGameBoardFile
	call drawscreen
	call updateScore

	mov dl, x
	mov dh, y
	mov al, "C"
	call writeToScreen	;draw pacman

	ret
resetBoard endp

;---------------------------------------------------------------------------
;Ghost Logic

reinitGhosts PROC
	mov mX, 14
	mov mY, 11
	mov mIntendedX, 14
	mov mIntendedY, 10

	mov m1X, 14
	mov m1Y, 11
	mov m1IntendedX, 14
	mov m1IntendedY, 10

	mov m2X, 14
	mov m2Y, 9
	mov m2IntendedX, 14
	mov m2IntendedY, 8

	ret
reinitGhosts endp

ghostUpdate PROC
    ; Check for free direction
    mov cl, mX
    mov ch, mY
    mov ax, mDirection

    mov bx, 0
    cmp bx, ax
    jz up

    mov bx, 1
    cmp bx, ax
    jz right

    mov bx, 2
    cmp bx, ax
    jz down

    mov bx, 3
    cmp bx, ax
    jz left

    up:
        dec ch
        jmp endOf
    right:
        inc cl
        jmp endOf
    down:
        inc ch
        jmp endOf
    left:
        dec cl
        jmp endOf
    endOf:

    mov  mIntendedX, cl
    mov  mIntendedY, ch

    mov al, cl
    mov ah, ch
    call readarray

    mov bl, ' '
    cmp al, bl
    jz free

    mov bl, '.'
    cmp al, bl
    jz free

    mov bl, '|'
    cmp al, bl
    je trueghost

    trueghost:
        sub mDirection, 1
        jmp moveGhost

    mov bl, '-'
    cmp al, bl
    je trueghost1

    trueghost1:
        add mDirection, 1
        jmp moveGhost

    mov bl, 'C'
    cmp al, bl
    jz pacman

    jmp wall

    free:
        jmp moveGhost

    wall:
        ; Adjust the conditions here to make the ghosts move independently
        mov eax, 4
        Call RandomRange
        mov mDirection, ax

        ; Replace the recursive call with a loop
        jmp ghostUpdate_continue

    pacman:
        ; Compare the ghost's position with Pac-Man's position
        mov al, x
        cmp mX, al
        jne ghostUpdate_continue
        mov ah, y
        cmp mY, ah
        jne ghostUpdate_continue

        ; Ghost has caught Pac-Man
        call endGame

    ghostUpdate_continue:
        ret
ghostUpdate ENDP


moveGhost PROC
		mov dl, mX
		mov dh, mY

		call writeToScreen	;clear last position ghost

		mov dl, mIntendedX
		mov dh, mIntendedY
		mov al, "O"
		call writeToScreen	;draw ghost

		mov mX, dl	;update cordinates
		mov mY, dh
	ret
moveGhost endp

ghost1Update PROC
    ; Check for free direction
    mov cl, m1X
    mov ch, m1Y
    mov ax, m1Direction

    mov bx, 0
    cmp bx, ax
    jz up

    mov bx, 1
    cmp bx, ax
    jz right

    mov bx, 2
    cmp bx, ax
    jz down

    mov bx, 3
    cmp bx, ax
    jz left

    up:
        dec ch
        jmp endOf
    right:
        inc cl
        jmp endOf
    down:
        inc ch
        jmp endOf
    left:
        dec cl
        jmp endOf
    endOf:

    mov  m1IntendedX, cl
    mov  m1IntendedY, ch

    mov al, cl
    mov ah, ch
    call readarray

    mov bl, ' '
    cmp al, bl
    jz free

    mov bl, '.'
    cmp al, bl
    jz free

    mov bl, '|'
    cmp al, bl
    je trueghost2

    trueghost2:
        sub m1Direction, 1

    mov bl, '-'
    cmp al, bl
    je true2

    true2:
        add m1Direction, 1

    mov bl, 'C'
    cmp al, bl
    jz pacman

    jmp wall

    free:
        call move1Ghost
        ret

    wall:
        ; Adjust the conditions here to make the ghosts move independently
        mov eax, 4
        Call RandomRange
        mov m1Direction, ax

        ; Replace the recursive call with a loop
        jmp ghost1Update

    pacman:
        ; Compare the ghost's position with Pac-Man's position
		mov bl, x
        cmp m1X, bl
        jne ghost1Update_continue
		mov bh, y
        cmp m1Y, bh
        jne ghost1Update_continue

        ; Ghost has caught Pac-Man
        call endGame

    ghost1Update_continue:
        ret
ghost1Update ENDP

move1Ghost PROC
		mov dl, m1X
		mov dh, m1Y

		call writeToScreen	;clear last position ghost

		mov dl, m1IntendedX
		mov dh, m1IntendedY
		mov al, "O"
		call writeToScreen	;draw ghost

		mov m1X, dl	;update cordinates
		mov m1Y, dh
	ret
move1Ghost endp

ghost2Update PROC
    ; Check for free direction
    mov cl, m2X
    mov ch, m2Y
    mov ax, m2Direction

    mov bx, 0
    cmp bx, ax
    jz up

    mov bx, 1
    cmp bx, ax
    jz right

    mov bx, 2
    cmp bx, ax
    jz down

    mov bx, 3
    cmp bx, ax
    jz left

    up:
        dec ch
        jmp endOf
    right:
        inc cl
        jmp endOf
    down:
        inc ch
        jmp endOf
    left:
        dec cl
        jmp endOf
    endOf:

    mov  m2IntendedX, cl
    mov  m2IntendedY, ch

    mov al, cl
    mov ah, ch
    call readarray

    mov bl, ' '
    cmp al, bl
    jz free

    mov bl, '.'
    cmp al, bl
    jz free

    mov bl, '|'
    cmp al, bl
    je trueghost3

    trueghost3:
        sub m2Direction, 1

    mov bl, '-'
    cmp al, bl
    je true3

    true3:
        add m2Direction, 1

    mov bl, 'C'
    cmp al, bl
    jz pacman

    jmp wall

    free:
        call move2Ghost
        ret

    wall:
        ; Adjust the conditions here to make the ghosts move independently
        mov eax, 4
        Call RandomRange
        mov m2Direction, ax

        ; Replace the recursive call with a loop
        jmp ghost2Update

    pacman:
        ; Compare the ghost's position with Pac-Man's position
		mov cl, x
        cmp m2X, cl
        jne ghost2Update_continue
		mov ch, y
        cmp m2Y, ch
        jne ghost2Update_continue

        ; Ghost has caught Pac-Man
        call endGame

    ghost2Update_continue:
        ret
ghost2Update ENDP

move2Ghost PROC
		mov dl, m2X
		mov dh, m2Y

		call writeToScreen	;clear last position ghost

		mov dl, m2IntendedX
		mov dh, m2IntendedY
		mov al, "O"
		call writeToScreen	;draw ghost

		mov m2X, dl	;update cordinates
		mov m2Y, dh
	ret
move2Ghost endp
;---------------------------------------------------------------------------
;Gameboard Loading, Displaying & Score

LoadGameBoardFile PROC
	mov edx, Offset filename
	cmp level, 2
	je level2
	cmp level, 3
	je level3
	jmp level1

	level1:
		mov edx, Offset filename
		jmp loadFile

	level2:
		mov edx, Offset filename2
		jmp loadFile

	level3:
		mov edx, Offset filename3
		jmp loadFile



loadFile:
	call openinputfile
	mov filehandle, eax
	mov edx, offset boardgame
	mov ecx, buffer_size
	call ReadFromFile
	mov boardgame[eax],0

	mov eax, filehandle
	call closefile

	ret
LoadGameBoardFile ENDP

drawScreen proc
	mov edi,0
	mov ecx, lengthof boardgame

	printcharacters:
		mov bl, boardgame[edi]
		cmp bl, "#"
		je changecolor
		jmp somewhere

		changecolor:
			mov eax, blue
			call SetTextColor
			mov al,bl
			call writechar
			jmp keepgoing
		somewhere:
			mov eax, blue
			call SetTextColor
			mov al, boardgame[edi]
			call writechar
		keepgoing:
	inc edi
	loop printcharacters
	call updateScore
drawScreen endp

updateScore PROC
    ; Score
    mov dl, 0
    mov dh, 25
    call gotoxy
    mov edx, offset scoreString
    call WriteString

    mov eax, score
    call writedec

    ; Level
    mov dl, 0
    mov dh, 24
    call gotoxy
    mov edx, offset levelString
    call WriteString

    mov eax, level
    call writedec

	; lives

	mov dl,0
	mov dh, 26
	call gotoxy
	mov edx, offset livesString
	call WriteString
	mov eax, lives
	call writedec

    ret
updateScore ENDP


;---------------------------------------------------------------------------
;Gameboard Array Procedures

readArray proc
	;al: x, ah: y
	;returns value in al
	mov esi, offset boardGame
	mov ecx, eax
	mov eax, 0	;use ax to store position
	;determine position
		mov al, boardWidth
		mul ch
		;cx = boardwidth * y
		mov ch, 0	;make cx equal to cl only
		add ax, cx	;add the x to the sum. Ax is now the offset from the begining of the array
	add esi, eax; add the offset off the array to its position in the array
	mov al, [esi]
	ret
readArray endp

writeToArray proc
	;al: x, ah: y
	;bl char
	mov esi, offset boardGame
	mov ecx, eax
	mov eax, 0	;use ax to store position

	; Boundary check
    cmp ecx, BUFFER_SIZE
    jae error_exit

	;determine position
		mov al, boardWidth
		mul ch
		;cx = boardwidth * y
		mov ch, 0	;make cx equal to cl only
		add ax, cx	;add the x to the sum. Ax is now the offset from the begining of the array
	add esi, eax; add the offset off the array to its position in the array
	mov [esi], bl
	ret

	error_exit:
    ; Handle error or exit gracefully
    ret

writeToArray endp

;-------------------------------------------------------------------------------------------
;Splash Screen
splashscreen PROC

	call clrscr

	mov edx, 0
	mov dh, 0
	call Gotoxy
	mov edx, Offset splashfile
	call openinputfile
	mov filehandle, eax
	mov edx, offset buffer1
	mov ecx, BUFFER_SIZE
	call ReadFromFile
	mov buffer1[eax],0
	mov edx, offset buffer1
	mov eax,lightblue
	call SetTextColor
	call writestring
	call crlf
	mov eax, filehandle
	call closefile

	; player name

    mov edx, OFFSET playerName
    mov dh, 23
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET playerName
    call ReadString

    ; Write the player's name to a file
    mov edx, OFFSET playerFile
    mov eax, GENERIC_WRITE
    mov ecx, CREATE_ALWAYS
    call CreateFile
    mov fileHandle, eax

    mov edx, OFFSET playerName
    mov ecx, LENGTHOF playerName
    mov ebx, OFFSET bytesWritten
    mov esi, fileHandle
    call WriteFile

    mov esi, fileHandle
    call CloseHandle


	mov edx, 0
	mov dh, 10
	call Gotoxy
	mov edx, Offset splashfile2
	call openinputfile
	mov filehandle, eax
	mov edx, offset buffer1
	mov ecx, buffer_size
	call ReadFromFile
	mov buffer1[eax],0
	mov edx, offset buffer1
	mov eax,yellow
	call SetTextColor
	call writestring
	call crlf
	mov eax, filehandle
	call closefile


	mov edx, 0
	mov dh, yvalue
	mov dl, xvalue
	call Gotoxy
	mov edx, offset Welcome
	mov eax,lightGreen
	call SetTextColor
	call WriteString

	call crlf
	mov dh, 21
	mov dl,15
	call Gotoxy
	mov edx, offset CreatedBy
	mov eax,magenta
	call SetTextColor
	call WriteString

	call crlf
	mov dh, 22
	mov dl,25
	call Gotoxy
	mov edx, offset NextStep
	mov eax,cyan
	call SetTextColor
	call WriteString
	invoke PlaySound, ADDR introFile, NULL, SND_FILENAME or SND_ASYNC
	call Readint
	mov inputnumber, eax

	mov eax, 15 ;changes color back to normal
	call SetTextColor

	cmp inputnumber, 1
	je beginplaying
	cmp inputnumber, 2
	je directions
	jmp invalidnum

	beginplaying:
		call clrscr
		call LoadGameBoardFile
		call drawscreen
		call gameLoop
		call crlf
		ret

	directions:
		call clrscr
		call printdirections

		mov edx, offset directionContinue
		call WriteString
		call Readint
		mov directionumber, eax

		cmp directionumber, 1
		je beginplaying
		cmp directionumber, 2
		je quitgame
		jmp invalidnum

		quitgame:
			exit
		ret

	invalidnum:
		call clrscr
		mov dh, 19
		mov dl, 24
		call Gotoxy
		mov edx, offset invalidnumber
		call WriteString
		call splashscreen
		call crlf

		ret

splashscreen ENDP


printdirections PROC
	
	mov edx, Offset directionfile
	call openinputfile
	mov filehandle, eax
	mov edx, offset buffer
	mov ecx, buffer_size
	call ReadFromFile
	mov buffer[eax],0
	mov edx, offset buffer
	call writestring
	call crlf
	mov eax, filehandle
	call closefile

ret
printdirections ENDP
;---------------------------------------------------------------------------

END main



