-- Unix-style wildcard path queries
wildcard = {}
local function escape_pattern(pattern_string)
  return pattern_string:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
end

local function parse(query_string)
  local tokenized = query_string
    :gsub("%*%*", "__DOUBLE_WILDCARD__")
    :gsub("%*", "__WILDCARD__")
    :gsub("%?", "__ANY_CHAR__")
  -- Then escape any magic characters.
  local escaped = escape_pattern(tokenized)
  -- Finally, replace tokens with true magic-character patterns.
  -- Double-asterisk will traverse any number of characters to make a match.
  -- single-asterisk will only traverse non-slash characters (i.e. in same dir).
  -- the ? will match any single character.
  local pattern = escaped
    :gsub("__DOUBLE_WILDCARD__", ".+")
    :gsub("__WILDCARD__", "[^/]+")
    :gsub("__ANY_CHAR__", ".")

  -- Make sure pattern matches from beginning of string.
  local bounded = "^" .. pattern

  return bounded
end
wildcard.parse = parse
