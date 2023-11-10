GUIFunctions.AddTab("NrakkUltMaster")

Gui, ICScriptHub:Tab, NrakkUltMaster
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, NrakkUltMaster
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, Master Nrakk's Ult

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNrakkUltMaster_Run, Run
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNrakkUltMaster_Stop, Stop

Gui, ICScriptHub:Add, Text, x15 y+10 vNrakkUltMaster_Status w300,

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
        this.farmUlt(ultButton)
        if (this.stopping == True) {
            this.stopping := False
            this.running := False
            return
        }

        ; If DM is in the formation and has ult ready, try using that to reset Nrakk's ult
        ; and run the farm again for more stacks...
        dmUltButton := g_SF.GetUltimateButtonByChampID(99)
        if (dmUltButton > 0) {
            GuiControl, ICScriptHub:, NrakkUltMaster_Status, Found DM ult - attempting to use it to reset
            dmUltReady := this.isUltReady(dmUltButton)
            if (dmUltReady == True) {
                g_SF.DirectedInput(,, dmUltButton) ; DM ult - reset cooldown
                ultReady := False
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master waiting for Nrakk ult ready
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
                    GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master reset by DM - going again
                    this.farmUlt(ultButton)
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

    farmUlt(ultButton) {
        g_SF.DirectedInput(,, ultButton) ; ult
        Sleep, 200
        loop {
            if (this.stopping == True) {
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master Stopped
                return
            }

            inArc := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadInTargetArc()
            if (inArc) {
                g_SF.DirectedInput(,, ultButton)
                Sleep, 10
            }

            attackCounter := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadAttacksCounter()
            maxAttacks := ActiveEffectKeySharedFunctions.Nrakk.NrakkUltimateAttackHandler.ReadMaxAttacks()
            GuiControl, ICScriptHub:, NrakkUltMaster_Status, % "Nrakk Ult Running - Attack Counter: " attackCounter "/" maxAttacks

            ultReady := this.isUltReady(ultButton)
            if (ultReady == False) {
                GuiControl, ICScriptHub:, NrakkUltMaster_Status, Nrakk Ult Master Finished
                return
            }

            Sleep, 10
        }
    }

    isUltReady(ultButton)
    {
        ultCd := g_SF.Memory.ReadUltimateCooldownByItem(ultButton - 1)
        return ultCd <= 0 ; any <= 0 means it's not on cd
    }
}
