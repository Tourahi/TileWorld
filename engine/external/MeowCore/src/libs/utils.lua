function Copy(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[Copy(k, s)] = Copy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

table.copy = {}
table.copy = Copy
