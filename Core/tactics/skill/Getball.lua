function Getball(task)
	local minter_flag = task.inter_flag or 1
	local mpermissions = task.permissions or 0
	local mFirstPos = task.firstPos or CGeoPoint(-param.INF,-param.INF)
	local mpos
	local mdir
	local msender = task.sender or 0
	local mrole   = task.srole or ""
	local macc    = task.acc or 0
	local mrec    = task.rec or 0 --mrec判断是否吸球  gty 2016-6-15
	local mvel
	local mspeed  = task.speed or 0
	local mforce_maunal_set_running_param = task.force_manual or false
	matchPos = function(runner) 
		return _c(ball.pos())
	end
	execute = function(runner)
		if runner >=0 and runner < param.maxPlayer then
			if mrole ~= "" then
				CRegisterRole(runner, mrole)
			end
		else
			print("Error runner in getball", runner)
		end
		local playerPos = CGeoPoint:new_local(player.pos(runner):x(),player.pos(runner):y())
	--[[	local inter_pos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,minter_flag,0,mFirstPos)--]]
		local idir = player.toBallDir(runner)
		local ipos = inter_pos

		local toballDir = math.abs((ball.rawPos() - player.rawPos(runner)):dir() * 57.3)
		local playerDir = math.abs(player.dir(runner)) * 57.3
		local Subdir = math.abs(toballDir-playerDir)
		local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
		-- 吸球嘴和球的方向没对齐的情况
		if Subdir > 30 then 
			local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
			iflag =  DSS_FLAG
		else
			-- iflag = bit:_or(flag.allow_dss,flag.dribbling) 
			iflag = flag.dribbling
		end
		local ballLine = CGeoLine(ball.pos(),ball.velDir())
		local prjFirstPos = ballLine:projection(mFirstPos)
		local prjPosToFirstPosDist = prjFirstPos:dist(mFirstPos)
		debugEngine:gui_debug_msg(prjFirstPos,prjPosToFirstPosDist,9)
		if (prjPosToFirstPosDist > 800) then
			-- 没射准就站在原地
			ipos = player.pos(runner)
		end

		-- if (inter_pos:x() == param.INF) then
		-- 	ipos = player.pos(runner)
		-- end
		-- if (ipos - param.lastInterPos):mod() < 115 then
		-- 	ipos = param.lastInterPos
		-- end 
			local v_ = 0
		local bp =ball.pos()
		local plp =player.pos(runner)
		local Diff = math.abs((bp -plp ):mod())
		local BallVel =ball.velMod()

		--[[if BallVel>1500 then
			v_=450
		else --v_=[0,1500]
			if BallVel>400  and Diff< 600 then
				v_=350
			else -- [0,400] and ([400,1500]and Diff > 600) 
				v_=0
				if BallVel < 200 and Diff < 600 then --[0,200] and Diff < 600
					v_= 50
				else-- [200,400]
					v_=100
				end
			end
		end--]]
		if BallVel > 1500 then           -- [1500,+max]
			v_ = 450
		else                             --[0,1500]
			
			if BallVel > 700 then           --[700,1500]
				v_ = 250
			else                            --[0,700]
				v_ = 0
				if BallVel < 400 then           --[0,400]
					v_ = 150
						
					if BallVel < 200 then         --[0,200]
							v_ = 50
						if Diff < 100 then
							v_ = 0
						else 
							v_ = 50
						end
					else                          --[200,400]
						if Diff < 100 then 
							v_ = 0
						else 
							v_ = 25
						end
					end
				else                             --[400,700]
					v_ = 200
				end
			end
		end 



		local endVel = Utils.Polar2Vector(v_,(ipos - player.pos(runner)):dir())
		mvel = endVel
		param.lastInterPos = ipos
		mvel = _c(endvel) or CVector:new_local(0,0)
		mpos = _c(ipos,runner)
		mdir = _c(idir,runner)
		macc = _c(task.acc) or 0
		mspeed = _c(task.speed) or 0
		if type(task.sender) == "string" then
			msender = player.num(task.sender)
		end
		local debugflag = iflag == flag.dribbling and "Dribbling" or "DSS"
		debugEngine:gui_debug_msg(CGeoPoint(0,-3800),"iflag:  " .. debugflag)
		debugEngine:gui_debug_msg(ipos,"GetballPos",4)
		task_param = TaskT:new_local()
		task_param.executor = runner
		task_param.player.pos = CGeoPoint(mpos)
		task_param.player.angle = mdir
		task_param.ball.Sender = msender or 0
		task_param.player.max_acceleration = macc or 0
		task_param.player.vel = CVector(mvel)
		task_param.player.force_manual_set_running_param = mforce_maunal_set_running_param
		task_param.player.flag = iflag
		return skillapi:run("SmartGoto", task_param)
	end

	return execute, matchPos
end

gSkillTable.CreateSkill{
	name = "Getball",
	execute = function (self)
		print("This is in skill"..self.name)
	end
}
