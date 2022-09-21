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
            group = {
                "id"       => "338b688b-5b45-447c-8445-df3ec389e9c3"
                "mikuType" => "Ax39Group"
                "name"     => "default"
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
                "type"     => "standard"
            }
        end
    end

    # Nx11E::toString(nx11e)
    def self.toString(nx11e)
        nx11e.to_s
    end

    # Nx11E::priority(nx11e)
    def self.priority(nx11e)
        0.8
    end
end