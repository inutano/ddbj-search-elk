require 'json'

def nested_fields(obj)
  listing = []
  obj.each_pair do |key, value|
    case value
    when Hash
      listing << [key, nested_fields(value)]
    when Array
      array_nested(value).each do |val|
        listing << [key, val]
      end
    else
      listing << [key, value]
    end
  end
  listing
end

def array_nested(array)
  array.map do |val|
    case val
    when Hash
      nested_fields(val)
    when Array
      array_nested(val)
    else
      val
    end
  end
end

if __FILE__ == $0
  json_lines = ARGV.first
  json_array = open(json_lines).readlines.map.with_index(1) do |line, i|
    if i % 2 == 0
      JSON.load(line)
    end
  end
  fields = nested_fields(json_array.compact.first)
  fields.each do |f|
    p f
  end
end
