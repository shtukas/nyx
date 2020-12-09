
# encoding: UTF-8

class Floats

    # Floats::floats()
    def self.floats()
        NyxObjects2::getSet("c1d07170-ed5f-49fe-9997-5cd928ae1928")
    end

    # Floats::getFloatsForUIListing()
    def self.getFloatsForUIListing()
        Floats::floats()
        .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
        .select{|float|
            DoNotShowUntil::isVisible(float["uuid"])
        }
        .map{|float|
            float["landing"] = lambda {
                operations = [
                    "update/set ordinal",
                    "destroy"
                ]
                operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                return if operation.nil?
                if operation == "update/set ordinal" then
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal ? (leave empty for none) : ")
                    ordinal = ordinal.size > 0 ? ordinal.to_f : nil
                    float["ordinal"] = ordinal
                    NyxObjects2::put(float)               
                end
                if operation == "destroy" then
                    NyxObjects2::destroy(float)
                end
            }
            float["nextNaturalStep"] = lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Floats::toString(float)}' ? ") then
                    NyxObjects2::destroy(float)
                end
            }
            float
        }
    end

    # Floats::issueFloatTextInteractivelyOrNull()
    def self.issueFloatTextInteractivelyOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal ? (leave empty for none) : ")
        ordinal = ordinal.size > 0 ? ordinal.to_f : nil
        uuid = Miscellaneous::l22()
        object = {
          "uuid"     => uuid,
          "nyxNxSet" => "c1d07170-ed5f-49fe-9997-5cd928ae1928",
          "unixtime" => Time.new.to_f,
          "type"     => "line",
          "line"     => line,
          "ordinal"  => ordinal
        }
        NyxObjects2::put(object)
        object
    end

    # Floats::toString(float)
    def self.toString(float)
        "[float]#{float["ordinal"] ? " #{float["ordinal"]}" : ""} #{float["line"]}"
    end
end
