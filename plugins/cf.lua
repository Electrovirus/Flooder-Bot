do
 local function save_file(name, text)
    local file = io.open("./data/"..name, "w")
    file:write(text)
    file:flush()
    file:close()
end   
function run(msg, matches)
  if matches[1] == "createfile" and is_sudo(msg) then
 
         local name = matches[2]
        local text = matches[3]
        return save_file(name, text)
    end
   end
return {
  patterns = {
  "^[/!](createfile) ([^%s]+) (.+)$"

  },
  run = run
}
end
