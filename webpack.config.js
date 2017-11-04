const webpack = require('webpack');
const path = require('path');

module.exports = {
  // エントリーポイント
  entry: './src/main.js',
  output: {
    filename: 'bundle.js',
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
        test: /\.scss/,
        loaders: [
          'style-loader',
          {
            loader: 'css-loader',
            options: {
              url :false  // cssのurl()禁止
            }
          },
          {
            loader: 'postcss-loader',
            options: {
              plugins: function() {
                return [
                  require('precss'),
                  require('autoprefixer')
                ];
              }
            }
          },
          'sass-loader'
        ]
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
};
