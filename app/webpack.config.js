const path = require("path");
const HTMLWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const webpack = require('webpack');

module.exports = {
  mode: 'development',
  entry: "./src/index.js",
  output: {
    filename: "index.js",
    path: path.resolve(__dirname, "dist"),
  },
  plugins: [
    new HTMLWebpackPlugin({
      template: './src/index.html',
    }),
    new CleanWebpackPlugin(),
    new webpack.ProvidePlugin({
      process: 'process/browser',
    }),
    new webpack.ProvidePlugin({
      Buffer: ['buffer', 'Buffer']
    }),
  ],
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
            plugins: ['@babel/plugin-transform-runtime'],
          }
        }
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\.(?:ico|svg|gif|png|jpg|jpeg)$/i,
        type: 'asset/resource',
      }
    ]
  },
  devServer: {
    static: "dist",
    open: true,
    compress: true,
  },
  resolve: {
    fallback: {
      "stream": false,
      "crypto": false,
      "assert": false,
      "http": require.resolve("stream-http"),
      "https": false,
      "url": false,
      "os": false,
      "buffer": require.resolve("buffer"),
    }
  }
};
