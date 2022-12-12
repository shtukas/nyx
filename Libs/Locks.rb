
class Locks

    # Locks::lock(item)
    def self.lock(item)
        filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
        return if File.exists?(filepath)
        FileUtils.touch(filepath)
    end

    # Locks::isLocked(item)
    def self.isLocked(item)
        filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
        File.exists?(filepath)
    end

    # Locks::unlock(item)
    def self.unlock(item)
        filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end