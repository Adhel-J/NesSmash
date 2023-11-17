.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player1_x: .res 1
player1_y: .res 1
player1_dir: .res 1
player1_air: .res 1
player1_animframe: .res 1
player1_animframestate: .res 1
player1_dead: .res 1
player1_health: .res 1
scroll: .res 1
ppucrtl_settings: .res 1
pad1: .res 1
.exportzp player1_x, player1_y, player1_dir, player1_animframe, player1_air, player1_animframestate, player1_dead, player1_health, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

  JSR read_controller1

  ; update tiles *after* DMA transfer
	JSR update_player1
  JSR draw_player1

	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler
.import draw_starfield
;.import draw_planet
;.import draw_ground

.export main
.proc main
    ; write a palette
    LDX PPUSTATUS
    LDX #$3f
    STX PPUADDR
    LDX #$00
    STX PPUADDR
  load_palettes:
    LDA palettes,X
    STA PPUDATA
    INX
    CPX #$20
    BNE load_palettes

    LDX #$20
    JSR draw_starfield
    JSR display_health1
    ;JSR draw_planet
    ;JSR draw_ground

  vblankwait:       ; wait for another vblank before continuing
    BIT PPUSTATUS
    BPL vblankwait

    LDA #%10010000  ; turn on NMIs, sprites use first pattern table
    STA PPUCTRL
    LDA #%00011110  ; turn on screen
    STA PPUMASK

  forever:
    JMP forever
.endproc

.proc update_player1
    ; save registers
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA

    ; platform collision
  collision:
    LDA player1_dead
    CMP #$01
    BNE dead
    JMP check_done
    dead:

    LDX player1_x
    LDY player1_y

    CLC
    CPX #$3B ; left limit of the platform
    BPL platf
    BCC normContinue
    CPX #$A4 ; right empty space of the platform
    BPL normContinue 
    JMP Continue

    platf:

    LDA #$01
    STA player1_air
    CPY #$67
    BNE normContinue
    LDA #$00
    STA player1_air
    JMP Continue

    normContinue:
    CLC
    ; This section of code is incharge of making the chacter always fall to
    ; ground level
    LDY player1_y
    CPY #$AF
    BCC Continue_fall
    LDA #$00 
    STA player1_air
    JMP Continue      
    Continue_fall:
    INC player1_y        ; increase y position (top to bottom)

    Continue:
  
    LDY player1_air
    CPY #$01
    BEQ check_left

    LDY player1_dir
    CPY #$01
    BEQ drawright

    drawleft:

      LDA #%01000000  
      ; load the atribute into each of the 4 sprites
      STA $0202     
      STA $0206
      STA $020a
      STA $020e

      ; load the sprite into the screen
      LDA #$05
      STA $0201
      LDA #$04
      STA $0205
      LDA #$07
      STA $0209
      LDA #$06
      STA $020d

      JMP check_left


    drawright:

      LDA #%00000000

      STA $0202
      STA $0206
      STA $020a
      STA $020e

      LDA #$04
      STA $0201
      LDA #$05
      STA $0205
      LDA #$06
      STA $0209
      LDA #$07
      STA $020d

  check_left:
    LDA pad1        ; Load button presses
    AND #BTN_LEFT
    BNE check_LD
    JMP check_right
    check_LD:

    LDA #$00
    STA player1_dir

    LDA player1_air
    CMP #$01
    BNE Continue_left1
    JMP move_left
    Continue_left1:

    ; load sprite atribute to A, in this case flips the character to the left
    LDA #%01000000  
    ; load the atribute into each of the 4 sprites
    STA $0202     
    STA $0206
    STA $020a
    STA $020e

    LDA player1_animframe
    CMP #$09
    BNE frameselectl
    LDA #$00
    STA player1_animframe

    frameselectl:

      LDA player1_animframe
      CMP #$00
      BEQ frame0l
      CMP #$01
      BEQ frame0l
      CMP #$02
      BEQ frame0l
      CMP #$03
      BEQ frame1l
      CMP #$04
      BEQ frame1l
      CMP #$05
      BEQ frame1l
      CMP #$06
      BEQ frame2l
      CMP #$07
      BEQ frame2l
      CMP #$08
      BEQ frame2l

      INC player1_animframe

      JMP move_left

      frame0l:

      ; LDA #$00
      ; STA player1_animframe

      LDA #$09
      STA $0201
      LDA #$08
      STA $0205
      LDA #$0B
      STA $0209
      LDA #$0A
      STA $020d

      INC player1_animframe

      JMP move_left

      frame1l:

      LDA #$0D
      STA $0201
      LDA #$0C
      STA $0205
      LDA #$0F
      STA $0209
      LDA #$0E
      STA $020d

      INC player1_animframe

      JMP move_left

      frame2l:

      LDA #$11
      STA $0201
      LDA #$10
      STA $0205
      LDA #$13
      STA $0209
      LDA #$12
      STA $020d

      INC player1_animframe

      JMP move_left


    move_left: 
      ; stop the character from moving beyond left border
      LDX player1_x
      CPX #$02
      BCS Continue_left2
      JMP check_right
      Continue_left2:
      DEC player1_x
      DEC player1_x


      LDA player1_air
      CMP #$01
      BNE check_right

      ; LDA #%01000000
      ; STA $0202
      ; STA $0206
      ; STA $020a
      ; STA $020e

      ; LDA #$11
      ; STA $0201
      ; LDA #$10
      ; STA $0205
      ; LDA #$13
      ; STA $0209
      ; LDA #$12
      ; STA $020d

  check_right:
    LDA pad1        ; load button presses
    AND #BTN_RIGHT  ; filter out all but right
    BNE check_AD
    JMP check_a
    check_AD:

    LDA #$01
    STA player1_dir

    LDA player1_air
    CMP #$01
    BNE Continue_right1
    JMP move_right
    Continue_right1:

    ; load sprite atribute to A, in this case flips the character to the right
    LDA #%00000000

    ; load the atribute into each of the 4 sprites
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    ; load the sprite into the screen

    LDA player1_animframe
    CMP #$09
    BNE frameselectr
    LDA #$00
    STA player1_animframe

    frameselectr:

      LDA player1_animframe
      CMP #$00
      BEQ frame0r
      CMP #$01
      BEQ frame0r
      CMP #$02
      BEQ frame0r
      CMP #$03
      BEQ frame1r
      CMP #$04
      BEQ frame1r
      CMP #$05
      BEQ frame1r
      CMP #$06
      BEQ frame2r
      CMP #$07
      BEQ frame2r
      CMP #$08
      BEQ frame2r

      INC player1_animframe

      JMP move_right

      frame0r:

      ; LDA #$00
      ; STA player1_animframe

      LDA #$08
      STA $0201
      LDA #$09
      STA $0205
      LDA #$0A
      STA $0209
      LDA #$0B
      STA $020d

      INC player1_animframe

      JMP move_right

      frame1r:

      LDA #$0C
      STA $0201
      LDA #$0D
      STA $0205
      LDA #$0E
      STA $0209
      LDA #$0F
      STA $020d

      INC player1_animframe

      JMP move_right

      frame2r:

      LDA #$10
      STA $0201
      LDA #$11
      STA $0205
      LDA #$12
      STA $0209
      LDA #$13
      STA $020d

      INC player1_animframe

      JMP move_right

    move_right:

      ; stop the character from moving beyond left border
      LDX player1_x
      CPX #$F0
      BCC Continue_right
      JMP check_a
      Continue_right:
      INC player1_x
      INC player1_x

      LDA player1_air
      CMP #$01
      BNE check_a

  check_a:

    ; this section of the code will be removed to clear the way for jumping to be A and not B
    LDA pad1
    AND #BTN_A
    BEQ check_b

    ; LDA player1_dead
    ; CMP #$00
    ; BEQ check_b

    LDA #$01 
    STA player1_dead

    LDA #%00000000
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    LDA #$1C
    STA $0201
    LDA #$1D
    STA $0205
    LDA #$1E
    STA $0209
    LDA #$1F
    STA $020d

    LDA player1_dead
    CMP #$01

  check_b:

    ; code for jumping (jetpack activation)
    ; will be remapped to button A
    LDA pad1
    AND #BTN_B
    BNE checkS
    JMP check_select
    checkS:

    ;BEQ check_done

    LDA #$01
    STA player1_air

    LDA #%01000000
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    LDA #$11
    STA $0201
    LDA #$10
    STA $0205
    LDA #$13
    STA $0209
    LDA #$12
    STA $020d

    ; code to both check if the player is reaching the top of the screen and
    ; stop it from passing the border, and activate jetpack

    LDY player1_y
    CPY #$08
    BCS Continue_b
    JMP check_done
    Continue_b:
    DEC player1_y
    DEC player1_y
    DEC player1_y

    LDA player1_dir
    CMP #$01
    BEQ air_left

    LDA #%01000000
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    LDA #$15
    STA $0201
    LDA #$14
    STA $0205
    LDA #$17
    STA $0209
    LDA #$16
    STA $020d

    JMP check_done

    air_left:

    LDA #%00000000
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    LDA #$14
    STA $0201
    LDA #$15
    STA $0205
    LDA #$16
    STA $0209
    LDA #$17
    STA $020d


  check_select:


    LDA pad1
    AND #BTN_SELECT
    BNE checkD
    JMP check_start
    checkD:

    LDX player1_health
    DEX

  check_start:

    LDA pad1
    AND #BTN_START
    BEQ check_done

   LDY player1_dir
    CPY #$01
    BEQ drawrighthit

    drawlefthit:

      LDA #%01000000  
      ; load the atribute into each of the 4 sprites
      STA $0202     
      STA $0206
      STA $020a
      STA $020e

      ; load the sprite into the screen
      LDA #$0D
      STA $0201
      LDA #$0C
      STA $0205
      LDA #$23
      STA $0209
      LDA #$22
      STA $020d

      JMP check_done


    drawrighthit:

      LDA #%00000000

      STA $0202
      STA $0206
      STA $020a
      STA $020e

      LDA #$0C
      STA $0201
      LDA #$0D
      STA $0205
      LDA #$22
      STA $0209
      LDA #$23
      STA $020d

  
  check_done:
    ; restore registers and return
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc

; this function's only purpose is to draw the character sprite at the locations of
; player_x and player_y
; anything drawn inside this function will always be active, no matter whether the 
; character moves or not
.proc draw_player1
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; store tile locations
  ; top left tile:
  LDA player1_y
  STA $0200
  LDA player1_x
  STA $0203

  ; top right tile (x + 8):
  LDA player1_y
  STA $0204
  LDA player1_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player1_y
  CLC
  ADC #$08
  STA $0208
  LDA player1_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player1_y
  CLC
  ADC #$08
  STA $020c
  LDA player1_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc display_health1
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA

    LDA player1_health
    CMP #$AA
    BPL health13
    CMP #$55
    BPL health12
    CMP #$00
    BPL health11

    health13:

    LDA #$1F
    STA $0210 ; Y-coord of first sprite
    LDA #$20
    STA $0211 ; tile number of first sprite
    LDA #$02
    STA $0212 ; attributes of first sprite
    LDA #$1F
    STA $0213 ; X-coord of first sprite

    LDA #$27
    STA $0214 ; Y-coord of first sprite
    LDA #$20
    STA $0215 ; tile number of first sprite
    LDA #$02
    STA $0216 ; attributes of first sprite
    LDA #$1F
    STA $0217 ; X-coord of first sprite

    LDA #$2F
    STA $0218 ; Y-coord of first sprite
    LDA #$20
    STA $0219 ; tile number of first sprite
    LDA #$02
    STA $021A ; attributes of first sprite
    LDA #$1F
    STA $021B ; X-coord of first sprite

    JMP done_health 

    health12:

    LDA #$1F
    STA $0210 ; Y-coord of first sprite
    LDA #$20
    STA $0211 ; tile number of first sprite
    LDA #$02
    STA $0212 ; attributes of first sprite
    LDA #$1F
    STA $0213 ; X-coord of first sprite

    LDA #$27
    STA $0214 ; Y-coord of first sprite
    LDA #$20
    STA $0215 ; tile number of first sprite
    LDA #$02
    STA $0216 ; attributes of first sprite
    LDA #$1F
    STA $0217 ; X-coord of first sprite

    LDA #$2F
    STA $0218 ; Y-coord of first sprite
    LDA #$00
    STA $0219 ; tile number of first sprite
    LDA #$02
    STA $021A ; attributes of first sprite
    LDA #$00
    STA $021B ; X-coord of first sprite

    JMP done_health


    health11:

    LDA #$1F
    STA $0210 ; Y-coord of first sprite
    LDA #$20
    STA $0211 ; tile number of first sprite
    LDA #$02
    STA $0212 ; attributes of first sprite
    LDA #$1F
    STA $0213 ; X-coord of first sprite

    LDA #$27
    STA $0214 ; Y-coord of first sprite
    LDA #$00
    STA $0215 ; tile number of first sprite
    LDA #$02
    STA $0216 ; attributes of first sprite
    LDA #$00
    STA $0217 ; X-coord of first sprite

    LDA #$2F
    STA $0218 ; Y-coord of first sprite
    LDA #$00
    STA $0219 ; tile number of first sprite
    LDA #$02
    STA $021A ; attributes of first sprite
    LDA #$00
    STA $021B ; X-coord of first sprite

    done_health:

    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
  .byte $0C, $20, $00, $28
  .byte $0C, $2C, $27, $2A
  .byte $0C, $18, $27, $16
  .byte $0C, $20, $00, $27

  .byte $0C, $11, $27, $14 
  .byte $0C, $2C, $27, $2A
  .byte $0C, $18, $27, $16
  .byte $0C, $20, $00, $27

.segment "CHR"
.incbin "graphics.chr"
