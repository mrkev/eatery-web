cheerio = require 'cheerio'
request = require 'request'

menu_locations = require('./menu_locations.json')

menus = (date, period, loc, callback) ->
  request.post({
    uri: 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm',
    form: {
      menudates: date
      menuperiod: period
      menulocations: loc
    }
  }, (err, httpResp, body) ->
    $ = cheerio.load(body)
    menuItems = []
    currentCategory = ''
    for sib in $('#menuform').siblings()
      continue unless $(sib).hasClass('menuCatHeader') || $(sib).hasClass('menuItem')
      if $(sib).hasClass('menuCatHeader')
        currentCategory = $(sib).text().trim()
        continue
      isHealthy = $(sib).children().length >= 1
      menuItems.push({
        name: $(sib).text().trim()
        category: currentCategory
        healthy: isHealthy
      })
    callback(menuItems)
  )

module.exports.menu_id = (req, res) ->
  menu_id = menu_locations[req.params.menu_id]
  menu_list = {}
  date = new Date()
  today = date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate()
  # Sorry … should probably use streams or promises
  done1 = done2 = done3 = done4 = false
  renderIfDone = ->
    return unless done1 && done2 && done3 && done4
    res.json menu_list
  menus(today, 'Breakfast', menu_id, (items) ->
    menu_list['breakfast'] = items
    done1 = true
    renderIfDone()
  )
  menus(today, 'Lunch', menu_id, (items) ->
    menu_list['lunch'] = items
    done2 = true
    renderIfDone()
  )
  menus(today, 'Dinner', menu_id, (items) ->
    menu_list['dinner'] = items
    done3 = true
    renderIfDone()
  )
  menus(today, 'Brunch', menu_id, (items) ->
    menu_list['brunch'] = items
    done4 = true
    renderIfDone()
  )