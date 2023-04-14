
-- for development:
local p = quarto.utils.dump

-- Take all text in a code block marked with `email` and transform it to an
-- HTML string using a template 

return {
  {
    Div = function(el)
      
      if not el.attr.classes:includes("email") then
        return el
      end

      p(el.classes)

      return el
  end
}}


