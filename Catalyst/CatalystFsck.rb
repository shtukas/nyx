
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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/MiningShips/MiningShips.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cube.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Quark.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"

# -------------------------------------------------------------------------

class CatalystFsck

    # CatalystFsck::entity(entity)
    def self.entity(entity)
        if entity["nyxType"] == "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721" then
            CatalystFsck::checkStarlightNode(entity)
            return
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" then
            CatalystFsck::checkCube(entity)
            return
        end
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            CatalystFsck::checkQuark(entity)
            return
        end
        raise "-[ 85884767-b32a-4d8f-8399-4c31edac6eda ]-"
    end

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
        puts JSON.pretty_generate(entity)
        supportedTypes = [
            "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721",
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
        CatalystFsck::entity(entity)
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
            mark = quark["mark"]
            location = AtlasCore::uniqueStringToLocationOrNull(mark)
            if location.nil? then
                puts "[error] could not identify target location for this quark mark".red
                puts JSON.pretty_generate(quark).red
                #exit
            end
        end
    end

    # CatalystFsck::checkAsteroid(asteroid)
    def self.checkAsteroid(asteroid)
        puts JSON.pretty_generate(asteroid)
        if asteroid["uuid"].nil? then
            puts "[error] asteroid has no uuid".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["nyxType"].nil? then
            puts "[error] asteroid has no nyxType".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["creationUnixtime"].nil? then
            puts "[error] asteroid has no creationUnixtime".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        # asteroid["description"]
        if asteroid["orbitalname"].nil? then
            puts "[error] asteroid has no orbitalname".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["orbitaluuid"].nil? then
            puts "[error] asteroid has no orbitaluuid".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["quarkuuid"].nil? then
            puts "[error] asteroid has no quarkuuid".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        quarkuuid = asteroid["quarkuuid"] # We are targetting Quarks
        quark = Nyx::getOrNull(quarkuuid)
        if quark.nil? then
            puts "[error] Asteroid has not known target quark".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        CatalystFsck::checkQuark(quark)
    end

    # CatalystFsck::checkMiningShip(miningship)
    def self.checkMiningShip(miningship)
        puts JSON.pretty_generate(miningship)
        if miningship["uuid"].nil? then
            puts "[error] miningship has no uuid".red
            puts JSON.pretty_generate(miningship).red
            exit
        end
        if miningship["nyxType"].nil? then
            puts "[error] miningship has no nyxType".red
            puts JSON.pretty_generate(miningship).red
            exit
        end
        if miningship["nyxType"] != "miningship-99a06996-dcad-49f5-a0ce-02365629e4fc" then
            puts "[error] miningship has incorrect nyxType".red
            puts JSON.pretty_generate(miningship).red
            exit
        end
        if miningship["cargo"].nil? then
            puts "[error] miningship has no cargo".red
            puts JSON.pretty_generate(miningship).red
            exit
        end

        cargoTypes = ["description", "asteroid", "quark"]
        if !cargoTypes.include?(miningship["cargo"]["type"]) then
            puts "[error] miningship has incorrect cargo type".red
            puts JSON.pretty_generate(miningship).red
            exit
        end

        if miningship["cargo"]["type"] == "quark" then
            quark = Nyx::getOrNull(miningship["cargo"]["quarkuuid"])
            if quark.nil? then
                puts "[error] MiningShip item has not known target quark".red
                puts JSON.pretty_generate(miningship).red
                exit
            end
            CatalystFsck::checkQuark(quark)
        end

        if miningship["engine"].nil? then
            puts "[error] miningship has no engine".red
            puts JSON.pretty_generate(miningship).red
            exit
        end

        engineTypes = ["time-commitment-on-curve", "time-commitment-indefinitely", "bank-account", "bank-account-special-circumstances", "arrow"]
        if !engineTypes.include?(miningship["engine"]["type"]) then
            puts "[error] miningship has incorrect engine type".red
            puts JSON.pretty_generate(miningship).red
            exit
        end
    end

    # CatalystFsck::checkStarlightNode(orbital)
    def self.checkStarlightNode(orbital)
        puts JSON.pretty_generate(orbital)
        if orbital["uuid"].nil? then
            puts "[error] starlight orbital has no uuid".red
            puts JSON.pretty_generate(orbital).red
            exit
        end
        if orbital["nyxType"].nil? then
            puts "[error] starlight orbital has no nyxType".red
            puts JSON.pretty_generate(orbital).red
            exit
        end
        if orbital["nyxType"] != "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721" then
            puts "[error] starlight orbital has incorrect nyxType".red
            puts JSON.pretty_generate(orbital).red
            exit
        end
        if orbital["name"].nil? then
            puts "[error] starlight orbital has no name".red
            puts JSON.pretty_generate(orbital).red
            exit
        end
        if orbital["name"].strip.size == 0 then
            puts "[error] starlight orbital has empty name".red
            puts JSON.pretty_generate(orbital).red
            exit
        end
    end

    # CatalystFsck::checkCube(cube)
    def self.checkCube(cube)
        puts JSON.pretty_generate(cube)
        if cube["uuid"].nil? then
            puts "[error] starlight cube has no uuid".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        if cube["nyxType"].nil? then
            puts "[error] starlight cube has no nyxType".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        if cube["nyxType"] != "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" then
            puts "[error] starlight cube has incorrect nyxType".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        if cube["description"].nil? then
            puts "[error] starlight orbital has no description".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        if cube["quarksuuids"].nil? then
            puts "[error] starlight quarksuuids has empty name".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        cube["quarksuuids"].each{|quarkuuid|
            quark = Quark::getOrNull(quarkuuid)
            if quark.nil? then
                puts "[error] starlight points as a null quark".red
                puts JSON.pretty_generate(cube).red
                puts "quarkuuid: #{quarkuuid}".red
                exit
            end
            CatalystFsck::checkQuark(quark)
        }
        if cube["tags"].nil? then
            puts "[error] starlight tags has empty name".red
            puts JSON.pretty_generate(cube).red
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
        Asteroids::asteroids().each{|asteroid|
            CatalystFsck::checkAsteroid(asteroid)
        }
        MiningShips::miningships().each{|miningship|
            CatalystFsck::checkMiningShip(miningship)
        }
        Orbitals::orbitals().each{|orbital|
            CatalystFsck::checkStarlightNode(orbital)
        }
        Cube::cubes().each{|cube|
            CatalystFsck::checkCube(cube)
        }
        puts "-> Completed Catalyst Integrity Check".green
    end
end
