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
