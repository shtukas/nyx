# encoding: UTF-8

class Nx11E

    # Nx11E::types()
    def self.types()
        ["hot", "ordinal", "ondate", "standard"]
    end

    # Makers

    # Nx11E::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type (none to abort):", Nx11E::types())
    end

    # Nx11E::makeStandard()
    def self.makeStandard()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "standard",
            "unixtime" => Time.new.to_f
        }
    end

    # Nx11E::makeStandard2(unixtime)
    def self.makeStandard2(unixtime)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "standard",
            "unixtime" => unixtime
        }
    end

    # Nx11E::makeOndate(datetime)
    def self.makeOndate(datetime)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "ondate",
            "datetime" => datetime
        }
    end

    # Nx11E::makeHot()
    def self.makeHot()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "hot",
            "unixtime" => Time.new.to_f
        }
    end

    # Nx11E::interactivelyCreateNewNx11EOrNull()
    def self.interactivelyCreateNewNx11EOrNull()
        type = Nx11E::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "hot" then
            return Nx11E::makeHot()
        end
        if type == "ordinal" then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty to abort): ")
            return nil if ordinal == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Nx11E",
                "type"     => "ordinal",
                "ordinal"  => ordinal
            }
        end
        if type == "ondate" then
            datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
            return Nx11E::makeOndate(datetime)
        end
        if type == "standard" then
            return Nx11E::makeStandard()
        end
    end

    # Nx11E::interactivelyCreateNewNx11E()
    def self.interactivelyCreateNewNx11E()
        loop {
            nx11e = Nx11E::interactivelyCreateNewNx11EOrNull()
            return nx11e if nx11e
        }
    end

    # Nx11E::interactivelySetANewEngineForItemOrNothing(item)
    def self.interactivelySetANewEngineForItemOrNothing(item)
        engine = Nx11E::interactivelyCreateNewNx11EOrNull()
        return item if engine.nil?
        Items::setAttribute2(item["uuid"], "nx11e", engine)
        Items::getItemOrNull(item["uuid"])
    end

    # Functions

    # Nx11E::toString(nx11e)
    def self.toString(nx11e)
        if nx11e["mikuType"] != "Nx11E" then
            raise "(error: a06d321f-d66c-4909-bfb9-00a6787c0311) This function only takes Nx11Es, nx11e: #{nx11e}"
        end

        if nx11e["type"] == "hot" then
            return "(hot)"
        end

        if nx11e["type"] == "ordinal" then
            return "(ordinal: #{"%.2f" % nx11e["ordinal"]})"
        end

        if nx11e["type"] == "ondate" then
            return "(ondate: #{nx11e["datetime"][0, 10]})"
        end

        if nx11e["type"] == "standard" then
            return "(standard)"
        end

        raise "(error: b8adb3e1-eaee-4d06-afb4-bc0f3db0142b) nx11e: #{nx11e}"
    end
end