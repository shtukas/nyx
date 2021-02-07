
# encoding: UTF-8

=begin
TimelineItem {
    "uuid"           : String 
    "nyxElementType" : "ea9f4f69-1c8c-49c9-b644-8854c1be75d8"
    "date"           : String
    "description"    : String   
}

_uuid_ text, _date_ text, _description_ text
=end

class TimelineItems

    # ------------------------------------------------
    # Database

    # TimelineItems::issueTimelineItem(uuid, date, description)
    def self.issueTimelineItem(uuid, date, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _timeline_ where _uuid_=?", [uuid]
        db.execute "insert into _timeline_ (_uuid_, _date_, _description_) values (?,?,?)", [uuid, date, description]
        db.commit 
        db.close
    end

    # TimelineItems::getTimelineItems()
    def self.getTimelineItems()
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _timeline_", []) do |row|
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

    # TimelineItems::getTimelineItemForUUIDOrNull(uuid)
    def self.getTimelineItemForUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _timeline_ where _uuid_=?", [uuid]) do |row|
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

    # TimelineItems::toString(event)
    def self.toString(event)
        "[event] #{event["date"]} ; #{event["description"]}"
    end

    # TimelineItems::interactivelyIssueNewTimelineItemOrNull()
    def self.interactivelyIssueNewTimelineItemOrNull()
        uuid = SecureRandom.hex
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        date = LucilleCore::askQuestionAnswerAsString("date (YYYY-MM-DD): ")
        return nil if date == ""
        TimelineItems::issueTimelineItem(uuid, date, description)
        TimelineItems::getTimelineItemForUUIDOrNull(uuid)
    end

    # TimelineItems::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _timeline_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # ------------------------------------------------

    # TimelineItems::nyxSearchItems()
    def self.nyxSearchItems()
        TimelineItems::getTimelineItems()
            .map{|event|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{TimelineItems::toString(event)}",
                    "type"         => "event",
                    "payload"      => event
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # TimelineItems::selectExistingTimelineItemOrNull()
    def self.selectExistingTimelineItemOrNull()
        CatalystUtils::selectOneOrNull(TimelineItems::getTimelineItems().sort{|e1,v2| e1["date"] <=> e2["date"] }, lambda{|event| TimelineItems::toString(event) })
    end

    # TimelineItems::landing(event)
    def self.landing(event)

        locpaddingsize = 11

        loop {
            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            puts TimelineItems::toString(event).green
            puts "uuid: #{event["uuid"]}".yellow

            puts ""

            Arrows::getParentsUUIDs(event["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            Arrows::getChildrenUUIDs(event["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            puts ""

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                Patricia::architectAddParentForDX7(event)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                Patricia::architectAddChildForDX7(event)
            })

            mx.item("select and remove parent".yellow, lambda {
                Patricia::selectAndRemoveOneParentFromDX7(event)
            })

            mx.item("select and remove child".yellow, lambda {
                Patricia::selectAndRemoveOneChildFromDX7(event)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    TimelineItems::destroy(event["uuid"])
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
