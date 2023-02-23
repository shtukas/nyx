# encoding: UTF-8

class NxHeads

    # NxHeads::items()
    def self.items()
        ObjectStore2::objects("NxHeads")
    end

    # NxHeads::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxHeads", item)
    end

    # NxHeads::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxHeads", uuid)
    end

    # NxHeads::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxHeads", uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxHeads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "position"    => position
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{N1DataIO::putBlob(url)}"
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxTails::commit(item)
        item
    end

    # NxHeads::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(DatablobStoreElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxTails::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxHeads::toString(item)
    def self.toString(item)
        rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
        "(stream) (#{"%5.2f" % rt}) #{item["description"]} (pos: #{item["position"].round(3)})"
    end

    # NxHeads::startZone()
    def self.startZone()
        NxHeads::items().map{|item| item["position"] }.sort.take(3).inject(0, :+).to_f/3
    end

    # NxHeads::endPosition()
    def self.endPosition()
        ([-4] + NxHeads::items().map{|item| item["position"] }).max
    end

    # NxHeads::listingItems()
    def self.listingItems()
        NxHeads::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
            .take(3)
            .map {|item|
                {
                    "item" => item,
                    "rt"   => BankUtils::recoveredAverageHoursPerDay(item["uuid"])
                }
            }
            .select{|packet| packet["rt"] < 1 } # This ensure that there might be a moment where it's time to go to bed
            .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
            .map {|packet| packet["item"] }
    end

    # NxHeads::listingRunningItems()
    def self.listingRunningItems()
        NxHeads::items().select{|item| NxBalls::itemIsActive(item) }
    end

    # --------------------------------------------------
    # Operations

    # NxHeads::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
