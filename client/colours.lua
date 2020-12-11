local unpack = unpack or table.unpack

local mt = {__call = function(self, alpha)
	assert(type(alpha) == "number", "Number expected, got " .. type(alpha))
	local r, g, b = unpack(self)
	return {r, g, b, alpha}
end}

local c = function(t)
	return setmetatable(t, mt)
end

local colours = {
	gray1 = c{1/8, 1/8, 1/8},
	gray2 = c{2/8, 2/8, 2/8},
	gray3 = c{3/8, 3/8, 3/8},
	gray4 = c{4/8, 4/8, 4/8},
	gray5 = c{5/8, 5/8, 5/8},
	gray6 = c{6/8, 6/8, 6/8},
	gray7 = c{7/8, 7/8, 7/8},

	white = c{1, 1, 1},
	black = c{0, 0, 0},

	red62    = c{6/8, 2/8, 2/8},
	yellow62 = c{6/8, 6/8, 2/8},
	green62  = c{2/8, 6/8, 2/8},
}

colours.background = colours.gray1
colours.error      = colours.red62
colours.warning    = colours.yellow62
colours.success    = colours.green62
colours.text       = colours.gray7
colours.uiLines    = colours.gray5
colours.uiLabels   = colours.gray5
colours.spectator  = colours.gray4
colours.player     = colours.gray7
colours.timer      = colours.gray7
colours.wordTurn   = colours.gray7
colours.wordOther  = colours.gray2


return colours