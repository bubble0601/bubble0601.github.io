def help
    puts "Usage"
    puts "\tgenerate: generate pug"
    puts "\tdata [name]: manipulate data/[name].yml; if not exists, creatre interactively"
end

if __FILE__ == $0
    if ARGV.length == 0
        help()
    else
        case ARGV[0]
        when 'generate', 'gen', 'g'
            require_relative "generate"

        when 'data', 'd'
            if ARGV.length < 2
                help()
            end
            require_relative "data_manager"
            dm = DataMan.new(ARGV[1])
            dm.console()
        end
    end
end