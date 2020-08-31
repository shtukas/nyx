
# encoding: UTF-8

class NSDataPoint

    # NSDataPoint::datapoints()
    def self.datapoints()
        NyxObjects2::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # NSDataPoint::getDataPointParents(datapoint)
    def self.getDataPointParents(datapoint)
        Arrows::getSourcesForTarget(datapoint)
    end

    # NSDataPoint::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # NSDataPoint::issueLine(line)
    def self.issueLine(line)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "line",
            "line"       => line
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueUrl(url)
    def self.issueUrl(url)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "url",
            "url"        => url
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::typeA02CB78ERegularExtensions()
    def self.typeA02CB78ERegularExtensions()
        [".jpg", ".jpeg", ".png", ".pdf"]
    end

    # NSDataPoint::issueNyxDir(nyxPodName)
    def self.issueNyxDir(nyxPodName)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxDir",
            "name"       => nyxPodName
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueNyxFile(nyxFileName)
    def self.issueNyxFile(nyxFileName)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxFile",
            "name"       => nyxFileName
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueNewPointInteractivelyOrNull()
    def self.issueNewPointInteractivelyOrNull()
        types = ["line", "url", "text", "NyxFile", "NyxDir"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return NSDataPoint::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return NSDataPoint::issueUrl(url)
        end
        if type == "text" then
            nyxfilename = "NyxFile-#{SecureRandom.uuid}"
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/NyxFiles/#{nyxfilename}.txt"
            File.touch(filepath)
            system("open '#{filepath}'")
            LucilleCore::pressEnterToContinue()
            return NSDataPoint::issueNyxFile(nyxfilename)
        end
        if type == "NyxFile" then
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["nyxfilename already exists", "issue new nyxfilename"])
            return nil if op.nil?
            if op == "nyxfilename already exists" then
                nyxfilename = LucilleCore::askQuestionAnswerAsString("nyxfile name: ")
                return nil if nyxfilename.size == 0
            end
            if op == "issue new nyxfilename" then
                nyxfilename = "NyxFile-#{SecureRandom.uuid}"
                puts "nyxfilename: #{nyxfilename}"
                LucilleCore::pressEnterToContinue()
            end
            return NSDataPoint::issueNyxFile(nyxfilename)
        end
        if type == "NyxDir" then
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["podname already exists", "issue new podname"])
            return nil if op.nil?
            if op == "podname already exists" then
                nyxpodname = LucilleCore::askQuestionAnswerAsString("nyxpod name: ")
                return nil if nyxpodname.size == 0
            end
            if op == "issue new podname" then
                nyxpodname = "NyxDir-#{SecureRandom.uuid}"
                puts "podname: #{nyxpodname}"
                LucilleCore::pressEnterToContinue()
            end
            return NSDataPoint::issueNyxDir(nyxpodname)
        end
    end

    # NSDataPoint::getReferenceUnixtime(datapoint)
    def self.getReferenceUnixtime(datapoint)
        DateTime.parse(GenericObjectInterface::getObjectReferenceDateTime(datapoint)).to_time.to_f
    end

    # NSDataPoint::toStringUseTheForce(datapoint)
    def self.toStringUseTheForce(datapoint)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(datapoint)
        if description then
            return "[#{datapoint["type"]}] #{description}"
        end
        if datapoint["type"] == "line" then
            return "[#{datapoint["type"]}] #{datapoint["line"]}"
        end
        if datapoint["type"] == "url" then
            return "[#{datapoint["type"]}] #{datapoint["url"]}"
        end
        if datapoint["type"] == "NyxFile" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        if datapoint["type"] == "NyxDir" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        raise "[NSDataPoint error d39378dc]"
    end

    # NSDataPoint::toString(datapoint, useCachedValue = true)
    def self.toString(datapoint, useCachedValue = true)
        cacheKey = "e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{datapoint["uuid"]}"
        if useCachedValue then
            str = KeyValueStore::getOrNull(nil, cacheKey)
            return str if str
        end
        str = NSDataPoint::toStringUseTheForce(datapoint)
        KeyValueStore::set(nil, cacheKey, str)
        str
    end

    # NSDataPoint::selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
    def self.selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
        owners = Arrows::getSourcesForTarget(datapoint)
        owner = nil
        if owners.size == 0 then
            puts "Could not find any owner for #{NSDataPoint::toString(datapoint)}"
            puts "Aborting opening"
            LucilleCore::pressEnterToContinue()
            return
        end
        if owners.size == 1 then
            owner = owners.first
        end
        if owners.size > 1 then
            puts "We have more than one owner for this aion point (how did that happen?...)"
            puts "Choose one for the desk management"
            owner = LucilleCore::selectEntityFromListOfEntitiesOrNull("owner", owners, lambda{|owner| GenericObjectInterface::toString(owner) })
        end
        owner
    end

    # NSDataPoint::accessopen(datapoint)
    def self.accessopen(datapoint)
        if datapoint["type"] == "line" then
            puts "line: #{datapoint["line"]}"
            if LucilleCore::askQuestionAnswerAsBoolean("edit line ? : ", false) then
                line = datapoint["line"]
                line = Miscellaneous::editTextSynchronously(line).strip
                return NSDataPoint::issueLine(line)
            end
            return nil
        end
        if datapoint["type"] == "url" then
            puts "url: #{datapoint["url"]}"
            system("open '#{datapoint["url"]}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit url ? : ", false) then
                url = datapoint["url"]
                url = Miscellaneous::editTextSynchronously(url).strip
                return NSDataPoint::issueUrl(url)
            end
            return nil
        end
        if datapoint["type"] == "NyxFile" then
            location = NyxElementDatapointLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "filepath: #{location}"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["name"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "NyxDir" then
            location = NyxElementDatapointLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "opening folder '#{location}'"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["name"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        puts datapoint
        raise "[NSDataPoint error e12fc718]"
    end

    # NSDataPoint::landing(datapoint)
    def self.landing(datapoint)
        loop {

            return if NyxObjects2::getOrNull(datapoint["uuid"]).nil?

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            puts "[parents]".yellow
            puts ""

            Arrows::getSourcesForTarget(datapoint)
                .each{|o|
                    menuitems.item(
                        "parent: #{GenericObjectInterface::toString(o)}",
                        lambda { GenericObjectInterface::landing(o) }
                    )
                }

            Miscellaneous::horizontalRule()
            puts JSON.pretty_generate(datapoint).yellow
            puts "[datapoint]".yellow

            puts "    #{NSDataPoint::toString(datapoint)}"
            puts "    uuid: #{datapoint["uuid"]}".yellow
            puts "    date: #{GenericObjectInterface::getObjectReferenceDateTime(datapoint)}".yellow

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(datapoint)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
            end

            puts ""

            menuitems.item(
                "open",
                lambda { NSDataPoint::accessopen(datapoint) }
            )

            menuitems.item(
                "destroy",
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of '#{NSDataPoint::toString(datapoint)}': ") then
                        NyxObjects2::destroy(datapoint)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.promptAndRunSandbox()
            break if !status
        }
    end
end

class NyxElementDatapointLocation

    # NyxElementDatapointLocation::getLocationByAllMeansOrNull(datapoint)
    def self.getLocationByAllMeansOrNull(datapoint)
        location = NyxFileSystemElementsMapping::getStoredLocationForObjectUUIDOrNull(datapoint["uuid"])
        if location then
            if File.exists?(location) then
                return location
            end
        end

        location = GalaxyFinder::nyxFileSystemElementNameToLocationOrNull(datapoint["name"])
        if location then
            NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
            return location
        end

        nil
    end

    # NyxElementDatapointLocation::runMappingUpdate()
    def self.runMappingUpdate()
        NSDataPoint::datapoints().each{|datapoint|
            puts JSON.pretty_generate(datapoint)
            next if !["NyxDir", "NyxFile"].include?(datapoint["type"])
            xname = datapoint["name"]
            location = NyxElementDatapointLocation::getLocationByAllMeansOrNull(datapoint)
            if location.nil? then
                puts "Falling to find a location for this datapoint nyx element"
                puts JSON.pretty_generate(datapoint)
                raise "63e36570-bbf0-4c2d-a3f1-0f839011191f"
            end
            NyxFileSystemElementsMapping::register(datapoint["uuid"], xname, location)
        }
    end
end
