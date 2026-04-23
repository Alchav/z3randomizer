;================================================================================
; Dungeon & Boss Drop Fixes
;--------------------------------------------------------------------------------
!BOSS_PRIZE_ACTIVE = "$7F5047"
!BOSS_PRIZE_ROOM = "$7F5048"

DropSafeDungeon:
	LDA $040C : CMP #$08 : BEQ +
		LDA $01C6FC, X : JSL Sprite_SpawnFallingItem
	+
RTL
;--------------------------------------------------------------------------------
BossPrizeRoomTag:
	LDA BossPrizeShuffle : BEQ .vanilla
	JSL.l CheckIfBossRoom : BCC .vanilla

	LDA $0403 : AND.b #$80 : BEQ .heartContainerStillExists
	LDA $0403 : AND.b #$40 : BNE .criticalItemAlreadyObtained

	JSL.l LoadBossPrizeRoomValue
	JSL.l Sprite_SpawnFallingItem
	JSL.l SetBossPrizeContext
	BRA .clearTagFlag

.vanilla
	LDA $0403 : AND.b #$80 : BEQ .heartContainerStillExists

	LDA $040C : LSR A : TAX
	LDA $7EF3CA : BNE .inDarkWorld
		LDA $7EF374 : AND.l CrystalPendantFlags, X : BNE .criticalItemAlreadyObtained
		BRA .giveCriticalItem

.inDarkWorld
	LDA $7EF37A : AND.l CrystalPendantFlags, X : BNE .criticalItemAlreadyObtained

.giveCriticalItem
	LDA.b #$80 : STA $04C2
	LDA $0E : PHA
		LDA $040C : LSR A : TAX
		JSL.l DropSafeDungeon
	PLA : STA $0E
	BRA .clearTagFlag

.criticalItemAlreadyObtained
	JSL.l ClearBossPrizeContext

.clearTagFlag
	LDX $0E
	STZ $AE, X

.heartContainerStillExists
RTL
;--------------------------------------------------------------------------------
SetBossPrizeContext:
	LDA.b #$01 : STA !BOSS_PRIZE_ACTIVE
	PHP
	REP #$20
	LDA $A0 : STA !BOSS_PRIZE_ROOM
	PLP
RTL
;--------------------------------------------------------------------------------
ClearBossPrizeContext:
	LDA.b #$00
	STA !BOSS_PRIZE_ACTIVE
	STA !BOSS_PRIZE_ROOM
	STA !BOSS_PRIZE_ROOM+1
RTL
;--------------------------------------------------------------------------------
BossPrizeContextMatchesRoom:
	LDA BossPrizeShuffle : BEQ .mismatch
	LDA !BOSS_PRIZE_ACTIVE : BEQ .mismatch
	LDA $1B : BEQ .mismatch

	PHP
	REP #$20
	LDA !BOSS_PRIZE_ROOM : CMP $A0 : BNE .notCurrentRoom
	PLP
	SEC
	RTL

.notCurrentRoom
	PLP

.mismatch
	CLC
RTL
;--------------------------------------------------------------------------------
BossPrizeApplyItemPlayer:
	JSL.l BossPrizeContextMatchesRoom : BCC .done
	JSL.l BossPrizeGetPlayer : STA !MULTIWORLD_ITEM_PLAYER_ID
.done
RTL
;--------------------------------------------------------------------------------
MaybeCollectBossPrize:
	JSL.l BossPrizeContextMatchesRoom : BCC .done

	LDA $0403 : ORA.b #$40 : STA $0403
	JSL.l MarkBossPrizeDungeonCompletion
	JSL.l ClearBossPrizeContext
	JSL.l PrepDungeonExit

.done
RTL
;--------------------------------------------------------------------------------
MarkBossPrizeDungeonCompletion:
	LDA $040C
	CMP #$FF : BEQ .done
		LSR : AND #$0F : CMP #$08 : !BGE +
			JSR .valueShift
			ORA $7EF46B : STA $7EF46B
			BRA .done
		+
			!SUB #$08
			JSR .valueShift
			BIT.b #$C0 : BEQ ++ : LDA.b #$C0 : ++ ; Make Hyrule Castle / Sewers Count for Both
			ORA $7EF46C : STA $7EF46C
.done
RTL

.valueShift
	PHX
	TAX : LDA.b #$01
	-
		CPX #$00 : BEQ +
		ASL
		DEX
	BRA -
	+
	PLX
RTS
;--------------------------------------------------------------------------------
MaybeSetOrdinaryBossPrizeBits:
	CMP.b #$B6 : BNE +
		LDA $7EF374 : ORA.b #$04 : STA $7EF374
		SEC : RTL
	+ CMP.b #$B7 : BNE +
		LDA $7EF374 : ORA.b #$02 : STA $7EF374
		SEC : RTL
	+ CMP.b #$B8 : BNE +
		LDA $7EF374 : ORA.b #$01 : STA $7EF374
		SEC : RTL
	+ CMP.b #$B9 : BNE +
		LDA $7EF37A : ORA.b #$02 : STA $7EF37A
		SEC : RTL
	+ CMP.b #$BA : BNE +
		LDA $7EF37A : ORA.b #$10 : STA $7EF37A
		SEC : RTL
	+ CMP.b #$BB : BNE +
		LDA $7EF37A : ORA.b #$40 : STA $7EF37A
		SEC : RTL
	+ CMP.b #$BC : BNE +
		LDA $7EF37A : ORA.b #$20 : STA $7EF37A
		SEC : RTL
	+ CMP.b #$BD : BNE +
		LDA $7EF37A : ORA.b #$04 : STA $7EF37A
		SEC : RTL
	+ CMP.b #$BE : BNE +
		LDA $7EF37A : ORA.b #$01 : STA $7EF37A
		SEC : RTL
	+ CMP.b #$BF : BNE +
		LDA $7EF37A : ORA.b #$08 : STA $7EF37A
		SEC : RTL
	+
	CLC
RTL
;--------------------------------------------------------------------------------
MaybeIncrementOrdinaryBossPrizeCounts:
	CPY.b #$B6 : BCC .miss
	CPY.b #$B9 : BCS .checkCrystals
	LDA $7EF429 : INC : AND #$03 : TAX
	LDA $7EF429 : AND #$FC : STA $7EF429
	TXA : ORA $7EF429 : STA $7EF429
	SEC
	RTL

.checkCrystals
	CPY.b #$C0 : BCS .miss
	LDA $7EF422 : INC : AND #$07 : TAX
	LDA $7EF422 : AND #$F8 : STA $7EF422
	TXA : ORA $7EF422 : STA $7EF422
	SEC
	RTL

.miss
	CLC
RTL
;--------------------------------------------------------------------------------
LoadBossPrizeRoomValue:
	PHP
	REP #$20 ; set 16-bit accumulator
	LDA $A0 ; these are all decimal because i got them that way
	CMP.w #200 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_ArmosKnights, BossPrizeValues)
		BRL .done
	+ CMP.w #51 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Lanmolas, BossPrizeValues)
		BRL .done
	+ CMP.w #7 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Moldorm, BossPrizeValues)
		BRL .done
	+ CMP.w #90 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_HelmasaurKing, BossPrizeValues)
		BRL .done
	+ CMP.w #6 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Arrghus, BossPrizeValues)
		BRL .done
	+ CMP.w #41 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Mothula, BossPrizeValues)
		BRL .done
	+ CMP.w #172 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Blind, BossPrizeValues)
		BRL .done
	+ CMP.w #222 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Kholdstare, BossPrizeValues)
		BRL .done
	+ CMP.w #144 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Vitreous, BossPrizeValues)
		BRL .done
	+ CMP.w #164 : BNE +
		%GetPossiblyEncryptedItem(BossPrize_Trinexx, BossPrizeValues)
		BRL .done
	+
	LDA.w #$0000

.done
	AND.w #$00FF
	PLP
RTL
;--------------------------------------------------------------------------------
BossPrizeGetPlayer:
	PHP
	REP #$20 ; set 16-bit accumulator
	LDA $A0 ; these are all decimal because i got them that way
	CMP.w #200 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_ArmosKnights_Player)
		BRL .done
	+ CMP.w #51 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Lanmolas_Player)
		BRL .done
	+ CMP.w #7 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Moldorm_Player)
		BRL .done
	+ CMP.w #90 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_HelmasaurKing_Player)
		BRL .done
	+ CMP.w #6 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Arrghus_Player)
		BRL .done
	+ CMP.w #41 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Mothula_Player)
		BRL .done
	+ CMP.w #172 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Blind_Player)
		BRL .done
	+ CMP.w #222 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Kholdstare_Player)
		BRL .done
	+ CMP.w #144 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Vitreous_Player)
		BRL .done
	+ CMP.w #164 : BNE +
		%GetPossiblyEncryptedPlayerID(BossPrize_Trinexx_Player)
		BRL .done
	+
	LDA.w #$0000

.done
	AND.w #$00FF
	PLP
RTL
;--------------------------------------------------------------------------------
