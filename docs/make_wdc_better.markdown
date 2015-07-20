Things to make WDC better:


- better communication when using Tableua instead of the Simulator (error and
  log messages are swallowed by Tableau, and we cannot show a meaningful error
  message if the extraction fails after tableau.submit() is called )

- Perheaps a +tablea.authenticationData+ field where we can store
  arbitrary data that wont be stored plain-text

- The option to turn off showing of the password field in the simulator
  (during demos and more importanty debugging of failed connectors,
  private passwords may be leaked)

- 
