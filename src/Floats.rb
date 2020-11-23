
# encoding: UTF-8

class Floats

    # Floats::floats()
    def self.floats()
        NyxObjects2::getSet("c1d07170-ed5f-49fe-9997-5cd928ae1928")
    end

    # Floats::getFloatsForUIListing()
    def self.getFloatsForUIListing()
        Floats::floats().map{|float|
            float["landing"] = lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("confirm '#{Floats::toString(float)}' done ? ") then
                    NyxObjects2::destroy(float)
                end
            }
            float
        }
    end

    # Floats::issueFloatTextInteractivelyOrNull(ordinal)
    def self.issueFloatTextInteractivelyOrNull(ordinal)
        text = Miscellaneous::editTextSynchronously("")
        storageKey = SecureRandom.hex
        KeyValueStore::set(nil, storageKey, text)
        uuid = Miscellaneous::l22()
        object = {
          "uuid"       => uuid,
          "nyxNxSet"   => "c1d07170-ed5f-49fe-9997-5cd928ae1928",
          "type"       => "text",
          "storageKey" => storageKey
        }
        NyxObjects2::put(object)
        object
    end

    # Floats::toString(point)
    def self.toString(point)
        text = KeyValueStore::getOrNull(nil, point["storageKey"]) 
        return "[float] -> no body found" if text.nil?
        return "[float] -> empty body" if text == ""
        "[float] #{text.lines.first.strip}"
    end
end
