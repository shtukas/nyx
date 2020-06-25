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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/VideoStream/VideoStream.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Drives.rb"

# ------------------------------------------------------------------------

$SpecialCircumstancesFileNames = [
    "Interface-Top.txt",
    "Guardian-Next.txt",
    "Lucille.txt",
]

class NSXCatalystUI

    # NSXCatalystUI::applyNextTransformationToFile(filepath)
    def self.applyNextTransformationToFile(filepath)
        CatalystCommon::copyLocationToCatalystBin(filepath)
        content = IO.read(filepath).strip
        content = SectionsType0141::applyNextTransformationToContent(content)
        File.open(filepath, "w"){|f| f.puts(content) }
    end

    # NSXCatalystUI::getSpecialCircumstanceFilepaths(catalystObjects)
    def self.getSpecialCircumstanceFilepaths(catalystObjects)
        filepaths = []
        if IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Special-Circumstances-Files/Interface-Top.txt").strip.size > 0 then
            filepaths << "/Users/pascal/Galaxy/DataBank/Catalyst/Special-Circumstances-Files/Interface-Top.txt"
        end
        if catalystObjects.any?{|object| object["isRunning"] and object["body"].include?("Daily Guardian Work") } then
            filepaths << "/Users/pascal/Galaxy/DataBank/Catalyst/Special-Circumstances-Files/Guardian-Next.txt"
        end
        if catalystObjects.any?{|object| object["isRunning"] and object["body"].include?("Lucille.txt") } then
            filepaths << "/Users/pascal/Galaxy/DataBank/Catalyst/Special-Circumstances-Files/Lucille.txt"
        end
        filepaths
    end

    # NSXCatalystUI::objectFocus(object)
    def self.objectFocus(object)
        return if object.nil?
        puts NSXDisplayUtils::makeDisplayStringForCatalystListing(object)
        loop {
            object["execute"].call()
            return if LucilleCore::askQuestionAnswerAsBoolean("exit object ? ", true)
        }
    end

    # NSXCatalystUI::operations()
    def self.operations()
        loop {
            system("clear")

            items = []

            items << [
                "general search", 
                lambda { NSXGeneralSearch::searchAndDive() }
            ]

            items << [
                "cliques (listing)", 
                lambda { Cliques::cliquesListingAndDive() }
            ]

            items << [
                "quarks (listing)", 
                lambda { Quarks::quarksListingAndDive() }
            ]

            items << nil

            items << [
                "quark (new)",
                lambda { 
                    quark = Quarks::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    Quarks::issueZeroOrMoreTagsForQuarkInteractively(quark)
                    Quarks::attachQuarkToZeroOrMoreCliquesInteractively(quark)
                }
            ]

            items << [
                "asteroid (new)",
                lambda { 
                    asteroid = Asteroids::issueSpaceShipInteractivelyOrNull()
                    return if asteroid.nil?
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "merge two cliques",
                lambda { 
                    Cliques::interactivelySelectTwoCliquesAndMerge()
                }
            ]

            items << nil

            items << [
                "Asteroids",
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/asteroids") }
            ]
            items << [
                "OpenCycles",
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/opencycles") }
            ]
            items << [
                "Calendar",
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar") }
            ]
            items << [
                "Waves",
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Waves/waves") }
            ]

            items << nil

            items << [
                "Print Generation Speed Report", 
                lambda { 
                    NSXCatalystObjectsOperator::generationSpeedReport()
                }
            ]

            items << [
                "Run Data Integrity Check", 
                lambda { 
                    CatalystFsck::run()
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "Run Shadow Update", 
                lambda { Drives::runShadowUpdate() }
            ]

            items << [
                "Nyx garbage collection", 
                lambda { NyxGarbageCollection::run() }
            ]

            items << [
                "Nyx curation", 
                lambda { NSXCuration::run() }
            ]

            items << [
                "Timeline garbage collection", 
                lambda { 
                    puts "#{NSXEstateServices::getArchiveT1mel1neSizeInMegaBytes()} Mb"
                    NSXEstateServices::binT1mel1neGarbageCollectionEnvelop(true)
                }
            ]

            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::doTheObviousThingWithThis(object)
    def self.doTheObviousThingWithThis(object)
        if object["x-asteroid"] and !object["isRunning"] then
            Asteroids::asteroidStartSequence(object["x-asteroid"])
            return
        end
        if object["x-asteroid"] and object["isRunning"] then
            Asteroids::asteroidStopSequence(object["x-asteroid"])
            return
        end
        if object["x-calendar-date"] then
            Calendar::setDateAsReviewed(object["x-calendar-date"])
            return
        end
        if object["x-wave"] then
            Waves::openProcedure(object["x-wave"])
            return
        end
        if object["x-video-stream"] then
            VideoStream::play(object["x-filepath"])
            return
        end

        if object["x-anniversaries"] then
            object["execute"].call()
            return
        end

        puts "I could not determine the obvious thing to to do with this"
        puts JSON.pretty_generate(object)
        LucilleCore::pressEnterToContinue()
    end

    # NSXCatalystUI::performStandardDisplay(catalystObjects)
    def self.performStandardDisplay(catalystObjects)

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3
        menuitems = LCoreMenuItemsNX1.new()

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1
        OpenCycles::opencycles()
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
            .map{|opencycle|
                menuitems.item(
                    OpenCycles::opencycleToString(opencycle).yellow,
                    lambda { 
                        entity = NyxIO::getOrNull(opencycle["targetuuid"])
                        if entity.nil? then
                            puts "I could not find a target for this open cycle"
                            LucilleCore::pressEnterToContinue()
                            OpenCycles::opencycleDive(opencycle)
                            return
                        end
                        NyxDataCarriers::objectDive(entity)
                    }
                )
                verticalSpaceLeft = verticalSpaceLeft - 1
            }

        asteroids = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "66ecd959-967c-4c5e-b437-c07169f3d3b1", "[]"))
                        .map{|uuid| NyxIO::getOrNull(uuid) }
                        .compact
        if asteroids.size > 0 then
            puts ""
            asteroids.each{|asteroid|
                menuitems.item(
                    Asteroids::asteroidToString(asteroid).yellow,
                    lambda { Asteroids::asteroidDive(asteroid) }
                )
            }
            verticalSpaceLeft = verticalSpaceLeft - (asteroids.size+1)
        end

        floats = BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Floats", "7B828D25-43D7-4FA2-BCE0-B1EC86ECF27E")
        if floats.size > 0 then
            puts ""
            floats
                .sort{|f1, f2| (f1["unixtime"] || 0) <=> (f2["unixtime"] || 0) }
                .each{|float|
                    menuitems.item(
                        "float: #{float["description"]}".yellow,
                        lambda { 
                            puts "float: #{float["description"]}"
                            return if !LucilleCore::askQuestionAnswerAsBoolean("destroy ? ")
                            BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Floats", "7B828D25-43D7-4FA2-BCE0-B1EC86ECF27E", float["id"]) 
                        }
                    )
                }
            verticalSpaceLeft = verticalSpaceLeft - (floats.size+1)
        end

        specialCircumstanceFilepaths = NSXCatalystUI::getSpecialCircumstanceFilepaths(catalystObjects)
        specialCircumstanceFilepaths.each{|filepath|
            text = IO.read(filepath).strip
            if text.size > 0 then
                text = text.lines.first(10).join().strip.lines.map{|line| "    #{line}" }.join()
                puts ""
                puts File.basename(filepath)
                puts text.green
                verticalSpaceLeft = verticalSpaceLeft - (NSXDisplayUtils::verticalSize(text) + 2)
            end
        }

        Calendar::dates()
            .each{|date|
                next if date > Time.new.to_s[0, 10]
                puts "🗓️  "+date
                puts IO.read(dateToFilepath(date))
                    .strip
                    .lines
                    .map{|line| "    #{line}" }
                    .join()
            }

        # --------------------------------------------------------------------------
        # Print

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1
        catalystObjects.each{|object| 
            str = NSXDisplayUtils::makeDisplayStringForCatalystListing(object)
            break if (verticalSpaceLeft - NSXDisplayUtils::verticalSize(str) < 0)
            if object["isRunning"] then
                str = str.green
            end
            menuitems.item(
                str,
                lambda { object["execute"].call() }
            )
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(str)
        }

        # --------------------------------------------------------------------------
        # Prompt

        puts ""
        print "--> "
        command = STDIN.gets().strip

        if NSXMiscUtils::isInteger(command) then
            position = command.to_i
            menuitems.executePosition(position)
            return
        end

        if command == 'expose' then
            object = catalystObjects.select{|object| object["isFocus"]}.first
            return if object.nil?
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "++" then
            object = catalystObjects.select{|object| object["isFocus"]}.first
            return if object.nil?
            unixtime = NSXMiscUtils::codeToUnixtimeOrNull("+1 hours")
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command.start_with?('+') and (unixtime = NSXMiscUtils::codeToUnixtimeOrNull(command)) then
            object = catalystObjects.select{|object| object["isFocus"]}.first
            return if object.nil?
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command == ".." then
            object = catalystObjects.select{|object| object["isFocus"]}.first
            return if object.nil?
            NSXCatalystUI::doTheObviousThingWithThis(object)
            return
        end

        if command == "::" then
            filename = LucilleCore::selectEntityFromListOfEntitiesOrNull("file", $SpecialCircumstancesFileNames)
            return if filename.nil?
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Special-Circumstances-Files/#{filename}"
            system("open '#{filepath}'")
        end

        if command == "[]" then
            specialCircumstancesFilepath = specialCircumstanceFilepaths.first
            if specialCircumstancesFilepath then
                NSXCatalystUI::applyNextTransformationToFile(specialCircumstancesFilepath)
            end
        end

        if command == "l+" then
            items = []

            items << [
                "float (visible text things to keep in mind -- should be short lived)", 
                lambda {
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                    return if description.size == 0
                    float = {
                        "id"          => SecureRandom.hex,
                        "unixtime"    => Time.new.to_i,
                        "description" => description
                    }
                    BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Floats", "7B828D25-43D7-4FA2-BCE0-B1EC86ECF27E", float["id"], float)
                }
            ]

            items << [
                "starship", 
                lambda { Asteroids::issueSpaceShipInteractivelyOrNull() }
            ]

            items << [
                "open cycle (with created quark)", 
                lambda { OpenCycles::createQuarkAndIssueNew() }
            ]

            LucilleCore::menuItemsWithLambdas(items)
            return
        end

        if command == "/" then
            NSXCatalystUI::operations()
            return
        end
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {

            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                exit
            end

            # Some Admin
            NSXMiscUtils::importFromLucilleInbox()

            # Displays
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            if objects.empty? then
                puts "No catalyst object found"
                LucilleCore::pressEnterToContinue()
                return
            end
            objects[0]["isFocus"] = true
            NSXCatalystUI::performStandardDisplay(objects)
        }
    end
end


