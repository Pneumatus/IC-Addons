GUIFunctions.AddTab("BetterAzaka")

global g_BetterAzakaSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Settings.json" )
if !IsObject(g_BetterAzakaSettings)
    g_BetterAzakaSettings := {}

Gui, ICScriptHub:Tab, BetterAzaka
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, BetterAzaka
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, This AddOn will use the configured ults at a set Omin number of contracts fulfilled.
Gui, ICScriptHub:Add, Text, x15 y+5, Ults will only be triggered when all ultimates are off cooldown.
Gui, ICScriptHub:Add, Text, x15 y+5, If configured, once all ults have been triggered the W formation will activated for
Gui, ICScriptHub:Add, Text, x15 y+5, the configured amount of time before swapping back to Q.

if ( g_BetterAzakaSettings.NumContracts == "" )
    g_BetterAzakaSettings.NumContracts := 95
Gui, ICScriptHub:Add, Text, x15 y+15, Ult. on this many Contracts Fulfilled:
Gui, ICScriptHub:Add, Edit, vBetterAzaka_Contracts x+5 w50, % g_BetterAzakaSettings.NumContracts
Gui, ICScriptHub:Add, Text, x+5 vBetterAzaka_Contracts_Saved w200, % "Saved value: " . g_BetterAzakaSettings.NumContracts

if ( g_BetterAzakaSettings.Loops == "" )
    g_BetterAzakaSettings.Loops := 5
Gui, ICScriptHub:Add, Text, x15 y+15, Ult. this many times:
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
Gui, ICScriptHub:Add, Text, x15 y+15, Swap to W for this many seconds after ults:
Gui, ICScriptHub:Add, Edit, vBetterAzaka_SwapWDurationSecs x+5 w50, % g_BetterAzakaSettings.SwapWDurationSecs
Gui, ICScriptHub:Add, Text, x+5 vBetterAzaka_SwapWDurationSecs_Saved w200, % "Saved value: " . g_BetterAzakaSettings.SwapWDurationSecs

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gBetterAzaka_Save, Save Settings
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gBetterAzaka_Run, Run

Gui, ICScriptHub:Add, Text, x15 y+10 vBetterAzaka_Running w300,
Gui, ICScriptHub:Add, Text, x15 y+5 vBetterAzaka_CurrentContracts w300,
Gui, ICScriptHub:Add, Text, x15 y+5 vBetterAzaka_CurrentUltStatus w300,
Gui, ICScriptHub:Add, Text, x15 y+5 vBetterAzaka_UltsUsed w300,

BetterAzaka_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    g_BetterAzakaSettings.NumContracts := BetterAzaka_Contracts
    GuiControl, ICScriptHub:, BetterAzaka_Contracts_Saved, % "Saved value: " . g_BetterAzakaSettings.NumContracts

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
    guiData.guiControlIDcont := "BetterAzaka_CurrentContracts"
    guiData.guiControlIDultStatus := "BetterAzaka_CurrentUltStatus"
    guiData.guiControlIDults := "BetterAzaka_UltsUsed"

    azaka := new BetterAzakaFarm(g_BetterAzakaSettings, guiData)
    azaka.Run()

    GuiControl, ICScriptHub:, BetterAzaka_Running, Azaka farm is complete.
    GuiControl, ICScriptHub:, BetterAzaka_CurrentContracts,
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
        this.numContracts := settings.NumContracts
        this.swapWDurationSecs := g_BetterAzakaSettings.SwapWDurationSecs
        if IsObject(guiData)
        {
            this.useGUI := true
            this.guiName := guiData.guiName
            this.guiControlIDcont := guiData.guiControlIDcont
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
        num := ActiveEffectKeySharedFunctions.Omin.OminContractualObligationsHandler.ReadNumContractsFulfilled()
        if (this.useGUI)
            GuiControl, % this.guiName, % this.guiControlIDcont, % "Current No. Contracts Fulfilled: " . num
        ultsReady := this.areAllUltsReady()
        if (this.useGUI)
            GuiControl, % this.guiName, % this.guiControlIDultStatus, % "Ults Status: " . ((ultsReady) ? "READY" : "On Cooldown")

        if ((num > this.numContracts) AND ultsReady)
        {
            while (num > this.numContracts)
            {
                num := ActiveEffectKeySharedFunctions.Omin.OminContractualObligationsHandler.ReadNumContractsFulfilled()
                g_SF.DirectedInput(,, this.inputs*)
                ; When all ults have been fired, optionally swap to another formation
                if (this.swapWDurationSecs > 0 AND this.areAllUltsOnCooldown())
                {
                    g_SF.DirectedInput(,,["{w}"]*)
                    sleep, this.swapWDurationSecs * 1000
                    g_SF.DirectedInput(,,["{q}"]*)
                    return true
                }
                sleep, 100
            }
            return true
        }
        return false
    }

    areAllUltsReady()
    {
        For index, value in this.ultIndexes
        {
            ultCd := this.readUltimateCooldownByItem(value)
            if (ultCd > 0)
                return false ; any ult cd > 0 means they aren't all ready
        }
        return true
    }

    areAllUltsOnCooldown()
    {
        For index, value in this.ultIndexes
        {
            ultCd := this.readUltimateCooldownByItem(value)
            if (ultCd <= 0)
                return false ; any ult cd <= 0 means it's not on cd
        }
        return true
    }

    ; TODO: Temp while this isn't in scripthub proper
    readUltimateCooldownByItem(item := 0)
    {
        return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.ultimatesBar.ultimateItems[item].ultimateAttack.CooldownTimer.Read()
    }
}
