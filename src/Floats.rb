
# encoding: UTF-8

class Floats

    # Floats::floats()
    def self.floats()
        NyxObjects2::getSet("c1d07170-ed5f-49fe-9997-5cd928ae1928")
    end

    # Floats::getFloatsForUIListing()
    def self.getFloatsForUIListing()
        Floats::floats()
        .select{|float|
            DoNotShowUntil::isVisible(float["uuid"])
        }
        .map{|float|
            float["landing"] = lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("confirm '#{Floats::toString(float)}' done ? ") then
                    NyxObjects2::destroy(float)
                end
            }
            float["nextNaturalStep"] = lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("confirm '#{Floats::toString(float)}' done ? ") then
                    NyxObjects2::destroy(float)
                end
            }
            float["done"] = lambda { NyxObjects2::destroy(float) }
            float
        }
    end

    # Floats::issueFloatTextInteractivelyOrNull(ordinal)
    def self.issueFloatTextInteractivelyOrNull(ordinal)
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        uuid = Miscellaneous::l22()
        object = {
          "uuid"     => uuid,
          "nyxNxSet" => "c1d07170-ed5f-49fe-9997-5cd928ae1928",
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
