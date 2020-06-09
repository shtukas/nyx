
# encoding: UTF-8

class NSXDisplayUtils

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
            defaultCommand ? "#{defaultCommand.green}" : nil,
            commands.join(" "),
            NSXDisplayUtils::defaultCatalystObjectCommands().join(" ")
        ].compact.reject{|command| command=='' }.join(" ")
    end

    # NSXDisplayUtils::makeDisplayStringForCatalystListing(object)
    def self.makeDisplayStringForCatalystListing(object)
        # NSXMiscUtils::screenWidth()
        body = object["body"]
        lines = body.lines.to_a
        if lines.size == 1 then
            "(#{"%5.3f" % object["metric"]}) #{lines.first}"
        else
            first = lines.shift
            "(#{"%5.3f" % object["metric"]}) #{first}\n" + lines.map{|line|  "         #{line}"}.join()
        end
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end
end