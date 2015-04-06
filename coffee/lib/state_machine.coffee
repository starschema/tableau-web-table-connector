_ = require 'underscore'
$ = require 'jquery'


# Generates a tab-handler function that acts like a state machine
stateMachine = (startState, stateList, transitionHandlers={})->
  # Set up the data store
  data = {}
  # Initialize the current tab
  history = [startState]

  runTransitions = (from, to, names, callback)->
    for name in names
      transition = transitionHandlers[name]
      continue unless transition
      console.log("Running transition handler[#{from} -> #{to}]: #{name}")
      transition(data,from,to)

  # Shortcut for getting a transitions name
  nameOf = (from,to)-> "#{from} > #{to}"

  # The main transition function.
  #
  # Transition to a new state and use the history to figure out which
  # state we came from
  transitionTo = (to, withData={})->
    return unless _.contains(stateList, to)
    from = _.last history
    return if to == from
    _.extend data, withData
    runTransitions(from, to, ["leave #{from}", nameOf(from,to),"*", "enter #{to}"])
    history.push(to)

  # Go back in history
  goBack = (n)-> transitionTo(_.last( history,n)[0] )

  return {
    # A function that can be called with the id of
    # the new tab and transitions
    to: transitionTo
    back: goBack
    data: -> data
  }

# Provide a wizzard-like interface using the stateMachine.
#
#
wizzard = (startState, steps, transitionHandlers={})->
  $steps = (name)-> $(steps[name])
  console.log("steps:", steps)
  handlers = _.extend {}, transitionHandlers,
    "*": (data,from,to)->
      $steps(from).fadeOut(100)
      $steps(to).removeClass('hide').fadeIn(100)

  # Get the state machine
  sm = stateMachine(startState, _.keys(steps), handlers)

  $ ->
    # Hook our transitioners
    $('body').on 'click', '*[data-state-to]', (e)->
      e.preventDefault()
      transitions = $(this).data('state-to').split(/ +/)
      console.log("transition req:", transitions, sm)
      for to in transitions
        switch
          when to == ':back' then sm.back(1)
          when to == ':back2' then sm.back(2)
          else sm.to(to)

  sm


_.extend module.exports,
  stateMachine: stateMachine
  wizzard: wizzard
