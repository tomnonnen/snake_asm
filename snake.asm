;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
	; stw     zero, HEAD_X(zero)
	; stw     zero, HEAD_Y(zero)
	; stw     zero, TAIL_X(zero)
	; stw     zero, TAIL_Y(zero)
	; addi    t0, t0, 3
	; stw     t0, GSA(zero)

	; addi    s0, ra, 0

	; inf_loop:
	;     call    clear_leds
	;     addi    ra, s0, 0
	;     call    get_input
	;     addi    ra, s0, 0
	; 	addi	a0, zero, 0
	;     call    move_snake
	;     addi    ra, s0, 0
	;     call    draw_array
	;     addi    ra, s0, 0
	;     br      inf_loop


	; const
	addi    s1, zero, 1
	addi    s2, zero, 2
	addi    s5, zero, BUTTON_CHECKPOINT

	addi    s0, ra, 0

	; CP_VALID = 0
	stw     zero, CP_VALID(zero)
	init_game_:
		call    init_game
		addi    ra, s0, 0
	get_input_:
		call    wait_procedure
		addi    ra, s0, 0
		call    get_input
		addi    ra, s0, 0

	
	beq     v0, s5, checkpoint_pressed 	; checkpoint button pressed?
	jmpi    checkpoint_not_pressed

	
	checkpoint_pressed:
		call    restore_checkpoint
		addi    ra, s0, 0
		beq     v0, zero, get_input_    ; checkpoint valid?
		jmpi    blink_score_


	checkpoint_not_pressed:
		call    hit_test
		addi    ra, s0, 0
		beq     v0, s1, eat_food    ; Eat food?
		beq     v0, s2, collide     ; Collide?
		addi    a0, zero, 0         ; we put a0=0 bc the snake’s head doesn't collide with the food

		call    move_snake
		addi    ra, s0, 0

		clear_leds_draw_array:
			call    clear_leds
			addi    ra, s0, 0
			call    draw_array
			addi    ra, s0, 0
			jmpi    get_input_

		collide:
			call    wait_procedure
			addi    ra, s0, 0
			jmpi    init_game_

		eat_food:
			ldw     t0, SCORE(zero)
			addi    t0, t0, 1
			stw     t0, SCORE(zero) ; we update the score 
			call    display_score
			addi    ra, s0, 0
			addi    a0, zero, 1     ; we put a0=1 bc the snake’s head collides with the food
			call    move_snake
			addi    ra, s0, 0
			call    create_food
			addi    ra, s0, 0
			call    save_checkpoint
			addi    ra, s0, 0
			beq     v0, s1, blink_score_    ; Checkpoint saved?
			jmpi    clear_leds_draw_array

			blink_score_:
				call    blink_score
				addi    ra, s0, 0
				jmpi    clear_leds_draw_array

	ret

; BEGIN: clear_leds
clear_leds:
	stw     zero, LEDS(zero)	; putting zeros for LED[0]
	stw     zero, LEDS+4(zero)	; putting zeros for LED[1]
	stw     zero, LEDS+8(zero)	; putting zeros for LED[2]
	ret

; END: clear_leds


; BEGIN: set_pixel
set_pixel:
	; below, find index and multiply it by 4
	srli    t0, a0, 2
	slli    t0, t0, 2

	andi    t1, a0, 3		; t1 is the value of x modulo 4
	ldw     t2, LEDS(t0)	; t2 is the value of the corresponding adress t0

	; the bit that we set is the x*8 + y bit
	addi    t3, zero, 1		; we add 1 to t3 (new value of led)
	slli    t4, t1, 3		; we multiply x by 8; the bit that we set is 
	add     t4, t4, a1		; we add y
	sll     t3, t3, t4		; we shift 1 to the right place (x * 8) + y to light the led

	or      t3, t3, t2		; we do a or with the last and the new value of led
	stw     t3, LEDS(t0)	; we store now the new value t3

	ret


; END: set_pixel


; BEGIN: display_score
display_score:
	; push on the stack ;
	addi	sp, sp, -16
	stw		s0, 0(sp)
	stw		s1, 4(sp)
	stw		s3, 8(sp)
	stw		s4, 12(sp)

	ldw		t0, SCORE(zero)				; t0 = current score
	addi	t1, zero, 100				; t1 = 100
	blt		t0, t1, else_disp_score		; if current score >= 100 go to if_bigger_eq_100
	
	if_bigger_eq_100:
		addi	t0, zero, 99	; max score is 99
	else_disp_score:

	; count the number of times we can put 10 in t0
	addi	t2, zero, 0		; t2 = 0 (counter of 10)
	addi	s3, zero, 0		; s3 = 0 (counter of 1) -> the third 7seg is s3
	loop_tens_ds:
		addi	t2, t2, 10			    ; update t2 (t2 += 10)
		addi	s3, s3, 1			    ; update s3 (s3 += 1)
		bge 	t0, t2, loop_tens_ds	; continue to loop while t0 >= t2

	; there was one iteration more than we needed
	addi	t2, t2, -10	; correct t2 counter
	addi	s3, s3, -1	; correct s3 counter

	; count the number of times we can put 1 in t0 % 10
	sub		s4, t0, t2

	;; change SEVEN_SEGS in memory ;;
	ldw 	t7, SEVEN_SEGS(zero)	; get current 7seg
	andi	t7, t7, 0xFFFF			; modify only the last 2 bytes

	; Prepare to treat the tens segment ;
	addi	s0, s3, 0		; s0 should store the int we want to represent
	addi	s1, zero, 16	; s1 should store the shift to apply in order to represent the int on the right segment (0 -> 0, 1 -> 8, 2 -> 16, 3 -> 24)

	; this process modifies t7 in function of the integer in s0 and whether it's the third (s1 = 16) or fourh segment (s1 = 24) ;
	seg7_cond:
		addi	t5, zero, 0			; t5 = 0 (it's a counter that help us do the if conditions)
		beq     s0, t5, one_if_0	; if s0 == 0
		addi 	t5, t5, 1
		beq     s0, t5, one_if_1	; else if s0 == 1
		addi 	t5, t5, 1
		beq     s0, t5, one_if_2	; else if s0 == 2
		addi 	t5, t5, 1
		beq     s0, t5, one_if_3	; else if s0 == 3
		addi 	t5, t5, 1
		beq     s0, t5, one_if_4	; else if s0 == 4
		addi 	t5, t5, 1
		beq     s0, t5, one_if_5	; else if s0 == 5
		addi 	t5, t5, 1
		beq     s0, t5, one_if_6	; else if s0 == 6
		addi 	t5, t5, 1
		beq     s0, t5, one_if_7	; else if s0 == 7
		addi 	t5, t5, 1
		beq     s0, t5, one_if_8	; else if s0 == 8
		addi 	t5, t5, 1
		beq     s0, t5, one_if_9	; else if s0 == 9

		one_if_0:
			addi	t6, zero, 0xFC
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_1:
			addi	t6, zero, 0x60
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_2:
			addi	t6, zero, 0xDA
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_3:
			addi	t6, zero, 0xF2
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_4:
			addi	t6, zero, 0x66
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_5:
			addi	t6, zero, 0xB6
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_6:
			addi	t6, zero, 0xBE
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_7:
			addi	t6, zero, 0xE0
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_8:
			addi	t6, zero, 0xFE
			sll		t6, t6, s1
			or		t7, t7, t6
			br		one_else 
		one_if_9:
			addi	t6, zero, 0xF6
			sll		t6, t6, s1
			or		t7, t7, t6

		one_else:

	addi	t6, zero, 16
	bne		s1, t6, already_done 	; if we haven't done the fourth segment yet do it
	if_not_done:
		; Prepare to treat the ones segment ;
		addi	s0, s4, 0
		addi	s1, zero, 24
		br		seg7_cond
	already_done:

	addi	t0, zero, 0xFC
	stw		t0, SEVEN_SEGS(zero)
	stw		t0, SEVEN_SEGS+4(zero)

	srli	t0, t7, 24
	stw		t0, SEVEN_SEGS+12(zero)
	srli	t0, t7, 16
	andi	t0, t0, 0xFF
	stw		t0, SEVEN_SEGS+8(zero)

	; pop the stack ;
	ldw 	s0, 0(sp)
	ldw 	s1, 4(sp)
	ldw 	s3, 8(sp)
	ldw		s4, 12(sp)
	addi	sp, sp, 16

	ret

; END: display_score


; BEGIN: init_game
init_game:
	; Push the stack ;
	addi	sp, sp, -4
	stw		s0, 0(sp)

	; Reset the GSA ;
	addi	t0, zero, 0
	addi	t2, zero, NB_CELLS

	loop_rst_gsa:
		slli	t1, t0, 2
		stw		zero, GSA(t1)
		addi	t0, t0, 1
		blt		t0, t2, loop_rst_gsa

	; Place snake going right at pos (0,0) ;
	addi	t0, zero, 4
	stw		t0, GSA(zero)

	addi	t0, zero, 0
	stw		t0, HEAD_X(zero)
	stw		t0, HEAD_Y(zero)
	stw		t0, TAIL_X(zero)
	stw		t0, TAIL_Y(zero)		


	; Call function to create food ;
	add		s0, zero, ra
	call 	create_food
	add		ra, zero, s0

	; Score is 0 ;
	addi	t0, zero, 0
	stw		t0, SCORE(zero)

	call	display_score
	add		ra, zero, s0

	call	clear_leds
	add		ra, zero, s0
	call	draw_array
	add		ra, zero, s0

	; Pop the stack ;
	ldw		s0, 0(sp)
	addi	sp, sp, 4

	ret

; END: init_game


; BEGIN: create_food
create_food:

	ldw     t0, RANDOM_NUM(zero) 	; t0 is the random number
	andi    t0, t0, 0xFF			; we take the lowest byte of t0

	; verify that t0 is between 0 and 96 (excluded) in a loop
	blt     t0, zero, create_food 	; if t0 is is less than 0
	addi    t2, zero, NB_CELLS 
	bge     t0, t2, create_food 	; if t0 is greater or equal than NB_CELLS(96) we go back at the debut of the function

	; verify that in the GSA the emplacement of the random number have a behavior of 0
	slli    t0, t0, 2
	ldw     t1,  GSA(t0) 			; t1 is the information of the behavior of the random number in GSA

	; verify that the behavior is 0
	bne     t1, zero, create_food

	; we have a valid value
	addi    t3, zero, FOOD
	stw     t3, GSA(t0) 			; we asign the value for food (5) at the cell 
	

	ret


; END: create_food


; BEGIN: hit_test
hit_test:
	; push on the stack ;
	addi       sp, sp, -12
	stw        s0, 0(sp)
	stw        s1, 4(sp)
	stw        s2, 8(sp)


	; test if the head eats a food
	; recup head position;
	ldw     t0, HEAD_X(zero)	; t0 = HEAD_X
	ldw     t1, HEAD_Y(zero)	; t1 = HEAD_Y

	slli    t2, t0, 3	; t2 = HEAD_X * 8
	add     t2, t2, t1	; t2 += HEAD_Y, so t2 = array index of the head
	slli    t2, t2, 2	;t2 = array index of the head * 4

	ldw     t3, GSA(t2)			; t3 = direction of the head

	addi    t4, zero, DIR_LEFT		; const t4 = 1
	addi    t5, zero, DIR_UP		; const t5 = 2
	addi    t6, zero, DIR_DOWN		; const t6 = 3
	addi    t7, zero, DIR_RIGHT		; const t7 = 4

	beq     t3, t4, head_if_left2	; if t3 == 1
	beq     t3, t5, head_if_up2		; else if t3 == 2
	beq     t3, t6, head_if_down2	; else if t3 == 3
	beq     t3, t7, head_if_right2	; else if t3 == 4

	;===================================================
	; we search the next value
	head_if_left2:
		; we must go at the cell of left to see if it is a food, or a bound, or the body
		addi         t0, t0, -1	; we put x at -1 if he go left
		jmpi verify_border
	head_if_up2:
		addi        t1, t1, -1	; we put y at -1 if he go up
		jmpi verify_border
	head_if_down2:
		addi         t1, t1, 1	; we put y at +1 if he go down
		jmpi verify_border    
	head_if_right2:
		addi         t0, t0, 1	; we put x at +8 if he go right
		jmpi verify_border

	;==================================================
	; we verify first if the next 
	verify_border:
		addi     s0, zero, NB_COLS	; s0 is equal at the NB_COLS (12)
		addi     s1, zero, NB_ROWS	; s1 is equal at the NB_ROWS (8)

		blt     t0, zero, game_over	; if new x<0 => game over
		blt     t1, zero, game_over	; if new y<0 => game over
		bge     t0, s0, game_over	; if new x >= NB_COLS => game over
		bge     t1, s1, game_over	; if new y >= NB_ROWS => game over


	verify_touch_queue:
		slli    t2, t0, 3		; t2 = new x * 8
		add     t2, t2, t1		; t2 += new y, so t2 = array index of the next head
		slli    t2, t2, 2		; t2 = array index of the next head * 4
		ldw     t3, GSA(t2)		; t3 = direction of the next head

		; verify that's the next head is a snake (1-4)
		beq     t3, t4, game_over	; if the next head is a body of the snake
		beq     t3, t5, game_over	; if the next head is a body of the snake
		beq     t3, t6, game_over	; if the next head is a body of the snake
		beq     t3, t7, game_over	; if the next head is a body of the snake


	verify_food:
		addi    s3, zero, FOOD			; s3 is food
		beq     t3, s3, update_score	; verify that the new coordinates is a food
	
	;===========================================
	no_collision:
		addi    v0, zero, 0
		jmpi end_func

	game_over:
		addi     v0, zero, 2
		jmpi end_func
	
	update_score:
		addi    v0, zero, 1
		jmpi end_func
	


	end_func:
	; pop the stack ;
	ldw     s0, 0(sp)
	ldw     s1, 4(sp)
	ldw     s2, 8(sp)
	addi    sp, sp, 12
	ret
; END: hit_test


; BEGIN: get_input
get_input:
	; BUTTONS+4 is hot encoding
	; first we check if it is a check point
	; else we go progressively

	ldw     v0, BUTTONS+4(zero)		; we recup the value of edgecapture (Buttons + 4)
	stw 	zero, BUTTONS+4(zero)	; clear the edge capture
	andi    v0, v0, 31				; we only analyse the first 5 first bits

	; button  0 : left,  1 : up, 2 : down, 3 : right , 4 : checkpoint
	; we check each bit
	addi    t3, zero, 16
	andi    t2, v0, 16			; we analyze fith bit (checkpoint)
	beq     t2, t3, v0_bit_4

	addi    t3, zero, 1
	andi    t2, v0, 1			; we analyze first bit
	beq     t2, t3, v0_bit_0

	addi    t3, zero, 2
	andi    t2, v0, 2			; we analyze second bit
	beq     t2, t3, v0_bit_1

	addi    t3, zero, 4
	andi    t2, v0, 4			; we analyze third bit
	beq     t2, t3, v0_bit_2

	addi    t3, zero, 8
	andi    t2, v0, 8			; we analyze fourth bit
	beq     t2, t3, v0_bit_3

	

	no_button_pushed:
		addi v0, zero, 0
		jmpi analyze_with_head

	v0_bit_0:
		addi v0, zero, 1
		jmpi analyze_with_head
	v0_bit_1:
		addi v0, zero, 2
		jmpi analyze_with_head
	v0_bit_2:
		addi v0, zero, 3
		jmpi analyze_with_head
	v0_bit_3:
		addi v0, zero, 4
		jmpi analyze_with_head
	v0_bit_4:
		addi v0, zero, 5
		jmpi end_if


	analyze_with_head:
	; to test : 
	; input : in Buttons+4 :     1, 2, 0, 3, 4, 1, 5
	; output : in GSA(8*x + y) : 1, 2, 2, 2, 4, 4, 4

	; the value that we update is the word : 8*x + y, stocked in adress t0, that we must multiply by 4
	ldw     t1, HEAD_X(zero)
	add     t0, zero, t1
	slli    t0, t0, 3
	ldw     t1, HEAD_Y(zero)
	add     t0, t0, t1
	slli    t0, t0, 2


	; we recup the direction of the head of the snake : in t1
	ldw     t1, GSA(t0)

	; t1 : value of the direction of the head
	; v0 : value of the new button

	; if t1 == x and v0 == none => t1
	; if t1 == left and v0 == right ==> t1
	; if t1 == right and v0 == left ==> t1
	; if t1 == up and v0 == down ==> t1
	; if t1 == down and v0 == up ==> t1
	; else ==> v0
	; button state

	; t2 = none(0), t3 = left(1), t4 = up(2), t5 = down(3), t6 = right(4), t7 = checkpoint(5)
	addi    t2, zero, BUTTON_NONE
	addi    t3, zero, BUTTON_LEFT
	addi    t4, zero, BUTTON_UP
	addi    t5, zero, BUTTON_DOWN
	addi    t6, zero, BUTTON_RIGHT
	addi    t7, zero, BUTTON_CHECKPOINT


	beq     v0, t2, end_if 		; v0 == none => end_if
	beq     v0, t7, end_if 		; v0 == checkpoint => end_if
	beq     t1, t3, if_t1_left 	; t1 == left => if_t1_left
	beq     t1, t6, if_t1_right	; t1 == right => if_t1_right
	beq     t1, t4, if_t1_up	; t1 == up => if_t1_up
	beq     t1, t5, if_t1_down 	; t1 == down => if_t1_down


	;====================right/left======================
	if_t1_left:
		bne v0, t6, else_1 	; if v0 != right 
		if_v0_right:
			jmpi end_if 	; we don't update
		else_1:
			stw v0, GSA(t0) ; we update the value
			jmpi end_if
		
	if_t1_right:
		bne v0, t3, else_2 	; if v0 != left 
		if_v0_left:
			jmpi end_if 	; we don't update
		else_2:
			stw v0, GSA(t0) ; we update the value
			jmpi end_if

	;====================up/down=========================
	if_t1_up:
		bne v0, t5, else_3 	; if v0 != down 
		if_v0_down:
			jmpi end_if 	; we don't update
		else_3:
			stw v0, GSA(t0) ; we update the value
			jmpi end_if

	if_t1_down:
		bne v0, t4, else_4 	; if v0 != up 
		if_v0_up:
			jmpi end_if 	; we don't update
		else_4:
			stw v0, GSA(t0) ; we update the value
			jmpi end_if

	;====END====
	end_if: 

	ret

; END: get_input


; BEGIN: draw_array
draw_array:
	; push on the stack ;
	addi	sp, sp, -16
	stw		s0, 0(sp)
	stw		s1, 4(sp)
	stw		s2, 8(sp)
	stw		s3, 12(sp)

	; s1 = 0, it is a counter which goes from 0 to NB_CELLS	
	; It helps us to set leds by iterating over the GSA
	addi 	s0, zero, 0	
	addi 	s2, zero, NB_CELLS 	; s2 = NB_CELLS
	
	draw_array_loop:
		slli	t0, s0, 2
		ldw 	s1, GSA(t0)			; s1 = GSA at index s0 (s0 is the counter which goes from 0 to NB_CELLS)
		beq 	s1, zero, else_led	; if s1 is empty we don't light the led

		if_set_led:
			srli 	a0, s0, 3	; calculate x
			andi 	a1, s0, 7	; calculate y

			addi	s3, ra, 0	; store ra
			call 	set_pixel	; call set pixel with arg x and y
			addi	ra, s3, 0	; load ra
		else_led:

		addi 	s0, s0, 1					; update s0
		blt 	s0, s2, draw_array_loop		; loop if s0 (the counter) < NB_CELLS

	; pop the stack ;
	ldw 	s0, 0(sp)
	ldw 	s1, 4(sp)
	ldw 	s2, 8(sp)
	ldw		s3, 12(sp)
	addi	sp, sp, 16
	ret
; END: draw_array


; BEGIN: move_snake; 
move_snake:
	; push the stack
	addi	sp, sp, -16
	stw		s0, 0(sp)
	stw		s1, 4(sp)
	stw		s2, 8(sp)
	stw		s3, 12(sp)

	;; Update head's position ;;
	ldw     s0, HEAD_X(zero)	; s0 = HEAD_X
	ldw     s1, HEAD_Y(zero)	; s1 = HEAD_Y

	slli    s2, s0, 3		; s2 = HEAD_X * 8
	add     s2, s2, s1      ; s2 += HEAD_Y, so s2 = array index of the head
	slli	s2, s2, 2		; s2 *= 4 to access memory correctly

	ldw     s3, GSA(s2)		; s3 = direction of the head

	addi    t1, zero, DIR_LEFT		; const t1 = 1
	addi    t2, zero, DIR_UP		; const t2 = 2
	addi    t3, zero, DIR_DOWN		; const t3 = 3
	addi    t4, zero, DIR_RIGHT		; const t4 = 4

	beq     s3, t1, head_if_left	; if s3 == 1
	beq     s3, t2, head_if_up		; else if s3 == 2
	beq     s3, t3, head_if_down	; else if s3 == 3
	beq     s3, t4, head_if_right	; else if s3 == 4

	; Update head_x, head_y and GSA ;
	head_if_left:
		sub		s0, s0, t1
		stw     s0, HEAD_X(zero)
		stw		s3, GSA-32(s2)
		br head_if_end
	head_if_up:
		sub		s1, s1, t1
		stw		s1, HEAD_Y(zero)
		stw		s3, GSA-4(s2)
		br head_if_end
	head_if_down:
		add		s1, s1, t1
		stw		s1, HEAD_Y(zero)
		stw		s3, GSA+4(s2)
		br head_if_end
	head_if_right:
		add		s0, s0, t1
		stw		s0, HEAD_X(zero)
		stw		s3, GSA+32(s2)
	head_if_end:


	; If a0 = 1 (snake eats smg) we don't remove the tail;
	addi    t5, zero, 1
	beq     a0, t5, tail_if_end

	;; Update tail's position ;;
	;  Empty tail in GSA ;
	ldw     s0, TAIL_X(zero)	; s0 = TAIL_X
	ldw     s1, TAIL_Y(zero)	; s1 = TAIL_Y

	slli    s2, s0, 3		; s2 = TAIL_X * 8
	add     s2, s2, s1  	; s2 += TAIL_Y, so s2 = array index of the tail
	slli	s2, s2, 2		; s2 *= 4 to access memory correctly

	ldw		s3, GSA(s2)		; s3 = direction of tail

	stw		zero, GSA(s2)	; set the tail to empty in GSA

	;  Update tail_x and tail_y ;
	

	beq     s3, t1, tail_if_left	; if s3 == 1
	beq     s3, t2, tail_if_up		; else if s3 == 2
	beq     s3, t3, tail_if_down	; else if s3 == 3
	beq     s3, t4, tail_if_right	; else if s3 == 4

	tail_if_left:
		sub		s0, s0, t1
		stw     s0, TAIL_X(zero)
		br tail_if_end
	tail_if_up:
		sub		s1, s1, t1
		stw     s1, TAIL_Y(zero)
		br tail_if_end
	tail_if_down:
		add		s1, s1, t1
		stw     s1, TAIL_Y(zero)
		br tail_if_end
	tail_if_right:
		add		s0, s0, t1
		stw     s0, TAIL_X(zero)
	tail_if_end:

	; pop the stack
	ldw		s0, 0(sp)
	ldw		s1, 4(sp)
	ldw		s2, 8(sp)
	ldw		s3, 12(sp)
	addi	sp, sp, 16
	ret
; END: move_snake



; BEGIN: save_checkpoint
save_checkpoint:

	; score modulo 10, t0 is Score%10
	ldw     t0, SCORE(zero); score
	addi    t1, zero, 10
	loop_tens_sc:
		addi	t0, t0, -10				; update t2 (t2 += 10)
		bge 	t0, t1, loop_tens_sc	; continue to loop while t0 >= 10
	
	; if score%10 == 0 => is_Score_mod0
	beq  t0, zero, is_Score_mod0
	; else we go to the end
	addi    v0, zero, 0; return 0
	jmpi end_    


	is_Score_mod0: ; set the CP_VALID to one and save the current game state to the checkpoint memory region specified
		addi    t1, zero, 1
		stw     t1, CP_VALID(zero)	; set the CP_VALID to one
		
		;save the current game state to the checkpoint memory region specified
		; first save head_X and head_Y
		ldw     t0, HEAD_X(zero) 	; t0 is Head_X
		ldw     t1, HEAD_Y(zero)	; t1 is Head_Y
		stw     t0, CP_HEAD_X(zero)
		stw     t1, CP_HEAD_Y(zero)

		; then save tail_X and tail_Y
		ldw     t0, TAIL_X(zero) 	; t0 is tail_X
		ldw     t1, TAIL_Y(zero)	; t1 is tail_Y
		stw     t0, CP_TAIL_X(zero)
		stw     t1, CP_TAIL_Y(zero)

		; then save score
		ldw     t0, SCORE(zero) ; t0 is score
		stw     t0, CP_SCORE(zero)

		;then save the GSA
		addi    t0, zero, 0		; t0 is the pointer address to pick the data in GSA and store it to CP_GSA
		addi    t2, zero, 380	; t2 is a const
		loop_save:
			ldw     t1, GSA(t0) ; t1s is the data in GSA
			stw     t1, CP_GSA(t0)
			addi    t0, t0, 4
			blt     t0, t2, loop_save	; while t0 < 380


		addi v0, zero, 1	; return 1

	end_:

	ret
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
	;restore_checkpoint should be called when the player presses the checkpoint button to restore a game checkpoint 
	ldw     t0, CP_VALID(zero); t0 is CP_VALID
	addi    t1, zero, 1

	;if CP_VALID is valid
	beq     t0, t1, is_valid
	; else
	addi    v0, zero, 0; return 0
	jmpi end__

	is_valid :

		; first restore head_X and head_Y
		ldw     t0, CP_HEAD_X(zero) ; t0 is CP_Head_X
		ldw     t1, CP_HEAD_Y(zero)  ; t1 is CP_Head_Y
		stw     t0, HEAD_X(zero)
		stw     t1, HEAD_Y(zero)

		; then restore tail_X and tail_Y
		ldw     t0, CP_TAIL_X(zero) ; t0 is CP_tail_X
		ldw     t1, CP_TAIL_Y(zero)  ; t1 is CP_tail_Y
		stw     t0, TAIL_X(zero)
		stw     t1, TAIL_Y(zero)

		; then restore score
		ldw     t0, CP_SCORE(zero) ; t0 is CP_score
		stw     t0, SCORE(zero)

		;then restore the GSA
		addi    t0, zero, 0; t0 is the pointer address to pick the data in GSA and store it to CP_GSA
		addi    t2, zero, 380; t2 is a const
		loop_rest:
			ldw     t1, CP_GSA(t0) ; t1s is the data in CP_GSA
			stw     t1, GSA(t0)
			addi    t0, t0, 4
			blt     t0, t2, loop_rest; while t0 < 380
		 
		addi    v0, zero, 1; return 1

	end__:

	ret
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
	; push the stack
	addi	sp, sp, -4
	stw		s0, 0(sp)

	add		s0, zero, ra

	; Shut down the seven seg
	addi	t0, zero, 0
	stw		t0, SEVEN_SEGS(zero)
	stw		t0, SEVEN_SEGS+4(zero)
	stw		t0, SEVEN_SEGS+8(zero)
	stw		t0, SEVEN_SEGS+12(zero)
	
	call    wait_procedure
	add		ra, zero, s0

	; Call function to display score
	
	call 	display_score
	add		ra, zero, s0

	call    wait_procedure
	add		ra, zero, s0

	; Shut down the seven seg
	addi	t0, zero, 0
	stw		t0, SEVEN_SEGS(zero)
	stw		t0, SEVEN_SEGS+4(zero)
	stw		t0, SEVEN_SEGS+8(zero)
	stw		t0, SEVEN_SEGS+12(zero)

	call    wait_procedure
	add		ra, zero, s0

	; Call function to display score
	call 	display_score
	add		ra, zero, s0

	; pop the stack
	ldw		s0, 0(sp)
	addi	sp, sp, 4
	ret
; END: blink_score

wait_procedure:
	; 50 000 bc 20 us x 50000 = 1sec : 50000 = 10 x 5000
	addi t7, zero, 1000
	decrease_loop1:
		addi    t7, t7, -1
		addi    t0, zero, 5000 
		decrease_loop2 :
			addi    t0, t0, -1
			bne     t0, zero, decrease_loop2 ; while t0 != 0
		bne t7, zero, decrease_loop1; while t1 != 0
	
	ret