##
# The route handler for calendar information. 
# 
# Should get the data, filter it, and answer to the response.
##

iroh = require 'Iroh'
render_calendar = (require './calendar').render_calendar
cal_for = (require './calendar').cal_for
payment_options =  require('./payment_options.json')

paymentOptionsForCalID = (cal_id) ->
  pms = payment_options[cal_id]
  return pms.split(',')

##w
# Serves array with ids for all available calendars
module.exports.all_ids = (req, res) ->
  iroh.query().then((data)->
    res.json data.dining
    return
  )

##
# req: contains cal_id for calendar to fetch.
module.exports.cal_id = (req, res) ->
  cal_id = req.params.cal_id
  iroh.query(cal_id).then((data)->
    data['cal_id'] = cal_id
    # delete data['events']

    data['payment_methods'] = paymentOptionsForCalID(cal_id)

    res.json data
    return
  ).catch((err) ->
    console.log('504 error on cal_id')
    res.status(504).end()
  )

# req: contains cal_id, start, and end.
module.exports.render_range = (req, res) ->
  cal_id = req.params.cal_id
  cal_for(cal_id, req.params.start, req.params.end).then((data)->

    data.cal_id = cal_id
    data.payment_methods = paymentOptionsForCalID(cal_id)
    res.json data

    return
  ).catch((err) -> 
    res.status(504).end()
    console.trace err
  )

