
# encoding: UTF-8

class NSDataType0s

    # NSDataType0s::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # NSDataType0s::issueLine(line)
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

    # NSDataType0s::issueUrl(url)
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

    # NSDataType0s::issueText(text)
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

    # NSDataType0s::typeA02CB78ERegularExtensions()
    def self.typeA02CB78ERegularExtensions()
        [".jpg", ".jpeg", ".png", ".pdf"]
    end

    # NSDataType0s::issueTypeA02CB78E(filepath)
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

    # NSDataType0s::issueAionPoint(namedhash)
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

    # NSDataType0s::issueUniqueName(uniquename)
    def self.issueUniqueName(uniquename)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "unique-name",
            "name"       => uniquename
        }
        NyxObjects::put(object)
        object
    end

    # NSDataType0s::getNSDataType0Types()
    def self.getNSDataType0Types()
        if Realms::isCatalyst() then
            return ["line", "url", "text", "picture(+)", "fs-location aion-point", "unique-name"]
        end
        if Realms::isDocnet() then
            return ["line", "url", "text", "picture(+)", "fs-location aion-point"]
        end
        Realms::raiseException()
    end

    # NSDataType0s::issueTypeA02CB78EInteractivelyOrNull()
    def self.issueTypeA02CB78EInteractivelyOrNull()
        filepath = NSDataType0s::selectOneLocationOnTheDesktopOrNull()
        return nil if filepath.nil?
        extension = File.extname(filepath).downcase
        if extension == "" then
            puts "I could not determine an extension for this file. Aborting."
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if !NSDataType0s::typeA02CB78ERegularExtensions().include?(extension) then
            puts "I can see that the extension of this file is not... registered."
            status = LucilleCore::askQuestionAnswerAsBoolean("Continue ? : ")
            if status then
                puts "Very well, but feel free to patch the code to regiter: #{extension}"
                LucilleCore::pressEnterToContinue()
            else
                return nil
            end
        end
        return NSDataType0s::issueTypeA02CB78E(filepath)
    end

    # NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
    def self.issueNewNSDataType0InteractivelyOrNull()
        types = NSDataType0s::getNSDataType0Types()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return NSDataType0s::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return NSDataType0s::issueUrl(url)
        end
        if type == "text" then
            text = Miscellaneous::editTextSynchronously("").strip
            return nil if text.size == 0
            return NSDataType0s::issueText(text)
        end
        if type == "picture(+)" then
            return NSDataType0s::issueTypeA02CB78EInteractivelyOrNull()
        end
        if type == "fs-location aion-point" then
            location = NSDataType0s::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return NSDataType0s::issueAionPoint(namedhash)
        end
        if type == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            return nil if uniquename.size == 0
            return NSDataType0s::issueUniqueName(uniquename)
        end
    end

    # NSDataType0s::extractADescriptionFromAionPointOrNull(point)
    def self.extractADescriptionFromAionPointOrNull(point)
        if point["aionType"] == "file" then
            return point["name"]
        end
        if point["aionType"] == "directory" then
            return nil if point["items"].size != 0
            return nil if point["items"].size == 0
            aionpoint = JSON.parse(NyxBlobs::getBlobOrNull(point["items"][0]))
            return NSDataType0s::extractADescriptionFromAionPointOrNull(aionpoint)
        end
        return "[unknown aion point]"
    end

    # NSDataType0s::frameToStringUseTheForce(ns0)
    def self.frameToStringUseTheForce(ns0)
        if ns0["type"] == "line" then
            return "[#{ns0["type"]}] #{ns0["line"]}"
        end
        if ns0["type"] == "url" then
            return "#{ns0["url"]}"
        end
        if ns0["type"] == "text" then
            namedhashToFirstLine = lambda {|namedhash|
                text = NyxBlobs::getBlobOrNull(namedhash).strip
                line = text.size>0 ? "#{text.lines.first.strip} [* more lines *]" : "[empty text]"
            }
            return "[#{ns0["type"]}] #{namedhashToFirstLine.call(ns0["namedhash"])}"
        end
        if ns0["type"] == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1" then
            return "#{ns0["extensionWithDot"]}"
        end
        if ns0["type"] == "aion-point" then
            aionpoint = JSON.parse(NyxBlobs::getBlobOrNull(ns0["namedhash"]))
            description = NSDataType0s::extractADescriptionFromAionPointOrNull(aionpoint) || ns0["namedhash"]
            return "[#{ns0["type"]}] #{description}"
        end
        if ns0["type"] == "unique-name" then
            return "[#{ns0["type"]}] #{ns0["name"]}"
        end
        raise "[NSDataType0s error 2c53b113-cc79]"
    end

    # NSDataType0s::frameToString(ns0)
    def self.frameToString(ns0)
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9eb:#{Miscellaneous::today()}:#{ns0["uuid"]}")
        return str if str
        str = NSDataType0s::frameToStringUseTheForce(ns0)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("e7eb4787-0cfd-4184-a286-1dbec629d9eb:#{Miscellaneous::today()}:#{ns0["uuid"]}", str)
        str
    end

    # NSDataType0s::openFrame(ns1, ns0)
    def self.openFrame(ns1, ns0)
        if ns0["type"] == "line" then
            puts ns0["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if ns0["type"] == "url" then
            system("open '#{ns0["url"]}'")
            return
        end
        if ns0["type"] == "text" then
            namedhash = ns0["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            filepath = "/tmp/#{Miscellaneous::l22()}.txt"
            File.open(filepath, "w"){|f| f.puts(text) }
            system("open #{filepath}")
            LucilleCore::pressEnterToContinue()
            return
        end
        if ns0["type"] == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1" then
            namedhash = ns0["namedhash"]
            filedata = NyxBlobs::getBlobOrNull(namedhash)
            filepath = "/tmp/#{namedhash}#{ns0["extensionWithDot"]}"
            File.open(filepath, "w"){|f| f.write(filedata) }
            system("open #{filepath}")
            LucilleCore::pressEnterToContinue()
            return
        end
        if ns0["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForNSDataType0CreateIfNotExists(ns1, ns0)
            system("open '#{folderpath}'")
            return
        end
        if ns0["type"] == "unique-name" then
            uniquename = ns0["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
            if location then
                if File.file?(location) then
                    if Miscellaneous::fileByFilenameIsSafelyOpenable(File.basename(location)) then
                        puts "opening safely openable file '#{location}'"
                        system("open '#{location}'")
                    else
                        puts "opening parent folder of '#{location}'"
                        system("open '#{File.dirname(location)}'")
                    end
                else
                    puts "opening folder '#{location}'"
                    system("open '#{location}'")
                end
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        puts ns0
        raise "[NSDataType0 error 4bf5cfb1-c2a2]"
    end

    # NSDataType0s::editFrame(ns1, ns0)
    def self.editFrame(ns1, ns0)
        if ns0["type"] == "line" then
            line = ns0["line"]
            line = Miscellaneous::editTextSynchronously(line).strip
            newframe = NSDataType0s::issueLine(line)
            Arrows::issueOrException(ns1, newframe)
            return
        end
        if ns0["type"] == "url" then
            url = ns0["url"]
            url = Miscellaneous::editTextSynchronously(url).strip
            newframe = NSDataType0s::issueUrl(url)
            Arrows::issueOrException(ns1, newframe)
            return
        end
        if ns0["type"] == "text" then
            namedhash = ns0["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            text = Miscellaneous::editTextSynchronously(text)
            newframe = NSDataType0s::issueText(text)
            Arrows::issueOrException(ns1, newframe)
            return
        end
        if ns0["type"] == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1" then
            puts "pictures(+) are not directly editable"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to issue a new one for the same point ? : ") then
                newframe = NSDataType0s::issueTypeA02CB78EInteractivelyOrNull()
                return if newframe.nil?
                Arrows::issueOrException(ns1, newframe)
            end
            return
        end
        if ns0["type"] == "aion-point" then
            puts "aion points are edited through the desk management"
            LucilleCore::pressEnterToContinue()
            return
        end
        if ns0["type"] == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            newframe = NSDataType0s::issueUniqueName(uniquename)
            Arrows::issueOrException(ns1, newframe)
            return
        end
        puts ns0
        raise "[NSDataType0 error 93e453d8]"
    end
end
