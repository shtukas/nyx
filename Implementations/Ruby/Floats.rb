
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
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Floats::toString(float)}' ? ") then
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
        uuid = Miscellaneous::l22()
        object = {
          "uuid"     => uuid,
          "nyxNxSet" => "c1d07170-ed5f-49fe-9997-5cd928ae1928",
          "unixtime" => Time.new.to_f,
          "type"     => "line",
          "line"     => line 
        }
        NyxObjects2::put(object)
        object
    end

    # Floats::toString(float)
    def self.toString(float)
        "[float] #{float["line"]}"
    end
end
