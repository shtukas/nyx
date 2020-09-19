
# encoding: UTF-8

class Interpreter

    def initialize()
        @items = []
    end

    def registerExactCommand(command, execution)
        @items << {
            "type"    => "exact-command",
            "command" => command,
            "lambda"  => execution
        }
    end

    def prompt()
        loop {
            prompt = LucilleCore::askQuestionAnswerAsString("-> ")
            return if prompt == ""
            exactCommandItem = @items.select{|item| item["command"] == prompt }.first
            if exactCommandItem then
                exactCommandItem["lambda"].call()
            end
        }
    end
end

