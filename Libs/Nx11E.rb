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

    # Nx11E::interactivelySetANewEngineForItemOrNothing(item)
    def self.interactivelySetANewEngineForItemOrNothing(item)
        engine = Nx11E::interactivelyCreateNewNx11EOrNull()
        return if engine.nil?
        ItemsEventsLog::setAttribute2(item["uuid"], "nx11e", engine)
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

    # Nx11E::priorityOrNull(nx11e, cx22Opt)
    # We return a null value when the nx11e should not be displayed
    def self.priorityOrNull(nx11e, cx22Opt)
        shiftOnDateTime = lambda {|datetime|
            0.01*(Time.new.to_f - DateTime.parse(datetime).to_time.to_f)/86400
        }

        shiftOnUnixtime = lambda {|unixtime|
            0.01*Math.log(Time.new.to_f - unixtime)
        }

        if nx11e["mikuType"] != "Nx11E" then
            raise "(error: a99fb12c-53a6-465a-8b87-14a85c58463b) This function only takes Nx11Es, nx11e: #{nx11e}"
        end

        if nx11e["type"] == "hot" then
            unixtime = nx11e["unixtime"]
            return 0.90 + shiftOnUnixtime.call(unixtime)
        end

        if nx11e["type"] == "ordinal" then
            return 0.85 -  Math.atan(nx11e["ordinal"]).to_f/100
        end

        if nx11e["type"] == "ondate" then
            return nil if (CommonUtils::today() < nx11e["datetime"][0, 10])
            return 0.70 + Math.atan(Time.new.to_f - DateTime.parse(nx11e["datetime"]).to_time.to_f).to_f/100
        end

        if nx11e["type"] == "standard" then

            unixtime = nx11e["unixtime"]

            if cx22Opt then
                cx22 = cx22Opt
                ax39     = cx22["ax39"]
                account  = cx22["bankaccount"]
                cr = Ax39::completionRatio(ax39, account)
                return nil if cr >= 1
                return 0.50 + (1 - cr).to_f/10 + shiftOnUnixtime.call(unixtime)
            end

            return 0.40 + shiftOnUnixtime.call(unixtime)
        end

        raise "(error: 188c8d4b-1a79-4659-bd93-6d8e3ddfe4d1) nx11e: #{nx11e}"
    end
end