
# encoding: UTF-8

class TimePointsOperator

    # ----------------------------------------------------------------------

    # TimePointsOperator::issueTimePoint(timeCommitmentInHours, description)

    def self.issueTimePoint(timeCommitmentInHours, description)
        data = {
            "uuid" => SecureRandom.hex(4),
            "unixtime" => Time.new.to_f,
            "description" => description,
            "time-commitment-in-hours" => timeCommitmentInHours
        }
        File.open("/Galaxy/DataBank/Catalyst/Agents-Data/time-points/#{LucilleCore::timeStringL22()}.json", "w") { |f| f.puts(JSON.pretty_generate(data)) }
    end
end
