
-- package.path = package.path .. ";../luasocket/?.lua;" 

-- local mime = require("mime")

-- local subject = nil
-- local attachments = nil

-- local headers = {
--   to = "recipient@example.com",
--   from = "sender@example.com",
--   subject = "HTML Email",
--   ["content-type"] = "text/html; charset=utf-8",
-- }

-- local body = [[
--   <html>
--       <head>
--           <title>HTML Email</title>
--       </head>
--       <body>
--           <h1>This is an HTML email.</h1>
--           <p>Welcome to my email message!</p>
--       </body>
--   </html>
-- ]]

-- print(body)

-- Create the email message
-- local msg = mime.create(headers, body)

-- Print the email message
-- print(msg)



function Meta(meta)
    attachments = {}
    for _, v in pairs(meta.attachments) do
        table.insert(attachments, pandoc.utils.stringify(v))
    end
end

function Div(div)
    if div.classes:includes("subject") then
        subject = pandoc.utils.stringify(div)
        return {}
    end
end

function process_document(doc)
  local str = quarto.json.encode({
      hello = "world",
      subject = subject,
      attachments = attachments
  })
  io.open(".connect-email.json", "w"):write(str):close()
end

function Pandoc(doc)

    process_document(doc)

    -- print JSON document (mostly for development purposes)
    local json_file = io.open(".connect-email.json", "r")
    if json_file then
    local contents = json_file:read("*all")
    json_file:close()
    print(contents)
else
    print("Error: could not open file")
end

end
