
# encoding: UTF-8

class Nx111

    # Nx111::types()
    def self.types()
        [
            "text",
            "url",
            "file",
            "aion-point",
            "unique-string",
            "Dx8Unit",
            "DxPure"
        ]
    end

    # Nx111::typesForNewObjects()
    def self.typesForNewObjects()
        [
            "text",
            "url",
            "file",
            "aion-point",
            "unique-string",
            "Dx8Unit"
        ]
    end

    # Nx111::locationToNx111DxPureAionPoint(objectuuid, location)
    def self.locationToNx111DxPureAionPoint(objectuuid, location)
        raise "(error: e53a9bfb-6901-49e3-bb9c-3e06a4046230) #{location}" if !File.exists?(location)
        sha1 = DxPure::issueDxPureAionPoint(objectuuid, location)
        {
            "uuid" => SecureRandom.uuid,
            "type" => "DxPure",
            "sha1" => sha1
        }
    end

    # Nx111::locationToNx111DxPureFileOrNull(objectuuid, location) # Nx111
    def self.locationToNx111DxPureFileOrNull(objectuuid, location)
        raise "[b54a34d7-4717-4478-bb4e-64f665a2b686, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[386e4a91-9580-4711-8a71-209472a2e17c, filepath: #{filepath}]" if !File.file?(filepath)
        filepath = location
        sha1 = DxPure::issueDxPureFile(objectuuid, filepath)
        {
            "uuid" => SecureRandom.uuid,
            "type" => "DxPure",
            "sha1" => sha1
        }
    end

    # Nx111::interactivelyCreateNewNx111OrNull(objectuuid)
    def self.interactivelyCreateNewNx111OrNull(objectuuid)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx111 type", Nx111::typesForNewObjects())
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "text",
                "text" => text
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url",
                "url"  => url
            }
        end
        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            sha1 = DxPure::issueDxPureFile(objectuuid, filepath)
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "DxPure",
                "sha1" => sha1
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            sha1 = DxPure::issueDxPureAionPoint(objectuuid, location)
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "DxPure",
                "sha1" => sha1
            }
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (use 'Nx01-#{SecureRandom.hex(6)}' if need one): ")
            return nil if uniquestring == ""
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        raise "(error: aae1002c-2f78-4c2b-9455-bdd0b5c0ebd6): #{type}"
    end

    # Nx111::toString(nx111)
    def self.toString(nx111)
        if nx111.nil? then
            return "(nx111) null"
        end
        "(nx111) #{nx111["type"]}"
    end

    # Nx111::toStringShort(nx111)
    def self.toStringShort(nx111)
        if nx111.nil? then
            return "(nx111) null"
        end
        "#{nx111["type"]}"
    end

    # Nx111::access(item, nx111)
    def self.access(item, nx111)
        return if nx111.nil?

        if nx111["type"] == "url" then
            url = nx111["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            return
        end

        if nx111["type"] == "text" then
            text = nx111["text"]
            CommonUtils::accessText(text)
            LucilleCore::pressEnterToContinue()
            return
        end

        if nx111["type"] == "DxPure" then
            sha1 = nx111["sha1"]
            DxPure::access(sha1)
            return
        end

        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::acquireUnit(unitId)
            if location.nil? then
                puts "I could not acquire the Dx8Unit. Aborting operation."
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "location: #{location}"
            StargateCentral::ensureEnergyGrid1()
            if LucilleCore::locationsAtFolder(location).size == 1 and LucilleCore::locationsAtFolder(location).first[-5, 5] == ".webm" then
                location2 = LucilleCore::locationsAtFolder(location).first
                if File.basename(location2).include?("'") then
                    location3 = "#{File.dirname(location2)}/#{File.basename(location2).gsub("'", "-")}"
                    FileUtils.mv(location2, location3)
                    location2 = location3
                end
                location = location2
            end
            system("open '#{location}'")
            return
        end

        if nx111["type"] == "unique-string" then
            uniquestring = nx111["uniquestring"]
            UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
            return
        end

        puts "Code to be written (33685044-382e-4e98-bf8c-6fb4cf31ce1c)"
        exit
    end

    # Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
    def self.fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
        return if nx111.nil?

        repeatKey = "d17407ac-1c38-4b03-bbe7-66ff9cf8039a:#{objectuuid}:#{JSON.generate(nx111)}"
        return if XCache::getFlag(repeatKey)

        puts "Nx111::fsckNx111NoRepeatErrorAtFirstFailure(#{objectuuid}, #{nx111})"

        if objectuuid.nil? then
            puts "objectuuid: #{objectuuid}".red
            puts "Malformed Fx18 file, I could not find a uuid".red
            raise "Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
        end

        if !Nx111::types().include?(nx111["type"]) then
            puts "objectuuid has an incorrect nx111 value type".red
            puts "objectuuid: #{objectuuid}".red
            puts "nx111: type: #{JSON.pretty_generate(nx111["type"])}".red
            raise "Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
        end

        if nx111["type"] == "text" then
            text = nx111["text"]
            if text.nil? then
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "Fx18FileDataForFsck::getBlobOrNull(objectuuid, nhash): could not find the text".red
                raise "Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
            end
            XCache::setFlag(repeatKey, true)
            return
        end

        if nx111["type"] == "url" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if nx111["type"] == "unique-string" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::acquireUnit(unitId)
            if location.nil? then
                puts "I could not acquire the Dx8Unit. Aborting operation."
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "Dx8Unit: location: #{location}"
            if !File.exists?(location) then
                puts "note: could not find location for Dx8Unit: #{unitId}".red
            end
            XCache::setFlag(repeatKey, true)
            return
        end

        if nx111["type"] == "DxPure" then
            sha1 = nx111["sha1"]
            DxPure::fsckSha1RaiseError(sha1)
            XCache::setFlag(repeatKey, true)
            return
        end

        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect nx111 value: #{nx111})"
    end
end
