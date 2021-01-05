CFC_Vote = CFC_Vote or {}

CFC_Vote.NET_LIVE_UPDATE = "CFC_Vote_LiveUpdate"
CFC_Vote.NET_CONSOLE_PRINT = "CFC_Vote_ConsolePrint"
CFC_Vote.NOTIFICATION_LIVE_NAME = "CFC_Vote_VoteLive"

if CLIENT then
    include( "cfc_vote/client/cl_net.lua" )
    return
end

util.AddNetworkString( CFC_Vote.NET_LIVE_UPDATE )
util.AddNetworkString( CFC_Vote.NET_CONSOLE_PRINT )

CFC_Vote.VOTE_COMMAND = CreateConVar( "cfc_vote_chat_command", "!cfcvote", FCVAR_NONE, "Chat command for CFC Vote" )
CFC_Vote.VOTE_MAX_OPTIONS = CreateConVar( "cfc_vote_max_options", 6, FCVAR_NONE, "Max number of vote options", 2, 10 )
CFC_Vote.VOTE_DURATION = CreateConVar( "cfc_vote_duration", 30, FCVAR_NONE, "How long votes will last for, in seconds", 1, 50000 )
CFC_Vote.RESULTS_DURATION = CreateConVar( "cfc_vote_results_duration", 15, FCVAR_NONE, "How long vote results will last for, in seconds", 1, 50000 )
CFC_Vote.NOTIFICATION_VOTE_NAME = "CFC_Vote_VoteQuery"
CFC_Vote.NOTIFICATION_RESULTS_NAME = "CFC_Vote_VoteResults"
CFC_Vote.NOTIFICATION_STOP_NAME = "CFC_Vote_VoteStop"
CFC_Vote.BUTTON_COLOR = Color( 200, 220, 245, 255 )

include( "cfc_vote/server/sv_vote.lua" )
