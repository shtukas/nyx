
# encoding: UTF-8

class NxBallsService

=begin

    status {
        "type"                    => "running",
        "thisSprintStartUnixtime" => Float,
        "lastMarginCallUnixtime"  => nil or Float,
        "bankedTimeInSeconds"     => Float
    }

    {
        "type"                    => "paused",
        "bankedTimeInSeconds"     => Float
    }

=end

    # --------------------------------------------------------------------
    # Basic IO

    # NxBallsService::instanceSubFolder()
    def self.instanceSubFolder()
        subfolder = "#{Config::pathToDataCenter()}/NxBallsService/#{Config::thisInstanceId()}"
        if !File.exists?(subfolder) then
            FileUtils.mkdir(subfolder)
        end
        subfolder
    end

    # NxBallsService::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{NxBallsService::instanceSubFolder()}/#{item["uuid"]}.json"
        if File.exists?(filepath) then
            puts "NxBalls should be immutable!"
            exit
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxBallsService::issue(owneruuid, description, accounts)
    def self.issue(owneruuid, description, accounts)
        nxball = {
            "uuid"         => SecureRandom.uuid,
            "owneruuid"    => owneruuid,
            "mikuType"     => "NxBall.v2",
            "unixtime"     => Time.new.to_f,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "accounts"     => accounts
        }
        NxBallsService::commit(nxball)
    end

    # NxBallsService::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{NxBallsService::instanceSubFolder()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBallsService::items()
    def self.items()
        folderpath = NxBallsService::instanceSubFolder()
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBallsService::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{NxBallsService::instanceSubFolder()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------------------------
    # Operations

    # NxBallsService::getBallByOwnerOrNull(owneruuid)
    def self.getBallByOwnerOrNull(owneruuid)
        NxBallsService::items()
            .select{|nxball| nxball["owneruuid"] == owneruuid }
            .first
    end

    # NxBallsService::itemToNxBallOpt(item)
    def self.itemToNxBallOpt(item)
        if item["mikuType"] == "NxBall.v2" then
            return item
        end
        NxBallsService::getBallByOwnerOrNull(item["uuid"])
    end

    # NxBallsService::close(nxBallOpt, verbose) # timespan in seconds or null
    def self.close(nxBallOpt, verbose)
        return if nxBallOpt.nil?
        nxball = nxBallOpt
        timespan = Time.new.to_f - nxball["start"]
        timespan = [timespan, 3600*2].min
        if verbose then
            puts "(#{Time.new.to_s}) nxball total time: #{(timespan.to_f/3600).round(2)} hours"
        end
        nxball["accounts"].each{|account|
            if verbose then
                announce = "account number: #{account}"
                # Let's try and find a better announce
                # Often accounts are object uuids
                obj1 = PolyFunctions::getCatalystItemOrNull(account)
                if obj1 then
                    announce = PolyFunctions::toString(obj1)
                end
                puts "(#{Time.new.to_s}) putting #{timespan} seconds into: #{announce}" 
            end
            Bank::put(account, timespan)
        }
        NxBallsService::destroy(nxball["uuid"])
        timespan
    end

    # --------------------------------------------------------------------
    # Information

    # NxBallsService::toString(nxball)
    def self.toString(nxball)
        "(nxball) #{nxball["description"]} (running for: #{((Time.new.to_i - nxball["start"]).to_f/3600).round(2)} hours)"
    end

    # NxBallsService::activityStringOrEmptyString(leftSide, itemuuid, rightSide)
    def self.activityStringOrEmptyString(leftSide, itemuuid, rightSide)
        nxball = NxBallsService::getBallByOwnerOrNull(itemuuid)
        if nxball.nil? then
            return ""
        end
        "#{leftSide}#{NxBallsService::toString(nxball)}#{rightSide}"
    end
end
