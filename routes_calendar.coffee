##
# The route handler for calendar information. 
# 
# Should get the data, filter it, and answer to the response.
##

iroh = require('./iroh')
RRule = require('rrule').RRule

##
# Serves array with ids for all available calendars
module.exports.all_ids = (req, res) ->
  iroh.query().then((data)->
      res.json data.dining
      return
    )

##
# req: contains cal_id for calendar to fetch.
module.exports.cal_id = (req, res) ->
  iroh.query(req.params.cal_id).then((data)->
      augmentedData = data
      augmentedData['cal_id'] = req.params.cal_id
      res.json augmentedData
      return
    )

# req: contains cal_id, start, and end.
module.exports.render_range = (req, res) ->
  
  iroh.query(req.params.cal_id).then((data)->
    console.log('============ THEN =============')
    jayjelly = render_calendar(data, req.params.start, req.params.end)
    res.json jayjelly
    return
  )


require 'datejs'

dow = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
rruleday = {
  "MO":RRule.MO
  "TU":RRule.TU
  "WE":RRule.WE
  "TH":RRule.TH
  "FR":RRule.FR
  "SA":RRule.SA
  "SU":RRule.SU
}


##
# @param[cal]     JSON vCalendar source
# @param[start]   start date to render
# @param[end]     end date to render
# @return         List of events between [start] and [end] rendered from  
#                 source [cal].
render_calendar = (cal, start, end) ->

  start = Date.parse start # Start date
  end   = Date.parse end   # End date

  # Find rules we might acutally care about
  # 
    
  results = []

  console.log "will loop over #{cal.events.length} events"
  i = 0

  for x in cal.events
    # console.log('x: ' + x)
    # End of the length we care about 
    death = if x.rrule then x.rrule.end else x.end
    # console.log('Not dead!')

    weekdays = x.rrule.weekdays || false
    # console.log(0)

    # >> If null, probably eternally repeating event. Not sure though. check.
    #    Make it unreachably in the future.
    if not death
      death = end.add(1).days()

    # console.log "#{death} and #{Object.prototype.toString.call(death)}"

    # Filter only the entries that would affect our range.
    if start.isAfter(x.start) and start.isBefore(death)
      # console.log(1)
      
      # We don't care if its for a weekday outside our range.
      if weekdays && weekdays.indexOf(dow[start.getDay()]) < 0
        # console.log('1a')
        continue
      # console.log(2)

      # Here we have all rules and events for the days we care about... maybe.
      

      if x.rrule
        # console.log(3)
        byweekday = if weekdays then (x.rrule.weekdays.split(",").map (x)->
          return rruleday[x]
        ) else []

        # console.log('3a')
        rule = new RRule({
            freq: RRule.WEEKLY, # Change.
            byweekday: byweekday,
            dtstart: x.rrule.start,
            until: x.rrule.end
        });
        # console.log('3b')
        evres = rule.between(start, end).map (r) ->

          start = new Date(
            r.getFullYear(),
            r.getMonth(),
            r.getDay(),
            x.start.getHours(),
            x.start.getMinutes(),
            x.start.getSeconds())

          end = new Date(
            r.getFullYear(),
            r.getMonth(),
            r.getDay(),
            x.end.getHours(),
            x.end.getMinutes(),
            x.end.getSeconds())

          results.push {
            summary : x.summary
            start : start
            end   : end
          }
          return 'done'

      else 
        # console.log(4)
        results.push x
  # console.log(5)
  return results



###

"events":[{
  description : ,
  start : 2014-12-22 05:00,
  end : 2014-12-23 05:00,
  location : ,
  modified : 2014-07-01T19:17:41.000Z,
  revisions : 1,
  rrule:
  {
    BYDAY : MO,TU,WE,TH,FR,
    FREQ : WEEKLY,
    UNTIL: 2015 01 20 
  },
  status : CONFIRMED,
  summary : Closed,
  timestamp : 2014-10-19T17:32:41.000Z,
  transparent : OPAQUE,
  uid : uffgb4i3hfpf2sl36dmibhl69k@google.com,
  updated : 2013-12-12T21:35:44.000Z
}
###



###

{
  location : <string>
  events: [{
    start: <int>
    end: <int>
    description: <string>
  }]
}

###