
# encoding: UTF-8

class Dx8UnitsUtils
    # Dx8UnitsUtils::infinityRepository()
    def self.infinityRepository()
        "#{Config::pathToInfinityDidact()}/Dx8Units"
    end

    # Dx8UnitsUtils::dx8UnitFolder(dx8UnitId)
    def self.dx8UnitFolder(dx8UnitId)
        "#{Dx8UnitsUtils::infinityRepository()}/#{dx8UnitId}"
    end
end

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

    # Nx111::iamTypesForManualMakingOfNyxNodes()
    def self.iamTypesForManualMakingOfNyxNodes()
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

    # Nx111::iamTypesForManualMakingOfNyxNodesAttachment()
    def self.iamTypesForManualMakingOfNyxNodesAttachment()
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

    # Nx111::locationToPrimitiveFileDataArrayOrNull(filepath) # [dottedExtension, nhash, parts]
    def self.locationToPrimitiveFileDataArrayOrNull(filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
 
        dottedExtension = File.extname(filepath)
 
        nhash = Librarian0Utils::filepathToContentHash(filepath)
 
        lambdaBlobCommitReturnNhash = lambda {|blob|
            InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::putBlob(blob)
        }
        parts = Librarian0Utils::commitFileToXCacheReturnPartsHashsImproved(filepath, lambdaBlobCommitReturnNhash)
 
        return [dottedExtension, nhash, parts]
    end

    # Nx111::locationToPrimitiveFileNx111OrNull(uuid, filepath)
    def self.locationToPrimitiveFileNx111OrNull(uuid, filepath)
        data = Nx111::locationToPrimitiveFileDataArrayOrNull(filepath)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        {
            "uuid"  => uuid,
            "type"  => "primitive-file",
            "dottedExtension" => dottedExtension,
            "nhash" => nhash,
            "parts" => parts
        }
    end

    # Nx111::locationToAionPointNx111OrNull(location)
    def self.locationToAionPointNx111OrNull(location)
        raise "(error: e53a9bfb-6901-49e3-bb9c-3e06a4046230) #{location}" if !File.exists?(location)
        rootnhash = AionCore::commitLocationReturnHash(InfinityElizabeth_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching.new(), location)
        {
            "uuid"      => SecureRandom.uuid,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }
    end

    # Nx111::interactivelyCreateNewIamValueOrNull(types)
    def self.interactivelyCreateNewIamValueOrNull(types)
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
            text = Librarian0Utils::editTextSynchronously("")
            nhash = InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::putBlob(text)
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
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
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
        if type == "primitive-file" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Nx111::locationToPrimitiveFileNx111OrNull(SecureRandom.uuid, location)
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
