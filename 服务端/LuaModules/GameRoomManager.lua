
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



--在模块加载后调用 传入了模块ID号


GameRoomList = GameRoomList or {}
CMDS = {};
PlayerRoomID = PlayerRoomID or {}


function GetNewGameRoomObj()
     local GameRoom = {
        RoomID = 0,
        CurPlayerNum = 0,
        MaxPlayer = 0,
        state = 0,
        Type = 1 -- 1 普通房间  2 匹配房间
     }
     return GameRoom;

end



function OnInit(id)
    ID = id
    print("[Lua]: GameRoomManager初始化成功  ID: "..ID)
    ServerLuaLib.RegMessage(2001,ID);
    ServerLuaLib.RegMessage(2002,ID);
    ServerLuaLib.RegMessage(2003,ID);
    ServerLuaLib.RegMessage(2004,ID);
    ServerLuaLib.RegMessage(2005,ID);
    ServerLuaLib.RegMessage(2006,ID);
    ServerLuaLib.RegMessage(2007,ID);
    CMDS[2001] = GetGameRoomList_CMD;
    CMDS[2002] = CreateGameRoom_CMD;
     CMDS[2003] = JoinGameRoom_CMD;
     CMDS[2004] = ExitGameRoom_CMD;
     CMDS[2005] = RemoveGameRoom_CMD;
     CMDS[2006] =  CreateMatchGameRoom_CMD
     CMDS[2007] =   GetGameRoomType_CMD


end

--一直调用
function OnUpdate()


end

--在有消息达到时调用
function OnParseMessage(MessageID,data,srcModuleID)
   
   if CMDS[MessageID] ~= nil then
    CMDS[MessageID](data,srcModuleID);
   end
end

--模块删除时调用
function OnExit()
    print("[Lua]: 模块: "..ID.. "退出")
end

function GetGameRoomList_CMD(data)
    --sock + head + size + buffer
    local sock = string.unpack("i4",data);
    local roomData = "";
    local dataSize = 0;
    for k,v in pairs(GameRoomList) do
        -- 房间ID  房间人数  最大人数
        roomData = roomData..string.pack("i4i4i4",v.RoomID,v.CurPlayerNum,v.MaxPlayer);
        dataSize =  dataSize +12;
    end
    
    local sendData = string.pack("i4i4i4c"..dataSize,sock,201,dataSize,roomData);
    ServerLuaLib.SendMessage(102,sendData,ID,-1);
end

function CreateGameRoom_CMD(data)
    local sock,playerID = string.unpack("i4i4",data);
    local RoomID  = 0;
    for  tempi = 5000,5999  do
        if(GameRoomList[tempi] == nil) then 
            RoomID = tempi
            break;
        end;
    end

    if(RoomID == 5999 or RoomID == 0) then return false end;

    GameRoomList[RoomID]  = GetNewGameRoomObj();
    GameRoomList[RoomID].RoomID = RoomID;
    GameRoomList[RoomID].state = 1;
    GameRoomList[RoomID].MaxPlayer = 2;
    GameRoomList[RoomID].Type = 1;
    ServerLuaLib.Log("INFO","创建房间"..RoomID);
    ServerLuaLib.LoadNewModule(RoomID,"GameRoom.lua");

     

    sendData = string.pack("i4i4i4i4",playerID,202,4,RoomID);
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
    return true
end

function CreateMatchGameRoom_CMD(data)
    local player1ID, player2ID = string.unpack("i4i4",data);
   -- print(player1ID.."  "..player2ID)
    local RoomID  = 0;
    for  tempi = 5000,5999  do
        if(GameRoomList[tempi] == nil) then 
            RoomID = tempi
            break;
        end;
    end

    if(RoomID == 5999 or RoomID == 0) then return false end;

    GameRoomList[RoomID]  = GetNewGameRoomObj();
    GameRoomList[RoomID].RoomID = RoomID;
    GameRoomList[RoomID].state = 1;
    GameRoomList[RoomID].MaxPlayer = 2;
    GameRoomList[RoomID].Type = 2;
    ServerLuaLib.Log("INFO","创建房间"..RoomID);
    ServerLuaLib.LoadNewModule(RoomID,"GameRoom.lua");



    local sendData = string.pack("i4i4i4i4",player1ID,202,4,RoomID);
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
    local sendData = string.pack("i4i4i4i4",player2ID,202,4,RoomID);
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
    return true

    

end


function GetGameRoomType_CMD(data,srcModuleID)
    local sendData = string.pack("i4",GameRoomList[srcModuleID].Type);
    ServerLuaLib.SendMessage(5000,sendData,ID,srcModuleID);
end


function JoinGameRoom_CMD(data)
    local sock, playerID,roomID = string.unpack("i4i4i4",data);
   
    --房间不存在
    if(GameRoomList[roomID] == nil) then
     sendData = string.pack("i4i4i4i4",playerID,203,4,-1);
     ServerLuaLib.SendMessage(10004,sendData,ID,-1);

        return -1 
    
    end
    --房间已满
    if(GameRoomList[roomID].max == GameRoomList[roomID].CurPlayerNum) then
     sendData = string.pack("i4i4i4i4",playerID,203,4,-2);
     ServerLuaLib.SendMessage(10004,sendData,ID,-1);   
        return -2 
    end
    --玩家已经进入了一个房间 将退出原房间
     if(PlayerRoomID[playerID] ~= nil) then
         local curroomID = PlayerRoomID[playerID];
         ExitGameRoom(playerID,curroomID)
     end

    ServerLuaLib.Log("INFO","玩家" .. playerID.."加入房间"..roomID);
    PlayerRoomID[playerID] = roomID;
    --发送给GameRoom模块
    local senddata = string.pack("i4",playerID);
    ServerLuaLib.SendMessage(5001,senddata,ID,roomID);


    --发送给玩家
     sendData = string.pack("i4i4i4i4",playerID,203,4,roomID);
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);
    GameRoomList[roomID].CurPlayerNum =  GameRoomList[roomID].CurPlayerNum+1;

end

function RemoveGameRoom_CMD(data)
    ID = string.unpack("i4",data)
    RemoveGameRoom(ID);
end

function RemoveGameRoom(RoomID)
    if( GameRoomList[RoomID] == nil)then return end;
    ServerLuaLib.CloseModule(RoomID);
    GameRoomList[RoomID] = nil;

end

function ExitGameRoom(playerID,roomID)

    
    if(GameRoomList[roomID] == nil) then return -1 end
    GameRoomList[roomID].CurPlayerNum = GameRoomList[roomID].CurPlayerNum-1;
    PlayerRoomID[playerID] = nil;

    --发送给GameRoom模块
    local senddata = string.pack("i4",playerID);
    ServerLuaLib.SendMessage(5002,senddata,ID,roomID);
    --发送给玩家
    local state = 1;
    local sendData = string.pack("i4i4i4i4",playerID,204,4,state);
    ServerLuaLib.SendMessage(10004,sendData,ID,-1);

    if( GameRoomList[roomID].CurPlayerNum == 0)then
        RemoveGameRoom(roomID);
    end
end

function ExitGameRoom_CMD(data)
    local sock,playerID = string.unpack("i4i4",data);
    if(PlayerRoomID[playerID] == nil)then return end;
 
    roomID = PlayerRoomID[playerID];
   
    ExitGameRoom(playerID,roomID);
    
end

