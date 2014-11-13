cheerio = require 'cheerio'
request = require 'request'

menu_locations = require('./menu_locations.json')

module.exports.menu_id = (req, res) ->
  cal_id = req.params.cal_id
  menu_id = menu_locations[cal_id]
  request.post({
    uri: 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm',
    form: {
      menudates: '2014-11-9'
      menuperiod: 'Lunch'
      menulocations: menu_id
    }
  }, (err, httpResp, body) ->
    $ = cheerio.load(body)
    html = ''
    # $('#menuform').siblings().each((i, el) ->
    #   html += el.text()
    # )
    menuItems = []
    for sib in $('#menuform').siblings('.menuItem')
      menuItems.push($(sib).text().trim())
    res.json menuItems
  )