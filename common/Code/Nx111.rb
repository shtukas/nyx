
# encoding: UTF-8

class Nx111

    # Nx111::iamTypes()
    def self.iamTypes()
        [
            "navigation",
            "log",
            "description-only",
            "text",
            "url",
            "aion-point",
            "unique-string",
            "primitive-file",
            "carrier-of-primitive-files",
            "Dx8Unit"
        ]
    end

    # Nx111::iamTypesForManualMaking()
    def self.iamTypesForManualMaking()
        [
            "navigation",
            "log",
            "text",
            "url",
            "aion-point",
            "unique-string",
            "primitive-file",
            "carrier-of-primitive-files"
        ]
    end

    # Nx111::iamTypesForManualMakingOfCatalystItems()
    def self.iamTypesForManualMakingOfCatalystItems()
        [
            "description-only (default)",
            "text",
            "url",
            "aion-point",
            "unique-string"
        ]
    end

    # Nx111::interactivelySelectIamTypeOrNull(types)
    def self.interactivelySelectIamTypeOrNull(types)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("iam type", types)
        if type.nil? and types.include?("description-only (default)") then
            return "description-only"
        end
        type
    end

    # Nx111::locationToAionPointNx111OrNull(objectuuid, location)
    def self.locationToAionPointNx111OrNull(objectuuid, location)
        raise "(error: e53a9bfb-6901-49e3-bb9c-3e06a4046230) #{location}" if !File.exists?(location)
        rootnhash = AionCore::commitLocationReturnHash(Fx12sElizabethV2.new(objectuuid), location)
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
        if type == "navigation" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "navigation"
            }
        end
        if type == "log" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "log"
            }
        end
        if type == "description-only" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "description-only"
            }
        end
        if type == "description-only (default)" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "description-only"
            }
        end
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = Fx12sElizabethV2.new(objectuuid).commitBlob(text)
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
        if type == "primitive-file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return PrimitiveFiles::locationToPrimitiveFileNx111OrNull(objectuuid, SecureRandom.uuid, location)
        end
        if type == "carrier-of-primitive-files" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "carrier-of-primitive-files"
            }
        end
        raise "(error: aae1002c-2f78-4c2b-9455-bdd0b5c0ebd6): #{type}"
    end
end
