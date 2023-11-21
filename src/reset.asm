.include "constants.inc"

.segment "ZEROPAGE"
.importzp player1_x, player1_y, player1_dir, player1_animframe, player1_air, player1_animframestate, player1_dead, player1_health, pad1, player2_x, player2_y, player2_dir, player2_animframe, player2_air, player2_animframestate, player2_dead, player2_health, pad2

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPUCTRL
  STX PPUMASK

vblankwait:
  BIT PPUSTATUS
  BPL vblankwait

	LDX #$00
	LDA #$ff
clear_oam:
	STA $0200,X ; set sprite y-positions off the screen
	INX
	INX
	INX
	INX
	BNE clear_oam

vblankwait2:
	BIT PPUSTATUS
	BPL vblankwait2

	; initialize zero-page values
	LDA #$80
	STA player1_x
	LDA #$a0
	STA player1_y
	LDA #$00
	STA player1_dir
	STA player1_air
	STA player1_dead
	STA player1_animframe
	LDA #$00
	STA player1_animframestate
	LDA #$FF
	STA player1_health

	LDA #$8f
	STA player2_x
	LDA #$a0
	STA player2_y
	LDA #$00
	STA player2_dir
	STA player2_air
	STA player2_dead
	STA player2_animframe
	LDA #$00
	STA player2_animframestate
	LDA #$FF
	STA player2_health

  JMP main
.endproc
