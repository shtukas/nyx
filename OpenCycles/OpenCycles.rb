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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cube.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

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
        Nyx::commitToDisk(opencycle)
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
        Nyx::commitToDisk(opencycle)
        opencycle
    end

    # OpenCycles::opencycles()
    def self.opencycles()
        Nyx::objects("open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f")
    end

    # OpenCycles::openQuark(opencycle)
    def self.openQuark(opencycle)
        entity = QuarksCubesAndStarlightNodes::getObjectByUuidOrNull(opencycle["targetuuid"])
        return if entity.nil?
        QuarksCubesAndStarlightNodes::openObject(entity)
    end

    # OpenCycles::opencycleToString(opencycle)
    def self.opencycleToString(opencycle)
        entity = QuarksCubesAndStarlightNodes::getObjectByUuidOrNull(opencycle["targetuuid"])
        "[opencycle] #{entity ? QuarksCubesAndStarlightNodes::objectToString(entity) : "data entity not found"}"
    end

    # OpenCycles::opencycleDive(opencycle)
    def self.opencycleDive(opencycle)
        loop {
            puts JSON.pretty_generate(opencycle)
            entity = QuarksCubesAndStarlightNodes::getObjectByUuidOrNull(opencycle["targetuuid"])
            if entity.nil? then
                puts "Could not determine entity for opencycle #{opencycle}"
                LucilleCore::pressEnterToContinue()
                return
            end
            options = [
                "access target",
                "destroy opencycle"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "access target" then
                entity = QuarksCubesAndStarlightNodes::getObjectByUuidOrNull(opencycle["targetuuid"])
                if entity.nil? then
                    puts "I could not find a entity for his: #{opencycle}"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                QuarksCubesAndStarlightNodes::objectDive(entity)
            end
            if option == "destroy opencycle" then
                Nyx::destroy(opencycle["uuid"])
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
                    opencycle = LucilleCore::selectEntityFromListOfEntitiesOrNull("opencycle", OpenCycles::opencycles(), lambda {|opencycle| "[#{opencycle["uuid"][0, 4]}] #{OpenCycles::opencycleToString(opencycle)}" })
                    break if opencycle.nil?
                    OpenCycles::opencycleDive(opencycle)
                }
            end
            if operation == "make new opencycle" then
                entity = QuarksCubesAndStarlightNodesMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
                opencycle = {
                    "uuid"             => SecureRandom.uuid,
                    "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
                    "creationUnixtime" => Time.new.to_f,
                    "targetuuid"       => entity["uuid"],
                }
                puts JSON.pretty_generate(opencycle)
                Nyx::commitToDisk(opencycle)
            end
        }
    end
end


