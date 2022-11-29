
class TxItemCx22Pair

    # TxItemCx22Pair::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/TxItemCx22Pair"
        items = LucilleCore::locationsAtFolder(folderpath)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
        items
    end

    # TxItemCx22Pair::getOrNull(itemuuid)
    def self.getOrNull(itemuuid)
        filepath = "#{Config::pathToDataCenter()}/TxItemCx22Pair/#{itemuuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TxItemCx22Pair::issue(itemuuid, nxballuuid)
    def self.issue(itemuuid, nxballuuid)
        object = {
            "itemuuid"   => itemuuid,
            "nxballuuid" => nxballuuid
        }
        filepath = "#{Config::pathToDataCenter()}/TxItemCx22Pair/#{itemuuid}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # TxItemCx22Pair::getNxBallOrNull(itemuuid)
    def self.getNxBallOrNull(itemuuid)
        pair = TxItemCx22Pair::getOrNull(itemuuid)
        return nil if pair.nil?
        NxBalls::getItemOrNull(pair["nxballuuid"])
    end

    # TxItemCx22Pair::closeNxBallForItemIfExists(itemuuid)
    def self.closeNxBallForItemIfExists(itemuuid)
        nxball = TxItemCx22Pair::getNxBallOrNull(itemuuid)
        return if nxball.nil?
        NxBalls::close(nxball)
    end
end
