
# Security


### Scenario 1: Malicious connector on a remote server, well set-up target

Since there is no whitelisting (at least I could not find any traces of
it in the source code for the WDC API or the Simulator) HTTP resources
on the internal network can be secured against smuggling out by setting
up the Same Origin Policy on the target servers (by default servers
should refuse.

### Scenario 2: Malicious connector th on a remote server, badly configured target

Since the Same Origin Policy is applied after the request takes
place (since its implemented on the server side), a server configured
to share embeddable web resources may allow the attacker to both smuggle out
the content and/or trigger actions (URLs having side-effects) on the target
server (both in the Simulator and when using Tableau itself).


### Scenario 2: Malicious connector on the target server

If the malicious party can trick the users to install the connector on
the target server (like a Tomcat WAR package deployed to the companys
internal workgroup server), its Game Over.

The WDC framework cannot protect against compromise.


### Suggestions

- Make all connectors declare their intentions in a non-programmatic
  way before use. For example:

  - A JSON file declaring the name of the connector, some signature data
    to verify its origin and untouched nature, and the url masks it will
    be using (which will be whitelisted for the connector if the user
    accepts them)

  - Before first use, show this data to the user and allow them to
    review the policies of the connector before any of its code is ran.
    (like mobile applications show the required permissions before
    install)

  - If the signature of the connector changes, notify the user and
    let them re-review and re-accept the policies / the connector


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

