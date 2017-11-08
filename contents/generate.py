# src/pugのpugたちを生成する

import json
from datetime import datetime as dt

STATES = {
  'Invalid':   0,
  'Published': 1
};

try:
    with open('main.json', 'r') as f:
        data = json.loads(f.read())

    for d in data:
        with open(d['filename'], 'r') as f:
            contents = json.loads(f.read())
        for c in contents:
            if c['state'] == STATES['Invalid']:
                continue
            # パラメータ
            params = dict([(k, json.dumps(v, ensure_ascii=False)) for k, v in c['params'].items()])
            params['name'] = json.dumps(c['name'])
            params['date'] = json.dumps(dt.fromtimestamp(c['date']).date().isoformat())

            # template読み込み
            with open(d['path'] + '/' + c['template'] + '.pug') as f:
                tpl = f.read()

            # pug読み込み
            with open(d['path'] + '/' + c['name'] + '.pug') as f:
                params['content'] = f.read().replace("\n", "\n    ")

            # template適用
            for k, v in params.items():
                tpl = tpl.replace("#{%s}" % k, v)

            # 出力
            output_path = '../src/pug/' + d['path'] + '/' + c['name'] + '.pug'
            with open(output_path, 'w') as f:
                f.write(tpl)
            print('write: %s' % output_path)
except Exception as e:
    # print(e)
    raise e
