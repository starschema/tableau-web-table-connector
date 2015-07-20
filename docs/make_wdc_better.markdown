# General

## Things that could make WDC better:

- better communication when using Tableua instead of the Simulator (error and
  log messages are swallowed by Tableau, and we cannot show a meaningful error
  message if the extraction fails after tableau.submit() is called )

- Perheaps a +tableau.encryptedData+ field where we can store
  arbitrary data that wont be stored plain-text in the Tableu file.
  Currently only tableau.password provides this capability.

- The option to turn off showing of the password field in the simulator
  (during demos and more importanty debugging of failed connectors,
  private passwords used to access confidential sources may be leaked
  to the developer or anyone with a plain view of the screen)


# Security

## Smuggling out local resources using the WDC

Since there is no whitelisting (at least I could not find any traces of
it in the source code for the WDC API or the Simulator) HTTP resources
on the internal network can be secured against smuggling out by setting
up the Same Origin Policy on the target servers (by default servers
should refuse.

However, since the Same Origin Policy is applied after the request takes
place (and the response is returned by the server), it may allow the
attacker to trigger actions (URLs having side-effects) on the target server
while not neccessary having access to the result of those actions (both
in the Simulator and when using Tableau itself).


Websockets are to be evaluated for malicious purposes.
