
# encoding: UTF-8

class Nx101Structure

    # Nx101Structure::primitiveFileStructureFromLocationOrNull(location)
    def self.primitiveFileStructureFromLocationOrNull(location)
        data = Librarian17PrimitiveFilesAndCarriers::readPrimitiveFileOrNull(location)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        {
            "type"            => "primitive-file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
    end

    # Nx101Structure::interactivelySelectStructureTypeOrNull()
    def self.interactivelySelectStructureTypeOrNull()
        types = [
            "navigation",
            "atomic",
            "log",
            "primitive-file",
            "carrier-of-primitive-files"
        ]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("structure type", types)
    end

    # Nx101Structure::interactivelyCreateNewStructureOrNull()
    def self.interactivelyCreateNewStructureOrNull()
        type = Nx101Structure::interactivelySelectStructureTypeOrNull()
        return nil if type.nil?
        if type == "navigation" then
            return {
                "type" => "navigation"
            }
        end
        if type == "atomic" then
            atom = Librarian5Atoms::interactivelyIssueNewAtomOrNull()
            return nil if atom.nil?
            return {
                "type"     => "atomic",
                "atomuuid" => atom["uuid"]
            }
        end
        if type == "log" then
            return {
                "type" => "log"
            }
        end
        if type == "primitive-file" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Nx101Structure::primitiveFileStructureFromLocationOrNull(location)
        end
        if type == "carrier-of-primitive-files" then
            return {
                "type" => "carrier-of-primitive-files"
            }
        end
    end

    # Nx101Structure::accessStructure(item, structure)
    def self.accessStructure(item, structure)
        if structure["type"] == "navigation" then
            puts "This is a navigation node"
            LucilleCore::pressEnterToContinue()
        end
        if structure["type"] == "atomic" then
            atom = Librarian6Objects::getObjectByUUIDOrNull(structure["atomuuid"])
            if atom.nil? then
                puts "structure:"
                puts JSON.pretty_generate(structure)
                puts "Could not find the atom 😞 Do you want to run fsck or something ?"
                LucilleCore::pressEnterToContinue()
                return
            end
            Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
        end
        if structure["type"] == "primitive-file" then
            dottedExtension = structure["dottedExtension"]
            parts = structure["parts"]
            location = "/Users/pascal/Desktop"
            filepath = Librarian17PrimitiveFilesAndCarriers::exportPrimitiveFileAtLocation(item["uuid"], dottedExtension, parts, location)
            LucilleCore::pressEnterToContinue()
            if File.exists?(filepath) and LucilleCore::askQuestionAnswerAsBoolean("delete file ? ") then
                FileUtils.rm(filepath)
            end
        end
        if structure["type"] == "carrier-of-primitive-files" then
            Librarian17PrimitiveFilesAndCarriers::exportCarrier(item["uuid"])
        end
    end
end
