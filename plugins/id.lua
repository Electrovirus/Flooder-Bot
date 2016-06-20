#addplug local function run(msg, matches)
     if matches[1]:lower() == '!id' and is_sudo(msg) then
  text = "!id"
  reply_msg(msg.id, text, ok_cb, false)
 end
end
return {
  patterns = {
       "^[!]id$",
  },
  run = run,
} 333
