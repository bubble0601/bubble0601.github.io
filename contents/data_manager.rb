require 'yaml'
require 'kosi'

class DataMan
    ROOT_PATH = File.dirname(__FILE__)
    @name
    @file_name
    @data

    @is_table
    @columns

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
                cond.keys.all? { |k| v[k] == cond[k] }
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
            puts "can not insert into this data"
        end
        return self
    end

    def update(cond, data)
        if @is_table
            @data.each do |e|
                if cond.map{ |k, v| e[k] == v }.all?
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
            @data.delete_if{ |e| cond.map{ |k, v| e[k] == v }.all? }
            dump()
        else
            raise "unsupported operation"
        end
        return self
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
                when 'exit', 'e', 'quit', 'q'
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
                when 'exit', 'e', 'quit', 'q'
                    break
                else
                    help()
                end
                print "#{@name}> "
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
        else
            puts 'commands'
            puts ' show'
            puts ' exit'
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

    def to_s
        if @is_table
            kosi = Kosi::Table.new({header: @columns.keys})
            kosi.render(@data.map{ |v| v.values.map!{ |v| v.to_s } })
        else
            @data.to_s
        end
    end
end

if __FILE__ == $0
    d = DataMan.new('univ_articles')
    puts d
    puts d.get(cond: {'name' => '1'})
    puts d.insert({'name' => 'test'})
    puts d.update({'name' => 'test'}, {'state' => 2})
    puts d.delete({'name' => 'test'})
end
