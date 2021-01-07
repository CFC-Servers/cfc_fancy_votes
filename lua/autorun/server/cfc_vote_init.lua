AddCSLuaFile( "cfc_vote/client/net.lua" )
AddCSLuaFile( "cfc_vote/shared/base.lua" )

hook.Add( "CFC_Notifications_init", "CFC_Vote_Startup", function()
    include( "cfc_vote/shared/base.lua" )
end )
