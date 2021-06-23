CFC_Vote = CFC_Vote or {}

CFC_Vote.voteResults = {}
CFC_Vote.voteInProgress = false
CFC_Vote.voteCaller = false
CFC_Vote.voters = {}
CFC_Vote.undecidedVoters = {}

local function setNotifSettings( notif, text )
    notif:SetText( text )
    notif:SetDisplayTime( CFC_Vote.VOTE_DURATION:GetFloat() )
    notif:SetPriority( CFCNotifications.PRIORITY_HIGH )
    notif:SetCloseable( false )
    notif:SetIgnoreable( false )
    notif:SetTimed( true )
end

function CFC_Vote.stopVote( byAdmin )
    if not CFC_Vote.voteInProgress then return end

    local notif = CFCNotifications.get( CFC_Vote.NOTIFICATION_VOTE_NAME )
    local liveNotif = CFCNotifications.get( CFC_Vote.NOTIFICATION_LIVE_NAME )
    local adminNotif = CFCNotifications.get( CFC_Vote.NOTIFICATION_ADMIN_NAME )
    local voters = CFC_Vote.voters or {}

    notif:Remove()
    liveNotif:Remove()
    adminNotif:Remove()

    table.insert( voters, CFC_Vote.voteCaller )
    timer.Remove( "CFC_Vote_VoteFinished" )

    local stopNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_STOP_NAME, "Text", true )
    setNotifSettings( stopNotif, "The vote was stopped early" .. ( byAdmin and " by an admin!" or "!" ) )
    stopNotif:SetTitle( "CFC Vote" )
    stopNotif:SetDisplayTime( 5 )
    stopNotif:SetPriority( CFCNotifications.PRIORITY_LOW )
    stopNotif:Send( voters )

    CFC_Vote.voteInProgress = false
end

local function playerStopVote( ply )
    if CFC_Vote.voteCaller ~= ply then return end

    CFC_Vote.stopVote()
end

local function doVote( caller, args, optionCount )
    local question = args[1]
    local plys = player.GetHumans()
    local voters = table.Copy( plys )
    local voteResults = {}
    local adminPlys = {}
    local adminLookup = {}
    local undecidedVoters = {}

    table.RemoveByValue( voters, caller )
    table.remove( args, 1 )

    for i, ply in ipairs( plys ) do
        local isVoteAdmin

        if ULib then
            isVoteAdmin = ULib.ucl.query( ply, "ulx stopvote", true )
        else
            isVoteAdmin = ply:IsAdmin()
        end

        if isVoteAdmin and ply ~= caller then
            table.insert( adminPlys, ply )
            adminLookup[ply] = true
        end

        if ply ~= caller then
            undecidedVoters[ply] = true
        end
    end

    CFC_Vote.voteInProgress = true
    CFC_Vote.voteCaller = caller
    CFC_Vote.voters = voters
    CFC_Vote.voteResults = voteResults
    CFC_Vote.undecidedVoters = undecidedVoters

    local notif = CFCNotifications.new( CFC_Vote.NOTIFICATION_VOTE_NAME, "Buttons", true )
    local liveNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_LIVE_NAME, "Buttons", true )
    local resultNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_RESULTS_NAME, "Buttons", true )
    local adminNotif = CFCNotifications.new( CFC_Vote.NOTIFICATION_ADMIN_NAME, "Buttons", true )

    notif:SetTitle( "CFC Vote" )
    liveNotif:SetTitle( "CFC Vote Live Results" )
    resultNotif:SetTitle( "CFC Vote Results" )
    adminNotif:SetTitle( "CFC Vote Admin Info" )

    liveNotif:AddButtonAligned( "Stop the vote", CFC_Vote.BUTTON_STOP_COLOR, CFCNotifications.ALIGN_CENTER )
    liveNotif:NewButtonRow()

    for index, option in ipairs( args ) do
        voteResults[index] = 0
        notif:AddButtonAligned( option, CFC_Vote.BUTTON_VOTE_COLOR, CFCNotifications.ALIGN_LEFT, index )
        liveNotif:AddButtonAligned( option .. "\n0", CFC_Vote.BUTTON_VOTE_COLOR, CFCNotifications.ALIGN_LEFT )
        liveNotif:EditButtonCanPress( index + 1, 1, false )
        liveNotif:NewButtonRow()

        if index < optionCount then
            notif:NewButtonRow()
        end
    end

    voteResults[optionCount + 1] = #voters
    liveNotif:AddButtonAligned( "No Response\n" .. voteResults[optionCount + 1], Color( 255, 0, 0, 255 ), CFCNotifications.ALIGN_LEFT )
    liveNotif:EditButtonCanPress( optionCount + 2, 1, false )

    adminNotif:AddButtonAligned( "Stop the vote", CFC_Vote.BUTTON_STOP_COLOR, CFCNotifications.ALIGN_CENTER, true )
    adminNotif:AddButtonAligned( "Discard this", CFC_Vote.BUTTON_DISCARD_COLOR, CFCNotifications.ALIGN_CENTER, false )

    setNotifSettings( notif, question .. "\n\nClick on a button below to vote!" )
    setNotifSettings( liveNotif, question .. "\n\nThese are the live results!" )
    setNotifSettings( resultNotif, question .. "\n\nThese are the results!\nClick on any button to close this message." )
    setNotifSettings( adminNotif, "The current vote was created by\n" .. caller:Nick() .. " " .. caller:SteamID() )

    resultNotif:SetDisplayTime( CFC_Vote.RESULTS_DURATION:GetFloat() )
    resultNotif:SetPriority( CFCNotifications.PRIORITY_LOW )

    function notif:OnButtonPressed( ply, index )
        if not undecidedVoters[ply] or type( index ) ~= "number" then return end
        if index > optionCount or index < 1 or math.floor( index ) ~= index then return end

        undecidedVoters[ply] = nil
        voteResults[index] = voteResults[index] + 1
        voteResults[optionCount + 1] = voteResults[optionCount + 1] - 1
        notif:RemovePopup( notif:GetCallingPopupID(), ply )

        local optionResultText = args[index] .. "\n" .. voteResults[index]
        local UndecidedText = "No Response\n" .. voteResults[optionCount + 1]

        liveNotif:EditButtonText( index + 1, 1, optionResultText, CFC_Vote.voteCaller )
        liveNotif:EditButtonText( optionCount + 2, 1, UndecidedText, CFC_Vote.voteCaller )
    end

    function liveNotif:OnButtonPressed( ply )
        playerStopVote( ply )
    end

    function resultNotif:OnButtonPressed( ply )
        resultNotif:RemovePopup( resultNotif:GetCallingPopupID(), ply )
    end

    function adminNotif:OnButtonPressed( ply, stop )
        if not stop then return end
        if not adminLookup[ply] then return end

        CFC_Vote.stopVote( true )
    end

    adminNotif:Send( adminPlys )
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

        for index, option in ipairs( args ) do
            local color = CFC_Vote.BUTTON_VOTE_COLOR

            if highInds[index] then
                color = Color( 0, 255, 0, 255 )
            end

            resultNotif:AddButtonAligned( option .. "\n" .. voteResults[index], color, CFCNotifications.ALIGN_LEFT )
            resultNotif:NewButtonRow()
        end

        resultNotif:AddButtonAligned( "No Response\n" .. voteResults[optionCount + 1], Color( 255, 0, 0, 255 ), CFCNotifications.ALIGN_LEFT )
        resultNotif:Send( plys )

        timer.Simple( CFC_Vote.RESULTS_DURATION:GetFloat(), function()
            CFC_Vote.voteInProgress = false
        end )
    end )
end

function CFC_Vote.tryVote( ply, fromConsole, args )
    if not IsValid( ply ) then return end

    if ULib and not ULib.ucl.query( ply, "ulx cfcvote", true ) then
        if fromConsole then
            net.Start( CFC_Vote.NET_CONSOLE_PRINT )
            net.WriteString( "You do not have access to this command, " .. ply:Nick() .. "." )
            net.Send( ply )
        else
            ply:ChatPrint( "You do not have access to this command, " .. ply:Nick() .. "." )
        end

        return
    end

    if CFC_Vote.voteInProgress then
        if fromConsole then
            net.Start( CFC_Vote.NET_CONSOLE_PRINT )
            net.WriteString( "There is already a vote in progress!" )
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
            net.WriteString( "Not enough arguments! You need a question and at least two options. Surround each argument with quotes to separate them off\n" ..
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
            net.WriteString( "Too many vote options! The maximum is " .. CFC_Vote.VOTE_MAX_OPTIONS:GetInt() ..
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
        net.WriteString( "Creating a vote..." )
        net.Send( ply )
    else
        ply:ChatPrint( "Creating a vote..." )
    end

    for index, option in ipairs( args ) do
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

if not ulx then return end

local function voteFromULX( caller, title, ... )
    if not IsValid( caller ) then return end

    if CFC_Vote.voteInProgress then
		ULib.tsayError( caller, "There is already a CFC vote in progress. Please wait for the current one to end.", true )
		return
	end

    local args = { ... }
    local maxOptions = CFC_Vote.VOTE_MAX_OPTIONS:GetInt()

    for index, option in ipairs( args ) do
        if index > maxOptions then
            args[index] = nil
        else
            args[index] = string.Replace( option, "\n", "" )
        end
    end

    net.Start( CFC_Vote.NET_CONSOLE_PRINT )
    net.WriteString( "Creating a vote..." )
    net.Send( caller )

    caller:ChatPrint( "Creating a vote..." )

    table.insert( args, 1, title )
    doVote( caller, args, #args - 1 )
end

local voteCmd = ulx.command( "Voting", "ulx cfcvote", voteFromULX )
voteCmd:addParam{ type=ULib.cmds.StringArg, hint="title" }
voteCmd:addParam{ type=ULib.cmds.StringArg, hint="options", ULib.cmds.takeRestOfLine, repeat_min=2, repeat_max=CFC_Vote.VOTE_MAX_OPTIONS:GetInt() }
voteCmd:defaultAccess( ULib.ACCESS_ADMIN )
voteCmd:help( "Starts a fancy public vote." )
