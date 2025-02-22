local function get_force_sorted(caster)
    local force_sorted = false
    local base_wand = nil
    local wands = {}
    local inventories = EntityGetAllChildren(caster) or {}
    for inventory_index = 1, #inventories do
        if EntityGetName(inventories[inventory_index]) == "inventory_quick" then
            local children = EntityGetAllChildren(inventories[inventory_index]) or {}
            for i = 1, #children do
                if EntityHasTag(children[i], "wand") then
                    wands[#wands+1] = children[i]
                end
            end
            break
        end
    end
    if #wands > 0 then
        local inventory2 = EntityGetFirstComponent(caster, "Inventory2Component")
        local active_item = ComponentGetValue2(inventory2, "mActiveItem")
        for wand_index = 1, #wands do
            if wands[wand_index] == active_item then
                base_wand = wands[wand_index]
                break
            end
        end
    end
    if base_wand ~= nil then
        local wand_children = EntityGetAllChildren(base_wand) or {}
        for i=1,#wand_children do
            if EntityHasTag( wand_children[i], "card_action" ) then
                local iac = EntityGetFirstComponentIncludingDisabled( wand_children[i], "ItemActionComponent" )
                if ComponentGetValue2( iac, "action_id" ) == "COPIS_THINGS_ORDER_DECK" then
                    force_sorted = true
                    break
                end
            end
            if force_sorted then
                break
            end
        end
    end
    return force_sorted
end

local function order_deck()

    copi_state.skip_type = {
        [0] = false,
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false,
        [6] = false,
        [7] = false,
    }

    local shooter = GetUpdatedEntityID()
    local force_sorted = get_force_sorted(shooter)

    if force_sorted then
        local before = gun.shuffle_deck_when_empty
        gun.shuffle_deck_when_empty = false
        copi_state.old._order_deck()
        gun.shuffle_deck_when_empty = before
    else
        copi_state.old._order_deck()
    end

    local vsc = EntityGetFirstComponent(shooter, "VariableStorageComponent", "mana_efficiency_mult")
    local shooter_mult = (vsc and ComponentGetValue2(vsc, "value_float")) or 1.0

    --[[print(string.rep("\n", 3))
    print(string.rep("=", 83))]]
    -- This allows me to hook into the mana access and call an arbitrary function. Very tricksy :^)
    for _, action in pairs(deck) do
        --[[print(string.rep("\n", 3))
        print(string.rep("-", 83))
        for key, value in pairs(action) do
            print(string.format("%-40s | %40s", tostring(key), GameTextGetTranslatedOrNot(tostring(value))))
        end]]
        if action.copi_mana_calculated == nil then
            if action.type == ACTION_TYPE_PROJECTILE or action.type == ACTION_TYPE_STATIC_PROJECTILE or
                action.type == ACTION_TYPE_MATERIAL or action.type == ACTION_TYPE_UTILITY then
                local base_mana = action.mana or 0
                action.mana = nil
                local action_meta = {
                    __index = function(table, key)
                        if key == "mana" then
                            return (base_mana * copi_state.mana_multiplier) * shooter_mult
                        end
                    end
                }
                setmetatable(action, action_meta)
            end
            action.copi_mana_calculated = true
        end
    end
end

return {order_deck = order_deck}