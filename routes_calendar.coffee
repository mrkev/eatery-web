##
# The route handler for calendar information. 
# 
# Should get the data, filter it, and answer to the response.
##

iroh = require 'Iroh'
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
      res.json data
      return
    )

# req: contains cal_id, start, and end.
module.exports.render_range = (req, res) ->
  
  iroh.query(req.params.cal_id).then((data)->
    try
      console.log data
      jayjelly = render_calendar(data.events, req.params.start, req.params.end)
    catch e 
      console.trace e
    res.json jayjelly
    return
  ).catch(console.trace)


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

  console.log "will loop over #{cal.length} events"
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
            start : start
            end   : end
          }
          return 'done'

      else 
        results.push x
      
  return results


##################
# For testing
# test = JSON.parse '[{"start":1413028800000,"end":1413050400000,"description":"","status":"CONFIRMED","summary":"Open until 2:00pm"},{"start":1417323600000,"end":1417410000000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1408654800000,"end":1408660200000,"description":"","status":"CONFIRMED","summary":"Dinner until 6:30pm"},{"start":1408568400000,"end":1408577400000,"description":"","status":"CONFIRMED","summary":"Dinner until 7:30pm"},{"start":1408633200000,"end":1408642200000,"description":"","status":"CONFIRMED","summary":"Limited Lunch until 1:30pm"},{"start":1408359600000,"end":1408406400000,"description":"","status":"CONFIRMED","summary":"Limited Service until 8:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1408507199000},"rexcept":1408359600000},{"start":1408532400000,"end":1408555800000,"description":"","status":"CONFIRMED","summary":"Limited Lunch until 1:30pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1408618800000}},{"start":1419051600000,"end":1419138000000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR,SA","end":1420848000000}},{"start":1416978000000,"end":1417064400000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"WE,TH,FR,SA","end":1417219200000}},{"start":1413086400000,"end":1413172800000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU","end":1413244800000}},{"start":1409432400000,"end":1409443200000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1419112800000},"rexcept":1419112800000},{"start":1410026400000,"end":1410033600000,"description":"","status":"CONFIRMED","summary":"Lite Lunch served until 4:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1418497200000},"rexcept":1417287600000},{"start":1409409000000,"end":1409421600000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1419089400000},"rexcept":1419089400000},{"start":1408888800000,"end":1408903200000,"description":"","status":"CONFIRMED","summary":"Brunch served until 2:00pm"},{"start":1408804200000,"end":1408824000000,"description":"","status":"CONFIRMED","summary":"Lunch served until 4:00pm"},{"start":1408791600000,"end":1408804200000,"description":"","status":"CONFIRMED","summary":"Open until 10:30pm"},{"start":1408717800000,"end":1408737600000,"description":"","status":"CONFIRMED","summary":"Lunch served until 4:00pm"},{"start":1408374000000,"end":1408404600000,"description":"","status":"CONFIRMED","summary":"Limited service until 7:30pm"},{"start":1404142200000,"end":1404151200000,"description":"","status":"CONFIRMED","summary":"Open until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1405611000000}},{"start":1404073800000,"end":1404082800000,"description":"","status":"CONFIRMED","summary":"Open until 7pm"},{"start":1402113600000,"end":1402200000000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1409356800000},"rexcept":1409371200000},{"start":1390050000000,"end":1390093200000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1402113599000},"rexcept":1396094400000},{"start":1409400000000,"end":1409409000000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1419080400000},"rexcept":1419080400000},{"start":1409000400000,"end":1409011200000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm"},{"start":1409086800000,"end":1409097600000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1419026400000},"rexcept":1417212000000},{"start":1408989600000,"end":1408996800000,"description":"","status":"CONFIRMED","summary":"Lite Lunch served until 4:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1419015600000},"rexcept":1417201200000},{"start":1408977000000,"end":1408989600000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1419003000000},"rexcept":1417188600000},{"start":1408964400000,"end":1408977000000,"description":"","status":"CONFIRMED","summary":"Breakfast served until  10:30am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1418990400000},"rexcept":1417176000000},{"start":1408914000000,"end":1408924800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1419199200000},"rexcept":1417384800000},{"start":1408903200000,"end":1408910400000,"description":"","status":"CONFIRMED","summary":"Lite Lunch served until 4:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1418583600000},"rexcept":1417374000000},{"start":1408890600000,"end":1408903200000,"description":"","status":"CONFIRMED","summary":"Brunch served until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1418571000000},"rexcept":1417361400000},{"start":1408825800000,"end":1408838400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm"},{"start":1408739400000,"end":1408752000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm"},{"start":1407038400000,"end":1407124800000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1408233600000}},{"start":1405828800000,"end":1405915200000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH","end":1406764800000}},{"start":1404678600000,"end":1404687600000,"description":"","status":"CONFIRMED","summary":"Open until 7:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1405283400000}},{"start":1404160200000,"end":1404169200000,"description":"","status":"CONFIRMED","summary":"Open until 7:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE","end":1405542600000}},{"start":1404446400000,"end":1404532800000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"FR","end":1406851200000}},{"start":1404126000000,"end":1404133200000,"description":"","status":"CONFIRMED","summary":"Open until 9:00am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1405594800000}},{"start":1401595200000,"end":1401681600000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1403827200000}},{"start":1400846400000,"end":1400889600000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1400760000000,"end":1400803200000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1397422800000,"end":1397435400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30PM"},{"start":1397509200000,"end":1397521800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30PM"},{"start":1396103400000,"end":1396116000000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm"},{"start":1396090800000,"end":1396103400000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1396040400000,"end":1396053000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30pm"},{"start":1396029600000,"end":1396036800000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4:00pm"},{"start":1396756800000,"end":1396843200000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1392526800000,"end":1392613200000,"description":"","status":"CONFIRMED","summary":"Closed for Break","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU","end":1392681600000}},{"start":1392478200000,"end":1392490800000,"description":"","status":"CONFIRMED","summary":"Open until 2:00pm"},{"start":1392465600000,"end":1392478200000,"description":"","status":"CONFIRMED","summary":"Open until 10:30am"},{"start":1392415200000,"end":1392426000000,"description":"","status":"CONFIRMED","summary":"Open until 8:00pm"},{"start":1392933600000,"end":1392944400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00PM"},{"start":1392847200000,"end":1392858000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00PM"},{"start":1393279200000,"end":1393290000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00PM","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1400792400000},"rexcept":1400792400000},{"start":1393279200000,"end":1393290000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 2:00PM","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1393279199000}},{"start":1392588000000,"end":1392598800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00PM","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1400446800000},"rexcept":1396818000000},{"start":1391378400000,"end":1391389200000,"description":"","status":"CONFIRMED","summary":"Dinner served until 2:00PM","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1392587999000}},{"start":1391464800000,"end":1391475600000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1392069599000}},{"start":1392069600000,"end":1392080400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1392328800000}},{"start":1390255200000,"end":1390267800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1391403599000},"rexcept":1390255200000},{"start":1390168800000,"end":1390181400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 2:00PM","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1391317199000},"rexcept":1390168800000},{"start":1389790800000,"end":1389834000000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,WE,TH,FR,SA","end":1390222800000}},{"start":1387639800000,"end":1387652400000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm"},{"start":1387627200000,"end":1387639800000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1387576800000,"end":1387587600000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm"},{"start":1387566000000,"end":1387573200000,"description":"","status":"CONFIRMED","summary":"Late Lunch open until 4:00pm"},{"start":1387553400000,"end":1387566000000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm"},{"start":1387540800000,"end":1387553400000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1387544400000,"end":1387587600000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR,SA","end":1388235600000},"rexcept":1387630800000},{"start":1387121400000,"end":1387134000000,"description":"","status":"CONFIRMED","summary":"Brunch served until 2pm"},{"start":1386417600000,"end":1386430200000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1401019200000,"end":1401062400000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1401451200000}},{"start":1393268400000,"end":1393275600000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4:00PM","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1400781600000},"rexcept":1400781600000},{"start":1390231800000,"end":1390244400000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00PM","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1400855400000},"rexcept":1400855400000},{"start":1390219200000,"end":1390231800000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30PM","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1400842800000},"rexcept":1400842800000},{"start":1390158000000,"end":1390165200000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4:00PM","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1400436000000},"rexcept":1396807200000},{"start":1396180800000,"end":1396224000000,"description":"","status":"CONFIRMED","summary":"Closed (Spring Break)","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1396612800000}},{"start":1392555600000,"end":1392598800000,"description":"","status":"CONFIRMED","summary":"TBD","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1392987600000},"rexcept":1392987600000},{"start":1390244400000,"end":1390251600000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4:00PM","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1392318000000},"rexcept":1390244400000},{"start":1390143600000,"end":1390158000000,"description":"","status":"CONFIRMED","summary":"Brunch served until 2:00PM","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1400421600000},"rexcept":1396792800000},{"start":1388322000000,"end":1388365200000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR,SA","end":1389704400000}},{"start":1385640000000,"end":1385683200000,"description":"","status":"CONFIRMED","summary":"Closed for Thanksgiving","rrule":{"frequency":"WEEKLY","weekdays":"TH,FR,SA","end":1385787599000}},{"start":1385812800000,"end":1385856000000,"description":"","status":"CONFIRMED","summary":"Closed for Thanksgiving","rrule":{"frequency":"WEEKLY","weekdays":"SU,TH,FR,SA","end":1385899200000}},{"start":1385566200000,"end":1385578800000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2pm"},{"start":1385553600000,"end":1385566200000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1385578800000,"end":1385622000000,"description":"","status":"CONFIRMED","summary":"Closed for Thanksgiving"},{"start":1381809600000,"end":1381896000000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1381723200000,"end":1381809600000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1381636800000,"end":1381723200000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1381575600000,"end":1381588200000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1381525200000,"end":1381537800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30pm"},{"start":1376827200000,"end":1376870400000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"DAILY","count":5}},{"start":1377289800000,"end":1377302400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8pm"},{"start":1377982800000,"end":1377993600000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8pm","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1387663200000},"rexcept":1387663200000},{"start":1377972000000,"end":1377979200000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4pm","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1387652400000},"rexcept":1387652400000},{"start":1377959400000,"end":1377972000000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2pm","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1387639800000},"rexcept":1387639800000},{"start":1377950400000,"end":1377959400000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1387630800000},"rexcept":1387630800000},{"start":1355576400000,"end":1355619600000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SA","end":1377950400000},"rexcept":1377950400000},{"start":1376946000000,"end":1376956800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1387576800000},"rexcept":1387576800000},{"start":1376935200000,"end":1376942400000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1387566000000},"rexcept":1387566000000},{"start":1376922600000,"end":1376935200000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1387553400000},"rexcept":1387553400000},{"start":1376910000000,"end":1376922600000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1387540800000},"rexcept":1387540800000},{"start":1377464400000,"end":1377475200000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1387749600000},"rexcept":1387749600000},{"start":1377453600000,"end":1377460800000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1387738800000},"rexcept":1387738800000},{"start":1377439200000,"end":1377453600000,"description":"","status":"CONFIRMED","summary":"Brunch served until 2pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1387724400000},"rexcept":1387724400000},{"start":1368738000000,"end":1368750600000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30pm"},{"start":1372019400000,"end":1372028400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 7pm","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH","end":1372278600000}},{"start":1372087800000,"end":1372096800000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1372347000000}},{"start":1372071600000,"end":1372078800000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 9am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR,SA","end":1372330800000}},{"start":1373229000000,"end":1373238000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 7pm","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1373488200000}},{"start":1373297400000,"end":1373306400000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH","end":1373556600000}},{"start":1373281200000,"end":1373288400000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 9am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1373540400000}},{"start":1377378000000,"end":1377388800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8pm"},{"start":1377367200000,"end":1377374400000,"description":"","status":"CONFIRMED","summary":"Late Lunch served until 4pm"},{"start":1377354600000,"end":1377367200000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2pm"},{"start":1377345600000,"end":1377354600000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1376683200000,"end":1376697600000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8pm"},{"start":1376773200000,"end":1376785800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30pm"},{"start":1376749800000,"end":1376764200000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:30pm"},{"start":1376740800000,"end":1376749800000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1373630400000,"end":1373673600000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1376222400000},"rexcept":1374062400000},{"start":1372420800000,"end":1372464000000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1373025600000}},{"start":1370174400000,"end":1370217600000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR,SA","end":1371902400000}},{"start":1367593200000,"end":1367604000000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm"},{"start":1367578800000,"end":1367593200000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 11:00am"},{"start":1369564200000,"end":1369575000000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 9:30am"},{"start":1368964800000,"end":1369008000000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1370001600000},"rexcept":1369569600000},{"start":1340733600000,"end":1340740800000,"description":"","status":"CONFIRMED","summary":"Lite Lunch served until 4:00pm","rrule":{"frequency":"WEEKLY","weekdays":"TU,TH","end":1368727200000},"rexcept":1363888800000},{"start":1355166000000,"end":1355173200000,"description":"","status":"CONFIRMED","summary":"Lite Lunch until 4:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,WE","end":1368640800000},"rexcept":1363802400000},{"start":1364158800000,"end":1364171400000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30pm"},{"start":1340658000000,"end":1340668800000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH","end":1368738000000},"rexcept":1363899600000},{"start":1355079600000,"end":1355086800000,"description":"","status":"CONFIRMED","summary":"Lite Lunch served until 4:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1368381600000},"rexcept":1364148000000},{"start":1367838000000,"end":1367850600000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1368788400000}},{"start":1367850600000,"end":1367863200000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1368801000000}},{"start":1336917600000,"end":1336932000000,"description":"","status":"CONFIRMED","summary":"Brunch served until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"SU","end":1368367200000},"rexcept":1364133600000},{"start":1368887400000,"end":1368900000000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm"},{"start":1368874800000,"end":1368887400000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 10:30am"},{"start":1368824400000,"end":1368837000000,"description":"","status":"CONFIRMED","summary":"Dinner served until 8:30pm"},{"start":1368813600000,"end":1368820800000,"description":"","status":"CONFIRMED","summary":"Lite Lunch served until 4:00pm"},{"start":1340636400000,"end":1340647200000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1367812799000},"rexcept":1367593200000},{"start":1340622000000,"end":1340636400000,"description":"","status":"CONFIRMED","summary":"Breakfast served until 11:00am","rrule":{"frequency":"WEEKLY","weekdays":"MO,TU,WE,TH,FR","end":1367812799000},"rexcept":1367578800000},{"start":1363521600000,"end":1363564800000,"description":"","status":"CONFIRMED","summary":"Closed","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH,FR","end":1363953600000}},{"start":1363446000000,"end":1363456800000,"description":"","status":"CONFIRMED","summary":"Lunch served until 2:00pm"},{"start":1363435200000,"end":1363446000000,"description":"","status":"CONFIRMED","summary":"Breakfast Served until 11:00am"},{"start":1363381200000,"end":1363392000000,"description":"","status":"CONFIRMED","summary":"Dinner Served until 8:00pm"},{"start":1363370400000,"end":1363377600000,"description":"","status":"CONFIRMED","summary":"Lite Lunch Served until 4:00pm"},{"start":1358514000000,"end":1358557200000,"description":"","status":"CONFIRMED","summary":"Closed"},{"start":1336942800000,"end":1336953600000,"description":"","status":"CONFIRMED","summary":"Dinner","rrule":{"frequency":"WEEKLY","weekdays":"SU,MO,TU,WE,TH","end":1340596799000}}]'
# render_calendar(test, 'today', 'tomorrow')
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