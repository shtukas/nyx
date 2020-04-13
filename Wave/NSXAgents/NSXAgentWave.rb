
# encoding: UTF-8

require 'json'

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Zeta.rb"
=begin
    Zeta::makeNewFile(filepath)
    Zeta::set(filepath, key, value)
    Zeta::getOrNull(filepath, key)
    Zeta::destroy(filepath, key)
=end

# ----------------------------------------------------------------------

class NSXAgentWave

    # NSXAgentWave::agentuid()
    def self.agentuid()
        "283d34dd-c871-4a55-8610-31e7c762fb0d"
    end

    # NSXAgentWave::getObjects()
    def self.getObjects()
        NSXAgentWave::getAllObjects()
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .reverse
    end

    # NSXAgentWave::getAllObjects()
    def self.getAllObjects()
        NSXWaveUtils::catalystUUIDsEnumerator()
            .map{|uuid| NSXWaveUtils::makeCatalystObjectOrNull(uuid) }
    end

    def self.processObjectAndCommand(objectuuid, command)

        if command == 'open' then
            filepath = NSXWaveUtils::catalystUUIDToItemFilepathOrNull(objectuuid)
            return if filepath.nil?
            text = Zeta::getOrNull(filepath, "text").strip
            puts text
            if text.lines.to_a.size == 1 and text.start_with?("http") then
                url = text
                if NSXMiscUtils::isLucille18() then
                    system("open '#{url}'")
                else
                    system("open -na 'Google Chrome' --args --new-window '#{url}'")
                end
                return
            end
            if text.lines.to_a.size > 1 then
                LucilleCore::pressEnterToContinue()
                return
            end
            return
        end

        if command == 'done' then
            NSXWaveUtils::performDone2(objectuuid)
            return
        end

        if command == 'recast' then
            schedule = NSXWaveUtils::makeNewSchedule()
            NSXWaveUtils::writeScheduleToZetaFile(objectuuid, schedule)
            return
        end

        if command.start_with?('description:') then
            _, description = NSXStringParser::decompose(command)
            if description.nil? then
                puts "usage: description: <description>"
                LucilleCore::pressEnterToContinue()
                return
            end
            NSXWaveUtils::setItemDescription(objectuuid, description)
            return
        end

        if command == 'destroy' then
            if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                NSXWaveUtils::sendItemToBin(objectuuid)
                return
            end
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentWave",
            "agentuid"    => NSXAgentWave::agentuid(),
        }
    )
rescue
end
