local function resolve(input)
    if input.id == "failure" then
        return nil, errors.new({ message = "host directory unavailable", kind = errors.UNAVAILABLE })
    elseif input.id == "inactive" then
        return { active = false, groups = {} }, nil
    elseif input.id == "empty" then
        return { active = true, groups = {} }, nil
    elseif input.id == "malformed" then
        return { active = true }, nil
    elseif input.id == "invalid-group" then
        return { active = true, groups = { 42 } }, nil
    elseif input.id == "sparse-groups" then
        return { active = true, groups = { [2] = "host:user" } }, nil
    end
    return { active = true, groups = { "host:user", "host:editors" } }, nil
end
return { resolve = resolve }
