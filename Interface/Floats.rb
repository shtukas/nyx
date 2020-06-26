# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/VideoStream/VideoStream.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Drives.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx.v2/NyxSets.rb"

# ------------------------------------------------------------------------

class Floats

    # Floats::floatToString(float)
    def self.floatToString(float)
        if float["type"] == "float-description-ff149b92-cf23-49b2-9268-b63f8773eb40" then
            return "[float] #{float["description"]}"
        end
        if float["type"] == "float-quark-d442c162-893c-47f8-ba57-b84980a79d59" then
            quarkuuid = float["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark then
                return "[float] #{Quarks::quarkToString(quark)}"
            else
                return "[float] [quark] not found (#{quarkuuid})"
            end
        end
        if float["type"] == "float-clique-656a24a8-2acb-417a-b23e-09dc29106f38" then
            cliqueuuid = float["cliqueuuid"]
            clique = Quarks::getOrNull(cliqueuuid)
            if clique then
                return "[float] #{Cliques::cliqueToString(clique)}"
            else
                return "[float] [clique] not found (#{quarkuuid})"
            end
        end
    end

    # Floats::commitToDisk(float)
    def self.commitToDisk(float)
        NyxSets::putObject(float)
    end

    # Floats::issueFloat()
    def self.issueFloat()
        items = []

        items << [
            "description", 
            lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description.size == 0
                float = {
                    "uuid"        => SecureRandom.hex,
                    "nyxNxSet"    => "1aaa9485-2c07-4b14-a5c3-ed1d6772ca19",
                    "unixtime"    => Time.new.to_i,
                    "type"        => "float-description-ff149b92-cf23-49b2-9268-b63f8773eb40",
                    "description" => description
                }
                Floats::commitToDisk(float)
            }
        ]

        items << [
            "quark (new)", 
            lambda {
                quark = Quarks::issueNewQuarkInteractivelyOrNull()
                return if quark.nil?
                float = {
                    "uuid"       => SecureRandom.hex,
                    "nyxNxSet"   => "1aaa9485-2c07-4b14-a5c3-ed1d6772ca19",
                    "unixtime"   => Time.new.to_i,
                    "type"       => "float-quark-d442c162-893c-47f8-ba57-b84980a79d59",
                    "quarkuuid"  => quark["uuid"]
                }
                Floats::commitToDisk(float)
            }
        ]
        items << [
            "clique (new)", 
            lambda {
                clique = Cliques::issueCliqueInteractivelyOrNull()
                return if clique.nil?
                float = {
                    "uuid"       => SecureRandom.hex,
                    "nyxNxSet"   => "1aaa9485-2c07-4b14-a5c3-ed1d6772ca19",
                    "unixtime"   => Time.new.to_i,
                    "type"       => "float-clique-656a24a8-2acb-417a-b23e-09dc29106f38",
                    "cliqueuuid" => clique["uuid"]
                }
                Floats::commitToDisk(float)
            }
        ]

        LucilleCore::menuItemsWithLambdas(items)
    end

    # Floats::processFloat(float)
    def self.processFloat(float)
        if float["type"] == "float-description-ff149b92-cf23-49b2-9268-b63f8773eb40" then
            puts "float: #{float["description"]}"
            return if !LucilleCore::askQuestionAnswerAsBoolean("destroy ? ")
            NyxSets::destroy(float["uuid"])
        end
        if float["type"] == "float-quark-d442c162-893c-47f8-ba57-b84980a79d59" then
            quarkuuid = float["quarkuuid"]
            quark = Quarks::getOrNull(quarkuuid)
            if quark.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("destroy ? ")
                NyxSets::destroy(float["uuid"])
                return
            end
            items = []
            items << [
                "(quark) dive", 
                lambda { Quarks::quarkDive(quark) }
            ]
            items << [
                "destroy", 
                lambda { NyxSets::destroy(float["uuid"]) }
            ]
            LucilleCore::menuItemsWithLambdas(items)
        end
        if float["type"] == "float-clique-656a24a8-2acb-417a-b23e-09dc29106f38" then
            cliqueuuid = float["cliqueuuid"]
            clique = Quarks::getOrNull(cliqueuuid)
            if clique.nil? then
                return if !LucilleCore::askQuestionAnswerAsBoolean("destroy ? ")
                NyxSets::destroy(float["uuid"])
                return
            end
            items = []
            items << [
                "(clique) dive", 
                lambda { Cliques::cliqueDive(clique) }
            ]
            items << [
                "destroy", 
                lambda { NyxSets::destroy(float["uuid"]) }
            ]
            LucilleCore::menuItemsWithLambdas(items)
        end
    end

    # Floats::getFloatsOrdered()
    def self.getFloatsOrdered()
        NyxSets::getObjectsFromSet("1aaa9485-2c07-4b14-a5c3-ed1d6772ca19")
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end
end


