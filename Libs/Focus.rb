# encoding: UTF-8

class Focus

    # Focus::filepath()
    def self.filepath()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Focus")
            .select{|filepath| filepath[-5, 5]}
            .first
    end

    # Focus::getData()
    def self.getData()
        JSON.parse(IO.read(Focus::filepath()))
    end

    # Focus::getuuids()
    def self.getuuids()
        Focus::getData()["uuids"]
    end

    # Focus::commitdata(data)
    def self.commitdata(data)
        FileUtils.rm(Focus::filepath())
        filepath = "#{Config::pathToDataCenter()}/Focus/#{SecureRandom.hex(4)}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end

    # Focus::select(items)
    def self.select(items)
        uuids = Focus::getuuids()
        focus = items.select{|item| NxBalls::itemIsRunning(item) or uuids.include?(item["uuid"]) }
        return focus if !focus.empty?
        # focus is empty.
        data = Focus::getData()
        puts "Achievement unlocked ✨ in #{((Time.new.to_i - data["unixtime"]).to_f/3600).round(2)} hours"
        puts "Sleeping for one minute 😴"
        sleep 60
        items = CatalystListing::listingItems().first(12)
        data = {
            "unixtime" => Time.new.to_i,
            "uuids"    => items.map{|item| item["uuid"] }
        }
        Focus::commitdata(data)
        items
    end
end
