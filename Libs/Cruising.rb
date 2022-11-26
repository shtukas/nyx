# encoding: UTF-8

=begin

NxCruisingState {
    "topItem"       => Item
    "startUnixtime" => Float
    "cx22"          => Cx22
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

    # Cruising::issueNewStateUsingComponents(item, unixtime, cx22)
    def self.issueNewStateUsingComponents(item, unixtime, cx22)
        state = {
            "item"     => item,
            "unixtime" => unixtime,
            "cx22"     => cx22
        }
        Cruising::setState(state)
        state
    end

    # Cruising::issueNewStateWithThisItem(item)
    def self.issueNewStateWithThisItem(item)
        system("clear")
        puts "item: #{PolyFunctions::toString(item)}"
        cx22 = nil
        loop {
            cx22 = Cx22::itemuuid2ToCx22OrNull(item["uuid"])
            break if cx22
            Cx22::addItemToInteractivelySelectedCx22OrNothing(item["uuid"])
        }
        Cruising::issueNewStateUsingComponents(item, Time.new.to_f, cx22)
    end

    # Cruising::close()
    def self.close()
        state = Cruising::getStateOrNull()
        return if state.nil?
        timespan = Time.new.to_i - state["unixtime"]
        puts "bank: putting #{timespan} seconds into '#{Cx22::toString(state["cx22"])}'"
        Bank::put(state["cx22"]["uuid"], timespan)
        # Then we need to close that state
        filepath = Cruising::filepath()
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
