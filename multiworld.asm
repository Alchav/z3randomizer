

macro Print_Text(hdr, hdr_len, player_id)
PHX : PHY : PHP
	REP #$30
	LDX #$0000
	-
	CPX <hdr_len> : !BGE ++
		LDA <hdr>, X
		STA !MULTIWORLD_HUD_CHARACTER_DATA, X
		INX #2
		BRA -
	++
	LDY <hdr_len>

	LDA <player_id>
	AND #$00FF
	DEC
	CMP #$00FF : !BGE .textdone
	ASL #5
	TAX
	-
	CPY <hdr_len>+$20 : !BGE ++
		LDA PlayerNames, X
		PHX : TYX : STA !MULTIWORLD_HUD_CHARACTER_DATA, X : PLX
		INX #2 : INY #2
		BRA -
	++

	TYX
	-
	CPX #$0040 : !BGE ++
		LDA #$007F
		STA !MULTIWORLD_HUD_CHARACTER_DATA, X
		INX #2
		BRA -
	++

	SEP #$20
	LDA #$01 : STA !NMI_AUX+1 : STA !NMI_AUX
	LDA !MULTIWORLD_HUD_DELAY
	STA !MULTIWORLD_HUD_TIMER
.textdone
PLP : PLY : PLX
endmacro

WriteText:
{
	PHA : PHX : PHP
		SEP #$10
		LDX $4340 : PHX ; preserve DMA parameters
		LDX $4341 : PHX ; preserve DMA parameters
		LDX $4342 : PHX ; preserve DMA parameters
		LDX $4343 : PHX ; preserve DMA parameters
		LDX $4344 : PHX ; preserve DMA parameters
		LDX $4345 : PHX ; preserve DMA parameters
		LDX $4346 : PHX ; preserve DMA parameters
		LDX $2115 : PHX ; preserve DMA parameters
		LDX $2116 : PHX ; preserve DMA parameters
		LDX $2117 : PHX ; preserve DMA parameters
		LDX $2100 : PHX : LDX.b #$80 : STX $2100 ; save screen state & turn screen off

		REP #$20
		LDX #$80 : STX $2115
		LDA #$6000+$0340 : STA $2116
		LDA.w #!MULTIWORLD_HUD_CHARACTER_DATA : STA $4342
		LDX.b #!MULTIWORLD_HUD_CHARACTER_DATA>>16 : STX $4344
		LDA #$0040 : STA $4345
		LDA #$1801 : STA $4340
		LDX #$10 : STX $420B

		PLX : STX $2100 ; put screen back however it was before
		PLX : STX $2117 ; restore DMA parameters
		PLX : STX $2116 ; restore DMA parameters
		PLX : STX $2115 ; restore DMA parameters
		PLX : STX $4346 ; restore DMA parameters
		PLX : STX $4345 ; restore DMA parameters
		PLX : STX $4344 ; restore DMA parameters
		PLX : STX $4343 ; restore DMA parameters
		PLX : STX $4342 ; restore DMA parameters
		PLX : STX $4341 ; restore DMA parameters
		PLX : STX $4340 ; restore DMA parameters
	PLP : PLX : PLA
RTL
}

GetMultiworldItem:
{
	PHP
	LDA !MULTIWORLD_ITEM : BNE +
	LDA !MULTIWORLD_HUD_TIMER : BNE +
		BRL .return
	+

	LDA $10
	CMP #$07 : BEQ +
	CMP #$09 : BEQ +
	CMP #$0B : BEQ +
		BRL .return
	+

	LDA !MULTIWORLD_HUD_TIMER : BEQ .textend
		DEC #$01 : STA !MULTIWORLD_HUD_TIMER
		CMP #$00 : BNE .textend
			; Clear text
			PHP : REP #$30
			LDX #$0000
			-
			CPX #$0040 : !BGE ++
				LDA #$007F
				STA !MULTIWORLD_HUD_CHARACTER_DATA, X
				INX #2
				BRA -
			++
			PLP
			LDA #$01 : STA !NMI_AUX+1 : STA !NMI_AUX
	.textend

	LDA $5D
	CMP #$00 : BEQ +
	CMP #$04 : BEQ +
	CMP #$17 : BEQ +
		BRL .return
	+

	LDA !MULTIWORLD_ITEM : BNE +
		BRL .return
	+

	PHA
	LDA #$22
	LDY #$04
	JSL Ancilla_CheckForAvailableSlot : BPL +
		PLA
		BRL .return
	+
	PLA

	; The added current-dungeon key ring cases make some branches exceed 8-bit
	; range, so near labels trampoline to the original key handling blocks.
	BRA .checkCurrentDungeonKey
	.thisdungeon_near
		BRL .thisdungeon
	.keyend_near
		BRL .keyend
	.checkCurrentDungeonKey

	; Check if we have a key for the dungeon we are currently in
	LDX $040C
	; Escape
	CMP #$A0 : BNE + : CPX #$00 : BEQ ++ : CPX #$02 : BEQ ++ : BRL .keyend : ++ : BRL .thisdungeon : +
	; Eastern
	CMP #$A2 : BNE + : CPX #$04 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; Desert
	CMP #$A3 : BNE + : CPX #$06 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; Hera
	CMP #$AA : BNE + : CPX #$14 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; Aga
	CMP #$A4 : BNE + : CPX #$08 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; PoD
	CMP #$A6 : BNE + : CPX #$0C : BEQ .thisdungeon_near : BRA .keyend_near : +
	; Swamp
	CMP #$A5 : BNE + : CPX #$0A : BEQ .thisdungeon_near : BRA .keyend_near : +
	; SW
	CMP #$A8 : BNE + : CPX #$10 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; TT
	CMP #$AB : BNE + : CPX #$16 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; Ice
	CMP #$A9 : BNE + : CPX #$12 : BEQ .thisdungeon_near : BRA .keyend_near : +
	; Mire
	CMP #$A7 : BNE + : CPX #$0E : BEQ .thisdungeon_near : BRA .keyend_near : +
	; TR
	CMP #$AC : BNE + : CPX #$18 : BNE ++ : BRL .thisdungeon : ++ : BRL .keyend : +
	; GT
	CMP #$AD : BNE + : CPX #$1A : BNE ++ : BRL .thisdungeon : ++ : BRL .keyend : +
	; GT BK
	CMP #$92 : BNE .keyend : CPX #$1A : BNE .keyend : LDA #$32 : BRA .keyend
	.thisdungeon
	LDA #$24
	.keyend

	STA $02D8 ;Set Item to receive
	TAY

	LDA #$01 : STA !MULTIWORLD_RECEIVING_ITEM
	LDA #$00 : STA !MULTIWORLD_ITEM_PLAYER_ID

	STZ $02E9
	JSL.l $0791B3 ; Player_HaltDashAttackLong
	JSL Link_ReceiveItem
	LDA #$00 : STA !MULTIWORLD_ITEM : STA !MULTIWORLD_RECEIVING_ITEM

	%Print_Text(HUD_ReceivedFrom, #$001C, !MULTIWORLD_ITEM_FROM)
	
	.return
	PLP
	LDA $5D : ASL A : TAX
RTL
}

Multiworld_OpenKeyedObject:
{
	PHP
	SEP #$20
	LDA ChestData_Player+2, X : STA !MULTIWORLD_ITEM_PLAYER_ID
	PLP

	LDA !Dungeon_ChestData+2, X ; thing we wrote over
RTL
}

Multiworld_BottleVendor_GiveBottle:
{
	PHA : PHP
	SEP #$20
	%GetPossiblyEncryptedItem(BottleMerchant, SpriteItemValues)
	TAY
	%GetPossiblyEncryptedPlayerID(BottleMerchant_Player)
	STA !MULTIWORLD_ITEM_PLAYER_ID
	PLP : PLA

	JSL Link_ReceiveItem ; thing we wrote over
RTL
}

Multiworld_MiddleAgedMan_ReactToSecretKeepingResponse:
{
	PHA : PHP
	SEP #$20
	%GetPossiblyEncryptedItem(PurpleChest_Item, SpriteItemValues)
	TAY
	%GetPossiblyEncryptedPlayerID(PurpleChest_Item_Player)
	STA !MULTIWORLD_ITEM_PLAYER_ID
	PLP : PLA

	JSL Link_ReceiveItem ; thing we wrote over
RTL
}

Multiworld_Hobo_GrantBottle:
{
	PHA : PHP
	SEP #$20
	%GetPossiblyEncryptedItem(HoboItem, SpriteItemValues)
	TAY
	%GetPossiblyEncryptedPlayerID(HoboItem_Player)
	STA !MULTIWORLD_ITEM_PLAYER_ID
	PLP : PLA

	JSL Link_ReceiveItem ; thing we wrote over
RTL
}

Multiworld_MasterSword_GrantToPlayer:
{
	PHA : PHP
	SEP #$20
	%GetPossiblyEncryptedItem(PedestalSword, SpriteItemValues)
	TAY
	%GetPossiblyEncryptedPlayerID(PedestalSword_Player)
	STA !MULTIWORLD_ITEM_PLAYER_ID : CMP #$00 : BNE + ; If the triforce is for another player, pedestal can stay pulled.
		LDA $0589B0 : CMP #$6A : BNE + ; If the item is not triforce, the pedestal can stay pulled.
		LDA InvincibleGanon : CMP #$06 : BNE + ; If the goal is pedestal ganon, then pedestal remains pulled, even though this pull caused a win.
		LDA $7EF300 : AND #$BF : STA $7EF300 ; Otherwise, reset the pedestal so that it can be pulled again after the full credit roll.
		+
	PLP : PLA

	JSL Link_ReceiveItem ; thing we wrote over
RTL
}

Multiworld_AddReceivedItem_notCrystal:
{
	TYA : STA $02E4 : PHX ; things we wrote over
	
	LDA !MULTIWORLD_ITEM_PLAYER_ID : BNE +
		JML.l AddReceivedItem_notCrystal+5
	+
		PHY : LDY $02D8 : JSL AddInventory : PLY

		%Print_Text(HUD_SentTo, #$0010, !MULTIWORLD_ITEM_PLAYER_ID)
		LDA #$33 : STA $012F

		JML.l AddReceivedItem_gfxHandling
}

Multiworld_Ancilla_ReceiveItem_stillInMotion:
{
	CMP.b #$28 : BNE + ; thing we wrote over
	LDA !MULTIWORLD_ITEM_PLAYER_ID : BNE +
		JML.l Ancilla_ReceiveItem_stillInMotion_moveon
	+
	JML.l Ancilla_ReceiveItem_dontGiveRupees
}

Multiworld_ConsumingFire_TransmuteToSkullWoodsFire:
{
	LDA $8A : AND.b #$40 : BEQ .failed ; things we wrote over
	LDA $0C4A : CMP #$22 : BEQ .failed
	LDA $0C4B : CMP #$22 : BEQ .failed
	LDA $0C4C : CMP #$22 : BEQ .failed
	LDA $0C4D : CMP #$22 : BEQ .failed
	LDA $0C4E : CMP #$22 : BEQ .failed
	LDA $0C4F : CMP #$22 : BEQ .failed

	JML.l ConsumingFire_TransmuteToSkullWoodsFire_continue

	.failed
	JML.l AddDoorDebris_spawn_failed
}
