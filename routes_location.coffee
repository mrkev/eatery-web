iroh = require 'Iroh'
menu_manager = (require './menu_manager')
cal_for = (require './calendar').cal_for

module.exports.all_locations = (req, res) ->
  iroh.query().then((iroh)->
    requests = []
    for cal_id in iroh.dining
      do(cal_id) ->
        console.log "Now on #{cal_id}"
        requests.push(all_data_for cal_id)

    Promise.all(requests).then(res.json)

    return
  ).catch((err) ->
    console.errur('504 error on location_id')
    res.status(504).end()
  )

all_data_for = (cal_id) ->
  cal_for(cal_id, 'today', 'tomorrow').then((cal_data)->
    
    loc_data = 
      id : cal_id
      calendar : cal_data
      payment_methods : paymentOptionsForCalID(cal_id)

    console.log "> Cal for #{cal_id}"
    
    menu_manager.menu_id(cal_id).then((menu_data) ->
      loc_data.menus = menu_data
      console.log "> Menu for #{cal_id}"
      return loc_data
    ).catch((e)->
      throw e
    )
  )

# Copy and paste from routes_calendar (Sorry)
payment_options = require('./payment_options.json')
paymentOptionsForCalID = (cal_id) ->
  pms = payment_options[cal_id]
  return pms.split(',')

module.exports.location = (req, res) ->
  location = req.params.loc_id
  iroh.query(location).then((data)->
    data['id'] = location
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
    console.log('504 error on location_id')
    res.status(504).end()
  )