
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

    # Nx113Make::file(filepath) # Nx113
    def self.file(filepath)
        raise "(error: d3539fc0-5615-46ff-809b-85ac34850070)" if !File.exists?(filepath)

        operator = DataStore2SQLiteBlobStoreElizabethTheForge.new()
        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        {
            "mikuType"        => "Nx113",
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts,
            "database"        => operator.publish()
        }
    end

    # Nx113Make::aionpoint(location) # Nx113
    def self.aionpoint(location)
        raise "(error: 93590239-f8e0-4f35-af47-d7f1407e21f2)" if !File.exists?(location)
        operator = DataStore2SQLiteBlobStoreElizabethTheForge.new()
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        {
            "mikuType"   => "Nx113",
            "type"       => "aion-point",
            "rootnhash"  => rootnhash,
            "database"   => operator.publish()
        }
    end

    # Nx113Make::interactivelyMakeNx113AionPoint()
    def self.interactivelyMakeNx113AionPoint()
        location = CommonUtils::interactivelySelectDesktopLocation()
        Nx113Make::aionpoint(location)
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

    # Nx113Make::interactivelyMakeNx113OrNull() # Nx113
    def self.interactivelyMakeNx113OrNull()
        type = Nx113Make::interactivelySelectOneNx113TypeOrNull()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            nx113 = Nx113Make::text(text)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            nx113 = Nx113Make::url(url)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            nx113 = Nx113Make::file(filepath)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "aion-point" then
            nx113 = Nx113Make::interactivelyMakeNx113AionPoint()
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
            return nil if  unitId == ""
            nx113 = Nx113Make::dx8Unit(unitId)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring.nil?
            nx113 = Nx113Make::uniqueString(uniquestring)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        raise "(error: 0d26fe42-8669-4f33-9a09-aeecbd52c77c)"
    end
end

class Nx113Access

    # Nx113Access::accessAionPointAtExportDirectory(rootnhash, database, parentLocation)
    def self.accessAionPointAtExportDirectory(rootnhash, database, parentLocation)
        databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(database, true)
        operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
        if !File.exists?(parentLocation) then
            FileUtils.mkdir(parentLocation)
        end
        AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
    end

    # Nx113Access::accessAionPoint(rootnhash, database)
    def self.accessAionPoint(rootnhash, database)
        exportDirectory = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
        Nx113Access::accessAionPointAtExportDirectory(rootnhash, database, exportDirectory)
        puts "Item exported at #{exportDirectory}"
        LucilleCore::pressEnterToContinue()
    end

    # Nx113Access::access(nx113)
    def self.access(nx113)

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
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(nx113["database"], true)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
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
            Nx113Access::accessAionPoint(nx113["rootnhash"], nx113["database"])
        end

        if nx113["type"] == "Dx8Unit" then
            unitId = nx113["unitId"]
            location = Dx8UnitsUtils::acquireUnitFolderPathOrNull(unitId)
            if location.nil? then
                puts "I could not acquire the Dx8Unit. Aborting operation."
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "location: #{location}"
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
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "unique-string" then
            uniquestring = item["uniquestring"]
            UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
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

    # Nx113Edit::editAionPointComponents(rootnhash, database) # {rootnhash, database}
    def self.editAionPointComponents(rootnhash, database) # {rootnhash, database}
        databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(database, true)
        operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
        exportLocation   = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
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

        operator = DataStore2SQLiteBlobStoreElizabethTheForge.new()
        location = acquireLocationInsideExportFolder.call(exportLocation)
        puts "reading: #{location}"
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        return {
            "rootnhash"  => rootnhash,
            "database"   => operator.publish()
        }
    end

    # Nx113Edit::editNx113(nx113) # Nx113 or null if no change
    def self.editNx113(nx113)

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
            Nx113Access::access(item["nx113"])
            filepath = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if filepath.nil?
            return Nx113Make::file(filepath)
        end

        if nx113["type"] == "aion-point" then
            packet = Nx113Edit::editAionPointComponents(nx113["rootnhash"], nx113["database"])
            nx113 = {
                "mikuType"   => "Nx113",
                "type"       => "aion-point",
                "rootnhash"  => packet["rootnhash"],
                "database"   => packet["database"]
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
        nx113v2 = Nx113Edit::editNx113(nx113)
        return if nx113v2.nil?
        item["nx113"] = nx113v2
        PolyActions::commit(item)
    end
end

class Nx113Dx33s

    # Nx113Dx33s::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, SecureRandom.hex, false)
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

class Nx113Transforms

    # Nx113Transforms::transformDx8UnitToAionPointOrNull(nx113)
    def self.transformDx8UnitToAionPointOrNull(nx113)
        return nil if nx113["type"] != "Dx8Unit" # Not the right Nx113 type
        # We access the unit if we can, and then make a aion point, and then issue a Dx33
        unitId = nx113["unitId"]
        location = Dx8UnitsUtils::acquireUnitFolderPathOrNull(unitId)
        return nil if !File.exists?(location) # Dx8Unit is not reachable
        nx113v2 = Nx113Make::aionpoint(location) # Nx113
        # We should not forget to issue the Dx33
        Nx113Dx33s::issue(unitId)
        nx113v2
    end

    # Nx113Transforms::mutateItemIfCarryingDx8UnitToCarryAionPoint(item)
    def self.mutateItemIfCarryingDx8UnitToCarryAionPoint(item)
        return if item["nx113"].nil?
        nx113v2 = Nx113Transforms::transformDx8UnitToAionPointOrNull(item["nx113"])
        return if nx113v2.nil?
        FileSystemCheck::fsck_Nx113(nx113v2, SecureRandom.hex, true)
        puts "Nx113Transforms::mutateItemIfCarryingDx8UnitToCarryAionPoint: #{PolyFunctions::toString(item).green}, #{JSON.pretty_generate(item["nx113"])}, #{JSON.pretty_generate(nx113v2)}"
        puts JSON.pretty_generate(item)
        item["nx113"] = nx113v2
        puts JSON.pretty_generate(item)
        PolyActions::commit(item)
    end

    # Nx113Transforms::transformDx8UnitToAionPointsDuringEnergyGridUpdate()
    def self.transformDx8UnitToAionPointsDuringEnergyGridUpdate()
        NxTodos::listingItems().each{|item|
            Nx113Transforms::mutateItemIfCarryingDx8UnitToCarryAionPoint(item)
        }
    end
end
