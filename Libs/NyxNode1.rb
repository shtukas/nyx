# encoding: UTF-8

=begin
NyxNode1 {
    "uuid"        : String
    "mikuType"    : "NyxNode1"
    "unixtime"    : Float
    "datetime"    : DateTime Iso 8601 UTC Zulu
    "description" : String
}
=end

class NyxNode1

    # --------------------------------------------
    # IO

    # NyxNode1::pathToObjectsRepository()
    def self.pathToObjectsRepository()
        "#{Config::userHomeDirectory()}/Galaxy/NxData/03-Nyx/01-Objects"
    end

    # NyxNode1::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{NyxNode1::pathToObjectsRepository()}/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NyxNode1::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{NyxNode1::pathToObjectsRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxNode1::items()
    def self.items()
        folderpath = NyxNode1::pathToObjectsRepository()
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NyxNode1::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{NyxNode1::pathToObjectsRepository()}/#{uuid}.json"
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # 

    # NyxNode1::interacrtivelyMakeNoteOrNull()
    def self.interacrtivelyMakeNoteOrNull()
        note = nil
        if LucilleCore::askQuestionAnswerAsBoolean("add note ? :") then
            note = CommonUtils::editTextSynchronously("")
        end
        note
    end

    # NyxNode1::issueUniqueStringOrNull()
    def self.issueUniqueStringOrNull()

        # We can either:
        # 1. provide the unique string
        # 2. the unique string is generated and the folder created at Nyx
        # 3. the unique string is generated and you have to use it yourself.
        # 4. A drop is generated for you, it's an empty file with a .nyx2 extension that carries the unique string in its name.
        # 5. Decide to go with a null unique string (if for instance the note is what matters)

        option1 = "no unique string (node note focused) (default)",
        option2 = "generate string and show",
        option3 = "generate string and create folder",
        option4 = "generate drop file (for existing folder)"
        option5 = "enter unique string"

        options = [ option1, option2, option3, option4, option5 ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)

        if option.nil? then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm no unique string: ") then
                return nil
            else
                return NyxNode1::issueUniqueStringOrNull()
            end
        end

        if option == option1 then
            return nil
        end

        if option == option2 then
            uniquestring = "Nx01-#{SecureRandom.hex(5)}"
            puts "unique string: #{uniquestring}"
            LucilleCore::pressEnterToContinue()
            return uniquestring
        end

        if option == option3 then
            uniquestring = SecureRandom.hex(6)
            puts "unique string: #{uniquestring}"
            foldername = uniquestring
            folderpath = "#{Config::pathToGalaxy()}/NxData/03-Nyx/02-Timeline/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{uniquestring}"
            puts "creating and opening folder"
            if !File.exists?(folderpath) then
                FileUtils.mkpath(folderpath)
            end
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return uniquestring
        end

        if option == option4 then
            uniquestring = SecureRandom.hex(6)
            filename = "#{uniquestring}.nxy2"
            filepath = "#{Config::userHomeDirectory()}/Desktop/#{filename}"
            puts "creating drop file at [desktop] #{File.dirname(filepath)}"
            FileUtils.touch(filepath)
            LucilleCore::pressEnterToContinue()
            return uniquestring
        end

        if option == option5 then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string: ")
            return uniquestring
        end

        raise "(error: adef292f-1765-4f92-b26a-9b5fef01125a) How did that happen ?"
    end

    # NyxNode1::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        note = NyxNode1::interacrtivelyMakeNoteOrNull()
        uniquestring = NyxNode1::issueUniqueStringOrNull()
        node = {
            "uuid"         => SecureRandom.uuid,
            "mikuType"     => "NyxNode1",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "note"         => note,
            "uniquestring" => uniquestring
        }
        NyxNode1::commit(node)
        node
    end
end