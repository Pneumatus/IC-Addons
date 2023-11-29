GUIFunctions.AddTab("NrakkUltMaster")

Gui, ICScriptHub:Tab, NrakkUltMaster
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, NrakkUltMaster
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5 w450 wrap, This AddOn will use Nrakk's ultimate to generate Ki points. It will activate Nrakk's ultimate and attempt to hit all 10 reactivation triggers for a total of 30 Ki Points.
Gui, ICScriptHub:Add, Text, x15 y+5 w450 wrap, If Dungeon Master is in the formation and has his ultimate off of cooldown, it will be used to reset Nrakks's ultimate timer and attempt to gain another 30 Ki Points.
Gui, ICScriptHub:Add, Text, x15 y+5 w450 wrap, It is reccomended that auto-progress is disabled so that you don't accidentally transition mid-ultimate.

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNrakkUltMaster_Run, Run
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNrakkUltMaster_Stop, Stop

Gui, ICScriptHub:Add, Text, x15 y+10 vNrakkUltMaster_Status w300,
Gui, ICScriptHub:Add, Text, x15 y+10 vNrakkUltMaster_Status2 w300,

global g_NrakkUltMaster := new NrakkUltMaster()
NrakkUltMaster_Run() {
    ; initialize shared functions for directed inputs
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    g_SF.Memory.OpenProcessReader()
    g_SF.Memory.ActiveEffectKeyHandler.Refresh()
    g_NrakkUltMaster.Run()
}

NrakkUltMaster_Stop() {
    if (g_NrakkUltMaster.IsRunning() == False) {
        MsgBox Nrakk Ult Master isn't running
        return
    }
    g_NrakkUltMaster.Stop()
}

class NrakkUltMaster {

    stopping := False
    running := False

    IsRunning() {
        return this.running
    }

    Run() {
        this.stopping := False
        this.running := True
        GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Running Ult Master"
        ultButton := g_SF.GetUltimateButtonByChampID(24)
        if (ultButton <= 0) {
            this.running := False
            GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult not found!"
            return
        }
        ultReady := this.isUltReady(ultButton)
        if (ultReady == False) {
            this.running := False
            GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult not ready!"
            return
        }
        attacks := this.farmUlt(ultButton)
        maxAttacks := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadMaxAttacks()
        if (attacks != maxAttacks) {
            return ; don't go on to using DM ult if we didn't get max first time
        }
        if (this.stopping == True) {
            this.stopping := False
            this.running := False
            return
        }

        ; If DM is in the formation and has ult ready, try using that to reset Nrakk's ult
        ; and run the farm again for more stacks...
        dmUltButton := g_SF.GetUltimateButtonByChampID(99)
        if (dmUltButton > 0) {
            GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Found DM ult - attempting to use it to reset Nrakk to improve on " attacks " attacks..."
            dmUltReady := this.isUltReady(dmUltButton)
            if (dmUltReady == True) {
                g_SF.DirectedInput(,, dmUltButton) ; DM ult - reset cooldown
                ultReady := False
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Waiting for Nrakk ult ready after DM ult to improve on " attacks " attacks..."
                Loop 500 { ; wait for ready
                    ultReady := this.isUltReady(ultButton)
                    if (ultReady == True) { ; also make sure that the handler has reset properly...
                        attacksCounter := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadAttacksCounter()
                        if (attacksCounter == 0) {
                            break
                        }
                    }
                    Sleep, 10
                }
                if (ultReady == True) {
                    this.farmUlt(ultButton, attacks)
                }
            }
        }
        this.running := False
        this.stopping := False
    }

    Stop() {
        this.stopping := True
        GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master Stopping
    }

    farmUlt(ultButton, attacksOffset := 0) {
        initialFillPercent := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadLastSetFilledPercent()
        g_SF.DirectedInput(,, ultButton) ; ult
        loop { ; wait for bar to start moving
            currFillPercent := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadLastSetFilledPercent()
            if (initialFillPercent != currFillPercent) {
                break
            }
            if (this.stopping == True) {
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master Stopped
                return
            }
            Sleep, 5
        }

        attacksCounter := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadAttacksCounter()
        maxAttacks := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadMaxAttacks()
        GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult Running - Attack Counter: "(attacksCounter + attacksOffset) "/" (maxAttacks + attacksOffset)

        loop { ; main loop
            if (this.stopping == True) {
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master Stopped
                return
            }
            inArc := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadInTargetArc()
            lastSetFilledPercent := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadLastSetFilledPercent()
            lastSetTargetArcPercent := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadLastSetTargetArcPercent()
            GuiControl, ICScriptHub:, NrakkUltMaster_Status2, % (lastSetFilledPercent * 100) "% - Target: " ((1 - lastSetTargetArcPercent) * 100) "% - In Arc? " (inArc ? "True" : "False")
            if (inArc) {
                g_SF.DirectedInput(,, ultButton)
                ; Wait for the attack counter to increment or the ult to become unready(fail)
                Loop { ; wait for ready
                    attacksCounter := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadAttacksCounter()
                    maxAttacks := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadMaxAttacks()
                    if (attacksCounter == maxAttacks) {
                        GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult Master Finished Successfully - "(attacksCounter + attacksOffset) "/" (maxAttacks + attacksOffset)
                        GuiControl, ICScriptHub:, NrakkUltMaster_Status2,
                        return attacksCounter
                    }
                    inArc := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadInTargetArc()
                    if (!inArc) {
                        GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult Running - Attack Counter: "(attacksCounter + attacksOffset) "/" (maxAttacks + attacksOffset)
                        break ; Attack has registered - move on to the next ult
                    }
                    ultReady := this.isUltReady(ultButton)
                    if (ultReady == False) {
                        GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult Master Finished - Failed with " (attacksCounter + attacksOffset) " attacks."
                        return attacksCounter
                    }
                    if (this.stopping == True) {
                        GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master Stopped
                        return attacksCounter
                    }
                    Sleep, 5
                }
            }

            ; Failsafe - we missed the arc(?)
            ultReady := this.isUltReady(ultButton)
            if (ultReady == False) {
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult Master Finished - Failed with " (attacksCounter + attacksOffset) " attacks - mistiming?"
                return attacksCounter
            }

            Sleep, 5
        }
    }

    isUltReady(ultButton)
    {
        ultCd := g_SF.Memory.ReadUltimateCooldownByItem(ultButton - 1)
        return ultCd <= 0 ; <= 0 means it's not on cd
    }
}
