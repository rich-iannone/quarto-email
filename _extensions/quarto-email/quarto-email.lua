--[[
Extension for generating email components needed for Posit Connect

1. extracts the subject line of the email from a div with the class `subject` 
2. takes a div from a Quarto HTML document that has the class `email`, places that in
   a specially-crafted HTML-email template
3. takes all references to images (i.e, image tags) and replaces them with CID
   (Content-ID) tags. When embedding an image in an HTML email, rather than linking
   to the image file on a server, the image is encoded and included directly in the
   message.
4. identifies all associated images (e.g., PNGs) in the email portion of the document
   (as some may exist outside of the email context/div and creates Base64 encoded strings;
   we must also include mime-type information
5. generates a JSON file which contains specific email message components that Posit
   Connect is expecting for its own email generation code
]]


-- Define function for Base64-encoding of an image file
function base64_encode(data)
  local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  return ((data:gsub(".", function(x)
    local r, b = "", x:byte()
    for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
    return r;
  end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
    if (#x < 6) then return "" end
    local c = 0
    for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
    return b:sub(c + 1, c + 1)
  end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

-- Define path for images associated with figures
local figure_html_path = "report_files/figure-html"

local html_email_template_top = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"> <!-- utf-8 works for most cases -->
<meta name="viewport" content="width=device-width"> <!-- Forcing initial-scale shouldn't be necessary -->
<meta http-equiv="X-UA-Compatible" content="IE=edge"> <!-- Use the latest (edge) version of IE rendering engine -->
<meta name="x-apple-disable-message-reformatting">  <!-- Disable auto-scale in iOS 10 Mail entirely -->
<meta name="format-detection" content="telephone=no,address=no,email=no,date=no,url=no"> <!-- Tell iOS not to automatically link certain text strings. -->
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<!-- What it does: Makes background images in 72ppi Outlook render at correct size. -->
<!--[if gte mso 9]>
<xml>
<o:OfficeDocumentSettings>
<o:AllowPNG/>
<o:PixelsPerInch>96</o:PixelsPerInch>
</o:OfficeDocumentSettings>
</xml>
<![endif]-->
]]

-- <title>$if(title-prefix)$$title-prefix$ - $endif$$pagetitle$</title>

local html_email_template_style = [[
<style>
body {
font-family: Helvetica, sans-serif;
font-size: 14px;
}
.content {
background-color: white;
}
.content .message-block {
margin-bottom: 24px;
}
.header .message-block, .footer message-block {
margin-bottom: 12px;
}
img {
max-width: 100%;
}
@media only screen and (max-width: 767px) {
.container {
width: 100%;
}
.articles, .articles tr, .articles td {
display: block;
width: 100%;
}
.article {
margin-bottom: 24px;
}
}
</style>
</head>
]]

local html_email_template_body_1 = [[
<body style="background-color:#f6f6f6;font-family:Helvetica, sans-serif;color:#222;margin:0;padding:0;">
<table width="85%" align="center" class="container" style="max-width: $content-width$;">
<tr>
<td style="padding:24px;">
<div class="header" style="font-family:Helvetica, sans-serif;color:#999999;font-size:12px;font-weight:normal;margin:0 0 24px 0;text-align:center;">
]]

--$for(include-before)$
--$include-before$
--$endfor$

local html_email_template_body_2 = [[
</div>
<table width="100%" class="content" style="background-color:white;">
<tr>
]]

-- <td style="padding:12px;">email_body</td>

local html_email_template_body_3 = [[
</tr>
</table>
<div class="footer" style="font-family:Helvetica, sans-serif;color:#999999;font-size:12px;font-weight:normal;margin:24px 0 0 0;">
]]

-- $for(include-after)$
-- $include-after$
-- $endfor$
-- $if(rsc-footer)$
-- $if(include-after)$
-- <hr/>$endif$

local html_email_template_bottom = [[
<p>If HTML documents are attached, they may not render correctly when viewed in some email clients. For a better experience, download HTML documents to disk before opening in a web browser.</p>
</div>
</td>
</tr>
</table>
</body>
</html>
]]

local subject = nil
local attachments = nil
local email_html = nil

-- TODO:
--   use a parameter to control whether to produce the contents
--   of the email div as the output, or everything but the email
--   div as the output

function Meta(meta)
  attachments = {}
  for _, v in pairs(meta.attachments) do
    table.insert(attachments, pandoc.utils.stringify(v))
  end

  -- etc.
  meta["rsc-report-rendering-url"] = "..."
end

function Div(div)
  if div.classes:includes("subject") then
    subject = pandoc.utils.stringify(div)
    return {}
  elseif div.classes:includes("email") then
    email_html = extract_div_html(div)
  end
end

-- function to extract the rendered HTML from a Div of class 'email'
function extract_div_html(doc)
  return pandoc.write(pandoc.Pandoc({ doc }), "html")
end

function process_document(doc)
  -- TODO: perform processing on the email HTML

  local connect_date_time = "2020-12-01 12:00:00"
  local connect_report_rendering_url = "http://www.example.com"
  local connect_report_url = "http://www.example.com"
  local connect_report_subscription_url = "http://www.example.com"

  -- The following regexes remove the surrounding <div> from the HTML text
  email_html = string.gsub(email_html, "^<div class=\"email\">", '')
  email_html = string.gsub(email_html, "</div>$", '')

  -- Use the Connect email template components along with the `email_html`
  -- fragment to forge the email HTML

  local html_email_body =
      html_email_template_top .. html_email_template_style ..
      html_email_template_body_1 .. html_email_template_body_2 .. 
      "<td style=\"padding:12px;\">" .. email_html .. "</td>" ..
      html_email_template_body_3 ..
      "<p>This message was generated on " .. connect_date_time .. ".</p>\n\n" ..
      "<p>This Version: <a href=\"" .. connect_report_rendering_url .. "\">" ..
      connect_report_rendering_url .. "</a><br/>" ..
      "Latest Version: <a href=\"" .. connect_report_url ..
      "\">$rsc-report-url$</a></p>\n\n" ..
      "<p>If you wish to stop receiving emails for this document, you may <a href=\"" ..
      connect_report_subscription_url .. "\">unsubscribe here</a>.</p>\n\n" .. 
      html_email_template_bottom

  print("Lines of HTML of email follows:\n" .. html_email_body)

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
