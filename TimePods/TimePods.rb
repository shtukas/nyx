
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

    # TimePods::issue(description, timeCommitmentInHours, startUnixtime, endUnixtime)
    def self.issue(description, timeCommitmentInHours, startUnixtime, endUnixtime)
        pod = {
            "uuid"                  => SecureRandom.uuid,
            "description"           => description,
            "timeCommitmentInHours" => timeCommitmentInHours,
            "startUnixtime"         => startUnixtime,
            "endUnixtime"           => endUnixtime
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

    # TimePods::idealCompletionPercentage(pod)
    def self.idealCompletionPercentage(pod)
        operationTimeInSeconds = 0.9*(pod["endUnixtime"] - pod["startUnixtime"])
                                    # We compute on the basis of completing in  90%% of the allocated time
        timeSinceStart = Time.new.to_i - pod["startUnixtime"]
        timeRatioSinceStart = timeSinceStart.to_f/operationTimeInSeconds
        100*timeRatioSinceStart
    end

    # TimePods::actualCompletionPercentage(pod)
    def self.actualCompletionPercentage(pod)
        uuid = pod["uuid"]
        x1 = Bank::total(uuid)
        x2 = Runner::runTimeInSecondsOrNull(uuid) || 0
        (x1+x2).to_f/(3600*pod["timeCommitmentInHours"])
    end

    # TimePods::metric(pod)
    def self.metric(pod)
        uuid = pod["uuid"]
        timeBank = Bank::total(uuid)
        return -1 if (timeBank >= 3600*pod["timeCommitmentInHours"]) # Todo: we might want to destroy them, but fine for the moment
        if TimePods::actualCompletionPercentage(pod) < TimePods::idealCompletionPercentage(pod) then
            0.77 + 0.001*(TimePods::idealCompletionPercentage(pod) - TimePods::actualCompletionPercentage(pod)).to_f
        else
            0.60 - 0.01*(TimePods::actualCompletionPercentage(pod) - TimePods::idealCompletionPercentage(pod)).to_f
        end
    end
end
