module.exports = (->
  ipaddr: process.env.OPENSHIFT_NODEJS_IP or "0.0.0.0"
  port: process.env.OPENSHIFT_NODEJS_PORT or 80
)()