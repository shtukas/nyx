# encoding: UTF-8

class Topping

    # The reason we are not just opening the files, is because those functions used to read and write 
    # from KeyValueStore. We kept the same logic and the same functions (and just added universe as argument)

    # Topping::getText(universe)
    def self.getText(universe)
        return nil if universe.nil?
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/tops/#{universe}.txt"
        if !File.exists?(filepath) then
            FileUtils.touch(filepath)
        end
        IO.read(filepath)
    end

    # Topping::setText(universe, text)
    def self.setText(universe, text)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/tops/#{universe}.txt"
        File.open(filepath, "w") {|f| f.puts(text.strip) }
    end

    # Topping::applyTransformation(universe)
    def self.applyTransformation(universe)
        return if universe.nil?
        text = Topping::getText(universe)
        text = SectionsType0141::applyNextTransformationToText(text)
        Topping::setText(universe, text)
    end

    # Topping::top(universe)
    def self.top(universe)
        return if universe.nil?
        text = Topping::getText(universe)
        text = Utils::editTextSynchronously(text)
        Topping::setText(universe, text)
    end
end


