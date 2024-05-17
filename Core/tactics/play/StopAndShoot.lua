local ballpos = function ()
    return CGeoPoint:new_local(ball.posX(),ball.posY())
end
local balldir = function ()
    return function()
        return player.toBallDir("Assister")
    end
end

local runPos = function()
    return function()
        return CGeoPoint:new_local(run_pos:x(),run_pos:y())
    end
end

local shootPosFun = function()
    if type(param.shootPos) == "function" then
        return param.shootPos()
    else
        return param.shootPos
    end
end


local shoot_kp = param.shootKp
local resShootPos = CGeoPoint(4500,0)
local shootKPFun = function()
    return function()
        return shoot_kp
    end
end
local debugMesg = function ()
    if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
        debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),1)
    else
        debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),4)
    end
        debugEngine:gui_debug_x(resShootPos,6)
        debugEngine:gui_debug_msg(resShootPos,"rotCompensatePos",6)

end
-- 初始坐标
-- local firstPos = {
--     CGeoPoint(1500,0),
--     CGeoPoint(-750,1299),
--     CGeoPoint(-750,-1299)
-- }
local firstPos = {
    CGeoPoint(1500,0),
    CGeoPoint(-750,1299),
    CGeoPoint(-750,-1299),
    
}

-- 某角色指向球的方向
local toBallDir = function(role)
    return function()
        return player.toBallDir(role)
    end
end

-- 某角色拿球的坐标
local toballPos = function(role)
    return function()
        return ball.pos() + Utils.Polar2Vector(-105,(ball.pos() - player.pos(role)):dir())
    end
end

-- 改变所有角色的匹配 ：
-- 原理： 改变 firstPos 的顺序然后利用角色匹配规则实现
local function changeMatchAll()
    local firstElement = table.remove(firstPos, 1)
    table.insert(firstPos, firstElement)
end
-- 改变接球角色的匹配
local function changeMatchGetball()
    local secondElement = table.remove(firstPos, 2)
    table.insert(firstPos, secondElement)
end


gPlayTable.CreatePlay{
firstState = "Init1",
["Init1"] = {
    switch = function()
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800),ball.velMod(),4)
        if player.toTargetDist('Assister') < 600 and player.toTargetDist('Kicker') < 600 and player.toTargetDist('Leader') < 600 then
            return "Init"
        end
    end,
    Assister = task.goCmuRush(function() return firstPos[1] end, toBallDir("Assister")),
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "[AKL]"
},

--- 初始状态，根据firstPos决定匹配结果
["Init"] = {
    switch = function()
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800),ball.velMod(),4)
        return "goFirstPos"
    end,
    Assister = task.goCmuRush(function() return firstPos[1] end, toBallDir("Assister")),
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "[AKL]"
},

-- 如果所有机器人都离自己的目标点很近就可以跳到拿球
["goFirstPos"] = {
    switch = function()
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800), ball.velMod(),4)
        -- if player.toTargetDist('Assister') < 600 and player.toTargetDist('Kicker') < 600 and player.toTargetDist('Leader') < 600 then
            return "getball"
        -- end
    end,
    Assister = task.goCmuRush(function() return firstPos[1] end, toBallDir("Assister")),
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "{AKL}"
},


-- 拿到球然后指向目标点
["getball"] = {
    switch = function()
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)

        
        --
        if player.myinfraredCount("Assister") > param.Icount then
            return "turned"
        end
        -- 如果不能传球（传球路径有敌人，那么换一个机器人传球）
        debugEngine:gui_debug_msg(CGeoPoint(0,200),"canpass:".. tostring(task.canPass(player.pos("Assister"),player.pos("Kicker"),param.enemy_buffer)))
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800),ball.velMod(),4)
        --[[if(not task.canPass(player.pos("Assister"),player.pos("Kicker"),param.enemy_buffer)) then
            -- 改变表顺序
            changeMatchGetball()
            return "Init"
        end--]]
    end,
    Assister = task.getBall2024("Assister",function() return player.pos("Kicker")end),
   
    -- Assister = task.getball(function() return firstPos[1] end,param.playerVel,param.getballMode),
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "{AKL}"
},

["turned"] ={
    switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)
        debugEngine:gui_debug_msg(CGeoPoint(0,200),"canpass:".. tostring(task.canPass(player.pos("Assister"),player.pos("Kicker"),param.enemy_buffer)))
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800), ball.velMod(),4)
       
     
        if player.myinfraredCount("Assister") > 150  then         
            return "Stop"
        end

        if player.myinfraredCount("Assister") < param.Icount then
            return "getball"
        end

        debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
        debugMesg()
        if shootPosFun():x() == param.pitchLength / 2 then
            shoot_kp = 10000
        else
            shoot_kp = param.shootKp
        end
    
        local c=1
        if (not task.canPass(player.pos("Assister"),player.pos("Kicker"),param.enemy_buffer) )then
            -- 改变表顺序
            
            changeMatchGetball()
            return "Init"

        end
        

        local playerpos1=player.pos("Assister")
        local pos2=player.pos("Kicker")
        
        local enemyNum=0 
        for i=0,param.maxPlayer do    
            if enemy.valid(i) then
            enemyNum=i
            end
        end
        local enemypos=enemy.pos(enemyNum)
        local passLine = CGeoSegment(playerpos1, pos2)
        local projectionPos = passLine:projection(enemypos)
        local enemyTOPasslineDist = (enemypos - projectionPos):mod()
          
        local Mordis=700 -  enemyTOPasslineDist
        
        if  Mordis > 100 then
            Mordis=100
        end
        if Mordis < 0 then 
            Mordis = 0
        
        end

        local ToNextDir = (player.pos("Kicker")-player.pos("Assister")):dir()
        local ToEnemyDir =(enemypos-player.pos("Assister")):dir()
        
        local comangleDir=task.compensateDir(ToNextDir,ToEnemyDir)
        
        local resPassPos = pos2 + Utils.Polar2Vector(Mordis,(ball.pos() - pos2):dir() +  comangleDir*math.pi / 2)
      --[[  debugEngine:gui_debug_msg(resPassPos,ResPassPos,4)--]]
        debugEngine:gui_debug_msg(CGeoPoint(0,1000),enemyNum,4)
        debugEngine:gui_debug_msg(CGeoPoint(-1500,0),comangleDir,4)
        debugEngine:gui_debug_line(playerpos1, pos2,3)
        debugEngine:gui_debug_x(resPassPos,4)
        debugEngine:gui_debug_x(resPassPos,4)
        debugEngine:gui_debug_msg(resPassPos,"resPassPos",4)
        debugEngine:gui_debug_msg(CGeoPoint(0,800),player.myinfraredCount("Assister"),6)
        

        local Vy = player.rotVel("Assister")
        local ToTargetDist = player.toPointDist("Assister",function() return resPassPos end)
        resShootPos = task.compensateAngle("Assister",Vy,function() return resPassPos end,ToTargetDist * param.rotCompensate)
        debugEngine:gui_debug_msg(CGeoPoint(0,-3000),shoot_kp)
        if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
            return "shoot"
        end
        
    end,
    Assister = function() return task.TurnToPointV2("Assister", function() return resShootPos end,param.rotVel) end,
    
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "{AKL}"
},

["Stop"] = {
    switch = function ()
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800),ball.velMod(),4)
        --虚拟直线计算拦截机器人是否到达
        
        local enemyNum=0 
        for i=0,param.maxPlayer do    
            if enemy.valid(i) then
            enemyNum=i
            end
        end


        local playerpos1=player.pos("Assister")
        local pos2=player.pos("Kicker")
        local enemypos=enemy.pos(enemyNum)
        local passLine = CGeoSegment(playerpos1, pos2)
        local projectionPos = passLine:projection(enemypos)
        local enemyTOPasslineDist = (enemypos - projectionPos):mod()

        if (enemyTOPasslineDist <= 50 and player.myinfraredCount("Assister") > 50) or bufcnt(true,30) then
            changeMatchGetball()
            return "turned1"
        
        end


    end,
        





    Assister = task.getBall2024("Assister",function() return player.pos("Kicker")end),
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "{AKL}"

},


["turned1"] ={
    switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,1)
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,1)
        debugEngine:gui_debug_msg(CGeoPoint(0,200),"canpass:".. tostring(task.canPass(player.pos("Assister"),player.pos("Kicker"),param.enemy_buffer)))

       
     
        

        if player.myinfraredCount("Assister") < 4 then
            return "Init"
        end

        debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
        debugMesg()
        if shootPosFun():x() == param.pitchLength / 2 then
            shoot_kp = 10000
        else
            shoot_kp = param.shootKp
        end
    
        local c=1
        --[[if (not task.canPass(player.pos("Assister"),player.pos("Kicker"),param.enemy_buffer) )then
            -- 改变表顺序--]]
            
        
           
        
    

        local playerpos1=player.pos("Assister")
        local pos2=player.pos("Leader")
        
        local enemyNum=0 
        for i=0,param.maxPlayer do    
            if enemy.valid(i) then
            enemyNum=i
            end
        end
        local enemypos=enemy.pos(enemyNum)
        local passLine = CGeoSegment(playerpos1, pos2)
        local projectionPos = passLine:projection(enemypos)
        local enemyTOPasslineDist = (enemypos - projectionPos):mod()
          
        local Mordis=700 -  enemyTOPasslineDist
        
        if  Mordis > 100 then
            Mordis=100
        end
        if Mordis < 0 then 
            Mordis = 0
        
        end

        
        local ToNextDir = (player.pos("Kicker")-player.pos("Assister")):dir()
        local ToEnemyDir =(enemypos-player.pos("Assister")):dir()
        
        local comangleDir=task.compensateDir(ToNextDir,ToEnemyDir)
        
        local resPassPos = pos2 + Utils.Polar2Vector(Mordis,(ball.pos() - pos2):dir() +  comangleDir*math.pi / 2)


      --[[  debugEngine:gui_debug_msg(resPassPos,ResPassPos,4)--]]
        debugEngine:gui_debug_msg(CGeoPoint(0,1000),enemyNum,4)

        debugEngine:gui_debug_line(playerpos1, pos2,3)
        debugEngine:gui_debug_x(resPassPos,4)
        debugEngine:gui_debug_x(resPassPos,4)
        debugEngine:gui_debug_msg(resPassPos,"resPassPos",4)
        debugEngine:gui_debug_msg(CGeoPoint(-800,-800),ball.velMod(),4)
        



        local Vy = player.rotVel("Assister")
        local ToTargetDist = player.toPointDist("Assister",function() return resPassPos end)
        resShootPos = task.compensateAngle("Assister",Vy,function() return resPassPos end,ToTargetDist * param.rotCompensate)
        debugEngine:gui_debug_msg(CGeoPoint(0,-3000),shoot_kp)
        if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
            return "shoot"
        end
        



    end,
    Assister = function() return task.TurnToPointV2("Assister", function() return resShootPos end,param.rotVel) end,
    
    Kicker = task.goCmuRush(function() return firstPos[3] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[2] end,toBallDir("Leader")),
    match = "{AKL}"
},


["shoot"] = {
    switch = function()
        debugEngine:gui_debug_arc(firstPos[1],600,0,360,4)
        debugEngine:gui_debug_arc(firstPos[2],600,0,360,4) 
        debugEngine:gui_debug_arc(firstPos[3],600,0,360,4)
        debugEngine:gui_debug_msg(CGeoPoint(0,800),player.myinfraredCount("Assister"),6)
        if player.kickBall("Assister")  --[[and player.myinfraredCount("Assister")<=0--]] then
            debugEngine:gui_debug_msg(CGeoPoint(0,0),firstPos[1]:x().."   ".. firstPos[1]:y())
            debugEngine:gui_debug_msg(CGeoPoint(0,100),firstPos[2]:x().."   ".. firstPos[2]:y())
            debugEngine:gui_debug_msg(CGeoPoint(0,200),firstPos[3]:x().."   ".. firstPos[3]:y())
            debugEngine:gui_debug_msg(CGeoPoint(-800,-800),ball.velMod(),4)
            changeMatchAll()
            debugEngine:gui_debug_msg(CGeoPoint(-2000,0),firstPos[1]:x().."   ".. firstPos[1]:y())
            debugEngine:gui_debug_msg(CGeoPoint(-2000,100),firstPos[2]:x().."   ".. firstPos[2]:y())
            debugEngine:gui_debug_msg(CGeoPoint(-2000,200),firstPos[3]:x().."   ".. firstPos[3]:y())
            return "Init"
        end
    end,
    Assister = task.Shootdot( "Assister",function() return resShootPos end, shootKPFun() , param.shootError +15, kick.flat),
    --[[Assister = task.Shootdot("Assister",function() return player.pos("Kicker")end, 1.8, 4, kick.flat),--]]
    Kicker = task.goCmuRush(function() return firstPos[2] end,toBallDir("Kicker")),
    Leader = task.goCmuRush(function() return firstPos[3] end,toBallDir("Leader")),
    match = "{AKL}"
},



name = 'StopAndShoot',
applicable ={
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}