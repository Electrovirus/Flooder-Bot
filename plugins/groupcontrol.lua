do

-- make sure to set with value that not higher than stats.lua
local NUM_MSG_MAX = 4
local TIME_CHECK = 4 -- seconds

local function generate_link(cb_extra, success, result)
    local receiver = cb_extra.receiver
    local data = cb_extra.data
    local user_id = cb_extra.user_id
    local chat_id = string.gsub(receiver, '.+#id', '')
    if success == 0 then
      return send_large_msg(receiver, "Can't generate invite link for this group")
    end
    data[tostring(chat_id)]['link'] = result
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, 'Link sent by PM')
    return send_large_msg('user#id'..user_id,'=> '..result)
end

local function kick_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, function (data, success, result)
    if success ~= 1 then
      local text = 'I can\'t kick '..data.user..' but he should be kicked'
      send_msg(data.chat, '', ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function kick_user_chan(user_id, chat_id)
  local channel = 'channel#id'..chat_id
  local user = 'user#id'..user_id
  channel_kick_user(channel, user, function (data, success, result)
    if success ~= 1 then
      local text = 'I can\'t kick '..data.user..' but he should be kicked'
      send_msg(data.chat, '', ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function del_msg(msg_id)
    delete_msg(msg_id, ok_cb, false)
end

local function set_description(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local data_cat = 'description'
    data[tostring(msg.to.id)][data_cat] = deskripsi
    save_data(_config.moderation.data, data)

    return 'Set group description to:\n'..deskripsi
end

local function set_description_chan(msg, data, deskripsi)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local data_cat = 'description'
    data[tostring(msg.to.id)][data_cat] = deskripsi
    save_data(_config.moderation.data, data)
    channel_set_about('channel#id'..msg.to.id, deskripsi, ok_cb, false)
    return 'Set group description to:\n'..deskripsi
end

local function get_description(msg, data)
    local data_cat = 'description'
    if not data[tostring(msg.to.id)][data_cat] then
        return 'No description available.'
    end
    local about = data[tostring(msg.to.id)][data_cat]
    local about = string.gsub(msg.to.print_name, "_", " ")..':\n\n'..about
    return 'About '..about
end

local function set_rules(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local data_cat = 'rules'
    data[tostring(msg.to.id)][data_cat] = rules
    save_data(_config.moderation.data, data)

    return 'Set group rules to:\n'..rules
end

local function get_rules(msg, data)
    local data_cat = 'rules'
    if not data[tostring(msg.to.id)][data_cat] then
        return 'No rules available.'
    end
    local rules = data[tostring(msg.to.id)][data_cat]
    local rules = string.gsub(msg.to.print_name, '_', ' ')..' rules:\n\n'..rules
    return rules
end

local function lock_group_name(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_name_set = data[tostring(msg.to.id)]['settings']['set_name']
    local group_name_lock = data[tostring(msg.to.id)]['settings']['lock_name']
    if group_name_lock == 'yes' then
        return 'Group name is already locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_name'] = 'yes'
        save_data(_config.moderation.data, data)
        data[tostring(msg.to.id)]['settings']['set_name'] = string.gsub(msg.to.print_name, '_', ' ')
        save_data(_config.moderation.data, data)
    return 'Group name has been locked'
    end
end

local function unlock_group_name(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_name_set = data[tostring(msg.to.id)]['settings']['set_name']
    local group_name_lock = data[tostring(msg.to.id)]['settings']['lock_name']
    if group_name_lock == 'no' then
        return 'Group name is already unlocked'
    else
        data[tostring(msg.to.id)]['settings']['lock_name'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Group name has been unlocked'
    end
end

local function lock_group_member(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_member_lock = data[tostring(msg.to.id)]['settings']['lock_member']
    if group_member_lock == 'yes' then
        return 'Group members are already locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_member'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Group members has been locked'
end

local function unlock_group_member(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_member_lock = data[tostring(msg.to.id)]['settings']['lock_member']
    if group_member_lock == 'no' then
        return 'Group members are not locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_member'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Group members has been unlocked'
    end
end

local function lock_group_bot(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_bot_lock = data[tostring(msg.to.id)]['settings']['lock_bot']
    if group_bot_lock == 'yes' then
        return 'Anti bot already locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_bot'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Anti bot has been locked'
end

local function unlock_group_bot(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_bot_lock = data[tostring(msg.to.id)]['settings']['lock_bot']
    if group_bot_lock == 'no' then
        return 'Anti bot is not locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_bot'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Anti bot has been unlocked'
    end
end

local function lock_group_link(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_link_lock = data[tostring(msg.to.id)]['settings']['lock_link']
    if group_link_lock == 'yes' then
        return 'Anti link already locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_link'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Anti link has been locked'
end

local function unlock_group_link(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_link_lock = data[tostring(msg.to.id)]['settings']['lock_link']
    if group_link_lock == 'no' then
        return 'Anti link is not locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_link'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Anti link has been unlocked'
    end
end

local function lock_group_inviteme(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_inviteme_lock = data[tostring(msg.to.id)]['settings']['lock_inviteme']
    if group_inviteme_lock == 'yes' then
        return 'Join group already locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_inviteme'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Join group has been locked'
end

local function unlock_group_inviteme(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_inviteme_lock = data[tostring(msg.to.id)]['settings']['lock_inviteme']
    if group_inviteme_lock == 'no' then
        return 'Join group is not locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_inviteme'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Join group has been unlocked'
    end
end

local function lock_group_photo(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_photo_lock = data[tostring(msg.to.id)]['settings']['lock_photo']
    if group_photo_lock == 'yes' then
        return 'Group photo is already locked'
    else
        data[tostring(msg.to.id)]['settings']['set_photo'] = 'waiting'
        save_data(_config.moderation.data, data)
    end
    return 'Please send me the group photo now'
end

local function unlock_group_photo(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_photo_lock = data[tostring(msg.to.id)]['settings']['lock_photo']
    if group_photo_lock == 'no' then
        return 'Group photo is not locked'
    else
        data[tostring(msg.to.id)]['settings']['lock_photo'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Group photo has been unlocked'
    end
end

local function set_group_photo(msg, success, result)
  local data = load_data(_config.moderation.data)
  local receiver = get_receiver(msg)
  if success then
    local file = 'data/photos/chat_photo_'..msg.to.id..'.jpg'
    print('File downloaded to:', result)
    os.rename(result, file)
    print('File moved to:', file)
    chat_set_photo (receiver, file, ok_cb, false)
    data[tostring(msg.to.id)]['settings']['set_photo'] = file
    save_data(_config.moderation.data, data)
    data[tostring(msg.to.id)]['settings']['lock_photo'] = 'yes'
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, 'Photo saved!', ok_cb, false)
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
-- show group settings
local function show_group_settings(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    if msg.to.type == 'chat' then
        local settings = data[tostring(msg.to.id)]['settings']
        local wordlist = ''
        for k,v in pairs(data[tostring(msg.to.id)]['blocked_words']) do
            wordlist = wordlist..' / '..k
        end
        local text = "Group settings:\nLock group name : "..settings.lock_name.."\nLock group photo : "..settings.lock_photo.."\nLock group member : "..settings.lock_member.."\nLock bot : "..settings.lock_bot.."\nLock share link : "..settings.lock_link.."\nLock for public : "..settings.lock_inviteme.."\nAnti sticker : "..settings.lock_sticker.."\nLock share image : "..settings.lock_image.."\nLock share file : "..settings.lock_file.."\n\nBlocked words : "..wordlist
        return text
    else
        local settings = data[tostring(msg.to.id)]['settings']
        local wordlist = ''
        for k,v in pairs(data[tostring(msg.to.id)]['blocked_words']) do
            wordlist = wordlist..' / '..k
        end
        local text = "Group settings:\nLock group member : "..settings.lock_member.."\nLock bot : "..settings.lock_bot.."\nLock share link : "..settings.lock_link.."\nLock for public : "..settings.lock_inviteme.."\nAnti sticker : "..settings.lock_sticker.."\nLock share image : "..settings.lock_image.."\nLock share file : "..settings.lock_file.."\nLock talking : "..settings.lock_talk.."\n\nBlocked words : "..wordlist
        return text
    end
end

--lock/unlock anti sticker
local function lock_group_sticker(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_sticker_lock = data[tostring(msg.to.id)]['settings']['lock_sticker']
    if group_sticker_lock == 'yes' then
        return 'Anti sticker already enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_sticker'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Anti sticker has been enabled'
end

local function unlock_group_sticker(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_sticker_lock = data[tostring(msg.to.id)]['settings']['lock_sticker']
    if group_sticker_lock == 'no' then
        return 'Anti sticker is not enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_sticker'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Anti sticker has been disabled'
    end
end

local function lock_group_image(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_image_lock = data[tostring(msg.to.id)]['settings']['lock_image']
    if group_image_lock == 'yes' then
        return 'Image lock already enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_image'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Image lock has been enabled'
end

local function unlock_group_image(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_image_lock = data[tostring(msg.to.id)]['settings']['lock_image']
    if group_image_lock == 'no' then
        return 'Image lock is not enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_image'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Image lock has been disabled'
    end
end

--[[local function lock_group_video(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_video_lock = data[tostring(msg.to.id)]['settings']['lock_sticker']
    if group_video_lock == 'yes' then
        return 'Anti sticker already enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_sticker'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Anti sticker has been enabled'
end

local function unlock_group_video(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_video_lock = data[tostring(msg.to.id)]['settings']['lock_sticker']
    if group_video_lock == 'no' then
        return 'Anti sticker is not enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_sticker'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Anti sticker has been disabled'
    end
end

local function lock_group_audio(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_audio_lock = data[tostring(msg.to.id)]['settings']['lock_audio']
    if group_audio_lock == 'yes' then
        return 'Lock audio already enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_audio'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Lock audio has been enabled'
end

local function unlock_group_audio(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_audio_lock = data[tostring(msg.to.id)]['settings']['lock_audio']
    if group_audio_lock == 'no' then
        return 'Lock audio is not enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_audio'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Lock audio has been disabled'
    end
end]]

local function lock_group_file(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_file_lock = data[tostring(msg.to.id)]['settings']['lock_file']
    if group_file_lock == 'yes' then
        return 'Lock file already enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_file'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Lock file has been enabled'
end

local function unlock_group_file(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_file_lock = data[tostring(msg.to.id)]['settings']['lock_file']
    if group_file_lock == 'no' then
        return 'Lock file is not enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_file'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Lock file has been disabled'
    end
end

local function lock_group_talk(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_talk_lock = data[tostring(msg.to.id)]['settings']['lock_talk']
    if group_talk_lock == 'yes' then
        return 'Silent group already enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_talk'] = 'yes'
        save_data(_config.moderation.data, data)
    end
    return 'Silent group has been enabled'
end

local function unlock_group_talk(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    local group_talk_lock = data[tostring(msg.to.id)]['settings']['lock_talk']
    if group_talk_lock == 'no' then
        return 'Silent group is not enabled'
    else
        data[tostring(msg.to.id)]['settings']['lock_talk'] = 'no'
        save_data(_config.moderation.data, data)
    return 'Silent group has been disabled'
    end
end

local function lock_group_all(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    return 'lock all'
end

local function unlock_group_all(msg, data)
    if not is_momod(msg) then
        return "For moderators only!"
    end
    return 'unlock all'
end

local function is_word_allowed(chat_id,text)
  local var = true
  local data = load_data(_config.moderation.data)
  if not data[tostring(chat_id)] then
      return true
  end
  local wordlist = ''
  if data[tostring(chat_id)]['blocked_words'] then
    for k,v in pairs(data[tostring(chat_id)]['blocked_words']) do 
        if string.find(string.lower(text), string.lower(k)) then
            return false
        end
    end
  end
  return var
end

local function pre_process(msg)
    --vardump(msg)
    if not msg.text and msg.media then
    	msg.text = '['..msg.media.type..']'
    end
    if msg.to.type == 'chat' then
        local receiver = get_receiver(msg)
        -- spam detector
        local hash = 'floodc:'..msg.from.id..':'..msg.to.id
        redis:incr(hash)
        if msg.from.type == 'user' then
            local hash = 'user:'..msg.from.id..':floodc'
            local msgs = tonumber(redis:get(hash) or 0)
            if msgs > NUM_MSG_MAX then
                if not is_momod(msg) then
                    send_large_msg(receiver, 'Don\'t spam!')
                    chat_del_user(receiver, 'user#id'..msg.from.id, ok_cb, true)
                    msg = nil
                    return nil
                end
            end
            redis:setex(hash, TIME_CHECK, msgs+1)
        end
        -- end spam detect
        local data = load_data(_config.moderation.data)
        if not data[tostring(msg.to.id)] then
            return msg
        end
        local settings = data[tostring(msg.to.id)]['settings']
    	if msg.action and msg.action.type then
            local action = msg.action.type
            if action == 'chat_rename' then
                local group_name_set = settings.set_name
                local group_name_lock = settings.lock_name
                local to_rename = 'chat#id'..msg.to.id
                if group_name_lock == 'yes' then
                    if group_name_set ~= tostring(msg.to.print_name) then
                        rename_chat(to_rename, group_name_set, ok_cb, false)
                    end
                elseif group_name_lock == 'no' then
                    return nil
                end
            end
            if action == 'chat_add_user' or action == 'chat_add_user_link' then
                if msg.action.link_issuer then
                    user_id = 'user#id'..msg.from.id
                else
                    user_id = 'user#id'..msg.action.user.id
                end
                if settings.lock_member == 'yes' and msg.from.id ~= 0 and not is_momod(msg) then
                    local kick_a = chat_del_user(receiver, user_id, ok_cb, true)
                    local kick_b = chat_del_user(receiver, 'user#id'..msg.from.id, ok_cb, true)
                end
                if action == 'chat_add_user' and msg.action.user.flags == 1 then -- NEED FIX
                	if settings.lock_bot == 'yes' and not is_momod(msg) then
                		--chat_del_user(receiver, user_id, ok_cb, true)
                	end
                end
            end
        end
        if action == 'chat_delete_photo' then
            local group_photo_lock = settings.lock_photo
            if group_photo_lock == 'yes' then
                chat_set_photo(receiver, settings.set_photo, ok_cb, false)
            end
        end
        if action == 'chat_change_photo' and msg.from.id ~= 0 then
            local group_photo_lock = settings.lock_photo
            if group_photo_lock == 'yes' then
                chat_set_photo(receiver, settings.set_photo, ok_cb, false)
            end
        end
        if msg.media and not is_momod(msg) then
        	if msg.media.type == 'document' and msg.media.caption == 'sticker.webp' then
                if data[tostring(msg.to.id)]['settings']['lock_sticker'] == 'yes' then
                    kick_user(msg.from.id,msg.to.id)
                    return 'Don\'t send sticker'
                end
            end
            if msg.media.type == 'photo' then
                if data[tostring(msg.to.id)]['settings']['lock_image'] == 'yes' then
                    kick_user(msg.from.id,msg.to.id)
                    return 'Don\'t send image'
                end
            end
            if msg.media.type == 'document' then
                if data[tostring(msg.to.id)]['settings']['lock_file'] == 'yes' then
                    kick_user(msg.from.id,msg.to.id)
                    return 'Don\'t send file'
                end
            end
        end
        if is_word_allowed(msg.to.id, msg.text) then
            print('word allowed')
        else
            print('word is not allowed')
            if not is_momod(msg) then
                chat_del_user(receiver, 'user#id'..msg.from.id, ok_cb, true)
                return 'That word is not allowed'
            end
        end
        if string.find(msg.text, "https?://[%w-_%.%?%.:/%+=&]+") then
		    if is_momod(msg) then
			    print('link detected, but he is privileged user')
		    else
		        local data = load_data(_config.moderation.data)
                if data[tostring(msg.to.id)]['settings']['lock_link'] == 'yes' then
                    chat_del_user(receiver, 'user#id'..msg.from.id, ok_cb, true)
                    return 'Don\'t share link!'
                end
		    end
    	end
        return msg
    end
    if msg.to.type == 'channel' then -- THIS IS SUPERGROUPPPPPPPPPPPPPPPPPPPPP
        local receiver = get_receiver(msg)
        -- spam detect
        local hash = 'floodc:'..msg.from.id..':'..msg.to.id
        redis:incr(hash)
        if msg.from.type == 'user' then
            local hash = 'user:'..msg.from.id..':floodc'
            local msgs = tonumber(redis:get(hash) or 0)
            if msgs > NUM_MSG_MAX then
                if not is_momod(msg) then
                    send_large_msg(receiver, 'Don\'t spam!')
                    channel_kick_user(receiver, 'user#id'..msg.from.id, ok_cb, true)
                    delete_msg(msg.id, ok_cb, false)
                    msg = nil
                end
            end
            redis:setex(hash, TIME_CHECK, msgs+1)
        end
        -- spam detect
        local data = load_data(_config.moderation.data)
        if not data[tostring(msg.to.id)] then
            return msg
        end
        local settings = data[tostring(msg.to.id)]['settings']
        if settings.lock_talk == 'yes' then
            if not is_momod(msg) then
                return del_msg(msg.id)
            end
        end
        if msg.action and msg.action.type then
            local action = msg.action.type
            if action == 'chat_add_user' or action == 'chat_add_user_link' then
                if msg.action.link_issuer then
                    user_id = 'user#id'..msg.from.id
                else
                    user_id = 'user#id'..msg.action.user.id
                end
                if group_member_lock == 'yes' and msg.from.id ~= 0 and not is_momod(msg) then
                    channel_kick_user(receiver, user_id, ok_cb, true)
                end
                if action == 'chat_add_user' and msg.action.user.flags == 1 then -- Need fix
                	if settings.lock_bot == 'yes' and not is_momod(msg) then
                	    --channel_kick_user(receiver, user_id, ok_cb, true)
                	end
                end
            end
            return msg
        end
        if msg.media and not is_momod(msg) then
    		if msg.media.type == 'document' and msg.media.caption == 'sticker.webp' then
                if data[tostring(msg.to.id)]['settings']['lock_sticker'] == 'yes' then
                    delete_msg(msg.id, ok_cb, false)
                    return 'Don\'t send sticker'
                end
            end
            if msg.media.type == 'photo' then
                if data[tostring(msg.to.id)]['settings']['lock_image'] == 'yes' then
                    delete_msg(msg.id, ok_cb, false)
                    return 'Don\'t send image'
                end
            end
            if msg.media.type == 'document' then
                if data[tostring(msg.to.id)]['settings']['lock_file'] == 'yes' then
                    delete_msg(msg.id, ok_cb, false)
                    return 'Don\'t send file'
                end
            end
        end
        if is_word_allowed(msg.to.id, msg.text) then
            print('word allowed')
        else
            print('word is not allowed')
            if not is_momod(msg) then
                delete_msg(msg.id, ok_cb, false)
                return 'That word is not allowed'
            end
        end
        if string.find(msg.text, "https?://[%w-_%.%?%.:/%+=&]+") then
		    if is_momod(msg) then
			    print('link detected, but he is privileged user')
		    else
                if data[tostring(msg.to.id)]['settings']['lock_link'] == 'yes' then
                    delete_msg(msg.id, ok_cb, false)
                    return 'Don\'t share link!'
                end
		    end
    	end
        return msg
    end
    return msg
end

local function block_word(receiver, wordblock)
    local chat_id = string.gsub(receiver, '.+#id', '')
    local data = load_data(_config.moderation.data)
    data[tostring(chat_id)]['blocked_words'][(wordblock)] = true
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, 'Word "'..wordblock..'" has been added to blocked list.')
end

local function unblock_word(receiver, wordblock)
    local chat_id = string.gsub(receiver, '.+#id', '')
    local data = load_data(_config.moderation.data)
    if data[tostring(chat_id)]['blocked_words'][wordblock] then
        data[tostring(chat_id)]['blocked_words'][(wordblock)] = nil
        save_data(_config.moderation.data, data)
        send_large_msg(receiver, 'Word "'..wordblock..'" has been removed from blocked list.')
    else
        send_large_msg(receiver, 'Word "'..wordblock..'" isn\'t in blocked list.')
    end
end

function run(msg, matches)
	local data = load_data(_config.moderation.data)
    local receiver = get_receiver(msg)
    if is_chat_msg(msg) then
    	if msg.media and is_momod(msg) then
    		if msg.media.type == 'photo' and data[tostring(msg.to.id)] then
    			if data[tostring(msg.to.id)]['settings']['set_photo'] == 'waiting' then
    				load_photo(msg.id, set_group_photo, msg)
    			end
    		end
		end
        if data[tostring(msg.to.id)] then
        	local settings = data[tostring(msg.to.id)]['settings']
        	local get_cmd = matches[1]
            if matches[1] == 'block' and matches[2] then
                if not is_momod(msg) then
                    return "For moderators only!"
                end
                return block_word(receiver, matches[2])
            end
            if matches[1] == 'unblock' and matches[2] then
                if not is_momod(msg) then
                    return "For moderators only!"
                end
                return unblock_word(receiver, matches[2])
            end
            if matches[1] == 'getlink' then
                if not is_momod(msg) then
                    return "For moderators only!"
                end
                if data[tostring(msg.to.id)]['link'] then
                    local link = data[tostring(msg.to.id)]['link']
                    local text = string.gsub(msg.to.print_name, '_', ' ')..'\n'..link
                    send_large_msg('user#id'..msg.from.id, text)
                else
                    export_chat_link(receiver, generate_link, {receiver=receiver, data=data, user_id=msg.from.id})
                end
            end
            if matches[1] == 'relink'then
                if not is_momod(msg) then
                    return "Moderators only!"
                end
                if matches[2] == tostring(msg.to.id) then
                    export_chat_link(receiver, generate_link, {receiver=receiver, data=data, user_id=msg.from.id})
                else
                    return "Group ID didn't match. Reset invite link failed!"
                end
            end
            if matches[1] == 'setabout' and matches[2] then
                deskripsi = matches[2]
                return set_description(msg, data)
            end
            if matches[1] == 'about' then
                return get_description(msg, data)
            end
            if matches[1] == 'setrules' then
                rules = matches[2]
                return set_rules(msg, data)
            end
            if matches[1] == 'rules' then
                return get_rules(msg, data)
            end
            if matches[1] == 'close' then --group lock *
                if matches[2] == 'name' then
                    return lock_group_name(msg, data)
                end
                if matches[2] == 'member' then
                    return lock_group_member(msg, data)
                end
                if matches[2] == 'photo' then
                    return lock_group_photo(msg, data)
                end
                --if matches[2] == 'bot' then
                --	return lock_group_bot(msg, data)
                --end
                if matches[2] == 'link' then
                	return lock_group_link(msg, data)
                end
                if matches[2] == 'join' then
                	return lock_group_inviteme(msg, data)
                end
                if matches[2] == 'sticker' then
                	return lock_group_sticker(msg, data)
                end
                if matches[2] == 'image' then
                	return lock_group_image(msg, data)
                end
                if matches[2] == 'file' then
                	return lock_group_file(msg, data)
                end
                --if matches[2] == 'chat' then
                --	return lock_group_chat(msg, data)
                --end
                if matches[2] == 'all' then
                	return lock_group_all(msg, data)
                end
            end
            if matches[1] == 'open' then --group unlock *
                if matches[2] == 'name' then
                    return unlock_group_name(msg, data)
                end
                if matches[2] == 'member' then
                    return unlock_group_member(msg, data)
                end
                if matches[2] == 'photo' then
                    return unlock_group_photo(msg, data)
                end
                --if matches[2] == 'bot' then
                --	return unlock_group_bot(msg, data)
                --end
                if matches[2] == 'link' then
                	return unlock_group_link(msg, data)
                end
                if matches[2] == 'join' then
                	return unlock_group_inviteme(msg, data)
                end
                if matches[2] == 'sticker' then
                    return unlock_group_sticker(msg, data)
                end
                if matches[2] == 'image' then
                	return unlock_group_image(msg, data)
                end
                if matches[2] == 'file' then
                	return unlock_group_file(msg, data)
                end
                --if matches[2] == 'chat' then
                --	return unlock_group_chat(msg, data)
                --end
                if matches[2] == 'all' then
                	return unlock_group_all(msg, data)
                end
            end
            if matches[1] == 'group' and matches[2] == 'settings' then
                return show_group_settings(msg, data)
            end
            if matches[1] == 'setname' and is_momod(msg) then
                local new_name = string.gsub(matches[2], '_', ' ')
                data[tostring(msg.to.id)]['settings']['set_name'] = new_name
                save_data(_config.moderation.data, data) 
                local group_name_set = data[tostring(msg.to.id)]['settings']['set_name']
                local to_rename = 'chat#id'..msg.to.id
                rename_chat(to_rename, group_name_set, ok_cb, false)
            end
            if matches[1] == 'setphoto' and is_momod(msg) then
                data[tostring(msg.to.id)]['settings']['set_photo'] = 'waiting'
                save_data(_config.moderation.data, data)
                return 'Please send me new group photo now'
            end
        end
    end
    if is_channel_msg(msg) then -- For ChANNEL O SUPERGROUPSSSS
        if data[tostring(msg.to.id)] then
        	local settings = data[tostring(msg.to.id)]['settings']
        	local get_cmd = matches[1]
            if matches[1] == 'block' and matches[2] then
                if not is_momod(msg) then
                    return "For moderators only!"
                end
                return block_word(receiver, matches[2])
            end
            if matches[1] == 'unblock' and matches[2] then
                if not is_momod(msg) then
                    return "For moderators only!"
                end
                return unblock_word(receiver, matches[2])
            end
            if matches[1] == 'getlink' then
                if not is_momod(msg) then
                    return "For moderators only!"
                end
                if data[tostring(msg.to.id)]['link'] then
                    local link = data[tostring(msg.to.id)]['link']
                    local text = string.gsub(msg.to.print_name, '_', ' ')..'\n'..link
                    send_large_msg('user#id'..msg.from.id, text)
                else
                    export_channel_link(receiver, generate_link, {receiver=receiver, data=data, user_id=msg.from.id})
                end
            end
            if matches[1] == 'relink'then
                if not is_momod(msg) then
                    return "Moderators only!"
                end
                if matches[2] == tostring(msg.to.id) then
                    export_channel_link(receiver, generate_link, {receiver=receiver, data=data, user_id=msg.from.id})
                else
                    return "Group ID didn't match. Reset invite link failed!"
                end
            end
            if matches[1] == 'setabout' and matches[2] then
                local deskripsi = matches[2]
                return set_description_chan(msg, data, deskripsi)
            end
            if matches[1] == 'about' then
                return get_description(msg, data)
            end
            if matches[1] == 'setrules' then
                rules = matches[2]
                return set_rules(msg, data)
            end
            if matches[1] == 'rules' then
                return get_rules(msg, data)
            end
            if matches[1] == 'close' then --group lock *
                --[[if matches[2] == 'name' then
                    return lock_group_name(msg, data)
                end
                if matches[2] == 'member' then
                    return lock_group_member(msg, data)
                end
                if matches[2] == 'photo' then
                    return lock_group_photo(msg, data)
                end
                if matches[2] == 'bot' then
                	return lock_group_bot(msg, data)
                end]]
                if matches[2] == 'link' then
                	return lock_group_link(msg, data)
                end
                if matches[2] == 'join' then
                	return lock_group_inviteme(msg, data)
                end
                if matches[2] == 'sticker' then
                	return lock_group_sticker(msg, data)
                end
                if matches[2] == 'image' then
                	return lock_group_image(msg, data)
                end
                if matches[2] == 'file' then
                	return lock_group_file(msg, data)
                end
                if matches[2] == 'chat' then
                	return lock_group_talk(msg, data)
                end
                --if matches[2] == 'all' then
                --	return lock_group_all(msg, data)
                --end
            end
            if matches[1] == 'open' then --group unlock *
                --[[if matches[2] == 'name' then
                    return unlock_group_name(msg, data)
                end
                if matches[2] == 'member' then
                    return unlock_group_member(msg, data)
                end
                if matches[2] == 'photo' then
                    return unlock_group_photo(msg, data)
                end
                if matches[2] == 'bot' then
                	return unlock_group_bot(msg, data)
                end]]
                if matches[2] == 'link' then
                	return unlock_group_link(msg, data)
                end
                if matches[2] == 'join' then
                	return unlock_group_inviteme(msg, data)
                end
                if matches[2] == 'sticker' then
                    return unlock_group_sticker(msg, data)
                end
                if matches[2] == 'image' then
                	return unlock_group_image(msg, data)
                end
                if matches[2] == 'file' then
                	return unlock_group_file(msg, data)
                end
                if matches[2] == 'chat' then
                    return unlock_group_talk(msg, data)
                end
                --if matches[2] == 'all' then
                --	return unlock_group_all(msg, data)
                --end
            end
            if matches[1] == 'group' and matches[2] == 'settings' then
                return show_group_settings(msg, data)
            end
            --[[if matches[1] == 'setname' and is_momod(msg) then
                local new_name = string.gsub(matches[2], '_', ' ')
                data[tostring(msg.to.id)]['settings']['set_name'] = new_name
                save_data(_config.moderation.data, data) 
                local group_name_set = data[tostring(msg.to.id)]['settings']['set_name']
                local to_rename = 'chat#id'..msg.to.id
                rename_chat(to_rename, group_name_set, ok_cb, false)
            end
            if matches[1] == 'setphoto' and is_momod(msg) then
                data[tostring(msg.to.id)]['settings']['set_photo'] = 'waiting'
                save_data(_config.moderation.data, data)
                return 'Please send me new group photo now'
            end]]
        end
    else
        if matches[1] == 'join' and matches[2] then
            if string.match(matches[2], '^%d+$') then
                if not data[tostring(matches[2])] then
                    return 'Group id is not recognized'
                end
                if data[tostring(matches[2])]['settings']['lock_inviteme'] == 'yes' then
                    return 'Sorry, group is locked, i cant invite you'
                else
                    if data[tostring(matches[2])]['group_type'] == 'chat' then
                        chat_add_user("chat#id"..matches[2], "user#id"..msg.from.id, callback, false)
                    else
                        channel_invite_user("channel#id"..matches[2], "user#id"..msg.from.id, callback, false)
                    end
                end
            end
        end
    end
end


return {
  description = "Plugin to manage group chat.", 
  usage = {
      user = {
          "/about : Read group description",
          "/rules : Read group rules",
          },
      moderator = {
          "/block <word> : Block word in group",
          "/unblock <word> : Unblock word from blocked list",
          "/getlink : Show group invite link",
          "/relink <group_id> : Reset group invite link",
          "/setabout <description> : Set group description",
          "/setrules <rules> : Set group rules",
          "/setname <new_name> : Set group name",
          "/setphoto : Set group photo",
          "/<close|open> name : Lock/unlock group name",
          "/<close|open> photo : Lock/unlock group photo",
          "/<close|open> member : Lock/unlock group member",
          "/<close|open> spam : Enable/disable spam protection",
          "/<close|open> sticker : Enable/disable anti sticker",
          "/<close|open> antilink : Enable/disable anti link",
          "/group settings : Show group settings",
          "/join <group id> : Join to any group by ID (if not locked)",
          },
      },
  patterns = {
    "^/(block) (.+)$",
    "^/(unblock) (.+)$",
    "^/(getlink)$",
    "^/(relink) (.+)$",
    "^/(setabout) (.*)$",
    "^/(about)$",
    "^/(setrules) (.*)$",
    "^/(rules)$",
    "^/(setname) (.*)$",
    "^/(setphoto)$",
    "^/(close) (.*)$",
    "^/(open) (.*)$",
    "^/(group) (settings)$",
    "^/(join) (.+)$",
    "%[(photo)%]",
    "%[(document)%]",
    
  }, 
  run = run,
  pre_process = pre_process
}

end