
# encoding: UTF-8

class Nx111

    # Nx111::types()
    def self.types()
        [
            "text",
            "url",
            "aion-point",
            "unique-string",
            "Dx8Unit"
        ]
    end

    # Nx111::interactivelySelectIamTypeOrNull(types)
    def self.interactivelySelectIamTypeOrNull(types)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("nx111 type", types)
    end

    # Nx111::locationToAionPointNx111OrNull(location)
    def self.locationToAionPointNx111OrNull(location)
        raise "(error: e53a9bfb-6901-49e3-bb9c-3e06a4046230) #{location}" if !File.exists?(location)
        rootnhash = AionCore::commitLocationReturnHash(EnergyGridElizabeth.new(), location)
        {
            "uuid"      => SecureRandom.uuid,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }
    end

    # Nx111::interactivelyCreateNewIamValueOrNull(types, objectuuid)
    def self.interactivelyCreateNewIamValueOrNull(types, objectuuid)
        type = Nx111::interactivelySelectIamTypeOrNull(types)
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = EnergyGridElizabeth.new().commitBlob(text)
            return {
                "uuid"  => SecureRandom.uuid,
                "type"  => "text",
                "nhash" => nhash
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
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Nx111::locationToAionPointNx111OrNull(location)
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
        "(nx111) #{nx111["type"]}"
    end

    # Nx111::toStringShort(nx111)
    def self.toStringShort(nx111)
        "#{nx111["type"]}"
    end
end
