do

local function callback(extra, success, result)
	vardump(success)
end

local function is_spromoted(chat_id, user_id)
  local hash =  'sprom:'..chat_id..':'..user_id
  local spromoted = redis:get(hash)
  return spromoted or false
end

local function spromote(receiver, user_id, username)
  local chat_id = string.gsub(receiver, '.+#id', '')
  local data = load_data(_config.moderation.data)
  if not data[tostring(chat_id)] then
    return send_large_msg(receiver, 'Group is not added.')
  end
  if data[tostring(chat_id)]['moderators'][tostring(user_id)] then
    if is_spromoted(chat_id, user_id) then
      return send_large_msg(receiver, 'Already as moderator leader')
    end
    local hash =  'sprom:'..chat_id..':'..user_id
  redis:set(hash, true)
  send_large_msg(receiver, 'User '..username..' ['..user_id..'] promoted as moderator leader')
  return
  else
    data[tostring(chat_id)]['moderators'][tostring(user_id)] = string.gsub(username, '@', '')
    save_data(_config.moderation.data, data)
    local hash =  'sprom:'..chat_id..':'..user_id
    redis:set(hash, true)
    send_large_msg(receiver, 'User '..username..' ['..user_id..'] promoted as moderator leader')
    return
  end
end

local function sdemote(receiver, user_id, username)
  local chat_id = string.gsub(receiver, '.+#id', '')
  if not is_spromoted(chat_id, user_id) then
    return send_large_msg(receiver, 'Not a moderator leader')
  end
  local data = load_data(_config.moderation.data)
  data[chat_id]['moderators'][tostring(user_id)] = nil
  save_data(_config.moderation.data, data)
  local hash =  'sprom:'..chat_id..':'..user_id
  redis:del(hash)
  send_large_msg(receiver, 'User '..username..' ['..user_id..'] demoted!')
end

local function check_member(cb_extra, success, result)
   local receiver = cb_extra.receiver
   local data = cb_extra.data
   local msg = cb_extra.msg
   for k,v in pairs(result.members) do
      local user_id = v.id
      if user_id ~= our_id then
          local username = v.username
          data[tostring(msg.to.id)] = {
            moderators ={},
            settings = {
              set_name = string.gsub(msg.to.print_name, '_', ' '),
              lock_name = 'no',
              lock_photo = 'no',
              lock_member = 'no',
              lock_bot = 'yes',
              lock_link = 'no',
              lock_inviteme = 'no',
              lock_sticker = 'no',
              lock_image = 'no',
              --lock_video = 'no',
              --lock_audio = 'no',
              lock_file = 'no',
              lock_talk = 'no'
            },
            group_type = msg.to.type,
            blocked_words = {},
          }
          save_data(_config.moderation.data, data)
				  local hash =  'sprom:'..msg.to.id..':'..user_id
	        redis:set(hash, true)
          return send_large_msg(receiver, 'You have been promoted as moderator for this group.')
      end
    end
end

local function modadd(msg)
  if not is_admin(msg) then
    return
  end
  local data = load_data(_config.moderation.data)
  if data[tostring(msg.to.id)] then
    return 'Group is already added.'
  end
  data[tostring(msg.to.id)] = {
    moderators ={},
    settings = {
      set_name = string.gsub(msg.to.print_name, '_', ' '),
      lock_name = 'no',
      lock_photo = 'no',
      lock_member = 'no',
      lock_bot = 'yes',
      lock_link = 'no',
      lock_inviteme = 'no',
      lock_sticker = 'no',
      lock_image = 'no',
      --lock_video = 'no',
      --lock_audio  = 'no',
      lock_file = 'no',
      lock_talk = 'no',
    },
    group_type = msg.to.type,
    blocked_words = {},
  }
  save_data(_config.moderation.data, data)
  return 'Group has been added.'
end

local function modrem(msg)
  if not is_admin(msg) then
    return "You're not admin"
  end
  local data = load_data(_config.moderation.data)
  local receiver = get_receiver(msg)
  if not data[tostring(msg.to.id)] then
    return 'Group is not added.'
  end

  data[tostring(msg.to.id)] = nil
  save_data(_config.moderation.data, data)

  return 'Group has been removed'
end

local function promote(receiver, username, user_id)
  local data = load_data(_config.moderation.data)
  local group = string.gsub(receiver, '.+#id', '')
  if not data[group] then
    return send_large_msg(receiver, 'Group is not added.')
  end
  if data[group]['moderators'][tostring(user_id)] then
    return send_large_msg(receiver, username..' is already a moderator.')
    end
    data[group]['moderators'][tostring(user_id)] = string.gsub(username, '@', '')
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, username..' has been promoted.')
end

local function demote(receiver, username, user_id)
  local data = load_data(_config.moderation.data)
  local group = string.gsub(receiver, '.+#id', '')
  if not data[group] then
    return send_large_msg(receiver, 'Group is not added.')
  end
  if not data[group]['moderators'][tostring(user_id)] then
    return send_large_msg(receiver, string.gsub(username, '@', '')..' is not a moderator.')
  end
  data[group]['moderators'][tostring(user_id)] = nil
  save_data(_config.moderation.data, data)
  return send_large_msg(receiver, username..' has been demoted.')
end

local function upmanager(receiver, username, user_id)
  channel_set_admin(receiver, 'user#id'..user_id, callback, false)
  return send_large_msg(receiver, 'Done!')
end

local function inmanager(receiver, username, user_id)
  channel_set_unadmin(receiver, 'user#id'..user_id, callback, false)
  return send_large_msg(receiver, 'Done!')
end

local function admin_promote(receiver, username, user_id)  
  local data = load_data(_config.moderation.data)
  if not data['admins'] then
    data['admins'] = {}
    save_data(_config.moderation.data, data)
  end

  if data['admins'][tostring(user_id)] then
    return send_large_msg(receiver, username..' is already as admin.')
  end
  
  data['admins'][tostring(user_id)] = string.gsub(username, '@', '')
  save_data(_config.moderation.data, data)
  return send_large_msg(receiver, username..' has been promoted as admin.')
end

local function admin_demote(receiver, username, user_id)
    local data = load_data(_config.moderation.data)
  if not data['admins'] then
    data['admins'] = {}
    save_data(_config.moderation.data, data)
  end

  if not data['admins'][tostring(user_id)] then
    return send_large_msg(receiver, username..' is not an admin.')
  end

  data['admins'][tostring(user_id)] = nil
  save_data(_config.moderation.data, data)

  return send_large_msg(receiver, 'Admin '..username..' has been demoted.')
end

local function username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local member = cb_extra.member
   local text = 'No user @'..member..' in this group.'
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
        username = member
        user_id = v.peer_id
        if get_cmd == 'promote' then
            return promote(receiver, username, user_id)
        elseif get_cmd == 'demote' then
          if is_spromoted(string.gsub(receiver,'.+#id', ''), user_id) then
            return send_large_msg(receiver, 'Can\'t demote leader')
          end
          return demote(receiver, username, user_id)
        elseif get_cmd == 'adminprom' then
          if user_id == our_id then
            return
          end
          return admin_promote(receiver, username, user_id)
        elseif get_cmd == 'admindem' then
          if user_id == our_id then
            return
          end
          return admin_demote(receiver, username, user_id)
        elseif get_cmd == 'spromote' then
          return spromote(receiver, user_id, username)
        elseif get_cmd == 'sdemote' then
          return sdemote(receiver, user_id, username)
        end
      end
   end
   send_large_msg(receiver, text)
end

local function channel_username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local member = cb_extra.member
   local text = 'No user @'..member..' in this group.'
   for k,v in pairs(result) do
      vusername = v.username
      if vusername == member then
        username = member
        user_id = v.peer_id
        if get_cmd == 'promote' then
          return promote(receiver, username, user_id)
        elseif get_cmd == 'demote' then
          if is_spromoted(string.gsub(receiver,'.+#id', ''), user_id) then
            return send_large_msg(receiver, 'Can\'t demote leader')
          end
          return demote(receiver, username, user_id)
        elseif get_cmd == 'adminprom' then
          if user_id == our_id then
            return
          end
          return admin_promote(receiver, username, user_id)
        elseif get_cmd == 'admindem' then
          if user_id == our_id then
            return
          end
          return admin_demote(receiver, username, user_id)
        elseif get_cmd == 'spromote' then
          return spromote(receiver, user_id, username)
        elseif get_cmd == 'sdemote' then
          return sdemote(receiver, user_id, username)
        elseif get_cmd == 'upmanager' then
          return upmanager(receiver, username, user_id)
        elseif get_cmd == 'inmanager' then
          return inmanager(receiver, username, user_id)
        end
      end
   end
   send_large_msg(receiver, text)
end

local function get_msg_callback(extra, success, result)
  if success ~= 1 then return end
  local get_cmd = extra.get_cmd
  local receiver = extra.receiver
  local user_id = result.from.peer_id
  local chat_id = result.to.id
  if result.from.username then
    username = '@'..result.from.username
  else
    username = string.gsub(result.from.print_name, '_', ' ')
  end
  if get_cmd == 'spromote' then
    if user_id == our_id then
      return nil
    end
    return spromote(receiver, user_id, username)
  end
  if get_cmd == 'sdemote' then
    if user_id == our_id then
      return nil
    end
    return sdemote(receiver, user_id, username)
  end
  if get_cmd == 'promote' then
    if user_id == our_id then
      return nil
    end
    return promote(receiver, username, user_id)
  end
  if get_cmd == 'demote' then
    if user_id == our_id then
      return nil
    end
    if is_spromoted(chat_id, user_id) then
      return send_large_msg(receiver, 'Can\'t demote leader')
    end
    return demote(receiver, username, user_id)
  end
  if get_cmd == 'upmanager' then
    return upmanager(receiver, username, user_id)
  end
  if get_cmd == 'inmanager' then
    return inmanager(receiver, username, user_id)
  end
end

local function modlist(msg)
  local data = load_data(_config.moderation.data)
  if not data[tostring(msg.to.id)] then
    return 'Group is not added.'
  end
  -- determine if table is empty
  if next(data[tostring(msg.to.id)]['moderators']) == nil then --fix way
    return 'No moderator in this group.'
  end
  local message = 'List of moderators for ' .. string.gsub(msg.to.print_name, '_', ' ') .. ':\n'
  for k,v in pairs(data[tostring(msg.to.id)]['moderators']) do
    if is_spromoted(msg.to.id, k) then
      message = message .. '- '..v..' [' ..k.. '] * \n'
    else
      message = message .. '- '..v..' [' ..k.. '] \n'
    end
  end

  return message
end

local function admin_list(msg)
    local data = load_data(_config.moderation.data)
  if not data['admins'] then
    data['admins'] = {}
    save_data(_config.moderation.data, data)
  end
  if next(data['admins']) == nil then --fix way
    return 'No admin available.'
  end
  local message = 'List for Bot admins:\n'
  for k,v in pairs(data['admins']) do
    message = message .. '- ' .. v ..' ['..k..'] \n'
  end
  return message
end

function run(msg, matches)
  if is_chat_msg(msg) then
    local get_cmd = matches[1]
    local receiver = get_receiver(msg)
    if matches[1] == 'modadd' then
      return modadd(msg)
    end
    
    if matches[1] == 'modrem' then
      return modrem(msg)
    end
    
    if matches[1] == 'promote' then
      if not is_momod(msg) then
        return
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      local member = string.gsub(matches[2], "@", "")
      chat_info(receiver, username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'demote' then
      if not is_momod(msg) then
        return "Only moderator can demote"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.gsub(matches[2], "@", "") == msg.from.username then
        return "You can't demote yourself"
      end
      local member = string.gsub(matches[2], "@", "")
      chat_info(receiver, username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'spromote' then
      if not is_admin(msg) then
        return "Only admin can promote moderator leader"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      local member = string.gsub(matches[2], "@", "")
      chat_info(receiver, username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'sdemote' then
      if not is_admin(msg) then
        return "Only moderator can demote moderator leader"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return sdemote(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      chat_info(receiver, username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'modlist' then
      return modlist(msg)
    end
    
    if matches[1] == 'adminprom' then
      if not is_admin(msg) then
        return "Only sudo can promote user as admin"
      end
      local member = string.gsub(matches[2], "@", "")
      chat_info(receiver, username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'admindem' then
      if not is_admin(msg) then
        return "Only sudo can promote user as admin"
      end
      if string.match(matches[2], '^%d+$') then
        admin_demote(receiver, matches[2], matches[2])
      else
        local member = string.gsub(matches[2], "@", "")
        chat_info(receiver, username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
      end
    end
    
    if matches[1] == 'adminlist' then
      if not is_admin(msg) then
        return 'Admin only!'
      end
      return admin_list(msg)
    end
    
    if matches[1] == 'chat_add_user' and msg.action.user.id == our_id then
      chat_del_user(receiver, 'user#id'..our_id, ok_cb, true)
    end
    
    if matches[1] == 'chat_created' and msg.from.id == 0 then
      --return automodadd(msg)
    end
  end
  if is_channel_msg(msg) then -- supergrouuuuppppppppp
    local get_cmd = matches[1]
    local receiver = get_receiver(msg)
    if matches[1] == 'modadd' then
      return modadd(msg)
    end
    
    if matches[1] == 'modrem' then
      return modrem(msg)
    end
    
    if matches[1] == 'promote' then
      if not is_momod(msg) then
        return
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'demote' then
      if not is_momod(msg) then
        return "Only moderator can demote"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.gsub(matches[2], "@", "") == msg.from.username then
        return "You can't demote yourself"
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'spromote' then
      if not is_admin(msg) then
        return "Only admin can promote moderator leader"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'sdemote' then
      if not is_admin(msg) then
        return "Only moderator can demote moderator leader"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return sdemote(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'modlist' then
      return modlist(msg)
    end
    
    if matches[1] == 'upmanager' then
      if not is_admin(msg) then
        if not is_spromoted(msg.to.id, msg.from.id) then
          return "You're not a leader"
        end
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return upmanager(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'inmanager' then
      if not is_admin(msg) then
        if not is_spromoted(msg.to.id, msg.from.id) then
          return "You're not a leader"
        end
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return sdemote(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'adminprom' then
      if not is_admin(msg) then
        return "Only sudo can promote user as admin"
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'admindem' then
      if not is_admin(msg) then
        return "Only sudo can promote user as admin"
      end
      if string.match(matches[2], '^%d+$') then
        admin_demote(receiver, matches[2], matches[2])
      else
        local member = string.gsub(matches[2], "@", "")
        channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
      end
    end
    
    if matches[1] == 'adminlist' then
      if not is_admin(msg) then
        return 'Admin only!'
      end
      return admin_list(msg)
    end
    
    if matches[1] == 'chat_add_user' and msg.action.user.id == our_id then
      channel_kick_user(receiver, 'user#id'..our_id, ok_cb, true)
    end
  else
    return
  end
end

return {
  description = "Moderation plugin", 
  usage = {
      user = {
          "/modlist : List of moderators",
          },
      moderator = {
          "/promote <username> : Promote user as moderator by username",
          "/promote (on reply) : Promote user as moderator by reply",
          "/demote <username> : Demote user from moderator",
          "/demote (on reply) : demote user from moderator by reply",
          },
      admin = {
          "/modadd : Add group to moderation list",
          "/modrem : Remove group from moderation list",
          "/spromote <username> : Promote user as moderator leader by username",
          "/spromote (on reply) : Promote user as moderator leader by reply",
          "/sdemote <username> : Demote user from being moderator leader by username",
          "/sdemote (on reply) : Demote user from being moderator leader by reply",
          },
      sudo = {
          "/adminprom <username> : Promote user as admin (must be done from a group)",
          "/admindem <username> : Demote user from admin (must be done from a group)",
          "/admindem <id> : Demote user from admin (must be done from a group)",
          },
      },
  patterns = {
    "^/(modadd)$",
    "^/(modrem)$",
    "^/(spromote) (.*)$",
    "^/(spromote)$",
    "^/(sdemote) (.*)$",
    "^/(sdemote)$",
    "^/(promote) (.*)$",
    "^/(promote)$",
    "^/(demote) (.*)$",
    "^/(demote)$",
    "^/(upmanager) (.*)$",
    "^/(upmanager)",
    "^/(inmanager) (.*)$",
    "^/(inmanager)",
    "^/(modlist)$",
    "^/(adminprom) (.*)$", -- sudoers only
    "^/(admindem) (.*)$", -- sudoers only
    "^/(adminlist)$",
    "^!!tgservice (chat_add_user)$",
    "^!!tgservice (chat_created)$",
  }, 
  run = run,
}

end