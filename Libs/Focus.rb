# encoding: UTF-8

class Focus

    # Focus::lock(domain, uuid)
    def self.lock(domain, uuid)
        data = { "domain" => domain, "uuid" => uuid }
        contents = JSON.pretty_generate(data)
        filepath = "#{Config::pathToDataCenter()}/Focus/#{Digest::SHA1.hexdigest(contents)}.json"
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # Focus::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Focus")
            .select{|filepath| filepath[-5, 5]}
    end

    # Focus::isLocked(uuid)
    def self.isLocked(uuid)
        Focus::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .reduce(false){|flag, item|
                flag or (item["uuid"] == uuid)
            }
    end

    # Focus::done(uuid)
    def self.done(uuid)
        Focus::filepaths()
            .each{|filepath|
                item = JSON.parse(IO.read(filepath))
                if item["uuid"] == uuid then
                    FileUtils.rm(filepath)
                end
            }
    end

    # Focus::shelves()
    def self.shelves()
        Focus::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

end
