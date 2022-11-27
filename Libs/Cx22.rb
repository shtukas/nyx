
class Cx22

    # Cx22::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/Cx22"
        items = LucilleCore::locationsAtFolder(folderpath)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("Cx22-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size}.max)
        items
    end

    # Cx22::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/Cx22/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Cx22::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{Config::pathToDataCenter()}/Cx22/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # --------------------------------------------
    # Makers

    # Cx22::interactivelySelectStyle()
    def self.interactivelySelectStyle()
        loop {
            style = LucilleCore::selectEntityFromListOfEntitiesOrNull("Cx22 style", ["sequence", "managed-top-3"])
            return style if style
        }
    end

    # Cx22::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        style = Cx22::interactivelySelectStyle()
        isPriority = LucilleCore::askQuestionAnswerAsBoolean("is priority (work-like commitment) ? : ")
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Cx22",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "style"       => style,
            "isPriority"  => isPriority
        }
        FileSystemCheck::fsck_Cx22(item, true)
        Cx22::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # Cx22::toString(item)
    def self.toString(item)
        "#{item["description"]}"
    end

    # Cx22::toStringWithDetails(item)
    def self.toStringWithDetails(item)
        percentage = 100 * Ax39::completionRatio(item["uuid"], item["ax39"])
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "#{item["description"]} : #{Ax39::toString(item["ax39"])}#{percentageStr}#{dnsustr}"
    end

    # Cx22::toStringWithDetailsFormatted(item)
    def self.toStringWithDetailsFormatted(item)
        descriptionPadding = (XCache::getOrNull("Cx22-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 28).to_i # the original value
        percentage = 100 * Ax39::completionRatio(item["uuid"], item["ax39"])
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "(group) #{item["description"].ljust(descriptionPadding)} : #{Ax39::toString(item["ax39"]).ljust(18)}#{percentageStr}#{dnsustr}"
    end

    # Cx22::itemsInCompletionOrder()
    def self.itemsInCompletionOrder()
        Cx22::items()
            .map{|cx22|  
                {
                    "cx22"  => cx22,
                    "ratio" => Ax39::completionRatio(cx22["uuid"], cx22["ax39"])
                }
            }
            .sort{|p1, p2| p1["ratio"] <=> p2["ratio"] }
            .map{|packet| packet["cx22"] }
    end

    # ----------------------------------------------------------------
    # Mapping

    # Cx22::attach(cx22uuid, itemuuid)
    def self.attach(cx22uuid, itemuuid)
        folderpath = "#{Config::pathToDataCenter()}/Cx22/#{cx22uuid}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{itemuuid}"
        FileUtils.touch(filepath)
    end

    # Cx22::cx22uuidsToItemsuuids(cx22uuid)
    def self.cx22uuidsToItemsuuids(cx22uuid)
        folderpath = "#{Config::pathToDataCenter()}/Cx22/#{cx22uuid}"
        return [] if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[0, 1] != "." }
            .map{|filepath| File.basename(filepath) }
    end

    # Cx22::cx22uuidsToItems(cx22uuid)
    def self.cx22uuidsToItems(cx22uuid)
        Cx22::cx22uuidsToItemsuuids(cx22uuid)
            .map{|itemuuid| Catalyst::getCatalystItemOrNull(itemuuid) }
            .compact
    end

    # Cx22::itemuuid2ToCx22OrNull(itemuuid)
    def self.itemuuid2ToCx22OrNull(itemuuid)
        Cx22::items().each{|cx22|
            if Cx22::cx22uuidsToItemsuuids(cx22["uuid"]).include?(itemuuid) then
                return cx22
            end
        }
        nil
    end

    # Cx22::cx22uuidAndItemuuiToFilepath(cx22uuid, itemuuid)
    def self.cx22uuidAndItemuuiToFilepath(cx22uuid, itemuuid)
        "#{Config::pathToDataCenter()}/Cx22/#{cx22uuid}/#{itemuuid}"
    end

    # Cx22::garbageCollection(itemuuid)
    def self.garbageCollection(itemuuid)
        Cx22::items().each{|cx22|
            filepath = Cx22::cx22uuidAndItemuuiToFilepath(cx22["uuid"], itemuuid)
            next if !File.exists?(filepath)
            FileUtils.rm(filepath)
        }
    end

    # --------------------------------------------
    # Ops

    # Cx22::interactivelySelectCx22OrNull()
    def self.interactivelySelectCx22OrNull()
        cx22s = Cx22::items().sort{|i1, i2| i1["description"] <=> i2["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", cx22s, lambda{|cx22| Cx22::toStringWithDetailsFormatted(cx22)})
    end

    # Cx22::addItemToInteractivelySelectedCx22OrNothing(itemuuid)
    def self.addItemToInteractivelySelectedCx22OrNothing(itemuuid)
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        Cx22::attach(cx22["uuid"], itemuuid)
    end

    # Cx22::probe(cx22)
    def self.probe(cx22)
        loop {
            actions = ["add time"]
            action = LucilleCore::selectEntityFromListOfEntities("action: ", actions)
            return if action.nil?
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "adding #{timeInHours} hours to '#{Cx22::toString(cx22)}'"
                Bank::put(cx22["uuid"], timeInHours*3600)
            end
        }
    end

    # Cx22::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            cx22 = Cx22::interactivelySelectCx22OrNull()
            return if cx22.nil?
            Cx22::probe(cx22)
        }
    end

    # Cx22::itemToCx22Attemp(item)
    def self.itemToCx22Attemp(item)
        cx22 = Cx22::itemuuid2ToCx22OrNull(item["uuid"])
        return cx22 if cx22
        puts "item: #{PolyFunctions::toString(item)}"
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        Cx22::attach(cx22["uuid"], item["uuid"])
        cx22
    end
end
