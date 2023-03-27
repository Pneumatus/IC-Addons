#include %A_LineFile%\..\IC_BrivGemFarm_CloseWelcomeBack_TimerScript.ahk

class IC_BrivGemFarm_CloseWelcomeBack_Component
{
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_CloseWelcomeBack_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
        OutputDebug, % addonLoc . " to " . g_BrivFarmModLoc
    }
}
IC_BrivGemFarm_CloseWelcomeBack_Component.InjectAddon()

; timer script on start
g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(IC_BrivGemFarm_CloseWelcomeBack_TimerScript, "CreateTimedFunctions"))
g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(IC_BrivGemFarm_CloseWelcomeBack_TimerScript, "StartTimedFunctions"))
; timer script on stop
g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(IC_BrivGemFarm_CloseWelcomeBack_TimerScript, "StopTimedFunctions"))
