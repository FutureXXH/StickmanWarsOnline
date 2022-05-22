
print("[Lua]: lua文件打开成功!")

ID = -1
--使用这种来使重载时保留原值
i = i or 0

--ServerLuaLib.RegMessage(消息ID,模块ID)
--关闭模块
--ServerLuaLib.CloseModule(模块ID);
--加载模块
--ServerLuaLib.LoadNewModule(模块ID,模块文件名)
--发送消息
--ServerLuaLib.SendMessage(消息ID,数据,发送源模块ID,目标模块ID);目标模块ID填-1则发送给所有注册该消息的模块
--获取时间戳
--ServerLuaLib.GetTime();
--输出日志
--ServerLuaLib.Log(级别,消息)  (INFO,WARNING,ERROR);

CurPlayerCount = 0
MaxPlayer = 2
CMDS = {};


--游戏地图数据
CurMapID = 1;
Maps = {}
Maps[1] = {  LB = 0 , RB = 20}

function GetRoomPlayer(setID,setx,setz,setHP,setPower)
    local player = {
        ID = setID,
        posx = setx,
        posz = setz,
        state = 0,
        dir = 0,
        speed = 4,
        len = 4,
        MaxHP = 100,
        MaxPower = 100,
        HP = setHP,
        Power = setPower

    }
  return player;
   
end


BlockList = {};

RoomPlayerList = RoomPlayerList or {};

RoomPlayerIndex = {}




local ball = {
    dir = math.pi/4,
    speed = 4,
    posx = 1,
    posz = 2
}
local mapinfo = {
    xlen = 10,
    zlen = 20
}


local LastCollisiontime = ServerLuaLib.GetTime()/1000;
local curtime = ServerLuaLib.GetTime()/1000;
local lasttime = ServerLuaLib.GetTime()/1000;
local dtime = curtime-lasttime;
local GameState = "WAIT";

local GameRootType = 1;

function GameRunTime()
    

  if GameState == "WAIT" then
    SendCurGameState(0)
    if(CurPlayerCount >= MaxPlayer) then
        GameState = "Ready"
    end
    SendPlayerCount();

  elseif GameState ==  "Ready" then
    SendCurGameState(1)
    ReadyGame()
    SendPlayerData()
   
  elseif GameState ==  "Runing" then
    SendCurGameState(2)
    UpdatePlayerData()
    PlayerMove()
    SendPlayerData()

   elseif GameState ==  "End" then
    GameOver()
    SendCurGameState(3)

    elseif GameState ==  "EXIT" then
    SendCurGameState(4)
   end

   RoomCheck()
  
end



--在模块加载后调用 传入了模块ID号
function OnInit(id)
    ID = id
    ServerLuaLib.Log("INFO","[Lua]: GameRoom初始化成功  ID: "..ID)
    ServerLuaLib.RegMessage(5000,ID);
    ServerLuaLib.RegMessage(5001,ID);
    ServerLuaLib.RegMessage(5002,ID);
    ServerLuaLib.RegMessage(5003,ID);
    ServerLuaLib.RegMessage(5004,ID);
    ServerLuaLib.RegMessage(5005,ID);
    CMDS[5000] = GameRoomInitData_CMD;
    CMDS[5001] = JoinPlaye1_CMD;
    CMDS[5002] = ExitPlayer_CMD;
    CMDS[5003] = PlayerUpdateState_CMD;
    CMDS[5004] = PlayerAction_CMD;
    CMDS[5005] = Attack_CMD;
    


    GetRoomType();
end

--一直调用
function OnUpdate()
  curtime = ServerLuaLib.GetTime()/1000;
  dtime = curtime-lasttime;
  if dtime > 0.05 then
    GameRunTime();
    lasttime = curtime;
  end
  
end

--在有消息达到时调用
function OnParseMessage(MessageID,data,srcModuleID)
   
    if CMDS[MessageID] ~= nil then
        CMDS[MessageID](data);
       end
end

--模块删除时调用
function OnExit()
    print("[Lua]: 模块: "..ID.. "退出")
end

function SendCurGameState(state)
    for k,v in pairs(RoomPlayerList) do
        local data = string.pack("i4i4i4i4",v.ID,503,4,state);
        ServerLuaLib.SendMessage(10004,data,ID,-1);
    end
end

function SendPlayerCount()

    for k,v in pairs(RoomPlayerList) do
        local data = string.pack("i4i4i4i4i4",v.ID,502,8,CurPlayerCount,MaxPlayer);
        ServerLuaLib.SendMessage(10004,data,ID,-1);
    end
end



function SendPlayerData()
    for k,v in pairs(RoomPlayerList) do
        for k2,v2 in pairs(RoomPlayerList) do
            local data = string.pack("i4i4i4i4i4i4i4i4i4i4i4",v.ID,504,32,v2.ID,math.floor(v2.posx*100),math.floor(v2.speed*100),math.floor(v2.dir*100),v2.HP,v2.Power,v2.MaxHP,v2.MaxPower);
            ServerLuaLib.SendMessage(10004,data,ID,-1);
        end
    end
end

function GetRoomType()
    senddata = "";
    ServerLuaLib.SendMessage(2007,senddata,ID,-1);
end

local ReadyTime = 10;
function ReadyGame()
    ReadyTime = ReadyTime-dtime;
    for k,v in pairs(RoomPlayerList) do
        local data = string.pack("i4i4i4i4",v.ID,507,4,math.floor(ReadyTime*100));
        ServerLuaLib.SendMessage(10004,data,ID,-1);
    end
    if(ReadyTime <= 0) then
        GameState = "Runing"
    end

end   

function GameRoomInitData_CMD(data)
    GameRootType =  string.unpack("i4",data);
 
    
end


function JoinPlaye1_CMD(data)
    PlayerID = string.unpack("i4",data);
    if(RoomPlayerList[PlayerID] ~= nil) then
        ServerLuaLib.Log("WARNING","玩家"..PlayerID.."已经在房间里了")
        return -1;
    end


    for i = 1,MaxPlayer do
        if(RoomPlayerIndex[i] == nil) then
            RoomPlayerIndex[i] = PlayerID;
            break;
        end
    end

    if(RoomPlayerIndex[1] == PlayerID) then
    RoomPlayerList[PlayerID] = GetRoomPlayer(PlayerID,1,0,100,0);
    elseif(RoomPlayerIndex[2] == PlayerID) then
    RoomPlayerList[PlayerID] = GetRoomPlayer(PlayerID,5,0,100,0);
     end
    CurPlayerCount = CurPlayerCount+1;
    
end

function ExitPlayer_CMD(data)

    PlayerID = string.unpack("i4",data);
    if(RoomPlayerList[PlayerID] ~= nil) then
        RoomPlayerList[PlayerID] = nil;
        CurPlayerCount = CurPlayerCount-1;
    end

    if(GameState == "Runing") then
        GameState = "End";
    end


end

Checktime = 0
function RoomCheck()

    Checktime = Checktime+dtime;
    if(Checktime > 5 and CurPlayerCount == 0)then
    
          senddata = string.pack("i4",ID);
          ServerLuaLib.SendMessage(2005,senddata,ID,-1);
     end
end

function PlayerUpdateState_CMD(data)
    PlayerID,State,Dir = string.unpack("i4i4i4",data,5);
    --print(PlayerID.." "..State.." "..Dir .. " ".. Speed)
    if(RoomPlayerList[PlayerID] ~= nil) then
         if(math.abs(Dir) > 100) then return end;
        RoomPlayerList[PlayerID].state = State;
        RoomPlayerList[PlayerID].dir = Dir/100;
    end
end

function PlayerMove()
  for k,v in pairs(RoomPlayerList) do
    if(v.state == 1)then
    v.posx = math.max(math.min(v.posx+ v.dir*v.speed*dtime,Maps[CurMapID].RB),Maps[CurMapID].LB);
    --v.posx = v.posx + v.dir*v.speed*dtime;
    --v.posz = math.max(math.min(v.posz+ math.sin(v.dir)*v.speed*dtime,20),0);
    end
  end
end

function PlayerAction_CMD(data)
    PlayerID,CMD = string.unpack("i4i4",data,5);
    if(RoomPlayerList[PlayerID] == nil)then return end;

    if(CMD == 1 )then
        PlayerAction(PlayerID,CMD,3)
    elseif(CMD == 2 )then
             PlayerAction(PlayerID,CMD,5)
    elseif(CMD == 101)then
             PlayerAction(PlayerID,CMD,10)
     elseif(CMD == 102)then
            PlayerAction(PlayerID,CMD,10)
    elseif(CMD == 103)then
            PlayerAction(PlayerID,CMD,30)
     end
  
end

function PlayerAction(PlayerID,CMD,costPower)
    if RoomPlayerList[PlayerID].Power >= costPower then
    RoomPlayerList[PlayerID].Power = RoomPlayerList[PlayerID].Power-costPower;
    for k,v in pairs(RoomPlayerList) do
        local data = string.pack("i4i4i4i4i4i4",v.ID,505,12,PlayerID,CMD,math.floor(RoomPlayerList[PlayerID].posx*100));
        ServerLuaLib.SendMessage(10004,data,ID,-1);
    end
    end
end

local updatePowerTime = 0;
function UpdatePlayerData()
    updatePowerTime = updatePowerTime+dtime;
    --更新能量值
    if (updatePowerTime > 1) then
        for k,v in pairs(RoomPlayerList) do
          v.Power = math.min(v.Power+2,v.MaxPower)
        end
        updatePowerTime = 0;
    end
    --检测玩家HP
    for k,v in pairs(RoomPlayerList) do
       if(v.HP <= 0) then
        GameState = "End"
       end
      end
    


end


function Attack_CMD(data)
  PlayerID,AttackID,AimPlayerID = string.unpack("i4i4i4",data,5);
  if(RoomPlayerList[PlayerID] == nil or RoomPlayerList[AimPlayerID] == nil)then return end;

  if(AttackID == 1)then
    RoomPlayerList[AimPlayerID].HP = RoomPlayerList[AimPlayerID].HP-2;
  elseif (AttackID == 2) then
   RoomPlayerList[AimPlayerID].HP = RoomPlayerList[AimPlayerID].HP-15;
  end
  


end

winID = -1
function  GameOver()
    if(winID == -1) then
      for k,v in pairs(RoomPlayerList) do
       if(v.HP > 0) then
        winID = v.ID;
        break;
       end
      end
      PlayerReward();
    end
     

      for k,v in pairs(RoomPlayerList) do
        local data = string.pack("i4i4i4i4",v.ID,506,4,winID);
        ServerLuaLib.SendMessage(10004,data,ID,-1);
      end
end

function PlayerReward()
    for k,v in pairs(RoomPlayerList) do
        if(GameRootType == 1) then
            if(v.ID ~= winID)then
                local data = string.pack("i4i4i4",v.ID,50,0);
                ServerLuaLib.SendMessage(4011,data,ID,-1);
            else
                local data = string.pack("i4i4i4",v.ID,50+v.HP,0);
                ServerLuaLib.SendMessage(4011,data,ID,-1);
            end
        else
            if(v.ID ~= winID)then
                local data = string.pack("i4i4i4",v.ID,50,-10);
                ServerLuaLib.SendMessage(4011,data,ID,-1);
            else
                local data = string.pack("i4i4i4",v.ID,50+v.HP,10+math.floor(v.HP/10));
                ServerLuaLib.SendMessage(4011,data,ID,-1);
            end      

        end
       end
end
