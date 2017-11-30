require 'io/console'
require 'yaml'
require 'kosi'
require_relative 'misc'

class DataMan
    ROOT_PATH = File.dirname(__FILE__)
    @name
    @file_name
    @data

    @is_table
    @columns

    @history

    def initialize(name)
        @name = name
        @file_name = "#{ROOT_PATH}/data/#{name}.yml"
        if File.exist?(@file_name)
            @data = YAML.load_file(@file_name)
        else
            @columns = {}
            while true
                print "column name: "
                column = STDIN.gets.chomp
                break if ['e', 'exit', 'q', 'quit'].include?(column)

                print "type of #{column}: (String) "
                type = STDIN.gets.chomp
                type = 'String' if type.empty?

                print "default of #{column}: "
                case type
                when 'String'
                    default = STDIN.gets.chomp
                when 'Array', 'Hash'
                    begin
                        default = YAML.load(STDIN.gets.chomp)
                    rescue
                        puts 'parse error'
                        exit(1)
                    end
                when 'Integer'
                    begin
                        default = Integer(STDIN.gets.chomp)
                    rescue
                        puts 'not a number'
                        exit(1)
                    end
                when 'Date'
                    begin
                        default = Date.parse(STDIN.gets.chomp)
                    rescue
                        puts 'parse error'
                        exit(1)
                    end
                else
                    default = STDIN.gets.chomp
                end
                @columns[column] = {'type' => type, 'default' => default}
            end
            @data = {}
            @is_table = @columns.length > 0
            puts "create #{name}.yml"
            dump()
        end

        @is_table = @data.instance_of?(Hash) && @data.key?('columns')
        if @is_table
            @columns = @data['columns']
            @data = @data['data']
        end
    end

    def get(field: nil, cond: {}, order: nil, offset: 0, count: -1)
        if @is_table
            field = @columns.keys unless field
            # deep copy
            ret = deep_copy(@data)
            # cond
            ret.select! do |v|
                cond.keys.all? { |k| compare(v[k], cond[k]) }
            end
            # field
            ret.each do |v|
                v.keep_if{ |k, v| field.include?(k) }
            end
            # offset
            ret = ret[offset..-1] ? ret[offset..-1] : []
            # count
            count = ret.length if count == -1
            ret = ret[0...count]
            return ret
        else
            return @data
        end
    end

    def insert(data)
        if @is_table
            # 未設定ならデフォルトを設定
            @columns.each do |k, v|
                if !data.key?(k)
                    data[k] = v['default']
                end
            end
            # 余計なデータがあれば削除
            data.keep_if{ |k| @columns.key?(k) }
            @data << data
            dump()
        elsif @data.instance_of?(Array)
            @data << data
            dump()
        else
            puts "cannot insert into this data"
        end
        return self
    end

    def update(cond: nil, data:)
        if @is_table
            @data.each do |e|
                if cond == nil or cond.map{ |k, v| compare(e[k], v) }.all?
                    data.each{ |k, v| e[k] = v }
                end
            end
            dump()
        else
            @data = data
            dump()
        end
        return self
    end

    def delete(cond)
        if @is_table
            @data.delete_if{ |e| cond.map{ |k, v| compare(e[k], v) }.all? }
            dump()
        else
            raise "unsupported operation"
        end
        return self
    end

    def swap(id1, id2)
        if @data.instance_of?(Array)
            @data.swap!(id1, id2)
            dump()
        else
            puts "cannot swap the data"
        end
        return self
    end

    # for cond
    def compare(value, cond)
        if cond.is_a?(Regexp)
            return cond =~ value
        else
            return cond == value
        end
    end

    def console
        if @is_table
            while true
                print "#{@name}> "
                line = STDIN.gets
                queries = line.split()
                case queries[0]
                when 'show', 's'
                    puts self
                when 'insert', 'i'
                    new_data = {}
                    @columns.each do |k, v|
                        print "#{k}: (#{v['default'].to_s}) "
                        case v['type']
                        when 'String'
                            new_data[k] = STDIN.gets.chomp
                            new_data[k] = v['default'] if new_data[k].strip.empty?
                        when 'Array', 'Hash'
                            begin
                                arr = STDIN.gets.chomp
                                arr = v['default'] if arr.strip.empty?
                                new_data[k] = YAML.load(arr)
                            rescue
                                puts 'parse error'
                                new_data = nil
                            end
                        when 'Integer'
                            begin
                                num = STDIN.gets.chomp
                                num = v['default'] if num.strip.empty?
                                new_data[k] = Integer(num)
                            rescue
                                puts 'not a number'
                                new_data = nil
                            end
                        when 'Date'
                            begin
                                date = STDIN.gets.chomp
                                date = v['default'] if date.strip.empty?
                                new_data[k] = Date.parse(STDIN.gets.chomp)
                            rescue
                                puts 'parse error'
                                new_data = nil
                            end
                        end
                    end
                    puts 'insert new data'
                    p new_data
                    insert(new_data) if new_data
                when 'update', 'u'
                    cond = {}
                    while true
                        print "cond [column] = [param]: "
                        break
                    end
                    data = get(cond: cond)
                when 'delete', 'd'
                    cond = {}
                    while true
                        print "cond [column] = [param]: "
                        break
                    end
                when 'eval', 'e'
                    repl()
                when 'exit', 'quit', 'q'
                    break
                else
                    help()
                end
            end
        else
            print "#{@name}> "
            while line = STDIN.gets
                queries = line.split()
                case queries[0]
                when 'show', 's'
                    puts self
                when 'eval', 'e'
                    repl()
                when 'exit', 'quit', 'q'
                    break
                else
                    help()
                end
                print "#{@name}> "
            end
        end
    end

    def repl
        @history = [] unless @history
        while true
            print "#{@name}(eval)> "
            command = ''
            current = @history.length
            @history[current] = ''
            pos = 0
            len = ->{command.length}    # Proc, len.call()やlen.()やlen[]で呼び出す
            while true
                key = STDIN.getch
                case key
                when "\C-c" # Control+C
                    command = "quit"
                    break
                when "\r"   # Enter
                    break
                when "\e"   # ESC
                    if STDIN.getch == "[" and ["A", "B", "C", "D"].include?((key = STDIN.getch))
                        case key
                        when "A"
                            if current > 0
                                print "\e[#{pos}D\e[0K" if pos > 0
                                current -= 1
                                print @history[current]
                                command = @history[current].dup
                                pos = len[]
                            end
                        when "B"
                            if current < @history.length - 1
                                print "\e[#{pos}D\e[0K" if pos > 0
                                current += 1
                                print @history[current]
                                command = @history[current].dup
                                pos = len[]
                            end
                        when "C"
                            if pos < len[]
                                pos += 1
                                print "\e[C"
                            end
                        when "D"
                            if pos > 0
                                pos -= 1
                                print "\e[D"
                            end
                        end
                    end
                when "\u007f"   # Back Space
                    if pos > 0
                        print "\e[D\e[0K#{command[pos...len[]]}"
                        print "\e[#{len[] - pos}D" if len[] - pos > 0
                        command.slice!(pos-1)
                        pos -= 1
                        @history[-1] = command if current == @history.length-1
                    end
                when "(", "[", "{", "\"", "'"
                    str = case key
                    when "(";"()"
                    when "[";"[]"
                    when "{";"{}"
                    when "\"";"\"\""
                    when "'";"''"
                    end
                    print str + command[pos...len[]]
                    print "\e[#{len[] - pos + 1}D"
                    command.insert(pos, str)
                    pos += 1
                else
                    print key + command[pos...len[]]
                    print "\e[#{len[] - pos}D" if len[] - pos > 0
                    command.insert(pos, key)
                    pos += 1
                    @history[-1] = command if current == @history.length-1
                end
            end
            print "\n"
            if ['exit', 'quit'].include?(command)
                break
            end
            p command
            @history[-1] = command
            begin
                eval('puts ' + command)
            rescue => e
                p e
            end
        end
    end

    def help
        if @is_table
            puts 'commands'
            puts ' insert'
            puts ' update(not implemented)'
            puts ' delete(not implemented)'
            puts ' show'
            puts ' eval'
            puts ' exit/quit'
        else
            puts 'commands'
            puts ' show'
            puts ' eval'
            puts ' exit/quit'
        end
    end

    def dump
        data = @is_table ? {'columns' => @columns, 'data' => @data} : @data
        open(@file_name, 'w') { |f| YAML.dump(data, f) }
        return
    end

    def deep_copy(obj)
        YAML.load(YAML.dump(obj))
    end

    def to_s(field: nil, cond: {})
        if @is_table
            field = @columns.keys unless field
            kosi = Kosi::Table.new({header: ['id'] + field.select{ |v| @columns.keys.include?(v)}})
            data = get(field: field, cond: cond).map.with_index{ |row, i| [i.to_s] + row.values.map(&:to_s) }
            kosi.render(data)
        elsif @data.instance_of?(Array)
            kosi = Kosi::Table.new()
            kosi.render(@data.map.with_index{ |row, i| [i.to_s] + row.values.map(&:to_s) })
        else
            @data.to_s
        end
    end

    def show(field: nil, cond: {})
        to_s(field: field, cond: cond)
    end
end

if __FILE__ == $0
    d = DataMan.new('learning_articles')
    puts d
    puts d.get(cond: {'name' => '1'})
    puts d.insert({'name' => 'test'})
    puts d.update({'name' => 'test'}, {'state' => 2})
    puts d.delete({'name' => 'test'})
end
