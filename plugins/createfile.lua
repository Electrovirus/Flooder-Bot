local function run(msg, matches)
  if matches[1] == "createfile" then
    local file = matches[2]
    if is_sudo(msg) then
      local receiver = get_receiver(msg)
      send_document(receiver, "./data/"..file, ok_cb, false)
    end
  end
end

return {
  patterns = {
    "^[/!](createfile) ([^%s]+) (.+)$"
  },
  run = run
}
