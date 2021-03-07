/* eslint no-var: 0 */

var path = require('path');
var webpack = require('webpack');

const babelLoaderConfiguration = {
	test: /\.(ts|tsx|js)?$/,
	use: {
	  loader: 'babel-loader',
	  options: {
		cacheDirectory: true,
		presets: [
			'@babel/preset-react',
		],
		plugins: [
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

function createConfig(isProductionMode) {
	var config = {
		mode: isProductionMode ? 'production' : 'development',
		plugins: [ 
			new webpack.DefinePlugin({
				'process.env': {
					'NODE_ENV': isProductionMode ? 'production' : 'undefined'
				}
			})
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

	if (isProductionMode) {
		config.plugins.push(new webpack.optimize.UglifyJsPlugin({
			minimize: true,
			compress: {
				warnings: false
			},
			sourceMap: false
		}));
		config.devtool = 'hidden-source-map';
	}
	else {
		config.devtool = 'eval-cheap-module-source-map';
	}
	return config;
}

module.exports = [
	Object.assign({}, createConfig(process.env.NODE_ENV === 'production'), {
		entry: { 
			main: './Sources/DBBrowser/js/main.js',
		},
		output: {
			path: path.join(__dirname, 'Sources/DBBrowser/Public'),
			publicPath: '/',
			filename: 'js/[name].js'
		}
	})
];
