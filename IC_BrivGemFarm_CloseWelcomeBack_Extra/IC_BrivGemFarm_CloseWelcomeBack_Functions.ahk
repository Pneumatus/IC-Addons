class IC_BrivCloseWelcomeBack_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    WaitForModronReset(timeout)
    {
        ret := base.WaitForModronReset(timeout)
        if (this.Memory.ReadWelcomeBackActive())
            this.DirectedInput(,,"{Esc}")
        return ret
    }
}
