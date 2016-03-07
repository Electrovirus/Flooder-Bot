local function is_spromoted(chat_id, user_id)
  local hash =  'sprom:'..chat_id..':'..user_id
  local spromoted = redis:get(hash)
  return spromoted or false
end

local function kick_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, ok_cb, true)
end

local function kick_user_chan(user_id, chat_id)
  local channel = 'channel#id'..chat_id
  local user = 'user#id'..user_id
  channel_kick_user(channel, user, ok_cb, true)
end

local function ban_user(user_id, chat_id)
  local hash =  'banned:'..chat_id..':'..user_id
  redis:set(hash, true)
  kick_user(user_id, chat_id)
end

local function superban_user(user_id, chat_id)
  local hash =  'superbanned:'..user_id
  redis:set(hash, true)
  kick_user(user_id, chat_id)
end

local function superban_user_chan(user_id, chat_id)
  local hash =  'superbanned:'..user_id
  redis:set(hash, true)
  kick_user_chan(user_id, chat_id)
end

local function silent_user(user_id, chat_id)
  local hash =  'silent:'..chat_id..':'..user_id
  redis:set(hash, true)
end

local function is_banned(user_id, chat_id)
  local hash =  'banned:'..chat_id..':'..user_id
  local banned = redis:get(hash)
  return banned or false
end

local function is_super_banned(user_id)
    local hash = 'superbanned:'..user_id
    local superbanned = redis:get(hash)
    return superbanned or false
end

local function is_user_silent(user_id, chat_id)
  local hash =  'silent:'..chat_id..':'..user_id
  local silent = redis:get(hash)
  return silent or false
end

local function pre_process(msg)
  if msg.action and msg.action.type then
    local action = msg.action.type
    if action == 'chat_add_user' or action == 'chat_add_user_link' then
      local user_id
      if msg.action.link_issuer then
          user_id = msg.from.id
      else
        user_id = msg.action.user.id
      end
      print('Checking invited user '..user_id)
      local superbanned = is_super_banned(user_id)
      local banned = is_banned(user_id, msg.to.id)
      if superbanned or banned then
        print('User is banned!')
        if msg.to.type == 'chat' then
          kick_user(user_id, msg.to.id)
        end
        if msg.to.type == 'channel' then
          kick_user_chan(user_id, msg.to.id)
        end
      end
    end
    return msg
  end

  -- BANNED USER TALKING
  if msg.to.type == 'chat' then -- For chat
    local user_id = msg.from.id
    local chat_id = msg.to.id
    local superbanned = is_super_banned(user_id)
    local banned = is_banned(user_id, chat_id)
    if superbanned then
      print('SuperBanned user talking!')
      superban_user(user_id, chat_id)
      msg.text = ''
    end
    if banned then
      print('Banned user talking!')
      ban_user(user_id, chat_id)
      msg.text = ''
    end
  end
  if msg.to.type == 'channel' then -- For supergroup
    local user_id = msg.from.id
    local chat_id = msg.to.id
    if is_user_silent(user_id, chat_id) then -- is user allowed to talk?
      delete_msg(msg.id, ok_cb, false)
      return nil
    end
    local superbanned = is_super_banned(user_id)
    local banned = is_banned(user_id, chat_id)
    if superbanned then
      print('SuperBanned user talking!')
      superban_user_chan(user_id, chat_id)
      msg.text = ''
    end
    if banned then
      print('Banned user talking!')
      ban_user(user_id, chat_id)
      msg.text = ''
    end
  end
  return msg
end

local function username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local member = cb_extra.member
   local chat_id = string.gsub(receiver,'.+#id', '')
   local text = 'No user @'..member..' in this group.'
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
        member_username = member
        member_id = v.peer_id
        if get_cmd == 'kick' then
          if member_id == our_id then
            send_large_msg(receiver, 'Are you kidding?')
            return nil
          end
          local data = load_data(_config.moderation.data)
          if data[tostring('admins')] then
            if data[tostring('admins')][tostring(member_id)] then
              send_large_msg(receiver, 'You can\'t kick admin!')
              return nil
            end
          end
          if is_spromoted(chat_id, member_id) then
            return send_large_msg(receiver,'You can\'t kick leader')
          end
          return kick_user(member_id, chat_id)
        end
        if get_cmd == 'ban' then
          if member_id == our_id then
            send_large_msg(receiver, 'Are you kidding?')
            return nil
          end
          local data = load_data(_config.moderation.data) -- FLUX MOD
          if data[tostring('admins')] then
            if data[tostring('admins')][tostring(member_id)] then
              send_large_msg(receiver, 'You can\'t ban admin!')
              return nil
            end
          end
          if is_spromoted(chat_id, member_id) then
            return send_large_msg(receiver, 'You can\'t ban leader')
          end
          send_large_msg(receiver, 'User @'..member..' ['..member_id..'] banned')
          return ban_user(member_id, chat_id)
        end
        if get_cmd == 'sban' then
          if member_id == our_id then
            return nil
          end
          send_large_msg(receiver, 'User @'..member..' ['..member_id..'] globally banned!')
          return superban_user(member_id, chat_id)
        end
      end
   end
   return send_large_msg(receiver, text)
end

local function channel_username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local chat_id = string.gsub(receiver,'.+#id', '')
   local member = cb_extra.member
   local text = 'No user @'..member..' in this group.'
   for k,v in pairs(result) do
      vusername = v.username
      if vusername == member then
        member_username = member
        member_id = v.peer_id
        if get_cmd == 'kick' then
            if member_id == our_id then
                send_large_msg(receiver, 'Are you kidding?')
                return nil
            end
            local data = load_data(_config.moderation.data) -- FLUX MOD
            if data[tostring('admins')] then
              if data[tostring('admins')][tostring(member_id)] then
                send_large_msg(receiver, 'You can\'t kick admin!')
                return nil
              end
            end
            if is_spromoted(chat_id, member_id) then
              return send_large_msg(receiver,'You can\'t kick leader')
            end
            return kick_user_chan(member_id, chat_id)
        end
        if get_cmd == 'ban' then
          if member_id == our_id then
              send_large_msg(receiver, 'Are you kidding?')
              return nil
          end
          local data = load_data(_config.moderation.data)
          if data[tostring('admins')] then
            if data[tostring('admins')][tostring(member_id)] then
              send_large_msg(receiver, 'You can\'t ban admin!')
              return nil
            end
          end
          if is_spromoted(chat_id, member_id) then
            return send_large_msg(receiver, 'You can\'t ban leader')
          end
          send_large_msg(receiver, 'User @'..member..' ['..member_id..'] banned')
          return ban_user(member_id, chat_id)
        end
        if get_cmd == 'sban' then
          if member_id == our_id then
            return nil
          end
          send_large_msg(receiver, 'User @'..member..' ['..member_id..'] globally banned!')
          return superban_user_chan(member_id, chat_id)
        end
        if get_cmd == 'silent' then
          if member_id == our_id then
              return nil
          end
          local data = load_data(_config.moderation.data)
          if data[tostring('admins')] then
            if data[tostring('admins')][tostring(member_id)] then
              send_large_msg(receiver, 'You can\'t do this to admin!')
              return nil
            end
          end
          if is_spromoted(chat_id, member_id) then
            return send_large_msg(receiver, 'You can\'t do this to leader')
          end
          send_large_msg(receiver, 'User '..member_id..' not allowed to talk!')
          return silent_user(member_id, chat_id)
        end
        if get_cmd == 'unsilent' then
          if member_id == our_id then
              return nil
          end
          local data = load_data(_config.moderation.data)
          if data[tostring('admins')] then
            if data[tostring('admins')][tostring(member_id)] then
              send_large_msg(receiver, 'Admin always allowed to talk!')
              return nil
            end
          end
          local hash =  'silent:'..chat_id..':'..member_id
          redis:del(hash)
          return send_large_msg(receiver, 'User '..member_id..' allowed to talk')
        end
      end
   end
   return send_large_msg(receiver, text)
end

local function get_msg_callback(extra, success, result)
  if success ~= 1 then return end
  local get_cmd = extra.get_cmd
  local receiver = extra.receiver
  local user_id = result.from.peer_id
  local chat_id = string.gsub(receiver,'.+#id', '')
  if result.from.username then
    username = '@'..result.from.username
  else
    username = string.gsub(result.from.print_name, '_', ' ')
  end
  if string.find(receiver,'chat#id.+') then
    group_type = 'chat'
  else
    group_type = 'channel'
  end
  if get_cmd == 'kick' then
    if user_id == our_id then
      return nil
    end
    local data = load_data(_config.moderation.data)
    if data[tostring('admins')] then
      if data[tostring('admins')][tostring(user_id)] then
        return send_large_msg(receiver, 'You can\'t kick admin!')
      end
    end
    if is_spromoted(chat_id, user_id) then
      print('kick leader')
      return send_large_msg(receiver,'You can\'t kick leader')
    end
    if group_type == 'chat' then
      return kick_user(user_id, chat_id)
    else
      return kick_user_chan(user_id, chat_id)
    end
  end
  if get_cmd == 'ban' then
    if user_id == our_id then
      return nil
    end
    local data = load_data(_config.moderation.data) -- FLUX MOD
    if data[tostring('admins')] then
      if data[tostring('admins')][tostring(user_id)] then
        return send_large_msg(receiver, 'You can\'t ban admin!')
      end
    end
    if is_spromoted(chat_id, user_id) then
      return send_large_msg(receiver,'You can\'t ban leader')
    end
    send_large_msg(receiver, 'User '..username..' ['..user_id..'] banned')
    if group_type == 'chat' then
      return ban_user(user_id, chat_id)
    else
      return kick_user_chan(user_id, chat_id)
    end
end
  if get_cmd == 'unban' then
    if user_id == our_id then
      return nil
    end
    local hash =  'banned:'..chat_id..':'..user_id
    redis:del(hash)
    return send_large_msg(receiver, 'User '..user_id..' unbanned')
  end
  if get_cmd == 'sban' then
    if user_id == our_id then
      return nil
    end
    send_large_msg(receiver, 'User '..username..' ['..user_id..'] globally banned!')
    return superban_user(member_id, chat_id)
  end
  if get_cmd == 'silent' then
    if user_id == our_id then
      return nil
    end
    local data = load_data(_config.moderation.data)
    if data[tostring('admins')] then
      if data[tostring('admins')][tostring(user_id)] then
        send_large_msg(receiver, 'You can\'t do this to admin!')
        return nil
      end
    end
    if is_spromoted(chat_id, user_id) then
      return send_large_msg(receiver, 'You can\'t do this to leader')
    end
    send_large_msg(receiver, 'User '..user_id..' not allowed to talk!')
    return silent_user(user_id, chat_id)
  end
  if get_cmd == 'unsilent' then
    if member_id == our_id then
      return nil
    end
    local data = load_data(_config.moderation.data)
    if data[tostring('admins')] then
      if data[tostring('admins')][tostring(user_id)] then
        send_large_msg(receiver, 'Admin always allowed to talk!')
        return nil
      end
    end
    local hash =  'silent:'..chat_id..':'..user_id
    redis:del(hash)
    return send_large_msg(receiver, 'User '..user_id..' allowed to talk')
  end
end

local function run(msg, matches)
  if matches[1] == 'kickme' then
    if is_chat_msg(msg) then
      kick_user(msg.from.id, msg.to.id)
    elseif is_channel_msg(msg) then
      kick_user_chan(msg.from.id, msg.to.id)
    else
      return
    end
  end
  if not is_momod(msg) then
    return nil
  end
  local receiver = get_receiver(msg)
  local get_cmd = matches[1]

  if is_channel_msg(msg) then -- SUPERGROUUUPPPPPPPPPPPP
    if matches[1] == 'ban' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
      end
      if not matches[2] then
        return
      end
      local user_id = matches[2]
      local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id then
          return
        end
        local data = load_data(_config.moderation.data) -- FLUX MOD
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(user_id)] then
            return 'You can\'t ban admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) and not is_admin(msg) then
          return 'You can\'t ban leader'
        end
        ban_user(user_id, chat_id)
        send_large_msg(receiver, 'User '..user_id..' banned!')
      else
          local member = string.gsub(matches[2], '@', '')
          channel_get_users(receiver, chanel_username_id, {get_cmd=get_cmd, receiver=receiver, member=member})
      end
    end
    if matches[1] == 'unban' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
      end
      if not matches[2] then
        return
      end
      local user_id = matches[2]
      local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        local hash =  'banned:'..chat_id..':'..user_id
        redis:del(hash)
        return 'User '..user_id..' unbanned'
      else
        return 'Use user id only'
      end
    end
    if matches[1] == 'sban' and is_admin(msg) then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
      end
      if not matches[2] then
        return
      end
      local user_id = matches[2]
      local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id then
          return
        end
        local data = load_data(_config.moderation.data) -- FLUX MOD
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(user_id)] then
            return 'You can\'t ban admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) and not is_admin(msg) then
          return 'You can\'t ban leader'
        end
        ban_user(user_id, chat_id)
        send_large_msg(receiver, 'User '..user_id..' globally banned!')
      else
        local member = string.gsub(matches[2], '@', '')
        channel_get_users(receiver, chanel_username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member})
      end
    end
    if matches[1] == 'unsban' then
      local user_id = matches[2]
      local chat_id = msg.to.id
      local hash =  'superbanned:'..user_id
      redis:del(hash)
      return 'User '..user_id..' unbanned'
    end
    if matches[1] == 'kick' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id and not is_admin(msg) then
          return
        end
        local data = load_data(_config.moderation.data)
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(matches[2])] then
            return 'You can\'t kick admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) and not is_admin(msg) then
          return 'You can\'t kick leader'
        end
        kick_user_chan(matches[2], msg.to.id)
      else
        local member = string.gsub(matches[2], '@', '')
        channel_get_users(receiver, channel_username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
      end
    end
    if matches[1] == 'silent' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id then
          return
        end
        local data = load_data(_config.moderation.data)
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(matches[2])] then
            return 'You can\'t do this to admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) and not is_admin(msg) then
          return 'You can\'t do this to leader'
        end
        silent_user(matches[2], msg.to.id)
        send_large_msg(receiver, 'User '..matches[2]..' not allowed to talk!')
      else
        local member = string.gsub(matches[2], '@', '')
        channel_get_users(receiver, channel_username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
      end
    end
    if matches[1] == 'unsilent' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id then
          return
        end
        local data = load_data(_config.moderation.data)
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(matches[2])] then
            return 'Admin always allowed to talk!'
          end
        end
        local hash =  'silent:'..msg.to.id..':'..matches[2]
        redis:del(hash)
        return 'User '..user_id..' allowed to talk'
      else
        local member = string.gsub(matches[2], '@', '')
        channel_get_users(receiver, channel_username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
      end
    end
  end
  
  if is_chat_msg(msg) then -- CHAAAAAAAAATTTTTTTTTTTTTTTTTTTTTT
    if matches[1] == 'ban' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
      end
      if not matches[2] then
        return
      end
      local user_id = matches[2]
      local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id then
          return
        end
        local data = load_data(_config.moderation.data) -- FLUX MOD
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(user_id)] then
            return 'You can\'t ban admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) and not is_admin(msg) then
          return 'You can\'t ban leader'
        end
          ban_user(user_id, chat_id)
          send_large_msg(receiver, 'User '..user_id..' banned!')
      else
          local member = string.gsub(matches[2], '@', '')
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, member=member})
      end
    end
    if matches[1] == 'unban' then
      local user_id = matches[2]
      local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        local hash =  'banned:'..chat_id..':'..user_id
        redis:del(hash)
        return 'User '..user_id..' unbanned'
      else
        return 'Use user id only'
      end
    end
    if matches[1] == 'sban' and is_admin(msg) then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
      end
      if not matches[2] then
        return
      end
      local user_id = matches[2]
      local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id then
          return
        end
        local data = load_data(_config.moderation.data) -- FLUX MOD
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(user_id)] then
            return 'You can\'t ban admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) and not is_admin(msg) then
          return 'You can\'t ban leader'
        end
        ban_user(user_id, chat_id)
        send_large_msg(receiver, 'User '..user_id..' globally banned!')
      else
        local member = string.gsub(matches[2], '@', '')
        chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, member=member})
      end
    end
    if matches[1] == 'unsban' then
      local hash =  'superbanned:'..user_id
      redis:del(hash)
      return 'User '..user_id..' unbanned'
    end
    if matches[1] == 'kick' then
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        if matches[2] == our_id and not is_admin(msg) then
          return
        end
        local data = load_data(_config.moderation.data)
        if data[tostring('admins')] then
          if data[tostring('admins')][tostring(matches[2])] then
            return 'You can\'t kick admin!'
          end
        end
        if is_spromoted(msg.to.id, matches[2]) then
          if not is_admin(msg) then
            return 'You can\'t kick leader'
          end
        end
        kick_user(matches[2], msg.to.id)
      else
        local member = string.gsub(matches[2], '@', '')
        chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member})
      end
    end
  end
end

return {
  description = "Plugin to manage bans, kicks and white/black lists.", 
  usage = {
      user = "!kickme : Exit from group",
      moderator = {
          "!ban user <user_id> : Kick user from chat and kicks it if joins chat again",
          "!ban user <username> : Kick user from chat and kicks it if joins chat again",
          "!unban (on reply)",
          "!kick (on reply) : Kick user from chat group by reply",
          "!ban delete <user_id> : Unban user",
          "!kick <user_id> : Kick user from chat group by id",
          "!kick <username> : Kick user from chat group by username",
          "!kick (on reply) : Kick user from chat group by reply",
          "!silent (username|id|reply) : make a user silent",
          },
      admin = {
          "!banallgp user <user_id> : Ban user from all chat by id",
          "!banallgp user <username> : Ban user from all chat by username",
          "!banallgp (on reply) : Ban user from all chat by reply",
          "!banallgp delete <user_id> : Unban user",
          },
      },
  patterns = {
    "^/(ban) (.*)$",
    "^/(unban) (.*)$",
    "^/(unban)$",
    "^/(ban)$",
    "^/(sban) (.*)$",
    "^/(unsban) (.*)$",
    "^/(sban)$",
    "^/(kick) (.*)$",
    "^/(kick)$",
    "^/(kickme)$",
    "^/(silent) (.*)$", --only for supergroup
    "^/(silent)$",
    "^/(unsilent) (.*)$",
    "^/(unsilent)$", --till here
    "^!!tgservice (.+)$",
  }, 
  run = run,
  pre_process = pre_process
}