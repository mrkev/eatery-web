#                                                                              #
#                              Eatery server                                   #
#                                                                              #

express = require("express")
app   = express()
router  = express.Router()

config  = require("./config")

#
# Set up the routes
#

## Home

router
  .route("/")
  .get (req, res) ->
      res.json message: "yo, welcome to our api!"
      return

## Locations

router
  .route("/location")
  .get (req, res) ->
      res.json( yo: 'whereup' )
      return

router
  .route("/location/:loc_id")
  .get (req, res) ->
      res.json( loc_id: req.params.loc_id )
      return


## Calendars

router
  .route("/calendar")
  .get (req, res) ->
      res.json( yo: 'whatup' )
      return

router
  .route("/calendar/:cal_id")
  .get (req, res) ->
      res.json( cal_id: req.params.cal_id )
      return

## Menus

router
  .route("/menu")
  .get (req, res) ->
      res.json( this_is: 'the_menu' )
      return

router
  .route("/menu/:menu_id")
  .get (req, res) ->
      res.json( menu_id: req.params.menu_id )
      return

router
  .route("/menu/:menu_id/:meal_type")
  .get (req, res) ->
      res.json
        menu_id: req.params.menu_id
        meal_type : req.params.meal_type
      return


#
# Start the server
# 
app
  .use("/", router)
  .listen(config.port)

console.log("Good stuff happens on port " + config.port)