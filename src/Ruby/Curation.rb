
# encoding: UTF-8

class Counter0731
    def initialize()
        @count = 0
    end
    def increment()
        @count = @count + 1
    end
    def hasReached(n)
        @count >= n
    end
end

class Curation

    # Curation::oneCurationStep()
    def self.oneCurationStep()

        counter = Counter0731.new()

        # Give a description to the aion-point points which do not have one

        NSDataType1::objects()
        .each{|node|
            return if counter.hasReached(10)
            next if NSDataType1::getAsteroidsForNode(node).size > 0
            next if NSDataTypeXExtended::getLastDescriptionForTargetOrNull(node)
            counter.increment()
            system("clear")
            puts "Update description of next node"
            LucilleCore::pressEnterToContinue()
            NSDataType1::landing(node)
        }

    end

    # Curation::session()
    def self.session()
        time1 = Time.new.to_f
        loop {
            Curation::oneCurationStep()
            break if ((Time.new.to_i-time1) > 1200)
        }
        time2 = Time.new.to_f
    end

end