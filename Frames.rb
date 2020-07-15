
# encoding: UTF-8

class FrameCached
    # FrameCached::forget(frame)
    def self.forget(frame)
        InMemoryWithOnDiskPersistenceValueCache::delete("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{frame["uuid"]}")
    end
end

class Frames

    # Frames::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # Frames::issueLine(line)
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

    # Frames::issueUrl(url)
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

    # Frames::issueText(text)
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

    # Frames::issueAionPoint(namedhash)
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

    # Frames::issueUniqueName(uniquename)
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

    # Frames::issueNewFrameInteractivelyOrNull()
    def self.issueNewFrameInteractivelyOrNull()
        puts "Making a new Frame..."
        types = ["line", "url", "text", "fs-location aion-point", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return Frames::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return Frames::issueUrl(url)
        end
        if type == "text" then
            text = Miscellaneous::editTextUsingTextmate("").strip
            return nil if text.size == 0
            return Frames::issueText(text)
        end
        if type == "fs-location aion-point" then
            location = Frames::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return Frames::issueAionPoint(namedhash)
        end
        if type == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            return nil if uniquename.size == 0
            return Frames::issueUniqueName(uniquename)
        end
    end

    # Frames::frames()
    def self.frames()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # Frames::frameToString(frame)
    def self.frameToString(frame)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{frame["uuid"]}")
        return str if str

        str = (lambda{|frame|
            if frame["type"] == "line" then
                return "[frame] [#{frame["uuid"][0, 4]}] [#{frame["type"]}] #{frame["line"]}"
            end
            if frame["type"] == "url" then
                return "[frame] [#{frame["uuid"][0, 4]}] [#{frame["type"]}] #{frame["url"]}"
            end
            if frame["type"] == "text" then
                namedhashToFirstLine = lambda {|namedhash|
                    text = NyxBlobs::getBlobOrNull(namedhash).strip
                    line = text.size>0 ? text.lines.first.strip : "[empty text]"
                }
                return "[frame] [#{frame["uuid"][0, 4]}] [#{frame["type"]}] #{namedhashToFirstLine.call(frame["namedhash"])}"
            end
            if frame["type"] == "aion-point" then
                return "[frame] [#{frame["uuid"][0, 4]}] [#{frame["type"]}] #{frame["namedhash"]}"
            end
            if frame["type"] == "unique-name" then
                return "[frame] [#{frame["uuid"][0, 4]}] [#{frame["type"]}] #{frame["name"]}"
            end
            raise "[Frames error 2c53b113-cc79]"
        }).call(frame)

        InMemoryWithOnDiskPersistenceValueCache::set("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{frame["uuid"]}", str)
        str
    end

    # Frames::openFrame(flock, frame)
    def self.openFrame(flock, frame)
        puts "flock:"
        puts JSON.pretty_generate(flock)
        puts "frame:"
        puts JSON.pretty_generate(frame)
        if frame["type"] == "line" then
            puts frame["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if frame["type"] == "url" then
            system("open '#{frame["url"]}'")
            return
        end
        if frame["type"] == "text" then
            system("clear")
            namedhash = frame["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            puts text
            LucilleCore::pressEnterToContinue()
            return
        end
        if frame["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForFrameCreateIfNotExists(flock, frame)
            system("open '#{folderpath}'")
            return
        end
        if frame["type"] == "unique-name" then
            uniquename = frame["name"]
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
        raise "[Frame error 4bf5cfb1-c2a2]"
    end
end
