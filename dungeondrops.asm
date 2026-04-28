;================================================================================
; Dungeon & Boss Drop Fixes
;--------------------------------------------------------------------------------
!BOSS_PRIZE_ACTIVE = "$7F5047"
!BOSS_PRIZE_ROOM = "$7F5048"
!BOSS_PRIZE_SLOT = "$7F504A"
!BOSS_PRIZE_NARROW_SHADOW = "$7F504B"
!BOSS_PRIZE_DRAW_ACTIVE = "$7F504C"
!BOSS_PRIZE_DISPLAY_ITEM = "$7F504D"
!ITEM_BUSY = "$7F5091"

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
	JSL.l BossPrizeDungeonCompletionMatches : BCS .criticalItemAlreadyObtained
	LDA !ITEM_BUSY : BNE .heartContainerStillExists
	JSL.l BossPrizeSpawnReady : BCC .heartContainerStillExists

	LDA $0E : PHA
	JSL.l LoadBossPrizeRoomValue
	JSL.l SpawnBossPrizeFallingItem : BCC +
		PLA : STA $0E
		BRA .heartContainerStillExists
	+
	JSL.l SetBossPrizeContext
	PLA : STA $0E
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
	LDA.b #$FF : STA !BOSS_PRIZE_SLOT
	LDA.b #$00
	STA !BOSS_PRIZE_NARROW_SHADOW
	STA !BOSS_PRIZE_DRAW_ACTIVE
	STA !BOSS_PRIZE_DISPLAY_ITEM
RTL
;--------------------------------------------------------------------------------
SpawnBossPrizeFallingItem:
	PHA
	JSL.l BossPrizeResolveItem
	STA !BOSS_PRIZE_DISPLAY_ITEM
	PLA : PHA

	LDY.b #$04
	LDA.b #$29
	JSL.l AddAncillaLong : BCC .spawned
		PLA
		SEC
	RTL

	.spawned
	PLA : STA $0C5E, X
	LDA !BOSS_PRIZE_DISPLAY_ITEM : TAY

	PHX : PHB
		LDA.b #AddReceivedItemExpanded_item_graphics_indices>>16 : PHA : PLB
		LDA.w AddReceivedItemExpanded_item_graphics_indices, Y : STA $72
		CMP.b #$FF : BEQ .invalidItem
		CMP.b #$20 : BEQ .shieldItem
		CMP.b #$2D : BEQ .shieldItem
		CMP.b #$2E : BNE .getItemTiles
	.shieldItem
			TYA
			JSL.l GetSpriteID
			STA $72
			BRA .getItemTiles

		.invalidItem
		LDA.b #$00

		.getItemTiles
		JSL.l GetAnimatedSpriteTile_variable

		LDA $72 : CMP.b #$06 : BEQ .swordItem
		          CMP.b #$18 : BNE .notSwordItem
	.swordItem
			JSL.l BossPrizeDecompResolvedSwordGfx
		.notSwordItem
	PLB : PLX

	LDA.b #$D0 : STA $0294, X
	STZ $0C22, X
	STZ $0C2C, X
	STZ $0C54, X
	LDA.b #$80 : STA $029E, X
	LDA.b #$09 : STA $03B1, X
	STZ $03A4, X
	LDA.b #$05 : STA $0BF0, X
	STZ $039F, X
	STZ $0385, X
	STZ $0394, X

	LDA $0C5E, X : STA $02D8

	LDA $040C : CMP.b #$14 : BNE .normalCoords
		LDA $21 : AND.b #$FE : INC A : STA $01
		                               STZ $00
		LDA $23 : AND.b #$FE : INC A : STA $03
		                               STZ $02
		BRA .setCoords

	.normalCoords
	REP #$20
		LDA $E8 : !ADD.w #$0078 : STA $00
		LDA $E2 : !ADD.w #$0078 : STA $02
	SEP #$20

	.setCoords
	LDA !BOSS_PRIZE_DISPLAY_ITEM : TAY
	LDA.w AddReceivedItemExpanded_wide_item_flag, Y : BNE +
		REP #$20
		LDA $02 : !ADD.w #$0008 : STA $02
		SEP #$20
	+
	LDA $00 : STA $0BFA, X
	LDA $01 : STA $0C0E, X
	LDA $02 : STA $0C04, X
	LDA $03 : STA $0C18, X
	TXA : STA !BOSS_PRIZE_SLOT
	CLC
RTL
;--------------------------------------------------------------------------------
BossPrizeDecompResolvedSwordGfx:
	PHP
	SEP #$20
	LDA $7EF359 : PHA
	LDA !BOSS_PRIZE_DISPLAY_ITEM
	CMP.b #$49 : BEQ .fighterSword
	CMP.b #$01 : BEQ .masterSword
	CMP.b #$50 : BEQ .masterSword
	CMP.b #$02 : BEQ .temperedSword
	LDA.b #$04 : BRA .loadSword

.fighterSword
	LDA.b #$01 : BRA .loadSword

.masterSword
	LDA.b #$02 : BRA .loadSword

.temperedSword
	LDA.b #$03

.loadSword
	STA $7EF359
	JSL.l DecompSwordGfx
	JSL.l Palette_Sword
	PLA : STA $7EF359
	PLP
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
BossPrizeContextMatchesSlot:
	LDA !BOSS_PRIZE_SLOT : CMP.b #$FF : BEQ .mismatch
	TXA : CMP !BOSS_PRIZE_SLOT : BNE .mismatch
	SEC
	RTL

.mismatch
	CLC
RTL
;--------------------------------------------------------------------------------
BossPrizeReceiveContextMatches:
	LDA $02E9 : CMP.b #$03 : BNE .mismatch
	JSL.l BossPrizeContextMatchesRoom : BCC .mismatch
	JSL.l BossPrizeContextMatchesSlot : BCC .mismatch
	SEC
	RTL

.mismatch
	CLC
RTL
;--------------------------------------------------------------------------------
BossPrizeObjectContextMatches:
	LDA $0C54, X : CMP.b #$03 : BNE .mismatch
	JSL.l BossPrizeContextMatchesRoom : BCC .mismatch
	JSL.l BossPrizeContextMatchesSlot : BCC .mismatch
	SEC
	RTL

.mismatch
	CLC
RTL
;--------------------------------------------------------------------------------
BossPrizeApplyItemPlayer:
	JSL.l BossPrizeReceiveContextMatches : BCC .done
	JSL.l BossPrizeGetPlayer : STA !MULTIWORLD_ITEM_PLAYER_ID
.done
RTL
;--------------------------------------------------------------------------------
BossPrizeItemNeedsVictoryFanfare:
	JSL.l BossPrizeObjectContextMatches : BCC .noFanfare
	SEC
	RTL

.noFanfare
	CLC
RTL
;--------------------------------------------------------------------------------
BossPrizePendantWaitCheck:
	LDA $0C5E, X : CMP.b #$37 : BEQ .waitForMusic
	               CMP.b #$38 : BEQ .waitForMusic
	               CMP.b #$39 : BEQ .waitForMusic

	JSL.l BossPrizeItemNeedsVictoryFanfare : BCC .dontWaitForMusic

.waitForMusic
	JML.l PendantFanfareWait

.dontWaitForMusic
	JML.l PendantFanfareDone
;--------------------------------------------------------------------------------
HandleBossPrizeObjectFinished:
	JSL.l BossPrizeObjectContextMatches : BCC .normalObjectFinished
	JSL.l MarkBossPrizeDungeonCompletion
	JSL.l ClearBossPrizeContext

	LDA $7F509F : BEQ +
		LDA.b #$04 : STA $0C54, X
		JSL.l HideBossPrizeItemVisual
		STZ $1CF0 : STZ $1CF1
		JSL.l Main_ShowTextMessage_Alt
		LDA.b #$00 : STA $7F509F
		JML.l Ancilla_ReceiveItem_return
	+

	STZ $0C4A, X
	STZ $0FC1
	LDA $0C54, X : PHA : PHX
	JSL.l PrepDungeonExit
	PLX : PLA

	JML.l Ancilla_ReceiveItem_objectFinished+44

.normalObjectFinished
	STZ $0C4A, X
	STZ $0FC1
	JML.l Ancilla_ReceiveItem_objectFinished+6
;--------------------------------------------------------------------------------
HideBossPrizeItemVisual:
	PHP
	REP #$20
	LDA $E8 : SEC : SBC.w #$0018
	SEP #$20
	STA $0BFA, X
	XBA
	STA $0C0E, X

	REP #$20
	LDA $E2 : SEC : SBC.w #$0018
	SEP #$20
	STA $0C04, X
	XBA
	STA $0C18, X
	PLP
RTL
;--------------------------------------------------------------------------------
MarkBossPrizeDungeonCompletion:
	LDA $040C
	CMP #$FF : BEQ .done
		LSR : AND #$0F : CMP #$08 : !BGE +
			JSR BossPrizeValueShift
			ORA $7EF46B : STA $7EF46B
			BRA .done
		+
			!SUB #$08
			JSR BossPrizeValueShift
			BIT.b #$C0 : BEQ ++ : LDA.b #$C0 : ++ ; Make Hyrule Castle / Sewers Count for Both
			ORA $7EF46C : STA $7EF46C
.done
RTL

BossPrizeDungeonCompletionMatches:
	LDA $040C
	CMP #$FF : BEQ .mismatch
		LSR : AND #$0F : CMP #$08 : !BGE +
			JSR BossPrizeValueShift
			AND.l $7EF46B : BNE .match
			BRA .mismatch
		+
			!SUB #$08
			JSR BossPrizeValueShift
			BIT.b #$C0 : BEQ ++ : LDA.b #$C0 : ++
			AND.l $7EF46C : BNE .match

.mismatch
	CLC
RTL

.match
	SEC
RTL

BossPrizeValueShift:
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
BossPrizeResolveItem:
	PHA
	JSL.l BossPrizeGetPlayer : CMP.b #$00 : BEQ .local

.remote
	PLA
	RTL

.local
	PLA
	JSL.l AttemptItemSubstitutionLong
	CMP.b #$4E : BNE .notProgressiveMagic

.progressiveMagic
	LDA $7EF37B : BNE +
		RTL
	+
	LDA.b #$4F
	RTL

.notProgressiveMagic
	CMP.b #$5E : BNE .notProgressiveSword

.progressiveSword
	LDA $7EF359 : CMP.l ProgressiveSwordLimit : !BLT +
		LDA.l ProgressiveSwordReplacement : RTL
	+
	LDA $7EF359 : CMP.b #$FF : BNE +
		LDA.b #$49 : RTL
	+ : CMP.b #$00 : BNE +
		LDA.b #$49 : RTL
	+ : CMP.b #$01 : BNE +
		LDA.b #$50 : RTL
	+ : CMP.b #$02 : BNE +
		LDA.b #$02 : RTL
	+ LDA.b #$03 : RTL

.notProgressiveSword
	CMP.b #$5F : BNE .notProgressiveShield

.progressiveShield
	LDA !PROGRESSIVE_SHIELD : LSR #6 : CMP.l ProgressiveShieldLimit : !BLT +
		LDA.l ProgressiveShieldReplacement : RTL
	+
	LDA !PROGRESSIVE_SHIELD : AND.b #$C0 : BNE +
		LDA.b #$04 : RTL
	+ : CMP.b #$40 : BNE +
		LDA.b #$05 : RTL
	+ LDA.b #$06 : RTL

.notProgressiveShield
	CMP.b #$60 : BNE .notProgressiveArmor

.progressiveArmor
	LDA $7EF35B : CMP.l ProgressiveArmorLimit : !BLT +
		LDA.l ProgressiveArmorReplacement : RTL
	+
	LDA $7EF35B : CMP.b #$00 : BNE +
		LDA.b #$22 : RTL
	+ LDA.b #$23 : RTL

.notProgressiveArmor
	CMP.b #$61 : BNE .notProgressiveGlove

.progressiveGlove
	LDA $7EF354 : BNE +
		LDA.b #$1B : RTL
	+ LDA.b #$1C : RTL

.notProgressiveGlove
	CMP.b #$64 : BEQ .progressiveBow
	CMP.b #$65 : BNE .displayResolved

	.progressiveBow
	LDA $7EF340 : INC : LSR : CMP.l ProgressiveBowLimit : !BLT +
		LDA.l ProgressiveBowReplacement : RTL
	+
	LDA $7EF340 : INC : LSR : CMP.b #$00 : BNE +
		LDA.b #$3A : RTL
	+ LDA.b #$3B : RTL

	.displayResolved
		RTL
;--------------------------------------------------------------------------------
BossPrizeDrawPrep:
	LDA.b #$00
	STA !BOSS_PRIZE_NARROW_SHADOW
	STA !BOSS_PRIZE_DRAW_ACTIVE
	JSL.l BossPrizeContextMatchesRoom : BCC .restore
	JSL.l BossPrizeContextMatchesSlot : BCC .restore
	LDA.b #$01 : STA !BOSS_PRIZE_DRAW_ACTIVE
	LDA !BOSS_PRIZE_DISPLAY_ITEM : TAY
	LDA.w AddReceivedItemExpanded_wide_item_flag, Y : BNE .restore
	LDA.b #$01 : STA !BOSS_PRIZE_NARROW_SHADOW
	REP #$20
	LDA $02 : CLC : ADC.w #$0008 : STA $02
	SEP #$20

.restore
	REP #$20
	LDA $00 : CLC : ADC.w #$0008 : STA $08
	SEP #$20
	PHX
	LDA $0BF0, X : STA $74
	JML.l BossPrizeDrawContinue
;--------------------------------------------------------------------------------
BossPrizeMilestoneShadowPrep:
	SEP #$20
	LDA !BOSS_PRIZE_NARROW_SHADOW : BEQ .prepShadowY
		LDX.b #$02
		REP #$20
		LDA $02 : SEC : SBC.w #$0008 : STA $02
		BRA .shadowYReady

.prepShadowY
	REP #$20

.shadowYReady
	LDA $06 : CLC : ADC.w #$000C : STA $00
RTL
;--------------------------------------------------------------------------------
BossPrizeShiftUpperItemTileAndLoadWideItemFlag:
	PHX : PHY
	LDA !BOSS_PRIZE_DRAW_ACTIVE : BEQ .normalItem
		LDA !BOSS_PRIZE_DISPLAY_ITEM : TAX
		LDA.l AddReceivedItemExpanded_wide_item_flag, X : CMP.b #$02 : BEQ .loadWideFlag

		TYA : ASL #2 : TAY
		LDA ($90), Y : CLC : ADC.b #$04 : STA ($90), Y
		BRA .loadWideFlag

.normalItem
.loadWideFlag
	LDA.l AddReceivedItemExpanded_wide_item_flag, X
	PLY : PLX
RTL
;--------------------------------------------------------------------------------
BossPrizeLoadNarrowObject:
	PHX : PHY
	LDA !BOSS_PRIZE_DRAW_ACTIVE : BEQ .normalItem
		LDA !BOSS_PRIZE_DISPLAY_ITEM : TAX
		BRA .loadWideFlag

.normalItem
	TXA

.loadWideFlag
	LDA.l AddReceivedItemExpanded_wide_item_flag, X : STA ($92), Y
	CMP.b #$02 : BEQ .done
	LDA !BOSS_PRIZE_DRAW_ACTIVE : BEQ .done

	TYA : ASL #2 : TAY
	LDA ($90), Y : CLC : ADC.b #$04 : STA ($90), Y

.done
	PLY : PLX
RTL
;--------------------------------------------------------------------------------
BossPrizeMasterSwordSourceCheck:
	LDA $02E9 : CMP.b #$02 : BEQ .spriteSource
	JSL.l BossPrizeReceiveContextMatches : BCS .spriteSource
	JML.l BossPrizeMasterSwordSourceNormal

.spriteSource
	JML.l BossPrizeMasterSwordFromSprite
;--------------------------------------------------------------------------------
BossPrizeQueueFreeItemNotice:
	JSL.l BossPrizeReceiveContextMatches : BCC .done
	JSL.l BossPrizeGetPlayer : CMP.b #$00 : BNE .done
	LDA $02D8 : JSL.l FreeDungeonItemNotice
.done
RTL
;--------------------------------------------------------------------------------
BossPrizeSpawnReady:
	LDX.b #$09

.nextAncilla
	LDA $0C4A, X : CMP.b #$22 : BEQ .blocked
	DEX : BPL .nextAncilla
	SEC
	RTL

.blocked
	CLC
	RTL
;--------------------------------------------------------------------------------
BossPrizeReceiveDispatch:
	LDA $0C54, X : BEQ .fromTextOrObject
	CMP.b #$03 : BEQ .fromTextOrObject
	CMP.b #$04 : BEQ .waitForTextClose
	JML.l Ancilla_ReceiveItem_fromChestOrSprite

.fromTextOrObject
	JML.l Ancilla_ReceiveItem_fromTextOrObject

.waitForTextClose
	LDA $10 : CMP.b #$0E : BEQ .keepWaiting
	LDA $11 : BNE .keepWaiting
	LDA $1CD8 : BNE .keepWaiting

	STZ $0C4A, X
	STZ $0FC1
	LDA $0C54, X : PHA : PHX
	JSL.l PrepDungeonExit
	PLX : PLA
	JML.l Ancilla_ReceiveItem_objectFinished+44

.keepWaiting
	LDA.b #$01 : STA $02E4
	LDA.b #$01 : STA $0FC1
	JML.l Ancilla_ReceiveItem_return
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
