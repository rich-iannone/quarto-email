-- Extension for generating email components for Posit Connect

local subject = nil
local attachments = nil

-- TODO:
--   use a parameter to control whether to produce the contents
--   of the email div as the output, or everything but the email
--   div as the output

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
  elseif div.classes:includes("email") then
    local html = extract_div_html(div)
    print("extracted html")
    print(html)
    print(string.len(html))
    print(type(html))
  end
end

-- function to extract the rendered HTML from a Div of class 'email'
-- this requires a 
function extract_div_html(doc)
  -- local html = ""
  -- local function walk_block(block)
  --   if block.t == "Div" then
  --   --if block.t == "Div" and block.classes:includes("email") then
  --     local writer = pandoc.writer.new("html")
  --     html = writer(block.content)
  --   end
  --   return block
  -- end
  -- pandoc.walk_block(doc, {walk_block = walk_block})
  -- return html

  return pandoc.write(pandoc.Pandoc({doc}), "html")
end

function process_document(doc)
  local str = quarto.json.encode({
    rsc_email_subject = subject,
    rsc_email_attachments = attachments,
    rsc_email_suppress_report_attachment = true,
    rsc_email_suppress_scheduled = false
  })
  io.open("connect-email.json", "w"):write(str):close()
end

function Pandoc(doc)

  -- local rendering_email = get_option() -- TODO
  -- if rendering_email then
  --   -- make the content of doc be only the content of the .email div    
  -- else
  --   -- remove the .email div from doc
  -- end

    process_document(doc)

    -- print JSON document (this is mostly for development purposes)
    local json_file = io.open("connect-email.json", "r")
    if json_file then
        local contents = json_file:read("*all")
        json_file:close()
        print(contents)
    else
        print("Error: could not open file")
    end

end
