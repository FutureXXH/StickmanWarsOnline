
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


SkillCost = {};
SkillCost[101] = 100; 
SkillCost[102] = 100; 
SkillCost[103] = 300; 
SkillCost[104] = 100; 

PlayerDataList = PlayerDataList or {};
CMDS = {};
function GetNewPlayerData(setid)
    local Player = {
        ID = setid,
       Skills = {},
       EquptSkills = {},
       Money = 999999,
       Rating = 1000
    }
    return Player;
end


--在模块加载后调用 传入了模块ID号
function OnInit(id)
    ID = id
    print("[Lua]: PlayerDataManager初始化成功  ID: "..ID)
    ServerLuaLib.RegMessage(4001,ID);
    ServerLuaLib.RegMessage(4002,ID);
    ServerLuaLib.RegMessage(4003,ID);
    ServerLuaLib.RegMessage(4004,ID);
    ServerLuaLib.RegMessage(4005,ID);
    ServerLuaLib.RegMessage(4006,ID);
    ServerLuaLib.RegMessage(4007,ID);
    ServerLuaLib.RegMessage(4008,ID);
    ServerLuaLib.RegMessage(4009,ID);
    ServerLuaLib.RegMessage(4010,ID);
    ServerLuaLib.RegMessage(4011,ID);
    CMDS[4001] = GetPlayerSkillList_CMD;
    CMDS[4002] = AddPlayer_CMD;
    CMDS[4003] = RemovePlayer_CMD;
    CMDS[4004] =  ClickSkillIcon_CMD;
    CMDS[4005] =  AddPlayerSkill_CMD;
    CMDS[4006] =    GetPlayerEquptInfo_CMD;
    CMDS[4007] =   EquptPlayerSkill_CMD;
    CMDS[4008] =   GetPlayerDataInfo_CMD;
    CMDS[4009] =   JoinMatchGame_CMD;
    CMDS[4010] = ExitMatchGame_CMD;
    CMDS[4011] = PlayerReward_CMD;



end

--一直调用
function OnUpdate()


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

function AddPlayer_CMD(data)
    local PlayerID = string.unpack("i4",data);
    PlayerDataList[PlayerID] = GetNewPlayerData(PlayerID);
end

function  RemovePlayer_CMD(data)
    local PlayerID = string.unpack("i4",data);
    if(PlayerDataList[PlayerID] == nil )then return end;
    PlayerDataList[PlayerID] = nil;
end

function GetPlayerSkillList_CMD(data)
  local PlayerID = string.unpack("i4",data,5);
  if(PlayerDataList[PlayerID] == nil )then return end;
  local data1 = "";
  for k,v in pairs(PlayerDataList[PlayerID].Skills) do
    data1 = data1..string.pack("i2",k);
  end
  local size = #data1;
  local sendData = string.pack("i4i4i4c"..size,PlayerID,401,size,data1);
  ServerLuaLib.SendMessage(10004,sendData,ID,-1);

end

function ClickSkillIcon_CMD(data)
    local PlayerID,SkillID = string.unpack("i4i4",data,5);
    if(PlayerDataList[PlayerID] == nil )then return end;
    if(SkillCost[SkillID] == nil )then return end;
     
    if(PlayerDataList[PlayerID].Skills[SkillID] == nil) then
        state = -1
        local sendData = string.pack("i4i4i4i4i4i4",PlayerID,402,12,state,SkillID,SkillCost[SkillID]);
        ServerLuaLib.SendMessage(10004,sendData,ID,-1);
    else
        state = 1
        local sendData = string.pack("i4i4i4i4i4",PlayerID,402,8,state,SkillID);
        ServerLuaLib.SendMessage(10004,sendData,ID,-1);
    end

    
end

function AddPlayerSkill_CMD(data)
    local PlayerID,SkillID = string.unpack("i4i4",data,5);
   
    if(PlayerDataList[PlayerID] == nil )then return end;
    if(SkillCost[SkillID] == nil )then return end;
    if(PlayerDataList[PlayerID].Skills[SkillID] ~= nil )then return end;
    if(PlayerDataList[PlayerID].Money - SkillCost[SkillID] < 0) then 
        state = -1
        local sendData = string.pack("i4i4i4i4",PlayerID,403,4,state);
        ServerLuaLib.SendMessage(10004,sendData,ID,-1);
        return;
    end

    PlayerDataList[PlayerID].Money = PlayerDataList[PlayerID].Money - SkillCost[SkillID];
    PlayerDataList[PlayerID].Skills[SkillID] = true;

    state = 1
    local sendData = string.pack("i4i4i4i4",PlayerID,403,4,state);
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);

end

function GetPlayerEquptInfo_CMD(data)
    local PlayerID = string.unpack("i4",data,5);
    if(PlayerDataList[PlayerID] == nil )then return end;

    
    sendData = "";
    for k,v in pairs(PlayerDataList[PlayerID].EquptSkills) do
        sendData = sendData..string.pack("i4i4",k,v);
    end
    size = #sendData;
    sendData = string.pack("i4i4i4c"..size,PlayerID,404,size,sendData)
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
end


function EquptPlayerSkill_CMD(data)
    
    local PlayerID,SkillID,pos = string.unpack("i4i4i4",data,5);
    
    if(PlayerDataList[PlayerID] == nil )then return end;
    if(SkillCost[SkillID] == nil )then return end;
    if(PlayerDataList[PlayerID].Skills[SkillID] == nil )then return end;
    if(pos < 0 or pos >= 4 )then return end;
    PlayerDataList[PlayerID].EquptSkills[pos] = SkillID;

    local sendData = "";
    for k,v in pairs(PlayerDataList[PlayerID].EquptSkills) do
        sendData = sendData..string.pack("i4i4",k,v);
    end
    size = #sendData;
    sendData = string.pack("i4i4i4c"..size,PlayerID,404,size,sendData)
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
 
end


function GetPlayerDataInfo_CMD(data)
    local PlayerID = string.unpack("i4",data,5);
    if(PlayerDataList[PlayerID] == nil )then return end;


    local sendData = string.pack("i4i4i4i4i4",PlayerID,405,8,PlayerDataList[PlayerID].Money,PlayerDataList[PlayerID].Rating)
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);

end

function  GetPlayerAllData_Local(data)
    local PlayerID = string.unpack("i4",data,5);
    if(PlayerDataList[PlayerID] == nil )then return end;
    local sendData = string.pack("i4i4",PlayerDataList[PlayerID].Money,PlayerDataList[PlayerID].Rating)
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
end

function JoinMatchGame_CMD(data)
    local PlayerID = string.unpack("i4",data,5);
    if(PlayerDataList[PlayerID] == nil )then return end;
   
    local sendData = string.pack("i4i4",PlayerID,PlayerDataList[PlayerID].Rating)
    ServerLuaLib.SendMessage(6001,sendData,ID,-1);
end


function ExitMatchGame_CMD(data)
    local PlayerID = string.unpack("i4",data,5);
    if(PlayerDataList[PlayerID] == nil )then return end;
   
    local sendData = string.pack("i4",PlayerID)
    ServerLuaLib.SendMessage(6002,sendData,ID,-1);
end

function PlayerReward_CMD(data)
   PlayerID,money,rating = string.unpack("i4i4i4",data)
   print(money,rating);
   if(PlayerDataList[PlayerID] == nil )then return end;
   PlayerDataList[PlayerID].Money = PlayerDataList[PlayerID].Money + money;
   PlayerDataList[PlayerID].Rating = math.min(PlayerDataList[PlayerID].Rating + rating,4000)

   local sendData = string.pack("i4i4i4i4i4",PlayerID,406,8,money,rating)
   ServerLuaLib.SendMessage(10004,sendData,ID,-1);
end