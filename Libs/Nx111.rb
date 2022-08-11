
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

    # Nx111::interactivelySelectIamTypeOrNull(types)
    def self.interactivelySelectIamTypeOrNull(types)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("nx111 type", types)
    end

    # Nx111::locationToAionPointNx111OrNull(objectuuid, location)
    def self.locationToAionPointNx111OrNull(objectuuid, location)
        raise "(error: e53a9bfb-6901-49e3-bb9c-3e06a4046230) #{location}" if !File.exists?(location)
        operator = ExDataElizabeth.new(objectuuid)
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        {
            "uuid"      => SecureRandom.uuid,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }
    end

    # Nx111::interactivelyCreateNewNx111OrNull(objectuuid)
    def self.interactivelyCreateNewNx111OrNull(objectuuid)
        type = Nx111::interactivelySelectIamTypeOrNull(Nx111::types())
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
            return Nx111::locationToAionPointNx111OrNull(objectuuid, location)
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
        "(nx111) #{nx111["type"]}"
    end

    # Nx111::toStringShort(nx111)
    def self.toStringShort(nx111)
        "#{nx111["type"]}"
    end

    # Nx111::access(item, nx111)
    def self.access(item, nx111)
        return if nx111.nil?

        if nx111["type"] == "aion-point" then

            rootnhash = nx111["rootnhash"]
            puts "You are accesssing a Nx111 type aion-point (#{JSON.pretty_generate(nx111)})"
            puts "We are currently in the process to migrate them to Nx111 DxPureAionPoint"
            LucilleCore::pressEnterToContinue()

            randomValue  = SecureRandom.hex
            mikuType     = "DxPureAionPoint"
            unixtime     = Time.new.to_i
            datetime     = Time.new.utc.iso8601
            # owner
            # location

            filepath1 = "/tmp/#{SecureRandom.hex}.sqlite3"
            DxPure::makeNewPureFile(filepath1)

            puts "fsck, migration"
            operator = DxPureElizabethFsck1_Migration.new(filepath1)
            status = AionFsck::structureCheckAionHash(operator, rootnhash) # This will move the data into the DxPure
            if !status then
                raise "(3c5521bc-a224-4c57-9c0b-1e0e9b176383)"
            end

            puts "fsck, structure"
            operator = DxPureElizabeth.new(filepath1)
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                raise "(0a5ff16e-7e3c-49fd-9735-13b4a6a9eb21)"
            end

            owner = item["uuid"]

            DxPure::insertIntoPure(filepath1, "randomValue", randomValue)
            DxPure::insertIntoPure(filepath1, "mikuType", mikuType)
            DxPure::insertIntoPure(filepath1, "unixtime", unixtime)
            DxPure::insertIntoPure(filepath1, "datetime", datetime)
            DxPure::insertIntoPure(filepath1, "owner", owner)
            DxPure::insertIntoPure(filepath1, "rootnhash", rootnhash)

            DxPure::fsckFileRaiseError(filepath1)

            sha1 = Digest::SHA1.file(filepath1).hexdigest

            filepath2 = DxPure::sha1ToLocalFilepath(sha1)

            FileUtils.mv(filepath1, filepath2)

            nx111_v2 = {
                "uuid" => SecureRandom.uuid,
                "type" => "DxPure",
                "sha1" => sha1
            }

            puts "new:"
            puts JSON.pretty_generate(nx111_v2)

            puts "Next action: putting the new Nx111 #{JSON.pretty_generate(nx111_v2)} into item: #{JSON.pretty_generate(item)}"
            LucilleCore::pressEnterToContinue()

            Fx18Attributes::setJsonEncodeObjectMaking(item["uuid"], "nx111", nx111_v2)

            # Done
            # Now we just need to actually access the new DxPure

            item = Fx18s::getItemAliveOrNull(item["uuid"])

            puts "Done. Here is the new situation:"
            puts "item: #{JSON.pretty_generate(item)}"
            puts "We are going to run with that"
            LucilleCore::pressEnterToContinue()

            nx111 = item["nx111"]
            Nx111::access(item, nx111)

            return
        end

        if nx111["type"] == "DxPure" then
            sha1 = nx111["sha1"]
            DxPure::access(sha1)
            return
        end

        puts "Code to be written (8cfc7215-743a-418f-9f92-9e40c22f27ab)"
        exit
    end
end
