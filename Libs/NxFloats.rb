# encoding: UTF-8

class NxFloats

    # --------------------------------------------------
    # IO

    # NxFloats::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxFloats"
    end

    # NxFloats::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{NxFloats::repositoryFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # NxFloats::nxfloats()
    def self.nxfloats()
        LucilleCore::locationsAtFolder(NxFloats::repositoryFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # NxFloats::getNxFloatByUUIDOrNull(uuid)
    def self.getNxFloatByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxFloats::repositoryFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxFloats::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxFloats::repositoryFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxFloats::axiomsRepositoryFolderPath()
    def self.axiomsRepositoryFolderPath()
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

        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(NxFloats::axiomsRepositoryFolderPath(), LucilleCore::timeStringL22())

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
        NxAxioms::accessWithOptionToEdit(NxFloats::axiomsRepositoryFolderPath(), item["axiomId"])
    end

    # --------------------------------------------------
    # nx16s

    # NxFloats::run(nxfloat)
    def self.run(nxfloat)
        uuid = nxfloat["uuid"]
        puts NxFloats::toString(nxfloat)
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
        NxFloats::accessContent(nxfloat)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{NxFloats::toString(nxfloat)}' ? ", true) then
            NxFloats::destroy(nxfloat)
        end
        NxBalls::closeNxBall(nxball, true)
    end

    # NxFloats::ns16OrNull(nxfloat)
    def self.ns16OrNull(nxfloat)
        uuid = nxfloat["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "(#{"%4.2f" % rt}) #{NxFloats::toString(nxfloat)}#{noteStr}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce.green,
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    NxFloats::run(nxfloat)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{NxFloats::toString(nxfloat)}' ? ", true) then
                        NxFloats::destroy(nxfloat)
                    end
                end
            },
            "run" => lambda {
                NxFloats::run(nxfloat)
            },
            "rt" => rt
        }
    end

    # NxFloats::ns16s()
    def self.ns16s()
        NxFloats::nxfloats()
            .map{|nxfloat| NxFloats::ns16OrNull(nxfloat) }
            .compact
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # --------------------------------------------------

    # NxFloats::nx19s()
    def self.nx19s()
        NxFloats::nxfloats().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxFloats::toString(item),
                "lambda"   => lambda { NxFloats::landing(item) }
            }
        }
    end
end
