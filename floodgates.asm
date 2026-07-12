;================================================================================
; Floodgate Fixes
;--------------------------------------------------------------------------------
FloodGateAndMasterSwordFollowerReset:
	JSL.l MasterSwordFollowerClear
FloodGateReset:
	LDA.l PersistentFloodgate : BNE +
		LDA $7EF2BB : AND.b #$DF : STA $7EF2BB ; reset water outside floodgate
		LDA $7EF2FB : AND.b #$DF : STA $7EF2FB ; reset water outside swamp palace
		LDA $7EF216 : AND.b #$7F : STA $7EF216 ; clear water inside floodgate
		LDA $7EF051 : AND.b #$FE : STA $7EF051 ; clear water front room (room 40)
	+
FloodGateResetInner:
	LDA.l Bugfix_SwampWaterLevel : BEQ .done
		LDA.l ShuffleKeyDrops : BNE .check_room_55
	    LDA $279004 : BEQ .check_room_53 ; Only do the check for room 55 if on door rando or key drop shuffle
	.check_room_55
		LDA $7EF06F : AND.b #$04 : BEQ .drain_room_55 ; Check if key in room 55 has been collected. 
		LDA $7EF356 : AND.b #$01 : BNE .check_room_53 ; Check for flippers. This can otherwise softlock doors if flooded without flippers and no way to reset.
	.drain_room_55
		LDA $7EF06E : AND.b #$7F : STA $7EF06E ; clear water room 55 - outer room you shouldn't be able to softlock except in major glitches
	.check_room_53
		LDA $7EF06B : AND.b #$04 : BNE .done ; Check if key in room 53 has been collected.
		; no need to check for flippers on the inner room, as you can't get to the west door no matter what, without flippers.
		LDA $7EF06A : AND.b #$7F : STA $7EF06A ; clear water room 53 - inner room with the easy key flood softlock
	.done
RTL
;================================================================================

; Puzzle randomization can place the good Floodgate lever on the left side of the
; room. Pulling it from there leaves the camera farther west than vanilla expects,
; which makes the watergate HDMA window start partly off-screen.
;
; $E2 is the BG2 camera scroll mirror. The watergate object position in $0680
; still needs to be converted to screen space, but for this one room we clamp
; the effective camera position to the vanilla-ish right-lever view and clip the
; packed left/right HDMA bounds so the later gate opening intervals do not wrap
; and make the water disappear.

ClampFloodgateWatergateHdmaScroll:
	LDA $A0 : CMP.w #$010B : BNE .normal ; Dam/Floodgate room 267.
		LDA $E2 : CMP.w #$1660 : BCS .normal
			LDA $0680 : SEC : SBC.w #$1660
			RTL

	.normal
	LDA $0680 : SEC : SBC $E2
RTL
;================================================================================

BuildFloodgateWatergateLineBounds:
	STA $0C
	LDA $A0 : CMP.w #$010B : BEQ .clipped ; Dam/Floodgate room 267.

	.normal
	LDA $0C : CLC : ADC $0670 : STA $02
	LDA $0670 : SEC : SBC $0C : AND.w #$00FF : STA $00
	LDA $02 : AND.w #$00FF : XBA : ORA $00 : STA $0C
	RTL

	.clipped
	LDA $0670 : SEC : SBC $0C : BPL .leftInBounds
		LDA.w #$0000

	.leftInBounds
	AND.w #$00FF : STA $00

	LDA $0670 : CLC : ADC $0C
	CMP.w #$0100 : BCC .rightInBounds
		LDA.w #$00FF

	.rightInBounds
	AND.w #$00FF : XBA : ORA $00 : STA $0C
RTL
;================================================================================
