
# encoding: UTF-8

=begin
Event {
    "uuid"           : String 
    "nyxElementType" : "ea9f4f69-1c8c-49c9-b644-8854c1be75d8"
    "date"           : String
    "description"    : String   
}

_uuid_ text, _date_ text, _description_ text
=end

class Events

    # ------------------------------------------------
    # Database

    # Events::issueEvent(uuid, date, description)
    def self.issueEvent(uuid, date, description)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.execute "insert into _events_ (_uuid_, _date_, _description_) values (?, ?, ?)", [uuid, date, description]
        db.commit 
        db.close
    end

    # Events::getEvents()
    def self.getEvents()
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _events_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'], 
                "nyxElementType" => "ea9f4f69-1c8c-49c9-b644-8854c1be75d8",
                "date"           => row['_date_'],
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Events::getEventForUUIDOrNull(uuid)
    def self.getEventForUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _events_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "ea9f4f69-1c8c-49c9-b644-8854c1be75d8",
                "date"           => row['_date_'],
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Events::toString(event)
    def self.toString(event)
        "[event] #{event["date"]} ; #{event["description"]}"
    end

    # Events::interactivelyIssueNewEventOrNull()
    def self.interactivelyIssueNewEventOrNull()
        uuid = SecureRandom.hex
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        date = LucilleCore::askQuestionAnswerAsString("date (YYYY-MM-DD): ")
        return nil if date == ""
        Events::issueEvent(uuid, date, description)
        Events::getEventForUUIDOrNull(uuid)
    end

    # Events::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # ------------------------------------------------

    # Events::nyxSearchItems()
    def self.nyxSearchItems()
        Events::getEvents()
            .map{|event|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{Events::toString(event)}",
                    "type"         => "event",
                    "payload"      => event
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # Events::selectExistingEventOrNull()
    def self.selectExistingEventOrNull()
        NyxUtils::selectOneOrNull(Events::getEvents().sort{|e1,v2| e1["date"] <=> e2["date"] }, lambda{|event| Events::toString(event) })
    end

    # Events::landing(event)
    def self.landing(event)

        locpaddingsize = 11

        loop {
            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            puts Events::toString(event).green
            puts "uuid: #{event["uuid"]}".yellow

            puts ""

            NyxArrows::getParentsUUIDs(event["uuid"]).each{|uuid1|
                e1 = NyxPatricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{NyxPatricia::dx7toString(e1)}", lambda { 
                    NyxPatricia::dx7landing(e1)
                })
            }

            NyxArrows::getChildrenUUIDs(event["uuid"]).each{|uuid1|
                e1 = NyxPatricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{NyxPatricia::dx7toString(e1)}", lambda { 
                    NyxPatricia::dx7landing(e1)
                })
            }

            puts ""

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                NyxPatricia::architectAddParentForDX7(event)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                NyxPatricia::architectAddChildForDX7(event)
            })

            mx.item("select and remove parent".yellow, lambda {
                NyxPatricia::selectAndRemoveOneParentFromDX7(event)
            })

            mx.item("select and remove child".yellow, lambda {
                NyxPatricia::selectAndRemoveOneChildFromDX7(event)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    Events::destroy(event["uuid"])
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
