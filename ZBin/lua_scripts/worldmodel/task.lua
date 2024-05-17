module(..., package.seeall)

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

function compensateDir(angle1,angle2)

	local ToNextDir = angle1
	if type(angle1) == 'function' then
	    ToNextDir = angle1()
	else
	    ToNextDir = angle1
	end

	local ToEnemyDir = angle2d
	if type(angle2) == 'function' then
	    ToEnemyDir = angle2()
	else
	    ToEnemyDir = angle2
	end 
	local ToEDiff=ToEnemyDir + 180
	local ToNDiff=ToNextDir + 180
	local EnNeDiff= math.abs(ToEDiff - ToNDiff)

	local ToTargetDir = ToNextDir - ToEnemyDir 
	if EnNeDiff >30 then
		return 0
	else	
		if ToTargetDir < 0 then
			return 1
		else 
			return -1
		end
	end
end
function getBall2024(role,targetPos)
	return function()
		local itargetPos
		if type(targetPos) == "function" then
			itargetPos = targetPos()
		else
			itargetPos = targetPos
		end
		local p
		local ballPos = ball.pos() + Utils.Polar2Vector(-80,(ball.pos() - player.pos(role)):dir())


		if player.infraredCount(role) < 20 then
			p = ballPos
			idir = player.toBallDir(role)
		else
			p = player.pos(role)
			idir = (itargetPos -player.pos(role) ):dir()

		end
		local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(99999,ball.velDir()))
		local getInterPos = ballLine:projection(player.pos(role))

		if ball.velMod() > 500 and ballLine:IsPointOnLineOnSegment(getInterPos)then
			p = getInterPos
			idir = player.toBallDir(role)
		end
		local v_ = 0
		local bp =ball.pos()
		local plp =player.pos(role)
		local Diff = math.abs((bp -plp ):mod())
		local BallVel =ball.velMod()
		--嵌套if语句，实现距离减小，末速减小

		
		if BallVel > 1500 then           -- [1500,+max]
			v_ = 450
		else                             --[0,1500]
			
			if BallVel > 700 then           --[700,1500]
				v_ = 300
			else                            --[0,700]
				v_ = 200
				if BallVel < 400 then           --[0,400]
					v_ = 200
						
					if BallVel < 200 then         --[0,200]
							v_ = 100
						if Diff < 100 then
							v_ = 50
						else 
							v_ = 100
						end
					else                          --[200,400]
						if Diff < 100 then 
							v_ = 50
						else 
							v_ = 100
						end
					end
				else                             --[400,700]
					v_ = 300
				end
			end
		end 




		
		local endVel = Utils.Polar2Vector(v_,(p - player.pos(role)):dir())
		local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = endVel, speed = s, force_manual = force_manual }
		return { mexe, mpos }
	end
end





function getBall_BallPlacement(role)
	return function()
		local ballPos = GlobalMessage.Tick.ball.pos
		-- debugEngine:gui_debug_x(ballPos,3)
		local placementflag = bit:_or(flag.dribbling, flag.our_ball_placement)
		local ballPlacementPos = CGeoPoint(ball.placementPos():x(),ball.placementPos():y())
		local ipos = ball.pos()
		local idir = player.toBallDir(role)
		local ia = 800
		--如果球在场地内，机器人就可以走到球后面然后推着球走
		if Utils.InField(ballPos) then
			local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
			local playerDir = math.abs(( ballPlacementPos - player.pos(role)):dir()) * 57.3
			local Subdir = math.abs(toballDir-playerDir)
			
			if bufcnt (Subdir < 18 and player.toBallDist(role) < 200,60) then
				debugEngine:gui_debug_msg(CGeoPoint(0,0),"1")
				placementflag = flag.our_ball_placement + flag.dribbling
				idir =  (ballPlacementPos - player.pos(role)):dir()
				ipos = ballPlacementPos + Utils.Polar2Vector(-90,idir)
			else
				debugEngine:gui_debug_msg(CGeoPoint(0,0),"2")
				local DSS_FLAG = flag.our_ball_placement + flag.dodge_ball
				placementflag =  DSS_FLAG
				ipos = ball.pos() + Utils.Polar2Vector(-150, (ballPlacementPos - ball.pos()):dir())
			end
		else
			-- debugEngine:gui_debug_msg(CGeoPoint(100,1000),player.myinfraredCount(role))
			
			if player.myinfraredCount(role) < 20 then
				local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
				local playerDir = math.abs((player.pos(role) -  ballPlacementPos):dir()) * 57.3
				local Subdir = math.abs(toballDir-playerDir)
				if bufcnt( Subdir < 18 and player.toBallDist(role) < 200,60) then
					debugEngine:gui_debug_msg(CGeoPoint(0,0),"3")
					placementflag = flag.our_ball_placement + flag.dribbling
					idir =  (player.pos(role) - ballPlacementPos ):dir()
					ipos = ball.pos() + Utils.Polar2Vector(-30,idir)

				else
					debugEngine:gui_debug_msg(CGeoPoint(0,0),"4")
					local DSS_FLAG = flag.our_ball_placement + flag.dodge_ball
					placementflag =  DSS_FLAG
					idir = player.toBallDir(role)
					ipos = ball.pos() + Utils.Polar2Vector(-120,(ball.pos() - ballPlacementPos):dir())
					ia = 2000
				end
			else
				debugEngine:gui_debug_msg(CGeoPoint(0,0),"5")
				idir =  (player.pos(role) - ballPlacementPos ):dir()
				ipos = ballPlacementPos + Utils.Polar2Vector(0,idir)
			end


		end
		local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = ia, flag = placementflag, rec = r, vel = v, speed = s, force_manual = force_manual }
		return { mexe, mpos }
	end
end









function angleDiff(angle1,  angle2)
    return math.atan2(math.sin(angle2 - angle1), math.cos(angle2 - angle1));
end

--补偿角度
function compensateAngle(role,robotRotVel,Pos,Kp)

	local iPos
	if type(Pos) == "function" then
		iPos = Pos()
	else
		iPos = Pos
	end

	local new_pos = iPos + Utils.Polar2Vector(robotRotVel * Kp, (iPos - player.pos(role)):dir() + math.pi / 2)
	return new_pos
end

-- 解决截球算点抖动问题
lastMovePoint = CGeoPoint:new_local(param.INF, param.INF)
function stabilizePoint(p)
	if lastMovePoint:dist(p) < 50 then
		return lastMovePoint
	end
	lastMovePoint = p
	return p
end

-- 快速移动
function endVelController(role, p)
	local endvel = Utils.Polar2Vector(50,(player.pos(role) - p):dir())
	if player.toPointDist(role, p) > param.playerRadius*2 then
		endvel = Utils.Polar2Vector(-100,(player.pos(role) - p):dir())
	end
	return endvel
end

function TurnRun(pos,vel)
	local ipos = pos or  CGeoPoint:new_local(0,80)  --自身相对坐标 旋转
	local ivel = vel -- 旋转速度 -+ 改变方向
	local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
	return { mexe, mpos }
end



function getball(FirstPos,playerVel, inter_flag, permissions)
	return function(runner)
		local IFirstPos
		if type(FirstPos) == "function" then
			IFirstPos = FirstPos()
		else
			IFirstPos = FirstPos
		end
		ipermissions = permissions or 0

		local mexe, mpos = Getball {firstPos = IFirstPos,permissions = permissions ,inter_flag = inter_flag, pos = pp, dir = idir, acc = a, flag = iflag, rec = 1, vel = v }
		return { mexe, mpos }
	end
end

function getballV2(role, playerVel, inter_flag, target_point, permissions)
	return function()
		local p1
		if type(target_point) == 'function' then
			p1 = target_point()
		else
			p1 = target_point
		end
		if permissions == nil then
			permissions = 0
		end

		if player.myinfraredCount(role) < 5 then
			local qflag = inter_flag or 0
			local playerPos = CGeoPoint:new_local( player.pos(role):x(),player.pos(role):y())
			local inter_pos = stabilizePoint(Utils.GetBestInterPos(vision,playerPos,playerVel,qflag,permissions))
			
			local idir = player.toBallDir(role)
			local ipos = ball.pos()
			if inter_pos:x()  ==  param.INF or inter_pos:y()  == param.INF then
				ipos = ball.pos()
			else
				ipos = inter_pos
			end
			
			-- local toballDir = math.abs(player.toBallDir(role))  * 57.3
			local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
			local playerDir = math.abs(player.dir(role)) * 57.3
			local Subdir = math.abs(toballDir-playerDir)
			local subPlayerBallToTargetDir = toballDir - playerDir 
			local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
			if Subdir > 20 then 
				  --自身相对坐标 旋转

				if subPlayerBallToTargetDir < 0 then
					local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
					local ivel = 10 * -1
					local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
					return { mexe, mpos }
				else
					
					local ipos = param.rotPos  --自身相对坐标 旋转
					local ivel = 10
					local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
					return { mexe, mpos }
				end
			else
				iflag = flag.dribbling
			end
			ipos = CGeoPoint:new_local(ipos:x(),ipos:y())
			ipos = stabilizePoint(ipos)
			local endvel = Utils.Polar2Vector(300,(ipos - player.pos(role)):dir())
			local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = iflag, rec = r, vel = endvel }
				return { mexe, mpos }
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local iflag = flag.dribbling
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = iflag, rec = 1, vel = v }
			return { mexe, mpos }
		end
	end
end

--blue
playerPower = {
	-- [num] = {min, max, KP} 
	[0] = {260,260,0},
	[1] = {260,260,0},
	[2] = {280,280,0},---
	[3] = {260,260,0},
	[4] = {260,260,0},
	[5] = {260,260,0},---
	[6] = {260,260,0},---
	[7] = {260,260,0},---
	[8] = {230,310,0},
	[9] = {230,310,0},
	[10] = {230,310,0},
	[11] = {230,310,0},
	[12] = {230,310,0},
	[13] = {230,310,0},
	[14] = {230,310,0},
	[15] = {230,310,0},
	[16] = {230,310,0}, -- Other
}
--yello
--[[playerPower = {
	-- [num] = {min, max, KP} 
	[0] = {260,260,0},
	[1] = {260,260,0},
	[2] = {280,280,0},---
	[3] = {260,260,0},
	[4] = {260,260,0},
	[5] = {260,260,0},---
	[6] = {260,260,0},---
	[7] = {260,260,0},---
	[9] = {230,310,0},
	[10] = {230,310,0},
	[11] = {230,310,0},
	[12] = {230,310,0},
	[13] = {230,310,0},
	[14] = {230,310,0},
	[15] = {230,310,0},
	[16] = {230,310,0}, -- 
}

--]]
function power(p, Kp, num) --根据目标点与球之间的距离求出合适的 击球力度 kp系数需要调节   By Umbrella 2022 06
	return function()
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local playerNum
		if type(num) == 'function' then
			playerNum = num()
		else
			playerNum = num
		end
		local dist = (p1 - ball.pos()):mod()
		
		if playerNum == -1 or playerNum == nil then
			playerNum = 16	
		end
		local res = (Kp + playerPower[playerNum][3]) * dist

		if param.isReality then
			if res < playerPower[playerNum][1] then
				res = playerPower[playerNum][1] 
			end
			if res > playerPower[playerNum][2] then
				res = playerPower[playerNum][2] 
			end
		else
			local SimulationRate = 20
			if res < playerPower[playerNum][1]  * SimulationRate then
				res = playerPower[playerNum][1] * SimulationRate
			end
			if res > playerPower[playerNum][2]  * SimulationRate then
				res = playerPower[playerNum][2] * SimulationRate
			end
		end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,3200),"Power" .. res .. "    toTargetDist: " .. dist,3)
		return res
	end
end

function GetBallV2(role, p, dist1, speed1) -------dist开始减速的距离   speed减速的速度
	--参数说明
	--role  使用这个函数的角色
	--p	    拿到球后指向的目标点
	--dist  距离球dist mm时开始减速
	--speed 减速后的速度 （范围 0～2500）			
	return function()
		local dist = dist1 or 0
		local speed = speed1 or 0
		local minDist = 9999999
		local longDist = 0
		local ballspeed = 800

		local p1 = p
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		if (player.myinfraredCount(role) < 20) then
			if ((player.pos(role) - ball.pos()):mod() < dist) then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(0, idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(longDist, idir)
				end
				local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = speed, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			else
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-1 * dist + 10, idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(longDist, idir)
				end
				local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			end
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
			return { mexe, mpos }
		end
	end
end

function TurnToPoint(role, p, speed)
	-- 函数说明: 
		--使用前提：拿到球之后
		--功能：以球为中心旋转到目标点,需要在State层跳出
	--参数说明	
		-- role 	 使用这个函数的角色
		-- p	     指向坐标
		-- speed	 旋转速度 [1,10]
	local p1 = p
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end
	if speed == nil then
		speed = param.rotVel
		
	end
	debugEngine:gui_debug_x(p1,6)
	local toballDir = (p1 - player.rawPos(role)):dir() * 57.3
	local playerDir = player.dir(role) * 57.3
	local subPlayerBallToTargetDir = toballDir - playerDir 
	-- local Subdir = math.abs(toballDir-playerDir)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,380),toballDir .. "                     " .. playerDir,4)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,220),math.abs(toballDir-playerDir) .. "                     " .. subPlayerBallToTargetDir,3)
	if math.abs(toballDir-playerDir) > 4 then
		if subPlayerBallToTargetDir  <0 then
			-- 顺时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "顺时针")
			local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
			local ivel = speed * -1
			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		else
			-- 逆时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "逆时针")
			local ipos = param.rotPos  --自身相对坐标 旋转
			local ivel = speed

			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		end
	else
		local idir = (ball.pos() - player.pos(role)):dir()
		local pp = ball.pos() + Utils.Polar2Vector(50, idir)
		local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
		return { mexe, mpos }  
	end
end

function TurnToPointV1(role, p, speed)
	--参数说明
	-- role 	 使用这个函数的角色
	-- p	     指向坐标
	-- speed	 旋转速度
	return function()
		local p1 = p
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		if speed == nil then
			speed = 800
		end
		local playerPos = player.pos(role)
		local playerDir = player.dir(role)
		local playerToBallDist = player.toBallDist(role)
		local playerToBallDir = (ball.pos() - player.pos(role)):dir()
		local playerToTargetDir = (p1 - player.pos(role)):dir()
		local ballPos = CGeoPoint:new_local (ball.posX(),ball.posY())
		local ballToTargetDir = (p1 - ball.pos()):dir()
		local subPlayerBallToTargetDir = playerToTargetDir - ballToTargetDir
		-- Debug
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*0), string.format("playerDir:         	   %6.3f", playerDir),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*1), string.format("playerToBallDir:         %6.3f", playerToBallDir),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*2), string.format("playerToTargetDir:       %6.3f", playerToTargetDir),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*3), math.abs(playerDir-playerToTargetDir)*57.3)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*4), string.format("playerToBallDist:       %6.3f", playerToBallDist),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*5), string.format("sub:       %6.3f", ballToTargetDir-playerToTargetDir),param.BLUE)
		-- debugEngine:gui_debug_x(p)
    	
		-- 逆时针旋转
		local idirLeft = (playerDir+param.PI/2)>param.PI and playerDir-(3/2)*param.PI or playerDir+param.PI/2 
		-- 顺时针旋转
		local idirRight = (playerDir-param.PI/2)>param.PI and playerDir+(3/2)*param.PI or playerDir-param.PI/2

		-- if math.abs(playerDir-playerToTargetDir) > 0.14 or math.abs(playerDir-playerToBallDir) > 0.40 then
		if math.abs(playerDir-playerToTargetDir) > 0.14 then
			if subPlayerBallToTargetDir > 0 then
				-- 逆时针旋转
				-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "0")
				local target_pos = playerPos+Utils.Polar2Vector(speed, idirLeft)+Utils.Polar2Vector(2*playerToBallDist, playerToBallDir)
				debugEngine:gui_debug_x(target_pos)
				local mexe, mpos = GoCmuRush { pos = target_pos, dir = playerToBallDir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			end
			-- 顺时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "1")
			local target_pos = playerPos+Utils.Polar2Vector(speed, idirRight)+Utils.Polar2Vector(2*playerToBallDist, playerToBallDir)
			debugEngine:gui_debug_x(target_pos)
			local mexe, mpos = GoCmuRush { pos = target_pos, dir = playerToBallDir, acc = a, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
		-- else
		elseif playerToBallDist > 1 then
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000, 1000), "2")
			local mexe, mpos = GoCmuRush { pos = ballPos, dir = playerToTargetDir, acc = a, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
			return { mexe, mpos }  

		end
	end
end

function TurnToPointV2(role, p, speed)
	--参数说明
	-- role 	 使用这个函数的角色
	-- p	     指向坐标
	-- speed	 旋转速度
	local p1 = p
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end

	if speed == nil then
		speed = param.rotVel
	end
	debugEngine:gui_debug_x(p1,6)

	-- local playerDir = player.dir(role)
	-- local playerToTargetDir = (p1 - player.pos(role)):dir() * 57.3
	-- local ballToTargetDir = (p1 - ball.pos()):dir() * 57.3
	-- local subPlayerBallToTargetDir = playerToTargetDir - ballToTargetDir
		local toballDir = (p1 - player.rawPos(role)):dir() * 57.3
		local playerDir = player.dir(role) * 57.3
		local subPlayerBallToTargetDir = toballDir - playerDir 
		-- local Subdir = math.abs(toballDir-playerDir)
		debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,380),toballDir .. "                     " .. playerDir,4)
		debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,220),math.abs(toballDir-playerDir) .. "   " .. subPlayerBallToTargetDir,3)
	if math.abs(toballDir-playerDir) > 4 then
		if subPlayerBallToTargetDir<0 then
			if subPlayerBallToTargetDir<-180 then
				local ipos = param.rotPos  --自身相对坐标 旋转
				local ivel = speed
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			
			else
				local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
				local ivel = speed * -1
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			end
		else 
			if subPlayerBallToTargetDir<180 then
				local ipos = param.rotPos  --自身相对坐标 旋转
				local ivel = speed
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }


			else 
				local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
				local ivel = speed * -1
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			end
		end


		--[[if subPlayerBallToTargetDir < 360  or subPlayerBallToTargetDir> 280  then
			-- 顺时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "顺时针")
			local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
			local ivel = speed * -1
			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		else
			-- 逆时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "逆时针")
			local ipos = param.rotPos  --自身相对坐标 旋转
			local ivel = speed

			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		end--]]
	else
		local idir = (ball.pos() - player.pos(role)):dir()
		local pp = ball.pos() + Utils.Polar2Vector(50, idir)
		local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
		return { mexe, mpos }  
		
	end
end

function TurnToPointV3(role, p, speed)
	--参数说明
	-- role 	 使用这个函数的角色
	-- p	     指向坐标
	-- speed	 旋转速度
	local p1 = p
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end

	if speed == nil then
		speed = param.rotVel
	end
	debugEngine:gui_debug_x(p1,6)

	-- local playerDir = player.dir(role)
	-- local playerToTargetDir = (p1 - player.pos(role)):dir() * 57.3
	-- local ballToTargetDir = (p1 - ball.pos()):dir() * 57.3
	-- local subPlayerBallToTargetDir = playerToTargetDir - ballToTargetDir
		local toballDir = (p1 - player.rawPos(role)):dir() * 57.3
		local playerDir = player.dir(role) * 57.3
		local subPlayerBallToTargetDir = toballDir - playerDir 
		-- local Subdir = math.abs(toballDir-playerDir)
		debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,380),toballDir .. "                     " .. playerDir,4)
		debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,220),math.abs(toballDir-playerDir) .. "   " .. subPlayerBallToTargetDir,3)
	if math.abs(toballDir-playerDir) > 4 then
		if subPlayerBallToTargetDir<0 then
			--[[if subPlayerBallToTargetDir<-180 then--]]
				local ipos = param.rotPos  --自身相对坐标 旋转
				local ivel = speed
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			
			--[[else
				local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
				local ivel = speed * -1
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			end--]]
		else 
			--[[if subPlayerBallToTargetDir<180 then--]]
				local ipos = param.rotPos  --自身相对坐标 旋转
				local ivel = speed
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }


			--[[else 
				local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
				local ivel = speed * -1
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			end--]]
		end


		--[[if subPlayerBallToTargetDir < 360  or subPlayerBallToTargetDir> 280  then
			-- 顺时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "顺时针")
			local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
			local ivel = speed * -1
			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		else
			-- 逆时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "逆时针")
			local ipos = param.rotPos  --自身相对坐标 旋转
			local ivel = speed

			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		end--]]
	else
		local idir = (ball.pos() - player.pos(role)):dir()
		local pp = ball.pos() + Utils.Polar2Vector(50, idir)
		local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
		return { mexe, mpos }  
		
	end
end


function ShootdotV2(p, Kp, error_, flag_)
	return function(runner)
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end

		local kp1
		if type(Kp) == 'function' then
			kp1 = Kp()
		else
			kp1 = Kp
		end
		local shootpos = function(runner)
			return ball.pos() + Utils.Polar2Vector(-50, (p1 - ball.pos()):dir())
		end
		local idir = function(runner)
			return (p1 - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end

		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = v }
		return { mexe, mpos, flag_, idir, error__, power(p, kp1,runner), power(p, kp1,runner), flag.dribbling }
	end
end


function Shootdot(role,p, Kp, error_, flagShoot) --
	return function(runner)
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local kp1
		if type(Kp) == 'function' then
			kp1 = Kp()
		else
			kp1 = Kp
		end
		local shootpos = ball.pos() + Utils.Polar2Vector(-50, (p1 - ball.pos()):dir())
		local idir = function()
			return (p1 - player.pos(role)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
		local endvel = Utils.Polar2Vector(300,player.toBallDir(role))
		-- local toballDir = math.abs(player.toBallDir(role))  * 57.3
		local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
		local playerDir = math.abs(player.dir(role)) * 57.3
		local Subdir = math.abs(toballDir-playerDir)
		local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
		if Subdir > error_ then 
			local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
			iflag =  DSS_FLAG
			shootpos = ball.pos() + Utils.Polar2Vector(-300, (p1 - ball.pos()):dir())

		else
			iflag = flag.dribbling
		end
		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
		return { mexe, mpos, flagShoot, idir, error__, power(p, kp1, player.num(role)), power(p, kp1, player.num(role)), 0x00000000 }
	end
end


-- function getBallAndShootToPoint(role, target)
-- 	if type(target) == "function" then
-- 		target = target()
-- 	end

-- 	local roleDir = player.dir(role)
-- 	local ballToTargetDir = (target - ball.rawPos()):dir()

-- 	debugEngine:gui_debug_msg(CGeoPoint(1000, 1000),player.myinfraredCount(role))

-- 	if(playerDirToPointDirSub(role,target) < param.shootError) then 
-- 		local kp = 1
-- 		local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
-- 		local idir = function(runner)
-- 			return (target - player.pos(runner)):dir()
-- 		end
-- 		local mexe, mpos = GoCmuRush { pos = rolePos, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, rolePos) }
-- 		-- return { mexe, mpos, kick.chip, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
-- 		return { mexe, mpos, kick.flat, idir, pre.low, power(target, kp), power(target, kp), 0x00000000 }
-- 	else

-- 	end

-- 	if math.abs(roleDir - ballToTargetDir) < 0.1 and player.myinfraredCount(role) > 10 then
		
-- 	end
-- 	-- local ikick = chip and kick.chip or kick.flat
-- 	-- local ipower = power and power or 8000
-- 	-- local idir = d and d or dir.shoot()
-- 	-- local iflag = 0x00000000
-- 	-- local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
-- 	-- return { mexe, mpos, ikick, idir, pre.low, kp.specified(8000), cp.full, iflag }


-- 	local tTable = getball(role, param.playerVel, 1, target, 1)()
-- 	return tTable
-- end


function enemyDirToPointDirSub(role, p)
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end
	local playerDir = enemy.dir(role) * 57.3 + 180
	local playerPointDit = (p1 - enemy.pos(role)):dir() * 57.3 + 180
	local sub = math.abs(playerDir - playerPointDit)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -3000),  "AngleError: ".. sub)
	return sub
end


function playerDirToPointDirSub(role, p) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end
	local playerDir = player.dir(role) * 57.3 + 180
	local playerPointDit = (p1 - player.rawPos(role)):dir() * 57.3 + 180
	local sub = math.abs(playerDir - playerPointDit)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -4000),  "AngleError: ".. sub)
	return sub
end

function pointToPointAngleSub(p, p2) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end
	local dir_pass = (ball.pos() - p2):dir() * 57.3 + 180
	local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	if sub > 300 then
		sub = 360 - sub
	end
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000, 0), sub)
	return sub
end

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---



--~		Play中统一处理的参数（主要是开射门）
--~		1 ---> task, 2 ---> matchpos, 3---->kick, 4 ---->dir,
--~		5 ---->pre,  6 ---->kp,       7---->cp,   8 ---->flag
------------------------------------- 射门相关的skill ---------------------------------------
-- TODO
------------------------------------ 跑位相关的skill ---------------------------------------
--~ p为要走的点,d默认为射门朝向

function touch()
	local ipos = pos.ourGoal()
	local mexe, mpos = Touch { pos = ipos }
	return { mexe, mpos }
end

function touchKick(p, ifInter, Kp, mode)
	return function(runner)
		local ipos 
		local idir = function(runner)
			return (_c(p) - player.pos(runner)):dir()
		end
		local mexe, mpos = Touch { pos = p, useInter = ifInter }
		return { mexe, mpos, mode and kick.flat or kick.chip, idir, pre.low, power(p,Kp,runner), power(p,Kp,runner), flag.nothing }
	end
end

function goSpeciPos(p, d, f, a) -- 2014-03-26 增加a(加速度参数)
	local idir
	local iflag
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end

	if f ~= nil then
		iflag = f
	else
		iflag = 0
	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = iflag }
	return { mexe, mpos }
end

function goSimplePos(p, d, f)
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end

	if f ~= nil then
		iflag = f
	else
		iflag = 0
	end

	local mexe, mpos = SimpleGoto { pos = p, dir = idir, flag = iflag }
	return { mexe, mpos }
end

function runMultiPos(p, c, d, idir, a, f)
	if c == nil then
		c = false
	end

	if d == nil then
		d = 20
	end

	if idir == nil then
		idir = dir.shoot()
	end

	local mexe, mpos = RunMultiPos { pos = p, close = c, dir = idir, flag = f, dist = d, acc = a }
	return { mexe, mpos }
end

function staticGetBall(target_pos, dist)
	local idist = dist or 140
	local p = function()
		local target = _c(target_pos) or pos.theirGoal()
		return ball.pos() + Utils.Polar2Vector(idist, (ball.pos() - target):dir())
	end
	local idir = function()
		local target = _c(target_pos) or pos.theirGoal()
		return (target - ball.pos()):dir()
	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, flag = flag.dodge_ball }
	return { mexe, mpos }
end

function goCmuRush(p, d, a, f, r, v, s, force_manual)
	-- p : CGeoPoint, pos
	-- d : double, dir
	-- a : double, max_acc
	-- f : int, flag
	-- v : CVector, target_vel
	-- s : double, max_speed
	-- force_manual : bool, force_manual
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
	return { mexe, mpos }
end

function forcekick(p, d, chip, power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
	return { mexe, mpos, ikick, idir, pre.low, kp.specified(ipower), cp.full, flag.forcekick }
end

function shoot(p, d, chip, power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local iflag = 0x00000000
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
	return { mexe, mpos, ikick, idir, pre.low, kp.specified(8000), cp.full, iflag }
end

------------------------------------ 防守相关的skill ---------------------------------------
-- Defender

function isBallPassingToOurArea()
	local aimLine = CGeoSegment(CGeoPoint:new_local(param.defenderAimX, param.INF), CGeoPoint:new_local(param.defenderAimX, -param.INF))
	local ballPos = CGeoPoint:new_local(ball.rawPos():x(), ball.rawPos():y())
	local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ball.velDir()))
	local tp = aimLine:segmentsIntersectPoint(ballLine)
	if Utils.InField(tp) then
		return true
	end
	-- debugEngine:gui_debug_x(tp, param.GREEN)
	-- debugEngine:gui_debug_line(CGeoPoint:new_local(param.defenderAimX, param.INF), CGeoPoint:new_local(param.defenderAimX, -param.INF))
	-- debugEngine:gui_debug_line(ballPos, ballPos+Utils.Polar2Vector(param.INF, ball.velDir()))
	return false
end

-- 获得拥有球或者球将会传到的敌人
function getManMarkEnemy()
	local closestBallEnemyNum = enemy.closestBall()
	local enemyNum = closestBallEnemyNum
	-- 找到需要盯防的人 --enemyNum
	if enemy.toBallDist(closestBallEnemyNum) > 100 and enemy.atBallLine() ~= -1 then
		enemyNum = enemy.atBallLine()
	end
	-- debug
	-- debugEngine:gui_debug_msg(CGeoPoint(0, 0), enemyNum)
	local enemyPos = enemy.pos(enemyNum)
	debugEngine:gui_debug_x(enemyPos, param.BLUE)
	return enemyNum
end

defenderCount = 0
defenderNums = {}
function getDefenderCount()
	defenderCount = 0
	for i=0, param.maxPlayer-1 do
		playerName = player.name(i)
		if player.valid(i) and (playerName == "Tier" or playerName == "Defender") then
			defenderNums[defenderCount] = i
			defenderCount = defenderCount + 1
		end
	end
	return defenderCount
end

-- defender who is the cloest the point 
function isClosestPointDefender(role, p)
	local minCatchBallDist = param.INF
	local roleNum = -1
	for i=0, defenderCount-1 do
		local playerPos = CGeoPoint:new_local(player.rawPos(defenderNums[i]):x(), player.rawPos(defenderNums[i]):y())
		if playerPos:dist(p) < minCatchBallDist then
			minCatchBallDist = playerPos:dist(p)
			roleNum = defenderNums[i]
		end
	end
	return player.num(role)==roleNum and true or false
end

-- defender_norm script 
-- mode: 0 upper area, 1 down area, 2 middle
-- flag: 0 aim the ball, 1 aim the enemy
function defend_norm(role, mode, flag)
	getDefenderCount()
	if defenderCount == 1 then
		mode = 2
	end
	if flag == nil then
		flag = 0
	end
	local enemyNum = getManMarkEnemy()
	local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
	local goalieToEnemyDir = (enemy.pos(enemyNum) - player.rawPos("Goalie")):dir()
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local ballPos = CGeoPoint:new_local(ball.rawPos():x(), ball.rawPos():y())
	local basePos = param.ourGoalPos
	local targetPos = ballPos
	if mode == 0 then
		basePos = param.ourTopGoalPos
	elseif mode == 1 then
		basePos = param.ourButtomGoalPos
	elseif mode == 2 then
		basePos = param.ourGoalPos
	end
	if flag == 0 then
		targetPos = ballPos
	elseif flag == 1 then
		targetPos = enemyPos
	end
	local baseDir = (targetPos - basePos):dir()
	-- use the math formula to calc the run pos
	local distX = basePos:x() - param.ourGoalPos:x()
	local distY = basePos:y() - param.ourGoalPos:y()
	local dist = math.sqrt(distX*distX + distY*distY)
	local angle = math.atan2(distY, distX)
	local dist = dist * math.cos(baseDir - angle) - param.defenderRadius
	-- debugEngine:gui_debug_msg(CGeoPoint(2000, 2000+(150*mode)), role.."  mode:"..mode)
	-- debugEngine:gui_debug_arc(param.ourGoalPos, param.defenderRadius, 0, 360)
	local defenderPoint = basePos+Utils.Polar2Vector(-dist, baseDir)
	local idir = player.toPointDir(enemyPos, role)
	local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, defenderPoint) }
	return { mexe, mpos }
end

function defend_front(role)
	getDefenderCount()
	local enemyNum = enemy.closestGoal()
	local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
	local enemyToGoalDir = (param.ourGoalPos - enemyPos):dir()
	local defenderPoint = enemyPos + Utils.Polar2Vector(3*param.playerRadius, enemyToGoalDir)
	if isClosestPointDefender(role, defenderPoint) then
		local idir = player.toPointDir(enemyPos, role)
		local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, defenderPoint) }
		return { mexe, mpos }
	else
		local tTable = defend_norm(role, 2)
		return tTable
	end
end

function defend_kick(role)
	getDefenderCount()
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local defenderPoint = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 2)
	local targetPos = ball.rawPos() --改了可能会出bug
	if isClosestPointDefender(role, defenderPoint) then
		local Kp = 1
		local idir = function(runner)
			return (targetPos - player.pos(runner)):dir()
		end
		debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), player.dir(role))
		local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, defenderPoint) }
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), math.abs(player.dir(role)))
		
		if math.abs(player.dir(role)) > math.pi/2 then
			return { mexe, mpos, param.defenderShootMode, idir, pre.low, kp.specified(0), kp.specified(0), 0x00000000 }
		end
		return { mexe, mpos, param.defenderShootMode, idir, pre.low, power(targetPos, Kp), power(targetPos, Kp), 0x00000000 }
	else
		local tTable = defend_norm(role, 2)
		return tTable
	end

end

-- 守门员skill
-- 当球进禁区时要踢到的目标点
-- mode 防守模式选择, 0在球射向球门时选择防守线(x=-param.pitchLength/2-param.playerRadius)上的点, 1在球射向球门使用bestinterpos的点
function goalie(role, target, mode)
	return function()
		if mode==nil then
			mode = 1
		end
		local goalRadius = param.penaltyRadius/2
		local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
		local goalieRadius = goalRadius-100
		
		local ballPos = ball.rawPos()
		local ballVelDir = ball.velDir()
		local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ballVelDir))
		local enemyNum = getManMarkEnemy()
		local enemyDir = enemy.dir(enemyNum)
		local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
		local enemyDirLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
		
		local goalToEnemyDir = (enemyPos - param.ourGoalPos):dir()
		local goalToEnemyLine = CGeoSegment(param.ourGoalPos, enemyPos)
		local goalLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2, -param.INF), CGeoPoint:new_local(-param.pitchLength/2, param.INF))
		local goalieMoveLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, -param.INF), CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, param.INF))
		local tPos = goalLine:segmentsIntersectPoint(ballLine)
		-- 判断是否踢向球门
		local isShooting = -param.penaltyRadius-100<tPos:y() and tPos:y()<param.penaltyRadius+100
		local getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		if flag == 0 then
			getBallPos = goalieMoveLine:segmentsIntersectPoint(ballLine)
		elseif flag == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		end

		if ball.velMod() < 1000 and flag == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		end
		-- debugEngine:gui_debug_x(getBallPos, param.WHITE)

		-- if (isShooting or ball.velMod() < 1000) and Utils.InExclusionZone(getBallPos) then
		if isShooting and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
			-- 当敌方射门的时候或球滚到禁区内停止时
			local kp = 1
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
			local idir = function(runner)
				return (ballPos - player.pos(runner)):dir()
			end
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, goaliePoint) }
			-- return { mexe, mpos, kick.chip, idir, pre.low, power(ballPos, kp), power(ballPos, kp), 0x00000000 }
			return { mexe, mpos, kick.flat, idir, pre.low, power(ballPos, kp), power(ballPos, kp), 0x00000000 }
		elseif ball.velMod() < 1000 and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
			-- 球滚到禁区内停止
			local kp = 1
			-- 守门员需要踢向哪个点
			local targetPos = CGeoPoint(0, 0)

			local idir = function(runner)
				return (targetPos - player.pos(runner)):dir()
			end

			local roleToBallTargetDir = math.abs((ballPos - rolePos):dir())
			local ballToTargetDir = math.abs((targetPos - ballPos):dir())	
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y()) + Utils.Polar2Vector(-param.playerRadius+10, ballToTargetDir)
			local Subdir = math.abs(ballToTargetDir-roleToBallTargetDir)
			local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
			if Subdir > 0.14 then 
				local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
				iflag =  DSS_FLAG
			else
				iflag = bit:_or(flag.allow_dss,flag.dribbling) 
			end

			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
			-- return { mexe, mpos, kick.chip, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
			return { mexe, mpos, kick.flat, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
		else
			-- 准备状态
			-- 这里是当球没有朝球门飞过来的时候，需要提前到达的跑位点
			local roleToEnemyDist = (enemyPos-rolePos):mod()
			local goaliePoint = param.ourGoalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			-- local goaliePoint = param.ourGoalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			if flag==0 then
				goaliePoint = goalieMoveLine:segmentsIntersectPoint(goalToEnemyLine)
			elseif flag==1 then
				goaliePoint = param.ourGoalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			end
			if roleToEnemyDist<param.goalieAimDirRadius then
				-- 近处需要考虑敌人朝向的问题
				local enemyAimLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
				local tPos = goalLine:segmentsIntersectPoint(enemyAimLine)
				-- 判断是否朝向球门
				local isToGoal = -param.penaltySegment-500<tPos:y() and tPos:y()<param.penaltySegment+500

				if isToGoal then
					local tP = tPos+Utils.Polar2Vector(-goalieRadius, enemyDir)
					if flag==0 then
						tP = goalieMoveLine:segmentsIntersectPoint(enemyDirLine)
					elseif flag==1 then
						tP = tPos+Utils.Polar2Vector(-goalieRadius, enemyDir)
					end
					-- goaliePoint = tP
					-- goaliePoint = CGeoPoint:new_local((tP:x()+goaliePoint:x())/2, (tP:y()+goaliePoint:y())/2)
					goaliePoint = tP
				end
			debugEngine:gui_debug_x(goaliePoint, param.WHITE)
			end
			local idir = player.toPointDir(enemyPos, role)
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos }
		end
	end
end



--[[ 盯防 ]]
markingTable = {}
markingTableLen = 0


function defender_marking(role,pos)
	local enemyDribblingNum = GlobalMessage.Tick.their.dribbling_num
	local p

	markingTable = {}
	markingTableLen = 0
	if type(pos) == "function" then
		p = pos()
	else
		p = pos 
	end
	local idir = player.toBallDir(role)
		-- 初始化 获取需要盯防的对象 <= 2
	-- if markingTableLen == 0 and ball.rawPos():x() > param.markingThreshold then 
		for i=0,param.maxPlayer-1 do
			if enemy.valid(i) and i ~= enemyDribblingNum and enemy.posX(i) < param.markingThreshold then
				markingTable[markingTableLen] = i
				markingTableLen = markingTableLen + 1
				if markingTableLen > 1 then
					break
				end
			end
		end
	-- end
	-- 如果 敌人在前场 ,我方正常跑位
	if markingTableLen == 0 or (markingTableLen == 1 and role == "Special" )  then 
		local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }
		return { mexe, mpos }
	else

		if (role == "Kicker") then
			minDistEnemyNum = markingTable[0]
		elseif markingTableLen > 1 then 
			minDistEnemyNum = markingTable[1]
		end
		local ballToEnemyDist = (enemy.pos(minDistEnemyNum) - ball.rawPos()):mod()
		local ballToEnemyDir = (enemy.pos(minDistEnemyNum) - ball.rawPos()):dir()
		if(markingTableLen ~= 0) then
			local dirFlag = enemy.pos(minDistEnemyNum):y() < 0 and 1 or -1
			local markingPos = enemy.pos(minDistEnemyNum) + 
			Utils.Polar2Vector(ballToEnemyDist*param.markingPosRate1, ballToEnemyDir + dirFlag * math.pi / 2 ) + 
			Utils.Polar2Vector(-param.minMarkingDist-ballToEnemyDist*param.markingPosRate2, ballToEnemyDir)
			debugEngine:gui_debug_x(markingPos)
			if(not Utils.InField(markingPos)) then
				markingPos = CGeoPoint (player.posX(role),player.posY(role))
			end

			local mexe, mpos = GoCmuRush { pos = markingPos, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }
			return { mexe, mpos }
		end

	end
end

function Dfenending( role )
	local ballPos = CGeoPoint(ball.posX(),ball.posY())
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end
	-- 球在后场
	if( ballPos:x() < 0) then



	-- 球在前场
	else

	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
	return { mexe, mpos }
end
----------------------------------------- 其他动作 --------------------------------------------

-- p为朝向，如果p传的是pos的话，不需要根据ball.antiY()进行反算
function goBackBall(p, d)
	local mexe, mpos = GoCmuRush { pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = flag.dodge_ball }
	return { mexe, mpos }
end

-- 带避车和避球
function goBackBallV2(p, d)
	local mexe, mpos = GoCmuRush { pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = bit:_or(flag.allow_dss, flag.dodge_ball) }
	return { mexe, mpos }
end

function stop()
	local mexe, mpos = Stop {}
	return { mexe, mpos }
end

function continue()
	return { ["name"] = "continue" }
end

------------------------------------ 测试相关的skill ---------------------------------------

function openSpeed(vx, vy, vw, iflag)
	local mexe, mpos = OpenSpeed { speedX = vx, speedY = vy, speedW = vw, flag = iflag }
	return { mexe, mpos }
end

function getInitData(role, p)
	return function()
		debugEngine:gui_debug_msg(p, "targetIsHere")
		if player.pos(role):dist(p) < 10 and player.velMod(role) < 11 then
			p = CGeoPoint:new_local(math.random(-3200, 3200), math.random(-2500, 2500))
		end
		idir = player.toPointDir(p, role)
		local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }

		return { mexe, mpos }
	end
end

kickPower = {}
minPower = 1000
maxPower = 6000
powerStep = 100
playerCount = 0
fitPlayerLen = 0
fitPlayerList = {}
fitPlayer1 = -1
fitPlayer2 = -1

-- isFitfinshed = false
function fitPower(i)
	return function()
		return kickPower[i]
	end
end

function getFitData_runToPos(role)
	return function()
		-- 当前角色
		local playerNum = player.num(role)
		fitPlayerLen = 0
		fitPlayerList = {}
		local i = 0
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 2800-(200*playerNum)),string.format("%s playerNum:            %d", role, playerNum))
		for i=0,param.maxPlayer-1 do
			-- debugEngine:gui_debug_msg(CGeoPoint(-4500, 2800-(200*i)),"kickPower: "..tostring(kickPower[i]).."  "..tostring(i))
			if kickPower[i] < 0 or kickPower[i] > maxPower then
				-- continue
			else
				fitPlayerList[fitPlayerLen] = i
				fitPlayerLen = fitPlayerLen + 1
			end
		end
		-- debugEngine:gui_debug_msg(CGeoPoint(100, 100), tostring(fitPlayerList[0]))
		-- 角色选择器
		if fitPlayerLen > 1 then
			fitPlayer1 = fitPlayerList[0]
			fitPlayer2 = fitPlayerList[1] 
		elseif playerCount >= 1 then
			fitPlayer1 = fitPlayerList[0]
			for i=0,param.maxPlayer-1 do
				if kickPower[i] < 0 then
					-- continue
				else
					fitPlayer2 = i
					break
				end
			end
		-- elseif fitPlayerLen == 0 then
		-- 	-- debugEngine:gui_debug_msg(CGeoPoint(-3000, -3000), "车不够多") 
		-- 	isFitfinshed = true
		end
    	
    	if playerNum == fitPlayer1 or playerNum == fitPlayer2 then
    		-- 跑去接踢位

    		-- 标记踢球人 1 - 踢球		-1 - 接球
    		local flag = playerNum == fitPlayer1 and 1 or -1
    		-- 拿球点
    		-- p0 = CGeoPoint:new_local(ball.posX(), ball.posY())
    		local rolePos = CGeoPoint:new_local(player.posX(fitPlayer1), player.posY(fitPlayer1))
    		local p0 = Utils.GetBestInterPos(vision, rolePos, 3, 1)
	    	-- 踢球车的准备点
	    	local p1 = CGeoPoint:new_local(flag*param.FIT_PLAYER_POS_X, flag*param.FIT_PLAYER_POS_Y)

    		if player.myinfraredCount(role) < 10 and flag == 1 then
    			-- 踢球人如果没有拿到球，就去拿球
	    		local idir = player.toPointDir(p0, role)
				local mexe, mpos = GoCmuRush { pos = p0, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif player.toPointDist(role, p1) > param.playerRadius or ball.velMod() > 20  then
				-- ::TODO there has some bugs
				-- 非踢球人去固定点
	    		local idir = (player.pos(fitPlayer2)- player.pos(role)):dir()
	    		if playerNum == fitPlayer2 then
		    		idir = (player.pos(fitPlayer1)- player.pos(role)):dir()
	    		end
				local mexe, mpos = GoCmuRush { pos = p1, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif flag == 1 then
				-- 踢球
				-- kickPower[fitPlayer1] = kickPower[fitPlayer1] + powerStep
				local ipos = CGeoPoint:new_local(0, 0)
				local idir = function(runner)
					return (_c(ipos) - player.pos(runner)):dir()
				end
				local mexe, mpos = Touch { pos = ipos, useInter = ifInter }
				local ipower = function()
					return kickPower[fitPlayer1]
				end
				return { mexe, mpos, kick.flat, idir, pre.low, ipower, ipower, 0x00000000 }
    		end
		else
    		-- 跑去待机位
    		local p = CGeoPoint(param.pitchWidth/2-param.playerRadius*3*playerNum, param.pitchLength/2-1500)
    		local idir = 0
			local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
			return { mexe, mpos }
    	end
	end
end

function getFitData_recording(role)
	return function()
		-- 当前角色
		local playerNum = player.num(role)

		if playerNum == fitPlayer2 then
			local rolePos = CGeoPoint:new_local(player.posX(role), player.posY(role))
			local getBallPos = Utils.GetBestInterPos(vision, rolePos, 3, 1)
			if getBallPos:x() < 0 or getBallPos:y() < 0 then
				-- 踢球
				local p = player.pos(fitPlayer1)
				local kp = 1
				local ipos = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
				local idir = function(runner)
					return (player.pos(fitPlayer1) - player.pos(runner)):dir()
				end
				local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }


				return { mexe, mpos, kick.flat, idir, pre.low, power(p, kp), power(p, kp), 0x00000000 }
			end

		elseif playerNum ~= fitPlayer1 then
			-- 跑去待机位
    		local p = CGeoPoint(param.pitchWidth/2-param.playerRadius*3*playerNum, param.pitchLength/2-1500)
    		local idir = 0
			local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
			return { mexe, mpos }
		end

	end
end

function canPass(startPos,endPos,buffer)
	----------------------------------
	---返回两点之间是否可以传球
	-- startPos: 开始坐标
	-- endPos  : 结束坐标
	-- buffer  : 敌人半径
	GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
	local start = CGeoPoint(startPos:x(),startPos:y())
	local end_ = CGeoPoint(endPos:x(),endPos:y())
	return Utils.isValidPass(vision,start,end_,buffer)
end