
# encoding: UTF-8

FlamePadding = "              "

class NSXDisplayUtils

    # NSXDisplayUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "multiline" then
            return item["text"]
        end
        "[8f854b3a] I don't know how to announce: #{item["type"]}"
    end

    # NSXDisplayUtils::defaultCatalystObjectCommands()
    def self.defaultCatalystObjectCommands()
        ["expose"]
    end

    # NSXDisplayUtils::makeInferfaceString(object)
    def self.makeInferfaceString(object)
        defaultCommand = object["defaultCommand"]
        commands = object["commands"]
        if defaultCommand then
            commands = commands.reject{|c| c == defaultCommand }
        end
        [
            FlamePadding[0, FlamePadding.size-1],
            defaultCommand ? "#{defaultCommand.green}" : nil,
            commands.join(" "),
            NSXDisplayUtils::defaultCatalystObjectCommands().join(" ")
        ].compact.reject{|command| command=='' }.join(" ")
    end

    # NSXDisplayUtils::makeDisplayStringForCatalystListing(object)
    def self.makeDisplayStringForCatalystListing(object)
        # NSXMiscUtils::screenWidth()

        width = NSXMiscUtils::screenWidth()-15

        contentItem = object["contentItem"]

        if contentItem["type"] == "line" then
            line = contentItem["line"]
            line = line[0, width]
            line = object["isRunning"] ? line.green : line
            return "(#{"%5.3f" % object["metric"]}) #{line}"
        end

        if contentItem["type"] == "multiline" then
            str = contentItem["text"]
                    .lines
                    .to_a
                    .map
                    .with_index{|line, indx|
                        line = line.rstrip
                        if indx == 0 then
                            "(#{"%5.3f" % object["metric"]}) #{line[0, width]}"
                        else
                            "              #{line[0, width]}"
                        end
                    }
                    .join("\n")
            return str 
        end
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end
end