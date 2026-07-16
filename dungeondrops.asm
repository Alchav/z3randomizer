;================================================================================
; Dungeon & Boss Drop Fixes
;--------------------------------------------------------------------------------
!BOSS_PRIZE_ACTIVE = "$7F5047"
!BOSS_PRIZE_ROOM = "$7F5048"
!BOSS_PRIZE_SLOT = "$7F504A"
!BOSS_PRIZE_NARROW_SHADOW = "$7F504B"
!BOSS_PRIZE_DRAW_ACTIVE = "$7F504C"
!BOSS_PRIZE_DISPLAY_ITEM = "$7F504D"
!BOSS_PRIZE_X_OFFSET_APPLIED = "$7F504E"
!ITEM_BUSY = "$7F5091"

; Boss prize shuffle tracks one spawned receive-item ancilla so the normal
; receive-item draw and collection code can identify the shuffled prize path.
DropSafeDungeon:
	LDA $040C : CMP #$08 : BEQ +
		LDA $01C6FC, X : JSL Sprite_SpawnFallingItem
	+
RTL
;--------------------------------------------------------------------------------
; Replace the vanilla boss room tag handler. In shuffle mode this spawns the
; configured item as a falling receive-item object instead of the vanilla prize.
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
; Mark the current room as owning an active shuffled boss prize.
SetBossPrizeContext:
	LDA.b #$01 : STA !BOSS_PRIZE_ACTIVE
	PHP
	REP #$20
	LDA $A0 : STA !BOSS_PRIZE_ROOM
	PLP
RTL
;--------------------------------------------------------------------------------
; Clear all state used to recognize and draw the shuffled boss prize ancilla.
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
	STA !BOSS_PRIZE_X_OFFSET_APPLIED
RTL
;--------------------------------------------------------------------------------
; Spawn the shuffled prize with vanilla receive-item behavior and preload the
; display graphics for the resolved item that Link will actually show.
SpawnBossPrizeFallingItem:
	PHA
	JSL.l BossPrizeResolveItem
	JSL.l BossPrizeResolvePrizeLocationDisplayItem
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

	; Swords and shields need their freestanding/decompressed graphics, while
	; other items can use the normal received-item graphics index directly.
	PHX : PHB
		LDA.b #AddReceivedItemExpanded_item_graphics_indices>>16 : PHA : PLB
		LDA.w AddReceivedItemExpanded_item_graphics_indices, Y : STA $72
		CMP.b #$FF : BEQ .invalidItem
		TYA
		CMP.b #$49 : BEQ .freestandingSwordItem
		CMP.b #$01 : BEQ .freestandingSwordItem
		CMP.b #$50 : BEQ .freestandingSwordItem
		CMP.b #$02 : BEQ .freestandingSwordItem
		CMP.b #$03 : BEQ .freestandingSwordItem
		LDA $72
		CMP.b #$20 : BEQ .shieldItem
		CMP.b #$2D : BEQ .shieldItem
		CMP.b #$2E : BNE .getItemTiles

		.shieldItem
			TYA
			JSL.l GetSpriteID
			STA $72
			JSL.l BossPrizeDecompResolvedShieldGfx
			LDA $72
			BRA .getItemTiles

		.freestandingSwordItem
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
	LDA $00 : STA $0BFA, X
	LDA $01 : STA $0C0E, X
	LDA $02 : STA $0C04, X
	LDA $03 : STA $0C18, X
	TXA : STA !BOSS_PRIZE_SLOT
	CLC
RTL
;--------------------------------------------------------------------------------
; Temporarily present the resolved sword level to the vanilla sword decompressor.
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
; Temporarily present the resolved shield level to the vanilla shield decompressor.
BossPrizeDecompResolvedShieldGfx:
	PHP
	SEP #$20
	LDA $7EF35A : PHA
	LDA !BOSS_PRIZE_DISPLAY_ITEM
	CMP.b #$04 : BEQ .fighterShield
	CMP.b #$05 : BEQ .redShield
	LDA.b #$03 : BRA .loadShield

.fighterShield
	LDA.b #$01 : BRA .loadShield

.redShield
	LDA.b #$02

.loadShield
	STA $7EF35A
	JSL.l DecompShieldGfx
	JSL.l Palette_Shield
	PLA : STA $7EF35A
	PLP
RTL
;--------------------------------------------------------------------------------
; True when the current room is the room that spawned the active shuffled prize.
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
; True when X is the receive-item ancilla slot used by the shuffled prize.
BossPrizeContextMatchesSlot:
	LDA !BOSS_PRIZE_SLOT : CMP.b #$FF : BEQ .mismatch
	TXA : CMP !BOSS_PRIZE_SLOT : BNE .mismatch
	SEC
	RTL

.mismatch
	CLC
RTL
;--------------------------------------------------------------------------------
; True while Link is receiving the tracked shuffled boss prize.
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
; True while the tracked boss-prize ancilla is still being animated.
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
; Every fourth received Piece of Heart obtained is converted into a second
; receive-item animation, then the original ancilla is cleared without entering
; the ordinary object-finished path. If that original item was a shuffled boss
; prize, move the boss-prize context to the new completion-heart ancilla so the
; existing finish hook can warp after the full-heart animation ends.
BossPrizeRetargetHeartPieceCompletion:
	JSL.l BossPrizeObjectContextMatches : BCC .done
	PHX
	LDX.b #$09

.nextAncilla
	LDA $0C4A, X : CMP.b #$22 : BNE .next
	LDA $0C5E, X : CMP.b #$26 : BNE .next
	LDA.b #$03 : STA $0C54, X
	TXA : STA !BOSS_PRIZE_SLOT
	BRA .found

.next
	DEX : BPL .nextAncilla

.found
	PLX

.done
RTL
;--------------------------------------------------------------------------------
; Replacement for the vanilla Piece of Heart completion branch in receive-item
; object cleanup. This preserves the normal completion-heart animation and adds
; the boss-prize retargeting above before clearing the original receive object.
BossPrizeHeartPieceCompletionBranch:
	PHX
	LDY.b #$26
	JSL.l Link_ReceiveItem
	PLX
	JSL.l BossPrizeRetargetHeartPieceCompletion
	STZ $0C4A, X
	STZ $0FC1
RTL
;--------------------------------------------------------------------------------
; Mark the location check and apply the configured multiworld recipient before
; the item is granted.
BossPrizeApplyItemPlayer:
	JSL.l BossPrizeReceiveContextMatches : BCC .done
	JSL.l MarkBossPrizeDungeonCompletion
	JSL.l BossPrizeGetPlayer : STA !MULTIWORLD_ITEM_PLAYER_ID
	.done
RTL
;--------------------------------------------------------------------------------
; Non-pendant shuffled prizes still need the victory fanfare before warping out.
BossPrizeItemNeedsVictoryFanfare:
	JSL.l BossPrizeObjectContextMatches : BCC .noFanfare
	SEC
	RTL

.noFanfare
	CLC
RTL
;--------------------------------------------------------------------------------
; Extend the pendant music wait to any shuffled boss prize that uses the victory fanfare.
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
; Finish a shuffled boss prize by showing deferred text if needed, then routing
; to the dungeon-exit path.
HandleBossPrizeObjectFinished:
	JSL.l BossPrizeObjectContextMatches : BCC .normalObjectFinished
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
; Move the item object offscreen while deferred text owns the receive-item state.
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
; Record shuffled boss-prize completion separately from vanilla pendant/crystal bits.
MarkBossPrizeDungeonCompletion:
	JSR BossPrizeRoomCompletionMask : BCC .done
	CPX.b #$01 : BEQ .highByte
		ORA $7EF46B : STA $7EF46B
		BRA .done
	.highByte
		ORA $7EF46C : STA $7EF46C
.done
RTL

; Check the shuffled boss-prize completion bit for the current boss-prize room.
BossPrizeDungeonCompletionMatches:
	JSR BossPrizeRoomCompletionMask : BCC .mismatch
	CPX.b #$01 : BEQ .highByte
		AND.l $7EF46B : BNE .match
		BRA .mismatch
	.highByte
		AND.l $7EF46C : BNE .match

.mismatch
	CLC
RTL

.match
	SEC
RTL

; Map the current boss room to the boss-prize completion byte and mask used by
; the client. Carry set on match. X=0 means $7EF46B; X=1 means $7EF46C.
BossPrizeRoomCompletionMask:
	REP #$20 ; set 16-bit accumulator
	LDA $A0
	CMP.w #200 : BNE +
		SEP #$20 : LDA.b #$04 : LDX.b #$00 : SEC : RTS
	+ CMP.w #51 : BNE +
		SEP #$20 : LDA.b #$08 : LDX.b #$00 : SEC : RTS
	+ CMP.w #7 : BNE +
		SEP #$20 : LDA.b #$04 : LDX.b #$01 : SEC : RTS
	+ CMP.w #90 : BNE +
		SEP #$20 : LDA.b #$40 : LDX.b #$00 : SEC : RTS
	+ CMP.w #6 : BNE +
		SEP #$20 : LDA.b #$20 : LDX.b #$00 : SEC : RTS
	+ CMP.w #41 : BNE +
		SEP #$20 : LDA.b #$01 : LDX.b #$01 : SEC : RTS
	+ CMP.w #172 : BNE +
		SEP #$20 : LDA.b #$08 : LDX.b #$01 : SEC : RTS
	+ CMP.w #222 : BNE +
		SEP #$20 : LDA.b #$02 : LDX.b #$01 : SEC : RTS
	+ CMP.w #144 : BNE +
		SEP #$20 : LDA.b #$80 : LDX.b #$00 : SEC : RTS
	+ CMP.w #164 : BNE +
		SEP #$20 : LDA.b #$10 : LDX.b #$01 : SEC : RTS
	+
	SEP #$20
	CLC
RTS

; Tag routine 0x16 "clear level to open doors". In shuffled-prize mode,
; use the boss-prize completion bits instead of vanilla pendant/crystal bits.
BossPrizeClearLevelToOpenDoors:
	LDA BossPrizeShuffle : BEQ .vanilla
	JSL.l CheckIfBossRoom : BCC .vanilla
	JSL.l BossPrizeDungeonCompletionMatches : BCS .openDoors
	BRA .dontHaveGoalItem

.vanilla
	LDA $040C : LSR A : TAX
	LDA.l CrystalPendantFlags_2, X : BNE .inDarkWorld
		LDA $7EF374 : AND.l CrystalPendantFlags, X : BNE .openDoors
		BRA .dontHaveGoalItem

.inDarkWorld
	LDA $7EF37A : AND.l CrystalPendantFlags, X : BEQ .dontHaveGoalItem

.openDoors
	REP #$30
	STZ $0468
	STZ $068E
	STZ $0690
	SEP #$30
	LDA.b #$05 : STA $11
	LDX $0E
	STZ $AE, X

.dontHaveGoalItem
	SEP #$30
RTL

; Convert a dungeon index into a single-bit mask for completion storage.
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
; Resolve progressive/substituted local prizes for display before the item is granted.
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
; Boss-prize Null/trap items use the blank received-item graphic. Show a random
; ordinary item graphic at the prize location while keeping the real item ID.
BossPrizeResolvePrizeLocationDisplayItem:
	PHA : PHY : PHB
		TAY
		LDA.b #AddReceivedItemExpanded_item_graphics_indices>>16 : PHA : PLB
		LDA.w AddReceivedItemExpanded_item_graphics_indices, Y
		CMP.b #$47 : BEQ .randomDisguise
	PLB : PLY : PLA
RTL

.randomDisguise
	PLB : PLY : PLA
	JSL.l GetRandomInt : AND.b #$3F
	BNE + : LDA.b #$49 : +
	CMP.b #$26 : BNE + : LDA.b #$6A : +
RTL
;--------------------------------------------------------------------------------
; Prepare receive-item drawing to use the resolved boss-prize display item.
BossPrizeDrawPrep:
	LDA.b #$00
	STA !BOSS_PRIZE_NARROW_SHADOW
	STA !BOSS_PRIZE_DRAW_ACTIVE
	STA !BOSS_PRIZE_X_OFFSET_APPLIED
	LDA $0C4A, X : CMP.b #$29 : BNE .restore
	JSL.l BossPrizeContextMatchesRoom : BCC .restore
	JSL.l BossPrizeContextMatchesSlot : BCC .restore
	LDA.b #$01 : STA !BOSS_PRIZE_DRAW_ACTIVE
	PHX
	LDA !BOSS_PRIZE_DISPLAY_ITEM : TAX
	JSR.w BossPrizeLoadDisplayWideItemFlag
	PLX
	CMP.b #$00 : BEQ .narrowItem
	JSR.w BossPrizeApplyDisplayXOffset
	BRA .restore

.narrowItem
	LDA.b #$01 : STA !BOSS_PRIZE_NARROW_SHADOW

.restore
	REP #$20
	LDA $00 : CLC : ADC.w #$0008 : STA $08
	SEP #$20
	PHX
	LDA $0BF0, X : STA $74
	JML.l BossPrizeDrawContinue
;--------------------------------------------------------------------------------
; Undo any boss-prize X adjustment before the milestone-item shadow is drawn.
BossPrizeMilestoneShadowPrep:
	SEP #$20
	LDA !BOSS_PRIZE_X_OFFSET_APPLIED : BEQ .drawShadow
		JSR.w BossPrizeUndoDisplayXOffset

.drawShadow
	LDA !BOSS_PRIZE_NARROW_SHADOW : BEQ .prepShadowY
		LDX.b #$02
		BRA .prepShadowY

.prepShadowY
	REP #$20

.shadowYReady
	LDA $06 : CLC : ADC.w #$000C : STA $00
RTL
;--------------------------------------------------------------------------------
; Match vanilla receive-item X centering for the resolved boss-prize item.
BossPrizeApplyDisplayXOffset:
	PHX : PHY
	LDA !BOSS_PRIZE_DISPLAY_ITEM : TAY
	JSR.w BossPrizeLoadDisplayXOffset
	BEQ .shiftRight
	BRA .done

.shiftRight
	LDA.b #$01 : STA !BOSS_PRIZE_X_OFFSET_APPLIED
	REP #$20
	LDA $02 : CLC : ADC.w #$0001 : STA $02
	SEP #$20

.done
	PLY : PLX
RTS
;--------------------------------------------------------------------------------
; Restore the draw X position after the boss-prize item body is drawn.
BossPrizeUndoDisplayXOffset:
	PHX : PHY
	LDA !BOSS_PRIZE_DISPLAY_ITEM : TAY
	JSR.w BossPrizeLoadDisplayXOffset
	BEQ .shiftLeft
	BRA .done

.shiftLeft
	REP #$20
	LDA $02 : SEC : SBC.w #$0001 : STA $02
	SEP #$20

.done
	PLY : PLX
RTS
;--------------------------------------------------------------------------------
; Treat freestanding swords as wide sprites even though their item IDs bypass the table.
BossPrizeLoadDisplayWideItemFlag:
	TXA
	CMP.b #$49 : BEQ .wideSword
	CMP.b #$01 : BEQ .wideSword
	CMP.b #$50 : BEQ .wideSword
	CMP.b #$02 : BEQ .wideSword
	CMP.b #$03 : BEQ .wideSword
	LDA.l AddReceivedItemExpanded_wide_item_flag, X
	RTS

.wideSword
	LDA.b #$02
RTS
;--------------------------------------------------------------------------------
; Load the display item's X offset, ignoring offsets for narrow item layouts.
BossPrizeLoadDisplayXOffset:
	TYA
	TAX
	JSR.w BossPrizeLoadDisplayWideItemFlag : BEQ .ignore
	LDA.l AddReceivedItemExpanded_x_offsets, X
	RTS

.ignore
	LDA.b #$04
RTS
;--------------------------------------------------------------------------------
; Use the resolved display item when the upper tile of a boss-prize object is drawn.
BossPrizeShiftUpperItemTileAndLoadWideItemFlag:
	PHX : PHY
	LDA !BOSS_PRIZE_DRAW_ACTIVE : BEQ .normalItem
		LDA !BOSS_PRIZE_DISPLAY_ITEM : TAX
		JSR.w BossPrizeLoadDisplayWideItemFlag : CMP.b #$02 : BEQ .done

	.narrowItem
		TYA : ASL #2 : TAY
		LDA ($90), Y : CLC : ADC.b #$04 : STA ($90), Y
		LDA !BOSS_PRIZE_DISPLAY_ITEM : TAX
		BRA .loadWideFlag

.normalItem
.loadWideFlag
	LDA.l AddReceivedItemExpanded_wide_item_flag, X
	BRA .done

.done
	PLY : PLX
RTL
;--------------------------------------------------------------------------------
; Store the resolved display item's narrow/wide flag into the OAM size buffer.
BossPrizeLoadNarrowObject:
	PHX : PHY
	LDA !BOSS_PRIZE_DRAW_ACTIVE : BEQ .normalItem
		LDA !BOSS_PRIZE_DISPLAY_ITEM : TAX
		JSR.w BossPrizeLoadDisplayWideItemFlag
		BRA .storeWideFlag

.normalItem
	LDA.l AddReceivedItemExpanded_wide_item_flag, X

.storeWideFlag
	STA ($92), Y
	CMP.b #$02 : BEQ .done
	LDA !BOSS_PRIZE_DRAW_ACTIVE : BEQ .done

	TYA : ASL #2 : TAY
	LDA ($90), Y : CLC : ADC.b #$04 : STA ($90), Y

.done
	PLY : PLX
RTL
;--------------------------------------------------------------------------------
; Boss-prize swords should use the sprite/freestanding source path, not the held-up source.
BossPrizeMasterSwordSourceCheck:
	LDA $02E9 : CMP.b #$02 : BEQ .spriteSource
	JSL.l BossPrizeReceiveContextMatches : BCS .spriteSource
	JML.l BossPrizeMasterSwordSourceNormal

.spriteSource
	JML.l BossPrizeMasterSwordFromSprite
;--------------------------------------------------------------------------------
; Show "free dungeon item" text for local shuffled boss prizes after substitution.
BossPrizeQueueFreeItemNotice:
	JSL.l BossPrizeReceiveContextMatches : BCC .done
	JSL.l BossPrizeGetPlayer : CMP.b #$00 : BNE .done
	LDA $02D8 : JSL.l FreeDungeonItemNotice
.done
RTL
;--------------------------------------------------------------------------------
; Avoid spawning the prize while another receive-item ancilla is still active.
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
; Route boss-prize receive states through object/text handling and wait for text close.
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
; Ordinary pendant/crystal item IDs collected outside boss rooms still set vanilla bits.
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
; Count ordinary pendant/crystal item IDs for inventory and stats displays.
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
; Map the current boss room to its configured shuffled prize item.
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
; Map the current boss room to the configured multiworld recipient.
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
