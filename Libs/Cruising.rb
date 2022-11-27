# encoding: UTF-8

=begin

NxCruisingState {
    "topItemUUID" : String
    "nxballuuid"  : String
}

=end

class Cruising

    # Cruising::filepath()
    def self.filepath()
        "#{Config::pathToDataCenter()}/Cruising/state.json"
    end

    # Cruising::getStateOrNull()
    def self.getStateOrNull()
        filepath = Cruising::filepath()
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Cruising::setState(state)
    def self.setState(state)
        filepath = Cruising::filepath()
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(state)) }
    end

    # Cruising::issueNewStateUsingComponents(topItemUUID, nxballuuid)
    def self.issueNewStateUsingComponents(topItemUUID, nxballuuid)
        state = {
            "topItemUUID" => topItemUUID,
            "nxballuuid"  => nxballuuid,
        }
        Cruising::setState(state)
        state
    end

    # Cruising::settleAnyExistingState()
    def self.settleAnyExistingState()
        state = Cruising::getStateOrNull()
        return if state.nil?
        return if state["nxballuuid"].nil?
        nxball = NxBalls::getItemOrNull(state["nxballuuid"])
        return if nxball.nil?
        NxBalls::close(nxball)
        state["nxballuuid"] = nil
        Cruising::setState(state)
    end

    # Cruising::continueWithThisItem(item)
    def self.continueWithThisItem(item)
        itemToAccounts = lambda {|item|
            cx22 = Cx22::itemToCx22Attemp(item)
            return [] if cx22.nil?
            [cx22["uuid"]]
        }
        Cruising::settleAnyExistingState()
        accounts = itemToAccounts.call(item)
        if accounts.empty? then
            Cruising::issueNewStateUsingComponents(item["uuid"], nil)
        else
            nxball = NxBalls::issue(PolyFunctions::toString(item), accounts)
            Cruising::issueNewStateUsingComponents(item["uuid"], nxball["uuid"])
        end
    end

    # Cruising::continueWithNoItem()
    def self.continueWithNoItem()
        Cruising::settleAnyExistingState()
        Cruising::issueNewStateUsingComponents(nil, nil)
    end

    # Cruising::end()
    def self.end()
        Cruising::settleAnyExistingState()
        # Then we need to delete that state
        filepath = Cruising::filepath()
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
