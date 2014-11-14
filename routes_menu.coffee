require './vendor/date_format'
gcheerio = require 'cheerio'
request  = require 'request'
Promise  = require('es6-promise').Promise;

menu_locations = require('./menu_locations.json')

##
# @param date       A date object.
# 
# @param period     The meal to fetch.
#                    - Breakfast
#                    - Lunch
#                    - Dinner
#                    - Brunch
# 
# @param loc        An integer referring to a particular dining location
#                    - Cook House Dining Room
#                    - Becker House Dining Room
#                    - Keeton House Dining Room
#                    - Rose House Dining Room
#                    - Hans Bethe – Jansen's Dining Room
#                    - Robert Purcell Marketplace Eatery
#                    - North Star
#                    - Risley Dining
#                    - 104 West!
#                    - Okenshields
menus = (date, period, loc, callback) ->
  request.post({
    uri: 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm',
    form: {
      menudates: date.format('yyyy-mm-dd')
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

today = ->
  date = new Date()
  return (date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate())

module.exports.menu_id = (req, res) ->
  menu_id = menu_locations[req.params.menu_id]
  menu_list = {}
  t = today()
  # Sorry … should probably use streams or promises
  done1 = done2 = done3 = done4 = false
  renderIfDone = ->
    return unless done1 && done2 && done3 && done4
    res.json menu_list
  menus(t, 'Breakfast', menu_id, (items) ->
    menu_list['breakfast'] = items
    done1 = true
    renderIfDone()
  )
  menus(t, 'Lunch', menu_id, (items) ->
    menu_list['lunch'] = items
    done2 = true
    renderIfDone()
  )
  menus(t, 'Dinner', menu_id, (items) ->
    menu_list['dinner'] = items
    done3 = true
    renderIfDone()
  )
  menus(t, 'Brunch', menu_id, (items) ->
    menu_list['brunch'] = items
    done4 = true
    renderIfDone()
  )

module.exports.menu_for_meal = (req, res) ->
  menu_id = menu_locations[req.params.menu_id]
  meal_type_param = req.params.meal_type
  meal_type = meal_type_param.charAt(0).toUpperCase() + meal_type_param.slice(1)
  menus(today(), meal_type, menu_id, (items) ->
    res.json items
  )