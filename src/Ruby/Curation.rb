
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

            next if Asteroids::getAsteroidsForType1(node).size > 0
            next if NSDataTypeXExtended::getLastDescriptionForTargetOrNull(node)
            ns0 = NSDataType1::getLastFrameOrNull(node)
            next if ns0.nil?
            next if ns0["type"] != "aion-point"

            system("clear")

            NSDataType0s::openFrame(node, ns0)

            counter.increment()

            description = LucilleCore::askQuestionAnswerAsString("description (or type 'dive'): ")
            next if description == ""
            if description == "dive" then
                NSDataType1::landing(node)
                next
            end
            NSDataTypeXExtended::issueDescriptionForTarget(node, description)
        }

        # Give a upstream nodes to content nodes which do not have one

        NSDataType1::objects()
        .each{|node|
            return if counter.hasReached(10)
            next if Asteroids::getAsteroidsForType1(node).size > 0
            next if NSDataType1::getUpstreamType1s(node).size > 0
            next if NSDataType1::getDownstreamType1s(node).size == 0
            system("clear")
            puts "Give a upstream node to the next node"
            LucilleCore::pressEnterToContinue()
            NSDataType1::landing(node)
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
        time2 = Time.new.to_f
        Bank::put("56995147-b264-49fb-955c-d5a919395ea3", time2-time1)
    end

end