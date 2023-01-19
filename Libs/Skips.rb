# encoding: UTF-8

class Skips

    # Skips::skip(uuid, unixtime)
    def self.skip(uuid, unixtime)
        data = { "uuid" => uuid, "unixtime" => unixtime }
        contents = JSON.pretty_generate(data)
        filepath = "#{Config::pathToDataCenter()}/Skips/#{Digest::SHA1.hexdigest(contents)}.json"
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # Skips::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Skips")
            .select{|filepath| filepath[-5, 5]}
    end

    # Skips::isSkipped(uuid)
    def self.isSkipped(uuid)
        Skips::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .reduce(false){|flag, item|
                flag or (item["uuid"] == uuid and Time.new.to_i < item["unixtime"])
            }
    end

    # Skips::done(uuid)
    def self.done(uuid)
        Skips::filepaths()
            .each{|filepath|
                item = JSON.parse(IO.read(filepath))
                if item["uuid"] == uuid then
                    FileUtils.rm(filepath)
                end
            }
    end
end
