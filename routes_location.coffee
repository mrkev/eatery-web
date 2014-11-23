iroh = require 'Iroh'
menu_manager = require './menu_manager'

module.exports.all_locations = (req, res) ->

# Copy and paste from routes_calendar (Sorry)
payment_options = require('./payment_options.json')
paymentOptionsForCalID = (cal_id) ->
  pms = payment_options[cal_id]
  return pms.split(',')

module.exports.location = (req, res) ->
  location = req.params.loc_id
  iroh.query(location).then((data)->
    data['cal_id'] = location
    delete data['events']
    data['payment_methods'] = paymentOptionsForCalID(location)
    menu_manager.menu_id(location).then((menu_data) ->
      data['menus'] = menu_data
      res.json data
    ).catch((e)->
      console.log('5')
      if e.name = '503'
        res.status(503).end()
      else
        res.status(500).end()
    )
    return
  ).catch((err) ->
    console.log('504 error on cal_id')
    res.status(504).end()
  )