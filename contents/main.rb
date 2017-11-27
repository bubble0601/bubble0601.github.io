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
        f.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        f.puts("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">")
        urls.each do |url|
            lastmod = File::Stat.new(url).mtime.to_s[0,10]
            url = "https://bubble0601.github.io/" + url.match(/\.\.\/public\/(.+\.html)$/)[1]
            f.puts("<url>")
            f.puts("<loc>#{url}</loc>")
            f.puts("<lastmod>#{lastmod}</lastmod>")
            f.puts("</url>")
        end
        f.puts("</urlset>")
    end
end

def lang
    require_relative "data_manager"
    dm = DataMan.new('lang_articles')
    print "lang: "
    lang  = STDIN.gets.chomp
    print "name: "
    name  = STDIN.gets.chomp
    print "title: "
    title = STDIN.gets.chomp
    print "category: "
    cat   = STDIN.gets.chomp
    dm.insert({"filename" => "#{lang}/#{name}", "state" => 1, "template" => "article", "category" => cat, "params" => {"title" => title}})
    open("#{ROOT_PATH}/lang/#{lang}/#{name}.pug", "w")
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

        when 'lang', 'l'
            lang()
        end
    end
end
