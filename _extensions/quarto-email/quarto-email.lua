local subject = nil
local attachments = nil

function process_document(doc)
    local str = quarto.json.encode({
        hello = "world",
        subject = subject,
        attachments = attachments
    })
    io.open(".connect-email.json", "w"):write(str):close()
end

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

function Pandoc(doc)
    process_document(doc)
end
