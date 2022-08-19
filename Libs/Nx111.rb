
# encoding: UTF-8

class Nx111

    # Nx111::types()
    def self.types()
        [
            "text",
            "url",
            "file",
            "unique-string",
            "Dx8Unit",
            "DxPure"
        ]
    end

    # Nx111::typesForNewItems()
    def self.typesForNewItems()
        [
            "text",
            "url",
            "file",
            "unique-string",
            "Dx8Unit",
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

    # Nx111::interactivelyCreateNewNx111OrNull(objectuuid)
    def self.interactivelyCreateNewNx111OrNull(objectuuid)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx111 type", Nx111::typesForNewItems())
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
            data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(objectuuid, location) # [dottedExtension, nhash, parts]
            raise "(error: a3339b50-e3df-4e5d-912d-a6b23aeb5c33)" if data.nil?
            dottedExtension, nhash, parts = data
            return {
                "uuid"            => SecureRandom.uuid,
                "type"            => "file",
                "dottedExtension" => dottedExtension,
                "nhash"           => nhash,
                "parts"           => parts
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
        if type == "DxPure" then
            sha1 = DxPure::interactivelyIssueNewOrNull(objectuuid)
            return nil if sha1.nil?
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "DxPure",
                "sha1" => sha1
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

        if nx111["type"] == "file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            operator = ExDataElizabeth.new(item["uuid"])
            filepath = "#{ENV['HOME']}/Desktop/#{nhash}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = operator.getBlobOrNull(nhash)
                    raise "(error: a614a728-fb28-455f-9430-43aab78ea35f)" if blob.nil?
                    f.write(blob)
                }
            }
            system("open '#{filepath}'")
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
end
