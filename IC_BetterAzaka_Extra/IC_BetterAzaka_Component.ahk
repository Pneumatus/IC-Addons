GUIFunctions.AddTab("BetterAzaka")

global g_BetterAzakaSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Settings.json" )
if !IsObject(g_BetterAzakaSettings)
    g_BetterAzakaSettings := {}

Gui, ICScriptHub:Tab, BetterAzaka
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, BetterAzaka
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, This AddOn will use the configured ultimates when all of them are off cooldown.
Gui, ICScriptHub:Add, Text, x15 y+5, Optionally once ultimates have been triggered the W formation will be activated
Gui, ICScriptHub:Add, Text, x15 y+5, for the configured amount of time before swapping back to Q.

if ( g_BetterAzakaSettings.Loops == "" )
    g_BetterAzakaSettings.Loops := 5
Gui, ICScriptHub:Add, Text, x15 y+15, Repeat ultimates this many times:
Gui, ICScriptHub:Add, Edit, vBetterAzaka_Loops x+5 w50, % g_BetterAzakaSettings.Loops
Gui, ICScriptHub:Add, Text, x+5 vBetterAzaka_Loops_Saved w200, % "Saved value: " . g_BetterAzakaSettings.Loops

if ( g_BetterAzakaSettings.Ult == "" )
{
    g_BetterAzakaSettings.Ult := {}
    loop, 10
    {
        g_BetterAzakaSettings.Ult[A_Index] := 0
    }
}

Gui, ICScriptHub:Add, Text, x15 y+15, Use the following ultimates:
loop, 10
{
    chk := g_BetterAzakaSettings.Ult[A_Index]
    Gui, ICScriptHub:Add, Checkbox, vBetterAzaka_CB%A_Index% Checked%chk% x15 y+10, % A_Index
    Gui, ICScriptHub:Add, Text, x+5 vBetterAzaka_CB%A_Index%_Saved w200, % chk == 1 ? "Saved value: Checked":"Saved value: Unchecked"
}

if ( g_BetterAzakaSettings.SwapWDurationSecs == "" )
    g_BetterAzakaSettings.SwapWDurationSecs := 0
Gui, ICScriptHub:Add, Text, x15 y+15, Swap to W for this many seconds after ultimates:
Gui, ICScriptHub:Add, Edit, vBetterAzaka_SwapWDurationSecs x+5 w50, % g_BetterAzakaSettings.SwapWDurationSecs
Gui, ICScriptHub:Add, Text, x+5 vBetterAzaka_SwapWDurationSecs_Saved w200, % "Saved value: " . g_BetterAzakaSettings.SwapWDurationSecs

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gBetterAzaka_Save, Save Settings
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gBetterAzaka_Run, Run

Gui, ICScriptHub:Add, Text, x15 y+10 vBetterAzaka_Running w300,
Gui, ICScriptHub:Add, Text, x15 y+5 vBetterAzaka_UltsUsed w300,

BetterAzaka_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide

    g_BetterAzakaSettings.Loops := BetterAzaka_Loops
    GuiControl, ICScriptHub:, BetterAzaka_Loops_Saved, % "Saved value: " . g_BetterAzakaSettings.Loops

    loop, 10
    {
        g_BetterAzakaSettings.Ult[A_Index] := BetterAzaka_CB%A_Index%
        GuiControl, ICScriptHub:, BetterAzaka_CB%A_Index%_Saved, % BetterAzaka_CB%A_Index% == 1 ? "Saved value: Checked":"Saved value: Unchecked"
    }

    g_BetterAzakaSettings.SwapWDurationSecs := BetterAzaka_SwapWDurationSecs
    GuiControl, ICScriptHub:, BetterAzaka_SwapWDurationSecs_Saved, % "Saved value: " . g_BetterAzakaSettings.SwapWDurationSecs

    g_SF.WriteObjectToJSON(A_LineFile . "\..\Settings.json" , g_BetterAzakaSettings)
}

BetterAzaka_Run()
{
    GuiControl, ICScriptHub:, BetterAzaka_Running, Azaka farm is running.
    ;initialize shared functions for memory reads and directed inputs
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    g_SF.Memory.OpenProcessReader()

    OutputDebug, % g_SF.Memory.GameManager.game.gameInstances.Screen.uiController.ultimatesBar.ultimateItems.ultimateAttack

    ;create object for azaka class to update gui
    guiData := {}
    guiData.guiName := "ICScriptHub:"
    guiData.guiControlIDultStatus := "BetterAzaka_CurrentUltStatus"
    guiData.guiControlIDults := "BetterAzaka_UltsUsed"

    azaka := new BetterAzakaFarm(g_BetterAzakaSettings, guiData)
    azaka.Run()

    GuiControl, ICScriptHub:, BetterAzaka_Running, Azaka farm is complete.
    GuiControl, ICScriptHub:, BetterAzaka_CurrentUltStatus,
    GuiControl, ICScriptHub:, BetterAzaka_UltsUsed,
    msgbox, Azaka farm is complete.
}

class BetterAzakaFarm
{
    ultIndexes := []
    inputs := {}
    loops := {}
    useGUI := false

    __new(settings, guiData)
    {
        loop, 10
        {
            if (settings.Ult[A_Index] AND A_Index < 10)
                this.inputs.Push(A_Index . "")
            else if (settings.Ult[A_Index] AND A_Index == 10)
                this.inputs.Push(0 . "")

            if (settings.Ult[A_Index])
                this.ultIndexes.Push(A_Index - 1)
        }
        this.loops := settings.Loops
        this.swapWDurationSecs := g_BetterAzakaSettings.SwapWDurationSecs
        if IsObject(guiData)
        {
            this.useGUI := true
            this.guiName := guiData.guiName
            this.guiControlIDultStatus := guiData.guiControlIDultStatus
            this.guiControlIDults := guiData.guiControlIDults
        }
        return this
    }

    Run()
    {
        if (this.useGUI)
            GuiControl, % this.guiName, % this.guiControlIDults, % "Ultimates Used: 0"
        loops := this.Loops
        loop, %loops%
        {
            wait := true
            while wait
            {
                if this.farm()
                    wait := false
                sleep, 100
            }
            if (this.useGUI)
                GuiControl, % this.guiName, % this.guiControlIDults, % "Ultimates Used: " . A_Index
        }
    }

    farm()
    {
        g_SF.Memory.ActiveEffectKeyHandler.Refresh()
        ultsReady := this.areAllUltsReady()
        if (this.useGUI)
            GuiControl, % this.guiName, % this.guiControlIDultStatus, % "Ults Status: " . ((ultsReady) ? "READY" : "On Cooldown")

        if ultsReady
        {
            g_SF.DirectedInput(,, this.inputs*)
            ; When all ults have been fired, optionally swap to another formation
            if this.swapWDurationSecs > 0
            {
                g_SF.DirectedInput(,,["{w}"]*)
                sleep, this.swapWDurationSecs * 1000
                g_SF.DirectedInput(,,["{q}"]*)
                return true
            }
            sleep, 100
        }
        return false
    }

    areAllUltsReady()
    {
        For index, value in this.ultIndexes
        {
            ultCd := g_SF.Memory.readUltimateCooldownByItem(value)
            if (ultCd > 0)
                return false ; any ult cd > 0 means they aren't all ready
        }
        return true
    }

; Inverse of areAllUltsReady()
; Aren't used anymore. Will leave it here in case we need it again
;    areAllUltsOnCooldown()
;    {
;        For index, value in this.ultIndexes
;        {
;            ultCd := this.readUltimateCooldownByItem(value)
;            if (ultCd <= 0)
;                return false ; any ult cd <= 0 means it's not on cd
;        }
;        return true
;    }

}

