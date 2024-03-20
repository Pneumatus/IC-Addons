#include %A_LineFile%\..\IC_BrivGemFarm_CloseWelcomeBack_Functions.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
if (IsObject(SH_UpdateClass)) {
    SH_UpdateClass.UpdateClassFunctions(g_SF, IC_BrivCloseWelcomeBack_SharedFunctions_Class, true)
} else {
    ; backwards compatibility
    #include %A_LineFile%\..\..\..\SharedFunctions\IC_UpdateClass_Class.ahk
    IC_UpdateClass_Class.UpdateClassFunctions(g_SF, IC_BrivCloseWelcomeBack_SharedFunctions_Class, true)
}
