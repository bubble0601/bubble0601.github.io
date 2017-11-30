ROOT_PATH = File.dirname(__FILE__)

def help
    puts "Usage"
    puts "\tgenerate/g: generate pug"
    puts "\tdata [name]/d [name]: manipulate data/[name].yml; if not exists, creatre interactively"
    puts "\tsitemap/s: generate sitemap"
    puts "\tdev: create new dev article"
end

if __FILE__ == $0
    require_relative "misc"
    if ARGV.length == 0
        help()
    else
        case ARGV[0]
        when 'generate', 'gen', 'g'
            require_relative "generate"

        when 'data', 'dat'
            if ARGV.length < 2
                help()
            end
            require_relative "data_manager"
            dm = DataMan.new(ARGV[1])
            dm.console()

        when 'sitemap', 's'
            sitemap()

        when 'dev', 'd'
            dev()
        end
    end
end
