
### Rendering the range ###
RRule = require('rrule').RRule
require 'datejs'
iroh = require 'Iroh'

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


module.exports.cal_for = (cal_id, start, end) ->
  iroh.query(cal_id).then((data)->
    
    data.events  = module.exports.render_calendar(data.events, start, end)
    data.updated = data.updated
    
    console.log "#{data.name} done."
    return data 
  
  ).catch((e) -> 
    console.trace e)

##
# @param[cal]     JSON vCalendar source
# @param[start]   start date to render
# @param[end]     end date to render
# @return         List of events between [start] and [end] rendered from  
#                 source [cal].
module.exports.render_calendar = (cal, start, end) ->

  start = Date.parse start # Start date
  end   = Date.parse end   # End date

  # Find rules we might acutally care about
  # 
    
  results = []

  i = 0

  for x in cal

    # End of the length we care about 
    death = if x.rrule then x.rrule.end else x.end

    # >> If null, probably eternally repeating event. Not sure though. check.
    #    Make it unreachably in the future.
    if not death
      death = end.add(1).days()

    # console.log "#{death} and #{Object.prototype.toString.call(death)}"

    # Filter only the entries that would affect our range.
    if start.isAfter(new Date(x.start)) and start.isBefore(new Date(death))
      
      # We don't care if its for a weekday outside our range.
      if x.rrule? and x.rrule.weekdays? and x.rrule.frequency? and x.rrule.weekdays.indexOf(dow[start.getDay()]) < 0
        continue

      # Here we have all rules and events for the days we care about... maybe.
      
      if x.rrule
        
        byweekday = undefined
        if x.rrule.weekdays
          byweekday = x.rrule.weekdays.split(",").map (x)-> return rruleday[x]

        for_rrule = {
            freq:       RRule.WEEKLY, # Change.
            dtstart:    x.rrule.start,
            until:      x.rrule.end,
            count:      x.rrule.count
        }

        if byweekday
          for_rrule.byweekday = byweekday
        
        if x.rrule.count
          for_rrule.count = x.rrule.count
        
        rule = new RRule(for_rrule);

        evres = rule.between(start, end).map (r) ->

          x.start = new Date(x.start)
          x.end = new Date(x.end)

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
            start : Number(start)
            end   : Number(end)
          }
          
          return 'done'

      else 
        results.push x
      
  return results

