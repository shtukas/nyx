
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

    # NSDataPoint::issueNyxPod(nyxPodName)
    def self.issueNyxPod(nyxPodName)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxPod",
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
        types = ["line", "url", "text", "NyxFile", "NyxPod"]
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
        if type == "NyxPod" then
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["podname already exists", "issue new podname"])
            return nil if op.nil?
            if op == "podname already exists" then
                nyxpodname = LucilleCore::askQuestionAnswerAsString("nyxpod name: ")
                return nil if nyxpodname.size == 0
            end
            if op == "issue new podname" then
                nyxpodname = "NyxPod-#{SecureRandom.uuid}"
                puts "podname: #{nyxpodname}"
                LucilleCore::pressEnterToContinue()
            end
            return NSDataPoint::issueNyxPod(nyxpodname)
        end
    end

    # NSDataPoint::toStringUseTheForce(datapoint)
    def self.toStringUseTheForce(datapoint)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(datapoint)
        if description then
            return "#{datapoint["type"]} #{description}"
        end
        if datapoint["type"] == "line" then
            return "#{datapoint["type"]} #{datapoint["line"]}"
        end
        if datapoint["type"] == "url" then
            return "#{datapoint["type"]} #{datapoint["url"]}"
        end
        if datapoint["type"] == "NyxFile" then
            return "#{datapoint["type"]} NyxFile: #{datapoint["name"]}"
        end
        if datapoint["type"] == "NyxPod" then
            return "#{datapoint["type"]} NyxPod: #{datapoint["name"]}"
        end
        raise "[NSDataPoint error d39378dc]"
    end

    # NSDataPoint::toString(datapoint)
    def self.toString(datapoint)
        str = KeyValueStore::getOrNull(nil, "e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{datapoint["uuid"]}")
        return str if str
        str = NSDataPoint::toStringUseTheForce(datapoint)
        KeyValueStore::set(nil, "e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{datapoint["uuid"]}", str)
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

    # NSDataPoint::enterDatalineDataPointCore(dataline, datapoint)
    def self.enterDatalineDataPointCore(dataline, datapoint)
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
            nyxfilename = datapoint["name"]
            location = NyxGalaxyFinder::uniqueStringToLocationOrNull(nyxfilename)
            if location then
                puts "filepath: #{location}"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{nyxfilename}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "NyxPod" then
            nyxpodname = datapoint["name"]
            location = NyxGalaxyFinder::uniqueStringToLocationOrNull(nyxpodname)
            if location then
                puts "opening folder '#{location}'"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{nyxpodname}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        puts datapoint
        raise "[NSDataPoint error e12fc718]"
    end

    # NSDataPoint::enterDatalineDataPointEnvelop(dataline, datapoint)
    def self.enterDatalineDataPointEnvelop(dataline, datapoint)
        newdatapoint = NSDataPoint::enterDatalineDataPointCore(dataline, datapoint)
        return if newdatapoint.nil?
        Arrows::issueOrException(dataline, newdatapoint)
    end

    # NSDataPoint::accessopen(datapoint)
    def self.accessopen(datapoint)
        dataline = NSDataPoint::selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
        return if dataline.nil?
        NSDataPoint::enterDatalineDataPointEnvelop(dataline, datapoint)
    end

    # NSDataPoint::landing(datapoint)
    def self.landing(datapoint)
        loop {
            menuitems = LCoreMenuItemsNX1.new()
            puts NSDataPoint::toString(datapoint)

            menuitems.item(
                "open",
                lambda { NSDataPoint::accessopen(datapoint) }
            )

            menuitems.item(
                "destroy",
                lambda { NyxObjects2::destroy(datapoint) }
            )

            status = menuitems.promptAndRunSandbox()
            break if !status
        }
    end
end
