CFC_Vote = CFC_Vote or {}

local voteData = {}
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

    CFCNotifications.new( CFC_Vote.NOTIFICATION_STOP_NAME, "Text", true )
    local stopNotif = CFCNotifications.get( CFC_Vote.NOTIFICATION_STOP_NAME )
    setNotifSettings( stopNotif, "The vote was stopped early!" )
    stopNotif:SetTitle( "CFC Vote" )
    stopNotif:SetDisplayTime( 5 )
    stopNotif:SetPriority( CFCNotifications.PRIORITY_LOW )
    stopNotif:Send( voters )

    voteInProgress = false
end

local function doVote( caller, args, optionCount )
    local question = args[1]
    local message = ""
    local plys = player.GetHumans()

    voters = table.Copy( plys )
    table.RemoveByValue( voters, caller )
    table.remove( args, 1 )
    voteInProgress = true
    voteCaller = caller
    voteResults = {}

    CFCNotifications.new( CFC_Vote.NOTIFICATION_VOTE_NAME, "Buttons", true )
    local notif = CFCNotifications.get( CFC_Vote.NOTIFICATION_VOTE_NAME )

    CFCNotifications.new( CFC_Vote.NOTIFICATION_LIVE_NAME, "Buttons", true )
    local liveNotif = CFCNotifications.get( CFC_Vote.NOTIFICATION_LIVE_NAME )

    CFCNotifications.new( CFC_Vote.NOTIFICATION_RESULTS_NAME, "Buttons", true )
    local resultNotif = CFCNotifications.get( CFC_Vote.NOTIFICATION_RESULTS_NAME )

    notif:SetTitle( "Vote: " .. question )
    liveNotif:SetTitle( "Results: " .. question )
    resultNotif:SetTitle( "Results: " .. question )

    for index, option in pairs( args ) do
        voteResults[index] = 0
        message = message .. index .. ": " .. option .. "\n"
        notif:AddButton( index, CFC_Vote.BUTTON_COLOR, index )
        liveNotif:AddButton( index .. ": 0", CFC_Vote.BUTTON_COLOR )
    end

    voteResults[optionCount + 1] = #voters
    liveNotif:AddButton( "?: " .. voteResults[optionCount + 1], Color( 0, 0, 0, 255 ) )

    setNotifSettings( notif, message )
    setNotifSettings( liveNotif, message .. "\nThese are the live results!\nPress any button to stop the vote early." )

    resultNotif:SetText( message .. "\n These are the results!\nPress any button to close this message." )
    resultNotif:SetDisplayTime( CFC_Vote.RESULTS_DURATION:GetFloat():GetFloat() )
    resultNotif:SetPriority( CFCNotifications.PRIORITY_LOW )
    resultNotif:SetCloseable( false )
    resultNotif:SetIgnoreable( false )
    resultNotif:SetTimed( true )

    function notif:OnButtonPressed( ply, index )
        voteResults[index] = voteResults[index] + 1
        voteResults[optionCount + 1] = voteResults[optionCount + 1] - 1
        notif:RemovePopup( notif:GetCallingPopupID(), ply )

        net.Start( CFC_Vote.NET_LIVE_UPDATE )
        net.WriteInt( index, 9 )
        net.WriteInt( voteResults[index], 9 )
        net.WriteInt( optionCount + 1, 9 )
        net.WriteInt( voteResults[optionCount + 1], 9 )
        net.Send( caller )
    end

    function liveNotif:OnButtonPressed( ply )
        stopVote()
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

        for index = 1, optionCount do
            local color = CFC_Vote.BUTTON_COLOR

            if highInds[index] then
                color = Color( 0, 255, 0, 255 )
            end

            resultNotif:AddButton( index .. ": " .. voteResults[index], color )
        end

        resultNotif:AddButton( "?: " .. voteResults[optionCount + 1], Color( 0, 0, 0, 255 ) )

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
            MsgN( "There is already a vote in progress!" )
        else
            ply:ChatPrint( "You do not have access to this command, " .. ply:Nick() .. "." )
        end

        return
    end

    if voteInProgress then
        if fromConsole then
            MsgN( "There is already a vote in progress!" )
        else
            ply:ChatPrint( "There is already a vote in progress!" )
        end

        return
    end

    local optionCount = #args - 1

    if optionCount < 2 then
        if fromConsole then
            MsgN( "Not enough arguments! You need a question and at least two options." )
        else
            ply:ChatPrint( "Not enough arguments! You need a question and at least two options." )
        end

        return
    end

    if optionCount > CFC_Vote.VOTE_MAX_OPTIONS:GetInt() then
        if fromConsole then
            MsgN( "Too many vote options! The maximum is " .. CFC_Vote.VOTE_MAX_OPTIONS:GetInt() .. "." )
        else
            ply:ChatPrint( "Too many vote options! The maximum is " .. CFC_Vote.VOTE_MAX_OPTIONS:GetInt() .. "." )
        end

        return
    end

    if fromConsole then
        MsgN( "Creating a vote..." )
    else
        ply:ChatPrint( "Creating a vote..." )
    end

    doVote( ply, args, optionCount )
end

hook.Add( "PlayerSay", "CFC_Vote_StartVote", function( ply, text )
    if text:sub( 1, CFC_Vote.VOTE_COMMAND:GetString():len() ) ~= CFC_Vote.VOTE_COMMAND:GetString() then return end

    local args = text:Split( " " )
    table.remove( args, 1 )

    timer.Simple( 0, function()
        tryVote( ply, false, args )
    end )
end )

concommand.Add( "cfc_vote", tryVote )