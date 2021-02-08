
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

    # TimelineItems::commitTimelineItem(uuid, date, description)
    def self.commitTimelineItem(uuid, date, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _timeline_ where _uuid_=?", [uuid]
        db.execute "insert into _timeline_ (_uuid_, _date_, _description_) values (?,?,?)", [uuid, date, description]
        db.commit 
        db.close
    end

    # TimelineItems::updateTimelineDescription(uuid, description)
    def self.updateTimelineDescription(uuid, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "update _timeline_ set _description_=? where _uuid_=?", [description, uuid]
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

    # TimelineItems::toString(item)
    def self.toString(item)
        "[timeline item] #{item["date"]} ; #{item["description"]}"
    end

    # TimelineItems::interactivelyIssueNewTimelineItemOrNull()
    def self.interactivelyIssueNewTimelineItemOrNull()
        uuid = SecureRandom.hex
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        date = LucilleCore::askQuestionAnswerAsString("date (YYYY-MM-DD): ")
        return nil if date == ""
        TimelineItems::commitTimelineItem(uuid, date, description)
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
            .map{|item|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{TimelineItems::toString(item)}",
                    "payload"      => item
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # TimelineItems::selectExistingTimelineItemOrNull()
    def self.selectExistingTimelineItemOrNull()
        CatalystUtils::selectOneOrNull(TimelineItems::getTimelineItems().sort{|e1,v2| e1["date"] <=> e2["date"] }, lambda{|item| TimelineItems::toString(item) })
    end

    # TimelineItems::landing(item)
    def self.landing(item)

        locpaddingsize = 11

        loop {

            return if TimelineItems::getTimelineItemForUUIDOrNull(item["uuid"]).nil? # could have been destroyed at the previous run

            item = TimelineItems::getTimelineItemForUUIDOrNull(item["uuid"])

            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            puts TimelineItems::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow

            puts ""

            Arrows::getParentsUUIDs(item["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            Arrows::getChildrenUUIDs(item["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            puts ""

            mx.item("update description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                TimelineItems::updateTimelineDescription(item["uuid"], description)
            })

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                Patricia::architectAddParentForDX7(item)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                Patricia::architectAddChildForDX7(item)
            })

            mx.item("select and remove parent".yellow, lambda {
                Patricia::selectAndRemoveOneParentFromDX7(item)
            })

            mx.item("select and remove child".yellow, lambda {
                Patricia::selectAndRemoveOneChildFromDX7(item)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    TimelineItems::destroy(item["uuid"])
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
