require 'json'
require 'date'

class DateTime
  class << self
    def is_date?(string)
      date = self.parse(string)
      true if date
    rescue
      false
    end
  end
end

module OmicsMetadata
  class << self
    def fields(object)
      evaluate(field_listing(object))
    end

    def field_listing(object)
      listing = []
      object.each_pair do |key, value|
        case value
        when Hash
          field_listing(value).each do |child|
            listing << [key, child]
          end
        when Array
          array_of_listing(value).each do |item|
            item.each do |i|
              listing << [key, i]
            end
          end
        else
          listing << [key, value]
        end
      end
      listing
    end

    def array_of_listing(array)
      array.map do |item|
        case item
        when Array
          array_of_listing(item)
        when Hash
          field_listing(item)
        else
          [item]
        end
      end
    end

    def evaluate(fields)
      collection = fields.map do |field|
        f = field.flatten
        value = f.pop
        tag = f.last
        if !DateTime.is_date?(value) && tag !~ /@/
          f.join(".")
        end
      end
      collection.compact.uniq
    end
  end
end

if __FILE__ == $0
  json_lines_path = ARGV.first

  json_array = open(json_lines_path).readlines.map.with_index(1) do |line, i|
    if i % 2 == 0
      JSON.load(line)
    end
  end

  puts OmicsMetadata.fields(json_array.compact.first)
end
