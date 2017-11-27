require "json"
require "fileutils"
require_relative 'data_manager'

module Status
    INVALID   = 0
    PUBLISHED = 1
end

################################################################################
# データ形式: Hashの配列. Hashの中身は以下
# filename(必須): 変換元(かつ変換先)のアドレス
# template(必須): \{param_name}をparamsから適用.↑はcontentとして適用
# params        : templateに適用するパラメータ
################################################################################
def main
    univ()
    univ_top()
    lang()
    lang_top()
end

def univ
    data = DataMan.new('univ_articles').get(cond: {'state' => Status::PUBLISHED})
    data.each { |e| e['params']['name'] = e['filename'] }
    generate(data, 'univ/')
end

def univ_top
    art_data = DataMan.new('univ_articles').get(cond: {'state' => Status::PUBLISHED})
    data = [{
        'filename' => 'univ',           # 出力先
        'template' => 'univ/top',       # 入力
        'params' => {'articles' => art_data.map{ |e| {
            'url' => "univ/#{e['filename']}",
            'title' => e['params']['title'],
            'img' => e['thumbnail']
        } }},
    }]
    generate(data)
end

def lang
    data = DataMan.new('lang_articles').get(cond: {'state' => Status::PUBLISHED})
    langs = DataMan.new('langs').get
    data.each do |e|
        begin
            e['lang'] = e['filename'].split('/')[0]
            e['params']['name'] = e['filename'].split('/')[1]
        rescue
            puts "failed: probably filename do not contain lang"
        end
        e['params']['langname'] = langs[e['lang']]['name']
    end
    data.each do |elem|
        categories = langs[elem['lang']]['categories']
        elem['params']['categories'] = []
        categories.each_with_index do |cat, i|
            elem['params']['categories'].push({
                'id' => i,
                'title' => cat['title'],
                'list' => data.select{ |e| e['lang'] == elem['lang'] and e['category'] == cat['alias'] }.map{ |e| {'filename' => e['filename'], 'title' => e['params']['title']} }
            })
        end

        other_lang_data = data.select{ |e| e['params']['name'] == elem['params']['name'] and e['lang'] != elem['lang'] }.map{ |e| {'filename' => e['filename'], 'title' => e['params']['langname']} }
        elem['params']['categories'].push({
            'id' => elem['params']['categories'].length,
            'title' => '他の言語',
            'list' => other_lang_data
        }) if other_lang_data.length > 0
    end
    generate(data, 'lang/')
end

def lang_top
    data = DataMan.new('lang_articles').get(cond: {'state' => Status::PUBLISHED})
    langs = DataMan.new('langs').get
    lang_data = langs.map do |k, l| {
        'lang' => k,
        'name' => l['name'],
        'categories' => l['categories'].map.with_index do |cat, i| {
            'id' => i,
            'title' => cat['title'],
            'list' => data.select{ |e| e['filename'].split('/')[0] == k and e['category'] == cat['alias'] }.map{ |e| {'filename' => e['filename'], 'title' => e['params']['title']} }
        }
        end
    }
    end
    data = [{
        'filename' => 'lang',
        'template' => 'lang/top',
        'params' => {
            'langs' => lang_data
        }
    }]
    generate(data)
end

def generate(data, path = '')
    data.each do |v|
        # パラメータ
        v['params'] = {} unless v['params']
        params = v['params'].map{ |k, v| [k, JSON.dump(v)] }.to_h
        v.each { |k, v| params[k] = JSON.dump(v) if k != 'params' }

        tpl = ''
        # template読み込み
        open("#{ROOT_PATH}/#{path}#{v['template']}.pug") do |f|
            tpl = f.read()
        end

        # pug読み込み
        if File.exist?("#{ROOT_PATH}/#{path}#{v['filename']}.pug")
            open("#{ROOT_PATH}/#{path}#{v['filename']}.pug") do |f|
                params['content'] = f.read().gsub(/\n/, "\n    ")   # TODO: インデントをうまく処理
            end
        end

        # template適用
        params.each do |name, val|
            tpl.gsub!(/\\{#{name}}/, val.to_s)
        end

        # 出力
        output_path = "#{ROOT_PATH}/../src/pug/#{path}#{v['filename']}.pug"
        dir = File.split(output_path)[0]
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        open(output_path, 'w') do |f|
            f.write(tpl)
        end
        puts "write: src/pug/#{path}#{v['filename']}.pug"
    end
end

main()
