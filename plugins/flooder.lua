local function run(msg, matches)
  if is_chat_msg(msg) then
    local text = [[‌إێنجام ڊٱۺ💀]]
    return text
  end
  if is_channel_msg(msg) then
    local text = [[‌‌ٱېڹڃٵم ډٵۺ💀]]
    return text
  else
    local text = [[aaa]]
    --return text
  end
end

return {
  description = "Help plugin. Get info from other plugins.  ", 
  usage = {
    "!help: Show list of plugins.",
  },
  patterns = {
    "^[Ff](looder)$",
  }, 
  run = run,
}
