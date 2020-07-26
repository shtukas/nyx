
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

        NSDataType1::points()
        .each{|point|

            return if counter.hasReached(10)

            next if NSDataType1::getAsteroidsForPoint(point).size > 0
            next if NSDataTypeXExtended::getLastDescriptionForTargetOrNull(point)
            ns0 = NSDataType1::pointToLastFrameOrNull(point)
            next if ns0.nil?
            next if ns0["type"] != "aion-point"

            system("clear")

            NSDataType0s::openFrame(point, ns0)

            counter.increment()

            description = LucilleCore::askQuestionAnswerAsString("description (or type 'dive'): ")
            next if description == ""
            if description == "dive" then
                NSDataType1::landing(point)
                next
            end
            NSDataTypeXExtended::issueDescriptionForTarget(point, description)
        }

        # Give a description to concepts which do not have one

        NSDataType2::concepts()
        .each{|concept|
            return if counter.hasReached(10)
            next if NSDataTypeXExtended::getLastDescriptionForTargetOrNull(concept)
            NSDataType2::landing(concept)
            counter.increment()
        }

        # Give a upstream concepts to points which do not have one

        NSDataType1::points()
        .each{|point|
            return if counter.hasReached(10)
            next if Type1Type2CommonInterface::getUpstreamConcepts(point).size > 0
            NSDataType2::landing(point)
            counter.increment()
        }
    end

    # Curation::catalystTodoListingCurationOpportunity()
    def self.catalystTodoListingCurationOpportunity()
        return if rand < BankExtended::recoveredDailyTimeInHours("56995147-b264-49fb-955c-d5a919395ea3")
        return if !LucilleCore::askQuestionAnswerAsBoolean("spare some time for curation ? ", true)
        time1 = Time.new.to_f

        Curation::oneCurationStep()

        time2 = Time.new.to_f
        Bank::put("56995147-b264-49fb-955c-d5a919395ea3", time2-time1)
    end

    # Curation::session()
    def self.session()
        time1 = Time.new.to_f
        loop {
            Curation::oneCurationStep()
            break if ((Time.new.to_i-time1) > 1200)
        }
    end

end