-- Quality Toggle -- runtime stage
--
-- Behaviour:
--   * Each force keeps its own visibility flag (ON = qualities visible, the
--     default) plus a set of the quality levels it has actually unlocked.
--   * When a force unlocks a new quality level (via research or at init) the
--     unlock is recorded in the mod's own table, and the new quality is
--     immediately shown/hidden to match the force's current visibility flag.
--   * When an admin presses the shortcut, the flag flips and every recorded
--     quality is locked/unlocked accordingly for that force.
--   * A non-admin who presses the shortcut only gets an info message.

local SHORTCUT = 'quality-toggle'

---------------------------------------------------------------------------
-- storage helpers
---------------------------------------------------------------------------

-- storage.forces[force_index] = { visible = bool, qualities = { [name] = true } }

local function init_storage()
    storage.forces = storage.forces or {}
end

---@param force LuaForce
local function get_force_data(force)
    local data = storage.forces[force.index]
    if not data then
        data = { visible = true, qualities = {} }
        storage.forces[force.index] = data
    end
    return data
end

---------------------------------------------------------------------------
-- quality helpers
---------------------------------------------------------------------------

-- Only quality levels above the default (normal, level 0) are managed --
-- hiding the base quality would make every item inaccessible.
---@param quality LuaQualityPrototype
local function is_managed_quality(quality)
    return quality.level > 0
end

-- Show/hide a single quality for a force according to `visible`.
---@param force LuaForce
---@param quality_name string
---@param visible boolean
local function apply_quality(force, quality_name, visible)
    if visible then
        force.unlock_quality(quality_name)
    else
        force.lock_quality(quality_name)
    end
end

-- Re-apply the force's visibility flag to every quality it has unlocked.
---@param force LuaForce
local function apply_force(force)
    local data = get_force_data(force)
    for quality_name in pairs(data.qualities) do
        apply_quality(force, quality_name, data.visible)
    end
end

-- Record a quality as unlocked for the force and apply the current flag to it.
---@param force LuaForce
---@param quality_name string
local function record_quality(force, quality_name)
    local quality = prototypes.quality[quality_name]
    if not (quality and is_managed_quality(quality)) then
        return
    end
    local data = get_force_data(force)
    data.qualities[quality_name] = true
    apply_quality(force, quality_name, data.visible)
end

-- Scan the force for any qualities that are already unlocked (e.g. researched
-- before this mod was added, or unlocked by other mods) and record them.
---@param force LuaForce
local function scan_force(force)
    local data = get_force_data(force)
    for name, quality in pairs(prototypes.quality) do
        if is_managed_quality(quality) and force.is_quality_unlocked(name) then
            data.qualities[name] = true
        end
    end
    apply_force(force)
end

local function scan_all_forces()
    for _, force in pairs(game.forces) do
        scan_force(force)
    end
end

-- Keep every player's shortcut button in sync with its force flag.
---@param force LuaForce
local function sync_shortcut(force)
    local visible = get_force_data(force).visible
    for _, player in pairs(force.players) do
        player.set_shortcut_toggled(SHORTCUT, visible)
    end
end

---------------------------------------------------------------------------
-- toggle
---------------------------------------------------------------------------

---@param player LuaPlayer
local function toggle(player)
    local force = player.force

    if not player.admin then
        player.create_local_flying_text({
            text = { 'quality-toggle.not-admin' },
            create_at_cursor = true,
        })
        -- revert the button state the click optimistically changed
        sync_shortcut(force)
        return
    end

    local data = get_force_data(force)
    data.visible = not data.visible
    apply_force(force)
    sync_shortcut(force)

    force.print({ data.visible and 'quality-toggle.enabled' or 'quality-toggle.disabled', player.name })
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------

local function refresh_all()
    init_storage()
    scan_all_forces()
    for _, force in pairs(game.forces) do
        sync_shortcut(force)
    end
end

script.on_init(refresh_all)
script.on_configuration_changed(refresh_all)

script.on_event(defines.events.on_force_created, function(event)
    scan_force(event.force)
    sync_shortcut(event.force)
end)

-- Detect quality levels unlocked through research.
script.on_event(defines.events.on_research_finished, function(event)
    local research = event.research
    for _, effect in pairs(research.prototype.effects) do
        if effect.type == 'unlock-quality' then
            record_quality(research.force, effect.quality)
        end
    end
end)

-- After a technology effects reset the game recomputes unlocks; re-scan and
-- re-apply so hidden qualities stay hidden.
script.on_event(defines.events.on_technology_effects_reset, function(event)
    scan_force(event.force)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= SHORTCUT then
        return
    end
    local player = game.get_player(event.player_index)
    if player then
        toggle(player)
    end
end)

-- A newly created player, or one moved to another force, needs its button set
-- to match its (new) force.
local function sync_player(event)
    local player = game.get_player(event.player_index)
    if player then
        player.set_shortcut_toggled(SHORTCUT, get_force_data(player.force).visible)
    end
end

script.on_event(defines.events.on_player_created, sync_player)
script.on_event(defines.events.on_player_changed_force, sync_player)
