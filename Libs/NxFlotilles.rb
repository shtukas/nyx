
# encoding: UTF-8

class NxFlotilles

    # ----------------------------------------------------------------------
    # IO

    # NxFlotilles::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxFlotille")
    end

    # NxFlotilles::getOrNull(uuid): null or NxFlotille
    def self.getOrNull(uuid)
        Librarian::getObjectByUUIDOrNull(uuid)
    end

    # NxFlotilles::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxFlotilles::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxFlotille",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxFlotilles::toString(item)
    def self.toString(item)
        "(flotille) #{item["description"]}"
    end

    # NxFlotilles::flts(flotille)
    def self.flts(flotille)
        TxFlts::items().select{|flt| flt["flotille"] == flotille["uuid"] }
    end

    # ------------------------------------------------
    # Operations

    # NxFlotilles::landing(flotille)
    def self.landing(flotille)
        loop {
            system("clear")

            puts "#{NxFlotilles::toString(flotille)}`".green

            store = ItemStore.new()

            NxFlotilles::flts(flotille).each{|flt|
                indx = store.register(flt, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxFlts::toString(flt)}"
            }

            puts "commands: <n> | description".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(flotille["description"]).strip
                next if description == ""
                flotille["description"] = description
                Librarian::commit(flotille)
                next
            end
        }

    end

    # ------------------------------------------------
    # Nx20s

    # NxFlotilles::nx20s()
    def self.nx20s()
        NxFlotilles::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxFlotilles::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
