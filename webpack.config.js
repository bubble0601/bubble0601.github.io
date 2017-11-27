/*global require, module, __dirname */
const webpack = require('webpack');
const path = require('path');
const glob = require('glob');
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const HtmlWebpackPlugin = require('html-webpack-plugin')

const getFileList = (dir, ext, exclude) =>{
  const ws = path.resolve(dir);
  const reg1 = new RegExp(`${ws}/`)
  const reg2 = new RegExp(`.${ext}$`)
  return glob.sync(`${ws}/**/[!_]*.${ext}`).map((v) => v.replace(reg1, '').replace(reg2, '')).filter((v) => v.indexOf(exclude) !== 0);
}

const pugs = getFileList('src/pug', 'pug', 'templates').map((v) => new HtmlWebpackPlugin({
  template: '../pug/' + v + '.pug',
  filename: '../' + v + '.html'
}));

module.exports = [{
  context: __dirname + '/src/js',
  entry: {
    'bundle': './main.js',
  },
  output: {
    filename: 'bundle.js',
    path: __dirname + '/public/js'
  },
  module: {
    rules: [
      {
        enforce: 'pre', // 他より先に処理
        test: /\.js$/,
        loader: 'eslint-loader'
      },
      {
        test: /\.js$/,
        use: [{
          loader: 'babel-loader',
          options: {
            presets: ['env']  // es2017 to es5
          }
        }]
      },
      {
        test: /\.pug$/,
        use: [{
          loader: 'html-loader'
        }, {
          loader: 'pug-html-loader',
          options: {
            filters: {
              'esc': text => text.replace(/[&'`"<>]/g, m => {return {'&': '&amp;',"'": '&#x27;','`': '&#x60;','"': '&quot;','<': '&lt;','>': '&gt;',}[m]})
            }
          }
        }]
      }
    ]
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin(),
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
      Popper: ['popper.js', 'default'],
      _: 'lodash'
    })
  ].concat(pugs)
}, {
  context: __dirname + '/src/sass',
  entry: {
    'bundle': './main.scss'
  },
  output: {
    filename: 'bundle.css',
    path: __dirname + '/public/css'
  },
  module: {
    rules: [
      {
        test: /\.scss$/,
        loader: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: ['css-loader?-url&minimize', 'sass-loader']
        })
      },
    ]
  },
  plugins: [
    new ExtractTextPlugin('[name].css')
  ]
}];
