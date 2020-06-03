
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystFsck.rb"

require 'json'
# JSON.pretty_generate(object)

require 'time'
require 'date'
require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# -----------------------------------------------------------------

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/Wave.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/TimePods.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cube.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Quark.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"

# -------------------------------------------------------------------------

class CatalystFsck

    # CatalystFsck::checkOpenCycle(opencycle)
    def self.checkOpenCycle(opencycle)
        puts JSON.pretty_generate(opencycle)
        targetuuid = opencycle["targetuuid"]
        entity = Nyx::getOrNull(targetuuid)
        if entity.nil? then
            puts "[error] open cycle".red
            puts JSON.pretty_generate(opencycle).red
            puts "... points as an unkown entity".red
            exit
        end
        supportedTypes = [
            "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2"
        ]
        if !supportedTypes.include?(entity["nyxType"]) then
            puts "[error] open cycle".red
            puts JSON.pretty_generate(opencycle).red
            puts "... points as an unsupported entity".red
            puts JSON.pretty_generate(entity).red
            exit
        end
    end

    # CatalystFsck::checkWave(wave)
    def self.checkWave(wave)
        puts JSON.pretty_generate(wave)
        if wave["uuid"].nil? then
            puts "[error] wave has no uuid".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["nyxType"].nil? then
            puts "[error] wave has no nyxType".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["creationUnixtime"].nil? then
            puts "[error] wave has no creationUnixtime".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["description"].nil? then
            puts "[error] wave has no description".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["schedule"].nil? then
            puts "[error] wave has no schedule".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        schedule = wave["schedule"]
    end

    # CatalystFsck::checkQuark(quark)
    def self.checkQuark(quark)
        puts JSON.pretty_generate(quark)
        if quark["uuid"].nil? then
            puts "[error] quark has no uuid".red
            puts JSON.pretty_generate(quark).red
            exit
        end
        if quark["nyxType"].nil? then
            puts "[error] quark has no nyxType".red
            puts JSON.pretty_generate(quark).red
            exit
        end
        if quark["nyxType"] != "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            puts "[error] quark has incorrected nyxType".red
            puts JSON.pretty_generate(quark).red
            exit
        end
        # quark["description"]
        if quark["type"].nil? then
            puts "[error] quark has no type".red
            puts JSON.pretty_generate(quark).red
            exit
        end
        types = ["line", "url", "file", "folder", "unique-name", "directory-mark"]
        if !types.include?(quark["type"]) then
            puts "[error] quark has incorrect type".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        if quark["type"] == "line" then
            if quark["line"].nil? then
                puts "[error] quark has no line".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "url" then
            if quark["url"].nil? then
                puts "[error] quark has no url".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "file" then
            if quark["filename"].nil? then
                puts "[error] quark has no filename".red
                puts JSON.pretty_generate(quark).red
                exit
            end
            if !CoreDataFile::exists?(quark["filename"]) then
                puts "[error] Targetted file doesn't exists".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "folder" then
            if quark["foldername"].nil? then
                puts "[error] quark has no foldername".red
                puts JSON.pretty_generate(quark).red
                exit
            end
            if !CoreDataDirectory::exists?(quark["foldername"]) then
                puts "[error] Targetted foldername doesn't exists".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "unique-name" then
            if quark["name"].nil? then
                puts "[error] quark has no name".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "directory-mark" then
            if quark["mark"].nil? then
                puts "[error] quark has no mark".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end
    end

    # CatalystFsck::checkTodoItem(todoitem)
    def self.checkTodoItem(todoitem)
        puts JSON.pretty_generate(todoitem)
        if todoitem["uuid"].nil? then
            puts "[error] todoitem has no uuid".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        if todoitem["nyxType"].nil? then
            puts "[error] todoitem has no nyxType".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        if todoitem["creationUnixtime"].nil? then
            puts "[error] todoitem has no creationUnixtime".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        # todoitem["description"]
        if todoitem["projectname"].nil? then
            puts "[error] todoitem has no projectname".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        if todoitem["projectuuid"].nil? then
            puts "[error] todoitem has no projectuuid".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        if todoitem["contentuuid"].nil? then
            puts "[error] todoitem has no contentuuid".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        contentuuid = todoitem["contentuuid"] # We are targetting Quark
        quark = Nyx::getOrNull(contentuuid)
        if quark.nil? then
            puts "[error] Todo item has not known target quark".red
            puts JSON.pretty_generate(todoitem).red
            exit
        end
        CatalystFsck::checkQuark(quark)
    end

    # CatalystFsck::checkTimePod(timepod)
    def self.checkTimePod(timepod)
        puts JSON.pretty_generate(timepod)
        if timepod["uuid"].nil? then
            puts "[error] timepod has no uuid".red
            puts JSON.pretty_generate(timepod).red
            exit
        end
        if timepod["nyxType"].nil? then
            puts "[error] timepod has no nyxType".red
            puts JSON.pretty_generate(timepod).red
            exit
        end
        if timepod["nyxType"] != "timepod-99a06996-dcad-49f5-a0ce-02365629e4fc" then
            puts "[error] timepod has incorrect nyxType".red
            puts JSON.pretty_generate(timepod).red
            exit
        end
        if timepod["passenger"].nil? then
            puts "[error] timepod has no passenger".red
            puts JSON.pretty_generate(timepod).red
            exit
        end

        passengerTypes = ["description", "todo-item", "quark"]
        if !passengerTypes.include?(timepod["passenger"]["type"]) then
            puts "[error] timepod has incorrect passenger type".red
            puts JSON.pretty_generate(timepod).red
            exit
        end

        if timepod["passenger"]["type"] == "quark" then
            quark = Nyx::getOrNull(timepod["passenger"]["quarkuuid"])
            if quark.nil? then
                puts "[error] TimePod item has not known target quark".red
                puts JSON.pretty_generate(timepod).red
                exit
            end
            CatalystFsck::checkQuark(quark)
        end

        if timepod["engine"].nil? then
            puts "[error] timepod has no engine".red
            puts JSON.pretty_generate(timepod).red
            exit
        end

        engineTypes = ["time-commitment-on-curve", "on-going-project", "bank-account", "bank-account-special-circumstances"]
        if !engineTypes.include?(timepod["engine"]["type"]) then
            puts "[error] timepod has incorrect engine type".red
            puts JSON.pretty_generate(timepod).red
            exit
        end

    end

    # CatalystFsck::run()
    def self.run()
        OpenCycles::opencycles().each{|opencycle|
            CatalystFsck::checkOpenCycle(opencycle)
        }
        Wave::waves().each{|wave|
            CatalystFsck::checkWave(wave)
        }
        Todo::todoitems().each{|todoitem|
            CatalystFsck::checkTodoItem(todoitem)
        }
        TimePods::timepods().each{|timepod|
            CatalystFsck::checkTimePod(timepod)
        }
        puts "-> Completed Catalyst Integrity Check".green
    end
end
