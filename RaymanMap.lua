--TODO: determine event type (could prove to be hard) and draw proper hitboxes (check with designer)
--rayman's flipped hitbox
--move away from forms...?
--allow form to choose between static/animated hitbox
--interpolation not only for camera but for event as well???

local getBlockName = function(hex)
	if hex == 0x04 then
		return "reactionary.png"
	elseif hex >= 0x08 and hex < 0x0c then
		return "left.png";
	elseif hex >= 0x0c and hex < 0x10 then
		return "right.png";
	elseif hex >= 0x10 and hex < 0x14 then
		return "left small 1.png";
	elseif hex >= 0x14 and hex < 0x18 then
		return "left small 2.png";
	elseif hex >= 0x18 and hex < 0x1c then
		return "right small 1.png";
	elseif hex >= 0x1c and hex < 0x20 then
		return "right small 2.png";
	elseif hex >= 0x20 and hex < 0x24 then
		return "death.png";
	elseif hex >= 0x24 and hex < 0x28 then
		return "bounce.png";
	elseif hex >= 0x28 and hex < 0x30 then
		return "water.png";
	elseif hex >= 0x30 and hex < 0x38 then
		return "climb.png";
	elseif hex >= 0x38 and hex < 0x3c then
		return "pass down.png";
	elseif hex >= 0x3c and hex < 0x48 then
		return "full.png";
	elseif hex >= 0x48 and hex < 0x4c then
		return "slippery left.png";
	elseif hex >= 0x4c and hex < 0x50 then
		return "slippery right.png";
	elseif hex >= 0x50 and hex < 0x54 then
		return "slippery left small 1.png";
	elseif hex >= 0x54 and hex < 0x58 then
		return "slippery left small 2.png";
	elseif hex >= 0x58 and hex < 0x5c then
		return "slippery right small 1.png";
	elseif hex >= 0x5c and hex < 0x60 then
		return "slippery right small 2.png";
	elseif hex >= 0x60 and hex < 0x64 then
		return "instant mortal.png";
	elseif hex >= 0x64 and hex < 0x78 then
		return "falling.png";
	elseif hex >= 0x78 and hex < 0x80 then
		return "slippery.png";
	else 
		return nil;
	end
end

--calculates screen position (as table) from the game position it is given
local gameToScreen = function(x, y)
	x = (x - camPos.x) * 2 + borderWidth.left;
	y = (y - camPos.y) * 2;
	return {x = x, y = y};
end

--draws block types by going through the list of blocks, converting them to screen coordinates and checking their type
local drawMap = function(winSize, tSizeCam, tCount, tSizeScreen)
	local cpos;
	if forms.ischecked(delayBox) 
	then
		local index = (framecounter - 3) % posCount;
		cpos = screenPositions[index];
	else
		cpos = camPos;
	end

	local width = memory.read_u16_le(0x1f4430); --in tiles
	local start = memory.read_u32_le(0x1f4438) - adr;
	
	local row = start + width * 2 * (math.floor(cpos.y / tSizeCam.h)) + 2 * (math.floor(cpos.x / tSizeCam.w)); --16 camera indices per tile

	local splitTile = {};
	splitTile.x = ((cpos.x % tSizeCam.w)  / tSizeCam.w)  * tSizeScreen.w;
	splitTile.y = ((cpos.y % tSizeCam.h) / tSizeCam.h) * tSizeScreen.h;
			
	for y = 0, tCount.y
	do
		for x = 0, tCount.x
		do
			local pos = {};
			pos.x = x * tSizeScreen.w + borderWidth.left - splitTile.x;
			pos.y = y * tSizeScreen.h - splitTile.y;
			local blockType = memory.readbyte(row + 1 + x * 2);
			if not forms.ischecked(verboseBox)
				then
				local blockFilename = getBlockName(blockType);
				if blockFilename ~= nil then
					gui.drawImage(blockFilename, pos.x, pos.y, tSizeScreen.w, tSizeScreen.h);
				end
			else
				if blockType ~= 0x00 then
					gui.drawText(pos.x, pos.y, bizstring.hex(blockType), 0xFFFFFFFF, 14);
				end 
			end
		end
		row = row + width * 2;
	end
		
	--shitty fix for drawing over the screen border
	gui.drawRectangle(0, 0, borderWidth.left, winSize.h, 0x00000000, 0xFF000000);
	gui.drawRectangle(winSize.w - borderWidth.right, 0, borderWidth.right, winSize.h, 0x00000000, 0xFF000000);
end

--gets the hitbox located in the sHitboxStart list 
local getStaticHitbox=function(current, pos, sHitboxStart, aniCounter, ani2base)	
	--TODO: replace shifts with multiplication (since bytes are used this should be fine)
	--NOT USED - previous idea to calculate position
	local aniAdr=memory.read_u32_le(ani2base)-adr;--+bit.lshift(aniCounter, 2);
	
	local hIndex=memory.readbyte(current+0x48); --event's byte that is used to get hitbox
	if hIndex~=0 --SHOULD NOT BE HERE!
	then		
		local hitboxAdr=sHitboxStart+bit.lshift(hIndex, 3); --TODO: source?
		local off={x=memory.read_s16_le(hitboxAdr), y=memory.read_s16_le(hitboxAdr+2)};
		local width=memory.readbyte(hitboxAdr+4);
		local height=memory.readbyte(hitboxAdr+5);
		
		--NOT USED - regular position calculation
		local regular=gameToScreen(pos.x+off.x, pos.y+off.y);
		--gui.drawRectangle(regular.x, regular.y, width*2, height*2);
		
		--position calculation
		--source: 1478fc
		local ani2Counter=bit.lshift(memory.read_u16_le(ani2base+8)*aniCounter, 2);
		local ani2HitOff7=bit.arshift(bit.lshift(memory.readbyte(hitboxAdr+7), 0x10), 0xe);
		
		local ani2=memory.read_u32_le(ani2base)-adr+ani2Counter+ani2HitOff7;
		local ani2SpriteIndex=memory.readbyte(ani2+3);
		
		local off0=memory.read_u32_le(current)-adr;
		local ani1=off0+bit.lshift(bit.lshift(ani2SpriteIndex, 2)+ani2SpriteIndex, 2);
		
		--OFF0 (ani1) hitbox test
		--1: use regular ani2 address! (instead of ani2Counter, ani2HitOff7)
		--2: regular ani2 add sra(sll(off5f, 0x10), 0xe)
		--[[local size={width=memory.readbyte(ani1+7), height=memory.readbyte(ani1+8)};
		if current==0xAFC40
		then
			console.writeline(bizstring.hex(ani1) .. " " .. bizstring.hex(ani2) .. " " .. bizstring.hex(ani2base));
		end
		local newPos=gameToScreen(pos.x, pos.y);
		gui.drawRectangle(newPos.x, newPos.y, size.w*2, size.h*2);]]--
		--OFF0 test end
		
		local final={};
		final.x=memory.readbyte(ani2+1)+bit.band(memory.readbyte(ani1+9), 0xf)+pos.x+off.x; --both ani1, ani2 and the static hitbox coordinates have influence
		final.y=memory.readbyte(ani2+2)+bit.rshift(memory.readbyte(ani1+9), 0x4)+pos.y+off.x;
		final=gameToScreen(final.x, final.y);

		return {x=final.x, y=final.y, w=width*2, h=height*2};
	else
		return nil;
	end
end

--gets the hitbox from off4
local getAnimatedHitbox = function(current, pos, aniCounter, ani2base)
	--source: 140804
	local hitboxAdr = memory.read_u32_le(ani2base + 4) - adr + bit.lshift(aniCounter, 2);
	local off = {x = memory.readbyte(hitboxAdr), y = memory.readbyte(hitboxAdr + 1)};
	local width = memory.readbyte(hitboxAdr + 2);
	local height = memory.readbyte(hitboxAdr + 3);
	--source: 6d loaded and processed at 147374
	local flipped = bit.band(memory.readbyte(current + 0x6d), 0x40);
	local x = pos.x + off.x;
	if flipped == 0x40
	then
		x = pos.x + bit.lshift(memory.readbyte(current + 0x52), 1) - off.x - width;
	end
	local y = pos.y + off.y;
	
	local final = gameToScreen(x, y);
	return {x = final.x, y = final.y, w = width * 2, h = height * 2};
end

--draws the index of the current even
local drawEventInfo = function(index, pos, screenPos, current, acString)	
	if screenPos.x >= 0 and screenPos.y >= 0 and screenPos.x < client.screenwidth() and screenPos.y < client.screenheight()
	then
		gui.text(screenPos.x, screenPos.y, index, "lightgreen");
		if forms.ischecked(infoBox)
		then
			local eventXs = memory.read_s16_le(current + 0x2c);
			local eventYs = memory.read_s16_le(current + 0x2e);
			
			gui.text(screenPos.x, screenPos.y + 15, "(" .. pos.x .. ", " .. pos.y .. ")");
			gui.text(screenPos.x, screenPos.y + 30, "(" .. eventXs .. ", " .. eventYs .. ")");
		end
	else
		acString = acString .. index .. ", ";
	end
	return acString;
end

--initialize camera / window values (assuming window is not resized)
local winSize = {w = 800, h = 480};
borderWidth = {left = 86, right = 74};

adr = 0x80000000;

--PERSISTENT MAP/TILE DATA
local tSizeCam = {w = 16, h = 16}; --tile size in game coordinates
local tCount = {x = 20, y = 15}; --20*15 tiles are on camera each time
--on screen sizes
local tSizeScreen = {w = 32, h = 32};

--PERSISTENT EVENT DATA
local evSize = 112;
local sHitboxStart = 0x1c1a94; --list of static hitboxes

mainForm = forms.newform("RaymanMap");
mapBox = forms.checkbox(mainForm, "Draw map", 5, 0);
verboseBox = forms.checkbox(mainForm, "Verbose", 15, 30);
delayBox = forms.checkbox(mainForm, "Adjust for delay", 120, 30);
rayBox = forms.checkbox(mainForm, "Rayman hitbox", 5, 60);
eventBox = forms.checkbox(mainForm, "Draw events", 5, 90);
aniBox = forms.checkbox(mainForm, "Animated hitbox", 15, 120);
infoBox = forms.checkbox(mainForm, "Show event info", 15, 150);

memory.usememorydomain("MainRAM");
framecounter = 0;

camPos = {x = memory.read_u16_le(0x1f84b8), y = memory.read_u16_le(0x1f84c0)};
posCount = 4;
screenPositions = {};
for i = 0, posCount - 1
do
	screenPositions[i] = camPos;
end

while true do
	if memory.readbyte(0x1cee81) == 1 --only draw if in a level
	then
		--camera data
		camPos = {x = memory.read_u16_le(0x1f84b8), y = memory.read_u16_le(0x1f84c0)};
		screenPositions[framecounter] = camPos;
		framecounter = framecounter + 1;
		if framecounter >= posCount
		then
			framecounter = 0;
		end
		
		if forms.ischecked(mapBox)
		then
			drawMap(winSize, tSizeCam, tCount, tSizeScreen);
		end
		
		--RAYMAN'S HITBOX
		if forms.ischecked(rayBox)
		then
			local off = {x = memory.read_s16_le(0x1f9a10), y = memory.read_s16_le(0x1f9a28)};
			local final = gameToScreen(off.x, off.y);
			local width = memory.readbyte(0x1f9a08);
			local height = memory.readbyte(0x1f84c8);
			gui.drawRectangle(final.x, final.y, width * 2, height * 2);
		end

		if forms.ischecked(eventBox)
		then
			--TODO: drawEvents function?
			local startEv = memory.read_u32_le(0x1d7ae0) - adr;
			local size = memory.readbyte(0x1d7ae4); --number of events
			local active = 0;
			
			local activeIndex = 0x1e5428; --current index in the list of active events located here
			local acString = "offscreen (active): ";
			
			local index = memory.read_s8(activeIndex);
			while index ~= -1
			do
				local current = startEv + evSize * index;
				local pos = {x = memory.read_s16_le(current + 0x1C), y = memory.read_s16_le(current + 0x1E)};
				
				local gamePos = gameToScreen(pos.x, pos.y);
				local screenPos = {x = client.transformPointX(gamePos.x), y = client.transformPointY(gamePos.y)}; 
				
				acString = drawEventInfo(index, pos, screenPos, current, acString);
				
				if forms.ischecked(aniBox)
				then
					local off4 = memory.read_u32_le(current + 4) - adr;
					local aniIndex = memory.readbyte(current + 0x54);
					local aniCounter = memory.readbyte(current + 0x55);
					local ani2base = off4 + bit.lshift(bit.lshift(aniIndex, 1) + aniIndex, 2);
					
					local hAnim = getAnimatedHitbox(current, pos, aniCounter, ani2base);
					if hAnim ~= nil
					then
						gui.drawRectangle(hAnim.x, hAnim.y, hAnim.w, hAnim.h, "red");
					end
				end
				
				active = active + 1
				activeIndex = activeIndex + 2;
				index = memory.read_s8(activeIndex);
			end

			gui.text(0, 0, string.format("event address: 0x%X, total events: %d, active events: %d", startEv, size, active), nil, "topright");
			gui.text(0, 15, acString, nil, "topright"); --display remaining elements
		end
	end

	emu.frameadvance();
end