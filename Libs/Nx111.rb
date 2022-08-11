
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

        EditionDesk::accessItemNx111Pair(item, nx111)
        return

        if nx111["type"] == "url" then
            url = nx111["url"]
            puts "You are accesssing a Nx111 type url (#{url})"
            puts "We are currently in the process to migrate them to Nx111 DxPure (Urls)"
            LucilleCore::pressEnterToContinue()

            puts "origin:"
            puts JSON.pretty_generate(nx111)

            sha1 = DxPureUrl::issue(item["uuid"], url)
            nx111_v2 = {
                "uuid" => SecureRandom.uuid,
                "type" => "DxPure",
                "sha1" => sha1
            }

            puts "new:"
            puts JSON.pretty_generate(nx111_v2)

            puts "Next action: putting the new Nx111 into item: #{JSON.pretty_generate(item)}"
            LucilleCore::pressEnterToContinue()

            Fx18Attributes::setJsonEncodeObjectMaking(item["uuid"], "nx111", nx111_v2)

            # Done
            # Now we just need to actually access the new DxPure

            item = Fx18s::getItemAliveOrNull(item["uuid"])
            nx111 = item["nx111"]

            puts "Done. Here is the new situation:"
            puts "item: #{JSON.pretty_generate(item)}"
            puts "We are going to run with that"
            LucilleCore::pressEnterToContinue()

            Nx111::access(item, nx111)

            return
        end

        EditionDesk::accessItemNx111Pair(item, nx111)
    end
end
