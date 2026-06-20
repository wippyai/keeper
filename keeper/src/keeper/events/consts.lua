-- keeper.events domain vocabulary. Single source of truth for the admin event
-- bus: the pg scope it rides on, the admin process group, and the clear topics
-- modules publish on (which admin hubs subscribe to and clients see verbatim).
local consts = {
    -- pg process-group scope carrying keeper admin events.
    BUS = "keeper.events:bus",

    -- The process group joined by admin user hubs. Membership = live admin presence.
    GROUP = "keeper.admins",

    -- Clear event topics. Publishers broadcast on these; the relay hub fans them
    -- to the user's clients under the same topic, so the frontend subscribes by name.
    TOPICS = {
        CHANGESET = "keeper.changeset",
        GIT       = "keeper.git",
        VERSION   = "registry:version",
    },

    -- Wire contract for instructing a relay user hub to join/leave the bus.
    -- Mirrors wippy.relay consts (USER_HUB_REGISTRY_PREFIX + HUB_CONTROL); kept
    -- here so the inbound adapter does not couple to the relay module's version.
    HUB = {
        PREFIX      = "user.",
        SUBSCRIBE   = "pg.subscribe",
        UNSUBSCRIBE = "pg.unsubscribe",
    },
}

return consts
