# encoding: UTF-8

class RStreamProgressMonitor
    def initialize()
        @data = JSON.parse(XCache::getOrDefaultValue("18705e17-41a7-4c7b-986b-a6a9292e8bb4", "[]"))
    end
    def anotherOne()
        @data << Time.new.to_i
        XCache::set("18705e17-41a7-4c7b-986b-a6a9292e8bb4", JSON.generate(@data))
    end
    def getCount()
        @data.size
    end
end

$RStreamProgressMonitor = RStreamProgressMonitor.new()

class TxTodos

    # TxTodos::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxTodo")
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxTodos::interactivelyCreateNewOrNull(description = nil)
    def self.interactivelyCreateNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601
        expectation = NxTodoExpectations::makeNew()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
          "expectation" => expectation
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]} (#{Nx111::toStringShort(item["nx111"])})"
    end

    # TxTodos::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(todo) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxTodos::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "#{TxTodos::toString(item)}#{NxBallsService::activityStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "nx111: #{item["nx111"]}"
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts "access | start | <datecode> | description | iam | transmute | note | json | >nyx | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItemWithI1asAttribute(item)
                next
            end

            if Interpreting::match("start", command) then
                if !NxBallsService::isRunning(item["uuid"]) then
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
                end
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), item["uuid"])
                next if nx111.nil?
                item["nx111"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxTodo")
                break
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(item)}' ? ", true) then
                    NxBallsService::close(item["uuid"], true)
                    TxTodos::destroy(item["uuid"])
                    break
                end
                next
            end

            if command == ">nyx" then
                i2 = Transmutation::interactivelyNx50ToNyx(item)
                LxAction::action("landing", i2)
                break
            end
        }
    end

    # --------------------------------------------------

    # TxTodos::itemsForListing()
    def self.itemsForListing()

        # We only show todo items when there is nothing else to see (in section 2)
        # We are informed of it by flag "a82d53c8-3a1e-4edb-b055-06ae97e3d5cb", true means empty section 2
        # With that said we still commit to a full rstream sequence (rt: 1 hour) everyday.

        return [] if !XCache::getFlag("a82d53c8-3a1e-4edb-b055-06ae97e3d5cb")

        getItems = lambda {|date|
            items = XCache::getOrNull("afb34ada-3ca5-4bc0-83f9-2b81ad7efb4b:#{date}")
            if items then
                return JSON.parse(items)
                            .map{|item| Librarian::getObjectByUUIDOrNull(item["uuid"]) }
                            .compact
            else
                items = TxTodos::items()
                            .sort{|i1, i2| NxTodoExpectations::expectationToUrgency(i1["expectation"]) <=> NxTodoExpectations::expectationToUrgency(i2["expectation"]) }
                            .take(20)
                XCache::set("afb34ada-3ca5-4bc0-83f9-2b81ad7efb4b:#{date}", JSON.generate(items))
                return items
            end
        }
        getItems.call(CommonUtils::today())
    end

    # --------------------------------------------------

    # TxTodos::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxTodo")
            .map{|item|
                {
                    "announce" => TxTodos::toStringForNS19(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
