module.exports = {
  plugins: [
    require('postcss-easy-import'),
    require('postcss-preset-env')({ 
      stage: 2,
      features: {
        'nesting-rules': true,
      },
    }),
    process.env.NODE_ENV === 'production' && require('cssnano')({
      preset: 'default',
    }),
  ],
}
