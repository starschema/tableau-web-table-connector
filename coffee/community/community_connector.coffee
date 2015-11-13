$ = require 'jquery'
_ = require 'underscore'


tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'

load_url = (url, success_callback)->
  $.ajax
    url: url
    dataType: "text"
    success: (res)->

      res = res.substring(res.indexOf("\n") + 1)
      out = JSON.parse(res)

      list = for post in out.list
        updated: post.updated
        tags: JSON.stringify(post.tags)
        subject: post.subject
        viewCount: post.viewCount
        published: post.published
        categories: JSON.stringify(post.categories)
        resolved: post.resolved
        status: post.status
	place: post.parentPlace.name
        url: post.resources.html.ref

      out.list = list
      success_callback( out )

    error: (xhr, ajaxOptions, thrownError)->
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"


wdc_base.make_tableau_connector
  name: "Simple XXX connector"

  steps:
    start:
      template: require './start.jade'
    run:
      template: require './run.jade'


  transitions:
    "start > run": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")
      
      data.url = "http://community.tableau.com/api/core/v3/search/contents?filter=type(document,discussion)&filter=after(#{data.after})&filter=search(*a*)&sort=updatedDesc&fields=modified,published,tags,subject,categories,resolved,status,viewCount,updated"


    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->
     
    url = lastRecordToken || connection_data.url
    url = url.replace("http://", "http://localhost:1337/")

    load_url url, (data)->

      # Call back tableau
      has_more =  if data.links.next then true else false
      tableau.dataCallback data.list, data.links.next, has_more


  columns: (connection_data)->

    # Call back tableau
    tableau.headersCallback(
	    ["updated", "tags",   "subject", "viewCount", "published", "categories", "resolved", "status", "url",   "place"],
	    ["string",  "string", "string",  "int",       "string",    "string",     "string",   "string", "string", "string" ]  )
