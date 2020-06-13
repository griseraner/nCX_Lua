-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy und ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-10-07
-- *****************************************************************
local NewMath = {
	---------------------------
	--        IsVectorIdentical
	---------------------------
	IsVectorIdentical = function(self, vec1, vec2)
		return vec1.x == vec2.x and vec1.y == vec2.y and vec1.z == vec2.z;
	end,
	---------------------------
	--        zero
	---------------------------
	zero = function(self, number)
		number = tonumber(number);
		if (number < 10 and number >= 0) then
			return "0"..number;
		end
		return number;
	end,
	---------------------------
	--        CopyVector
	---------------------------
	CopyVector = function(self, dest, src)
		dest.x = src.x;
		dest.y = src.y;
		dest.z = src.z;
	end,
	---------------------------
	--        vecSub
	---------------------------
	vecSub = function(self, va, vb)
		local v = {x=0,y=0,z=0};
		v.x = va.x-vb.x;
		v.y = va.y-vb.y;
		v.z = va.z-vb.z;
		return v;
	end,
	---------------------------
	--       vecLenSq
	---------------------------
	vecLenSq = function(self, v)
		return v.x*v.x+v.y*v.y+v.z*v.z;
	end,
	---------------------------
	--      IsNullVector
	---------------------------
	IsNullVector = function(self, a)
		return (a.x == 0 and a.y == 0 and a.z == 0);
	end,
	---------------------------
	--     LengthSqVector
	---------------------------
	LengthSqVector = function(self, a)
		return (a.x * a.x + a.y * a.y + a.z * a.z);
	end,
	---------------------------
	--      LengthVector
	---------------------------
	LengthVector = function(self, a)
		return self.sqrt((a.x * a.x + a.y * a.y + a.z * a.z));
	end,
	---------------------------
	--    DistanceSqVectors
	---------------------------
	DistanceSqVectors = function(self, a, b)
		local x = a.x-b.x;
		local y = a.y-b.y;
		local z = a.z-b.z;
		return x*x + y*y + z*z;
	end,
	---------------------------
	--   DistanceSqVectors2d
	---------------------------
	DistanceSqVectors2d = function(self, a, b)
		local x = a.x-b.x;
		local y = a.y-b.y;
		return x*x + y*y;
	end,
	---------------------------
	--    DistanceVectors
	---------------------------
	DistanceVectors = function(self, a, b)
		local x = a.x-b.x;
		local y = a.y-b.y;
		local z = a.z-b.z;
		return self.sqrt(x*x + y*y + z*z);
	end,
	---------------------------
	--    crossproduct3d
	---------------------------
	crossproduct3d = function(self, dest, p, q)
		dest.x = p.y*q.z-p.z*q.y;
		dest.y = p.z*q.x-p.x*q.z;
		dest.z = p.x*q.y-p.y*q.x;
	end,
	---------------------------
	--    dotproduct3d
	---------------------------
	dotproduct3d = function(self, a, b)
		return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
	end,
	---------------------------
	--    dotproduct2d
	---------------------------
	dotproduct2d = function(self, a, b)
		return (a.x * b.x) + (a.y * b.y);
	end,
	---------------------------
	--    SumVectors
	---------------------------
	SumVectors = function(self, a, b)
		return {x = a.x+b.x, y = a.y+b.y, z = a.z+b.z};
	end,
	---------------------------
	--    SubVectors
	---------------------------
	SubVectors = function(self, dest, a, b)
		dest.x = a.x - b.x;
		dest.y = a.y - b.y;
		dest.z = a.z - b.z;
	end,
	---------------------------
	--    FastSumVectors
	---------------------------
	FastSumVectors = function(self, dest, a, b)
		dest.x = a.x+b.x;
		dest.y = a.y+b.y;
		dest.z = a.z+b.z;
		return dest;
	end,
	---------------------------
	--    DifferenceVectors
	---------------------------
	DifferenceVectors = function(self, a, b)
		return {x = a.x-b.x, y = a.y-b.y, z = a.z-b.z};
	end,
	---------------------------
	--    ProductVectors
	---------------------------
	ProductVectors = function(self, a, b)
		return {x = a.x*b.x, y = a.y*b.y, z = a.z*b.z};
	end,
	---------------------------
	--    ScaleVector
	---------------------------
	ScaleVector = function(self, a, b)
		return {x = a.x*b, y = a.y*b, z = a.z*b};
	end,
	---------------------------
	--    ScaleVectorInPlace
	---------------------------
	ScaleVectorInPlace = function(self, a, b)
		a.x=a.x*b;
		a.y=a.y*b;
		a.z=a.z*b;
	end,
	---------------------------
	--    NormalizeVector
	---------------------------
	NormalizeVector = function(self, a)
		local len = self.sqrt(self:LengthSqVector(a));
		local multiplier;
		if(len > 0)then
			multiplier = 1/len;
		else
			multiplier = 0.0001;
		end
		a.x = a.x*multiplier;
		a.y = a.y*multiplier;
		a.z = a.z*multiplier;
		return a;
	end,
	---------------------------
	--    Lerp
	---------------------------
	Lerp = function(self, a, b, k)
		return (a + (b - a)*k);
	end,
	---------------------------
	--    Interpolate
	---------------------------
	Interpolate = function(self, actual, goal, speed)
		local delta = goal - actual;
		if (self.abs(delta) < 0.001) then
			return goal;
		end
		local res = actual + delta * self.min(speed,1.0);
		return res;
	end,	
	---------------------------
	--    GetWorldDistance
	---------------------------
	GetWorldDistance = function(self, A, B)
		local ax = (A.x or A[1]) - (B.x or B[1]);
		local ay = (A.y or A[2]) - (B.y or B[2]);
		local az = (A.z or A[3]) - (B.z or B[3]);
		return self.sqrt(ax*ax + ay*ay + az*az);
	end,
	max = new(math.max);
	min = new(math.min);
	abs = new(math.abs);
	sqrt = new(math.sqrt);
	ceil = new(math.ceil);
	floor = new(math.floor);
	random = new(math.random);
	sin = new(math.sin);
	asin = new(math.asin);
	cos = new(math.cos);
	deg = new(math.deg);
	tan = new(math.tan);
	rad = new(math.rad);
	atan2 = new(math.atan2);
	pi = new(math.pi);
	pow = new(math.pow);
};

math = new(NewMath);
