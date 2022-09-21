# encoding: UTF-8

class Nx11E

    # Nx11E::types()
    def self.types()
        ["hot", "ordinal", "ondate", "Ax39Group", "Ax39Engine", "standard"]
    end

    # Nx11E::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type (none to abort):", Nx11E::types())
    end

    # Nx11E::interactivelyCreateNewNx11EOrNull(itemuuid)
    def self.interactivelyCreateNewNx11EOrNull(itemuuid)
        type = Nx11E::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "hot" then
            return {
                "mikuType" => "Nx11E",
                "type"     => "hot"
            }
        end
        if type == "ordinal" then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty to abort): ")
            return nil if ordinal == ""
            return {
                "mikuType" => "Nx11E",
                "type"     => "ordinal",
                "ordinal"  => ordinal
            }
        end
        if type == "ondate" then
            datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
            return nil if datetime.nil?
            return {
                "mikuType" => "Nx11E",
                "type"     => "ondate",
                "datetime" => datetime
            }
        end
        if type == "Ax39Group" then
            ax39 = {
                "type"  => "daily-time-commitment",
                "hours" => 1
            }
            group = {
                "id"       => "338b688b-5b45-447c-8445-df3ec389e9c3",
                "mikuType" => "Ax39Group",
                "name"     => "default",
                "ax39"     => ax39,
                "account"  => "627fc35e-b0c3-4d3c-960d-9d0dd7787182"
            }
            position = 0
            return {
                "mikuType" => "Nx11E",
                "type"     => "Ax39Group",
                "group"    => group,
                "position" => position
            }
        end
        if type == "Ax39Engine" then
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
            return nil if ax39.nil?
            return {
                "mikuType" => "Nx11E",
                "type"     => "Ax39Engine",
                "ax39"     => ax39,
                "itemuuid" => itemuuid
            }
        end
        if type == "standard" then
            return {
                "mikuType" => "Nx11E",
                "type"     => "standard",
                "unixtime" => Time.new.to_f
            }
        end
    end

    # Nx11E::toString(nx11e)
    def self.toString(nx11e)
        nx11e.to_s
    end

    # Nx11E::priority(item)
    def self.priority(item)

        if item["mikuType"] != "Nx11E" then
            raise "(error: a99fb12c-53a6-465a-8b87-14a85c58463b) item: #{item}"
        end

        if item["type"] == "hot" then
            return 0.90
        end

        if item["type"] == "ordinal" then
            return 0.85 -  Math.atan(item["ordinal"]).to_f/100
        end

        if item["type"] == "ondate" then
            return 0.70 + Math.atan(Time.new.to_f - DateTime.parse(item["datetime"]).to_time.to_f).to_f/100
        end

        if item["type"] == "Ax39Group" then

            group    = item["group"]
            ax39     = group["ax39"]
            account  = group["account"]

            position = item["position"]

            cr = Ax39Extensions::completionRatio(ax39, account)

            return -1 if cr > 1

            return 0.60 + (1 - cr).to_f/100 - Math.atan(position).to_f/100
        end

        if item["type"] == "Ax39Engine" then
            cr = Ax39Extensions::completionRatio(item["ax39"], item["itemuuid"])
            return -1 if cr > 1
            return 0.50 + 0.2*(1-cr)
        end

        if item["type"] == "standard" then
            unixtime = item["unixtime"]
            return 0.40 + Math.atan(Time.new.to_f - unixtime).to_f/100
        end

        raise "(error: 188c8d4b-1a79-4659-bd93-6d8e3ddfe4d1) item: #{item}"

    end
end