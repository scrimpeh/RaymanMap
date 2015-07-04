-- Initialize functions
getBlockName = function(hex)
	if hex==0x04 then
		return "reactionary"
	elseif hex>=0x08 and hex<0x0c then
		return "left";
	elseif hex>=0x0c and hex<0x10 then
		return "right";
	elseif hex>=0x10 and hex<0x14 then
		return "left small 1";
	elseif hex>=0x14 and hex<0x18 then
		return "left small 2";
	elseif hex>=0x18 and hex<0x1c then
		return "right small 1";
	elseif hex>=0x1c and hex<0x20 then
		return "right small 2";
	elseif hex>=0x20 and hex<0x24 then
		return "death";
	elseif hex>=0x24 and hex<0x28 then
		return "bounce";
	elseif hex>=0x28 and hex<0x30 then
		return "water";
	elseif hex>=0x30 and hex<0x38 then
		return "climb";
	elseif hex>=0x38 and hex<0x3c then
		return "pass down";
	elseif hex>=0x3c and hex<0x48 then
		return "full";
	elseif hex>=0x48 and hex<0x4c then
		return "slippery left";
	elseif hex>=0x4c and hex<0x50 then
		return "slippery right";
	elseif hex>=0x50 and hex<0x54 then
		return "slippery left small 1";
	elseif hex>=0x54 and hex<0x58 then
		return "slippery left small 2";
	elseif hex>=0x58 and hex<0x5c then
		return "slippery right small 1";
	elseif hex>=0x5c and hex<0x60 then
		return "slippery right small 2";
	elseif hex>=0x60 and hex<0x64 then
		return "instant mortal";
	elseif hex>=0x64 and hex<0x78 then
		return "falling";
	elseif hex>=0x78 and hex<0x80 then
		return "slippery";
	else 
		return "";
	end
end

--TODO: separate variables by how many times they needs to be refreshed?

--initialize camera / window values
windowWidth = 800; --TODO: replace with bufferwidth/height?
windowHeight= 480;
borderLeftWidth  = 86;
borderRightWidth = 74; --yes, border left > border right

tileWidthCamera =16;
tileHeightCamera=16;
xTiles=20; --20 tiles are on camera each time (horizontally)
yTiles=15;

--on screen sizes
tileWidthScreen =32;
tileHeightScreen=32;

--initialize camera data
xCameraPrevious=0;
yCameraPrevious=0;

--initialize verbose state
verboseMode=false;

form=forms.newform("RaymanMap");
mapBox=forms.checkbox(form, "Draw map", 5, 0); --TODO: checked by default?!
eventBox=forms.checkbox(form, "Draw events", 5, 30);
verboseBox=forms.checkbox(form, "Verbose (map)", 5, 60);

while true do
	if mainmemory.readbyte(0x1cee81)==1 --only draw if in a level
	then
		verboseMode=forms.ischecked(verboseBox);
		
		--camera data
		xCamera=mainmemory.read_u16_le(0x1f84b8);
		yCamera=mainmemory.read_u16_le(0x1f84c0);
		
		--interpolate camera (will be added to x, y coordinates)
		xCameraI=(xCamera - xCameraPrevious)*3; -- 3 is just a magic constant that happened to work for me
		yCameraI=(yCamera - yCameraPrevious)*3; -- ... but it might not work elsewhere
		
		--[[ DRAW MAP ]]--
		--map data
		width=mainmemory.read_u16_le(0x1f4430); --in tiles
		start=mainmemory.read_u32_le(0x1f4438)-0x80000000;
		
		if forms.ischecked(mapBox)
		then
			row=start+width*2*(math.floor(yCamera/tileHeightCamera))+2*(math.floor(xCamera/tileWidthCamera)); --16 camera indices per tile

			xSplitTile=((xCamera%tileWidthCamera) /tileWidthCamera) *tileWidthScreen;
			ySplitTile=((yCamera%tileHeightCamera)/tileHeightCamera)*tileHeightScreen;
			
			--tile positions
			for y=0, yTiles
			do
				for x=0, xTiles
				do
					xPos=x*tileWidthScreen+borderLeftWidth-xSplitTile+xCameraI;
					yPos=y*tileHeightScreen               -ySplitTile+yCameraI;
					blockType=mainmemory.readbyte(row+1+x*2);
					if verboseMode==false
						then
						if getBlockName(blockType) ~= "" then
							gui.drawImage(getBlockName(blockType) .. ".png", xPos, yPos, tileWidthScreen, tileHeightScreen);
						end
					else
						if blockType ~= 0x00 then
							gui.drawText(xPos, yPos, bizstring.hex(blockType), 0xFFFFFFFF, 14);
						end 
					end
				end
				row=row+width*2;
			end
			
			--shitty fix for drawing over the screen border
			gui.drawRectangle(0, 0, borderLeftWidth, windowHeight, 0x00000000, 0xFF000000);
			gui.drawRectangle(windowWidth - borderRightWidth, 0, borderRightWidth, windowHeight, 0x00000000, 0xFF000000);
		end
		
		--[[ DRAW EVENTS ]]--
		if forms.ischecked(eventBox)
		then
			startEv=mainmemory.read_u32_le(0x1d7ae0)-0x80000000;
			size=mainmemory.readbyte(0x1d7ae4);
			activeIndex=0x1e5428;
			
			acString="offscreen (active): ";
			for i=0, size-1
			do
				current=startEv+112*i;
				xAdr=current+0x1c;
				xEv=mainmemory.read_s16_le(xAdr);
				yEv=mainmemory.read_s16_le(xAdr+2);
				
				active=false;
				if i==mainmemory.readbyte(activeIndex)
				then
					active=true;
					activeIndex=activeIndex+2;
				end
				
				xScreen=client.transformPointX((xEv-xCamera+xCameraI)*2+borderLeftWidth)
				yScreen=client.transformPointY((yEv-yCamera+yCameraI)*2);
				
				--TODO: replace shifts with multiplication (since bytes are used this should be fine)
				off0=mainmemory.read_u32_le(current)-0x80000000;
				off4=mainmemory.read_u32_le(current+4)-0x80000000;
				off54=mainmemory.readbyte(current+0x54);
				off55=mainmemory.readbyte(current+0x55);
				
				anim2=off4+bit.lshift(bit.lshift(off54, 1)+off54, 2);
				
				animAdr=mainmemory.read_u32_le(anim2)-0x80000000;--+bit.lshift(off55, 2);
				
				--static hitbox
				--[[shAdr=mainmemory.readbyte(current+0x48);
				if shAdr~=0
				then
					hitboxAdr=0x1c1a94+bit.lshift(shAdr, 3);
					xOff=mainmemory.read_s16_le(hitboxAdr);
					yOff=mainmemory.read_s16_le(hitboxAdr+2);
					width=mainmemory.readbyte(hitboxAdr+4);
					height=mainmemory.readbyte(hitboxAdr+5);
					
					off55Calc=bit.lshift(mainmemory.read_u16_le(anim2+8)*off55, 2);
					hitOff7=bit.arshift(bit.lshift(mainmemory.readbyte(hitboxAdr+7), 0x10), 0xe);
					anim2Adr=mainmemory.read_u32_le(anim2)-0x80000000+off55Calc+hitOff7;
					
					anim2Off3=mainmemory.readbyte(anim2Adr+3);
					anim1Adr=off0+bit.lshift(bit.lshift(anim2Off3, 2)+anim2Off3, 2);
					if current==0xaeba0
					then
						--console.writeline(bizstring.hex(anim2Adr) .. " " .. bizstring.hex(anim1Adr));
					end
					
					xFinal=mainmemory.readbyte(anim2Adr+1)+bit.band(mainmemory.readbyte(anim1Adr+9), 0xf)+xEv+xOff;
					yFinal=mainmemory.readbyte(anim2Adr+2)+bit.rshift(mainmemory.readbyte(anim1Adr+9), 0x4)+yEv+xOff;
					
					gui.drawRectangle((xEv+xOff-xCamera)*2+borderLeftWidth, (yEv+yOff-yCamera)*2, width*2, height*2);
					gui.drawRectangle((xFinal-xCamera)*2+borderLeftWidth+xCameraI, (yFinal-yCamera)*2+yCameraI, width*2, height*2, "red");
				end]]--
				
				--animated hitbox
				if off55~=0
				then
					ahAdr=mainmemory.read_u32_le(anim2+4)-0x80000000+bit.lshift(off55, 2);
					axOff=mainmemory.readbyte(ahAdr);
					ayOff=mainmemory.readbyte(ahAdr+1);
					aWidth=mainmemory.readbyte(ahAdr+2);
					aHeight=mainmemory.readbyte(ahAdr+3);
					gui.drawRectangle((xEv+axOff-xCamera)*2+borderLeftWidth+xCameraI, (yEv+ayOff-yCamera)*2+yCameraI, aWidth*2, aHeight*2, "red");
				end
				
				if xScreen>=0 and yScreen>=0 and xScreen<client.screenwidth() and yScreen<client.screenheight() --on screen?
				then
					if active
					then
						gui.text(xScreen, yScreen, i, null, "green");
					else
						gui.text(xScreen, yScreen, i, null, "red");
					end
				else
					if active
					then
						acString=acString .. i .. ", ";
					end
				end
				
				
			end
			gui.text(0, 0, acString, null, "green");
		end
	end
	-- previous camera data to determine the camera speed
	xCameraPrevious=xCamera;
	yCameraPrevious=yCamera;
	
	-- advance frame
	emu.frameadvance();
end
