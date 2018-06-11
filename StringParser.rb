
# encoding: UTF-8

# ----------------------------------------------------------------------

# StringParser::decompose(string): [null, null] or (token, null) or (token, rest) where rest is non empty

class StringParser
    def self.decompose(string)
        string = string.strip
        if string.size==0 then
            return [nil, nil]
        end
        spacepos = string.index(" ")
        if spacepos.nil? then
            return [string, nil]
        end
        token = string[0, spacepos].strip
        rest = string[spacepos, string.size].strip
        [token, rest]
    end
end


