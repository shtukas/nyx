
# encoding: UTF-8

class NSDataType0Cached
    # NSDataType0Cached::forget(ns0)
    def self.forget(ns0)
        InMemoryWithOnDiskPersistenceValueCache::delete("e7eb4787-0cfd-4184-a286-1dbec629d9e9:#{ns0["uuid"]}")
    end
end

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

    # NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
    def self.issueNewNSDataType0InteractivelyOrNull()
        puts "Making a new NSDataType0..."
        types = ["line", "url", "text", "fs-location aion-point", "unique-name"]
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
            text = Miscellaneous::editTextUsingTextmate("").strip
            return nil if text.size == 0
            return NSDataType0s::issueText(text)
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

    # NSDataType0s::ns0s()
    def self.ns0s()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # NSDataType0s::ns0ToString(ns0)
    def self.ns0ToString(ns0)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9e9:#{ns0["uuid"]}")
        return str if str

        str = (lambda{|ns0|
            if ns0["type"] == "line" then
                return "[ns0] [#{ns0["uuid"][0, 4]}] [#{ns0["type"]}] #{ns0["line"]}"
            end
            if ns0["type"] == "url" then
                return "[ns0] [#{ns0["uuid"][0, 4]}] [#{ns0["type"]}] #{ns0["url"]}"
            end
            if ns0["type"] == "text" then
                namedhashToFirstLine = lambda {|namedhash|
                    text = NyxBlobs::getBlobOrNull(namedhash).strip
                    line = text.size>0 ? text.lines.first.strip : "[empty text]"
                }
                return "[ns0] [#{ns0["uuid"][0, 4]}] [#{ns0["type"]}] #{namedhashToFirstLine.call(ns0["namedhash"])}"
            end
            if ns0["type"] == "aion-point" then
                return "[ns0] [#{ns0["uuid"][0, 4]}] [#{ns0["type"]}] #{ns0["namedhash"]}"
            end
            if ns0["type"] == "unique-name" then
                return "[ns0] [#{ns0["uuid"][0, 4]}] [#{ns0["type"]}] #{ns0["name"]}"
            end
            raise "[NSDataType0s error 2c53b113-cc79]"
        }).call(ns0)

        InMemoryWithOnDiskPersistenceValueCache::set("e7eb4787-0cfd-4184-a286-1dbec629d9e9:#{ns0["uuid"]}", str)
        str
    end

    # NSDataType0s::openNSDataType0(ns2, ns0)
    def self.openNSDataType0(ns2, ns0)
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
            system("clear")
            namedhash = ns0["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            puts text
            LucilleCore::pressEnterToContinue()
            return
        end
        if ns0["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForNSDataType0CreateIfNotExists(ns2, ns0)
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
        raise "[NSDataType0 error 4bf5cfb1-c2a2]"
    end
end
