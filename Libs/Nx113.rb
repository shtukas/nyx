
# encoding: UTF-8

class Nx113Make

    # Nx113Make::text(text) # Nx113
    def self.text(text)
        {
            "mikuType" => "Nx113",
            "type"     => "text",
            "text"     => text
        }
    end

    # Nx113Make::url(url) # Nx113
    def self.url(url)
        {
            "mikuType" => "Nx113",
            "type"     => "url",
            "url"      => url
        }
    end

    # Nx113Make::file(operator, filepath) # Nx113
    def self.file(operator, filepath)
        raise "(error: d3539fc0-5615-46ff-809b-85ac34850070)" if !File.exists?(filepath)
        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(operator, filepath) # [dottedExtension, nhash, parts]

        {
            "mikuType"        => "Nx113",
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
    end

    # Nx113Make::aionpoint(operator, location) # Nx113
    def self.aionpoint(operator, location)
        raise "(error: 93590239-f8e0-4f35-af47-d7f1407e21f2)" if !File.exists?(location)
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        {
            "mikuType"  => "Nx113",
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }
    end

    # Nx113Make::interactivelyMakeNx113AionPoint(operator)
    def self.interactivelyMakeNx113AionPoint(operator)
        location = CommonUtils::interactivelySelectDesktopLocation()
        Nx113Make::aionpoint(operator, location)
    end

    # Nx113Make::dx8Unit(unitId) # Nx113
    def self.dx8Unit(unitId)
        {
            "mikuType" => "Nx113",
            "type"     => "Dx8Unit",
            "unitId"   => unitId,
        }
    end

    # Nx113Make::uniqueString(uniquestring) # Nx113
    def self.uniqueString(uniquestring)
        {
            "mikuType"     => "Nx113",
            "type"         => "unique-string",
            "uniquestring" => uniquestring,
        }
    end

    # Nx113Make::types()
    def self.types()
        ["text", "url", "file", "aion-point", "Dx8Unit", "unique-string"]
    end

    # Nx113Make::interactivelySelectOneNx113TypeOrNull()
    def self.interactivelySelectOneNx113TypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Nx113Make::types())
    end

    # Nx113Make::interactivelyMakeNx113OrNull(operator) # Nx113
    def self.interactivelyMakeNx113OrNull(operator)
        type = Nx113Make::interactivelySelectOneNx113TypeOrNull()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            nx113 = Nx113Make::text(text)
            FileSystemCheck::fsck_Nx113(operator, nx113, true)
            return nx113
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            nx113 = Nx113Make::url(url)
            FileSystemCheck::fsck_Nx113(operator, nx113, true)
            return nx113
        end
        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            nx113 = Nx113Make::file(operator, filepath)
            FileSystemCheck::fsck_Nx113(operator, nx113, true)
            return nx113
        end
        if type == "aion-point" then
            nx113 = Nx113Make::interactivelyMakeNx113AionPoint(operation)
            FileSystemCheck::fsck_Nx113(operator, nx113, true)
            return nx113
        end
        if type == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
            return nil if  unitId == ""
            nx113 = Nx113Make::dx8Unit(unitId)
            FileSystemCheck::fsck_Nx113(operator, nx113, true)
            return nx113
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring.nil?
            nx113 = Nx113Make::uniqueString(uniquestring)
            FileSystemCheck::fsck_Nx113(operator, nx113, true)
            return nx113
        end
        raise "(error: 0d26fe42-8669-4f33-9a09-aeecbd52c77c)"
    end
end

class Nx113Access

    # Nx113Access::accessAionPointAtExportDirectory(operator, rootnhash, parentLocation)
    def self.accessAionPointAtExportDirectory(operator, rootnhash, parentLocation)
        if !File.exists?(parentLocation) then
            FileUtils.mkdir(parentLocation)
        end
        AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
    end

    # Nx113Access::accessAionPoint(operator, rootnhash)
    def self.accessAionPoint(operator, rootnhash)
        exportDirectory = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
        Nx113Access::accessAionPointAtExportDirectory(operator, rootnhash, exportDirectory)
        puts "Item exported at #{exportDirectory}"
        LucilleCore::pressEnterToContinue()
    end

    # Nx113Access::access(operator, nx113)
    def self.access(operator, nx113)

        if nx113["type"] == "text" then
            CommonUtils::accessText(nx113["text"])
        end

        if nx113["type"] == "url" then
            url = nx113["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
        end

        if nx113["type"] == "file" then
            dottedExtension  = nx113["dottedExtension"]
            nhash            = nx113["nhash"]
            parts            = nx113["parts"]
            filepath         = "#{ENV['HOME']}/Desktop/#{nhash}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = operator.getBlobOrNull(nhash)
                    raise "(error: 13709695-3dca-493b-be46-62d4ef6cf18f)" if blob.nil?
                    f.write(blob)
                }
            }
            system("open '#{filepath}'")
            puts "Item exported at #{filepath}"
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "aion-point" then
            Nx113Access::accessAionPoint(operator, nx113["rootnhash"])
        end

        if nx113["type"] == "Dx8Unit" then
            unitId = nx113["unitId"]
            Dx8Units::access(unitId)
        end

        if nx113["type"] == "unique-string" then
            uniquestring = item["uniquestring"]
            UniqueStrings::findAndAccessUniqueString(uniquestring)
        end
    end

    # Nx113Access::toStringOrNull(prefix, nx113, postfix)
    def self.toStringOrNull(prefix, nx113, postfix)
        return nil if nx113.nil?
        "#{prefix}(Nx113: #{nx113["type"]})#{postfix}"
    end

    # Nx113Access::toStringOrNullShort(prefix, nx113, postfix)
    def self.toStringOrNullShort(prefix, nx113, postfix)
        return nil if nx113.nil?
        "#{prefix}(#{nx113["type"]})#{postfix}"
    end
end

class Nx113Edit

    # Nx113Edit::editAionPoint(operator, rootnhash)
    def self.editAionPoint(operator, rootnhash)
        exportLocation = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(exportLocation)
        AionCore::exportHashAtFolder(operator, rootnhash, exportLocation)
        puts "Item exported at #{exportLocation} for edition"
        LucilleCore::pressEnterToContinue()

        acquireLocationInsideExportFolder = lambda {|exportLocation|
            locations = LucilleCore::locationsAtFolder(exportLocation).select{|loc| File.basename(loc)[0, 1] != "."}
            if locations.size == 0 then
                puts "I am in the middle of a Nx113 aion-point edit. I cannot see anything inside the export folder"
                puts "Exit"
                exit
            end
            if locations.size == 1 then
                return locations[0]
            end
            if locations.size > 1 then
                puts "I am in the middle of a Nx113 aion-point edit. I found more than one location in the export folder."
                puts "Exit"
                exit
            end
        }

        location = acquireLocationInsideExportFolder.call(exportLocation)
        puts "reading: #{location}"
        AionCore::commitLocationReturnHash(operator, location)
    end

    # Nx113Edit::editNx113(operator, nx113) # Nx113 or null if no change
    def self.editNx113(operator, nx113)

        if nx113["type"] == "text" then
            text1 = nx113["text"]
            text2 = CommonUtils::editTextSynchronously(text1)
            if text2 != text1 then
                return Nx113Make::text(text2)
            else
                return nil
            end
        end

        if nx113["type"] == "url" then
            puts "current url: #{nx113["url"]}"
            url2 = LucilleCore::askQuestionAnswerAsString("new url: ")
            return Nx113Make::url(url2)
        end

        if nx113["type"] == "file" then
            Nx113Access::access(operator, item["nx113"])
            filepath = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if filepath.nil?
            return Nx113Make::file(operator, filepath)
        end

        if nx113["type"] == "aion-point" then
            rootnhash = Nx113Edit::editAionPoint(operator, nx113["rootnhash"])
            nx113 = {
                "mikuType"   => "Nx113",
                "type"       => "aion-point",
                "rootnhash"  => rootnhash
            }
            return nx113
        end

        if nx113["type"] == "Dx8Unit" then
            puts "Edit is not implemented for Dx8Units"
            LucilleCore::pressEnterToContinue()
            return nil
        end

        if nx113["type"] == "unique-string" then
            puts "Edit is not implemented for unique-string"
            LucilleCore::pressEnterToContinue()
            return nil
        end
    end

    # Nx113Edit::editNx113Carrier(item)
    def self.editNx113Carrier(item)
        return if item["nx113"].nil?
        nx113 = item["nx113"]

        operator = nil
        if item["mikuType"] == "NxTodo" then
            operator = NxTodos::getElizabethOperatorForItem(item)
        end

        nx113v2 = Nx113Edit::editNx113(operator, nx113)
        return if nx113v2.nil?
        item["nx113"] = nx113v2
        PolyActions::commit(item)
    end
end

class Nx113Dx33s

    # Nx113Dx33s::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{Config::pathToDataCenter()}/Dx33/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Nx113Dx33s::issue(unitId)
    def self.issue(unitId)
        dx33 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Dx33",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
            "unitId"      => unitId
        }
        puts JSON.pretty_generate(dx33)
        Nx113Dx33s::commit(item)
    end

    # Nx113Dx33s::getItems()
    def self.getItems()
        folderpath = "#{Config::pathToDataCenter()}/Dx33"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Nx113Dx33s::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/Dx33/#{item["uuid"]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
