
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DailyTimes.rb"

class TimePods

    # TimePods::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/TimePods"
    end

    # TimePods::save(item)
    def self.save(item)
        filepath = "#{TimePods::path()}/#{item["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TimePods::issue(target, startUnixtime, timespanToDeadlineInDays, timeCommitmentInHours)
    def self.issue(target, startUnixtime, timespanToDeadlineInDays, timeCommitmentInHours)
        pod = {
            "uuid"                     => SecureRandom.uuid,
            "target"                   => target,
            "startUnixtime"            => startUnixtime,
            "timespanToDeadlineInDays" => timespanToDeadlineInDays,
            "timeCommitmentInHours"    => timeCommitmentInHours,
        }
        TimePods::save(pod)
        pod
    end

    # TimePods::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{TimePods::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TimePods::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{TimePods::path()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # TimePods::getTimePods()
    def self.getTimePods()
        Dir.entries(TimePods::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{TimePods::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TimePods::idealCompletionRatio(pod)
    def self.idealCompletionRatio(pod)
        timespanToDeadlineInSeconds = 0.9*pod["timespanToDeadlineInDays"]*86400
                                    # We compute on the basis of completing in  90%% of the allocated time
        timeSinceStart = Time.new.to_i - pod["startUnixtime"]
        [timeSinceStart.to_f/timespanToDeadlineInSeconds, 1].min
    end

    # TimePods::idealTime(pod)
    def self.idealTime(pod)
        TimePods::idealCompletionRatio(pod)*(3600*pod["timeCommitmentInHours"])
    end

    # TimePods::liveTime(pod)
    def self.liveTime(pod)
        uuid = pod["uuid"]
        x1 = Bank::total(uuid)
        x2 = Runner::runTimeInSecondsOrNull(uuid) || 0
        x1+x2
    end

    # TimePods::actualCompletionRatio(pod)
    def self.actualCompletionRatio(pod)
        TimePods::liveTime(pod).to_f/(3600*pod["timeCommitmentInHours"])
    end

    # TimePods::metric(pod)
    def self.metric(pod)
        uuid = pod["uuid"]
        timeBank = Bank::total(uuid)
        return -1 if (timeBank >= 3600*pod["timeCommitmentInHours"]) # Todo: we might want to destroy them, but fine for the moment
        if TimePods::actualCompletionRatio(pod) < TimePods::idealCompletionRatio(pod) then
            0.77 + 0.001*(TimePods::idealCompletionRatio(pod) - TimePods::actualCompletionRatio(pod)).to_f
        else
            0.60 - 0.01*(TimePods::actualCompletionRatio(pod) - TimePods::idealCompletionRatio(pod)).to_f
        end
    end

    # TimePods::toString(pod)
    def self.toString(pod)
        uuid = pod["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        metrics = "(completion: #{(100*TimePods::actualCompletionRatio(pod)).round(2)} %) (time commitment: #{pod["timeCommitmentInHours"]} hours, done: #{(TimePods::liveTime(pod).to_f/3600).round(2)} hours, ideal: #{(TimePods::idealTime(pod).to_f/3600).round(2)} hours)#{runningString}"
        target = pod["target"]
        if target["type"] == "self" then
            return "[timepod/self] #{target["description"]} #{metrics}"
        end
        if target["type"] == "LucilleTxt" then
            return "[timepod] LucilleTxt #{metrics}"
        end
        raise "[TimePods] error: CE8497BB"
    end
end

