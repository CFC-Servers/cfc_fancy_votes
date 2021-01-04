local function addFiles( dir )
    local files, dirs = file.Find( dir .. "/*", "LUA" )
    if not files then return end
    for k, v in pairs( files ) do
        if string.match( v, "^.+%.lua$" ) then
            AddCSLuaFile( dir .. "/" .. v )
        end
    end
    for k, v in pairs( dirs ) do
        addFiles( dir .. "/" .. v )
    end
end
addFiles( "cfc_vote/client" )
addFiles( "cfc_vote/shared" )

hook.Add( "CFC_Notifications_init", "CFC_Vote_Startup", function()
    include( "cfc_vote/shared/sh_base.lua" )
end )