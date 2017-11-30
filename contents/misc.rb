class Array
  def swap!(a, b)
    raise ArgumentError unless a.between?(0, self.count-1) && b.between?(0, self.count-1)

    self[a], self[b] = self[b], self[a]

    self
  end

  def swap(a, b)
    self.dup.swap!(a, b)
  end
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

def dev
    require_relative "data_manager"
    dev_art_man = DataMan.new('dev_articles')
    print "kind: "
    kind  = STDIN.gets.chomp
    print "name: "
    name  = STDIN.gets.chomp
    print "title: "
    title = STDIN.gets.chomp
    print "category: "
    cat   = STDIN.gets.chomp

    kind_man = DataMan.new('kinds')
    kinds = kind_man.get()
    dir = "#{ROOT_PATH}/dev/#{kind}"
    unless kinds.key?(kind)
        print "kind name: "
        kn = STDIN.gets.chomp
        kinds[kind] = {
            "name" => kn,
            "categories" => []
        }
        Dir.mkdir(dir)
        dev_art_man.insert({"path" => "#{kind}/top", "state" => 1, "template" => "article", "category" => nil, "params" => {"title" => kn}})
        open("#{dir}/top.pug", "w")
    end
    unless kinds[kind]['categories'].map{|v| v['alias'] }.include?(cat)
            print "category name: "
            cn = STDIN.gets.chomp
            kinds[kind]['categories'].push({
                "alias" => cat,
                "title" => cn
            })
    end
    kind_man.update(data: kinds)

    dev_art_man.insert({"path" => "#{kind}/#{name}", "state" => 1, "template" => "article", "category" => cat, "params" => {"title" => title}})
    open("#{dir}/#{name}.pug", "w")
end
