;--------------------------------------------------------------------------------
; NewBatInit:
; make sure bats always load LW stats
;--------------------------------------------------------------------------------
NewBatInit:
	;check if map id == 240 or 241
	LDA $A0 : CMP #$F0 : BNE + ;oldman cave1
		BRA .light_world
	+
	CMP #$F1 : BNE + ;oldman cave2
		BRA .light_world
	+
	CMP #$B0 : BNE + ;agahnim statue keese
		BRA .light_world
	+
	CMP #$D0 : BNE + ;agahnim darkmaze
		BRA .light_world
	+

	CPY #$00 : BEQ .light_world
	LDA.b #$85 : STA $0CD2, X
	LDA.b #$04 : STA $0E50, X
RTL

	.light_world
		LDA.b #$80 : STA $0CD2, X
		LDA.b #$01 : STA $0E50, X
RTL
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; TransformSpriteAndClearSoldierProbes:
; Soldier weapons are temporary sprite $41 probes whose $0DB0 points to their
; parent sprite slot plus one. If the parent is transformed, a surviving probe
; treats the replacement fairy/blob as a soldier and writes an invalid AI state
; into it. Remove those probes before performing the original transformation.
;
; Input: A = replacement sprite ID, X = sprite being transformed.
;--------------------------------------------------------------------------------
TransformSpriteAndClearSoldierProbes:
	PHA
	LDA $00 : PHA
	TXA : INC A : STA $00
	PHY
	LDY.b #$0F
.next_probe
	LDA $0DD0, Y : BEQ .skip_probe
	LDA $0E20, Y : CMP.b #$41 : BNE .skip_probe
	LDA $0DB0, Y : CMP $00 : BNE .skip_probe
	LDA.b #$00 : STA $0DD0, Y
	STA $0DB0, Y
.skip_probe
	DEY : BPL .next_probe
	PLY
	PLA : STA $00
	PLA : STA $0E20, X
	JSL.l $06B818 ; Sprite_LoadProperties
	RTL
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; WallmastersStayDeadCheckDamage:
; optionally clear the active Wallmaster spawner when one of its spawned
; Wallmasters is killed, preventing further spawns in this room visit.
;--------------------------------------------------------------------------------
WallmastersStayDeadCheckDamage:
	JSL.l $06F2B0 ; Sprite_CheckDamageFromPlayerLong, what we wrote over
	LDA.l WallmastersStayDead : BEQ .return
	LDA $0DD0, X : CMP.b #$09 : BNE .clear_spawners
	LDA $0E20, X : CMP.b #$90 : BNE .clear_spawners ; transformed into another sprite
	LDA $0CE2, X : BEQ .return
	CMP.b #$FD : BEQ .clear_spawners ; incinerated
	CMP.b #$FB : BCS .return ; stunned or frozen, not killed
	CMP $0E50, X : BCC .return ; pending damage is not lethal
.clear_spawners
	PHX
	LDX.b #$07
.next_spawner
	LDA $0B00, X : CMP.b #$09 : BNE .skip_spawner
	STZ $0B00, X
.skip_spawner
	DEX : BPL .next_spawner
	PLX
.return
	RTL
;--------------------------------------------------------------------------------
