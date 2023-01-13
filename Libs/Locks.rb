
class Locks

    # Locks::lock(item)
    def self.lock(item)
        Locks::unlock(item)
        data = {
            "uuid"     => item["uuid"],
            "unixtime" => Time.new.to_i,
            "random"   => SecureRandom.hex
        }
        contents = JSON.generate(data)
        filename = "#{Digest::SHA1.hexdigest(contents)}"
        filepath = "#{Config::pathToDataCenter()}/Locks/#{filename}.lock"
        File.open(filepath, "w") {|f| f.puts(contents) }
    end

    # Locks::unlock(item)
    def self.unlock(item)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Locks")
            .select{|filepath| filepath[-5, 5] == ".lock" }
            .each{|filepath|
                data = JSON.parse(IO.read(filepath))
                if data["uuid"] == item["uuid"] then
                    FileUtils.rm(filepath)
                end
            }
    end

    # Locks::locks()
    def self.locks()
        # This function is called from listing and actually just load the locks into memory
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Locks")
            .select{|filepath| filepath[-5, 5] == ".lock" }
            .map{|filepath| JSON.parse(IO.read(filepath))}
    end
end