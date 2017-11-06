const webpack = require('webpack');
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const HtmlWebpackPlugin = require('html-webpack-plugin')

var pugs = ['index', 'univ/1'];
pugs = pugs.map(function(v) {
  return new HtmlWebpackPlugin({
    template: '../pug/' + v + '.pug',
    filename: '../' + v + '.html'
  })
});

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
        loader:['html-loader', 'pug-html-loader']
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
