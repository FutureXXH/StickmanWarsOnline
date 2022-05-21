
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
CMDS = {};
WaitPlayerList = WaitPlayerList or {}
PlayerList = PlayerList or {}
function  GenerateTable( )
    local temp = {}
    return temp;
end

function  GetPlayer(setID,setRating )
    local player = {
        playerID = setID,
        Rating = setRating
    }
    return player;
end


--在模块加载后调用 传入了模块ID号
function OnInit(id)
    ID = id
    print("[Lua]: MatchSystem初始化成功  ID: "..ID)

    InitWaitPlayerList()


    ServerLuaLib.RegMessage(6001,ID);
    ServerLuaLib.RegMessage(6002,ID);
    ServerLuaLib.RegMessage(6003,ID);
    CMDS[6001] = AddWaitPlayer_CMD;
    CMDS[6002] = RemoveWaitPlayer_CMD;
end
local lasttime = ServerLuaLib.GetTime();
--一直调用
function OnUpdate()

    if(ServerLuaLib.GetTime() - lasttime > 1000) then
        MatchPlayer();
        lasttime = ServerLuaLib.GetTime();
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

function InitWaitPlayerList()
    for i=1,4000 do
        WaitPlayerList[i] = GenerateTable();
    end
end

function AddWaitPlayer_CMD(data)
    local PlayerID ,Rating = string.unpack("i4i4",data);
    print(Rating);
    PlayerList[PlayerID] = GetPlayer(PlayerID,Rating)
    WaitPlayerList[Rating][PlayerID] = 1;
    local  state = 1;
    local data = string.pack("i4i4i4i4",PlayerID,601,4,state);
    ServerLuaLib.SendMessage(10004,data,ID,-1);
end

function RemoveWaitPlayer_CMD(data )
    local PlayerID = string.unpack("i4",data);
    if(PlayerList[PlayerID] == nil)then return end;
    WaitPlayerList[PlayerList[PlayerID].Rating][PlayerID] = nil;
    PlayerList[PlayerID] = nil

    local  state = -1;
    local data = string.pack("i4i4i4i4",PlayerID,601,4,state);
    ServerLuaLib.SendMessage(10004,data,ID,-1);
end

function RemoveWaitPlayer(PlayerID)
    if(PlayerList[PlayerID] == nil)then return end;
    WaitPlayerList[PlayerList[PlayerID].Rating][PlayerID] = nil;
    PlayerList[PlayerID] = nil
end


function MatchPlayer()
    local Player1 = -1
    local Player2 = -1
    for k,v in pairs(WaitPlayerList) do
        for k2 in pairs(v) do
           
            if(Player1 == -1) then
                Player1 = k2;
            else
                Player2 = k2;
                 print(Player1.."  ".. Player2 .. "   匹配");
                local sendData = string.pack("i4i4",Player1,Player2);
                ServerLuaLib.SendMessage(2006,sendData,ID,-1);
                RemoveWaitPlayer(Player1)
                RemoveWaitPlayer(Player2)
                Player1 = -1;
                Player2 = -1;
            end


        end
    end
end

