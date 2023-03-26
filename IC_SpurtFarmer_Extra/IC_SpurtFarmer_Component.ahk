GUIFunctions.AddTab("SpurtFarmer")

Gui, ICScriptHub:Tab, SpurtFarmer
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, SpurtFarmer
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, Farm Spurt

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gSpurtFarm_Run, Run
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gSpurtFarm_Stop, Stop

Gui, ICScriptHub:Add, Text, x15 y+10 vSpurtFarm_Status w300,
Gui, ICScriptHub:Add, Text, x15 y+5 vSpurtFarm_Wasps w300,

global g_spurtFarm := new SpurtFarm()
SpurtFarm_Run() {
    if (g_spurtFarm.IsRunning() == true) {
        MsgBox Spurt Farm already running
        return
    }

    ; initialize shared functions for memory reads and directed inputs
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    g_SF.Memory.OpenProcessReader()
    g_SF.Memory.ActiveEffectKeyHandler.Refresh()

    ; check that spurt is in the formation
    currentFormation := g_SF.Memory.GetCurrentFormation()
    if (g_SF.IsChampInFormation(43, currentFormation) == false) {
        GuiControl, ICScriptHub:, SpurtFarm_Status, 404: Spurt not found
        return
    }

    g_spurtFarm.Run()
}

SpurtFarm_Stop() {
    if (g_spurtFarm.IsRunning() == false) {
        MsgBox Spurt Farm isn't running
        return
    }
    g_spurtFarm.Stop()
}

class SpurtFarm {

    running := false

    IsRunning() {
        return this.running
    }

    Run() {
        this.running := true
        if (ActiveEffectKeySharedFunctions.Spurt.WaspirationHandler) {
            GuiControl, ICScriptHub:, SpurtFarm_Status, Running MemRead Spurt Farm
            this.doMemReadFarm()
        } else {
            GuiControl, ICScriptHub:, SpurtFarm_Status, Running Timer Spurt Farm
            this.doTimedFarm()
        }
    }

    Stop() {
        this.running := false
        GuiControl, ICScriptHub:, SpurtFarm_Status, SpurtFarm Stopped
        GuiControl, ICScriptHub:, SpurtFarm_Wasps,
    }

    doMemReadFarm() {
        toggle := 0
        loop {
            num := ActiveEffectKeySharedFunctions.Spurt.WaspirationHandler.ReadSpurtWasps()
            GuiControl, ICScriptHub:, SpurtFarm_Wasps, % "Current Wasps: " . num
            if (num >= 15) {
                input := toggle = 1 ? ( "{Left}", toggle := 0) : ( "{Right}", toggle := 1)
                g_SF.DirectedInput(,,input)
            }
            Sleep, 100
            if (this.running == false) {
                return
            }
        }
    }

    doTimedFarm()  {
        toggle := 0
        loop {
            input := toggle = 1 ? ( "{Left}", toggle := 0) : ( "{Right}", toggle := 1)
            g_SF.DirectedInput(,,input)
            Sleep, 12000
            if (this.running == false) {
                return
            }
        }
    }
}
