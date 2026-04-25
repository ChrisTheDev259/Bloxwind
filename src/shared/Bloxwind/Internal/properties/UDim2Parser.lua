--!strict
-- UDim2Parser: standardized, lowercase-only syntax for animating Size and Position.
--
-- Accepted forms (all lowercase, always passed as a single string in the attribute):
--   "0.5"                  -> UDim2 with scale 0.5 on both axes, offset 0
--   "0.5,0.2"              -> UDim2 with scale 0.5 on X, 0.2 on Y
--   "0.5,10,0.2,0"         -> full scale + offset per axis (xScale,xOffset,yScale,yOffset)
--   "*1.1"                 -> multiply current UDim2 by 1.1 on both axes (scale AND offset)
--   "*1.2,*1.0"            -> multiply per axis
--   "+0.1,+0"              -> add to scale on each axis (offset unchanged)
--   "-0.05,-0"             -> subtract from scale on each axis
--
-- A single prefixed value ("*1.1", "+0.1", "-0.05") applies the operation to both axes.
-- Two prefixed values ("*1.2,*1.0") apply the operation per axis. Each axis can use its own op.
-- Bare numbers ("0.5" or "0.5,0.2") always mean "set scale", offset is set to 0.
--
-- Returns the new UDim2, or nil plus an error string if the input is invalid.

local UDim2Parser = {}

type Op = "set" | "mul" | "add" | "sub"

local function parseToken(token: string): (Op, number?)
	local prefix = token:sub(1, 1)
	if prefix == "*" then
		return "mul", tonumber(token:sub(2))
	elseif prefix == "+" then
		return "add", tonumber(token:sub(2))
	elseif prefix == "-" then
		return "sub", tonumber(token:sub(2))
	end
	return "set", tonumber(token)
end

local function applyOp(currentScale: number, currentOffset: number, op: Op, n: number): (number, number)
	if op == "set" then
		return n, 0
	elseif op == "mul" then
		return currentScale * n, currentOffset * n
	elseif op == "add" then
		return currentScale + n, currentOffset
	elseif op == "sub" then
		return currentScale - n, currentOffset
	end
	return currentScale, currentOffset
end

local function splitCsv(value: string): {string}
	local parts = {}
	for part in string.gmatch(value, "([^,]+)") do
		table.insert(parts, (part:gsub("%s+", "")))
	end
	return parts
end

-- current is the UDim2 we're transforming (the animation target's current value or live value).
function UDim2Parser.Parse(value: string, current: UDim2): (UDim2?, string?)
	if typeof(value) ~= "string" then
		return nil, "expected string"
	end

	value = value:lower():gsub("%s+", "")
	local parts = splitCsv(value)

	if #parts == 1 then
		local op, n = parseToken(parts[1])
		if n == nil then return nil, ("invalid number in token '%s'"):format(parts[1]) end

		local xs, xo = applyOp(current.X.Scale, current.X.Offset, op, n)
		local ys, yo = applyOp(current.Y.Scale, current.Y.Offset, op, n)
		return UDim2.new(xs, xo, ys, yo)

	elseif #parts == 2 then
		local xOp, xn = parseToken(parts[1])
		local yOp, yn = parseToken(parts[2])
		if xn == nil then return nil, ("invalid number in x token '%s'"):format(parts[1]) end
		if yn == nil then return nil, ("invalid number in y token '%s'"):format(parts[2]) end

		local xs, xo = applyOp(current.X.Scale, current.X.Offset, xOp, xn)
		local ys, yo = applyOp(current.Y.Scale, current.Y.Offset, yOp, yn)
		return UDim2.new(xs, xo, ys, yo)

	elseif #parts == 4 then
		-- full form: xScale,xOffset,yScale,yOffset (set only, no prefixes allowed here)
		local xs = tonumber(parts[1])
		local xo = tonumber(parts[2])
		local ys = tonumber(parts[3])
		local yo = tonumber(parts[4])
		if not (xs and xo and ys and yo) then
			return nil, "invalid 4-part UDim2 literal (expected plain numbers)"
		end
		return UDim2.new(xs, xo, ys, yo)
	end

	return nil, ("expected 1, 2, or 4 comma-separated parts, got %d"):format(#parts)
end

return UDim2Parser
