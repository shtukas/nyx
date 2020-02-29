# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

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

# ----------------------------------------------------------------------

class NSXTodoItemsTypes

    # NSXTodoItemsTypes::determineTypeProfile(foldername, itemname): TypeProfile
    def self.determineTypeProfile(foldername, itemname)
        location = "/Users/pascal/Galaxy/Todo/#{foldername}/#{itemname}"
        typeProfile = {}
        typeProfile["foldername"] = foldername
        typeProfile["itemname"] = itemname
        if File.directory?(location) then
            typeProfile["type"] = "folder"
            return typeProfile
        end
        if itemname[-9, 9] == ".todo.txt" then
            typeProfile["type"] = "todo-text-file"
            return typeProfile
        end
        if itemname[-4, 4] == ".txt" then
            typeProfile["type"] = "generic-text-file"
            return typeProfile
        end
        if [".jpg", ".png", ".eml"].include?(itemname[-4, 4]) then
            typeProfile["type"] = "non-text-openeable"
            return typeProfile
        else
            typeProfile["type"] = "non-text-non-openeable"
            return typeProfile
        end
        raise "[error] 1bc6eeda"
    end

    # NSXTodoItemsTypes::typeProfileToContentItem(typeProfile, runningAsTimeStringOrNull): ContentItem
    def self.typeProfileToContentItem(typeProfile, runningAsTimeStringOrNull)
        location = "/Users/pascal/Galaxy/Todo/#{typeProfile["foldername"]}/#{typeProfile["itemname"]}"
        line  = "[todo] #{typeProfile["foldername"]} / #{typeProfile["itemname"]}" + ( runningAsTimeStringOrNull ? " [#{runningAsTimeStringOrNull}]" : "" )
        if typeProfile["type"] == "todo-text-file" then
            return {
                "type" => "line-and-body",
                "line" => line,
                "body" => [
                              line,
                              IO.read(location).lines.first(10).join()
                          ].join("\n")
            }
        end
        if typeProfile["type"] == "generic-text-file" then
            return {
                "type" => "line-and-body",
                "line" => line,
                "body" => [
                              line,
                              IO.read(location).lines.first(10).join()
                          ].join("\n")
            }
        end
        if typeProfile["type"] == "non-text-openeable" then
            return         {
            "type" => "line",
            "line" => line + " [openable]"
        }
        end
        {
            "type" => "line",
            "line" => line
        }
    end

    # NSXTodoItemsTypes::typeProfileToCommands(typeProfile, isRunning)
    def self.typeProfileToCommands(typeProfile, isRunning)
        if !isRunning then
            return ["start"]
        end
        if typeProfile["type"] == "todo-text-file" then
            return ["[]", "open", "stop", "destroy"]
        end
        if typeProfile["type"] == "generic-text-file" then
            return ["open", "stop", "destroy"]
        end
        if typeProfile["type"] == "non-text-openeable" then
            return ["open", "stop", "destroy"]
        end
        ["stop"]
    end

end
