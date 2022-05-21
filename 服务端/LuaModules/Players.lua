
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
--ServerLuaLib.SendMessage(消息ID,数据,发送源模块ID);
--获取时间戳
--ServerLuaLib.GetTime();
--输出日志
--ServerLuaLib.Log(级别,消息)  (INFO,WARNING,ERROR);

function GetPlayer()
  Player = {
    ID = -1,
    state = 0,
    sockclientID = 0,
  }
  return Player;
end

CMDS = {};
CurPlayersNum = 0
PlayerList_ID = PlayerList_ID or {}
PlayerSOCK_ID = PlayerSOCK_ID or {}

lasttime = ServerLuaLib.GetTime()/1000;








--在模块加载后调用 传入了模块ID号
function OnInit(id)
    ID = id
    print("[Lua]: Players初始化成功  ID: "..ID)
    ServerLuaLib.RegMessage(10001,ID);
    ServerLuaLib.RegMessage(10002,ID);
    ServerLuaLib.RegMessage(10003,ID);
    ServerLuaLib.RegMessage(10004,ID);
    ServerLuaLib.RegMessage(101,ID);
    ServerLuaLib.RegMessage(1,ID);
    CMDS[1] = BackDelay_CMD;
    CMDS[101] = PlayerExit_CMD;
    CMDS[10001] = NewPlayer;
    CMDS[10002] = PlayerExit_CMD;
    CMDS[10003] = SendAllPlayerData;
    CMDS[10004] = SendPlayerData;
end

--一直调用
function OnUpdate()
    curtime = ServerLuaLib.GetTime()/1000;
    dtime = curtime-lasttime;
  if dtime > 10 then
    print("[Lua]: 当前玩家数量 "..CurPlayersNum)
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


--  head + datasize + data;
function SendAllPlayerData(data)

  local head,size = string.unpack("i4i4",data);


  for k, v in pairs(PlayerList_ID) do
    local senddata = string.pack("i4i4i4c"..size,v.sockclientID,head,size,string.unpack("c"..size,data,9));
    ServerLuaLib.SendMessage(102,senddata,ID,-1);
    end
  
end



-- playerID + head + datasize + data;
function SendPlayerData(data)

  local playerID,head,size,next = string.unpack("i4i4i4",data);
  
  if(PlayerList_ID[playerID] ~= nil) then
    local sendplayer = PlayerList_ID[playerID];

    local senddata = string.pack("i4i4i4c"..size,sendplayer.sockclientID,head,size,string.unpack("c"..size,data,next));
    ServerLuaLib.SendMessage(102,senddata,ID,-1);
    --SendPlayerData(sendplayer.sockclientID,head,string.unpack("c"..size,data,next),size);
  end

  
end

function NewPlayer(data)
              local player = GetPlayer();
              player.sockclientID ,player.ID = string.unpack("i4i4",data);
              if(PlayerList_ID[player.ID] ~= nil) then
                PlayerExit(player.ID,PlayerList_ID[player.ID].sockclientID)
              end

              PlayerList_ID[player.ID] = player;
              PlayerSOCK_ID[player.sockclientID] = player.ID;
              CurPlayersNum = CurPlayersNum+1; 
              print("[Lua]: 新玩家: "..player.ID.." sock:".. player.sockclientID.. "加入")
              --sock + head + size + buffer
              local  senddata = string.pack("i4i4i4i4",player.sockclientID,100,4,player.ID);
                
              ServerLuaLib.SendMessage(102,senddata,ID,-1);

              
              --发送给玩家数据管理器
              senddata = string.pack("i4",player.ID);
              ServerLuaLib.SendMessage(4002,senddata,ID,-1);
end

function PlayerExit_CMD(data)
        
        local sockid = string.unpack("i4",data);
        if( PlayerSOCK_ID[sockid] ~= nil ) then 
          local  playerid = PlayerSOCK_ID[sockid];
         
          PlayerExit(playerid,sockid)
        end

end

function PlayerExit(PlayerID,sockid)

   print("[Lua]: 玩家: "..PlayerID.." sock:".. sockid.. "退出")
   if(PlayerList_ID[PlayerID] ~= nil) then

   player = PlayerList_ID[PlayerID];
    PlayerList_ID[PlayerID] = nil;
    --发送给房间管理器 让玩家退出当前房间
    local  senddata = string.pack("i4i4",sockid,PlayerID);
    ServerLuaLib.SendMessage(2004,senddata,ID,-1);
    --发送给玩家数据管理器
    senddata = string.pack("i4",PlayerID);
    ServerLuaLib.SendMessage(4003,senddata,ID,-1);
    --发送给匹配系统推出匹配
    senddata = string.pack("i4",PlayerID);
    ServerLuaLib.SendMessage(6002,senddata,ID,-1);


    CurPlayersNum = CurPlayersNum-1; 

   end

   

   

   if(PlayerSOCK_ID[sockid] ~= nil) then
    local  senddata = string.pack("i4i4i4i4",sockid,-1,4,-1);
    ServerLuaLib.SendMessage(102,senddata,ID,-1);

    PlayerSOCK_ID[sockid] = nil;
    local  senddata = string.pack("i4",sockid);      
    ServerLuaLib.SendMessage(103,senddata,ID,-1);
    
   end
   



    
end



function BackDelay_CMD(data)

    local sock,time = string.unpack("i4i8",data);
    local  senddata = string.pack("i4i4i4i8",sock,1,8,time);   
    ServerLuaLib.SendMessage(102,senddata,ID,-1);
end



