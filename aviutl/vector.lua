ptype = type

type = function(o)
	local mt = getmetatable(o)
	if mt then
	 return mt.__type
	else
	 return ptype(o)
	end
end

function deepcopy(o)
 if ptype(o) == "table" then
	 local res = {}
	 for k, v in pairs(o) do
		 res[k] = v
		end
		setmetatable(res, getmetatable(o))
		return res
	else
	 return o
	end
end

function createVector(a, b, c)
 local o = {
	 x = (a == nil) and 0 or a,
		y = (b == nil) and 0 or b,
		z = (c == nil) and 0 or c
	}
	setmetatable(o, {
	 __type = "vector",
	 __add = function (self, b)
		 local res = {x=self.x + b.x, y=self.y + b.y, z=self.z + b.z}
			setmetatable(res, getmetatable(self))
			return res
		end,
		__sub = function (self, b)
		 local res = {x=self.x - b.x, y=self.y - b.y, z=self.z - b.z}
			setmetatable(res, getmetatable(self))
			return res
		end,
		__unm = function (self)
		 local res = {x = -self.x, y = -self.y, z = -self.z}
			setmetatable(res, getmetatable(self))
			return res
		end,
		__mul = function (self, b)
		 local res
		 if type(b) == "number" then
		  res = {x=self.x * b, y=self.y * b, z=self.z * b}
			elseif type(b) == "vector" then
			 res = {
					x = self.y * b.z - self.z * b.y,
					y = self.z * b.x - self.x * b.z,
					z = self.x * b.y - self.y * b.x
				}
			end
			setmetatable(res, getmetatable(self))
			return res
		end,
		__mod = function (self, b)
		 local res
		 if type(b) == "number" then
		  res = {x=self.x % b, y=self.y % b, z=self.z % b}
			elseif type(b) == "vector" then
		  res = {x=self.x % b.x, y=self.y % b.y, z=self.z % b.z}
			end
			setmetatable(res, getmetatable(self))
			return res
		end,
		__call = function (self, func, b)
			if func == "cross" then
			 return self * b
			elseif func == "dot" then
			 return self.x * b.x + self.y * b.y + self.z * b.z
			elseif func == "angle" then
			 return math.acos(self("dot", b) / (#self*#b))
			elseif func == "dist" then
			 return #(b - self)
			elseif func == "norm" then
			 local mag = #self
			 return self / mag
			elseif func == "rand2d" then
			 local res = {
				 x = math.random() * 2 - 1,
					y = math.random() * 2 - 1,
					z = 0
				}
				setmetatable(res, getmetatable(self))
				return res("norm")
			
			elseif func == "rand3d" then
			 local res = {
				 x = math.random() * 2 - 1,
					y = math.random() * 2 - 1,
					z = math.random() * 2 - 1
				}
				setmetatable(res, getmetatable(self))
				return res("norm")
			elseif func == "setMag" then
			 return self("norm") * b
			elseif func == "limit" then
			 local mag = #self
			 mag = math.min(mag, b)
				if mag == 0 then return createVector() end
				return self("setMag", mag)
			end
		end,
		__div = function (self, b)
		 return self * (1 / b)
		end,
		__len = function (self)
		 return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
		end,
		__tostring = function (self)
		 return string.format("[ %f, %f, %f ]", self.x, self.y, self.z)
		end
	})
	return o
end

Vector = createVector()