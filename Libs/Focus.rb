# encoding: UTF-8

=begin
{
  "unixtime": 1673738028,
  "uuids": [
    "20200618-210304-972290",
    (...)
    "e6c3cf14-dddc-494a-ab5e-3b9627db6822"
  ],
  "locks" : []
}

=end

class Focus

    # --------------------------------------------------
    # IO

    # Focus::filepath()
    def self.filepath()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Focus")
            .select{|filepath| filepath[-5, 5]}
            .first
    end

    # Focus::getdata()
    def self.getdata()
        JSON.parse(IO.read(Focus::filepath()))
    end

    # Focus::commitdata(data)
    def self.commitdata(data)
        FileUtils.rm(Focus::filepath())
        filepath = "#{Config::pathToDataCenter()}/Focus/#{SecureRandom.hex(4)}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end

    # --------------------------------------------------

    # Focus::itemsToFocusData(items)
    def self.itemsToFocusData(items)
        # This function takes listing items and compute the intersection with the store data
        # It returns the store store data after its's been garbage collected, and possibly recomputed.

        data = Focus::getdata()

        main = items.select{|item| NxBalls::itemIsRunning(item) or data["uuids"].include?(item["uuid"]) }
        if !main.empty? then

            # We here just need to perform a bit of garbage collection
            # Removing the uuids we are not using

            incomiguuids  = items.map{|item| item["uuid"] }
            datauuids, x1 = data["uuids"].partition{|uuid| incomiguuids.include?(uuid) }
            domains, x2   = data["locks"].partition{|datum| incomiguuids.include?(datum["uuid"]) }

            if !(x1+x2).empty? then
                data = {
                    "unixtime" => data["unixtime"],
                    "uuids"    => datauuids,
                    "locks"    => domains
                }
                Focus::commitdata(data)
            end

            return data
        end

        # main is empty.

        data = Focus::getdata()
        puts "----------------------------------------------------------------------"
        puts "Achievement unlocked ✨ in #{((Time.new.to_i - data["unixtime"]).to_f/3600).round(2)} hours"
        puts "----------------------------------------------------------------------"
        LucilleCore::pressEnterToContinue()
        items = CatalystListing::listingItems().first(12)
        data = {
            "unixtime" => Time.new.to_i,
            "uuids"    => items.map{|item| item["uuid"] },
            "locks"    => data["locks"]
        }
        Focus::commitdata(data)
        data
    end

    # Focus::makeDisplayData(items)
    def self.makeDisplayData(items)
        # This function takes listing items and return a structure that is used for display in the listing
        # It uses (updated) focus data to do so. 

        data = Focus::itemsToFocusData(items)
        itemByUUIDOrNull = lambda {|uuid|
            items.select{|item| item["uuid"] == uuid }.first
        }
        {
            "items" => data["uuids"].map{|uuid| itemByUUIDOrNull.call(uuid) }.compact,
            "locks" => data["locks"]
                        .map{|datum| 
                            item = itemByUUIDOrNull.call(datum["uuid"]) 
                            if item then
                                datum["item"] = item
                                datum
                            else
                                nil
                            end
                        }
                        .compact
        }
    end

    # Focus::lock(domain, uuid)
    def self.lock(domain, uuid)

        # We function updates the lock section of focus data

        data = Focus::getdata()

        # We need to remove the uuid from the main list
        data["uuids"] = data["uuids"].select{|u| u != uuid }

        # We also need to remove that uuid from the locks
        data["locks"] << { "domain" => domain, "uuid" => uuid }

        Focus::commitdata(data)
    end

    # Focus::line()
    def self.line()
        data = Focus::getdata()
        "> focus: active for #{((Time.new.to_i - data["unixtime"]).to_f/3600).round(2)} hours"
    end
end
