CFC_Vote = CFC_Vote or {}

local voteResults = {}
local voteInProgress = false
local voteCaller
local voters

local function setNotifSettings( notif, text )
    notif:SetText( text )
    notif:SetDisplayTime( CFC_Vote.VOTE_DURATION:GetFloat() )
    notif:SetPriority( CFCNotifications.PRIORITY_HIGH )
    notif:SetCloseable( false )
    notif:SetIgnoreable( false )
    notif:SetTimed( true )
end

function CFC_Vote.stopVote()
    local notif = CFCNotifications.get( CFC_Vote.NOTIFICATION_VOTE_NAME )
    local liveNotif = CFCNotifications.get( CFC_Vote.NOTIFICATION_LIVE_NAME )

    for _, ply in pairs( voters ) do
        notif:RemovePopups( ply )
    end

    liveNotif:RemovePopups( voteCaller )
    table.insert( voters, voteCaller )

    timer.Remove( "CFC_Vote_VoteFinished" )

    local stopNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_STOP_NAME, "Text", true )
    setNotifSettings( stopNotif, "The vote was stopped early!" )
    stopNotif:SetTitle( "CFC Vote" )
    stopNotif:SetDisplayTime( 5 )
    stopNotif:SetPriority( CFCNotifications.PRIORITY_LOW )
    stopNotif:Send( voters )

    voteInProgress = false
end

local function doVote( caller, args, optionCount )
    local question = args[1]
    local plys = player.GetHumans()

    voters = table.Copy( plys )
    table.RemoveByValue( voters, caller )
    table.remove( args, 1 )
    voteInProgress = true
    voteCaller = caller
    voteResults = {}

    local notif = CFCNotifications.new( CFC_Vote.NOTIFICATION_VOTE_NAME, "Buttons", true )
    local liveNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_LIVE_NAME, "Buttons", true )
    local resultNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_RESULTS_NAME, "Buttons", true )
    
    notif:SetTitle( "CFC Vote" )
    liveNotif:SetTitle( "CFC Vote Live Results" )
    resultNotif:SetTitle( "CFC Vote Results" )

    for index, option in pairs( args ) do
        voteResults[index] = 0
        notif:AddButtonAligned( option, CFC_Vote.BUTTON_COLOR, CFCNotifications.ALIGN_LEFT, index )
        liveNotif:AddButtonAligned( option .. "\n0", CFC_Vote.BUTTON_COLOR, CFCNotifications.ALIGN_LEFT )
        liveNotif:NewButtonRow()

        if index < optionCount then
            notif:NewButtonRow()
        end
    end

    voteResults[optionCount + 1] = #voters
    liveNotif:AddButtonAligned( "No Response\n" .. voteResults[optionCount + 1], Color( 255, 0, 0, 255 ), CFCNotifications.ALIGN_LEFT )

    setNotifSettings( notif, question .. "\n\nClick on a button below to vote!" )
    setNotifSettings( liveNotif, question .. "\n\nThese are the live results!\nClick on any button to stop the vote early." )
    setNotifSettings( resultNotif, question .. "\n\nThese are the results!\nClick on any button to close this message." )

    resultNotif:SetDisplayTime( CFC_Vote.RESULTS_DURATION:GetFloat() )
    resultNotif:SetPriority( CFCNotifications.PRIORITY_LOW )

    function notif:OnButtonPressed( ply, index )
        voteResults[index] = voteResults[index] + 1
        voteResults[optionCount + 1] = voteResults[optionCount + 1] - 1
        notif:RemovePopup( notif:GetCallingPopupID(), ply )

        local optionResultText = args[index] .. "\n" .. voteResults[index]
        local UndecidedText = "No Response\n" .. voteResults[optionCount + 1]

        liveNotif:EditButtonText( index, 1, optionResultText, voteCaller )
        liveNotif:EditButtonText( optionCount + 1, 1, UndecidedText, voteCaller )
    end

    function liveNotif:OnButtonPressed( ply )
        CFC_Vote.stopVote()
    end

    function resultNotif:OnButtonPressed( ply )
        resultNotif:RemovePopup( resultNotif:GetCallingPopupID(), ply )
    end

    notif:Send( voters )
    liveNotif:Send( caller )

    timer.Create( "CFC_Vote_VoteFinished", CFC_Vote.VOTE_DURATION:GetFloat(), 1, function()
        local highInds = {}
        local highScore = 1

        for index = 1, optionCount do
            local score = voteResults[index]

            if score >= highScore then
                if score == highScore then
                    highInds[index] = true
                else
                    highInds = { [index] = true }
                    highScore = score
                end
            end
        end

        for index, option in pairs( args ) do
            local color = CFC_Vote.BUTTON_COLOR

            if highInds[index] then
                color = Color( 0, 255, 0, 255 )
            end

            resultNotif:AddButtonAligned( option .. "\n" .. voteResults[index], color, CFCNotifications.ALIGN_LEFT )
            resultNotif:NewButtonRow()
        end

        resultNotif:AddButtonAligned( "No Response\n" .. voteResults[optionCount + 1], Color( 255, 0, 0, 255 ), CFCNotifications.ALIGN_LEFT )
        resultNotif:Send( plys )

        timer.Simple( CFC_Vote.RESULTS_DURATION:GetFloat(), function()
            voteInProgress = false
        end )
    end )
end

function CFC_Vote.tryVote( ply, fromConsole, args )
    if not IsValid( ply ) then return end

    if not ULib.ucl.query( ply, "ulx vote", true ) then
        if fromConsole then
            net.Start( CFC_Vote.NET_CONSOLE_PRINT )
            net.writeString( "You do not have access to this command, " .. ply:Nick() .. "." )
            net.Send( ply )
        else
            ply:ChatPrint( "You do not have access to this command, " .. ply:Nick() .. "." )
        end

        return
    end

    if voteInProgress then
        if fromConsole then
            net.Start( CFC_Vote.NET_CONSOLE_PRINT )
            net.writeString( "There is already a vote in progress!" )
            net.Send( ply )
        else
            ply:ChatPrint( "There is already a vote in progress!" )
        end

        return
    end

    local optionCount = #args - 1

    if optionCount < 2 then
        if fromConsole then
            net.Start( CFC_Vote.NET_CONSOLE_PRINT )
            net.writeString( "Not enough arguments! You need a question and at least two options. Surround each argument with quotes to separate them off\n" ..
                             "Example: cfc_vote \"Question\" \"Option One\" \"Option Two\" \"Option Three\"" )
            net.Send( ply )
        else
            ply:ChatPrint( "Not enough arguments! You need a question and at least two options. Arguments are separated out with a ;\n" ..
                           "Example: " .. CFC_Vote.VOTE_COMMAND:GetString() .. " Question;Option One;Option Two;Option Three" )
        end

        return
    end

    if optionCount > CFC_Vote.VOTE_MAX_OPTIONS:GetInt() then
        if fromConsole then
            net.Start( CFC_Vote.NET_CONSOLE_PRINT )
            net.writeString( "Too many vote options! The maximum is " .. CFC_Vote.VOTE_MAX_OPTIONS:GetInt() ..
                             ". Surround each argument with quotes to separate them off\n" ..
                             "Example: cfc_vote \"Question\" \"Option One\" \"Option Two\" \"Option Three\"" )
            net.Send( ply )
        else
            ply:ChatPrint( "Too many vote options! The maximum is " .. CFC_Vote.VOTE_MAX_OPTIONS:GetInt() ..
                           ". Arguments are separated out with a ;\n" ..
                           "Example: " .. CFC_Vote.VOTE_COMMAND:GetString() .. " Question;Option One;Option Two;Option Three" )
        end

        return
    end

    if fromConsole then
        net.Start( CFC_Vote.NET_CONSOLE_PRINT )
        net.writeString( "Creating a vote..." )
        net.Send( ply )
    else
        ply:ChatPrint( "Creating a vote..." )
    end

    for index, option in pairs( args ) do
        if index > 1 then
            args[index] = string.Replace( option, "\n", "" )
        end
    end

    doVote( ply, args, optionCount )
end

hook.Add( "PlayerSay", "CFC_Vote_StartVote", function( ply, text )
    local commandLength = CFC_Vote.VOTE_COMMAND:GetString():len()

    if text:sub( 1, commandLength ) ~= CFC_Vote.VOTE_COMMAND:GetString() then return end
    if text:len() == commandLength then return end

    text = text:sub( commandLength + 1 )
    text = text:Trim()
    local args = text:Split( ";" )

    timer.Simple( 0, function()
        CFC_Vote.tryVote( ply, false, args )
    end )
end )

concommand.Add( "cfc_vote", CFC_Vote.tryVote )
