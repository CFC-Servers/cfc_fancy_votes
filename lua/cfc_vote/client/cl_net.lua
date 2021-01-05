net.Receive( CFC_Vote.NET_LIVE_UPDATE, function()
    for _, popup in pairs( CFCNotifications._popups ) do
        local notif = popup.notification

        if notif._id == CFC_Vote.NOTIFICATION_LIVE_NAME then
            local buttonPanels = notif._btns
            local index = net.ReadInt( 9 )
            local count = net.ReadInt( 9 )
            local nonresponseIndex = net.ReadInt( 9 )
            local nonresponseCount = net.ReadInt( 9 )
            local option = net.ReadString()

            buttonPanels[index]:SetText( option .. "\n" .. count )
            buttonPanels[nonresponseIndex]:SetText( "No Response\n" .. nonresponseCount )

            break
        end
    end
end )