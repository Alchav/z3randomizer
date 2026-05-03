;--------------------------------------------------------------------------------
; $7F5010 - Scratch Space (Callee Preserved)
;--------------------------------------------------------------------------------
!GOAL_COUNTER = "$7EF418"
!GOAL_DRAW_ADDRESS = "$7EC72A"
;--------------------------------------------------------------------------------
; DrawGoalIndicator moved to newhud.asm
;--------------------------------------------------------------------------------
GoalItemGanonCheck:
	LDA $0E20, X : CMP.b #$D6 : BNE .success ; skip if not ganon
		JSL.l CheckGanonVulnerability
		BCS .success

		.fail
		LDA $0D80, X : CMP.b #17 : !BLT .success ; decmial 17 because Acmlm's chart is decimal
		LDA.b #$00
RTL
		.success
		LDA $44 : CMP.b #$80 ; thing we wrote over
RTL
;--------------------------------------------------------------------------------
;Carry clear = ganon invincible
;Carry set = ganon vulnerable
CheckGanonVulnerability:
	LDA InvincibleGanon : BEQ .success
		;#$00 = Off
	+ : CMP #$01 : BEQ .fail
		;#$01 = On
	+ : CMP #$02 : BNE +
		;#$02 = Require Number of Dungeons
		JSL CheckEnoughDungeonsForGanon : !BLT .fail ; require specified number of boss rooms/Aga fights
		BRA .success
	+ : CMP #$04 : BNE +
		;#$04 = Require Crystals
		JSL CheckEnoughCrystalsForGanon : !BLT .fail ; require specified number of crystals
		BRA .success
	+ : CMP #$03 : BNE +
		;#$03 = Require Crystals and Aga 2
		JSL CheckEnoughCrystalsForGanon : !BLT .fail ; require specified number of crystals
		LDA $7EF2DB : AND.b #$20 : CMP #$20 : BNE .fail ; require aga2 defeated (pyramid hole open)
		BRA .success
	+ : CMP #$05 : BNE +
		;#$05 = Require Goal Items
		REP #$20
		LDA.l !GOAL_COUNTER : CMP GoalItemRequirement : SEP #$20 : !BLT .fail ; require specified number of goal items
		BRA .success
	+ : CMP #$06 : BNE +
	    ;#$06 = Require pedestal to be pulled
		LDA $7EF300 : AND.b #$40 : CMP #$40 : BNE .fail ; require all pendants
		BRA .success
	+ 
.fail : CLC : RTL
.success : SEC : RTL
;--------------------------------------------------------------------------------
GetRequiredCrystalsForTower:
	BEQ + : JSL.l BreakTowerSeal_ExecuteSparkles : + ; thing we wrote over
	LDA.l NumberOfCrystalsRequiredForTower : CMP.b #$00 : BNE + : JML.l Ancilla_BreakTowerSeal_stop_spawning_sparkles : +
	LDA.l NumberOfCrystalsRequiredForTower : CMP.b #$01 : BNE + : JML.l Ancilla_BreakTowerSeal_draw_single_crystal : +
	LDA.l NumberOfCrystalsRequiredForTower : DEC #2 : TAX
JML.l GetRequiredCrystalsForTower_continue
;--------------------------------------------------------------------------------
GetRequiredCrystalsInX:
	LDA.l NumberOfCrystalsRequiredForTower : CMP.b #$00 : BNE +
		TAX
		RTL
	+

	TXA : - : CMP.l NumberOfCrystalsRequiredForTower : !BLT + : !SUB.l NumberOfCrystalsRequiredForTower : BRA - : +

	INC : CMP.l NumberOfCrystalsRequiredForTower : BNE +
		LDA.b #$08
	+ : DEC : TAX
RTL
;--------------------------------------------------------------------------------
CheckEnoughCrystalsForGanon:
	PHX : PHY
	LDA $7EF37A : JSL CountBits ; the comparison is against 1 less
	PLY : PLX
	CMP.l GanonRequirementCount
RTL
;--------------------------------------------------------------------------------
CheckEnoughDungeonsForGanon:
	PHX : PHY
	LDX.b #$00

	LDA.l $7EF191 : AND.b #$08 : BEQ + : INX : + ; Eastern Palace / Armos Knights
	LDA.l $7EF067 : AND.b #$08 : BEQ + : INX : + ; Desert Palace / Lanmolas
	LDA.l $7EF00F : AND.b #$08 : BEQ + : INX : + ; Tower of Hera / Moldorm
	LDA.l $7EF0B5 : AND.b #$08 : BEQ + : INX : + ; Palace of Darkness / Helmasaur King
	LDA.l $7EF00D : AND.b #$08 : BEQ + : INX : + ; Swamp Palace / Arrghus
	LDA.l $7EF053 : AND.b #$08 : BEQ + : INX : + ; Skull Woods / Mothula
	LDA.l $7EF159 : AND.b #$08 : BEQ + : INX : + ; Thieves' Town / Blind
	LDA.l $7EF1BD : AND.b #$08 : BEQ + : INX : + ; Ice Palace / Kholdstare
	LDA.l $7EF121 : AND.b #$08 : BEQ + : INX : + ; Misery Mire / Vitreous
	LDA.l $7EF149 : AND.b #$08 : BEQ + : INX : + ; Turtle Rock / Trinexx

	LDA.l $7EF041 : AND.b #$08 : BEQ + : INX : + ; Agahnim 1
	LDA.l $7EF01B : AND.b #$08 : BEQ + : INX : + ; Agahnim 2

	TXA
	PLY : PLX
	CMP.l GanonRequirementCount
RTL
;--------------------------------------------------------------------------------
CheckEnoughCrystalsForTower:
	PHX : PHY
	LDA $7EF37A : JSL CountBits ; the comparison is against 1 less
	PLY : PLX
	CMP.l NumberOfCrystalsRequiredForTower
RTL
