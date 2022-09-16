
# encoding: UTF-8

class Nx113Make

    # Nx113Make::text(text) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.text(text)
        item = {
            "mikuType" => "Nx113",
            "type"     => "text",
            "text"     => text
        }
        DataStore1::putDataByContent(JSON.generate(item))
    end

    # Nx113Make::url(url) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.url(url)
        item = {
            "mikuType" => "Nx113",
            "type"     => "url",
            "url"      => url
        }
        DataStore1::putDataByContent(JSON.generate(item))
    end

    # Nx113Make::file(filepath) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.file(filepath)
        raise "(error: d3539fc0-5615-46ff-809b-85ac34850070)" if !File.exists?(filepath)

        operator = SQLiteDataStore2ElizabethTheForge.new()
        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        item = {
            "mikuType"        => "Nx113",
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts,
            "database"        => operator.publish()
        }
        DataStore1::putDataByContent(JSON.generate(item))
    end

    # Nx113Make::aionpoint(location) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.aionpoint(location)
        raise "(error: 93590239-f8e0-4f35-af47-d7f1407e21f2)" if !File.exists?(location)
        operator = SQLiteDataStore2ElizabethTheForge.new()
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        item = {
            "mikuType"   => "Nx113",
            "type"       => "aion-point",
            "rootnhash"  => rootnhash,
            "database"   => operator.publish()
        }
        DataStore1::putDataByContent(JSON.generate(item))
    end

    # Nx113Make::dx8Unit(unitId) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.dx8Unit(unitId)
        item = {
            "mikuType" => "Nx113",
            "type"     => "Dx8Unit",
            "unitId"   => unitId,
        }
        DataStore1::putDataByContent(JSON.generate(item))
    end

    # Nx113Make::uniqueString(uniquestring) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.uniqueString(uniquestring)
        item = {
            "mikuType"     => "Nx113",
            "type"         => "unique-string",
            "uniquestring" => uniquestring,
        }
        DataStore1::putDataByContent(JSON.generate(item))
    end
end

class Nx113Access

    # Nx113Access::getNx113(nhash)
    def self.getDataOrNullErrorIfNotFound(nhash)
        filepath = DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash)
        JSON.parse(IO.read(filepath))
    end

    # Nx113Access::access(nhash)
    def self.access(nhash)
        nx113 = Nx113Access::getNx113(nhash)

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
            databasefilepath = DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nx113["database"])
            operator         = SQLiteDataStore2ElizabethReadOnly.new(databasefilepath)
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
            databasefilepath = DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nx113["rootnhash"])
            operator         = SQLiteDataStore2ElizabethReadOnly.new(databasefilepath)
            rootnhash        = nx113["rootnhash"]
            parentLocation   = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(parentLocation)
            AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
            puts "Item exported at #{parentLocation}"
            LucilleCore::pressEnterToContinue()
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

    # Nx113Access::access2(itemNx113Carrier)
    def self.access2(itemNx113Carrier)
        Nx113Access::access(itemNx113Carrier["nx113"])
    end
end

class Nx113Edit

    # Nx113Edit::edit(itemNx113Carrier)
    def self.edit(itemNx113Carrier)
        nx113 = Nx113Access::getNx113(itemNx113Carrier["nx113"])

        if nx113["type"] == "text" then
            newtext = CommonUtils::editTextSynchronously(nx113["text"])
            nhash = Nx113Make::text(text)
            DxF1::setAttribute2(itemNx113Carrier["uuid"], "nx113", nhash)
        end

        if nx113["type"] == "url" then
            puts "current url: #{nx113["url"]}"
            url2 = LucilleCore::askQuestionAnswerAsString("new url: ")
            nhash = Nx113Make::url(url2)
            DxF1::setAttribute2(itemNx113Carrier["uuid"], "nx113", nhash)
        end

        if nx113["type"] == "file" then
            Nx113Access::access(itemNx113Carrier["nx113"])
            filepath = CommonUtils::interactivelySelectDesktopLocationOrNull()
            nhash = Nx113Make::file(filepath)
            DxF1::setAttribute2(itemNx113Carrier["uuid"], "nx113", nhash)
        end

        if nx113["type"] == "aion-point" then
            Nx113Access::access(itemNx113Carrier["nx113"])
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            nhash = Nx113Make::aionpoint(location)
            DxF1::setAttribute2(itemNx113Carrier["uuid"], "nx113", nhash)
        end

        if nx113["type"] == "Dx8Unit" then
            puts "Edit is not implemented for Dx8Units"
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "unique-string" then
            puts "Edit is not implemented for unique-string"
            LucilleCore::pressEnterToContinue()
        end
    end
end