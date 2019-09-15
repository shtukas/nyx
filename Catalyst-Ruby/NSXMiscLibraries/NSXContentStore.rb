#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
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

class NSXContentStore

    # NSXContentStore::getItemOrNull(contentStoreItemId: String): ContentStoreItem or null
    def self.getItemOrNull(contentStoreItemId)
        sha1hash = Digest::SHA1.hexdigest(contentStoreItemId)
        pathfragment = "#{sha1hash[0,2]}/#{sha1hash[2,2]}/#{sha1hash}.json"
        filepath = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Content-Store/Content/#{pathfragment}"
        if !File.exists?(filepath) then
            return nil
        end
        JSON.parse(IO.read(filepath))
    end

    # NSXContentStore::setItem(contentStoreItemId, contentStoreItem)
    def self.setItem(contentStoreItemId, contentStoreItem)
        sha1hash = Digest::SHA1.hexdigest(contentStoreItemId)
        pathfragment = "#{sha1hash[0,2]}/#{sha1hash[2,2]}/#{sha1hash}.json"
        filepath = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Content-Store/Content/#{pathfragment}"
        contentStoreItemAsString = JSON.pretty_generate(contentStoreItem)
        if File.exists?(filepath) and (IO.read(filepath) == contentStoreItemAsString) then
            # We avoid rewriting a file whose content have not changed
            return
        end
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(contentStoreItemAsString) }
    end

end


class NSXContentStoreUtils

    # NSXContentStoreUtils::itemToAnnounce(item)
    def self.itemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["line"]
        end
        "[8f854b3a] I don't know how to announce: #{JSON.generate(item)}"
    end

    # NSXContentStoreUtils::itemToBody(item)
    def self.itemToBody(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["body"]
        end
        "[09bab884] I don't know how to body: #{JSON.generate(item)}"
    end

    # NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(contentStoreItemId)
    def self.contentStoreItemIdToAnnounceOrNull(contentStoreItemId)
        item = NSXContentStore::getItemOrNull(contentStoreItemId)
        return "NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(#{contentStoreItemId})" if item.nil?
        NSXContentStoreUtils::itemToAnnounce(item)
    end

    # NSXContentStoreUtils::contentStoreItemIdToBodyOrNull(contentStoreItemId)
    def self.contentStoreItemIdToBodyOrNull(contentStoreItemId)
        item = NSXContentStore::getItemOrNull(contentStoreItemId)
        return "NSXContentStoreUtils::contentStoreItemIdToBodyOrNull(#{contentStoreItemId})" if item.nil?
        NSXContentStoreUtils::itemToBody(item)
    end

end