# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Interface/Ordinals.rb"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/SectionsType0141.rb"
# SectionsType0141::contentToSections(text)
# SectionsType0141::applyNextTransformationToContent(content)

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxGarbageCollection.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/VideoStream/VideoStream.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Drives.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx.v2/NyxSets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Interface/Floats.rb"

# ------------------------------------------------------------------------

class Ordinals

    # Ordinals::ordinalToString(ordinal)
    def self.ordinalToString(ordinal)
        if ordinal["type"] == "ordinal-description-cc686a4e-d634-476f-bc03-6a41cda4344a" then
            return "[ordinal] (#{ordinal["position"]}) #{ordinal["description"]}"
        end
        if ordinal["type"] == "ordinal-quark-58558d36-12d4-459c-b220-24d8cbd10bf8" then
            quarkuuid = ordinal["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark then
                return "[ordinal] (#{ordinal["position"]}) #{Quarks::quarkToString(quark)}"
            else
                return "[ordinal] (#{ordinal["position"]}) [quark] not found (#{quarkuuid})"
            end
        end
        if ordinal["type"] == "ordinal-own-quark-ca833db7-1dd4-45bf-aac0-c26c7dc73214" then
            quarkuuid = ordinal["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark then
                return "[ordinal] (#{ordinal["position"]}) #{Quarks::quarkToString(quark)}"
            else
                return "[ordinal] (#{ordinal["position"]}) [quark] not found (#{quarkuuid})"
            end
        end
        if ordinal["type"] == "ordinal-float-e0b15f62-c8ed-4b86-addd-7345cbe46f92" then
            floatuuid = ordinal["floatuuid"]
            float = Floats::getOrNull(floatuuid)
            if float then
                return "[ordinal] (#{ordinal["position"]}) #{Floats::floatToString(float)}"
            else
                return "[ordinal] (#{ordinal["position"]}) [float] not found (#{asteroiduuid})"
            end
        end
        if ordinal["type"] == "ordinal-asteroid-d55fdefa-f1ee-4d45-b705-1145dc55bf4b" then
            asteroiduuid = ordinal["asteroiduuid"]
            asteroid = Asteroids::getOrNull(asteroiduuid)
            if asteroid then
                return "[ordinal] (#{ordinal["position"]}) #{Asteroids::asteroidToString(asteroid)}"
            else
                return "[ordinal] (#{ordinal["position"]}) [quark] not found (#{asteroiduuid})"
            end
        end
        if ordinal["type"] == "ordinal-wave-0a5c011f-4e95-4c01-8eae-e3df7ba44fd9" then
            waveuuid = ordinal["waveuuid"]
            wave = Waves::getOrNull(waveuuid)
            if wave then
                return "[ordinal] (#{ordinal["position"]}) #{Waves::waveToString(wave)}"
            else
                return "[ordinal] (#{ordinal["position"]}) [wave] not found (#{waveuuid})"
            end
        end
        raise "[error: 5060d61a-0403-44ab-9136-848ff30c42f8] #{ordinal}"
    end

    # Ordinals::commitToDisk(ordinal)
    def self.commitToDisk(ordinal)
        NyxSets::putObject(ordinal)
    end

    # Ordinals::issueOrdinal()
    def self.issueOrdinal()
        ms = LCoreMenuItemsNX1.new()
        ms.item(
            "description", 
            lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description.size == 0
                position = LucilleCore::askQuestionAnswerAsString("ordinal position: ").to_f
                ordinal = {
                    "uuid"        => SecureRandom.hex,
                    "nyxNxSet"    => "0fb6e397-ca40-4188-8375-6ea95ede34cf",
                    "position"    => position,
                    "type"        => "ordinal-description-cc686a4e-d634-476f-bc03-6a41cda4344a",
                    "description" => description
                }
                Ordinals::commitToDisk(ordinal)
            }
        )
        ms.item(
            "quark (new)", 
            lambda {

                position = LucilleCore::askQuestionAnswerAsString("ordinal position: ")
                return if position.size == 0
                position = position.to_f

                quark = Quarks::issueNewQuarkInteractivelyOrNull()
                return if quark.nil?

                ordinal = {
                    "uuid"       => SecureRandom.hex,
                    "nyxNxSet"   => "0fb6e397-ca40-4188-8375-6ea95ede34cf",
                    "position"   => position,
                    "type"       => "ordinal-own-quark-ca833db7-1dd4-45bf-aac0-c26c7dc73214",
                    "quarkuuid"  => quark["uuid"]
                }
                Ordinals::commitToDisk(ordinal)
            }
        )
        ms.prompt()
    end

    # Ordinals::issueQuarkAsOrdinalInteractively(quark)
    def self.issueQuarkAsOrdinalInteractively(quark)
        position = LucilleCore::askQuestionAnswerAsString("ordinal position: ")
        return nil if position.size == 0
        position = position.to_f
        ordinal = {
            "uuid"       => SecureRandom.hex,
            "nyxNxSet"   => "0fb6e397-ca40-4188-8375-6ea95ede34cf",
            "position"   => position,
            "type"       => "ordinal-quark-58558d36-12d4-459c-b220-24d8cbd10bf8",
            "quarkuuid"  => quark["uuid"]
        }
        Ordinals::commitToDisk(ordinal)
    end

    # Ordinals::issueFloatInteractivelyAsOrdinalInteractively(float)
    def self.issueFloatInteractivelyAsOrdinalInteractively(float)

        position = LucilleCore::askQuestionAnswerAsString("ordinal position: ")
        return nil if position.size == 0
        position = position.to_f

        ordinal = {}
        ordinal["uuid"]      = SecureRandom.hex
        ordinal["nyxNxSet"]  = "0fb6e397-ca40-4188-8375-6ea95ede34cf"
        ordinal["position"]  = position
        ordinal["type"]      = "ordinal-float-e0b15f62-c8ed-4b86-addd-7345cbe46f92"
        ordinal["floatuuid"] = float["uuid"]

        Ordinals::commitToDisk(ordinal)
    end

    # Ordinals::issueAsteroidAsOrdinalInteractively(asteroid)
    def self.issueAsteroidAsOrdinalInteractively(asteroid)
        position = LucilleCore::askQuestionAnswerAsString("ordinal position: ")
        return nil if position.size == 0
        position = position.to_f

        ordinal = {}
        ordinal["uuid"] = SecureRandom.hex
        ordinal["nyxNxSet"] = "0fb6e397-ca40-4188-8375-6ea95ede34cf"
        ordinal["position"] = position

        ordinal["type"] = "ordinal-asteroid-d55fdefa-f1ee-4d45-b705-1145dc55bf4b"
        ordinal["asteroiduuid"] = asteroid["uuid"]

        Ordinals::commitToDisk(ordinal)
    end

    # Ordinals::issueWaveAsOrdinalInteractively(wave)
    def self.issueWaveAsOrdinalInteractively(wave)
        position = LucilleCore::askQuestionAnswerAsString("ordinal position: ")
        return nil if position.size == 0
        position = position.to_f

        ordinal = {}
        ordinal["uuid"] = SecureRandom.hex
        ordinal["nyxNxSet"] = "0fb6e397-ca40-4188-8375-6ea95ede34cf"
        ordinal["position"] = position

        ordinal["type"] = "ordinal-wave-0a5c011f-4e95-4c01-8eae-e3df7ba44fd9"
        ordinal["waveuuid"] = wave["uuid"]

        Ordinals::commitToDisk(ordinal)
    end

    # Ordinals::performOrdinalRunDone(ordinal)
    def self.performOrdinalRunDone(ordinal)
        puts Ordinals::ordinalToString(ordinal)
        if ordinal["type"] == "ordinal-description-cc686a4e-d634-476f-bc03-6a41cda4344a" then
            if !LucilleCore::askQuestionAnswerAsBoolean("ordinal done ? ", true) then
                return
            end
            NyxSets::destroy(ordinal["uuid"])
        end
        if ordinal["type"] == "ordinal-quark-58558d36-12d4-459c-b220-24d8cbd10bf8" then
            quarkuuid = ordinal["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("quark cannot be found destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            Quarks::openQuark(quark)
            if !LucilleCore::askQuestionAnswerAsBoolean("ordinal done ? ") then
                return
            end
            NyxSets::destroy(ordinal["uuid"])
        end
        if ordinal["type"] == "ordinal-own-quark-ca833db7-1dd4-45bf-aac0-c26c7dc73214" then
            quarkuuid = ordinal["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("quark cannot be found destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            Quarks::openQuark(quark)
            if !LucilleCore::askQuestionAnswerAsBoolean("ordinal done ? ") then
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy ordinal own quark ? ") then
                NyxSets::destroy(ordinal["quarkuuid"])
            end
            NyxSets::destroy(ordinal["uuid"])
        end
        if ordinal["type"] == "ordinal-float-e0b15f62-c8ed-4b86-addd-7345cbe46f92" then
            floatuuid = ordinal["floatuuid"]
            float = NyxSets::getObjectOrNull(floatuuid)
            if float.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("float cannot be found, destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            if !LucilleCore::askQuestionAnswerAsBoolean("ordinal done ? ") then
                return
            end
            if !LucilleCore::askQuestionAnswerAsBoolean("destroy float ? ") then
                Floats::destroyFloat(float)
            end
            NyxSets::destroy(ordinal["uuid"])
        end
        if ordinal["type"] == "ordinal-asteroid-d55fdefa-f1ee-4d45-b705-1145dc55bf4b" then
            asteroiduuid = ordinal["asteroiduuid"]
            asteroid = Asteroids::getOrNull(asteroiduuid)
            if asteroid.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("asteroid cannot be found, destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            Asteroids::asteroidDive(asteroid)
            if !LucilleCore::askQuestionAnswerAsBoolean("ordinal done ? ") then
                return
            end
            NyxSets::destroy(ordinal["uuid"])
        end
        if ordinal["type"] == "ordinal-wave-0a5c011f-4e95-4c01-8eae-e3df7ba44fd9" then
            waveuuid = ordinal["waveuuid"]
            wave = Waves::getOrNull(waveuuid)
            if wave.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("wave cannot be found, destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            Waves::performDone(wave)
            NyxSets::destroy(ordinal["uuid"])
        end
    end

    # Ordinals::diveOrdinal(ordinal)
    def self.diveOrdinal(ordinal)
        puts Ordinals::ordinalToString(ordinal)

        ms = LCoreMenuItemsNX1.new()
        ms.item(
            "run/done ordinal", 
            lambda { Ordinals::performOrdinalRunDone(ordinal) }
        )

        if ordinal["type"] == "ordinal-description-cc686a4e-d634-476f-bc03-6a41cda4344a" then
            # 
        end
        if ordinal["type"] == "ordinal-quark-58558d36-12d4-459c-b220-24d8cbd10bf8" then
            quarkuuid = ordinal["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("quark cannot be found destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            ms.item(
                "(quark) dive", 
                lambda { Quarks::quarkDive(quark) }
            )
        end
        if ordinal["type"] == "ordinal-own-quark-ca833db7-1dd4-45bf-aac0-c26c7dc73214" then
            quarkuuid = ordinal["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("quark cannot be found destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            ms.item(
                "(quark) dive", 
                lambda { Quarks::quarkDive(quark) }
            )
        end
        if ordinal["type"] == "ordinal-float-e0b15f62-c8ed-4b86-addd-7345cbe46f92" then
            floatuuid = ordinal["floatuuid"]
            float = NyxSets::getObjectOrNull(floatuuid)
            if float.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("float cannot be found, destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            ms.item(
                "(float) dive", 
                lambda { Floats::diveFloat(float) }
            )
        end
        if ordinal["type"] == "ordinal-asteroid-d55fdefa-f1ee-4d45-b705-1145dc55bf4b" then
            asteroiduuid = ordinal["asteroiduuid"]
            asteroid = Asteroids::getOrNull(asteroiduuid)
            if asteroid.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("asteroid cannot be found, destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            ms.item(
                "(asteroid) dive", 
                lambda { Asteroids::asteroidDive(asteroid) }
            )
        end
        if ordinal["type"] == "ordinal-wave-0a5c011f-4e95-4c01-8eae-e3df7ba44fd9" then
            waveuuid = ordinal["waveuuid"]
            wave = Waves::getOrNull(waveuuid)
            if wave.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("wave cannot be found, destroy ordinal ? ")
                NyxSets::destroy(ordinal["uuid"])
                return
            end
            ms.item(
                "(wave) dive", 
                lambda { Waves::waveDive(wave) }
            )
        end
        ms.item(
            "update position", 
            lambda { 
                position = LucilleCore::askQuestionAnswerAsString("ordinal position: ")
                return if position.size == 0
                position = position.to_f
                ordinal["position"] = position
                Ordinals::commitToDisk(ordinal)
            }
        )
        ms.item(
            "destroy ordinal", 
            lambda { 
                if ordinal["type"] == "ordinal-own-quark-ca833db7-1dd4-45bf-aac0-c26c7dc73214" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy ordinal own quark ? ") then
                        NyxSets::destroy(ordinal["quarkuuid"])
                    end
                end
                NyxSets::destroy(ordinal["uuid"]) 
            }
        )
        ms.prompt()
    end

    # Ordinals::getOrdinalsOrdered()
    def self.getOrdinalsOrdered()
        NyxSets::objects("0fb6e397-ca40-4188-8375-6ea95ede34cf")
            .sort{|o1, o2| o1["position"] <=> o2["position"] }
    end
end


