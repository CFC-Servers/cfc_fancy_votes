net.Receive( CFC_Vote.NET_CONSOLE_PRINT, function()
    MsgN( net.ReadString() )
end )
