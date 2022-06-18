
# encoding: UTF-8

class EventLog

    # EventLog::pathToLocalEventLog()
    def self.pathToLocalEventLog()
        "/Users/pascal/Galaxy/DataBank/Stargate/EventLog"
    end

    # --------------------------------------------------------------
    # Log writing

    # EventLog::commit(item)
    def self.commit(item)

        raise "(error: 227b0b8d-4ab9-45c2-a80d-ac887a73c65a, missing attribute uuid)" if item["uuid"].nil?
        raise "(error: a4767984-547e-4ca6-a200-790e25765b0c, missing attribute mikuType)" if item["mikuType"].nil?

        id = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}-#{SecureRandom.hex[0, 4]}"

        # To every item that is sent to the event log we set the attribute 

        # lxEventId: for filenames
        item["lxEventId"] = id

        # lxEventTime: used to order the elements of the log
        item["lxEventTime"] = Time.new.to_f

        filename = "#{id}.event.json"

        folderpath = LucilleCore::indexsubfolderpath(EventLog::pathToLocalEventLog(), capacity = 1000)
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # --------------------------------------------------------------
    # Log reading

    # EventLog::getLogEvents()
    def self.getLogEvents()
        events = []
        Find.find(EventLog::pathToLocalEventLog()) do |path|
            next if File.basename(path)[-11, 11] != ".event.json"
            events << JSON.parse(IO.read(path))
        end
        events.sort{|e1, e2| e1["lxEventTime"] <=> e2["lxEventTime"] }
    end

    # EventLog::eventsToCliques(events)
    def self.eventsToCliques(events)
        cliques = {}
        events.each{|event|
            if cliques[event["uuid"]].nil? then
                cliques[event["uuid"]] = []
            end
            cliques[event["uuid"]] << event
        }
        cliques
    end

    # EventLog::cliquesToItems(cliques)
    def self.cliquesToItems(cliques)
        items = []
        cliques.values.each{|arr|
            lastItem = arr.last # that's the simple version that doesn't do reconciliation
            if lastItem["mikuType"] != "NxDeleted" then
                items << lastItem
            end
        }
        items
    end
end
