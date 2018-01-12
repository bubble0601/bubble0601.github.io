require "json"
require "fileutils"
require_relative 'data_manager'

module Status
    INVALID   = 0
    PUBLISHED = 1
end

################################################################################
# データ形式: Hashの配列. Hashの中身は以下
# path(必須): 変換元(かつ変換先)のアドレス
# template(必須): \{param_name}をparamsから適用.↑はcontentとして適用
# params        : templateに適用するパラメータ
################################################################################
def main
    learning()
    learning_top()
    dev()
    dev_top()
end

def learning
    data = DataMan.new('learning_articles').get(cond: {'state' => Status::PUBLISHED})
    data.each { |e| e['params']['name'] = e['path'] }
    generate(data, 'learning/')
end

def learning_top
    art_data = DataMan.new('learning_articles').get(cond: {'state' => Status::PUBLISHED})
    data = [{
        'path' => 'learning',           # 出力先
        'template' => 'learning/top',       # 入力
        'params' => {'articles' => art_data.map{ |e| {
            'url' => "learning/#{e['path']}",
            'title' => e['params']['title'],
            'img' => e['thumbnail']
        } }},
    }]
    generate(data)
end

def dev
    data = DataMan.new('dev_articles').get(cond: {'state' => Status::PUBLISHED})
    kinds = DataMan.new('kinds').get.select{ |k, v| v['state'] == 1 }
    data.each do |e|
        begin
            e['kind'] = e['path'].split('/')[0]
            e['params']['name'] = e['path'].split('/')[1]
        rescue
            puts "failed: probably path do not contain kind"
        end
        e['params']['kindname'] = kinds[e['kind']]['name']
    end
    data.each do |elem|
        categories = kinds[elem['kind']]['categories']
        elem['params']['categories'] = []
        categories.each_with_index do |cat, i|
            elem['params']['categories'].push({
                'id' => i,
                'title' => cat['title'],
                'list' => data.select{ |e| e['kind'] == elem['kind'] and e['category'] == cat['alias'] }.map{ |e| {'path' => e['path'], 'title' => e['params']['title']} }
            })
        end

        other_kind_data = data.select{ |e| e['params']['name'] == elem['params']['name'] and e['kind'] != elem['kind'] }.map{ |e| {'path' => e['path'], 'title' => e['params']['kindname']} }
        elem['params']['categories'].push({
            'id' => elem['params']['categories'].length,
            'title' => '他の言語',
            'list' => other_kind_data
        }) if other_kind_data.length > 0
    end
    generate(data, 'dev/')
end

def dev_top
    data = DataMan.new('dev_articles').get(cond: {'state' => Status::PUBLISHED})
    kinds = DataMan.new('kinds').get
    kind_data = kinds.map do |k, l| {
        'kind' => k,
        'name' => l['name'],
        'categories' => l['categories'].map.with_index do |cat, i| {
            'id' => i,
            'title' => cat['title'],
            'list' => data.select{ |e| e['path'].split('/')[0] == k and e['category'] == cat['alias'] }.map{ |e| {'path' => e['path'], 'title' => e['params']['title']} }
        }
        end
    }
    end
    data = [{
        'path' => 'dev',
        'template' => 'dev/top',
        'params' => {
            'kinds' => kind_data
        }
    }]
    generate(data)
end

def generate(data, dir = '')
    data.each do |v|
        # パラメータ
        v['params'] = {} unless v['params']
        params = v['params'].map{ |k, v| [k, JSON.dump(v)] }.to_h
        v.each { |k, v| params[k] = JSON.dump(v) if k != 'params' }

        tpl = ''
        # template読み込み
        open("#{ROOT_PATH}/#{dir}#{v['template']}.pug") do |f|
            tpl = f.read()
        end

        # pug読み込み
        if File.exist?("#{ROOT_PATH}/#{dir}#{v['path']}.pug")
            open("#{ROOT_PATH}/#{dir}#{v['path']}.pug") do |f|
                params['content'] = f.read().gsub(/\n/, "\n    ")   # TODO: インデントをうまく処理
            end
        end

        # template適用
        params.each do |name, val|
            tpl.gsub!(/\\{#{name}}/, val.to_s)
        end

        # 出力
        output_path = "#{ROOT_PATH}/../src/pug/#{dir}#{v['path']}.pug"
        output_dir = File.split(output_path)[0]
        FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
        open(output_path, 'w') do |f|
            f.write(tpl)
        end
        puts "write: src/pug/#{dir}#{v['path']}.pug"
    end
end

main()
