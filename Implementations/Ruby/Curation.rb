# encoding: UTF-8

class Curation

    # Curation::getCurationLambdaOrNull()
    def self.getCurationLambdaOrNull()
        nil
    end

    # Curation::runOnce()
    def self.runOnce()
        startTime = Time.new.to_f
        l = Curation::getCurationLambdaOrNull()
        return if l.nil?
        l.call()
        timespan = Time.new.to_f - startTime

        puts "#{timespan} at curation-12774764-77df-4185-ae4c-85bb176484ca"
        Bank::put("curation-12774764-77df-4185-ae4c-85bb176484ca", timespan)
    end

    # Curation::catalystObjects()
    def self.catalystObjects()
        return [] if Curation::getCurationLambdaOrNull().nil?
        {
            "uuid"             => "e113b812-d495-4735-b831-16ac69ef5d92",
            "body"             => "nyx curation",
            "metric"           => 0.4, # just after the DxThreads ratio 1
            "landing"          => lambda { Curation::runOnce() },
            "nextNaturalStep"  => lambda { Curation::runOnce() }
        }
    end
end


