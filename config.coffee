module.exports = (->
  ipaddr: process.env.OPENSHIFT_NODEJS_IP or  "127.0.0.1"
<<<<<<< HEAD
<<<<<<< HEAD
  port: process.env.OPENSHIFT_NODEJS_PORT or (if process.env.NODE_ENV == 'production' then process.env.PORT else 3000)
 
=======
  port: process.env.OPENSHIFT_NODEJS_PORT or (if process.env.NODE_ENV == 'production' then process.env.PORT else 8080)
)()
>>>>>>> This one is the charm
=======
  port: process.env.OPENSHIFT_NODEJS_PORT or (if process.env.NODE_ENV == 'production' then process.env.PORT else 3000)
)()
>>>>>>> Clean up
