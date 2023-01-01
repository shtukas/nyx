
# encoding: UTF-8

class Ticks

    # Ticks::emit()
    def self.emit()
        filepath = "#{Config::pathToDataCenter()}/Ticks/#{CommonUtils::timeStringL22()}.tick"
        File.open(filepath,  "w"){|f| f.puts(Time.new.to_i) }
    end

    # Ticks::gc()
    def self.gc()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Ticks")
            .select{|location| location[-5 ,5] == ".tick" }
            .each{|location|
                if (Time.new.to_i - IO.read(filepath).to_i) > 86400*7 then
                    FileUtils.rm(location)
                end
            }
    end

    # Ticks::count()
    def self.count()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Ticks")
            .select{|location| location[-5 ,5] == ".tick" }
            .size
    end
end
