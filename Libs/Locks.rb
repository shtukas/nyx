# encoding: UTF-8

class Locks

    # Locks::lock(domain, uuid)
    def self.lock(domain, uuid)
        data = { "domain" => domain, "uuid" => uuid }
        contents = JSON.pretty_generate(data)
        filepath = "#{Config::pathToDataCenter()}/Locks/#{Digest::SHA1.hexdigest(contents)}.json"
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # Locks::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Locks")
            .select{|filepath| filepath[-5, 5]}
    end

    # Locks::isLocked(uuid)
    def self.isLocked(uuid)
        Locks::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .reduce(false){|flag, item|
                flag or (item["uuid"] == uuid)
            }
    end

    # Locks::done(uuid)
    def self.done(uuid)
        Locks::filepaths()
            .each{|filepath|
                item = JSON.parse(IO.read(filepath))
                if item["uuid"] == uuid then
                    FileUtils.rm(filepath)
                end
            }
    end

    # Locks::shelves()
    def self.shelves()
        Locks::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

end
