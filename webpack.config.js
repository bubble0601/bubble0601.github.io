const webpack = require('webpack');
const path = require('path');
const ExtractTextPlugin = require('extract-text-webpack-plugin')

module.exports = [{
  // エントリーポイント
  entry: {
    'bundle': './src/main.js',
  },
  output: {
    filename: '[name].js',
    // 出力先のパス（絶対パスを指定）
    path: path.join(__dirname, 'public/js')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: [{
          loader: 'babel-loader',
          options: {
            presets: ['env']  // es2017 to es5
          }
        }]
      },
      {
        enforce: 'pre', // 他より先に処理
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'eslint-loader'
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
  ]
}, {
  entry: {
    'bundle': './src/main.scss'
  },
  output: {
    filename: '[name].css',
    path: path.join(__dirname, 'public/css')
  },
  module: {
    rules: [
      {
        test: /\.scss/,
        loader: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: ['css-loader?-url&minimize', 'sass-loader']})
      },
    ]
  },
  plugins: [
        new ExtractTextPlugin('[name].css')
  ]
}];
