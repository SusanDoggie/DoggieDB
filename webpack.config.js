/* eslint no-var: 0 */

const path = require('path');
const webpack = require('webpack');
const TerserPlugin = require('terser-webpack-plugin');
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');

module.exports = (env, argv) => {
	
	const IS_PRODUCTION = argv.mode !== 'development';
	
	const babelLoaderConfiguration = {
		test: /\.(ts|tsx|m?js)?$/,
		use: {
		  loader: 'babel-loader',
		  options: {
			cacheDirectory: true,
			presets: [
				[
					'@babel/preset-react',
					{
						development: !IS_PRODUCTION,
					},
				],
			],
			plugins: [
				'@babel/plugin-transform-runtime',
				'@babel/plugin-syntax-dynamic-import',
				'@babel/plugin-proposal-class-properties',
				'react-native-reanimated/plugin',
			]
		  },
		}
	};
	
	const imageLoaderConfiguration = {
	  test: /\.(gif|jpe?g|a?png|svg)$/,
	  use: {
		loader: 'file-loader',
		options: {
			name: '[name].[contenthash].[ext]',
			publicPath: '/images',
			outputPath: 'images',
		}
	  }
	};
	
	const webpackConfiguration = {
		mode: IS_PRODUCTION ? 'production' : 'development',
		devtool: IS_PRODUCTION ? false : 'cheap-module-source-map',
		optimization: {
			minimize: IS_PRODUCTION,
			minimizer: [
				new TerserPlugin({
					parallel: true,
					extractComments: !IS_PRODUCTION,
					terserOptions: {
						sourceMap: !IS_PRODUCTION,
						compress: IS_PRODUCTION,
					},
				}),
			],
		},
		plugins: [ 
			new NodePolyfillPlugin(),
			new webpack.DefinePlugin({
				'process.env': {
					'NODE_ENV': IS_PRODUCTION ? '"production"' : 'undefined'
				}
			}),
		],
		module: {
		  rules: [
			babelLoaderConfiguration,
			imageLoaderConfiguration
		  ]
		},
		resolve: {
		  alias: {
			'react-native$': 'react-native-web'
		  },
		  extensions: ['.web.js', '.js']
		}
	};
	
	return [
		Object.assign({}, webpackConfiguration, {
			entry: { 
				main: './Sources/DBBrowser/js/main.js',
				server: {
					import: './Sources/DBBrowser/js/server.js',
					library: {
						name: 'render',
						type: 'global',
						export: 'default'
					}
				},
			},
			output: {
				path: path.join(__dirname, 'Sources/DBBrowser/Public'),
				publicPath: '/',
				filename: 'js/[name].js'
			}
		})
	];
};