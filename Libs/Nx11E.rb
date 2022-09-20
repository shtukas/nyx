# encoding: UTF-8

class Nx11E

=begin

Nx11Engine {
    "mikuType" => "Nx11Engine"
    "type"     => "ondate"
    "datetime" => DateTime # the date decides the date it shows up. 
                           # The DateTime is used for ordering, priotorization
}

Nx11Engine {
    "type"    => "ordinal"
    "ordinal" => Float
}

Nx11Engine {
    "type"    => "hot"
}

Nx11Engine {
    "type"    => "hot"
}

Nx11Engine {
    "type"     => "TimeCommitmentCompanion"
    "tcuuid"   => String
    "position" => Float
}

Nx11Engine {
    "type"     => "SelfDrive"
    "ax39"     => Ax39
    "itemuuid" => String # essentially the bank account
}
=end

    # Nx11E::types()
    def self.types()
        ["daily-singleton-run", "daily-time-commitment", "weekly-time-commitment"]
    end

    # Nx11E::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Nx11E::types())
    end

    # Nx11E::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Nx11E::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "daily-singleton-run" then
            return {
                "type" => "daily-singleton-run"
            }
        end
        if type == "daily-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours : ")
            return nil if hours == ""
            return {
                "type"  => "daily-time-commitment",
                "hours" => hours.to_f
            }
        end
        if type == "weekly-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours : ")
            return nil if hours == ""
            return {
                "type"  => "weekly-time-commitment",
                "hours" => hours.to_f
            }
        end
    end

end