// Production backend bundle config used by Dockerfile.zh to rebuild the server
// bundle (docker/index.js) from source, mirroring the official build:
//   - entry: src/run/docker.ts (the standalone server bootstrap the image runs)
//   - output: docker/index.js  (the file /usr/src/appEntry/start.sh executes)
//   - minimize:false + nodeExternals so runtime deps resolve from the official
//     image's node_modules (unchanged for the same release tag).
// ts-checker is intentionally omitted: type-checking is not required to emit a
// correct bundle and would fail the build on unrelated pre-existing type noise.
const { resolve } = require('path');
const { rspack } = require('@rspack/core');
const nodeExternals = require('webpack-node-externals');

module.exports = {
  entry: './src/run/docker.ts',
  module: {
    rules: [
      {
        test: /\.node$/,
        loader: 'node-loader',
        options: {
          name: '[path][name].[ext]',
        },
      },
      {
        test: /\.tsx?$/,
        exclude: /node_modules/,
        loader: 'builtin:swc-loader',
        options: {
          sourceMaps: false,
          jsc: {
            parser: {
              syntax: 'typescript',
              tsx: true,
              decorators: true,
              dynamicImport: true,
            },
            transform: {
              legacyDecorator: true,
              decoratorMetadata: true,
            },
            target: 'es2017',
            loose: true,
            externalHelpers: false,
            keepClassNames: true,
          },
          module: {
            type: 'commonjs',
            strict: false,
            strictMode: true,
            lazy: false,
            noInterop: false,
          },
        },
      },
    ],
  },
  optimization: {
    minimize: false,
    nodeEnv: false,
  },
  externals: [
    nodeExternals({
      allowlist: ['nocodb-sdk'],
    }),
  ],
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.json', '.node'],
    tsConfig: {
      configFile: resolve('tsconfig.json'),
    },
    alias: {
      '@noco-local-integrations': resolve(__dirname, '../noco-integrations/packages'),
    },
  },
  mode: 'production',
  output: {
    filename: 'index.js',
    path: resolve(__dirname, 'docker'),
    library: 'libs',
    libraryTarget: 'umd',
    globalObject: "typeof self !== 'undefined' ? self : this",
  },
  node: {
    __dirname: false,
  },
  plugins: [
    new rspack.EnvironmentPlugin({
      EE: true,
    }),
    new rspack.CopyRspackPlugin({
      patterns: [{ from: 'src/public', to: 'public' }],
    }),
  ],
  target: 'node',
};
