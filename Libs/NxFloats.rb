# encoding: UTF-8

class NxFloats

    # --------------------------------------------------
    # IO

    # NxFloats::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxFloats"
    end

    # NxFloats::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{NxFloats::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # NxFloats::nxfloats()
    def self.nxfloats()
        LucilleCore::locationsAtFolder(NxFloats::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # NxFloats::getNxFloatByUUIDOrNull(uuid)
    def self.getNxFloatByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxFloats::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxFloats::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxFloats::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxFloats::axiomsFolderPath()
    def self.axiomsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxFloats-axioms"
    end

    # --------------------------------------------------
    # Making

    # NxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        unixtime     = Time.new.to_f

        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(NxFloats::axiomsFolderPath(), LucilleCore::timeStringL22())

        float = {
          "uuid"           => uuid,
          "unixtime"       => unixtime,
          "description"    => description,
          "axiomId"        => axiomId
        }

        NxFloats::commitFloatToDisk(float)

        float
    end

    # --------------------------------------------------
    # Operations

    # NxFloats::toString(item)
    def self.toString(item)
        "[float] #{item["description"]}"
    end

    # NxFloats::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(NxFloats::axiomsFolderPath(), item["axiomId"])
    end

    # --------------------------------------------------

    # NxFloats::run(nxfloat)
    def self.run(nxfloat)
        puts NxFloats::toString(nxfloat)
        NxFloats::accessContent(nxfloat)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{NxFloats::toString(nxfloat)}' ? ") then
            NxFloats::destroy(nxfloat)
        end
    end

    # NxFloats::nx19s()
    def self.nx19s()
        NxFloats::nxfloats().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxFloats::toString(item),
                "lambda"   => lambda { NxFloats::run(item) }
            }
        }
    end
end
