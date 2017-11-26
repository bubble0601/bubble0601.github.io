ROOT_PATH = File.dirname(__FILE__)

def help
    puts "Usage"
    puts "\tgenerate: generate pug"
    puts "\tdata [name]: manipulate data/[name].yml; if not exists, creatre interactively"
    puts "\tsitemap: generate sitemap"
end

def sitemap
    urls = Dir.glob("#{ROOT_PATH}/../public/**/*.html")
    open("#{ROOT_PATH}/../public/sitemap.xml", "w") do |f|
        f.puts("<?xml version=”1.0″ encoding=”UTF-8″?>")
        f.puts("<urlset xmlns=”http://www.sitemaps.org/schemas/sitemap/0.9″>")
        urls.each do |url|
            lastmod = File::Stat.new(url).mtime.to_s[0,10]
            url = "https://bubble0601.github.io/" + url.match(/\.\.\/public\/(.+\.html)$/)[1]
            f.puts("<url>")
            f.puts("<loc>#{url}</loc>")
            f.puts("<lastmod>#{lastmod}</lastmod>")
            f.puts("</url>")
        end
    end
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
        when 'sitemap', 's'
            sitemap()
        end
    end
end