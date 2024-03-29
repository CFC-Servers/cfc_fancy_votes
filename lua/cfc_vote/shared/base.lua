CFC_Vote = CFC_Vote or {}

CFC_Vote.NET_CONSOLE_PRINT = "CFC_Vote_ConsolePrint"
CFC_Vote.NOTIFICATION_LIVE_NAME = "CFC_Vote_VoteLive"

if CLIENT then
    include( "cfc_vote/client/net.lua" )

    if not ulx then return end

    local voteCmd = ulx.command( "Voting", "ulx cfcvote", function() end )
    voteCmd:addParam{ type = ULib.cmds.StringArg, hint = "title" }
    voteCmd:addParam{ type = ULib.cmds.StringArg, hint = "options", ULib.cmds.takeRestOfLine, repeat_min = 2, repeat_max = 10 }
    voteCmd:defaultAccess( ULib.ACCESS_ADMIN )
    voteCmd:help( "Starts a fancy public vote." )

    return
end

util.AddNetworkString( CFC_Vote.NET_CONSOLE_PRINT )

CFC_Vote.VOTE_COMMAND = CreateConVar( "cfc_vote_chat_command", "!cfcvote", FCVAR_NONE, "Chat command for CFC Vote" )
CFC_Vote.VOTE_MAX_OPTIONS = CreateConVar( "cfc_vote_max_options", 6, FCVAR_NONE, "Max number of vote options", 2, 10 )
CFC_Vote.VOTE_DURATION = CreateConVar( "cfc_vote_duration", 30, FCVAR_NONE, "How long votes will last for, in seconds", 1, 50000 )
CFC_Vote.RESULTS_DURATION = CreateConVar( "cfc_vote_results_duration", 15, FCVAR_NONE, "How long vote results will last for, in seconds", 1, 50000 )
CFC_Vote.NOTIFICATION_VOTE_NAME = "CFC_Vote_VoteQuery"
CFC_Vote.NOTIFICATION_RESULTS_NAME = "CFC_Vote_VoteResults"
CFC_Vote.NOTIFICATION_ADMIN_NAME = "CFC_Vote_AdminInfo"
CFC_Vote.NOTIFICATION_STOP_NAME = "CFC_Vote_VoteStop"
CFC_Vote.BUTTON_VOTE_COLOR = Color( 200, 220, 245, 255 )
CFC_Vote.BUTTON_STOP_COLOR = Color( 230, 58, 64, 255 )
CFC_Vote.BUTTON_DISCARD_COLOR = Color( 230, 153, 58, 255 )

include( "cfc_vote/server/vote.lua" )
