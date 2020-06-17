
# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

# -----------------------------------------------------------------------------

class OpenCycles

    # OpenCycles::issueFromQuark(quark)
    def self.issueFromQuark(quark)
        opencycle = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
            "creationUnixtime" => Time.new.to_f,
            "targetuuid"       => quark["uuid"]
        }
        NyxIO::commitToDisk(opencycle)
        opencycle
    end

    # OpenCycles::issueFromCube(cube)
    def self.issueFromCube(cube)
        opencycle = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
            "creationUnixtime" => Time.new.to_f,
            "targetuuid"       => cube["uuid"]
        }
        NyxIO::commitToDisk(opencycle)
        opencycle
    end

    # OpenCycles::issueFromClique(clique)
    def self.issueFromClique(clique)
        opencycle = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
            "creationUnixtime" => Time.new.to_f,
            "targetuuid"       => clique["uuid"]
        }
        NyxIO::commitToDisk(opencycle)
        opencycle
    end

    # OpenCycles::opencycles()
    def self.opencycles()
        NyxIO::objects("open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f")
    end

    # OpenCycles::getOpenCyclesByTargetUUID(targetuuid)
    def self.getOpenCyclesByTargetUUID(targetuuid)
        OpenCycles::opencycles()
            .select{|opencycle| opencycle["targetuuid"] == targetuuid }
    end

    # OpenCycles::openQuark(opencycle)
    def self.openQuark(opencycle)
        entity = NyxIO::getOrNull(opencycle["targetuuid"])
        return if entity.nil?
        NyxDataCarriers::objectDive(entity)
    end

    # OpenCycles::opencycleToString(opencycle)
    def self.opencycleToString(opencycle)
        target = NyxIO::getOrNull(opencycle["targetuuid"])
        if target.nil? then
            return "[opencycle] [#{opencycle["uuid"][0, 4]}] target not found"
        end
        target = NyxDataCarriers::applyQuarkToCubeUpgradeIfRelevant(target)
        "[opencycle] [#{opencycle["uuid"][0, 4]}] #{NyxDataCarriers::objectToString(target)}"
    end

    # OpenCycles::opencycleDive(opencycle)
    def self.opencycleDive(opencycle)
        loop {
            system("clear")
            puts OpenCycles::opencycleToString(opencycle)
            entity = NyxIO::getOrNull(opencycle["targetuuid"])
            if entity.nil? then
                puts "Could not determine entity for opencycle:"
                puts JSON.pretty_generate(opencycle)
            end
            options = [
                "access target",
                "destroy opencycle"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "access target" then
                entity = NyxIO::getOrNull(opencycle["targetuuid"])
                if entity.nil? then
                    puts "I could not find a entity for his: #{opencycle}"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                NyxDataCarriers::objectDive(entity)
            end
            if option == "destroy opencycle" then
                NyxIO::destroy(opencycle["uuid"])
                return
            end
        }
    end

    # OpenCycles::main()
    def self.main()
        loop {
            system("clear")
            puts "OpenCycles 🗃️"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("opencycle", ["dive opencycles", "make new opencycle"])
            return if operation.nil?
            if operation == "dive opencycles" then
                loop {
                    opencycle = LucilleCore::selectEntityFromListOfEntitiesOrNull("opencycle", OpenCycles::opencycles(), lambda {|opencycle| OpenCycles::opencycleToString(opencycle) })
                    break if opencycle.nil?
                    OpenCycles::opencycleDive(opencycle)
                }
            end
            if operation == "make new opencycle" then
                puts "You can't make an opencycle, but you can opencycle a cube or a clique."
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end


