
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

class NSX1ContentsItemUtils

    # NSX1ContentsItemUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["line"]
        end
        if item["type"] == "atlas-reference" then
            return item["announce"]
        end
        "[8f854b3a] I don't know how to announce: #{JSON.generate(item)}"
    end

    # NSX1ContentsItemUtils::contentItemToBody(item)
    def self.contentItemToBody(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["body"]
        end
        if item["type"] == "atlas-reference" then
            fileContent = NSXAtlasReferenceUtils::referenceToFileContentsOrNull(item["atlas-reference"])
            if fileContent.nil? then
                return "Could not determine atlas-reference: #{item["atlas-reference"]}, for '#{item["announce"]}'"
            else
                return [
                    item["announce"],
                    "atlas reference: #{item["atlas-reference"]}",
                    "file".green + ":",
                    fileContent.lines.first(10).map{|line| "        #{line}" }.join("\n")
                ].join("\n")
            end
        end
        "[09bab884] I don't know how to body: #{JSON.generate(item)}"
    end

end

