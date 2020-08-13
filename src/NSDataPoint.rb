
# encoding: UTF-8

class NSDataPoint

    # NSDataPoint::datapoints()
    def self.datapoints()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
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
        NyxObjects::put(object)
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
        NyxObjects::put(object)
        object
    end

    # NSDataPoint::issueText(text)
    def self.issueText(text)
        namedhash = NyxBlobs::put(text)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "text",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # NSDataPoint::typeA02CB78ERegularExtensions()
    def self.typeA02CB78ERegularExtensions()
        [".jpg", ".jpeg", ".png", ".pdf"]
    end

    # NSDataPoint::issueTypeA02CB78E(filepath)
    def self.issueTypeA02CB78E(filepath)
        raise "[error: 060bc858-c5ff-4e23-bbbf-5e0e81911476]" if !File.exists?(filepath)
        extensionWithDot = File.extname(filepath).downcase
        raise "[error: 8f3fe3ad-2073-4f28-a75b-1df882ea59be]" if extensionWithDot.size == 0
        namedhash = NyxBlobs::put(IO.read(filepath))
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1",
            "extensionWithDot" => extensionWithDot,
            "namedhash"  => namedhash
        }
        #{
        #    "uuid" => "6f29d4e3-dc55-4ed4-91db-ecadcc400a74", 
        #    "nyxNxSet" => "0f555c97-3843-4dfe-80c8-714d837eba69", 
        #    "unixtime" => 1595751407.256643, 
        #    "type" => "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1", 
        #    "extensionWithDot" => ".png", 
        #    "namedhash" => "SHA256-f0c8fc5c14372e502a0412b3d3a7d87af53ffd5571ab1d0121f6eddb6e0188b6"
        #}
        NyxObjects::put(object)
        object
    end

    # NSDataPoint::issueAionPoint(namedhash)
    def self.issueAionPoint(namedhash)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "aion-point",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
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
        NyxObjects::put(object)
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
        NyxObjects::put(object)
        object
    end

    # NSDataPoint::getNSDataPointTypes()
    def self.getNSDataPointTypes()
        if Realms::isCatalyst() then
            return ["line", "url", "text", "picture(+)", "fs-location aion-point", "NyxFile", "NyxPod"]
        end
        if Realms::isDocnet() then
            return ["line", "url", "text", "picture(+)", "fs-location aion-point"]
        end
        Realms::raiseException()
    end

    # NSDataPoint::issueTypeA02CB78EInteractivelyOrNull()
    def self.issueTypeA02CB78EInteractivelyOrNull()
        filepath = NSDataPoint::selectOneLocationOnTheDesktopOrNull()
        return nil if filepath.nil?
        extension = File.extname(filepath).downcase
        if extension == "" then
            puts "I could not determine an extension for this file. Aborting."
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if !NSDataPoint::typeA02CB78ERegularExtensions().include?(extension) then
            puts "I can see that the extension of this file is not... registered."
            status = LucilleCore::askQuestionAnswerAsBoolean("Continue ? : ")
            if status then
                puts "Very well, but feel free to patch the code to regiter: #{extension}"
                LucilleCore::pressEnterToContinue()
            else
                return nil
            end
        end
        return NSDataPoint::issueTypeA02CB78E(filepath)
    end

    # NSDataPoint::issueNewPointInteractivelyOrNull()
    def self.issueNewPointInteractivelyOrNull()
        types = NSDataPoint::getNSDataPointTypes()
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
            text = Miscellaneous::editTextSynchronously("").strip
            return nil if text.size == 0
            return NSDataPoint::issueText(text)
        end
        if type == "picture(+)" then
            return NSDataPoint::issueTypeA02CB78EInteractivelyOrNull()
        end
        if type == "fs-location aion-point" then
            location = NSDataPoint::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return NSDataPoint::issueAionPoint(namedhash)
        end
        if type == "NyxPod" then
            nyxpodname = LucilleCore::askQuestionAnswerAsString("nyxpod name: ")
            return nil if nyxpodname.size == 0
            return NSDataPoint::issueNyxPod(nyxpodname)
        end
        if type == "NyxFile" then
            nyxfilename = LucilleCore::askQuestionAnswerAsString("nyxfile name: ")
            return nil if nyxfilename.size == 0
            return NSDataPoint::issueNyxFile(nyxfilename)
        end
    end

    # NSDataPoint::extractADescriptionFromAionPointOrNull(point)
    def self.extractADescriptionFromAionPointOrNull(point)
        if point["aionType"] == "file" then
            return point["name"]
        end
        if point["aionType"] == "directory" then
            return nil if point["items"].size != 0
            return nil if point["items"].size == 0
            aionpoint = JSON.parse(NyxBlobs::getBlobOrNull(point["items"][0]))
            return NSDataPoint::extractADescriptionFromAionPointOrNull(aionpoint)
        end
        return "[unknown aion point]"
    end

    # NSDataPoint::decacheObjectMetadata(ns0)
    def self.decacheObjectMetadata(ns0)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{ns0["uuid"]}")
    end

    # NSDataPoint::toStringUseTheForce(ns0, showType: boolean)
    def self.toStringUseTheForce(ns0, showType)
        if ns0["type"] == "line" then
            return "#{(showType ? "[datapoint] " : "")}#{ns0["line"]}"
        end
        if ns0["type"] == "url" then
            return "#{(showType ? "[datapoint] " : "")}#{ns0["url"]}"
        end
        if ns0["type"] == "text" then
            namedhashToFirstLine = lambda {|namedhash|
                text = NyxBlobs::getBlobOrNull(namedhash).strip
                line = text.size>0 ? "#{(showType ? "[datapoint] " : "")}[text] #{text.lines.first.strip}" : "#{(showType ? "[datapoint] " : "")}[text] {empty}"
            }
            return "#{namedhashToFirstLine.call(ns0["namedhash"])}"
        end
        if ns0["type"] == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1" then
            return "#{(showType ? "[datapoint] " : "")}[file] #{ns0["extensionWithDot"]}"
        end
        if ns0["type"] == "aion-point" then
            aionpoint = JSON.parse(NyxBlobs::getBlobOrNull(ns0["namedhash"]))
            description = NSDataPoint::extractADescriptionFromAionPointOrNull(aionpoint) || ns0["namedhash"]
            return "#{(showType ? "[datapoint] " : "")}[aion tree] #{description}"
        end
        if ns0["type"] == "NyxFile" then
            return "#{(showType ? "[datapoint] " : "")}NyxFile: #{ns0["name"]}"
        end
        if ns0["type"] == "NyxPod" then
            return "#{(showType ? "[datapoint] " : "")}NyxPod: #{ns0["name"]}"
        end
        raise "[NSDataPoint error d39378dc]"
    end

    # NSDataPoint::toString(ns0)
    def self.toString(ns0)
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{ns0["uuid"]}")
        return str if str
        str = NSDataPoint::toStringUseTheForce(ns0, true)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{ns0["uuid"]}", str)
        str
    end

    # NSDataPoint::toStringForDataline(ns0)
    def self.toStringForDataline(ns0)
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("9e2041bb-e1e2-4bdb-a7db-e6e35397f554:#{ns0["uuid"]}")
        return str if str
        str = NSDataPoint::toStringUseTheForce(ns0, false)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("9e2041bb-e1e2-4bdb-a7db-e6e35397f554:#{ns0["uuid"]}", str)
        str
    end

    # NSDataPoint::selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
    def self.selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
        owners = Arrows::getSourcesForTarget(ns0)
        owner = nil
        if owners.size == 0 then
            puts "Could not find any owner for #{NSDataPoint::toString(ns0)}"
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

    # NSDataPoint::readWriteDatalineDataPointReturnNewPointOrNull(dataline, datapoint)
    def self.readWriteDatalineDataPointReturnNewPointOrNull(dataline, datapoint)
        if datapoint["type"] == "line" then
            line = datapoint["line"]
            line = Miscellaneous::editTextSynchronously(line).strip
            return NSDataPoint::issueLine(line)
        end
        if datapoint["type"] == "url" then
            url = datapoint["url"]
            url = Miscellaneous::editTextSynchronously(url).strip
            return NSDataPoint::issueUrl(url)
        end
        if datapoint["type"] == "text" then
            namedhash = datapoint["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash) # The code is currently written with the assumption that this always succeed.
            text = Miscellaneous::editTextSynchronously(text)
            return NSDataPoint::issueText(text)
        end
        if datapoint["type"] == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1" then
            puts "pictures(+) are not directly editable"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to issue a new one for the same dataline ? : ") then
                return NSDataPoint::issueTypeA02CB78EInteractivelyOrNull()
            else 
                return nil
            end
        end
        if datapoint["type"] == "aion-point" then
            if dataline.nil? then
                dataline = NSDataPoint::selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
                return nil if dataline.nil?
            end
            exportpath = DeskOperator::deskFolderpathForNSDatalineCreateIfNotExists(dataline, datapoint)
            system("open '#{exportpath}'")
            return nil
        end
        if datapoint["type"] == "NyxFile" then
            nyxfilename = ns0["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(nyxfilename)
            if location then
                puts "filepath: #{location}"
                puts "opening parent folder"
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{nyxfilename}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "NyxPod" then
            nyxpodname = datapoint["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(nyxpodname)
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

    # NSDataPoint::enterDataPoint(datapoint)
    def self.enterDataPoint(datapoint)
        dataline = NSDataPoint::selectDataPointOwnerPossiblyInteractivelyOrNull(datapoint)
        return if dataline.nil?
        newdatapoint = NSDataPoint::readWriteDatalineDataPointReturnNewPointOrNull(dataline, datapoint)
        return if newdatapoint.nil?
        Arrows::issueOrException(dataline, newdatapoint)
    end

    # NSDataPoint::decacheObjectMetadata(datapoint)
    def self.decacheObjectMetadata(datapoint)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{datapoint["uuid"]}")
    end
end
