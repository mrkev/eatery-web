module.exports = (->
  ipaddr: process.env.OPENSHIFT_NODEJS_IP or  "127.0.0.1"
  port: process.env.OPENSHIFT_NODEJS_PORT or (if process.env.NODE_ENV == 'production' then process.env.PORT else 3000)
)()